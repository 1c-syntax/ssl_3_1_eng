///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns a group for tasks that are not included in the command interface sections.
//
Function FullName() Export
	
	Settings = New Structure;
	Settings.Insert("OtherToDoItemsTitle");
	SSLSubsystemsIntegration.OnDefineToDoListSettings(Settings);
	ToDoListOverridable.OnDefineSettings(Settings);
	
	If ValueIsFilled(Settings.OtherToDoItemsTitle) Then
		OtherToDoItemsTitle = Settings.OtherToDoItemsTitle;
	Else
		OtherToDoItemsTitle = NStr("en = 'Other to-do items';");
	EndIf;
	
	Return OtherToDoItemsTitle;
	
EndFunction

#EndRegion

#EndIf