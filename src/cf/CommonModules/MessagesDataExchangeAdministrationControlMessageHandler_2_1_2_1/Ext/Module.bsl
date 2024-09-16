///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Namespace of the message interface version.
//
// Returns:
//   String -  name space.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Control";
	
EndFunction

// The version of the message interface served by the handler.
//
// Returns:
//   String - 
//
Function Version() Export
	
	Return "2.1.2.1";
	
EndFunction

// Base type for version messages.
//
// Returns:
//   XDTOObjectType - 
//
Function BaseType() Export
	
	If Not Common.SubsystemExists("CloudTechnology") Then
		Raise NStr("en = 'There is no Service manager.';");
	EndIf;
	
	ModuleMessagesSaaS = Common.CommonModule("MessagesSaaS");
	
	Return ModuleMessagesSaaS.TypeBody();
	
EndFunction

// Processes incoming messages from the service model
//
// Parameters:
//   Message   - XDTODataObject -  incoming message.
//   Sender - ExchangePlanRef.MessagesExchange -  the exchange plan node that corresponds to the sender of the message.
//   MessageProcessed - Boolean -  flag for successful message processing. The value of this parameter must
//                         be set to True if the message was successfully read in this handler.
//
Procedure ProcessSaaSMessage(Val Message, Val Sender, MessageProcessed) Export
	
	MessageProcessed = True;
	
	Dictionary = MessagesDataExchangeAdministrationControlInterface;
	MessageType = Message.Body.Type();
	
	If MessageType = Dictionary.DataSynchronizationSettingsReceivedMessage(Package()) Then
		DataExchangeSaaS.SaveSessionData(Message, SettingsGetActionPresentation());
	ElsIf MessageType = Dictionary.DataSynchronizationSettingsReceivingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SettingsGetActionPresentation());
	ElsIf MessageType = Dictionary.SynchronizationEnabledSuccessfullyMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationEnablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDisabledMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationDisablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationEnablingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationEnablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDisablingErrorMessage(Package()) Then
		DataExchangeSaaS.CommitUnsuccessfulSession(Message, SynchronizationDisablingPresentation());
	ElsIf MessageType = Dictionary.SynchronizationDoneMessage(Package()) Then
		DataExchangeSaaS.CommitSuccessfulSession(Message, SynchronizationExecutionPresentation());
	Else
		MessageProcessed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function SettingsGetActionPresentation()
	
	Return NStr("en = 'Getting data synchronization settings from Service manager.';");
	
EndFunction

Function SynchronizationEnablingPresentation()
	
	Return NStr("en = 'Enabling data synchronization in Service manager.';");
	
EndFunction

Function SynchronizationDisablingPresentation()
	
	Return NStr("en = 'Disabling data synchronization in Service manager.';");
	
EndFunction

Function SynchronizationExecutionPresentation()
	
	Return NStr("en = 'Running data synchronization by user request.';");
	
EndFunction

#EndRegion
