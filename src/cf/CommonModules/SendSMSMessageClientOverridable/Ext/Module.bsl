///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called before opening the SMS sending form.
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
//  StandardProcessing - Boolean -    the flag need to perform the standard processing of sending SMS.
//
Procedure OnSendSMSMessage(RecipientsNumbers, Text, AdditionalParameters, StandardProcessing) Export
	
EndProcedure

// Determines the address of the provider's page on the Internet.
//
// Parameters:
//  Provider - EnumRef.SMSProviders -  service provider for sending SMS.
//  InternetAddress - String -  address of the provider's web page.
//
Procedure OnGetProviderInternetAddress(Provider, InternetAddress) Export
	
	
	
EndProcedure

#EndRegion
