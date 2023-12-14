///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var GrowingImageNumber;

&AtClient
Var InsertionPosition;

&AtClient
Var Attachable_Module;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.TableOfFiles.Visible = False;
	Items.FormAcceptAllAsSingleFile.Visible = False;
	Items.FormAcceptAllAsSeparateFiles.Visible = False;
	
	If Parameters.Property("ResultType") Then
		ResultType = Parameters.ResultType;
	EndIf;
	
	If Parameters.Property("FileOwner") Then
		FileOwner = Parameters.FileOwner;
	EndIf;
	
	OneFileOnly = Parameters.OneFileOnly;
	
	If Parameters.Property("IsFile") Then
		IsFile = Parameters.IsFile;
	EndIf;
	
	ClientID = Parameters.ClientID;
	
	If Parameters.Property("NotOpenCardAfterCreateFromFile") Then
		NotOpenCardAfterCreateFromFile = Parameters.NotOpenCardAfterCreateFromFile;
	EndIf;
	
	FileNumber = FilesOperationsInternal.GetNewNumberToScan(FileOwner);
	FileName = FilesOperationsInternalClientServer.ScannedFileName(FileNumber, "");

	ReadSettings();
	
	Items.FormSetting.Visible = Not ShowScannerDialog;
	
	If Parameters.Property("ScanningParameters") Then
		FillPropertyValues(ThisObject, Parameters.ScanningParameters);
	EndIf;
	
	If ShouldSaveAsPDF Then
		PictureFormat = "PDF";
	Else	
		PictureFormat = String(ScannedImageFormat);
	EndIf;
	
	JPGFormat = Enums.ScannedImageFormats.JPG;
	TIFFormat = Enums.ScannedImageFormats.TIF;
	
	TransformCalculationsToParametersAndGetPresentation();
	
	ScanJobParameters = Common.CommonSettingsStorageLoad("ScanningComponent", "ScanJobParameters", Undefined);
	Items.ScanningError.Visible = ScanJobParameters <> Undefined;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(ResultType) Then
		ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile();
	EndIf;
	
	If Not ChecksOnOpenExecuted Then
		Cancel = True;
		StandardSubsystemsClient.SetFormStorageOption(ThisObject, True);
		AttachIdleHandler("BeforeOpen", 0.1, True);
	EndIf;
	
	InsertionPosition = Undefined;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("DataProcessor.Scanning.Form.SetupScanningForSession") Then
		
		If TypeOf(ValueSelected) <> Type("Structure") Then
			Return;
		EndIf;
		
		ResolutionEnum   = ValueSelected.Resolution;
		ColorDepthEnum    = ValueSelected.Chromaticity;
		RotationEnum      = ValueSelected.Rotation;
		PaperSizeEnum = ValueSelected.PaperSize;
		DuplexScanning = ValueSelected.DuplexScanning;
		
		UseImageMagickToConvertToPDF = ValueSelected.UseImageMagickToConvertToPDF;
		
		ShowScannerDialog         = ValueSelected.ShowScannerDialog;
		ScannedImageFormat = ValueSelected.ScannedImageFormat;
		JPGQuality                     = ValueSelected.JPGQuality;
		TIFFCompressionEnum          = ValueSelected.TIFFDeflation;
		ShouldSaveAsPDF                   = ValueSelected.ShouldSaveAsPDF;
		MultipageStorageFormat   = ValueSelected.MultipageStorageFormat;
		
		TransformCalculationsToParametersAndGetPresentation();
	ElsIf Upper(ChoiceSource.FormName) = Upper("DataProcessor.Scanning.Form.ScanningError") Then
		Items.ScanningError.Visible = FilesOperationsInternalClient.ThereWasScanError();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	DeleteTempFiles(TableOfFiles);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTableOfFiles

&AtClient
Procedure FilesTable1OnActivateRow(Item)
#If Not WebClient And Not MobileClient Then
	If Items.TableOfFiles.CurrentData = Undefined Then
		Return;
	EndIf;

	CurrentRowNumber = Items.TableOfFiles.CurrentRow;
	TableRow = Items.TableOfFiles.RowData(CurrentRowNumber);
	
	If PathToSelectedFile <> TableRow.PathToFile Then
		
		PathToSelectedFile = TableRow.PathToFile;
		
		If IsBlankString(TableRow.PictureAddress) Then
			BinaryData = New BinaryData(PathToSelectedFile);
			TableRow.PictureAddress = PutToTempStorage(BinaryData, UUID);
		EndIf;
		
		PictureAddress = TableRow.PictureAddress;
		
	EndIf;
	
#EndIf
EndProcedure

&AtClient
Procedure FilesTable1BeforeDeleteRow(Item, Cancel)
	
	If TableOfFiles.Count() < 2 Then
		Cancel = True;
		Return;
	EndIf;
	
	CurrentRowNumber = Items.TableOfFiles.CurrentRow;
	TableRow = Items.TableOfFiles.RowData(CurrentRowNumber);
	DeleteFiles(TableRow.PathToFile);
	
	If TableOfFiles.Count() = 2 Then
		Items.FilesTable1ContextMenuDelete.Enabled = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// The "Rescan" button replaces the selected picture (or the only picture if there are no more pictures) 
