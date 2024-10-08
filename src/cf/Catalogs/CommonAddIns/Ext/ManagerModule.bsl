﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region Private

// Returns a reference to the external component reference by ID and version.
//
// Parameters:
//  Id - String -  ID of the external component object.
//  Version        - String -  version of the component.
//
// Returns:
//  CatalogRef.AddIns - 
//
Function FindByID(Id, Version = Undefined) Export
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	
	If Not ValueIsFilled(Version) Then 
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|
			|ORDER BY
			|	AddIns.VersionDate DESC";
	Else 
		Query.SetParameter("Version", Version);
		Query.Text = 
			"SELECT TOP 1
			|	AddIns.Ref AS Ref
			|FROM
			|	Catalog.CommonAddIns AS AddIns
			|WHERE
			|	AddIns.Id = &Id
			|	AND AddIns.Version = &Version";
		
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then 
		Return EmptyRef();
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Result.Unload()[0].Ref;
	
EndFunction

#Region UpdateHandlers

// 
//
Procedure HandleCommonAddIns() Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	CommonAddIns.Ref,
	|	CommonAddIns.AddInStorage,
	|	CommonAddIns.TargetPlatforms
	|FROM
	|	Catalog.CommonAddIns AS CommonAddIns";
		
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 0 Then
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;

	While Selection.Next() Do

		TargetPlatforms = Selection.TargetPlatforms.Get();
		ComponentBinaryData = Selection.AddInStorage.Get();
		
		If TypeOf(ComponentBinaryData) <> Type("BinaryData") Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		InformationOnAddInFromFile = AddInsInternal.InformationOnAddInFromFile(
			ComponentBinaryData, False);
		If Not InformationOnAddInFromFile.Disassembled Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		Attributes = InformationOnAddInFromFile.Attributes;
		
		If TargetPlatforms <> Undefined And Common.IdenticalCollections(TargetPlatforms, Attributes.TargetPlatforms) Then
			ObjectsProcessed = ObjectsProcessed + 1;
			Continue;
		EndIf;
		
		RepresentationOfTheReference = String(Selection.Ref);
		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.CommonAddIns");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();

			ComponentObject_SSLs = Selection.Ref.GetObject(); // CatalogObject.CommonAddIns
			ComponentObject_SSLs.TargetPlatforms = New ValueStorage(Attributes.TargetPlatforms);
			InfobaseUpdate.WriteObject(ComponentObject_SSLs);

			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t process the common add-in %1 due to:
					 |%2';"), RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning, Selection.Ref.Metadata(), Selection.Ref, MessageText);

		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some common add-ins: %1';"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf