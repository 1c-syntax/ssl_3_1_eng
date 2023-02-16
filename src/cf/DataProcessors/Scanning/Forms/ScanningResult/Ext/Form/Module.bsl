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

#EndRegion

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.TableOfFiles.Visible = False;
	Items.FormAcceptAllAsSingleFile.Visible = False;
	Items.FormAcceptAllAsSeparateFiles.Visible = False;
	
	If Parameters.Property("FileOwner") Then
		FileOwner = Parameters.FileOwner;
	EndIf;
	
	OneFileOnly = Parameters.OneFileOnly;
	
	If Parameters.Property("IsFile") Then
		IsFile = Parameters.IsFile;
	EndIf;
	
	ClientID = Parameters.ClientID;
	
	If Parameters.Property("DontOpenCardAfterCreateFromFIle") Then
		DontOpenCardAfterCreateFromFIle = Parameters.DontOpenCardAfterCreateFromFIle;
	EndIf;
	
	FileNumber = FilesOperationsInternal.GetNewNumberToScan(FileOwner);
	FileName = FilesOperationsInternalClientServer.ScannedFileName(FileNumber, "");

	ScannedImageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ScannedImageFormat", 
		ClientID, Enums.ScannedImageFormats.PNG);
	
	SinglePageStorageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/SinglePageStorageFormat", 
		ClientID, Enums.SinglePageFileStorageFormats.PNG);
	
	MultipageStorageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/MultipageStorageFormat", 
		ClientID, Enums.MultipageFileStorageFormats.TIF);
	
	ResolutionEnum = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Resolution", 
		ClientID);
	
	ColorDepthEnum = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Chromaticity", 
		ClientID);
	
	RotationEnum = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Rotation", 
		ClientID);
	
	PaperSizeEnum = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/PaperSize", 
		ClientID);
	
	DuplexScanning = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DuplexScanning", 
		ClientID);
	
	UseImageMagickToConvertToPDF = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/UseImageMagickToConvertToPDF", 
		ClientID);
	
	JPGQuality = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/JPGQuality", 
		ClientID, 100);
	
	TIFFDeflation = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/TIFFDeflation", 
		ClientID, Enums.TIFFCompressionTypes.NoCompression);
	
	PathToConverterApplication = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/PathToConverterApplication", 
		ClientID, "convert.exe"); // ImageMagick
	
	ShowScannerDialogBoxImport = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ShowScannerDialog", 
		ClientID, True);
	
	ShowScannerDialog = ShowScannerDialogBoxImport;
	
	DeviceName = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DeviceName", 
		ClientID, "");
	
	ScannerName = DeviceName;
	
	If UseImageMagickToConvertToPDF Then
		If SinglePageStorageFormat = Enums.SinglePageFileStorageFormats.PDF Then
			PictureFormat = String(ScannedImageFormat);
		Else	
			PictureFormat = String(SinglePageStorageFormat);
		EndIf;
	Else	
		PictureFormat = String(ScannedImageFormat);
	EndIf;
	
	JPGFormat = Enums.ScannedImageFormats.JPG;
	TIFFormat = Enums.ScannedImageFormats.TIF;
	
	TransformCalculationsToParametersAndGetPresentation();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
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
		TIFFDeflation                      = ValueSelected.TIFFDeflation;
		SinglePageStorageFormat    = ValueSelected.SinglePageStorageFormat;
		MultipageStorageFormat   = ValueSelected.MultipageStorageFormat;
		
		TransformCalculationsToParametersAndGetPresentation();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	DeleteTempFiles(TableOfFiles);
	
EndProcedure

#EndRegion

#Region TableOfFilesFormTableItemEventHandlers

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

#Region FormCommandHandlers

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
	
	ShowDialogBox = ShowScannerDialog;
	SelectedDevice = ScannerName;
	DeflateParameter = ?(Upper(PictureFormat) = "JPG", JPGQuality, TIFFCompressionNumber);
	
	ApplicationParameters["StandardSubsystems.TwainComponent"].BeginScan(
		ShowDialogBox, SelectedDevice, PictureFormat, 
		Resolution, Chromaticity, Rotation, PaperSize, 
		DeflateParameter,
		DuplexScanning);
		
