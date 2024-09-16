///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If ValueIsFilled(Owner) Then
		AdditionalValuesOwner = Common.ObjectAttributeValue(Owner,
			"AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The ""%1"" property is based
				           |on the ""%2"" master property. Please create additional values for the master property.';"),
				Owner,
				AdditionalValuesOwner);
			
			If IsNew() Then
				Raise ErrorDescription;
			Else
				Common.MessageToUser(ErrorDescription);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf