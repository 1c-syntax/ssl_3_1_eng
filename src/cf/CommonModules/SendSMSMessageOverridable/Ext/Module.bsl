///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sends an SMS via the configured service provider.
//
// Parameters:
//  SendOptions - Structure:
//   * Provider          - EnumRef.SMSProviders -  service provider for sending SMS.
//   * RecipientsNumbers  - Array -  array of recipient number strings in the format +7XXXXXXXXXX;
//   * Text              - String -  message text, the maximum length of operators can be different;
//   * SenderName     - String -  the sender's name that will be displayed instead of the recipient's number;
//   * Login              - String -  login to access the SMS sending service;
//   * Password             - String -  password for accessing the SMS sending service.
//   
//  Result - Structure - :
//    * SentMessages - Array of Structure:
//     ** RecipientNumber - String -  recipient number from the array of recipient Numbers;
//     ** MessageID - String -  ID of the SMS that can be used to request the sending status.
//    Error descriptionstrand - a custom representation of the error. if the string is empty, there is no error.
//
Procedure SendSMS(SendOptions, Result) Export
	
	
	
EndProcedure

// Requests the SMS delivery status from the service provider.
//
// Parameters:
//  MessageID - String -  ID assigned to the SMS when it was sent.
//  Provider - EnumRef.SMSProviders -  provider of SMS sending services.
//  Login              - String -  login to access the SMS sending service.
//  Password             - String -  password for accessing the SMS sending service.
//  Result          - See SendSMSMessage.DeliveryStatus.
//
Procedure DeliveryStatus(MessageID, Provider, Login, Password, Result) Export 
	
	
	
EndProcedure

// Checks whether the saved SMS sending settings are correct.
//
// Parameters:
//  SMSMessageSendingSettings - Structure - :
//   * Provider - EnumRef.SMSProviders
//   * Login - String
//   * Password - String
//   * SenderName - String
//  Cancel - Boolean -  set this parameter to True if the settings are not filled in or filled in incorrectly.
//
Procedure OnCheckSMSMessageSendingSettings(SMSMessageSendingSettings, Cancel) Export

EndProcedure

// Completes the list of permissions for sending SMS.
//
// Parameters:
//  Permissions - Array -  array of objects returned by one of the functions running in the safe Mode.Permission*().
//
Procedure OnGetPermissions(Permissions) Export
	
EndProcedure

#EndRegion
