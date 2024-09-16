///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Parameters for calling an external Componentserver.Connect a component.
//
// Returns:
//  Structure:
//    * ObjectsCreationIDs - Array of String -  instance IDs of the object module,
//              used only for components that have multiple object creation IDs.
//              When setting the ID parameter, It will only be used to define the component.
//    * Isolated - Boolean  -  
//                               
//                                
//                                
//              - Undefined - :
//                                
//                               
//                               See https://its.1c.eu/db/v83doc
//    * FullTemplateName - String - 
//
Function ConnectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", Common.IsDefaultAddInAttachmentMethod());
	Parameters.Insert("FullTemplateName");
	
	Return Parameters;
	
EndFunction

// Connects on the 1C server:Create an external component from the external component store
// using the Native API or COM technology.
// The service model only allows connecting shared external components that are approved by the service administrator.
//
// Parameters:
//  Id - String - 
//  Version        - String -  version of the component.
//  ConnectionParameters - See ConnectionParameters.
//
// Returns:
//   Structure - :
//     * Attached - Boolean -  the sign connection;
//     * Attachable_Module - AddInObject -  instance of an external component object;
//                          - FixedMap of KeyAndValue - 
//                            :
//                            ** Key - String -  ID,
//                            ** Value - AddInObject -  an instance of an external component object.
//     * ErrorDescription - String -  brief description of the error. 
//
Function AttachAddInSSL(Val Id, Version = Undefined, ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		Isolated = Common.IsDefaultAddInAttachmentMethod();
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

// 

// 
//
// Parameters:
//  Variant - String - :
//    
//    
//    
//
// Returns:
//   - ValueTable:
//     * Id - String -  contains a unique identifier of the external
//                    component, which is specified by the user in the publication database;
//     * Version        - String - 
//     * Description  - String - 
//     * VersionDate    - Date - 
//     * AutoUpdate - Boolean - 
//   - Array - 
//
Function ComponentsToUse(Variant) Export
	
	If Not Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The operation is unavailable as the ""%1"" subsystem is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;
	
	If Variant = "Supplied1" Then
		Return AddInsInternal.SuppliedAddIns();
	EndIf;
	
	AddInsData = AddInsInternal.AddInsData(Variant);
	
	ModuleGetAddIns = Common.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails();
	
	For Each ComponentDetails In AddInsData Do
		NewRow = AddInsDetails.Add();
		FillPropertyValues(NewRow, ComponentDetails);
	EndDo;
	
	Return AddInsDetails;
	
EndFunction

// Performs the update of the external component.
//
// Parameters:
//  AddInsData - ValueTable - :
//    * Id - String -  ID.
//    * Version - String -  version.
//    * VersionDate - String -  the date of release.
//    * Description - String -  name.
//    * FileName - String -  file name.
//    * FileAddress - String -  file address.
//    * ErrorCode - String -  error code.
//  ResultAddress - String - 
//      
//      :
//       
//       
//         
//         
//       
//         
//         
//
Procedure UpdateAddIns(AddInsData, ResultAddress = Undefined) Export
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("Result", False);
	ExecutionResult.Insert("Errors", New Map);
	ExecutionResult.Insert("Success", New Map);
	
	If Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
	
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
		
		UsedAddIns = Undefined;
		
		// 
		For Each ResultString1 In AddInsData Do
			
			AddInPresentation = AddInsInternal.AddInPresentation(
				ResultString1.Id, ResultString1.Version);
			
			ErrorCode = ResultString1.ErrorCode;
			
			If ValueIsFilled(ErrorCode) Then
				
				If ErrorCode = "LatestVersion" Then
					ExecutionResult.Success.Insert(ResultString1.Id,
						StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = '%1: the latest version.';"), AddInPresentation));
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
				
				ExecutionResult.Errors.Insert(ResultString1.Id, ErrorText);
			
				WriteLogEvent(NStr("en = 'Updating add-ins';", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,	ErrorText);
				
				Continue;
			EndIf;
			
			BinaryData = GetFromTempStorage(ResultString1.FileAddress);
			Information = AddInsInternal.InformationOnAddInFromFile(BinaryData, False);
			
			If Not Information.Disassembled Then
				
				ExecutionResult.Errors.Insert(ResultString1.Id, AddInPresentation + " - "
					+ Information.ErrorDescription + ?(Information.ErrorInfo = Undefined, "", ": "
					+ ErrorProcessing.BriefErrorDescription(Information.ErrorInfo)));

				WriteLogEvent(NStr("en = 'Updating add-ins';",
					Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
					Information.ErrorDescription);
				Continue;
			EndIf;
			
			// 
			Filter = New Structure("Id", ResultString1.Id);
			Selection.Reset();
			If Selection.FindNext(Filter) Then 
				// 
				If Selection.VersionDate > ResultString1.VersionDate Then 
					AddInPresentation = AddInsInternal.AddInPresentation(
						ResultString1.Id, Selection.Version);
					
					ExecutionResult.Success.Insert(ResultString1.Id,
						StringFunctionsClientServer.SubstituteParametersToString(
							NStr("en = '%1: the app contains a version that is newer than the version in the service (%2 dated %3).';"), 
							AddInPresentation, ResultString1.Version, Format(ResultString1.VersionDate, "DLF=D")));
					Continue;
				EndIf;
				
				ObjectReference = Selection.Ref;
			Else
				ObjectReference = Undefined;
				If UsedAddIns = Undefined Then
					UsedAddIns = AddInsInternal.UsedAddIns();
				EndIf;
				RowOfAddIn = UsedAddIns.Find(ResultString1.Id, "Id");
				If RowOfAddIn <> Undefined Then
					AutoUpdate = RowOfAddIn.AutoUpdate;
				Else
					AutoUpdate = False;
				EndIf;
			EndIf;
				
			BeginTransaction();
			Try
				
				Block = New DataLock;
				LockItem = Block.Add("Catalog.AddIns");
				If ObjectReference <> Undefined Then
					LockItem.SetValue("Ref", ObjectReference);
				EndIf;
				Block.Lock();
				
				If ObjectReference <> Undefined Then
					Object = ObjectReference.GetObject();
					Object.Lock();
				Else
					Object = Catalogs.AddIns.CreateItem();
					Object.UpdateFrom1CITSPortal = AutoUpdate;
					Object.Use = Enums.AddInUsageOptions.Used;
				EndIf;
				
				FillPropertyValues(Object, Information.Attributes); // 
				FillPropertyValues(Object, ResultString1);     // 
				
				Object.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms);
				Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
				
				Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Imported from 1C:ITS Portal. %1.';"),
					CurrentSessionDate());
				
				Object.Write();
				
				ExecutionResult.Success.Insert(ResultString1.Id, StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1: updated.';"), AddInPresentation));
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ExecutionResult.Errors.Insert(ResultString1.Id, AddInPresentation
					+ " - " + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
				WriteLogEvent(NStr("en = 'Updating add-ins';",
						Common.DefaultLanguageCode()),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
			
		EndDo;
		
		ExecutionResult.Result = ExecutionResult.Errors.Count() = 0;
		
		If ValueIsFilled(ResultAddress) Then 
			PutToTempStorage(ExecutionResult, ResultAddress);
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

// Performs the update of a common external component.
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

// 
// 
//
// Returns:
//  ValueTable:
//    * Id - String -  contains a unique identifier of the external
//                   component, which is specified by the user in the publication database;
//    * Version        - String - 
//    * Description  - String - 
//    * VersionDate    - Date - 
//    * AutoUpdate - Boolean - 
//
Function AutomaticallyUpdatedAddIns() Export
	
	If Not Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Operation is unavailable. Subsystem ""%1"" is required.';"),
			"OnlineUserSupport.GetAddIns");
	EndIf;
	
	ModuleGetAddIns = Common.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails();
	
	AddInsData = AddInsInternal.AddInsData("ForUpdate");
	
	For Each ComponentDetails In AddInsData Do
		NewRow = AddInsDetails.Add();
		FillPropertyValues(NewRow, ComponentDetails);
	EndDo;
	
	Return AddInsDetails;
	
EndFunction

#EndRegion

// End OnlineUserSupport.GetAddIns

#EndRegion

