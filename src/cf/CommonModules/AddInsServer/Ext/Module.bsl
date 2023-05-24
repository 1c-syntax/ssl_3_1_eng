///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Parameters for the call of the AddInsServer.AttachAddInSSL procedure.
//
// Returns:
//  Structure:
//    * ObjectsCreationIDs - Array of String - IDs of object module instances.
//              Use it only for add-ins with several object creation IDs.
//              When specified, the ID parameter is used only to determine an add-in.
//    * Isolated - Boolean, Undefined -
//              
//              
//              
//              
//              See https://its.1c.ru/db/v83doc#bookmark:dev:TI000001866
//
//
Function ConnectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", False);
	
	Return Parameters;
	
EndFunction

// Attaches the add-in from the add-in storage
// based on Native API or COM technologies on 1C:Enterprise server.
// In SaaS mode, you can only attach common add-ins approved by the service administrator.
//
// Parameters:
//  Id - String - the add-in identification code.
//  Version        - String - an add-in version.
//  ConnectionParameters - See ConnectionParameters.
//
// Returns:
//   Structure - result of connecting components:
//     * Attached - Boolean - attachment flag.
//     * Attachable_Module - AddInObject - an instance of the add-in;
//                          - FixedMap of KeyAndValue - 
//                            
//                            ** Key - String - ID.
//                            ** Value - AddInObject - an instance of the add-in.
//     * ErrorDescription - String - brief error message. 
//
Function AttachAddInSSL(Val Id, Version = Undefined, ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		Isolated = False;
	Else
		Isolated = ConnectionParameters.Isolated;
	EndIf;
	
	CheckResult = AddInsInternal.CheckAddInAttachmentAbility(Id, Version, ConnectionParameters);
	If Not IsBlankString(CheckResult.ErrorDescription) Then
		Result = New Structure;
		Result.Insert("Attached", False);
		Result.Insert("Attachable_Module", Undefined);
		Result.Insert("Version", Version);
		Result.Insert("ErrorDescription", CheckResult.ErrorDescription);
		Return Result;
	EndIf;
	
	Return Common.AttachAddInSSLByID(
		CheckResult.Id, CheckResult.Location, Isolated);
	
EndFunction

#Region ForCallsFromOtherSubsystems

// OnlineUserSupport.GetAddIns

// Returns the table of add-ins details to be updated from the 1C:ITS Portal automatically.
//
// Returns:
//   See GetAddIns.AddInsDetails
//
Function AutomaticallyUpdatedAddIns() Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	AddIns.Id AS Id,
			|	AddIns.Version AS Version
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.UpdateFrom1CITSPortal";
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		ModuleGetAddIns = Common.CommonModule("GetAddIns");
		AddInsDetails = ModuleGetAddIns.AddInsDetails();
		
		While Selection.Next() Do
			ComponentDetails = AddInsDetails.Add();
			ComponentDetails.Id = Selection.Id;
			ComponentDetails.Version = Selection.Version;
		EndDo;
		
		Return AddInsDetails;
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Operation is unavailable. Subsystem ""%1"" is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;
	
EndFunction

// Updates add-ins.
//
// Parameters:
//  AddInsData - ValueTable - info on the add-ins to be updated:
//    * Id - String - ID.
//    * Version - String - version.
//    * VersionDate - String - version date.
//    * Description - String - description.
//    * FileName - String - file name.
//    * FileAddress - String - file address.
//    * ErrorCode - String - error code.
//  ResultAddress - String - a temporary storage address.
//      If it is specified, it contains operation result details.
//
Procedure UpdateAddIns(AddInsData, ResultAddress = Undefined) Export
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
	
		Result = "";
		
		Query = New Query;
		Query.Text =
			"SELECT
			|	AddIns.Ref AS Ref,
			|	AddIns.Id AS Id,
			|	AddIns.Version AS Version,
			|	AddIns.VersionDate AS VersionDate
			|FROM
			|	Catalog.AddIns AS AddIns
			|WHERE
			|	AddIns.Id IN(&IDs)";
		
		Query.SetParameter("IDs", AddInsData.UnloadColumn("Id"));
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		
		// Loop through the query result.
		For Each ResultString1 In AddInsData Do
			
			AddInPresentation = AddInsInternal.AddInPresentation(
				ResultString1.Id, ResultString1.Version);
			
			ErrorCode = ResultString1.ErrorCode;
			
			If ValueIsFilled(ErrorCode) Then
				
				If ErrorCode = "LatestVersion" Then
					Result = Result + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = '%1 - latest version.';"), AddInPresentation) + Chars.LF;
					Continue;
				EndIf;
				
				ErrorInfo = "";
				If ErrorCode = "ComponentNotFound" Then 
					ErrorInfo = NStr("en = 'This add-in is missing in the service';");
				ElsIf ErrorCode = "FileNotImported" Then 
					ErrorInfo = NStr("en = 'The add-in file is not imported from the service';");
				EndIf;
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot import the %1 add-in from the service:
					           |%2';"),
					AddInPresentation, ErrorInfo);
				
				Result = Result + AddInPresentation + " - " + ErrorInfo + Chars.LF;
				WriteLogEvent(NStr("en = 'Updating add-ins';", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,	ErrorText);
				
				Continue;
			EndIf;
			
			BinaryData = GetFromTempStorage(ResultString1.FileAddress);
			Information = AddInsInternal.InformationOnAddInFromFile(BinaryData, False);
			
			If Not Information.Disassembled Then 
				Result = Result + AddInPresentation + " - " + Information.ErrorDescription + Chars.LF;
				WriteLogEvent(NStr("en = 'Updating add-ins';",
					Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, Information.ErrorDescription);
				Continue;
			EndIf;
			
			// Find the ref.
			Filter = New Structure("Id", ResultString1.Id);
			If Selection.FindNext(Filter) Then 
				
				// If the earlier add-in than on 1C:ITS Portal is imported, it should not be updated.
				If Selection.VersionDate > ResultString1.VersionDate Then 
					AddInPresentation = AddInsInternal.AddInPresentation(
						ResultString1.Id, Selection.Version);
					Result = Result + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = '%1 - the application has a version that is newer than the version in the service (%2 dated %3).';"), 
						AddInPresentation, ResultString1.Version, Format(ResultString1.VersionDate, "DLF=D")) + Chars.LF;
					Continue;
				EndIf;
				
				BeginTransaction();
				Try
					
					Block = New DataLock;
					LockItem = Block.Add("Catalog.AddIns");
					LockItem.SetValue("Ref", Selection.Ref);
					Block.Lock();
					
					Object = Selection.Ref.GetObject();
					Object.Lock();
					
					FillPropertyValues(Object, Information.Attributes); // According to manifest data.
					FillPropertyValues(Object, ResultString1);     // 
					
					Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
					
					Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Imported from 1C:ITS Portal. %1.';"),
						CurrentSessionDate());
					
					Object.Write();
					
					Result = Result + StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = '%1 - updated.';"), AddInPresentation) + Chars.LF;
					
					CommitTransaction();
				Except
					RollbackTransaction();
					Result = Result + AddInPresentation
						+ " - " + ErrorProcessing.BriefErrorDescription(ErrorInfo()) + Chars.LF;
					
					WriteLogEvent(NStr("en = 'Updating add-ins';",
							Common.DefaultLanguageCode()),
						EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				EndTry;
				
			EndIf;
			
		EndDo;
		
		If ValueIsFilled(ResultAddress) Then 
			PutToTempStorage(Result, ResultAddress);
		EndIf;
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Operation is unavailable. Subsystem ""%1"" is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;
	
EndProcedure

// Returns:
//  Structure:
//      * Id - String
//      * Version - String
//      * VersionDate - Date
//      * Description - String
//      * FileName - String
//      * PathToFile - String
//
Function SuppliedSharedAddInDetails() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Id");
	LongDesc.Insert("Version");
	LongDesc.Insert("VersionDate");
	LongDesc.Insert("Description");
	LongDesc.Insert("FileName");
	LongDesc.Insert("PathToFile");
	Return LongDesc;
	
EndFunction

// Updates add-ins shares.
//
// Parameters:
//  ComponentDetails - See SuppliedSharedAddInDetails.
//
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.UpdateSharedAddIn(ComponentDetails);
	EndIf;
	
EndProcedure

// End OnlineUserSupport.GetAddIns

#EndRegion

#EndRegion
