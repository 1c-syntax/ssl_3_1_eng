///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var FormClosing;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IntegrationDetails = Undefined;
	
	If Parameters.Id <> Undefined Then
	
		IntegrationDetails = CollaborationSystem.GetIntegration(Parameters.Id);
		If IntegrationDetails <> Undefined Then
			
			Description = IntegrationDetails.Presentation;
			EndpointURL = IntegrationDetails.EndpointURL;
			
			Attendees.Clear();
			For Each IBUser In Conversations.InfoBaseUsers(IntegrationDetails.Members) Do
				Attendees.Add().User = IBUser.Value;
			EndDo;
				
			IsIntegrationUsed = IntegrationDetails.Use;
			If IsIntegrationUsed Then
				Items.Close.Title = NStr("en = 'Save and close';");
				Items.Disconnect.Visible = True;
			EndIf;

		EndIf;
		
	EndIf;
	
	ConversationsLocalization.OnFillInstructionOnIntegrationConnect(Items.Instruction.Title, 
	ConversationsInternalClientServer.ExternalSystemsTypes().WebChat);
	
	FillWebChatIntegrationParameters(IntegrationDetails);
	RefreshPreview();
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
	For Each Parameter In DisplayParameters Do
		UpdatePreviewOrientationParameters(Parameter);
		UpdateParameterPresentationByValue(Parameter);		
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If FormClosing = True And Not Exit Then
		Close(True);
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PreviewDocumentComplete(Item)
	
	UpdatePreviewParameters();
	
	PageObject = Items.Preview.Document.defaultView;
	PageObject.initString("today", 				NStr("en = 'Today';"));
	PageObject.initString("administrator",		NStr("en = 'Administrator';"));
	PageObject.initString("text1", 				NStr("en = 'Hi, what can I do for you?';"));
	PageObject.initString("text2", 				NStr("en = 'Hi, I would like to integrate your service into my website.';"));
	PageObject.initString("time", 				NStr("en = '14:53';"));
	PageObject.initString("textareaTooltip", 	NStr("en = 'Enter your message…';"));
	PageObject.initString("attachFileTooltip", 	NStr("en = 'Attach file';"));
	
	// ACC:1036-off - Domain-specific terminology.
	PageObject.initString("videoCallTooltip", 	NStr("en = 'Video call';"));
	// ACC:1036-on
	
	PageObject.initString("closeTooltip",		NStr("en = 'Close';"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttendees

&AtClient
Procedure ExternalParametersOnChange(Item)
	
	UpdatePreviewParameters();

	If FormClosing = True Then
		Items.Close.Title = NStr("en = 'Save and close';");
		IsIntegrationUsed = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalParametersOnRowActivation(Item)
	
	UpdateCurrentDataPresentation();
	
EndProcedure

&AtClient
Procedure AttendeesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	For Each PickedUser In ValueSelected Do
		If Attendees.FindRows(New Structure("User", PickedUser)).Count() = 0 Then
			Attendees.Add().User = PickedUser;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ExternalParametersValuePresentationOnChange(Item)

	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData.Type = "Color" Then
		CurrentData.ValuePresentation = CurrentData.ValuePresentation.GetAbsolute();
	EndIf;
	
	UpdateParameterValueByPresentation(CurrentData);

EndProcedure

&AtClient
Procedure ExternalParametersValuePresentationStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData.Name = "signKey" Then
		
		StandardProcessing = False;                        
		
		CurrentData.ValuePresentation = GenerateRandomKey();
		UpdateParameterValueByPresentation(CurrentData); 
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	ConversationsInternalClient.StartPickingConversationParticipants(Items.Attendees);
EndProcedure

&AtClient
Procedure ActivateBot(Command)
	
	If FormClosing = True Then
		Close(True);
		Return;
	EndIf;
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Try
		ActivateServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("en = 'Cannot enable the chat bot due to:';"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	If IsIntegrationUsed Then
		Close(True);
		Return;		
	EndIf;
	
	Items.Close.Title = NStr("en = 'Close';");
	FormClosing = True;
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	Try
		DisconnectServer();
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("en = 'Cannot disable the chat bot due to:';"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	Close(True);
EndProcedure

&AtClient
Procedure SaveWebPageFile(Command)

	MessageText = NStr("en = 'To save the file, install 1C:Enterprise Extension.';");
	
	NotifyDescription = New CallbackDescription("SaveWebPageFileFollowUp", ThisObject);
	FileSystemClient.Attach1CEnterpriseExtension(NotifyDescription, MessageText);

EndProcedure

#EndRegion

#Region Private

&AtClient
Async Procedure SaveWebPageFileFollowUp(FileSystemExtensionAttached1, AdditionalParameters) Export
	
	If Not FileSystemExtensionAttached1 Then
		Return;
	EndIf;  

	FileDialog = New FileDialog(FileDialogMode.Save);
	FileDialog.Title = NStr("en = 'Save file';");
	FileDialog.Filter = NStr("en = 'HTML files (*.html)|*.html|All files  (*.*)|*.*';");
	
	SelectedFiles = Await FileDialog.ChooseAsync();
	If SelectedFiles = Undefined Then
		Return;
	EndIf;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(WebPageFileContent());
	
	Try
		RecordingResult =  Await TextDocument.WriteAsync(SelectedFiles[0]);	
	Except
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, 
			NStr("en = 'Couldn''t save the file due to:';"), True);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	If RecordingResult = True Then
		
		Explanation = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'File saved to %1';"), 
			SelectedFiles[0]);
		
		AdditionalParameters = New Structure("FileName", SelectedFiles[0]);
		NotifyDescription = New CallbackDescription("SaveWebPageFileOpenFileDirectory",
			ThisObject, AdditionalParameters);
		
		ShowUserNotification(NStr("en = 'Save file';"), NotifyDescription, Explanation, 
			PictureLib.Information32);
		
	EndIf;

EndProcedure

&AtClient
Procedure SaveWebPageFileOpenFileDirectory(AdditionalParameters) Export

	FileSystemClient.OpenExplorer(AdditionalParameters.FileName);
	
EndProcedure

&AtClient
Function WebPageFileContent()
	
	FileContent = "<!doctype html>
		|<html lang=""ru"">
		|<head>
  		|	<meta charset=""utf-8"" />
  		|	<title></title>
		|</head>
		|<body>
    	|	<script src=""%1"" async></script> 
		|</body>
		|</html>";
	
	ConnectionPointPresentation = NStr("en = 'Insert connection point';");
	
	ReplaceSubstring = ?(IsBlankString(EndpointURL), 
		ConnectionPointPresentation, EndpointURL);
		
	Return StrTemplate(FileContent, ReplaceSubstring);
		
EndFunction

&AtServer
Procedure ActivateServer()
	
	IntegrationParameters = ConversationsInternal.IntegrationParameters();
	IntegrationParameters.Id = Parameters.Id;
	IntegrationParameters.Key = Description; 
	IntegrationParameters.Type = ConversationsInternalClientServer.ExternalSystemsTypes().WebChat;
	IntegrationParameters.Attendees = Attendees.Unload(, "User").UnloadColumn("User");
	
	For Each ExternalParameter In DisplayParameters Do
		IntegrationParameters.Insert(ExternalParameter.Name, ExternalParameter.Value);
	EndDo;
	
	Try
		IntegrationDetails = ConversationsInternal.CreateChangeIntegration(IntegrationParameters);
		// Collaboration System requires a secondary call.
		Integration = CollaborationSystem.GetIntegration(IntegrationDetails.ID)
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
			EventLogLevel.Error, , ,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	If Integration <> Undefined Then
		EndpointURL = Integration.EndpointURL;
		Parameters.Id = Integration.ID;
	EndIf;
	
EndProcedure

&AtServer
Procedure DisconnectServer()
	ConversationsInternal.DisableIntegration(Parameters.Id);
EndProcedure

#Region WebChatParameters

&AtServer
Procedure FillWebChatIntegrationParameters(IntegrationDetails = Undefined)
	
	If Not Conversations.ConversationsAvailable() Then
		Return;
	EndIf;
	
	ExternalSystemType = ConversationsInternalClientServer.ExternalSystemsTypes().WebChat;
	
	Try
		ExternalSystemDetails = CollaborationSystem.GetExternalSystemDescription(ExternalSystemType);	
	Except
		WriteLogEvent(ConversationsInternal.EventLogEvent(),
		EventLogLevel.Error, , ,
		ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
	DisplayParameters.Clear();

	For Each ExternalSystemParameter In ExternalSystemDetails.ParametersDescriptions Do
		WebChatParameter = DisplayParameters.Add();
		WebChatParameter.Name = ExternalSystemParameter.Name;
	EndDo;
	
	If IntegrationDetails <> Undefined Then

		For Each Parameter In IntegrationDetails.ExternalSystemParameters Do
			
			Filter = New Structure("Name", Parameter.Key);
			FoundRows = DisplayParameters.FindRows(Filter);
			
			If FoundRows.Count() = 0 Then
				ExternalParameter = DisplayParameters.Add();
				ExternalParameter.Name = Parameter.Key;
			Else
				ExternalParameter = FoundRows[0];
			EndIf;
			
			ExternalParameter.Value = Parameter.Value;
			
		EndDo;
		
	EndIf;

	For Each WebChatParameter In DisplayParameters Do
		FillParameterData(WebChatParameter);
	EndDo;
		
EndProcedure

&AtClient
Procedure UpdatePreviewOrientationParameters(WebChatParameter)
	
	If WebChatParameter.Name = "orientation" Or WebChatParameter.Name = "orientationPadding" Then
		UpdateOrientationPadding();	
	EndIf;

EndProcedure

&AtClient
Procedure UpdateOrientationPadding()
	
	Filter = New Structure("Name", "orientation");
	FoundRows = DisplayParameters.FindRows(Filter);
	
	If Not FoundRows.Count() Then
		Return;
	EndIf;
	
	OrientationParameter = FoundRows[0];
	
	Filter = New Structure("Name", "orientationPadding");
	FoundRows = DisplayParameters.FindRows(Filter); 
	
	If Not FoundRows.Count() Then
		Return;
	EndIf;
	
	IndentParameter = FoundRows[0];
	
	If OrientationParameter.Value = "bottom" Then
		IndentParameter.ValueList.Clear();
		IndentParameter.ValueList.Insert("_0",	NStr("en = 'Left';"));
		IndentParameter.ValueList.Insert("_50", 	NStr("en = 'Center';"));
		IndentParameter.ValueList.Insert("_100", NStr("en = 'Right';"));
	ElsIf OrientationParameter.Value = "left" Or OrientationParameter.Value = "right" Then
		IndentParameter.ValueList.Clear();
		IndentParameter.ValueList.Insert("_100", NStr("en = 'Top';"));
		IndentParameter.ValueList.Insert("_50", 	NStr("en = 'Center';"));
		IndentParameter.ValueList.Insert("_0", 	NStr("en = 'Bottom';"));
	EndIf;       
	
	UpdateParameterPresentationByValue(IndentParameter);
	
EndProcedure

&AtClient
Procedure UpdatePreviewParameters()
	
	WebPagePreviewWindow = Items.Preview.Document.defaultView;
	
	For Each DisplayParameter In DisplayParameters Do
		WebPagePreviewWindow.updatePreview(DisplayParameter.Name, DisplayParameter.Value);
	EndDo;  
	
EndProcedure

&AtClient
Procedure UpdateCurrentDataPresentation()
	
	CurrentData = Items.ExternalParameters.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;  
	
	ParameterValue = Items.ExternalParametersValuePresentation;
	ParameterValue.TypeRestriction = New TypeDescription(CurrentData.Type);
	
	If CurrentData.ChoiceButton <> Undefined Then
		ParameterValue.ChoiceButton = True;
		ParameterValue.ChoiceButtonPicture = CurrentData.ChoiceButton;
	Else
		ParameterValue.ChoiceButton = False;		
	EndIf;

	ParameterValue.ChoiceList.Clear();
	
	If CurrentData.ValueList <> Undefined Then
		ParameterValue.ListChoiceMode = True;
		For Each Value In CurrentData.ValueList Do
			ParameterValue.ChoiceList.Add(Value.Value);
		EndDo; 
	Else
		ParameterValue.ListChoiceMode = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ConvertHexToDec(Number)
	
	Dictionary = "0123456789ABCDEF";
	Result = 0;
	
	ItemCountInNumber = StrLen(Number);
	
	For Position = 1 To ItemCountInNumber Do
		Result = Result + ((StrFind(Dictionary, Mid(Number, Position, 1)) - 1) * Pow(16, ItemCountInNumber - Position));
	EndDo;
	
	Return Result; 
	
EndFunction

&AtClientAtServerNoContext
Function ConvertDecToHex(Number)
	
	Dictionary = "0123456789ABCDEF";
	
	Term1 = Int(Number / 16);
	Term2 = Number - (Term1 * 16);
	
	Return Mid(Dictionary, Term1 + 1, 1) + Mid(Dictionary, Term2 + 1, 1); 
	
EndFunction

&AtServer
Procedure FillParameterData(WebChatParameter)
	
	If WebChatParameter.Name = "allowVideoconferences" Then
		
		WebChatParameter.Presentation = NStr("en = 'Video calls';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "allowed";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("allowed", NStr("en = 'Available';"));
		WebChatParameter.ValueList.Insert("allowedToWebChatOnly", NStr("en = 'Available for chat only';"));
		WebChatParameter.ValueList.Insert("disallowed", NStr("en = 'Unavailable';"));  
			
	ElsIf WebChatParameter.Name = "defaultApplicationUserCameraState" Then
		
		WebChatParameter.Presentation = NStr("en = 'Default application camera status';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "on";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("on", NStr("en = 'Enabled';"));
		WebChatParameter.ValueList.Insert("off", NStr("en = 'Disabled';"));
			
	ElsIf WebChatParameter.Name = "signKey" Then
		
		WebChatParameter.Presentation = NStr("en = 'Signature key';");
		WebChatParameter.Type = "String";
		WebChatParameter.ChoiceButton = PictureLib.Reread;
		
	ElsIf WebChatParameter.Name = "orientation" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat position';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "bottom";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("left", NStr("en = 'Left';"));
		WebChatParameter.ValueList.Insert("bottom", NStr("en = 'Bottom';"));
		WebChatParameter.ValueList.Insert("right", NStr("en = 'Right';"));
		
	ElsIf WebChatParameter.Name = "orientationPadding" Then 
		
		WebChatParameter.Presentation = NStr("en = 'Chat alignment';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "100";
		
		WebChatParameter.ValueList = New Structure;
		
	ElsIf WebChatParameter.Name = "mobileButtonOrientation" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat button orientation in mobile version';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "rightBottom";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("leftBottom", NStr("en = 'Bottom left';"));
		WebChatParameter.ValueList.Insert("rightBottom", NStr("en = 'Bottom right';"));
		
	ElsIf WebChatParameter.Name = "colorTheme" Then
		
		WebChatParameter.Presentation = NStr("en = 'Color mode';");
		WebChatParameter.Type = "String";
		WebChatParameter.StandardValue = "auto";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("auto", NStr("en = 'Auto';"));
		WebChatParameter.ValueList.Insert("light", NStr("en = 'Light';"));
		WebChatParameter.ValueList.Insert("dark", NStr("en = 'Dark';"));
			
	ElsIf WebChatParameter.Name = "titleText" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat title';");
		WebChatParameter.Type = "String";
		
	ElsIf WebChatParameter.Name = "titleBackColor" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat background color';");
		WebChatParameter.Type = "Color";
		WebChatParameter.StandardValue = "#FBED9E";
		WebChatParameter.ChoiceButton = PictureLib.InputFieldSelect;
		
	ElsIf WebChatParameter.Name = "titleTextColor" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat title font color';");
		WebChatParameter.Type = "Color";
		WebChatParameter.StandardValue = "#333333";
		WebChatParameter.ChoiceButton = PictureLib.InputFieldSelect;
		
	ElsIf WebChatParameter.Name = "displayUserPictures" Then
		
		WebChatParameter.Presentation = NStr("en = 'Show profile pictures';");
		WebChatParameter.Type = "Boolean";
		WebChatParameter.StandardValue = "true";
		
		WebChatParameter.ValueList = New Structure;
		WebChatParameter.ValueList.Insert("true", True);
		WebChatParameter.ValueList.Insert("false", False);
		
	ElsIf WebChatParameter.Name = "languageCode" Then
		
		WebChatParameter.Presentation = NStr("en = 'Chat language code';");
		WebChatParameter.Type = "String"; 
		
		LocalizationList = AvailableLocales();
		If LocalizationList.FindByValue(CurrentLocaleCode()) <> Undefined Then
			WebChatParameter.StandardValue = CurrentLocaleCode();
		ElsIf LocalizationList.FindByValue(CurrentSystemLanguage()) <> Undefined Then
			WebChatParameter.StandardValue = CurrentSystemLanguage();
		Else
			WebChatParameter.StandardValue = "en";
		EndIf;    

		WebChatParameter.ValueList = New Structure;
		For Each LocaleItem In LocalizationList Do
			WebChatParameter.ValueList.Insert(LocaleItem.Value, LocaleItem.Presentation);
		EndDo;

	Else
		
		WebChatParameter.Presentation = WebChatParameter.Name;
		WebChatParameter.Type = "String";
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function AvailableLocales()
	
	LocalizationList = New ValueList;
	For Each LocalizationCode In GetAvailableLocaleCodes() Do
		LocalizationList.Add(LocalizationCode, LocaleCodePresentation(LocalizationCode));
	EndDo;
	LocalizationList.SortByPresentation(SortDirection.Asc);
	Return LocalizationList;
		
EndFunction

&AtServer
Procedure RefreshPreview()
	
	Preview = DataProcessors.EnableDiscussions.GetTemplate("WebChatDisplayTemplate").GetText()
	
EndProcedure

&AtClient
Procedure UpdateParameterPresentationByValue(WebChatParameter)
	
	If WebChatParameter.Value = "" And WebChatParameter.StandardValue <> "" Then
		WebChatParameter.Value = WebChatParameter.StandardValue;
	EndIf;
	
	Presentation = Undefined;
	
	If WebChatParameter.Value <> "" Then	
		
		If WebChatParameter.ValueList <> Undefined Then	
			
			FirstCharCode = CharCode(WebChatParameter.Value, 1);
			ValueKey = ?(48 <= FirstCharCode And FirstCharCode <= 57, "_" + WebChatParameter.Value, WebChatParameter.Value);
			
			Presentation = Undefined;
			WebChatParameter.ValueList.Property(ValueKey, Presentation);
			
			If Presentation <> Undefined Then	
				WebChatParameter.ValuePresentation = Presentation;
			EndIf;  
			
		EndIf; 
		
	EndIf;
	
	If Presentation = Undefined Then
		
		If WebChatParameter.Type = "String" Then
			WebChatParameter.ValuePresentation = WebChatParameter.Value;
		ElsIf WebChatParameter.Type = "Boolean" Then
			WebChatParameter.ValuePresentation = Boolean(WebChatParameter.Value);
		ElsIf WebChatParameter.Type = "Number" Then
			WebChatParameter.ValuePresentation = Number(WebChatParameter.Value);
		ElsIf WebChatParameter.Type = "Color" Then
			WebChatParameter.ValuePresentation = ColorFromText(WebChatParameter.Value);
		EndIf; 
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure UpdateParameterValueByPresentation(WebChatParameter)
	
	If WebChatParameter.ValueList <> Undefined Then		
		
		For Each ListItem In WebChatParameter.ValueList Do
			If ListItem.Value = WebChatParameter.ValuePresentation Then
				WebChatParameter.Value = ?(Mid(ListItem.Key, 1, 1) = "_", Mid(ListItem.Key, 2), ListItem.Key);	
			EndIf;
		EndDo;
		
	Else
		
		If WebChatParameter.Type = "String" Then
			WebChatParameter.Value = WebChatParameter.ValuePresentation;
		ElsIf WebChatParameter.Type = "Boolean" Or WebChatParameter.Type = "Number" Then
			WebChatParameter.Value = String(WebChatParameter.ValuePresentation);
		ElsIf WebChatParameter.Type = "Color" Then
			RGBColor = WebChatParameter.ValuePresentation.GetAbsolute();
			WebChatParameter.Value = "#" + ConvertDecToHex(RGBColor.R) 
				+ ConvertDecToHex(RGBColor.G) + ConvertDecToHex(RGBColor.B);
		EndIf;  
		
	EndIf;
	
	UpdatePreviewOrientationParameters(WebChatParameter); 
	
EndProcedure

&AtClientAtServerNoContext
Function ColorFromText(Text)
	
	Red = 0;
	Green = 0;
	B 	= 0;
	
	If Mid(Text, 1, 1) = "#" Then
		Red = ConvertHexToDec(Upper(Mid(Text, 2, 2)));
		Green = ConvertHexToDec(Upper(Mid(Text, 4, 2)));
		B 	= ConvertHexToDec(Upper(Mid(Text, 6, 2)));
	EndIf; 
	
	Return New Color(Red, Green, B);
	
EndFunction

&AtServerNoContext
Function GenerateRandomKey()
	
	NewKey = "";
	RNG = New RandomNumberGenerator(); 
	
	For Cnt = 1 To 32 Do
		RandomNumber = RNG.RandomNumber(0, 255);
		NewKey = NewKey + ConvertDecToHex(RandomNumber);
	EndDo;

	Return NewKey;
	
EndFunction

#EndRegion

#EndRegion
