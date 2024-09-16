///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

&AtClient
Procedure UpdateRegisterData(Command)
	
	ShowMessageBox(, DataUpdateResult());
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataUpdateResult()
	
	TemplateUpdated = NStr("en = '%1: Updated successfully.';");
	TemplateNoUpdateRequired = NStr("en = '%1: No update required.';");
	
	HasHierarchyChanges = False;
	HasChangesInComposition = False;
	
	InformationRegisters.UserGroupCompositions.UpdateHierarchyAndComposition(HasHierarchyChanges,
		HasChangesInComposition);
	
	Result = New Array;
	Result.Add(StringFunctionsClientServer.SubstituteParametersToString(
		?(HasHierarchyChanges, TemplateUpdated, TemplateNoUpdateRequired),
		Metadata.InformationRegisters.UserGroupsHierarchy.Presentation()));
	
	Result.Add(StringFunctionsClientServer.SubstituteParametersToString(
		?(HasChangesInComposition, TemplateUpdated, TemplateNoUpdateRequired),
		Metadata.InformationRegisters.UserGroupCompositions.Presentation()));
	
	Items.List.Refresh();
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

#EndRegion