//  , (or adds new pictures to the end if nothing is selected) with a new image (images).
//
&AtClient
Procedure Rescan(Command)
	
	If TableOfFiles.Count() = 1 Then
		DeleteTempFiles(TableOfFiles);
		InsertionPosition = 0;
	ElsIf TableOfFiles.Count() > 1 Then
		
		CurrentRowNumber = Items.TableOfFiles.CurrentRow;
		TableRow = Items.TableOfFiles.RowData(CurrentRowNumber);
		InsertionPosition = TableOfFiles.IndexOf(TableRow);
		DeleteFiles(TableRow.PathToFile);
		TableOfFiles.Delete(TableRow);
		
	EndIf;
	
	If PictureAddress <> "" Then
		DeleteFromTempStorage(PictureAddress);
	EndIf;	
	PictureAddress = "";
	PathToSelectedFile = "";
	
	Items.Save.Enabled = False;
	
	NotifyDescription = New NotifyDescription("StartScanAfterAddInObtained", ThisObject);
	FilesOperationsInternalClient.InitAddIn(NotifyDescription, True);
		
EndProcedure

&AtClient
Procedure Save(Command)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileArrayCopy", New Array);
	ExecutionParameters.Insert("ResultFile", "");
	
	For Each String In TableOfFiles Do
		ExecutionParameters.FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	
	// Working with one file here.
	TableRow = TableOfFiles.Get(0);
	PathToFileLocal = TableRow.PathToFile;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	ResultExtension = String(ScannedImageFormat);
	ResultExtension = Lower(ResultExtension); 
	
	Context = New Structure;
	Context.Insert("ExecutionParameters", ExecutionParameters);
	Context.Insert("PathToFileLocal", PathToFileLocal);
	Context.Insert("ResultBinaryData", "");
	
	If ShouldSaveAsPDF Then
		
#If Not WebClient And Not MobileClient Then
		ExecutionParameters.ResultFile = GetTempFileName("pdf");
#EndIf
		
		GraphicDocumentConversionParameters = FilesOperationsClient.GraphicDocumentConversionParameters();
		GraphicDocumentConversionParameters.ResultFileName = ExecutionParameters.ResultFile;
		If ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile() Then
			GraphicDocumentConversionParameters.ResultType = FilesOperationsClient.ConversionResultTypeFileName();
		ElsIf ValueIsFilled(ResultType) Then
			GraphicDocumentConversionParameters.ResultType = ResultType;
		EndIf;
		Notification = New NotifyDescription("SaveAfterMerging", ThisObject, Context); 
		FilesOperationsClient.CombineToMultipageFile(Notification, CommonClientServer.ValueInArray(PathToFileLocal), 
			GraphicDocumentConversionParameters);
	Else
		SaveAfterMergingCompletion(Context);
	EndIf;
EndProcedure