EndProcedure

&AtClient
Procedure Save(Command)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileArrayCopy", New Array);
	ExecutionParameters.Insert("ResultFile", "");
	
	Result = ScanningResult();
	
	For Each String In TableOfFiles Do
		ExecutionParameters.FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	
	// Working with one file here.
	TableRow = TableOfFiles.Get(0);
	PathToFileLocal = TableRow.PathToFile;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	ResultExtension = String(SinglePageStorageFormat);
	ResultExtension = Lower(ResultExtension); 
	
	If ResultExtension = "pdf" Then
		
#If Not WebClient And Not MobileClient Then
		ExecutionParameters.ResultFile = GetTempFileName("pdf"); // See AcceptCompletion.
#EndIf
		
		AllPathsString = PathToFileLocal;
		ApplicationParameters["StandardSubsystems.TwainComponent"].CombineToMultipageFile(
			AllPathsString, ExecutionParameters.ResultFile, PathToConverterApplication);
		
		ObjectResultFile = New File(ExecutionParameters.ResultFile);
		If Not ObjectResultFile.Exists() Then
			MessageText = MessageTextOfTransformToPDFError(ExecutionParameters.ResultFile);
			ShowMessageBox(, MessageText);
			DeleteFiles(PathToFileLocal);
			DeleteFiles(ExecutionParameters.ResultFile);
			
			Result.ErrorText = MessageText;
			AcceptCompletion(Result, ExecutionParameters);
			Return;
		EndIf;
		
		DeleteFiles(PathToFileLocal);
		PathToFileLocal = ExecutionParameters.ResultFile;
	EndIf;
	
	If Not IsBlankString(PathToFileLocal) Then
		Handler = New NotifyDescription("AcceptCompletion", ThisObject, ExecutionParameters);
		
		AddingOptions = New Structure;
		AddingOptions.Insert("ResultHandler", Handler);
		AddingOptions.Insert("FullFileName", PathToFileLocal);
		AddingOptions.Insert("FileOwner", FileOwner);
		AddingOptions.Insert("OwnerForm1", ThisObject);
		AddingOptions.Insert("NameOfFileToCreate", FileName);
		AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", DontOpenCardAfterCreateFromFIle);
		AddingOptions.Insert("FormIdentifier", UUID);
		AddingOptions.Insert("IsFile", IsFile);
		
		FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		Return;
	EndIf;
	
	Result.ErrorText = NStr("en = 'Couldn''t save the scanned file.';");
	AcceptCompletion(Result, ExecutionParameters);
EndProcedure

&AtClient
Procedure Setting(Command)
	
	DuplexScanningNumber = FilesOperationsInternalClient.GetSetting(
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
	FormParameters.Insert("TIFFDeflation",                          TIFFDeflation);
	FormParameters.Insert("SinglePageStorageFormat",        SinglePageStorageFormat);
	FormParameters.Insert("MultipageStorageFormat",       MultipageStorageFormat);
	
	OpenForm("DataProcessor.Scanning.Form.SetupScanningForSession", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure SaveAllAsSingleFile(Command)
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("FileArrayCopy", New Array);
	ExecutionParameters.Insert("ResultFile", "");
	
	Result = ScanningResult();
	
	For Each String In TableOfFiles Do
		ExecutionParameters.FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	// Working with all pictures here. Uniting them in one multi-page file.
	AllPathsString = "";
	For Each String In ExecutionParameters.FileArrayCopy Do
		AllPathsString = AllPathsString + "*";
		AllPathsString = AllPathsString + String.PathToFile;
	EndDo;
	
#If Not WebClient And Not MobileClient Then
	ResultExtension = String(MultipageStorageFormat);
	ResultExtension = Lower(ResultExtension); 
	ExecutionParameters.ResultFile = GetTempFileName(ResultExtension); // See AcceptAllAsOneFileCompletion
#EndIf
	ApplicationParameters["StandardSubsystems.TwainComponent"].CombineToMultipageFile(
		AllPathsString, ExecutionParameters.ResultFile, PathToConverterApplication);
	
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
		AddingOptions.Insert("OwnerForm1", ThisObject);
		AddingOptions.Insert("FullFileName", ExecutionParameters.ResultFile);
		AddingOptions.Insert("NameOfFileToCreate", FileName);
		AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", DontOpenCardAfterCreateFromFIle);
		AddingOptions.Insert("FormIdentifier", UUID);
		AddingOptions.Insert("UUID", UUID);
		AddingOptions.Insert("IsFile", IsFile);
		
		FilesOperationsInternalClient.AddFormFileSystemWithExtension(AddingOptions);
		Return;
	EndIf;
	
	AcceptAllAsOneFileCompletion(Result, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure SaveAllAsSeparateFiles(Command)
	
	FileArrayCopy = New Array;
	For Each String In TableOfFiles Do
		FileArrayCopy.Add(New Structure("PathToFile", String.PathToFile));
	EndDo;
	ScannedFiles = New Array;
	
	TableOfFiles.Clear(); // Not to delete files in OnClose.
	
	ResultExtension = String(SinglePageStorageFormat);
	ResultExtension = Lower(ResultExtension); 
	
	AddingOptions = New Structure;
	AddingOptions.Insert("FileOwner", FileOwner);
	AddingOptions.Insert("UUID", UUID);
	AddingOptions.Insert("FormIdentifier", UUID);
	AddingOptions.Insert("OwnerForm1", ThisObject);
	AddingOptions.Insert("DontOpenCardAfterCreateFromFIle", True);
	AddingOptions.Insert("FullFileName", "");
	AddingOptions.Insert("NameOfFileToCreate", "");
	AddingOptions.Insert("IsFile", IsFile);
	
	FullTextOfAllErrors = "";
	ErrorsCount = 0;
	
	// Working with all pictures here. Accepting each as a separate file.
	For Each String In FileArrayCopy Do
		
		PathToFileLocal = String.PathToFile;
		
		ResultFile = "";
		If ResultExtension = "pdf" Then
			
#If Not WebClient And Not MobileClient Then
			ResultFile = GetTempFileName("pdf");
#EndIf
			
			AllPathsString = PathToFileLocal;
			ApplicationParameters["StandardSubsystems.TwainComponent"].CombineToMultipageFile(
				AllPathsString, ResultFile, PathToConverterApplication);
			
			ObjectResultFile = New File(ResultFile);
			If Not ObjectResultFile.Exists() Then
				ErrorText = MessageTextOfTransformToPDFError(ResultFile);
				If FullTextOfAllErrors <> "" Then
					FullTextOfAllErrors = FullTextOfAllErrors + Chars.LF + Chars.LF + "---" + Chars.LF + Chars.LF;
				EndIf;
				FullTextOfAllErrors = FullTextOfAllErrors + ErrorText;
				ErrorsCount = ErrorsCount + 1;
				ResultFile = "";
			EndIf;
			
			PathToFileLocal = ResultFile;
			
		EndIf;
		
		If Not IsBlankString(PathToFileLocal) Then
			AddingOptions.FullFileName = PathToFileLocal;
			AddingOptions.NameOfFileToCreate = FileName;
			Result = FilesOperationsInternalClient.AddFromFileSystemWithExtensionSynchronous(AddingOptions);
			If Not Result.FileAdded Then
				If ValueIsFilled(Result.ErrorText) Then
					ShowMessageBox(, Result.ErrorText);
					Return;
				EndIf;
			Else
				ScannedFiles.Add(Result);
			EndIf;
		EndIf;
		
		If Not IsBlankString(ResultFile) Then
			DeleteFiles(ResultFile);
		EndIf;
		
		FileNumber = FileNumber + 1;
		FileName = FilesOperationsInternalClientServer.ScannedFileName(FileNumber, "");
		
	EndDo;
	
	FilesOperationsInternalServerCall.EnterMaxNumberToScan(
		FileOwner, FileNumber - 1);
	
	DeleteTempFiles(FileArrayCopy);
	
	If ErrorsCount > 0 Then
		If ErrorsCount = 1 Then
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t save the file. Reason:
					|%1';"),
				FullTextOfAllErrors);
		Else
			WarningText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t save some files (%1):
					|%2';"),
				String(ErrorsCount), FullTextOfAllErrors);
		EndIf;
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, WarningText, QuestionDialogMode.OK);
	EndIf;
	
	Close(ScannedFiles);
	
