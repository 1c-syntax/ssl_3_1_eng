///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Names of directory details whose values can be changed EN masse.
//
// Returns:
//   Array of String - 
//
Function AttributesToEditInBatchProcessing() Export
	
	Result = New Array;
	
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Names of reference list details that are used to control the uniqueness of elements.
//
// Returns:
//   Array of String - 
//
Function NaturalKeyFields() Export
	
	Result = New Array();
	
	Result.Add("Report");
	Result.Add("VariantKey");
	
	Return Result;
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#Else
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion
