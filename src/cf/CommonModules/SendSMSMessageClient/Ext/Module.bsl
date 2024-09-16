///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens the form for sending a new SMS.
//
// Parameters:
//  RecipientsNumbers - Array of Structure:
//   * Phone - String -  recipient's number in the format +<country Code><Codedef><number>;
//   * Presentation - String -  phone number representation;
//   * ContactInformationSource - CatalogRef -  owner of the phone number.
//  
//  Text - String -  text of the message, no more than 1000 characters long.
//  
//  AdditionalParameters - Structure - :
//   * SenderName - String -  the sender's name that will be displayed instead of the recipient's number;
//   * Transliterate - Boolean -  True if you want to translate the message text into translit before sending it.
//
Procedure SendSMS(RecipientsNumbers, Text, AdditionalParameters) Export
	
	StandardProcessing = True;
	SendSMSMessageClientOverridable.OnSendSMSMessage(RecipientsNumbers, Text, AdditionalParameters, StandardProcessing);
	If StandardProcessing Then
		
		SendOptions = SendOptions();
		SendOptions.RecipientsNumbers = RecipientsNumbers;
		SendOptions.Text             = Text;
		
		If TypeOf(AdditionalParameters) = Type("Structure") Then
			FillPropertyValues(SendOptions, AdditionalParameters);
		EndIf;
		
		NotifyDescription = New NotifyDescription("CreateNewSMSMessageSettingsCheckCompleted", ThisObject, SendOptions);
		CheckForSMSMessageSendingSettings(NotifyDescription);
		
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - 
//
Procedure OpenSettingsForm(OnCloseNotifyDescription = Undefined) Export
	
	OpenForm("CommonForm.OutboundSMSSettings", , , , , , OnCloseNotifyDescription);
	
EndProcedure

#EndRegion

#Region Private

// If the user does not have settings for sending SMS, then depending on the rights, it either displays
// the SMS settings form, or displays a message about the inability to send.
//
// Parameters:
//  ResultHandler - NotifyDescription -  the procedure in which you want to transfer code execution after verification.
//
Procedure CheckForSMSMessageSendingSettings(ResultHandler)
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.CanSendSMSMessage Then
		ExecuteNotifyProcessing(ResultHandler, True);
	Else
		If UsersClient.IsFullUser() Then
			NotifyDescription = New NotifyDescription("AfterSetUpSMSMessage", ThisObject, ResultHandler);
			OpenSettingsForm(NotifyDescription);
		Else
			MessageText = NStr("en = 'SMS settings are not configured.
				|Please contact the administrator.';");
			ShowMessageBox(, MessageText);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AfterSetUpSMSMessage(Result, ResultHandler) Export
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.CanSendSMSMessage Then
		ExecuteNotifyProcessing(ResultHandler, True);
	EndIf;
EndProcedure

// Continue with the send SMS procedure.
Procedure CreateNewSMSMessageSettingsCheckCompleted(SMSMessageSendingIsSetUp, SendOptions) Export
	
	If Not SMSMessageSendingIsSetUp Then
		Return;
	EndIf;
		
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If CommonClient.SubsystemExists("StandardSubsystems.Interactions")
		And ClientRunParameters.UseOtherInteractions Then
		
		ModuleInteractionsClient = CommonClient.CommonModule("InteractionsClient");
		FormParameters = ModuleInteractionsClient.SMSMessageSendingFormParameters();
		FormParameters.SMSMessageRecipients = SendOptions.RecipientsNumbers;
		FillPropertyValues(FormParameters, SendOptions);
		ModuleInteractionsClient.OpenSMSMessageSendingForm(FormParameters);
	Else
		OpenForm("CommonForm.SendSMSMessage", SendOptions);
	EndIf;
	
EndProcedure

// Returns:
//  Structure - :
//   * SenderName - String -  the sender's name that will be displayed instead of the recipient's number;
//   * Transliterate - Boolean -  True if you need to translate the message text into translit before sending it;
//   * SubjectOf - AnyRef -  the item that the SMS is associated with.
//
Function SendOptions()
	
	Result = New Structure;
	Result.Insert("RecipientsNumbers", "");
	Result.Insert("Text", "");
	Result.Insert("SenderName", "");
	Result.Insert("Transliterate", False);
	Result.Insert("SubjectOf", Undefined);
	
	Return Result;
	
EndFunction















#EndRegion