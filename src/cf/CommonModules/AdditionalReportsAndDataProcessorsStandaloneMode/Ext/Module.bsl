///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

#Region InternalEventsHandlers

#Region StandardSubsystems

#Region Core

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed information
// database.
//
// Parameters:
//   see the description of the event handler sent to the main() in the syntax helper.
// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Recipient) Export
	
	If ItemSend = DataItemSend.Ignore Then
		//
	ElsIf Common.IsStandaloneWorkplace() Then
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If Not IsServiceProcessing(DataElement.Ref) Then
				ItemSend = DataItemSend.Ignore;
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed information
// database.
//
// Parameters:
//   see the description of the event handler sent to the subordinate() in the syntax helper.
// 
Procedure OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
		
	If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
		If AdditionalReportsAndDataProcessorsSaaS.IsSuppliedDataProcessor(DataElement.Ref) Then
			DataProcessorStartupParameters = AdditionalReportsAndDataProcessorsSaaS.DataProcessorToUseAttachmentParameters(DataElement.Ref);
			FillPropertyValues(DataElement, DataProcessorStartupParameters);
		EndIf;
	EndIf;
	
	If TypeOf(DataElement) = Type("ConstantValueManager.UseAdditionalReportsAndDataProcessors") Then
		If Not InitialImageCreating Then
			ItemSend = DataItemSend.Ignore;
		EndIf;
	EndIf;
	
EndProcedure

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed information
// database.
//
// Parameters:
//   see the description of the event handler for the receipt of the given Main() in the syntax helper.
// 
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// 
		
	ElsIf Common.IsStandaloneWorkplace() Then
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If ValueIsFilled(DataElement.Ref) Then
				DataProcessorRef1 = DataElement.Ref;
			Else
				DataProcessorRef1 = DataElement.GetNewObjectRef();
			EndIf;
			
			RegisterServiceProcessing(DataProcessorRef1);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed information
// database.
//
// Parameters:
//   see the description of the handler for the event of receiving the sent() in the syntax helper.
// 
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender) Export
	
	If Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If ItemReceive = DataItemReceive.Ignore Then
		
		// 
		
	Else
		
		If TypeOf(DataElement) = Type("CatalogObject.AdditionalReportsAndDataProcessors") Then
			
			If AdditionalReportsAndDataProcessorsSaaS.IsSuppliedDataProcessor(DataElement.Ref) Then
				
				DataProcessorStartupParameters = AdditionalReportsAndDataProcessorsSaaS.DataProcessorToUseAttachmentParameters(DataElement.Ref);
				FillPropertyValues(DataElement, DataProcessorStartupParameters);
				DataElement.DataProcessorStorage = Undefined;
				
			Else
				
				If Not GetFunctionalOption("IndependentUsageOfAdditionalReportsAndDataProcessorsSaaS") Then
					ItemReceive = DataItemReceive.Ignore;
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AdditionalReportsAndDataProcessors

// Called when determining whether the current user has the right to add an additional
// report or processing to the data area.
//
// Parameters:
//  AdditionalDataProcessor - 
//    
//  Result - Boolean -  this parameter is set to the permission flag in this procedure,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard permission check processing.
//
Procedure OnCheckInsertRight(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = True;
		StandardProcessing = False;
		Return;
		
	EndIf;
	
EndProcedure

// Called when checking whether an additional report can be loaded or processed from a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean -  this parameter in this procedure sets the flag for whether
//    an additional report can be loaded or processed from a file,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard processing to check whether an additional report can be loaded or processed from a file.
//
Procedure OnCheckCanImportDataProcessorFromFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = Not IsServiceProcessing(AdditionalDataProcessor);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Called when checking whether an additional report can be uploaded or processed to a file.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors,
//  Result - Boolean -  this parameter in this procedure sets the flag for whether
//    an additional report can be uploaded or processed to a file,
//  StandardProcessing - Boolean -  this parameter in this procedure sets the flag for performing
//    standard processing to check whether an additional report can be uploaded or processed to a file.
//
Procedure OnCheckCanExportDataProcessorToFile(Val AdditionalDataProcessor, Result, StandardProcessing) Export
	
	SetPrivilegedMode(True);
	
	If Common.IsStandaloneWorkplace() Then
		
		Result = Not IsServiceProcessing(AdditionalDataProcessor);
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Fills in the types of publishing additional reports and processing that are not available for use
// in the current database model.
//
// Parameters:
//  NotAvailablePublicationKinds - Array of String
//
Procedure OnFillUnavailablePublicationKinds(Val NotAvailablePublicationKinds) Export
	
	If Common.IsStandaloneWorkplace() Then
		NotAvailablePublicationKinds.Add("DebugMode");
	EndIf;
	
EndProcedure

// The procedure must be called from the event before the directory is Written
//  Additional processing reports, checks the validity of changing the details
//  of elements in this directory for additional treatments received from
//  the catalog of additional treatments of the service Manager.
//
// Parameters:
//  Source - CatalogObject.AdditionalReportsAndDataProcessors,
//  Cancel - Boolean -  flag for refusing to write a directory element.
//
Procedure BeforeWriteAdditionalDataProcessor(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		
		If (Source.DeletionMark Or Source.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled) And IsServiceProcessing(Source.Ref) Then
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Additional report or data processor %1 was imported from the service and cannot be disabled from the standalone workstation.
					|To remove the additional report or data processor, perform a disconnection operation
					|in the service application and synchronize the standalone workstation data with the service.';"),
				Source.Description);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Registers an additional report for processing as processing received
// to the offline workplace from the service.
//
// Parameters:
//  Ref - CatalogRef.AdditionalReportsAndDataProcessors
//
Procedure RegisterServiceProcessing(Val Ref)
	
	Set = InformationRegisters.UseAdditionalReportsAndServiceProcessorsAtStandaloneWorkstation.CreateRecordSet();
	Set.Filter.AdditionalReportOrDataProcessor.Set(Ref);
	Record = Set.Add();
	Record.AdditionalReportOrDataProcessor = Ref;
	Record.Supplied = True;
	Set.Write();
	
EndProcedure

// The function checks whether additional processing was received in the offline workplace from the service.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors
//
// Returns:
//  Boolean
//
Function IsServiceProcessing(Ref)
	
	Manager = InformationRegisters.UseAdditionalReportsAndServiceProcessorsAtStandaloneWorkstation.CreateRecordManager();
	Manager.AdditionalReportOrDataProcessor = Ref;
	Manager.Read();
	
	If Manager.Selected() Then
		Return Manager.Supplied;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion
