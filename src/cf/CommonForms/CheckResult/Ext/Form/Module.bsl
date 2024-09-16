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
	Items.Instruction.Visible =
		DigitalSignatureInternal.VisibilityOfRefToAppsTroubleshootingGuide();
	Items.WarningTitle.Title = Parameters.WarningTitle;
	WarningText = Parameters.WarningText;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InstructionClick(Item)
	
	DigitalSignatureClient.OpenInstructionOnTypicalProblemsOnWorkWithApplications();
	
EndProcedure

#EndRegion