&AtClient
Procedure Setting(Command)
	
	DuplexScanningNumber = FilesOperationsInternalClient.ConfiguringScanner(ThisObject, Attachable_Module,
		ScannerName, "DUPLEX");
	DuplexScanningAvailable = (DuplexScanningNumber <> -1);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowScannerDialog",  ShowScannerDialog);
	FormParameters.Insert("Resolution",               ResolutionEnum);
	FormParameters.Insert("Chromaticity",                ColorDepthEnum);
	FormParameters.Insert("Rotation",                  RotationEnum);
	FormParameters.Insert("PaperSize",             PaperSizeEnum);
	FormParameters.Insert("DuplexScanning", DuplexScanning);
	
	FormParameters.Insert(
		"UseImageMagickToConvertToPDF", UseImageMagickToConvertToPDF);
	
	FormParameters.Insert("RotationAvailable",       RotationAvailable);
	FormParameters.Insert("PaperSizeAvailable",  PaperSizeAvailable);
	FormParameters.Insert("DuplexScanningAvailable", DuplexScanningAvailable);
	
	FormParameters.Insert("ScannedImageFormat",     ScannedImageFormat);
	FormParameters.Insert("JPGQuality",                         JPGQuality);
	FormParameters.Insert("TIFFDeflation",                          TIFFCompressionEnum);
	FormParameters.Insert("ShouldSaveAsPDF",        ShouldSaveAsPDF);
	FormParameters.Insert("MultipageStorageFormat",       MultipageStorageFormat);
	
	OpenForm("DataProcessor.Scanning.Form.SetupScanningForSession", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SaveAllAsSingleFile(Command)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileArrayCopy", New Array);
	ExecutionParameters.Insert("ResultFile", "");
	
	For Each String In TableOfFiles Do
		ExecutionParameters.FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	// Working with all pictures here. Uniting them in one multi-page file.
	
	PathsToFiles = New Array;
	
	For Each String In ExecutionParameters.FileArrayCopy Do
		PathsToFiles.Add(String.PathToFile);
	EndDo;
	
	GraphicDocumentConversionParameters = FilesOperationsClient.GraphicDocumentConversionParameters();
	GraphicDocumentConversionParameters.ResultFileName = ExecutionParameters.ResultFile;
	If ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile() Then
		GraphicDocumentConversionParameters.ResultType = FilesOperationsClient.ConversionResultTypeFileName();
	ElsIf ValueIsFilled(ResultType) Then
		GraphicDocumentConversionParameters.ResultType = ResultType;
	EndIf;	
#If Not WebClient And Not MobileClient Then
	ResultExtension = String(MultipageStorageFormat);
	ResultExtension = Lower(ResultExtension); 
	ExecutionParameters.ResultFile = GetTempFileName(ResultExtension);
	GraphicDocumentConversionParameters.ResultFormat = ResultExtension;
#EndIf
		
	Context = New Structure;
	Context.Insert("ExecutionParameters", ExecutionParameters);
	Context.Insert("ResultBinaryData", "");
	
	Notification = New NotifyDescription("SaveAllAsSingleFileCompletion", ThisObject, Context); 
	
	FilesOperationsClient.CombineToMultipageFile(Notification, PathsToFiles, GraphicDocumentConversionParameters);
EndProcedure

&AtClient
Procedure SaveAllAsSeparateFiles(Command)
	
	FileArrayCopy = New Array;
	For Each String In TableOfFiles Do
		FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	If ShouldSaveAsPDF Then
		ResultExtension = "pdf";
	Else
		ResultExtension = String(ScannedImageFormat);
		ResultExtension = Lower(ResultExtension);
	EndIf; 
	
	AddingOptions = New Structure;
	AddingOptions.Insert("FileOwner", FileOwner);
	AddingOptions.Insert("UUID", UUID);
	AddingOptions.Insert("FormIdentifier", UUID);
	AddingOptions.Insert("OwnerForm", ThisObject);
	AddingOptions.Insert("NotOpenCardAfterCreateFromFile", True);
	AddingOptions.Insert("FullFileName", "");
	AddingOptions.Insert("NameOfFileToCreate", "");
	AddingOptions.Insert("IsFile", IsFile);
	
	Context = New Structure;
	Context.Insert("ResultExtension", ResultExtension);
	Context.Insert("AddingOptions", AddingOptions);
	Context.Insert("ScannedFiles", New Array);
	Context.Insert("FullTextOfAllErrors", "");
	Context.Insert("ErrorsCount", 0);
	Context.Insert("FilesArray", FileArrayCopy);
	Context.Insert("FileIndex", 0);
	
	SaveAsSeparateFilesRecursively(Context);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	InsertionPosition = Undefined;
	NotifyDescription = New NotifyDescription("StartScanAfterAddInObtained", ThisObject);
	FilesOperationsInternalClient.InitAddIn(NotifyDescription, True);
		
EndProcedure

&AtClient
Procedure ScanErrorTextURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "TechnicalInformation" Then
		AfterReceivingTechnicalInformation = New NotifyDescription("AfterReceivingTechnicalInformation", ThisObject);
		FilesOperationsInternalClient.GetTechnicalInformation(NStr("en = 'The last scan attempt failed.';"),
			AfterReceivingTechnicalInformation);
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure HelpIsNeededClick(Item)
	
	ErrorText = StringFunctionsClient.FormattedString(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Scanning with device %1 is underway.
						|Try any of the following:
						| • Check whether the scanner is connected and try again.
						| • Specify the available scanner in the <a href = ""%2"">scanner settings</a>.
						| • If the issue persists, contact 1C technical support and 
						| provide <a href = ""%3"">technical information</a> about the issue.';"), 
					ScannerName, "OpenSettings", "TechnicalInformation"));
	
	FilesOperationsInternalClient.ShowScanError(Attachable_Module, ThisObject, 
		NStr("en = 'Scanning problem';"), 
		NStr("en = 'The user called help dialog box during scanning.';"), ErrorText, True);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeOpen()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CurrentStep", 1);
	OpeningParameters.Insert("ShowDialogBox", Undefined);
	OpeningParameters.Insert("SelectedDevice", Undefined);
	PrepareForScanning(Undefined, OpeningParameters);
EndProcedure

&AtClient
Procedure PrepareForScanning(Result, OpeningParameters) Export

	If OpeningParameters.CurrentStep = 2 Then
		Rescanning = Undefined;
		If TypeOf(Result) = Type("Structure") And Result.Property("Rescanning", Rescanning) 
			And Rescanning = True Then
			ReadSettings();
			OpeningParameters.SelectedDevice = ScannerName;
		EndIf;
		OpeningParameters.CurrentStep = 3;
	EndIf;
	
	If OpeningParameters.CurrentStep = 1 Then
		NotifyDescription = New NotifyDescription("PrepareForScanningAfterInitialization", ThisObject, OpeningParameters);
		FilesOperationsInternalClient.InitAddIn(NotifyDescription, True);
		Return;
	EndIf;
	
	BeforeOpenAutomatFollowUp(OpeningParameters);
EndProcedure
		
&AtClient
Procedure PrepareForScanningAfterInitialization(InitializationCheckResult, OpeningParameters) Export
	
	IsAddInInitialized = InitializationCheckResult.Attached;
	If Not IsAddInInitialized Then
		Return;
	EndIf;
	Attachable_Module = InitializationCheckResult.Attachable_Module;
	FilesOperationsInternalClient.EnableLoggingComponents(Attachable_Module, True);

	OpeningParameters.CurrentStep = 2;
	
	BeforeOpenAutomatFollowUp(OpeningParameters);
EndProcedure

&AtClient
Procedure BeforeOpenAutomatFollowUp(OpeningParameters)
	
	If OpeningParameters.CurrentStep = 2 Then
		OpeningParameters.ShowDialogBox = ShowScannerDialog;
		OpeningParameters.SelectedDevice = ScannerName;
		
		If OpeningParameters.SelectedDevice = "" Then
			Handler = New NotifyDescription("PrepareForScanning", ThisObject, OpeningParameters);
			FormOpenParameters = New Structure("Rescanning", True);
			OpenForm("DataProcessor.Scanning.Form.ScanningSettings", FormOpenParameters , ThisObject, , , , 
				Handler, FormWindowOpeningMode.LockWholeInterface);
			Return;
		EndIf;
		
		OpeningParameters.CurrentStep = 3;
	EndIf;
	
	If OpeningParameters.CurrentStep = 3 Then
		If OpeningParameters.SelectedDevice = "" Then 
			Return; // Do not open the form.
		EndIf;
		
		RotationNumber = FilesOperationsInternalClient.ConfiguringScanner(ThisObject, Attachable_Module,
			OpeningParameters.SelectedDevice, "ROTATION");
		PaperSizeNumber = FilesOperationsInternalClient.ConfiguringScanner(ThisObject, Attachable_Module,
			OpeningParameters.SelectedDevice, "SUPPORTEDSIZES");
		DuplexScanningNumber = FilesOperationsInternalClient.ConfiguringScanner(ThisObject, Attachable_Module,
			OpeningParameters.SelectedDevice, "DUPLEX");
		
		RotationAvailable = (RotationNumber <> -1);
		PaperSizeAvailable = (PaperSizeNumber <> -1);
		DuplexScanningAvailable = (DuplexScanningNumber <> -1);
			
		Items.Save.Enabled = False;
		
		DeflateParameter = ?(Upper(PictureFormat) = "JPG", JPGQuality, TIFFDeflation);
		
		If Not IsOpen() Then
			ChecksOnOpenExecuted = True;
			Open();
			ChecksOnOpenExecuted = False;
		EndIf;
			
		NotifyDescription = New NotifyDescription("StartScanAfterAddInObtained", ThisObject);
		FilesOperationsInternalClient.InitAddIn(NotifyDescription, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AcceptCompletion(Result, ExecutionParameters) Export
	
	DeleteTempFiles(ExecutionParameters.FileArrayCopy);
	If Not IsBlankString(ExecutionParameters.ResultFile) Then
		DeleteFiles(ExecutionParameters.ResultFile);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure AcceptAllAsOneFileCompletion(Result, ExecutionParameters) Export
	
	DeleteTempFiles(ExecutionParameters.FileArrayCopy);
	If ValueIsFilled(ExecutionParameters.ResultFile) Then
		DeleteFiles(ExecutionParameters.ResultFile);
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtServer
Procedure TransformCalculationsToParametersAndGetPresentation()
	
	Presentation = "";
		
		
		
	
	If Not ShowScannerDialog Then
	
		ScanningSettings1 = FilesOperationsInternalClientServer.ScanningParameters();
		ScanningSettings1.Resolution 	= ResolutionEnum;
		ScanningSettings1.Chromaticity		= ColorDepthEnum;
		ScanningSettings1.Rotation		= RotationEnum;
		ScanningSettings1.PaperSize	= PaperSizeEnum;
		ScanningSettings1.TIFFDeflation	= TIFFCompressionEnum;
		PrimitiveScanSettings = FilesOperationsInternal.ConvertScanSettings(ScanningSettings1);
		FillPropertyValues(ThisObject, PrimitiveScanSettings, 
			"Resolution, Chromaticity, Rotation, PaperSize, TIFFDeflation");
		
		If ShouldSaveAsPDF Then
			PictureFormat = String(ScannedImageFormat);
			
			Presentation = Presentation + NStr("en = 'Save as:';") + " ";
			Presentation = Presentation + "PDF";
			Presentation = Presentation + ". ";
			Presentation = Presentation + NStr("en = 'Scanning format:';") + " ";
			Presentation = Presentation + PictureFormat;
			Presentation = Presentation + ". ";
		Else	
			PictureFormat = String(ScannedImageFormat);
			Presentation = Presentation + NStr("en = 'Save as:';") + " ";
			Presentation = Presentation + PictureFormat;
			Presentation = Presentation + ". ";
		EndIf;
		

		If Upper(PictureFormat) = "JPG" Then
			Presentation = Presentation +  NStr("en = 'Quality:';") + " " + String(JPGQuality) + ". ";
		EndIf;	
		
		If Upper(PictureFormat) = "TIF" Then
			Presentation = Presentation +  NStr("en = 'Compression:';") + " " + String(TIFFCompressionEnum) + ". ";
		EndIf;
		
		Presentation = Presentation + NStr("en = 'Save as a multipage image:';") + " ";
		Presentation = Presentation + String(MultipageStorageFormat);
		Presentation = Presentation + ". ";
		
		If Resolution <> -1 Then
			Presentation = Presentation + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Resolution: %1 dpi. %2.';") + " ",
				String(Resolution), String(ColorDepthEnum));
		Else
			Presentation = Presentation + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Resolution: Not set. Color scale: %2.';") + " ",
				String(ColorDepthEnum));
		EndIf;
		
		If Not RotationEnum.IsEmpty() Then
			Presentation = Presentation +  NStr("en = 'Rotation:';")+ " " + String(RotationEnum) + ". ";
		EndIf;	
		
		If Not PaperSizeEnum.IsEmpty() Then
			Presentation = Presentation +  NStr("en = 'Paper size:';") + " " + String(PaperSizeEnum) + ". ";
		EndIf;	
		
		If DuplexScanning = True Then
			Presentation = Presentation +  NStr("en = 'Scan both sides';") + ". ";
		EndIf;	
		
	Else
		If ShouldSaveAsPDF Then
			PictureFormat = String(ScannedImageFormat);
			
			Presentation = Presentation + NStr("en = 'Save as:';") + " ";
			Presentation = Presentation + "PDF";
			Presentation = Presentation + ". ";
		EndIf;
		
		Presentation = Presentation + NStr("en = 'Save as a multipage image:';") + " ";
		Presentation = Presentation + String(MultipageStorageFormat);
		Presentation = Presentation + ". ";
		
		Presentation = Presentation + NStr("en = 'Scan settings are set in the scanner dialog box.';");
		
	EndIf;
	
	SettingsText = Presentation;
		
	Items.SettingsTextChange.Title = SettingsText + "Change";
	
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
#If Not WebClient And Not MobileClient Then
	If Source = "TWAIN" Then
		FilesOperationsInternalClient.WriteScanLog("ScannerEvent", 
			StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Event %1, data %2';"), Event, Data));
	EndIf;
	
	If Source = "TWAIN" And Event = "ImageAcquired" Then
		
		PictureFileName = Data;
		Items.Save.Enabled = True;
		RowsNumberBeforeAdd = TableOfFiles.Count();
		TableRow = Undefined;
		
		If InsertionPosition = Undefined Then
			TableRow = TableOfFiles.Add();
		Else
			TableRow = TableOfFiles.Insert(InsertionPosition);
			InsertionPosition = InsertionPosition + 1;
		EndIf;
		
		TableRow.PathToFile = PictureFileName;
		
		If GrowingImageNumber = Undefined Then
			GrowingImageNumber = 1;
		EndIf;
			
		TableRow.Presentation = NStr("en = 'Image';") + String(GrowingImageNumber);
		GrowingImageNumber = GrowingImageNumber + 1;
		
		If RowsNumberBeforeAdd = 0 Then
			PathToSelectedFile = TableRow.PathToFile;
			BinaryData = New BinaryData(PathToSelectedFile);
			PictureAddress = PutToTempStorage(BinaryData, UUID);
			TableRow.PictureAddress = PictureAddress;
		EndIf;
		
		If OneFileOnly Then
			Items.FormScanAgain.Visible = (TableOfFiles.Count() = 0);
		ElsIf TableOfFiles.Count() > 1 And Items.TableOfFiles.Visible = False Then
			Items.TableOfFiles.Visible = True;
			Items.FormAcceptAllAsSingleFile.Visible = True;
			Items.FormAcceptAllAsSingleFile.DefaultButton = True;
			Items.FormAcceptAllAsSeparateFiles.Visible = True;
			Items.Save.Visible = False;
		EndIf;
		
		If TableOfFiles.Count() > 1 Then
			Items.FilesTable1ContextMenuDelete.Enabled = True;
		EndIf;
		
	ElsIf Source = "TWAIN" And Event = "EndBatch" Then
		
		If TableOfFiles.Count() <> 0 Then
			RowID = TableOfFiles[TableOfFiles.Count() - 1].GetID();
			Items.TableOfFiles.CurrentRow = RowID;
		EndIf;
		FilesOperationsInternalClient.RemoveScanError(Attachable_Module);
	ElsIf Source = "TWAIN" And Event = "UserPressedCancel" Then
		If IsOpen() Then
			CurrentDate = CurrentDate(); 
			If CurrentDate < StartScanning_ + 3 Then
				ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Scanning is canceled (event %1) in %2 sec. See %3';"), Event, 
					CurrentDate - StartScanning_, "ImageScan.log");
				FilesOperationsInternalClient.WriteScanLog("ScannerEvent" + "." + Event, 
					ErrorPresentation, True);
				FilesOperationsInternalClient.ShowScanError(Attachable_Module, ThisObject, 
					NStr("en = 'Cannot scan the document';"), ErrorPresentation);
			Else
				FilesOperationsInternalClient.RemoveScanError(Attachable_Module);
				Close();
			EndIf;
		EndIf;
	EndIf;
	
	Items.ScanningError.Visible = FilesOperationsInternalClient.ThereWasScanError();
	
