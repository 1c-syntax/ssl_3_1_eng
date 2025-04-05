///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var Attachable_Module;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ClientID = Parameters.ClientID;
	UserScanSettings = FilesOperations.GetUserScanSettings(ClientID);
	FillPropertyValues(ThisObject, UserScanSettings);
	If DeviceName <> "" Then
		Items.DeviceName.ChoiceList.Add(DeviceName);
	EndIf;
	Items.ScanLogCatalog.Enabled = UseScanLogDirectory;
			
	MethodOfConversionToPDF = ?(UseImageMagickToConvertToPDF, 1, 0);
		
	JPGFormat = Enums.ScannedImageFormats.JPG;
	TIFFormat = Enums.ScannedImageFormats.TIF;
	
	MultiPageTIFFormat = Enums.MultipageFileStorageFormats.TIF;
	
	Items.GroupJPGQuantity.Visible = (ScannedImageFormat = JPGFormat);
	Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	
	InstallHints();
	
	Rescanning = Parameters.Rescanning;
	
	If Parameters.Rescanning Then
		Items.OK.Title = NStr("en = 'Scan'");
	EndIf;
	
	ScanJobParameters = Common.CommonSettingsStorageLoad("ScanAddIn", "ScanJobParameters", Undefined);
	
	Items.ScanningError.Visible = ScanJobParameters <> Undefined;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		ModuleForContactingTechnicalSupportService = Common.CommonModule(
			"ContactingTechnicalSupportInternal");
		
		ModuleForContactingTechnicalSupportService.OnCreateAtServer(ThisObject);
		
	Else
		Items.TechnicalSupportGroup.Visible = False;
	EndIf;
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If CommonClient.IsLinuxClient() Then
		AdaptForLinux();
		ShowScannerDialog = False;
	EndIf;
	RefreshStatus();
	ProcessScanDialogUsage();
	Items.ScanningError.Visible = Items.ScanningError.Visible And Not IsScanFormOpen();
	
	SetRecommendationText();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If ShowScannerDialog Then
		CheckedAttributes.Delete(CheckedAttributes.Find("Resolution"));
		CheckedAttributes.Delete(CheckedAttributes.Find("Chromaticity"));
	EndIf;
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "ScanSettingsChanged" Then
		FillPropertyValues(ThisObject, Parameter);
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DeviceNameOnChange(Item)
	ReadScannerSettings();
EndProcedure

&AtClient
Procedure DeviceNameChoiceProcessing(Item, ValueSelected, StandardProcessing)
	If DeviceName = ValueSelected Then // If nothing has changed, do not do anything.
		StandardProcessing = False;
	EndIf;	
EndProcedure

&AtClient
Procedure ScannedImageFormatOnChange(Item)
	
	Items.GroupJPGQuantity.Visible = (ScannedImageFormat = JPGFormat);
	Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	InstallHints();
	
EndProcedure

&AtClient
Procedure PathToConverterApplicationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
		
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName = PathToConverterApplication;
	Filter = NStr("en = 'Executable files (*.exe)|*.exe'");
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("en = 'Select file to convert to PDF'");
	If OpenFileDialog.Choose() Then
		PathToConverterApplication = OpenFileDialog.FullFileName;
	EndIf;
	
EndProcedure

&AtClient
Procedure MethodOfConversionToPDFOnChange(Item)
	
	UseImageMagickToConvertToPDF = MethodOfConversionToPDF = 1;
	ProcessChangesUseImageMagick();
	
EndProcedure

&AtClient
Procedure JPGQualityOnChange(Item)
	Items.JPGQuality.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Quality (%1)'"), JPGQuality);
EndProcedure

&AtClient
Procedure DeviceNameStartChoice(Item, StandardProcessing)
	Try
		DeviceArray = FilesOperationsInternalClient.EnumDevices(ThisObject, Attachable_Module);
	Except
		DeviceArray = New Array;
	EndTry;  
	
	If DeviceArray.Count() > 0 Then
		Item.ChoiceList.LoadValues(DeviceArray);
	Else
		StandardProcessing = False;
		ShowMessageBox(,NStr("en = 'No scanners were detected. Check the scanner connection.'"));
	EndIf;
EndProcedure 

&AtClient
Procedure ShowScannerDialogOnChange(Item)
	
	ProcessScanDialogUsage();
	
EndProcedure

&AtClient
Procedure ScanLogCatalogStartChoice(Item, ChoiceData, StandardProcessing)

	If Not FilesOperationsInternalClient.Is1CEnterpriseExtensionAttached() Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	OpenFileDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	OpenFileDialog.FullFileName = ScanLogCatalog;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("en = 'Select a path to save the scan log'");
	
	If OpenFileDialog.Choose() Then
		ScanLogCatalog = OpenFileDialog.Directory;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseScanLogDirectoryOnChange(Item)
	Items.ScanLogCatalog.Enabled = UseScanLogDirectory;
EndProcedure

&AtClient
Procedure RecommendationsURLProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "Run32BitClient" Then
		StandardProcessing = False;
		Run32BitClient();
	Else
		Expression = NStr("en = 'Действие для навигационной ссылки не определено.'");
		Raise(Expression, ErrorCategory.GotoURLError);
	EndIf;
	
EndProcedure

&AtClient
Procedure DescriptionOfSupportRequestURLProcessing(Item, Var_URL, StandardProcessing)
	
	// 
	If CommonClient.SubsystemExists("StandardSubsystems.ContactingTechnicalSupport") Then
		
		StandardProcessing = False;
		
		If Var_URL = "QuestionInSupport" Then
			
			CompletionHandler = New CallbackDescription(
				"ContinueSendingQuestionToSupport",
				ThisObject);
			
			If Not ValueIsFilled(ErrorPresentation) Then
				ErrorPresentation = NStr("en = 'Вызвана помощь из настроек сканирования.'");
			EndIf;
			
			FilesOperationsInternalClient.GenerateInformationForSupport(
				ErrorPresentation, 
				CompletionHandler);
			
		ElsIf Var_URL = "InformationToSendToSupport" Then
			
			CompletionHandler = New CallbackDescription(
				"ContinueDownloadingInformationToSendToSupport",
				ThisObject);
			
			If Not ValueIsFilled(ErrorPresentation) Then
				ErrorPresentation = NStr("en = 'Вызвана помощь из настроек сканирования.'");
			EndIf;
			
			FilesOperationsInternalClient.GenerateInformationForSupport(
				ErrorPresentation,
				CompletionHandler);
			
		Else
			
			Expression = NStr("en = 'Действие для навигационной ссылки не определено.'");
			Raise(Expression, ErrorCategory.GotoURLError);
			
		EndIf;
		
	EndIf;
	// 
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then 
		Return;
	EndIf;
		
	UserScanSettings = FilesOperationsClientServer.UserScanSettings();
	FillPropertyValues(UserScanSettings, ThisObject);
	
	If CommonClient.IsLinuxClient() Then
		UserScanSettings.PathToConverterApplication = "convert";
	EndIf;
	
	Context = New Structure;
	Context.Insert("UserScanSettings", UserScanSettings);
	Context.Insert("FillingCheckError", False);
	
	If UserScanSettings.UseScanLogDirectory Then
		If UserScanSettings.ScanLogCatalog = "" Then
			ErrorText = NStr("en = 'Path to scan log is not specified.'");
			CommonClient.MessageToUser(ErrorText, , "ScanLogCatalog");
			Context.FillingCheckError = True;
			Result = New Structure("Success", True);
			AfterScanDirAvailabilityChecked(Result, Context)
		Else
			Notification = New CallbackDescription("AfterScanDirAvailabilityChecked", ThisObject, Context);
			FilesOperationsInternalClient.CheckDirAvailability(Notification, UserScanSettings.ScanLogCatalog);
		EndIf;
	Else
		Result = New Structure("Success", True);
		AfterScanDirAvailabilityChecked(Result, Context);
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomizeStandardSettings(Command)
	ReadScannerSettings();
EndProcedure

