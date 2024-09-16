///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// See UsersInternalSaaS.GetUserFormProcessing
Procedure GetUserFormProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	UsersInternalSaaS.GetUserFormProcessing(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
	
EndProcedure

Procedure WriteTheErrorToTheLog(ErrorText) Export
	
	WriteLogEvent(
		NStr("en = 'Runtime error';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, ErrorText);
	
EndProcedure

#EndRegion