#EndIf

EndProcedure

&AtClient
Procedure DeleteTempFiles(FilesValueTable)
	
	For Each String In FilesValueTable Do
		DeleteFiles(String.PathToFile);
	EndDo;
	
	FilesValueTable.Clear();
	InsertionPosition = Undefined;
	
EndProcedure

&AtClient
Function MessageTextOfTransformToPDFError(ResultFile)
	
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'File ""%1"" is not found.
		           |Please check whether the ImageMagick application is installed, and
		           |whether the PDF converter path
		           |specified in the scanner settings form is valid.';"),
		ResultFile);
		
	Return MessageText;
	
EndFunction

&AtServer
Procedure ReadSettings()
	UserScanSettings = FilesOperations.GetUserScanSettings(ClientID);
	FillPropertyValues(ThisObject, UserScanSettings);
	ResolutionEnum = UserScanSettings.Resolution;
	ColorDepthEnum = UserScanSettings.Chromaticity;
	RotationEnum  = UserScanSettings.Rotation;
	TIFFCompressionEnum = UserScanSettings.TIFFDeflation;
	ScannerName = UserScanSettings.DeviceName;	
	PaperSizeEnum = UserScanSettings.PaperSize; 
EndProcedure

&AtClient
Procedure SaveAfterMergingCompletion(Context)
	ExecutionParameters = Context.ExecutionParameters;
	PathToFileLocal = Context.PathToFileLocal;
	
	Result = FilesOperationsInternalClient.ScanningResult();
		
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		Result.BinaryData = ?(ValueIsFilled(Context.ResultBinaryData), 
			Context.ResultBinaryData, New BinaryData(Context.PathToFileLocal));
		AcceptCompletion(Result, ExecutionParameters);
		Return;
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		Result.FileName = Context.PathToFileLocal;
		For FileIndex = -ExecutionParameters.FileArrayCopy.UBound() To 0 Do
			If ExecutionParameters.FileArrayCopy[-FileIndex].PathToFile <> Context.PathToFileLocal Then
				ExecutionParameters.FileArrayCopy.Delete(-FileIndex);
			EndIf;
		EndDo;	
		
		ExecutionParameters.ResultFile = "";
		AcceptCompletion(Result, ExecutionParameters);
		Return;
	Else
		If Not IsBlankString(PathToFileLocal) Then
			Handler = New NotifyDescription("AcceptCompletion", ThisObject, ExecutionParameters);
			
			AddingOptions = New Structure;
			AddingOptions.Insert("ResultHandler", Handler);
			AddingOptions.Insert("FullFileName", PathToFileLocal);
			AddingOptions.Insert("FileOwner", FileOwner);
			AddingOptions.Insert("OwnerForm", ThisObject);
			AddingOptions.Insert("NameOfFileToCreate", FileName);
			AddingOptions.Insert("NotOpenCardAfterCreateFromFile", NotOpenCardAfterCreateFromFile);
			AddingOptions.Insert("FormIdentifier", UUID);
			AddingOptions.Insert("IsFile", IsFile);
			
			FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
			Return;
		EndIf;
	EndIf;
	
	
	Result.ErrorText = NStr("en = 'Couldn''t save the scanned file.';");
	
	AcceptCompletion(Result, ExecutionParameters);
EndProcedure

&AtClient
Procedure SaveAfterMerging(MergeResult, Context) Export
	
	Context.ResultBinaryData = MergeResult.BinaryData;
	ExecutionParameters = Context.ExecutionParameters;
	
	Result = FilesOperationsInternalClient.ScanningResult();
	
	If MergeResult.Success = False Then
		MessageText = MergeResult.ErrorDescription;
		ShowMessageBox(, MessageText);
		DeleteFiles(Context.PathToFileLocal);
		DeleteFiles(ExecutionParameters.ResultFile);
		Result.ErrorText = MessageText;
		AcceptCompletion(Result, ExecutionParameters);
		Return;
	EndIf;
		
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		Result.BinaryData = Context.ResultBinaryData;
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		Result.FileName = MergeResult.ResultFileName;
	Else
		ObjectResultFile = New File(ExecutionParameters.ResultFile);
		If Not ObjectResultFile.Exists() Then
			MessageText = MessageTextOfTransformToPDFError(ExecutionParameters.ResultFile);
			ShowMessageBox(, MessageText);
			DeleteFiles(Context.PathToFileLocal);
			DeleteFiles(ExecutionParameters.ResultFile);
			Result.ErrorText = MessageText;
			AcceptCompletion(Result, ExecutionParameters);
			Return;
		EndIf;
		
		DeleteFiles(Context.PathToFileLocal);
		Context.PathToFileLocal = ExecutionParameters.ResultFile;
	EndIf;
	
	SaveAfterMergingCompletion(Context);
EndProcedure

