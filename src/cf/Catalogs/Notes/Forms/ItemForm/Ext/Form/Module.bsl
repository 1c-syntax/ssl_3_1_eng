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
	
	If ValueIsFilled(Parameters.SubjectOf) Then
		Object.SubjectOf = Parameters.SubjectOf;
		Object.SubjectPresentation = Common.SubjectString(Object.SubjectOf);
	EndIf;
	
	Items.SubjectOf.Title = Object.SubjectPresentation;
	Items.SubjectGroup.Visible = ValueIsFilled(Object.SubjectOf);
	
	If Object.Ref.IsEmpty() Then
		Object.Author = Users.CurrentUser();
		FormattedText = Parameters.CopyingValue.Content.Get();
		
		Items.NoteDate.Title = NStr("en = 'Not saved';")
	Else
		Items.NoteDate.Title = NStr("en = 'Saved';") + ": " + Format(Object.ChangeDate, "DLF=DDT");
	EndIf;
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	FormattedText = CurrentObject.Content.Get();

	// 
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	CurrentObject.Content = New ValueStorage(FormattedText, New Deflation(9));
	
	HTMLText = "";
	Attachments = New Structure;
	FormattedText.GetHTML(HTMLText, Attachments);
	
	CurrentObject.ContentText = StringFunctionsClientServer.ExtractTextFromHTML(HTMLText);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// 
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

	Items.NoteDate.Title = NStr("en = 'Saved';") + ": " + Format(Object.ChangeDate, "DLF=DDT");
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	NotifyChanged(Object.Ref);
	If ValueIsFilled(Object.SubjectOf) Then
		NotifyChanged(Object.SubjectOf);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SubjectOfClick(Item)
	ShowValue(,Object.SubjectOf);
EndProcedure

&AtClient
Procedure AuthorClick(Item)
	ShowValue(,Object.Author);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibility1()
	Items.Author.Title = Object.Author;
	OpenedByAuthor = Object.Author = Users.CurrentUser();
	Items.DisplayParameters.Visible = OpenedByAuthor;
	Items.AuthorInfo.Visible = Not OpenedByAuthor;
	
	ReadOnly = Not OpenedByAuthor;
	Items.Content.ReadOnly = Not OpenedByAuthor;
	Items.EditingCommandBar.Visible = OpenedByAuthor;
EndProcedure

#EndRegion
