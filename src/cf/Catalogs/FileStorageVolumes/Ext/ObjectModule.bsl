///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)

	If TypeOf(FillingData) = Type("Structure") Then
		If Not FillingData.Property("TypeOfFileStorageVolume") Then
			TypeOfFileStorageVolume = Enums.TypesOfFileStorage.OperationalStorage;
		EndIf;
	EndIf;

	FilesStorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		ModuleSafeModeManager   = Common.CommonModule("SafeModeManager");
		UseSecurityProfiles = ModuleSafeModeManager.UseSecurityProfiles();
		
	Else
		UseSecurityProfiles = False;
	EndIf;

	If Not AdditionalProperties.Property("SkipBasicFillingCheck") Then

		If Not ValueIsFilled(TypeOfFileStorageVolume) Then
			ErrorText = NStr("en = 'Volume storage method is required'");
			Common.MessageToUser(ErrorText, , "TypeOfFileStorageVolume", "Object", Cancel);
			Return
		EndIf;

		If Not ValueIsFilled(FilesStorageMethod) Then
			ErrorText = NStr("en = 'Volume storage method is required'");
			Common.MessageToUser(ErrorText, , "FilesStorageMethod", "Object", Cancel);
			Return;
		EndIf;

		If FilesStorageMethod = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol
				And IsBlankString(NameOfBinaryDataStore) Then
			ErrorText = NStr("en = 'Name of binary data storage is required'");
			Common.MessageToUser(ErrorText, , "NameOfBinaryDataStore", "Object", Cancel);
			Return;
		EndIf;

		If Not SequenceNumberUnique(FillOrder, Ref, TypeOfFileStorageVolume) Then
			ErrorText = NStr("en = 'The filling order is not unique. A volume with this order already exists.'");
			Common.MessageToUser(ErrorText, , "FillOrder", "Object", Cancel);
		EndIf;

		If Not CheckUniquenessOfStorageVolumeLocatedInBinaryDataStore(Ref, TypeOfFileStorageVolume, FilesStorageMethod) Then
			
			// ACC:1297-off - The string is localized below.
			ErrorText = TextOfBinaryDataStorageVolumeNonUniquenessError();
			// ACC:1297-on			
					
			Common.MessageToUser(NStr(ErrorText), , "FilesStorageMethod", "Object", Cancel);
		EndIf;		
		
		If MaximumSize <> 0 Then
			CurrentSizeInBytes = 0;
			If Not Ref.IsEmpty() Then
				CurrentSizeInBytes = FilesOperationsInVolumesInternal.VolumeSize(Ref);
			EndIf;
			ActualSize = CurrentSizeInBytes / (1024 * 1024);
			
			If MaximumSize < ActualSize Then
				ErrorText = NStr("en = 'The volume size limit is less than the current size.'");
				Common.MessageToUser(ErrorText, , "MaximumSize", "Object", Cancel);
			EndIf;
		EndIf;

		If FilesStorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories Then
			If IsBlankString(FullPathWindows) And IsBlankString(FullPathLinux) Then
				ErrorText = NStr("en = 'The full path is required.'");
				Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
				Common.MessageToUser(ErrorText, , "FullPathLinux",   "Object", Cancel);
				Return;
			EndIf;

			PathsToVolumes = Common.ObjectAttributesValues(Ref, "FullPathLinux, FullPathWindows");
			CheckTheUniquenessOfPaths = PathsToVolumes.FullPathLinux <> FullPathLinux 
											Or PathsToVolumes.FullPathWindows <> FullPathWindows;
			If CheckTheUniquenessOfPaths Then
				CheckTheUniquenessOfThePathToTheVolumes(Cancel); 
			EndIf;
			
			If Not UseSecurityProfiles
			   And Not IsBlankString(FullPathWindows)
			   And (    Left(FullPathWindows, 2) <> "\\"
			      Or StrFind(FullPathWindows, ":") <> 0 ) Then
				
				ErrorText = NStr("en = 'The volume path must be in the UNC format (\\servername\resource).'");
				Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
				Return;
			EndIf;
		EndIf
	EndIf;

	If Not AdditionalProperties.Property("SkipDirectoryAccessCheck") Then
		If FilesStorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories Then		
			FullPathFieldName = ?(Common.IsWindowsServer(), "FullPathWindows", "FullPathLinux");
			If Common.DataSeparationEnabled() Then
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				SeparatorValue = ?(ModuleSaaSOperations.SessionSeparatorUsage(),
					ModuleSaaSOperations.SessionSeparatorValue(), "");
			Else
				SeparatorValue = "";
			EndIf;

			FullVolumePath = StrReplace(ThisObject[FullPathFieldName], "%z", SeparatorValue);
			TestDirectoryName = FullVolumePath + "CheckAccess" + GetPathSeparator();

			Try
				CreateDirectory(TestDirectoryName);
				DeleteFiles(TestDirectoryName);
			Except
				ErrorInfo = ErrorInfo();

				If UseSecurityProfiles Then
					ErrorTemplate =
						NStr("en = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |Security profile permissions might not be configured,
						           |or an account on whose behalf
						           |1C:Enterprise server is running might have no access rights to the volume directory.
						           |
						           |%1'");
				Else
					ErrorTemplate =
						NStr("en = 'The volume path is invalid or the server with the volume is currently unavailable.
						           |Check if the path to the shared folder is correct and the server is available.
						           |An account on whose behalf 1C:Enterprise server is running
						           |might have no access rights to the volume directory.
						           |
						           |%1'");
				EndIf;

				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate, ErrorProcessing.BriefErrorDescription(ErrorInfo));
				
				Common.MessageToUser(
					ErrorText, , FullPathFieldName, "Object", Cancel);
			EndTry;
		EndIf;
	EndIf;

EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	WorkingWithBinaryDataStoresServer.ChangeCompositionOfStoredData(TypeOfFileStorageVolume, FilesStorageMethod, NameOfBinaryDataStore)

EndProcedure

Procedure OnWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DeletionMark Then
		If Not CheckUniquenessOfStorageVolumeLocatedInBinaryDataStore(Ref, TypeOfFileStorageVolume, FilesStorageMethod) Then

			// ACC:1297-off - The string is localized below.
			ErrorText = TextOfBinaryDataStorageVolumeNonUniquenessError(True);
			// ACC:1297-on

			Raise NStr(ErrorText);
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Returns False if there is a volume of the same order.
Function SequenceNumberUnique(FillOrder, VolumeRef, TypeOfFileStorageVolume)

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(Volumes.FillOrder) AS Count
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.FillOrder = &FillOrder
	|	AND Volumes.TypeOfFileStorageVolume = &TypeOfFileStorageVolume
	|	AND Volumes.Ref <> &VolumeRef";

	Query.Parameters.Insert("FillOrder"		, FillOrder);
	Query.Parameters.Insert("VolumeRef"				, VolumeRef);
	Query.Parameters.Insert("TypeOfFileStorageVolume"	, TypeOfFileStorageVolume);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Count = 0;
	EndIf;

	Return True;

EndFunction

Procedure CheckTheUniquenessOfThePathToTheVolumes(Cancel)
	
	Query = New Query;
	Query.SetParameter("VolumeBeingChecked", Ref);

	Query.Text = 
		"SELECT
		|	FileStorageVolumes.Ref AS Ref,
		|	PRESENTATION(FileStorageVolumes.Ref) AS Presentation,
		|	FileStorageVolumes.FullPathWindows AS FullPathWindows,
		|	FileStorageVolumes.FullPathLinux AS FullPathLinux
		|FROM
		|	Catalog.FileStorageVolumes AS FileStorageVolumes
		|WHERE
		|	NOT FileStorageVolumes.DeletionMark
		|	AND FileStorageVolumes.FilesStorageMethod = VALUE(Enum.WaysToStoreFiles.InNetworkDirectories)
		|	AND FileStorageVolumes.Ref <> &VolumeBeingChecked";
		
	QueryResult = Query.Execute();
	ResultTable2 = QueryResult.Unload();
	ResultTable2.Indexes.Add("FullPathLinux");
	ResultTable2.Indexes.Add("FullPathWindows");
	
	ErrorTemplate = NStr("en = 'The volume path must be unique. The directory is specified in the %1 volume.'");
	If ValueIsFilled(FullPathLinux) Then
		For Each Volume In ResultTable2.FindRows(New Structure("FullPathLinux", FullPathLinux)) Do
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Volume.Presentation);
			Common.MessageToUser(ErrorText, , "FullPathLinux", "Object", Cancel);
		EndDo;
	EndIf;
	
	If ValueIsFilled(FullPathWindows) Then
		For Each Volume In ResultTable2.FindRows(New Structure("FullPathWindows", FullPathWindows)) Do
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, Volume.Presentation);
			Common.MessageToUser(ErrorText, , "FullPathWindows", "Object", Cancel);
		EndDo;
	EndIf;
