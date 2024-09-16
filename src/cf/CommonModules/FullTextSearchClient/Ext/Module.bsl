///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Event handler for the message Processing event for the form where you want to display the use search checkbox.
//
// Parameters:
//   EventName - String -  name of the event that was received by the event handler on the form.
//   UseFullTextSearch - Number -  the props that the value will be placed in.
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Full-text search") Then
//		Modulpol-Text Searchclient = General Purpose Client.General Module ("Full-Text Searchclient");
//		Modelpantyhose.Processingreferencesexternal
//			Linksreferencesexternal Linksexternal Linksexternal Linksexternal Linksexternal Linksexternal Linksexternal Linksexternal Linksexternal Linksexternal Links, 
//			Use full-text search);
//	Conicelli;
//
Procedure UseSearchFlagChangeNotificationProcessing(Val EventName, UseFullTextSearch) Export
	
	If EventName = "FullTextSearchModeChanged" Then
		UseFullTextSearch = FullTextSearchInternalServerCall.UseSearchFlagValue();
	EndIf;
	
EndProcedure

// Handler for the Change event for the checkbox that switches the full-text search mode.
// The check box must be associated with a number-type item.
// 
// Parameters:
//   UseSearchFlagValue - Number -  the new value of the checkbox that you want to process.
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Full-text search") Then
//		Modulpol-Text Searchclient = General Purpose Client.General Module ("Full-Text Searchclient");
//		Modelpantyhose.When Changing The Use Search Option (Use Full-Text Search);
//	Conicelli;
//
Procedure OnChangeUseSearchFlag(UseSearchFlagValue) Export
	
	UseFullTextSearch = (UseSearchFlagValue = 1);
	
	IsSet = FullTextSearchInternalServerCall.SetFullTextSearchMode(
		UseFullTextSearch);
	
	If Not IsSet Then
		FullTextSearchInternalClient.ShowExclusiveChangeModeWarning();
	EndIf;
	
	Notify("FullTextSearchModeChanged");
	
EndProcedure

// Opens a form for managing full-text search and text extraction.
// Don't forget to set the command that executes the procedure call 
// to depend on the use full-text Search function option.
//
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Full-text search") Then
//		Modulpol-Text Searchclient = General Purpose Client.General Module ("Full-Text Searchclient");
//		Modelpantyhose.Parasitisation();
//	Conicelli;
//
Procedure ShowSetting() Export
	
	OpenForm("DataProcessor.FullTextSearchInData.Form.FullTextSearchAndTextExtractionControl");
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
Procedure ShowFullTextSearchAndTextExtractionManagement() Export
	
	ShowSetting();
	
EndProcedure

#EndRegion

#EndRegion