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
	
	UsersInternalSaaSServerCall.GetUserFormProcessing(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
	
EndProcedure

#EndRegion