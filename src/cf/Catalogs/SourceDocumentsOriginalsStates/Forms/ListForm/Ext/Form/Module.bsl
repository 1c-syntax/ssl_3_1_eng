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

	// Standard subsystems.Pluggable commands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListOnChange(Item)
	
	RefreshReusableValues();
	Notify("AddDeleteSourceDocumentOriginalState");
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

// Standard subsystems.Pluggable commands

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export

    ExecuteCommandAtServer(ExecutionParameters);

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)

    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);

EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
//End StandardSubsystems.AttachableCommands

#EndRegion