&AtClient
Procedure SaveAllAsSingleFileCompletion(MergeResult, Context) Export
	
	Result = FilesOperationsInternalClient.ScanningResult();
	
	ExecutionParameters = Context.ExecutionParameters;
	ExecutionParameters.ResultFile = MergeResult.ResultFileName;
	Context.ResultBinaryData = MergeResult.BinaryData;
	
	If MergeResult.Success = False Then
		MessageText = MergeResult.ErrorDescription;
		If ValueIsFilled(ExecutionParameters.ResultFile) Then
			DeleteFiles(ExecutionParameters.ResultFile);
		EndIf;
		ExecutionParameters.ResultFile = "";
		Result.ErrorText = MessageText;
		ShowMessageBox(, MessageText);
		AcceptAllAsOneFileCompletion(Result, ExecutionParameters);
		Return;
	EndIf;
		
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		Result.BinaryData = Context.ResultBinaryData;
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		Result.FileName = ExecutionParameters.ResultFile;
	Else
		ObjectResultFile = New File(ExecutionParameters.ResultFile);
		If Not ObjectResultFile.Exists() Then
			MessageText = MessageTextOfTransformToPDFError(ExecutionParameters.ResultFile);
			DeleteFiles(ExecutionParameters.ResultFile);
			ExecutionParameters.ResultFile = "";
			Result.ErrorText = MessageText;
			ShowMessageBox(, MessageText);
			AcceptAllAsOneFileCompletion(Result, ExecutionParameters);
			Return;
		EndIf;
		
		If Not IsBlankString(ExecutionParameters.ResultFile) Then
			
			Handler = New NotifyDescription("AcceptAllAsOneFileCompletion", ThisObject, ExecutionParameters);
			
			AddingOptions = New Structure;
			AddingOptions.Insert("ResultHandler", Handler);
			AddingOptions.Insert("FileOwner", FileOwner);
			AddingOptions.Insert("OwnerForm", ThisObject);
			AddingOptions.Insert("FullFileName", ExecutionParameters.ResultFile);
			AddingOptions.Insert("NameOfFileToCreate", FileName);
			AddingOptions.Insert("NotOpenCardAfterCreateFromFile", NotOpenCardAfterCreateFromFile);
			AddingOptions.Insert("FormIdentifier", UUID);
			AddingOptions.Insert("UUID", UUID);
			AddingOptions.Insert("IsFile", IsFile);
			
			FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
			Return;
		EndIf;
		
	EndIf;
	ExecutionParameters.ResultFile = "";
	AcceptAllAsOneFileCompletion(Result, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure SaveAsSeparateFilesRecursively(Context)
	
	ResultExtension = Context.ResultExtension;
	AddingOptions = Context.AddingOptions;
	ScannedFiles = Context.ScannedFiles;
	
	// All pictures are processed here. Each of them is accepted as a separate file.
	If Context.FileIndex <= Context.FilesArray.UBound() Then
		String = Context.FilesArray[Context.FileIndex];
		
		PathToFileLocal = String.PathToFile;
		Context.Insert("PathToFileLocal", PathToFileLocal);
		Context.Insert("ResultFile", "");
		Context.Insert("ResultBinaryData", "");
		If ResultExtension = "pdf" Then
			
#If Not WebClient And Not MobileClient Then
		
		
		Context.ResultFile = GetTempFileName("pdf");
		// ACC:441-on
#EndIf
			GraphicDocumentConversionParameters = FilesOperationsClient.GraphicDocumentConversionParameters();
			GraphicDocumentConversionParameters.ResultFileName = Context.ResultFile;
			If ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile() Then
				GraphicDocumentConversionParameters.ResultType = FilesOperationsClient.ConversionResultTypeFileName();
			ElsIf ValueIsFilled(ResultType) Then
				GraphicDocumentConversionParameters.ResultType = ResultType;
			EndIf;
			
			Notification = New NotifyDescription("SaveAsSeparateFilesRecursivelyAfterMerging", ThisObject, Context); 
			FilesOperationsClient.CombineToMultipageFile(Notification, CommonClientServer.ValueInArray(PathToFileLocal), 
			GraphicDocumentConversionParameters);
		Else
			If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
				Context.ResultBinaryData = New BinaryData(Context.PathToFileLocal);
			EndIf;

			Notification = New NotifyDescription("SaveAsSeparateFilesRecursivelyCompletion", ThisObject, Context);
			ExecuteNotifyProcessing(Notification);
		EndIf;
						
	Else
		If ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile() Then
			FilesOperationsInternalServerCall.EnterMaxNumberToScan(
				FileOwner, FileNumber - 1);
		EndIf;
		
		DeleteTempFiles(Context.FilesArray);
		
		If Context.ErrorsCount > 0 Then
			If Context.ErrorsCount = 1 Then
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t save the file. Reason:
						|%1';"),
					Context.FullTextOfAllErrors);
			Else
				WarningText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t save some files (%1):
						|%2';"),
					String(Context.ErrorsCount), Context.FullTextOfAllErrors);
			EndIf;
			StandardSubsystemsClient.ShowQuestionToUser(Undefined, WarningText, QuestionDialogMode.OK);
		EndIf;
		
		Close(ScannedFiles);
	EndIf;
	
EndProcedure

&AtClient
Procedure SaveAsSeparateFilesRecursivelyCompletion(AlertResult, Context) Export
	
	Result = FilesOperationsInternalClient.ScanningResult();
	If ResultType = FilesOperationsClient.ConversionResultTypeBinaryData() Then
		Result.BinaryData = Context.ResultBinaryData;
		Context.ScannedFiles.Add(Result);
	ElsIf ResultType = FilesOperationsClient.ConversionResultTypeFileName() Then
		Result.FileName = Context.ResultFile;
		Context.ScannedFiles.Add(Result);
	Else
		If Not IsBlankString(Context.PathToFileLocal) Then
			Context.AddingOptions.FullFileName = Context.PathToFileLocal;
			Context.AddingOptions.NameOfFileToCreate = FileName;
			Result = FilesOperationsInternalClient.AddFromFileSystemWithExtensionSynchronous(Context.AddingOptions);
			If Not Result.FileAdded Then
				If ValueIsFilled(Result.ErrorText) Then
					ShowMessageBox(, Result.ErrorText);
					Return;
				EndIf;
			Else
				Context.ScannedFiles.Add(Result);
			EndIf;
		EndIf;
		
		If Not IsBlankString(Context.ResultFile) Then
			DeleteFiles(Context.ResultFile);
		EndIf;
	EndIf;
	
	FileNumber = FileNumber + 1;
	FileName = FilesOperationsInternalClientServer.ScannedFileName(FileNumber, "");
	Context.FileIndex = Context.FileIndex + 1;
	SaveAsSeparateFilesRecursively(Context);
EndProcedure

&AtClient
Procedure SaveAsSeparateFilesRecursivelyAfterMerging(MergeResult, Context) Export
	Context.ResultFile = MergeResult.ResultFileName;
	Context.ResultBinaryData = MergeResult.BinaryData;
	
	If MergeResult.Success = False Then
		ErrorText = MergeResult.ErrorDescription;
		If Context.FullTextOfAllErrors <> "" Then
			Context.FullTextOfAllErrors = Context.FullTextOfAllErrors + Chars.LF + Chars.LF + "---" + Chars.LF + Chars.LF;
		EndIf;
		Context.FullTextOfAllErrors = Context.FullTextOfAllErrors + ErrorText;
		Context.ErrorsCount = Context.ErrorsCount + 1;
		Context.ResultFile = "";
	EndIf;
	
	If ResultType = FilesOperationsClient.ConversionResultTypeAttachedFile() Then
		ObjectResultFile = New File(Context.ResultFile);
		If Not ObjectResultFile.Exists() Then
			ErrorText = MessageTextOfTransformToPDFError(Context.ResultFile);
			If Context.FullTextOfAllErrors <> "" Then
				Context.FullTextOfAllErrors = Context.FullTextOfAllErrors + Chars.LF + Chars.LF + "---" + Chars.LF + Chars.LF;
			EndIf;
			Context.FullTextOfAllErrors = Context.FullTextOfAllErrors + ErrorText;
			Context.ErrorsCount = Context.ErrorsCount + 1;
			Context.ResultFile = "";
		EndIf;
		
		Context.PathToFileLocal = Context.ResultFile;
	EndIf;
	
	Notification = New NotifyDescription("SaveAsSeparateFilesRecursivelyCompletion", ThisObject, Context);
	ExecuteNotifyProcessing(Notification);
EndProcedure

&AtClient
Procedure StartScanAfterAddInObtained(InitializationResult, Context) Export
	If InitializationResult.Attached Then
		
		Attachable_Module = InitializationResult.Attachable_Module;
		ScanningParameters = FilesOperationsInternalClientServer.ScanningParameters();
		ScanningParameters.ShowDialogBox = ShowScannerDialog;
		ScanningParameters.SelectedDevice = ScannerName;
		ScanningParameters.PictureFormat = PictureFormat;
		ScanningParameters.Resolution = Resolution;
		ScanningParameters.Chromaticity = Chromaticity;
		ScanningParameters.Rotation = Rotation;
		ScanningParameters.PaperSize = PaperSize;
		ScanningParameters.JPGQuality = JPGQuality;
		ScanningParameters.TIFFDeflation = TIFFDeflation;
		ScanningParameters.DuplexScanning = DuplexScanning;
		StartScanning_ = CurrentDate();// ACC:143 - Intended for calculation time intervals
		ScanJobParameters = New Structure();
		ScanJobParameters.Insert("StartScanning_", StartScanning_);
		ScanJobParameters.Insert("ScanningParameters", ScanningParameters);
		
		PictureAddress = PutToTempStorage(PictureLib.TimeConsumingOperation48.GetBinaryData(), UUID);
		CommonServerCall.CommonSettingsStorageSave("ScanningComponent", "ScanJobParameters", 
			ScanJobParameters,,,True);
		FilesOperationsInternalClient.BeginScan(ThisObject, Attachable_Module, ScanningParameters);
		
	EndIf;
EndProcedure

&AtClient
Procedure AfterClosingErrorForm(ClosingResult, Context) Export
	If ClosingResult = "RepeatScan" Then
		ReadSettings();
		Rescan(Undefined);
	ElsIf ClosingResult = DialogReturnCode.Cancel And Not Context.ModeNeedsHelp Then
		If IsOpen() Then
			Close();
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AfterReceivingTechnicalInformation(Result, Context) Export
	Items.ScanningError.Visible = False;
EndProcedure

#EndRegion