EndProcedure

Function CheckUniquenessOfStorageVolumeLocatedInBinaryDataStore(VolumeRef, TypeOfFileStorageVolume, FilesStorageMethod)

	If FilesStorageMethod = Enums.WaysToStoreFiles.InNetworkDirectories Then
		Return True;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	COUNT(Volumes.FilesStorageMethod) AS Count
	|FROM
	|	Catalog.FileStorageVolumes AS Volumes
	|WHERE
	|	Volumes.TypeOfFileStorageVolume = &TypeOfFileStorageVolume
	|	AND Volumes.FilesStorageMethod = &FilesStorageMethod
	|	AND Volumes.Ref <> &VolumeRef
	|	AND NOT Volumes.DeletionMark";

	Query.Parameters.Insert("TypeOfFileStorageVolume"	, TypeOfFileStorageVolume);
	Query.Parameters.Insert("FilesStorageMethod"	, FilesStorageMethod);
	Query.Parameters.Insert("VolumeRef"				, VolumeRef);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Count = 0;
	EndIf;

EndFunction

Function PresentationOfWayToHackFilesForMessage(FilesStorageMethod)

	// ACC:1297-off - The function result is localized in FillCheckProcessing() and OnWrite().
	If FilesStorageMethod = Enums.WaysToStoreFiles.InExternalStorageUsingS3Protocol Then
		Result = "vo external storage binary data_ (on protocol S3)";
	ElsIf FilesStorageMethod = Enums.WaysToStoreFiles.InBuiltInStorage Then
        Result = "vo embedded storage binary data_";
	Else
		Result = String(FilesStorageMethod);
	EndIf;
	// ACC:1297-on

	Return Result;

EndFunction

Function TextOfBinaryDataStorageVolumeNonUniquenessError(CheckOnWrite = False)
	
	// ACC:1297-off - The string is localized in FillCheckProcessing() and OnWrite().
	AdditionWhenCheckingDuringRecording = "";
	If CheckOnWrite Then
		AdditionWhenCheckingDuringRecording = " And not marked to1 delete";
	EndIf;
	
	Result = StringFunctionsClientServer.SubstituteParametersToString("en = 'The system already has a volume of %1 kind containing data %2%3'",
					Lower(TypeOfFileStorageVolume),
					PresentationOfWayToHackFilesForMessage(FilesStorageMethod),
					AdditionWhenCheckingDuringRecording);
	// ACC:1297-on

	Return Result;

EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf