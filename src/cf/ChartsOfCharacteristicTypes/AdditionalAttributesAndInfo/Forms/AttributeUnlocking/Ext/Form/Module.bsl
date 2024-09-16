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
	
	If PropertyManagerInternal.AdditionalPropertyUsed(Parameters.Ref) Then
		
		Items.UserDialogs.CurrentPage = Items.ObjectUsed;
		
		Items.EnableEdit.DefaultButton = True;
		
		If Parameters.IsAdditionalAttribute = True Then
			Items.Warnings.CurrentPage = Items.AdditionalAttributeWarning;
		Else
			Items.Warnings.CurrentPage = Items.AdditionalInfoWarning;
		EndIf;
		
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "PropertyUsed");
		Items.NoteButtons.Visible = False;
	Else
		Items.UserDialogs.CurrentPage = Items.ObjectNotUsed;
		Items.ObjectUsed.Visible = False; // 
		
		Items.OK.DefaultButton = True;
		
		If Parameters.IsAdditionalAttribute = True Then
			Items.NotesText.CurrentPage = Items.AdditionalAttributeNote;
		Else
			Items.NotesText.CurrentPage = Items.AdditionalInfoNote;
		EndIf;
		
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "PropertyNotUsed");
		Items.WarningButtons.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)
	
	AttributesToUnlock = New Array;
	AttributesToUnlock.Add("ValueType");
	AttributesToUnlock.Add("Name");
	AttributesToUnlock.Add("IDForFormulas");
	
	Close(AttributesToUnlock);
	
EndProcedure

#EndRegion
