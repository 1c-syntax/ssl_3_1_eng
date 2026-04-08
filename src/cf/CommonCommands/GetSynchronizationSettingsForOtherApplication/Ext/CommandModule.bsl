///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If Not DataExchangeServerCall.SUBAssetIsIncludedInDSLExchangePlans(CommandParameter) Then
		
		Text = NStr("en = 'The command is not intended for this node type'",
			CommonClient.DefaultLanguageCode());
		ShowMessageBox(, Text);
		
		Return;
	
	EndIf;
	
	If Not ValueIsFilled(ExchangeMessageTransportServerCall.DefaultTransport(CommandParameter)) Then
		
		Text = NStr("en = 'No default transport type is specified for this node'",
			CommonClient.DefaultLanguageCode());
		ShowMessageBox(, Text);
		
		Return;
		
	EndIf;
	
	If TypeOfTransportUsedIsSM(CommandParameter) Then
		
		Text = NStr("en = 'This transport type does not support saving settings to a file.'",
			CommonClient.DefaultLanguageCode());
		
		ShowMessageBox(, Text);
		
		Return;
		
	EndIf;
		
	Cancel = False;
	
	AddressOfXMLConnectionSettings = "";
	AddressOfJSONConnectionSettings = "";
	
	GetSecondInfobaseDataExchangeSettingsAtServer(Cancel, 
		CommandParameter, AddressOfXMLConnectionSettings, AddressOfJSONConnectionSettings);
	
	If Cancel Then
		
		ShowMessageBox(, NStr("en = 'Cannot get data exchange settings.'"));
		Return;
		
	EndIf;
	
	FilesToObtain = New Array;
	
	If ValueIsFilled(AddressOfXMLConnectionSettings) Then
		
		FileName = NStr("en = 'Connection settings'", CommonClient.DefaultLanguageCode()) + ".xml";
		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfXMLConnectionSettings));
		
	EndIf;
	
	If ValueIsFilled(AddressOfJSONConnectionSettings) Then
		
		FileName = NStr("en = 'Connection settings'", CommonClient.DefaultLanguageCode()) + ".json";
		FilesToObtain.Add(New TransferableFileDescription(FileName, AddressOfJSONConnectionSettings));
		
	EndIf;
	
	If FilesToObtain.Count() > 0 Then
		
		Notification = New CallbackDescription("SaveConnectionSettingsFilesCompletion", ThisObject);
		
		SavingParameters = FileSystemClient.FilesSavingParameters();
		SavingParameters.Interactively = True;
			
		FileSystemClient.SaveFiles(Notification, FilesToObtain, SavingParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GetSecondInfobaseDataExchangeSettingsAtServer(Cancel,
	InfobaseNode, AddressOfXMLConnectionSettings, AddressOfJSONConnectionSettings)
	
	DataExchangeCreationWizard = DataExchangeServer.ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.Initialize(InfobaseNode);
	
	XMLConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsInXML(DataExchangeCreationWizard);
	
	If ValueIsFilled(XMLConnectionSettingsString) Then
		
		TempFileName = GetTempFileName();
		
		Record = New TextWriter;
		Record.Open(TempFileName, "UTF-8");
		Record.Write(XMLConnectionSettingsString);
		Record.Close();
		
		AddressOfXMLConnectionSettings = PutToTempStorage(
			New BinaryData(TempFileName));
		
		DeleteFiles(TempFileName);
		
	EndIf;
	
	JSONConnectionSettingsString = ExchangeMessagesTransport.ConnectionSettingsINJSON(DataExchangeCreationWizard);
	
	If ValueIsFilled(JSONConnectionSettingsString) Then
		
		TempFileName = GetTempFileName();
		
		Record = New TextWriter;
		Record.Open(TempFileName, "UTF-8");
		Record.Write(JSONConnectionSettingsString);
		Record.Close();
		
		AddressOfJSONConnectionSettings = PutToTempStorage(
			New BinaryData(TempFileName));
		
		DeleteFiles(TempFileName);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveConnectionSettingsFilesCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf; 
	
	MessageText = NStr("en = 'Connection settings saved'", CommonClient.DefaultLanguageCode());
	CommonClient.MessageToUser(MessageText);
	
EndProcedure

&AtServer
Function TypeOfTransportUsedIsSM(Val ExchangeNode)
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange.ExchangeMessagesTransport") Then
	
		ModuleMessageExchangeTransport = Common.CommonModule("ExchangeMessagesTransport");
	
		SMManagerModule = ModuleMessageExchangeTransport.TransportManagerSM();
	
		TransportID = ModuleMessageExchangeTransport.DefaultTransport(ExchangeNode);
		TransportParameters = SMManagerModule.TransportParameters();
	
		Return TransportID = TransportParameters.TransportID;
	
	Else
	
		Return False;

	EndIf;
	
EndFunction

#EndRegion