&AtClient
Procedure OpenScannedFilesNumbers(Command)
	OpenForm("InformationRegister.ScannedFilesNumbers.ListForm");
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ContinueSendingQuestionToSupport(Result, AdditionalParameters) Export
	
	// 
	ModuleForContactingTechnicalSupportServiceClient = CommonClient.CommonModule(
		"ContactingTechnicalSupportInternalClient");
	
	RequestParameters_ = ModuleForContactingTechnicalSupportServiceClient.RequestParameters_();
	RequestParameters_.TechnologicalInfo = Result.TechnologicalInfo;
	RequestParameters_.AdditionalFiles = Result.AdditionalFiles;
	RequestParameters_.Subject = NStr("en = 'Проблема при настройке сканирования'");
	
	ModuleForContactingTechnicalSupportServiceClient.SendQuestionToSupport(
		ThisObject,
		RequestParameters_);
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtClient
Procedure ContinueDownloadingInformationToSendToSupport(Result, AdditionalParameters) Export
	
	// 
	ModuleForContactingTechnicalSupportServiceClient = CommonClient.CommonModule(
		"ContactingTechnicalSupportInternalClient");
	
	RequestParameters_ = ModuleForContactingTechnicalSupportServiceClient.RequestParameters_();
	RequestParameters_.TechnologicalInfo = Result.TechnologicalInfo;
	RequestParameters_.AdditionalFiles = Result.AdditionalFiles;
	
	ModuleForContactingTechnicalSupportServiceClient.DownloadInformationToSendToSupport(
		ThisObject,
		RequestParameters_);
	// End StandardSubsystems.ContactingTechnicalSupport
	
EndProcedure

&AtClient
Procedure SetRecommendationText()
	
	Recommendations = New Array;
	
	Recommendations.Add(NStr("en = 'Попробуйте следующие варианты:'"));
	Recommendations.Add(" • " + NStr("en = 'Проверьте подключение сканера и повторите попытку сканирования.'"));
	
	If Not ShowScannerDialog And Not CommonClient.IsLinuxClient() Then
		Recommendation = " • " + NStr("en = 'Switch to the <b>advanced settings</b>.'");
		Recommendations.Add(Recommendation);
	EndIf;
	
	ImageResolution = PredefinedValue("Enum.ScannedImageResolutions.dpi1200");
	If ShowScannerDialog Or Resolution = ImageResolution Then
		Recommendations.Add(" • " + NStr("en = 'Снизьте разрешение сканирования до <b>600 dpi</b>.'"));
	EndIf;
	
	SystemInfo = New SystemInfo();
	If SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		Template = " • " + NStr(
			"en = 'Установите и запустите <a href = ""%1"">тонкий клиент 1С:Предприятия для Windows (32-bit)</a>,
			|   в котором доступно больше устройств и настроек сканирования.'");
		Recommendation = StringFunctionsClientServer.SubstituteParametersToString(Template, "Run32BitClient");
		Recommendations.Add(Recommendation);
	EndIf;
	
	Items.Recommendations.Title = StringFunctionsClient.FormattedString(
		StrConcat(Recommendations, Chars.LF));
	
EndProcedure

&AtClient
Procedure Run32BitClient()
	
#If Not WebClient Then
	
	BinDir32 = StrReplace(BinDir(), "\Program Files\", "\Program Files (x86)\");
	ApplicationName = BinDir32 + "1cv8.exe";
	AppFile = New File(ApplicationName);
	If AppFile.Exists() Then 
		FileSystemClient.StartApplication(ApplicationName);
	Else
		SystemInfo = New SystemInfo();
		FileSystemClient.OpenURL(
			"https://releases.1c.ru/version_files?nick=Platform83&ver=" + SystemInfo.AppVersion);
	EndIf;
	
#EndIf
	
EndProcedure

&AtClient
Procedure RefreshStatus()
	
	Items.JPGQuality.Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Quality (%1)'"), JPGQuality);
	Items.ScannedImageFormat.Enabled = False;
	Items.Resolution.Enabled = False;
	Items.Chromaticity.Enabled = False;
	Items.Rotation.Enabled = False;
	Items.PaperSize.Enabled = False;
	Items.DuplexScanning.Enabled = False;
	Items.DocumentAutoFeeder.Enabled = False;
	Items.CustomizeStandardSettings.Enabled = False;
	Items.ConvertToPDF.Enabled = False;
	Items.JPGQuality.Enabled = False;
	Items.TIFFDeflation.Enabled = False;
	Items.MultipageStorageFormat.Enabled = False;
	Items.MethodOfConversionToPDF.Enabled = False;
	Items.ShowScannerDialog.Enabled = False;
	
	NotifyDescription = New CallbackDescription("UpdateStateAfterInitialization", ThisObject);
	FilesOperationsInternalClient.InitAddIn(NotifyDescription, True);
EndProcedure

&AtClient
Procedure UpdateStateAfterInitialization(InitializationCheckResult, Context) Export
	Attachable_Module = InitializationCheckResult.Attached;
	
	If Not Attachable_Module Then
		Items.DeviceName.Enabled = False;
		Return;
	EndIf;
	Attachable_Module = InitializationCheckResult.Attachable_Module;
		
	If Not FilesOperationsInternalClient.IsReadyForScanning(ThisObject, Attachable_Module) Then
		Items.DeviceName.InputHint = NStr("en = 'Check scanner connection'");
		Return;
	Else
		Items.DeviceName.InputHint = "";
	EndIf;
		
	If IsBlankString(DeviceName) Then
		Return;
	EndIf;
	
	ReadScannerSettingsAndUpdateValues(False);
	
EndProcedure

&AtClient
Procedure ReadScannerSettings()
	Modified = True;
	Items.DuplexScanning.Enabled = False;
	Items.DocumentAutoFeeder.Enabled = False;
	
	If IsBlankString(DeviceName) Then
		Items.Rotation.Enabled = False;
		Items.PaperSize.Enabled = False;
		Return;
	EndIf;

	ReadScannerSettingsAndUpdateValues(True);
	
EndProcedure

&AtClient
Procedure ReadScannerSettingsAndUpdateValues(ShouldUpdateValues)

	Items.ScannedImageFormat.Enabled = True;
	Items.Resolution.Enabled = True;
	Items.Chromaticity.Enabled = True;
	Items.CustomizeStandardSettings.Enabled = True;
	Items.ConvertToPDF.Enabled = True;
	Items.JPGQuality.Enabled = True;
	Items.TIFFDeflation.Enabled = True;
	Items.MultipageStorageFormat.Enabled = True;
	Items.MethodOfConversionToPDF.Enabled = True;
	Items.ShowScannerDialog.Enabled = True;
	
	PermissionNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "XRESOLUTION");
	ChromaticityNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "PIXELTYPE");
	RotationNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "ROTATION");
	PaperSizeNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "SUPPORTEDSIZES");
	DuplexScanningNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module,
		DeviceName, "DUPLEX");
	DocumentAutoFeederNumber = FilesOperationsInternalClient.ScannerSetting(ThisObject, Attachable_Module, 
		DeviceName, "FEEDER");
	
	Items.Rotation.Enabled = (RotationNumber <> -1);
	Items.PaperSize.Enabled = (PaperSizeNumber <> -1);
	
	Items.DuplexScanning.Enabled = (DuplexScanningNumber <> -1);
	If ShouldUpdateValues Then
		UpdateValue(DuplexScanning, ?((DuplexScanningNumber = 1), True, False), Modified);
	EndIf;
	Items.DocumentAutoFeeder.Enabled = (DocumentAutoFeederNumber <> -1);
	If ShouldUpdateValues Then
		UpdateValue(DocumentAutoFeeder, ?((DocumentAutoFeederNumber = 1), True, False), Modified);
		ConvertScannerParametersToEnums(
			PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
		
		ProcessScanDialogUsage();
	EndIf;

EndProcedure

&AtServer
Procedure ConvertScannerParametersToEnums(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber) 
	
	Result = FilesOperationsInternal.ScannerParametersInEnumerations(PermissionNumber, ChromaticityNumber, 
		RotationNumber, PaperSizeNumber);
	UpdateValue(Resolution, Result.Resolution, Modified);
	UpdateValue(Chromaticity, Result.Chromaticity, Modified);
	UpdateValue(Rotation, Result.Rotation, Modified);
	UpdateValue(PaperSize, Result.PaperSize, Modified);
	
EndProcedure

&AtClient
Procedure ProcessChangesUseImageMagick()
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	
EndProcedure

&AtServer
Procedure InstallHints()
	
	FormatTooltip = "";
	ExtendedTooltip = String(Items.ConvertToPDF.ExtendedTooltip.Title); 
	Hints = StrSplit(ExtendedTooltip, Chars.LF);
	CurFormat = String(ScannedImageFormat);
	For Each ToolTip In Hints Do
		If StrStartsWith(ToolTip, CurFormat) Then
			 FormatTooltip = ToolTip;
		EndIf;
	EndDo;
	
	Items.SinglePageDocumentFormatDetails.Title = FormatTooltip;
	
EndProcedure

&AtClient
Procedure OKCompletion(UserScanSettings)
	FilesOperationsClient.SaveUserScanSettings(UserScanSettings);
	Result = New Structure("Rescanning", Rescanning);
	Close(Result);
EndProcedure

&AtClient
Procedure AfterCheckInstalledConversionApp(RunResult, ExternalContext) Export
	If StrFind(RunResult.OutputStream, "ImageMagick") = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Specified path to the %1 application is incorrect.'"), "ImageMagick"); 
		CommonClient.MessageToUser(MessageText, , "PathToConverterApplication");
	ElsIf Not ExternalContext.FillingCheckError Then
		OKCompletion(ExternalContext.UserScanSettings);
	EndIf;
EndProcedure

&AtClient
Procedure ProcessScanDialogUsage()
	
	Items.ScanningParametersGroup.Enabled = Not ShowScannerDialog;
	Items.ScannedImageFormat.Enabled = Not ShowScannerDialog;
	Items.JPGQuality.Enabled = Not ShowScannerDialog;
	Items.TIFFDeflation.Enabled = Not ShowScannerDialog;
	Items.Resolution.MarkIncomplete = Not ShowScannerDialog;
	Items.Chromaticity.MarkIncomplete = Not ShowScannerDialog;

EndProcedure

&AtClientAtServerNoContext
Procedure UpdateValue(Receiver, Source, Modified)
	Modified = Modified Or Receiver <> Source;
	Receiver = ?(ValueIsFilled(Source), Source, Receiver);
EndProcedure

&AtClient
Function IsScanFormOpen()
	For Each ClientApplicationWindow In GetWindows() Do
		For Each WindowContent In ClientApplicationWindow.Content Do
			If WindowContent.FormName = "DataProcessor.Scanning.Form.ScanningResult" Then
				Return True;
			EndIf;
		EndDo;
	EndDo;
	Return False;
EndFunction

&AtClient
Procedure AfterTechnicalInfoReceived(Result, Context) Export
	Items.ScanningError.Visible = False;
EndProcedure

&AtServer
Procedure AdaptForLinux()
	Items.ShowScannerDialog.Visible = False;
	Items.Rotation.Visible = False;
	AvailableFormats = New Array;
	AvailableFormats.Add(Enums.ScannedImageFormats.PNG);
	AvailableFormats.Add(Enums.ScannedImageFormats.JPG);
	Items.ScannedImageFormat.ChoiceList.LoadValues(AvailableFormats);
	Items.ScannedImageFormat.ListChoiceMode = True;
	If AvailableFormats.Find(ScannedImageFormat) = Undefined Then
		ScannedImageFormat = Enums.ScannedImageFormats.PNG;
		Modified = True;
	EndIf;
	Items.PathToConverterApplication.Visible = False; 
EndProcedure

&AtClient
Procedure AfterScanDirAvailabilityChecked(Result, ExternalContext) Export
	
	UserScanSettings = ExternalContext.UserScanSettings;
	FillingCheckError = ExternalContext.FillingCheckError;
	
	If Not Result.Success Then
		ErrorText = NStr("en = 'Cannot write to the specified directory. Choose another directory.'");
		CommonClient.MessageToUser(ErrorText, , "ScanLogCatalog");
		FillingCheckError = True;
	EndIf;
	
	If UserScanSettings.UseImageMagickToConvertToPDF Then
		If Not ValueIsFilled(UserScanSettings.PathToConverterApplication) Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Path to %1 is not specified.'"), 
				"ImageMagick");
			CommonClient.MessageToUser(ErrorText, , "PathToConverterApplication");
			FillingCheckError = True;
		Else
			Context = New Structure;
			Context.Insert("Context", UserScanSettings);
			Context.Insert("FillingCheckError", FillingCheckError);
			Context.Insert("UserScanSettings", UserScanSettings);
			CheckResultHandler = New CallbackDescription("AfterCheckInstalledConversionApp", ThisObject, 
				Context);
			FilesOperationsClient.StartCheckConversionAppPresence(UserScanSettings.PathToConverterApplication, 
				CheckResultHandler);
		EndIf;
	ElsIf Not FillingCheckError Then
		OKCompletion(UserScanSettings); 
	EndIf;
	
EndProcedure

#EndRegion