EndProcedure

&AtClient
Procedure Scan(Command)
	
	ShowDialogBox = ShowScannerDialog;
	SelectedDevice = ScannerName;
	DeflateParameter = ?(Upper(PictureFormat) = "JPG", JPGQuality, TIFFCompressionNumber);
	
	InsertionPosition = Undefined;
	
	ApplicationParameters["StandardSubsystems.TwainComponent"].BeginScan(
		ShowDialogBox, SelectedDevice, PictureFormat, 
		Resolution, Chromaticity, Rotation, PaperSize, 
		DeflateParameter,
		DuplexScanning);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeOpen()
	
	StandardSubsystemsClient.SetFormStorageOption(ThisObject, False);
	
	// Initial initialization of the machine (call from OnOpen ()).
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CurrentStep", 1);
	OpeningParameters.Insert("ShowDialogBox", Undefined);
	OpeningParameters.Insert("SelectedDevice", Undefined);
	BeforeOpenMachine(Undefined, OpeningParameters);
EndProcedure

&AtClient
Procedure BeforeOpenMachine(Result, OpeningParameters) Export
	// Secondary initialization of the machine (call from the dialog box opened by the machine).
	If OpeningParameters.CurrentStep = 2 Then
		If TypeOf(Result) = Type("String") And Not IsBlankString(Result) Then
			OpeningParameters.SelectedDevice = Result;
			ScannerName = OpeningParameters.SelectedDevice;
		EndIf;
		OpeningParameters.CurrentStep = 3;
	EndIf;
	
	If OpeningParameters.CurrentStep = 1 Then
		If Not FilesOperationsInternalClient.InitAddIn() Then
			Return;
		EndIf;
		
		// 
		// 
		If Not FilesOperationsInternalClient.ScanCommandAvailable() Then
			RefreshReusableValues();
			Return;
		EndIf;
		
		OpeningParameters.CurrentStep = 2;
	EndIf;
	
	If OpeningParameters.CurrentStep = 2 Then
		OpeningParameters.ShowDialogBox = ShowScannerDialog;
		OpeningParameters.SelectedDevice = ScannerName;
		
		If OpeningParameters.SelectedDevice = "" Then
			Handler = New NotifyDescription("BeforeOpenMachine", ThisObject, OpeningParameters);
			OpenForm("DataProcessor.Scanning.Form.ScanningDeviceChoice", , ThisObject, , , , Handler, FormWindowOpeningMode.LockWholeInterface);
			Return;
		EndIf;
		
		OpeningParameters.CurrentStep = 3;
	EndIf;
	
	If OpeningParameters.CurrentStep = 3 Then
		If OpeningParameters.SelectedDevice = "" Then 
			Return; // Do not open the form.
		EndIf;
		
		If Resolution = -1 Or Chromaticity = -1 Or Rotation = -1 Or PaperSize = -1 Then
			
			Resolution = FilesOperationsInternalClient.GetSetting(
				OpeningParameters.SelectedDevice,
				"XRESOLUTION");
			
			Chromaticity = FilesOperationsInternalClient.GetSetting(
				OpeningParameters.SelectedDevice,
				"PIXELTYPE");
			
			Rotation = FilesOperationsInternalClient.GetSetting(
				OpeningParameters.SelectedDevice,
				"ROTATION");
			
			PaperSize = FilesOperationsInternalClient.GetSetting(
				OpeningParameters.SelectedDevice,
				"SUPPORTEDSIZES");
			
			DuplexScanningNumber = FilesOperationsInternalClient.GetSetting(
				OpeningParameters.SelectedDevice,
				"DUPLEX");
			
			RotationAvailable = (Rotation <> -1);
			PaperSizeAvailable = (PaperSize <> -1);
			DuplexScanningAvailable = (DuplexScanningNumber <> -1);
			
			SystemInfo = New SystemInfo();
			ClientID = SystemInfo.ClientID;
			
			SaveScannerParameters(Resolution, Chromaticity, ClientID);
		Else
			
			RotationAvailable = Not RotationEnum.IsEmpty();
			PaperSizeAvailable = Not PaperSizeEnum.IsEmpty();
			DuplexScanningAvailable = True;
			
		EndIf;
		
		Items.Save.Enabled = False;
		
		DeflateParameter = ?(Upper(PictureFormat) = "JPG", JPGQuality, TIFFCompressionNumber);
		
		If Not IsOpen() Then
			ChecksOnOpenExecuted = True;
			Open();
			ChecksOnOpenExecuted = False;
		EndIf;
		
		ApplicationParameters["StandardSubsystems.TwainComponent"].BeginScan(
			OpeningParameters.ShowDialogBox,
			OpeningParameters.SelectedDevice,
			PictureFormat,
			Resolution,
			Chromaticity,
			Rotation,
			PaperSize,
			DeflateParameter,
			DuplexScanning);
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
	DeleteFiles(ExecutionParameters.ResultFile);
	Close(Result);
	
