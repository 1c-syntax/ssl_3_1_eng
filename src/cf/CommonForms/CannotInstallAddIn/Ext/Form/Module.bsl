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
	
	Items.FormResumeInstallationAttempt.Visible = Not Parameters.AfterConnectionErrorOccurred;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.DecorationNote.Title = AddInsInternalClient.TextCannotInstallAddIn(
		Parameters.ExplanationText);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationNoteURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportedClients", Parameters.SupportedClients);
	
	OpenForm("CommonForm.SupportedClientApplications", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ResumeInstallationAttempt(Command)
	
	Close(True);
	
EndProcedure

#EndRegion

