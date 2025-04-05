///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExchangeMessagesTransport.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	InfobaseOperatingMode();
	
	OperatingSystemAuthentication();

EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobaseOperatingModeOnChange(Item)
	
	InfobaseOperatingMode();
	
EndProcedure

&AtClient
Procedure OperatingSystemAuthenticationOnChange(Item)
	
	OperatingSystemAuthentication()
	
EndProcedure

&AtClient
Procedure InfobaseOperatingMode()
	
	CurrentPage = ?(Object.InfobaseOperatingMode = 0, Items.InfobaseFileModePage, Items.InfobaseClientServerModePage);
	
	Items.InfobaseModes.CurrentPage = CurrentPage;
	
EndProcedure

&AtClient
Procedure OperatingSystemAuthentication()
	
	Items.User.Enabled = Not Object.OperatingSystemAuthentication;
	Items.Password.Enabled = Not Object.OperatingSystemAuthentication;
	
EndProcedure

&AtClient
Procedure InfobaseDirectoryStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(Object, "InfobaseDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure InfobaseDirectoryOpening(Item, StandardProcessing)
	
	DataExchangeClient.FileOrDirectoryOpenHandler(Object, "InfobaseDirectory", StandardProcessing)
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If CheckFilling() Then
		
		ClosingResult = ResultOfClosureOnServer();
		Close(ClosingResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnection(Command)
	
	ClosingNotification1 = New CallbackDescription("TestConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Object);
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification1);
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ResultOfClosureOnServer()
	
	Return ExchangeMessagesTransport.ResultOfClosingTransportForm(ThisForm);
	
EndFunction

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Object)
	
	PermissionsRequests = New Array;
	Permissions = New Array;
	
	If Not IsBlankString(Object.InfobaseDirectory)
		Or Not IsBlankString(Object.NameOfInfobaseOn1CEnterpriseServer) Then
		
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
				
		COMConnectorName = CommonClientServer.COMConnectorName();
		Resolution = ModuleSafeModeManager.PermissionToCreateCOMClass(
			COMConnectorName, Common.COMConnectorID(COMConnectorName));
		
		Permissions.Add(Resolution);
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
		
	EndIf;
	
	Return PermissionsRequests;
	
EndFunction

&AtClient
Procedure TestConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		ConnectionIsSet = False;
		TestConnectionAtServer(ConnectionIsSet);
		
		WarningText = ?(ConnectionIsSet, NStr("en = 'Connection established.'"),
								NStr("en = 'Cannot establish connection.'"));
								
		ShowMessageBox(, WarningText);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(ConnectionIsSet)
	
	SetPrivilegedMode(True);
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	// Fill password.
	ExchangeMessagesTransport.FillInSettingsFromSecureStorageForForm(ThisForm, DataProcessorObject);
	
	// Check the connection.
	ConnectionIsSet = DataProcessorObject.ConnectionIsSet();
	If Not ConnectionIsSet Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessage
			+ Chars.LF + NStr("en = 'See the event log for details.'");
					
		Common.MessageToUser(ErrorMessage, , , , Cancel);
		
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure


#EndRegion


