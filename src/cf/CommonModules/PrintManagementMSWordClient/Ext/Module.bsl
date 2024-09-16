///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Creates a COM connection to the Word.Application COM object and creates a
// single document in it.
//
Function InitializeMSWordPrintForm(Template) Export
	
	Handler = New Structure("Type", "DOC");
	
#If Not MobileClient Then
	Try
		COMObject = New COMObject("Word.Application");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
	Handler.Insert("COMJoin", COMObject);
	Try
		COMObject.Documents.Add();
	Except
		COMObject.Quit(0);
		COMObject = 0;
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
	TemplatePagesSettings = Template; // 
	If TypeOf(Template) = Type("Structure") Then
		TemplatePagesSettings = Template.TemplatePagesSettings;
		// 
		Template.COMJoin.ActiveDocument.Close();
		Handler.COMJoin.ActiveDocument.CopyStylesFromTemplate(Template.FileName);
		
		Template.COMJoin.WordBasic.DisableAutoMacros(1);
		Template.COMJoin.Documents.Open(Template.FileName);
	EndIf;
	
	// 
	If TemplatePagesSettings <> Undefined Then
		For Each Setting In TemplatePagesSettings Do
			Try
				COMObject.ActiveDocument.PageSetup[Setting.Key] = Setting.Value;
			Except
				// 
			EndTry;
		EndDo;
	EndIf;
	// 
	Handler.Insert("ViewType", COMObject.Application.ActiveWindow.View.Type);
	
#EndIf

	Return Handler;
	
EndFunction

// Creates a COM connection to the Word.Application COM object and opens
// the layout in it. The layout file is saved based on the binary data
// passed in the function parameters.
//
// Parameters:
//   BinaryTemplateData - BinaryData -  binary layout data.
// Returns:
//   Structure - 
//
Function GetMSWordTemplate(Val BinaryTemplateData, Val TempFileName) Export
	
	Handler = New Structure("Type", "DOC");
#If Not MobileClient Then
	Try
		COMObject = New COMObject("Word.Application");
	Except
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
		FailedToGeneratePrintForm(ErrorInfo());
	EndTry;
	
#If WebClient Then
	FilesDetails1 = New Array;
	FilesDetails1.Add(New TransferableFileDescription(TempFileName, PutToTempStorage(BinaryTemplateData)));
	TempDirectory = PrintManagementInternalClient.CreateTemporaryDirectory("MSWord");
	If Not GetFiles(FilesDetails1, , TempDirectory, False) Then // 
		Return Undefined;
	EndIf;
	TempFileName = CommonClientServer.AddLastPathSeparator(TempDirectory) + TempFileName;
#Else
	TempFileName = GetTempFileName("DOC");
	BinaryTemplateData.Write(TempFileName);
