///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NameOfFirstUpdateFile = Parameters.NameOfFirstUpdateFile;
	Metadata_Version = Metadata.Version;
	
	If InfobaseUpdateInternal.DeferredUpdateCompleted()
	 Or Not ValueIsFilled(NameOfFirstUpdateFile)
	   And Not ConfigurationChanged() Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(NameOfFirstUpdateFile) Then
		ImportFile_();
	Else
		Result = False;
	#If Not WebClient And Not MobileClient Then
		Try
			Result = OnlyBuildNumberOfMainConfigurationHasChanged();
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteError(ErrorText);
		EndTry;
	#EndIf
		Close(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#If Not WebClient And Not MobileClient Then

&AtClient
Function OnlyBuildNumberOfMainConfigurationHasChanged()
	
	PathToTemporaryFolder = GetTempFileName() + "\";
	ListFileName    = PathToTemporaryFolder + "ConfigFiles.txt";
	MessagesFileName = PathToTemporaryFolder + "Out.txt";
	
	CreateDirectory(PathToTemporaryFolder);
	
	TextDocument = New TextDocument;
	TextDocument.SetText("Configuration");
	TextDocument.Write(ListFileName);
	
	SystemParameters = New Array;
	SystemParameters.Add("DESIGNER");
	SystemParameters.Add("/DisableStartupMessages");
	SystemParameters.Add("/DisableStartupDialogs");
	SystemParameters.Add("/DumpConfigToFiles");
	SystemParameters.Add("""" + PathToTemporaryFolder + """");
	SystemParameters.Add("-listfile");
	SystemParameters.Add("""" + ListFileName + """");
	SystemParameters.Add("/Out");
	SystemParameters.Add("""" + MessagesFileName + """");
	
	ReturnCode = 0;
	RunSystem(StrConcat(SystemParameters, " "), True, ReturnCode);
	
	If ReturnCode <> 0 Then
		TextDocument = New TextDocument;
		TextDocument.Read(MessagesFileName);
		DeleteFiles(PathToTemporaryFolder);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot dump the configuration to files due to:
			           |%1';"),
			"ReturnCode" + " = " + String(ReturnCode) + "
			|" + TextDocument.GetText());
		Raise ErrorText;
	EndIf;
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	XMLReader.OpenFile(PathToTemporaryFolder + "Configuration.xml");
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	DeleteFiles(PathToTemporaryFolder);
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'A version is not found in the %1 dump file';"),
		"Configuration.xml");
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	XPathExpression = "/xmlns:MetaDataObject/xmlns:Configuration/xmlns:Properties/xmlns:Version";
	XPathResult = DOMDocument.EvaluateXPathExpression(XPathExpression, DOMDocument, Dereferencer);
	If Not XPathResult.InvalidIteratorState Then
		NextNode = XPathResult.IterateNext();
		If TypeOf(NextNode) = Type("DOMElement")
		   And Upper(NextNode.TagName) = Upper("Version") Then
			Version = NextNode.TextContent;
			If StrSplit(Version, ".", False).Count() < 4 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Incorrect version ""%1"" in the %2 dump file';"),
					Version, "Configuration.xml");
			Else
				Return CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata_Version)
				      = CommonClientServer.ConfigurationVersionWithoutBuildNumber(Version);
			EndIf;
		EndIf;
	EndIf;
	
	Raise ErrorText;
	
EndFunction

#EndIf
&AtClient
Procedure ImportFile_()
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	
	Notification = New NotifyDescription("AfterUploadingFile", ThisObject);
	FileSystemClient.ImportFile_(Notification, ImportParameters, NameOfFirstUpdateFile);
	
EndProcedure

&AtClient
Procedure AfterUploadingFile(ImportedFile, Context) Export
	
	If ValueIsFilled(ImportedFile)
	   And ValueIsFilled(ImportedFile.Name)
	   And ValueIsFilled(ImportedFile.Location)
	   And OnlyBuildNumberHasChanged(ImportedFile.Location, ImportedFile.Name) Then
		
		Result = True;
	Else
		Result = False;
	EndIf;
	
	If IsOpen() Then
		Close(Result);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function OnlyBuildNumberHasChanged(AddressInTempStorage, FullFileName)
	
	Try
		BinaryData = GetFromTempStorage(AddressInTempStorage);
		DeleteFromTempStorage(AddressInTempStorage);
		If TypeOf(BinaryData) <> Type("BinaryData") Then
			Return False;
		EndIf;
	
		If StrEndsWith(FullFileName, ".cfu") Then
			UpdateDetails1 = New ConfigurationUpdateDescription(BinaryData);
			ConfigurationDescription = UpdateDetails1.TargetConfiguration;
		Else
			ConfigurationDescription = New ConfigurationDescription(BinaryData);
		EndIf;
		OnlyBuildNumberHasChanged =
			  CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata.Version)
			= CommonClientServer.ConfigurationVersionWithoutBuildNumber(ConfigurationDescription.Version);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteError(ErrorText);
		OnlyBuildNumberHasChanged = False;
	EndTry;
	
	Return OnlyBuildNumberHasChanged;
	
EndFunction

&AtServerNoContext
Procedure WriteError(ErrorText)
	
	ErrorTitle = NStr("en = 'Cannot get the new configuration version due to:';") + Chars.LF;
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(),
		EventLogLevel.Error,,, ErrorTitle + ErrorText);
	
EndProcedure

#EndRegion
