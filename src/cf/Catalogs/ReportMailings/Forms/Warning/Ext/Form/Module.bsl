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
	
	SetHeader();
	SetDescription();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToDocumentation(Command)
	
	ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
	ModuleEmailOperationsClient.GoToEmailAccountInputDocumentation();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetHeader()
	
	TitleText = Parameters.Title;
	If ValueIsFilled(TitleText) Then 
		Title = TitleText;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetDescription()
	
	Items.GoToDocumentation.Visible =
		Common.SubsystemExists("StandardSubsystems.EmailOperations")
		And ValueIsFilled(Parameters.More)
		And CommonClientServer.StructureProperty(Parameters, "UseEmail", False);
	
	If Not ValueIsFilled(Parameters.Text) Then 
		Return;
	EndIf;
	
	Text.Add(Parameters.Text, Type("FormattedDocumentText"));

	If ValueIsFilled(Parameters.More) Then 
		Text.Add(, Type("FormattedDocumentLinefeed"));
		Text.Add(, Type("FormattedDocumentLinefeed"));
		Text.Add(Parameters.More, Type("FormattedDocumentText"));
		Items.Indicator.Picture = PictureLib.DialogExclamation;
	EndIf;
	
	SetAuthenticationErrorDescription(Parameters);
	
EndProcedure

&AtServer
Procedure SetAuthenticationErrorDescription(LongDesc)
	
	If StrFind(Upper(LongDesc.More), "USERNAME AND PASSWORD NOT ACCEPTED") = 0 Then 
		Return;
	EndIf;
	
	Text.Add(, Type("FormattedDocumentLinefeed"));
	Text.Add(, Type("FormattedDocumentLinefeed"));
	
	If ValueIsFilled(LongDesc.Ref) Then 
		StringPattern = NStr("en = 'Go to <a href = ""%1"">email account settings</a> to correct the username and password.';");
		URL = GetURL(LongDesc.Ref);
		String = StringFunctions.FormattedString(StringPattern, URL);
	Else
		String = NStr("en = 'Go to email account settings to correct the username and password.';");
	EndIf;
	
	Rows = New Array;
	Rows.Add(Text.GetFormattedString());
	Rows.Add(String);
	
	Text.SetFormattedString(New FormattedString(Rows));
	
EndProcedure

#EndRegion