#EndIf
	
	Try
		COMObject.WordBasic.DisableAutoMacros(1);
		COMObject.Documents.Open(TempFileName);
	Except
		COMObject.Quit(0);
		COMObject = 0;
		DeleteFiles(TempFileName);
		EventLogClient.AddMessageForEventLog(EventLogEvent(), "Error",
			ErrorProcessing.DetailErrorDescription(ErrorInfo()),,True);
		Raise(NStr("en = 'Cannot open template file. Reason:';") + Chars.LF 
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	Handler.Insert("COMJoin", COMObject);
	Handler.Insert("FileName", TempFileName);
	Handler.Insert("IsTemplate", True);
	
	Handler.Insert("TemplatePagesSettings", New Map);
	
	For Each SettingName In PageParametersSettings() Do
		Try
			Handler.TemplatePagesSettings.Insert(SettingName, COMObject.ActiveDocument.PageSetup[SettingName]);
		Except
			// 
		EndTry;
	EndDo;
#EndIf
	
	Return Handler;
	
EndFunction

// Closes the connection to the word.Application COM object.
// Parameters:
//   Handler - 
//   CloseApplication - Boolean -  if you want to close the app.
//
Procedure CloseConnection(Handler, Val CloseApplication) Export
	
	If CloseApplication Then
		Handler.COMJoin.Quit(0);
	EndIf;
	
	Handler.COMJoin = 0;
	
	#If Not WebClient Then
	If Handler.Property("FileName") Then
		DeleteFiles(Handler.FileName);
	EndIf;
	#EndIf
	
EndProcedure

// Sets the visibility property of the MS Word application.
// 
// Parameters:
//  Handler - Structure -  link to the printed form.
//
Procedure ShowMSWordDocument(Val Handler) Export
	
	COMJoin = Handler.COMJoin;
	COMJoin.Application.Selection.Collapse();
	
	// 
	If Handler.Property("ViewType") Then
		COMJoin.Application.ActiveWindow.View.Type = Handler.ViewType;
	EndIf;
	
	COMJoin.Application.Visible = True;
	COMJoin.Activate();
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Gets the area from the layout.
//
// Parameters:
//  Handler - 
//  AreaName - name of the area in the layout.
//  OffsetStart    - Number -  redefines the border of the beginning of the area for cases when the area does not start immediately after
//                              the operator bracket, but after one or more characters.
//                              Default value: 1-the scope opening operator bracket is expected 
//                                                         to be followed by a newline character that does not need to be included in
//                                                         the resulting scope.
//  OffsetEnd - Number -  redefines the scope end boundary for cases where the scope ends
//                              one or more characters earlier than the operator bracket. The value must 
//                              be negative.
//                              Default value: -1-it is expected that
//                                                         there is a newline character before the scope closing operator bracket that does not need to be included in
//                                                         the resulting scope.
//
Function GetMSWordTemplateArea(Val Handler,
									Val AreaName,
									Val OffsetStart = 1,
									Val OffsetEnd = -1) Export
	
	Result = New Structure("Document,Start,End");
	
	PositionStart = OffsetStart + GetAreaStartPosition(Handler.COMJoin, AreaName);
	PositionEnd1 = OffsetEnd + GetAreaEndPosition(Handler.COMJoin, AreaName);
	
	If PositionStart >= PositionEnd1 Or PositionStart < 0 Then
		Return Undefined;
	EndIf;
	
	Result.Document = Handler.COMJoin.ActiveDocument;
	Result.Start = PositionStart;
	Result.End   = PositionEnd1;
	
	Return Result;
	
EndFunction

// Gets the header area of the first layout area.
// Parameters:
//   Handler - 
// 
//   
//
Function GetHeaderArea(Val Handler) Export
	
	Return New Structure("Header", Handler.COMJoin.ActiveDocument.Sections(1).Headers.Item(1));
	
EndFunction

// Gets the footer area of the first layout area.
// Parameters:
//   Handler - 
// 
//   
//
Function GetFooterArea(Handler) Export
	
	Return New Structure("Footer", Handler.COMJoin.ActiveDocument.Sections(1).Footers.Item(1));
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 

// Adds a footer to the printed form from the layout.
// Parameters:
//   PrintForm - Structure -  link to the printed form.
//   HandlerArea - COMObject -  link to the area in the layout.
//
Procedure AddFooter(Val PrintForm, Val HandlerArea) Export
	
	HandlerArea.Footer.Range.Copy();
	Footer(PrintForm).Paste();
	
EndProcedure

// Adds a header to the printed form from the layout.
// Parameters:
//   PrintForm - 
//   
//   
//   ObjectData - object data to fill in.
//
Procedure FillFooterParameters(Val PrintForm, Val ObjectData = Undefined) Export
	
	If ObjectData = Undefined Then
		Return;
	EndIf;
	
	For Each ParameterValue1 In ObjectData Do
		If TypeOf(ParameterValue1.Value) <> Type("Array") Then
			Replace(Footer(PrintForm), ParameterValue1.Key, ParameterValue1.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function Footer(PrintForm)
	Return PrintForm.COMJoin.ActiveDocument.Sections(1).Footers.Item(1).Range;
EndFunction

// Adds a header to the printed form from the layout.
// Parameters:
//   PrintForm - link to the printed form.
//   HandlerArea - 
//   
//   
//
Procedure AddHeader(Val PrintForm, Val HandlerArea) Export
	
	HandlerArea.Header.Range.Copy();
	Header(PrintForm).Paste();
	
EndProcedure

// Adds a header to the printed form from the layout.
// Parameters:
//   PrintForm - 
//   
//   
//   ObjectData - object data to fill in.
//
Procedure FillHeaderParameters(Val PrintForm, Val ObjectData = Undefined) Export
	
	If ObjectData = Undefined Then
		Return;
	EndIf;
	
	For Each ParameterValue1 In ObjectData Do
		If TypeOf(ParameterValue1.Value) <> Type("Array") Then
			Replace(Header(PrintForm), ParameterValue1.Key, ParameterValue1.Value);
		EndIf;
	EndDo;
	
EndProcedure

Function Header(PrintForm)
	Return PrintForm.COMJoin.ActiveDocument.Sections(1).Headers.Item(1).Range;
EndFunction

// 

// Adds an area to the print form from the layout, while replacing
// the parameters in the area with values from the object data.
// Used for single output of an area.
//
// Parameters:
//   PrintForm - link to the printed form.
//   HandlerArea - link to the area in the layout.
//   GoToNextRow - Boolean -  whether to insert a break after the area is displayed.
//
// Returns:
//   Structure:
//    * Document - COMObject
//    * Start - Number
//    * End - Number
//
Function AttachArea(Val PrintForm,
							Val HandlerArea,
							Val GoToNextRow = True,
							Val JoinTableRow = False) Export
	
	HandlerArea.Document.Range(HandlerArea.Start, HandlerArea.End).Copy();
	
	PFActiveDocument = PrintForm.COMJoin.ActiveDocument;
	DocumentEndPosition	= PFActiveDocument.Range().End;
	InsertionArea				= PFActiveDocument.Range(DocumentEndPosition-1, DocumentEndPosition-1);
	
	If JoinTableRow Then
		InsertionArea.PasteAppendTable();
	Else
		InsertionArea.Paste();
	EndIf;
	
	// 
	Result = New Structure("Document, Start, End",
							PFActiveDocument,
							DocumentEndPosition-1,
							PFActiveDocument.Range().End-1);
	
	If GoToNextRow Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
	Return Result;
	
EndFunction

// Adds the list area to the printed form from the layout, while replacing
// the parameters in the area with values from the object data.
// Used when displaying list data (bulleted or numbered).
//
// Parameters:
//   PrintFormArea - COMObject -  link to the area in printed form.
//   ObjectData - Structure
//
Procedure FillParameters_(Val PrintFormArea, Val ObjectData = Undefined) Export
	
	If ObjectData = Undefined Then
		Return;
	EndIf;
	
	For Each ParameterValue1 In ObjectData Do
		If TypeOf(ParameterValue1.Value) <> Type("Array") Then
			Replace(PrintFormArea.Document.Content, ParameterValue1.Key, ParameterValue1.Value);
		EndIf;
	EndDo;
	
EndProcedure

// 

// Adds the list area to the printed form from the layout, while replacing
// the parameters in the area with values from the object data.
// Used when displaying list data (bulleted or numbered).
//
// Parameters:
//   PrintForm - Structure -  link to the printed form.
//   HandlerArea - COMObject -  link to the area in the layout.
//   Parameters - String - a list of parameters that need to be replaced.
//   ObjectData - Array of Structure
//   GoToNextRow - Boolean -  whether to insert a break after the area is displayed.
//
Procedure JoinAndFillSet(Val PrintForm,
									  Val HandlerArea,
									  Val ObjectData = Undefined,
									  Val GoToNextRow = True) Export
	
	HandlerArea.Document.Range(HandlerArea.Start, HandlerArea.End).Copy();
	
	ActiveDocument = PrintForm.COMJoin.ActiveDocument;
	
	If ObjectData <> Undefined Then
		For Each RowData In ObjectData Do
			InsertPosition = ActiveDocument.Range().End;
			InsertionArea = ActiveDocument.Range(InsertPosition-1, InsertPosition-1);
			InsertionArea.Paste();
			
			If TypeOf(RowData) = Type("Structure") Then
				For Each ParameterValue1 In RowData Do
					Replace(ActiveDocument.Content, ParameterValue1.Key, ParameterValue1.Value);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	If GoToNextRow Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

// Adds a list area to the printed form from the layout, while replacing
// the parameters in the area with values from the object data.
// Used when displaying a table row.
//
// Parameters:
//   PrintForm - Structure -  link to the printed form.
//   HandlerArea - COMObject -  link to the area in the layout.
//   Table name - the name of the table (for data access).
//   ObjectData - Structure
//   GoToNextRow - Boolean -  whether to insert a break after the area is displayed.
//
Procedure JoinAndFillTableArea(Val PrintForm,
												Val HandlerArea,
												Val ObjectData = Undefined,
												Val GoToNextRow = True) Export
	
	If ObjectData = Undefined Or ObjectData.Count() = 0 Then
		Return;
	EndIf;
	
	FirstRow = True;
	
	HandlerArea.Document.Range(HandlerArea.Start, HandlerArea.End).Copy();
	
	ActiveDocument = PrintForm.COMJoin.ActiveDocument;
	
	// 
	// 
	InsertBreakAtNewLine(PrintForm); 
	InsertPosition = ActiveDocument.Range().End;
	InsertionArea = ActiveDocument.Range(InsertPosition-1, InsertPosition-1);
	InsertionArea.Paste();
	ActiveDocument.Range(InsertPosition-2, InsertPosition-2).Delete();
	
	If TypeOf(ObjectData[0]) = Type("Structure") Then
		For Each ParameterValue1 In ObjectData[0] Do
			Replace(ActiveDocument.Content, ParameterValue1.Key, ParameterValue1.Value);
		EndDo;
	EndIf;
	
	For Each TableRowData In ObjectData Do
		If FirstRow Then
			FirstRow = False;
			Continue;
		EndIf;
		
		NewInsertionPosition = ActiveDocument.Range().End;
		ActiveDocument.Range(InsertPosition-1, ActiveDocument.Range().End-1).Select();
		PrintForm.COMJoin.Selection.InsertRowsBelow();
		
		ActiveDocument.Range(NewInsertionPosition-1, ActiveDocument.Range().End-2).Select();
		PrintForm.COMJoin.Selection.Paste();
		InsertPosition = NewInsertionPosition;
		
		If TypeOf(TableRowData) = Type("Structure") Then
			For Each ParameterValue1 In TableRowData Do
				Replace(ActiveDocument.Content, ParameterValue1.Key, ParameterValue1.Value);
			EndDo;
		EndIf;
		
	EndDo;
	
	If GoToNextRow Then
		InsertBreakAtNewLine(PrintForm);
	EndIf;
	
EndProcedure

// 

// Inserts a break on the next line.
// Parameters:
//   Handler - 
//
Procedure InsertBreakAtNewLine(Val Handler) Export
	ActiveDocument = Handler.COMJoin.ActiveDocument;
	DocumentEndPosition = ActiveDocument.Range().End;
	ActiveDocument.Range(DocumentEndPosition-1, DocumentEndPosition-1).InsertParagraphAfter();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Function GetAreaStartPosition(Val COMJoin, Val AreaID)
	
	AreaID = "{v8 Area." + AreaID + "}";
	
	EntireDocument = COMJoin.ActiveDocument.Content;
	EntireDocument.Select();
	
	Search = COMJoin.Selection.Find;
	Search.Text = AreaID;
	Search.ClearFormatting();
	Search.Forward = True;
	Search.execute();
	
	If Search.Found Then
		Return COMJoin.Selection.End;
	EndIf;
	
	Return -1;
	
EndFunction

Function GetAreaEndPosition(Val COMJoin, Val AreaID)
	
	AreaID = "{/v8 Area." + AreaID + "}";
	
	EntireDocument = COMJoin.ActiveDocument.Content;
	EntireDocument.Select();
	
	Search = COMJoin.Selection.Find;
	Search.Text = AreaID;
	Search.ClearFormatting();
	Search.Forward = True;
	Search.execute();
	
	If Search.Found Then
		Return COMJoin.Selection.Start;
	EndIf;
	
	Return -1;

	
EndFunction

Function PageParametersSettings()
	
	SettingsArray = New Array;
	SettingsArray.Add("Orientation");
	SettingsArray.Add("TopMargin");
	SettingsArray.Add("BottomMargin");
	SettingsArray.Add("LeftMargin");
	SettingsArray.Add("RightMargin");
	SettingsArray.Add("Gutter");
	SettingsArray.Add("HeaderDistance");
	SettingsArray.Add("FooterDistance");
	SettingsArray.Add("PageWidth");
	SettingsArray.Add("PageHeight");
	SettingsArray.Add("FirstPageTray");
	SettingsArray.Add("OtherPagesTray");
	SettingsArray.Add("SectionStart");
	SettingsArray.Add("OddAndEvenPagesHeaderFooter");
	SettingsArray.Add("DifferentFirstPageHeaderFooter");
	SettingsArray.Add("VerticalAlignment");
	SettingsArray.Add("SuppressEndnotes");
	SettingsArray.Add("MirrorMargins");
	SettingsArray.Add("TwoPagesOnOne");
	SettingsArray.Add("BookFoldPrinting");
	SettingsArray.Add("BookFoldRevPrinting");
	SettingsArray.Add("BookFoldPrintingSheets");
	SettingsArray.Add("GutterPos");
	
	Return SettingsArray;
	
EndFunction

Function EventLogEvent()
	Return NStr("en = 'Print';", CommonClient.DefaultLanguageCode());
EndFunction

Procedure FailedToGeneratePrintForm(ErrorInfo)
#If WebClient Or MobileClient Then
	ClarificationText = NStr("en = 'Use thin client to generate this print from.';");
#Else		
	ClarificationText = NStr("en = 'To output print forms in MS Word formats, Microsoft Office must be installed.';");
#EndIf
	ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot generate print form: %1.
			|%2';"),
		ErrorProcessing.BriefErrorDescription(ErrorInfo), ClarificationText);
	Raise ExceptionText;
EndProcedure

Procedure Replace(Object, Val SearchString, Val ReplacementString)
	
	SearchString = "{v8 " + SearchString + "}";
	ReplacementString = String(ReplacementString);
	
	Object.Select();
	Selection = Object.Application.Selection;
	
	FindObject = Selection.Find;
	FindObject.ClearFormatting();
	While FindObject.Execute(SearchString) Do
		If IsBlankString(ReplacementString) Then
			Selection.Delete();
		ElsIf IsTempStorageURL(ReplacementString) Then
			Selection.Delete();
			TempDirectory = PrintManagementInternalClient.CreateTemporaryDirectory("MSWord");
#If WebClient Then
			TempFileName = TempDirectory + String(New UUID) + ".tmp";
#Else
			TempFileName = GetTempFileName("tmp");
#EndIf
			
			FilesDetails1 = New Array;
			FilesDetails1.Add(New TransferableFileDescription(TempFileName, ReplacementString));
			If GetFiles(FilesDetails1, , TempDirectory, False) Then // 
				Selection.Range.InlineShapes.AddPicture(TempFileName);
			Else
				Selection.TypeText("");
			EndIf;
		Else
			Selection.TypeText(ReplacementString);
		EndIf;
	EndDo;
	
	Selection.Collapse();
	
EndProcedure

#EndRegion