EndProcedure

&AtServer
Procedure TransformCalculationsToParametersAndGetPresentation()
		
	Resolution = -1;
	If ResolutionEnum = Enums.ScannedImageResolutions.dpi200 Then
		Resolution = 200; 
	ElsIf ResolutionEnum = Enums.ScannedImageResolutions.dpi300 Then
		Resolution = 300;
	ElsIf ResolutionEnum = Enums.ScannedImageResolutions.dpi600 Then
		Resolution = 600;
	ElsIf ResolutionEnum = Enums.ScannedImageResolutions.dpi1200 Then
		Resolution = 1200;
	EndIf;
	
	Chromaticity = -1;
	If ColorDepthEnum = Enums.ImageColorDepths.Monochrome Then
		Chromaticity = 0;
	ElsIf ColorDepthEnum = Enums.ImageColorDepths.Grayscale Then
		Chromaticity = 1;
	ElsIf ColorDepthEnum = Enums.ImageColorDepths.Colored Then
		Chromaticity = 2;
	EndIf;
	
	Rotation = 0;
	If RotationEnum = Enums.PictureRotationOptions.NoRotation Then
		Rotation = 0;
	ElsIf RotationEnum = Enums.PictureRotationOptions.Right90 Then
		Rotation = 90;
	ElsIf RotationEnum = Enums.PictureRotationOptions.Right180 Then
		Rotation = 180;
	ElsIf RotationEnum = Enums.PictureRotationOptions.Left90 Then
		Rotation = 270;
	EndIf;
	
	PaperSize = 0;
	If PaperSizeEnum = Enums.PaperSizes.NotDefined Then
		PaperSize = 0;
	ElsIf PaperSizeEnum = Enums.PaperSizes.A3 Then
		PaperSize = 11;
	ElsIf PaperSizeEnum = Enums.PaperSizes.A4 Then
		PaperSize = 1;
	ElsIf PaperSizeEnum = Enums.PaperSizes.A5 Then
		PaperSize = 5;
	ElsIf PaperSizeEnum = Enums.PaperSizes.B4 Then
		PaperSize = 6;
	ElsIf PaperSizeEnum = Enums.PaperSizes.B5 Then
		PaperSize = 2;
	ElsIf PaperSizeEnum = Enums.PaperSizes.B6 Then
		PaperSize = 7;
	ElsIf PaperSizeEnum = Enums.PaperSizes.C4 Then
		PaperSize = 14;
	ElsIf PaperSizeEnum = Enums.PaperSizes.C5 Then
		PaperSize = 15;
	ElsIf PaperSizeEnum = Enums.PaperSizes.C6 Then
		PaperSize = 16;
	ElsIf PaperSizeEnum = Enums.PaperSizes.USLetter Then
		PaperSize = 3;
	ElsIf PaperSizeEnum = Enums.PaperSizes.USLegal Then
		PaperSize = 4;
	ElsIf PaperSizeEnum = Enums.PaperSizes.USExecutive Then
		PaperSize = 10;
	EndIf;
	
	TIFFCompressionNumber = 6; // NoCompression
	If TIFFDeflation = Enums.TIFFCompressionTypes.LZW Then
		TIFFCompressionNumber = 2;
	ElsIf TIFFDeflation = Enums.TIFFCompressionTypes.RLE Then
		TIFFCompressionNumber = 5;
	ElsIf TIFFDeflation = Enums.TIFFCompressionTypes.NoCompression Then
		TIFFCompressionNumber = 6;
	ElsIf TIFFDeflation = Enums.TIFFCompressionTypes.CCITT3 Then
		TIFFCompressionNumber = 3;
	ElsIf TIFFDeflation = Enums.TIFFCompressionTypes.CCITT4 Then
		TIFFCompressionNumber = 4;
		
	EndIf;
	
	Presentation = "";
	// 
	// 
	// 
	
	If UseImageMagickToConvertToPDF Then
		If SinglePageStorageFormat = Enums.SinglePageFileStorageFormats.PDF Then
			PictureFormat = String(ScannedImageFormat);
			
			Presentation = Presentation + NStr("en = 'Storage format:';") + " ";
			Presentation = Presentation + "PDF";
			Presentation = Presentation + ". ";
			Presentation = Presentation + NStr("en = 'Scanning format:';") + " ";
			Presentation = Presentation + PictureFormat;
			Presentation = Presentation + ". ";
		Else	
			PictureFormat = String(SinglePageStorageFormat);
			Presentation = Presentation + NStr("en = 'Storage format:';") + " ";
			Presentation = Presentation + PictureFormat;
			Presentation = Presentation + ". ";
		EndIf;
	Else	
		PictureFormat = String(ScannedImageFormat);
		Presentation = Presentation + NStr("en = 'Storage format:';") + " ";
		Presentation = Presentation + PictureFormat;
		Presentation = Presentation + ". ";
	EndIf;

	If Upper(PictureFormat) = "JPG" Then
		Presentation = Presentation +  NStr("en = 'Quality:';") + " " + String(JPGQuality) + ". ";
	EndIf;	
	
	If Upper(PictureFormat) = "TIF" Then
		Presentation = Presentation +  NStr("en = 'Compression:';") + " " + String(TIFFDeflation) + ". ";
	EndIf;
	
	Presentation = Presentation + NStr("en = 'Multipage storage format:';") + " ";
	Presentation = Presentation + String(MultipageStorageFormat);
	Presentation = Presentation + ". ";
	
	Presentation = Presentation + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Resolution: %1 dpi. %2.';") + " ",
		String(Resolution), String(ColorDepthEnum));
	
	If Not RotationEnum.IsEmpty() Then
		Presentation = Presentation +  NStr("en = 'Rotation:';")+ " " + String(RotationEnum) + ". ";
	EndIf;	
	
	If Not PaperSizeEnum.IsEmpty() Then
		Presentation = Presentation +  NStr("en = 'Paper size:';") + " " + String(PaperSizeEnum) + ". ";
	EndIf;	
	
	If DuplexScanning = True Then
		Presentation = Presentation +  NStr("en = 'Scan both sides';") + ". ";
	EndIf;	
	
	SettingsText = Presentation;
	
	Items.SettingsTextChange.Title = SettingsText + "Change";
	
EndProcedure

&AtClient
Procedure ExternalEvent(Source, Event, Data)
	
#If Not WebClient And Not MobileClient Then
		
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
		
	ElsIf Source = "TWAIN" And Event = "UserPressedCancel" Then	
		If ThisObject.IsOpen() Then
			Close();
		EndIf;
	EndIf;
	
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

&AtServerNoContext
Procedure SaveScannerParameters(PermissionNumber, ChromaticityNumber, ClientID) 
	
	Result = FilesOperationsInternal.ScannerParametersInEnumerations(PermissionNumber, ChromaticityNumber, 0, 0);
	Common.CommonSettingsStorageSave("ScanningSettings1/Resolution", ClientID, Result.Resolution);
	Common.CommonSettingsStorageSave("ScanningSettings1/Chromaticity", ClientID, Result.Chromaticity);
	
EndProcedure

&AtClient
Function ScanningResult()
	
	Var Result;
	
	Result = New Structure();
	Result.Insert("ErrorText", "");
	Result.Insert("FileAdded", False);
	Result.Insert("FileRef");
	Return Result;

EndFunction

#EndRegion
