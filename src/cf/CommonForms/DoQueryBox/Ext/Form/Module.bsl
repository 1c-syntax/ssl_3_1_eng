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
	
	// 
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
		TitleWidth = 1.3 * StrLen(Title);
		If TitleWidth > 40 And TitleWidth < 80 Then
			Width = TitleWidth;
		ElsIf TitleWidth >= 80 Then
			Width = 80;
		EndIf;
	EndIf;
	
	If Parameters.LockWholeInterface Then
		WindowOpeningMode = FormWindowOpeningMode.LockWholeInterface;
	EndIf;
	
	// 
	If Parameters.Picture.Type <> PictureType.Empty Then
		Items.Warning.Picture = Parameters.Picture;
	Else
		// 
		// 
		// 
		// 
		ShowPicture = CommonClientServer.StructureProperty(Parameters, "ShowPicture", True);
		If Not ShowPicture Then
			Items.Warning.Visible = False;
		EndIf;
	EndIf;
	
	// 
	If TypeOf(Parameters.MessageText) = Type("String") Then 
		MessageText = Parameters.MessageText;
		Items.MultilineMessageText.Visible = True;
		Items.MessageTextFormattedString.Visible = False;
	ElsIf TypeOf(Parameters.MessageText) = Type("FormattedString") Then
		Items.MessageTextFormattedString.Title = Parameters.MessageText;
		Items.MultilineMessageText.Visible = False;
		Items.MessageTextFormattedString.Visible = True;
	ElsIf TypeOf(Parameters.MessageText) = Type("Undefined") Then
		// 
		MessageText = "";
	Else
		CommonClientServer.CheckParameter(
			Metadata.CommonForms.DoQueryBox.FullName(), 
			"MessageText", 
			Parameters.MessageText, 
			New TypeDescription("String, FormattedString"));
	EndIf;

	MinMarginWidth = 50;
	ApproximateMarginHeight = CountOfRows(Parameters.MessageText, MinMarginWidth);
	Items.MultilineMessageText.Width = MinMarginWidth;
	Items.MultilineMessageText.Height = Min(ApproximateMarginHeight, 10);
	
	// 
	If ValueIsFilled(Parameters.CheckBoxText) Then
		Items.NeverAskAgain.Title = Parameters.CheckBoxText;
	ElsIf Not AccessRight("SaveUserData", Metadata) Or Not Parameters.PromptDontAskAgain Then
		Items.NeverAskAgain.Visible = False;
	EndIf;
	
	// 
	AddCommandsAndButtonsToForm(Parameters.Buttons);
	
	// 
	HighlightDefaultButton = CommonClientServer.StructureProperty(Parameters, "HighlightDefaultButton", True);
	SetDefaultButton(Parameters.DefaultButton, HighlightDefaultButton);
	
	// 
	SetTimeoutButton(Parameters.TimeoutButton);
	
	// 
	TimeoutCounter = Parameters.Timeout;
	
	// 
	StandardSubsystemsServer.ResetWindowLocationAndSize(ThisObject);
	
	If Common.IsMobileClient() Then
		Items.Move(Items.NeverAskAgain, ThisObject);
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	// 
	If TimeoutCounter >= 1 Then
		TimeoutCounter = TimeoutCounter + 1;
		ContinueCountdown();
	EndIf;
	
	CurrentItem = Items.Columns;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_HandlerCommands(Command)
	ValueSelected = ButtonsAndReturnValuesMap.Get(Command.Name);
	
	SelectionResult = New Structure;
	SelectionResult.Insert("NeverAskAgain", NeverAskAgain);
	SelectionResult.Insert("Value", DialogReturnCodeByValue(ValueSelected));
	
	Close(SelectionResult);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure ContinueCountdown()
	TimeoutCounter = TimeoutCounter - 1;
	If TimeoutCounter <= 0 Then
		Close(New Structure("NeverAskAgain, Value", False, DialogReturnCode.Timeout));
	Else
		If TimeoutButtonName <> "" Then
			NewTitle = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1 (%2 seconds remaining)';"),
				TimeoutButtonTitle,
				String(TimeoutCounter));
				
			FormItem = Items[TimeoutButtonName]; // FormAllItems
			FormItem.Title = NewTitle;
		EndIf;
		AttachIdleHandler("ContinueCountdown", 1, True);
	EndIf;
EndProcedure

