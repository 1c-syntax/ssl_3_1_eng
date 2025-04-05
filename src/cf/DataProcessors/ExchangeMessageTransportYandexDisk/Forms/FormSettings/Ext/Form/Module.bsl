///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExchangeMessagesTransport.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	InitializeFormAttributes();
	
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompressOutgoingMessageFileOnChange(Item)
	SetVisibilityAvailability();
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

&AtClient
Procedure GetToken(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ClientID", Object.ClientID);
	FormParameters.Insert("ClientSecret", Object.ClientSecret);
	
	Notification = New CallbackDescription("GetTokenCompletion", ThisObject);
	
	OpenForm("DataProcessor.ExchangeMessageTransportYandexDisk.Form.TokenReceiptForm",
		FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure
	
&AtClient
Procedure GetTokenCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Result);
	
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
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource("HTTPS", "cloud-api.yandex.net"));
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
	Return PermissionsRequests;
	
EndFunction

&AtClient
Procedure TestConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		ConnectionIsSet = False;
		TestConnectionAtServer(ConnectionIsSet);
		
		WarningText = ?(ConnectionIsSet, NStr("en = 'Подключение успешно установлено.'"),
								NStr("en = 'Не удалось установить подключение.'"));
		ShowMessageBox(, WarningText);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(ConnectionIsSet)
	
	SetPrivilegedMode(True);
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	// Выполняем проверку подключения.
	ConnectionIsSet = DataProcessorObject.ConnectionIsSet();
	If Not ConnectionIsSet Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessage
			+ Chars.LF + NStr("en = 'Техническую информацию об ошибке см. в журнале регистрации.'");
					
		Common.MessageToUser(ErrorMessage, , , , Cancel);
			
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()

	Items.ArchivePasswordExchangeMessages.Enabled = Object.CompressOutgoingMessageFile;
	
	TransportSettings = Undefined;
	Parameters.Property("TransportSettings", TransportSettings);
	If ValueIsFilled(TransportSettings) Then
		Items.AccessSettings.Hide();
	EndIf;
		
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	If Not Parameters.Property("TransportSettings") Then
		Object.CompressOutgoingMessageFile = True;
	EndIf;
		
EndProcedure

#EndRegion