&AtClient
Function DialogReturnCodeByValue(Value)
	If TypeOf(Value) <> Type("String") Then
		Return Value;
	EndIf;
	
	If Value = "DialogReturnCode.Yes" Then
		Result = DialogReturnCode.Yes;
	ElsIf Value = "DialogReturnCode.None" Then
		Result = DialogReturnCode.No;
	ElsIf Value = "DialogReturnCode.OK" Then
		Result = DialogReturnCode.OK;
	ElsIf Value = "DialogReturnCode.Cancel" Then
		Result = DialogReturnCode.Cancel;
	ElsIf Value = "DialogReturnCode.Retry" Then
		Result = DialogReturnCode.Retry;
	ElsIf Value = "DialogReturnCode.Abort" Then
		Result = DialogReturnCode.Abort;
	ElsIf Value = "DialogReturnCode.Ignore" Then
		Result = DialogReturnCode.Ignore;
	Else
		Result = Value;
	EndIf;
	
	Return Result;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Procedure AddCommandsAndButtonsToForm(Buttons)
	// 
	//
	// Parameters:
	//  
	//		   
	//		   
	//		   
	//		   
	//		   
	
	If TypeOf(Buttons) = Type("String") Then
		ButtonsValueList = StandardSet(Buttons);
	Else
		ButtonsValueList = Buttons;
	EndIf;
	
	ButtonToValueMap = New Map;
	
	IndexOf = 0;
	
	For Each ButtonInfoItem In ButtonsValueList Do
		IndexOf = IndexOf + 1;
		CommandName = "Command" + XMLString(IndexOf);
		Command = Commands.Add(CommandName);
		Command.Action  = "Attachable_HandlerCommands";
		Command.Title = ButtonInfoItem.Presentation;
		Command.ModifiesStoredData = False;
		
		Button= Items.Add(CommandName, Type("FormButton"), CommandBar);
		Button.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
		Button.CommandName = CommandName;
		
		ButtonToValueMap.Insert(CommandName, ButtonInfoItem.Value);
	EndDo;
	
	ButtonsAndReturnValuesMap = New FixedMap(ButtonToValueMap);
EndProcedure

&AtServer
Procedure SetDefaultButton(DefaultButton, HighlightDefaultButton)
	If ButtonsAndReturnValuesMap.Count() = 0 Then
		Return;
	EndIf;
	
	Button = Undefined;
	For Each Item In ButtonsAndReturnValuesMap Do
		If Item.Value = DefaultButton Then
			Button = Items[Item.Key];
			Break;
		EndIf;
	EndDo;
	
	If Button = Undefined Then
		Button = CommandBar.ChildItems[0];
	EndIf;
	
	If HighlightDefaultButton Then
		Button.DefaultButton = True;
	EndIf;
	CurrentItem = Button;
EndProcedure

&AtServer
Procedure SetTimeoutButton(TimeoutButtonValue)
	If ButtonsAndReturnValuesMap.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Item In ButtonsAndReturnValuesMap Do
		If Item.Value = TimeoutButtonValue Then
			TimeoutButtonName = Item.Key;
			FormCommand = Commands[TimeoutButtonName]; // FormCommand
			TimeoutButtonTitle = FormCommand.Title;
			Return;
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Function StandardSet(Buttons)
	Result = New ValueList;
	
	If Buttons = "QuestionDialogMode.YesNo" Then
		Result.Add("DialogReturnCode.Yes",  NStr("en = 'Yes';"));
		Result.Add("DialogReturnCode.None", NStr("en = 'No';"));
	ElsIf Buttons = "QuestionDialogMode.YesNoCancel" Then
		Result.Add("DialogReturnCode.Yes",     NStr("en = 'Yes';"));
		Result.Add("DialogReturnCode.None",    NStr("en = 'No';"));
		Result.Add("DialogReturnCode.Cancel", NStr("en = 'Cancel';"));
	ElsIf Buttons = "QuestionDialogMode.OK" Then
		Result.Add("DialogReturnCode.OK", NStr("en = 'OK';"));
	ElsIf Buttons = "QuestionDialogMode.OKCancel" Then
		Result.Add("DialogReturnCode.OK",     NStr("en = 'OK';"));
		Result.Add("DialogReturnCode.Cancel", NStr("en = 'Cancel';"));
	ElsIf Buttons = "QuestionDialogMode.RetryCancel" Then
		Result.Add("DialogReturnCode.Retry", NStr("en = 'Retry';"));
		Result.Add("DialogReturnCode.Cancel",    NStr("en = 'Cancel';"));
	ElsIf Buttons = "QuestionDialogMode.AbortRetryIgnore" Then
		Result.Add("DialogReturnCode.Abort",   NStr("en = 'Abort';"));
		Result.Add("DialogReturnCode.Retry",  NStr("en = 'Retry';"));
		Result.Add("DialogReturnCode.Ignore", NStr("en = 'Ignore';"));
	EndIf;
	
	Return Result;
EndFunction

// Specifies the approximate number of lines, including hyphens.
&AtServerNoContext
Function CountOfRows(Text, CutoffByWidth, BringToFormItemSize = True)
	CountOfRows = StrLineCount(Text);
	HyphenationCount = 0;
	For LineNumber = 1 To CountOfRows Do
		String = StrGetLine(Text, LineNumber);
		HyphenationCount = HyphenationCount + Int(StrLen(String)/CutoffByWidth);
	EndDo;
	EstimatedLineCount = CountOfRows + HyphenationCount;
	If BringToFormItemSize Then
		ZoomRatio = 2/3; // 
		EstimatedLineCount = Int((EstimatedLineCount+1)*ZoomRatio);
	EndIf;
	If EstimatedLineCount = 2 Then
		EstimatedLineCount = 3;
	EndIf;
	Return EstimatedLineCount;
EndFunction

#EndRegion
