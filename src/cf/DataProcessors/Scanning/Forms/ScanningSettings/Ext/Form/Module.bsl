///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ClientID = Parameters.ClientID;
	
	ShowScannerDialog = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ShowScannerDialog", 
		ClientID, True);
	
	DeviceName = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DeviceName", 
		ClientID, "");
	
	ScannedImageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/ScannedImageFormat", 
		ClientID, Enums.ScannedImageFormats.PNG);
	
	SinglePageStorageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/SinglePageStorageFormat", 
		ClientID, Enums.SinglePageFileStorageFormats.PNG);
	
	MultipageStorageFormat = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/MultipageStorageFormat", 
		ClientID, Enums.MultipageFileStorageFormats.TIF);
	
	Resolution = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Resolution", 
		ClientID);
	
	Chromaticity = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Chromaticity", 
		ClientID);
	
	Rotation = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/Rotation", 
		ClientID);
	
	PaperSize = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/PaperSize", 
		ClientID);
	
	DuplexScanning = Common.CommonSettingsStorageLoad(
		"ScanningSettings1/DuplexScanning", 
		ClientID);
	
	UseImageMagickToConvertToPDF =  Common.CommonSettingsStorageLoad(
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
	
	JPGFormat = Enums.ScannedImageFormats.JPG;
	TIFFormat = Enums.ScannedImageFormats.TIF;
	
	MultiPageTIFFormat = Enums.MultipageFileStorageFormats.TIF;
	SinglePagePDFFormat = Enums.SinglePageFileStorageFormats.PDF;
	SinglePageJPGFormat = Enums.SinglePageFileStorageFormats.JPG;
	SinglePageTIFFormat = Enums.SinglePageFileStorageFormats.TIF;
	SinglePagePNGFormat = Enums.SinglePageFileStorageFormats.PNG;
	
	If Not UseImageMagickToConvertToPDF Then
		MultipageStorageFormat = MultiPageTIFFormat;
	EndIf;
	
	Items.StorageFormatGroup.Visible = UseImageMagickToConvertToPDF;
	
	If UseImageMagickToConvertToPDF Then
		If SinglePageStorageFormat = SinglePagePDFFormat Then
			Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
			Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
		Else	
			Items.JPGQuality.Visible = (SinglePageStorageFormat = SinglePageJPGFormat);
			Items.TIFFDeflation.Visible = (SinglePageStorageFormat = SinglePageTIFFormat);
		EndIf;
	Else	
		Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
		Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	EndIf;
	
	DecorationsVisible = (UseImageMagickToConvertToPDF And (SinglePageStorageFormat = SinglePagePDFFormat));
	Items.SinglePageStorageFormatDecoration.Visible = DecorationsVisible;
	Items.ScannedImageFormatDecoration.Visible = DecorationsVisible;
	
	ScanningFormatVisibility = (UseImageMagickToConvertToPDF And (SinglePageStorageFormat = SinglePagePDFFormat)) Or (Not UseImageMagickToConvertToPDF);
	Items.ScanningFormatGroup.Visible = ScanningFormatVisibility;
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	
	Items.MultipageStorageFormat.Enabled = UseImageMagickToConvertToPDF;
	
	SinglePageStorageFormatPrevious = SinglePageStorageFormat;
	
	If Not UseImageMagickToConvertToPDF Then
		Items.ScannedImageFormat.Title = NStr("en = 'Format';");
	Else
		Items.ScannedImageFormat.Title = NStr("en = 'Type';");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	RefreshStatus();
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
	
	If UseImageMagickToConvertToPDF Then
		If SinglePageStorageFormat = SinglePagePDFFormat Then
			Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
			Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
		Else	
			Items.JPGQuality.Visible = (SinglePageStorageFormat = SinglePageJPGFormat);
			Items.TIFFDeflation.Visible = (SinglePageStorageFormat = SinglePageTIFFormat);
		EndIf;
	Else	
		Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
		Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	EndIf;
	
EndProcedure

&AtClient
Procedure PathToConverterApplicationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not FilesOperationsInternalClient.FileSystemExtensionAttached1() Then
		Return;
	EndIf;
		
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.FullFileName = PathToConverterApplication;
	Filter = NStr("en = 'Executable files (*.exe)|*.exe';");
	OpenFileDialog.Filter = Filter;
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("en = 'Select file to convert to PDF';");
	If OpenFileDialog.Choose() Then
		PathToConverterApplication = OpenFileDialog.FullFileName;
	EndIf;
	
EndProcedure

&AtClient
Procedure SinglePageStorageFormatOnChange(Item)
	
	ProcessChangesSinglePageStorageFormat();
	
EndProcedure

&AtClient
Procedure UseImageMagickToConvertToPDFOnChange(Item)
	
	ProcessChangesUseImageMagick();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then 
		Return;
	EndIf;
	
	StructuresArray = New Array;
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	
	StructuresArray.Add (GenerateSetting("ShowScannerDialog", ShowScannerDialog, ClientID));
	StructuresArray.Add (GenerateSetting("DeviceName", DeviceName, ClientID));
	
	StructuresArray.Add (GenerateSetting("ScannedImageFormat", ScannedImageFormat, ClientID));
	StructuresArray.Add (GenerateSetting("SinglePageStorageFormat", SinglePageStorageFormat, ClientID));
	StructuresArray.Add (GenerateSetting("MultipageStorageFormat", MultipageStorageFormat, ClientID));
	StructuresArray.Add (GenerateSetting("Resolution", Resolution, ClientID));
	StructuresArray.Add (GenerateSetting("Chromaticity", Chromaticity, ClientID));
	StructuresArray.Add (GenerateSetting("Rotation", Rotation, ClientID));
	StructuresArray.Add (GenerateSetting("PaperSize", PaperSize, ClientID));
	StructuresArray.Add (GenerateSetting("DuplexScanning", DuplexScanning, ClientID));
	StructuresArray.Add (GenerateSetting("UseImageMagickToConvertToPDF", UseImageMagickToConvertToPDF, ClientID));
	StructuresArray.Add (GenerateSetting("JPGQuality", JPGQuality, ClientID));
	StructuresArray.Add (GenerateSetting("TIFFDeflation", TIFFDeflation, ClientID));
	StructuresArray.Add (GenerateSetting("PathToConverterApplication", PathToConverterApplication, ClientID));
	
	CommonServerCall.CommonSettingsStorageSaveArray(StructuresArray, True);
	Close();
	
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
Function GenerateSetting(Name, Value, ClientID)
	
	Item = New Structure;
	Item.Insert("Object", "ScanningSettings1/" + Name);
	Item.Insert("Setting", ClientID);
	Item.Insert("Value", Value);
	Return Item;
	
EndFunction	

&AtClient
Procedure RefreshStatus()
	
	Items.DeviceName.Enabled = False;
	Items.DeviceName.ChoiceList.Clear();
	Items.DeviceName.ListChoiceMode = False;
	Items.ScannedImageFormat.Enabled = False;
	Items.Resolution.Enabled = False;
	Items.Chromaticity.Enabled = False;
	Items.Rotation.Enabled = False;
	Items.PaperSize.Enabled = False;
	Items.DuplexScanning.Enabled = False;
	Items.CustomizeStandardSettings.Enabled = False;
	
	If Not FilesOperationsInternalClient.InitAddIn() Then
		Items.DeviceName.Enabled = False;
		Return;
	EndIf;
		
	If Not FilesOperationsInternalClient.ScanCommandAvailable() Then
		Items.DeviceName.Enabled = False;
		Return;
	EndIf;
		
	DeviceArray = FilesOperationsInternalClient.EnumDevices();
	For Each String In DeviceArray Do
		Items.DeviceName.ChoiceList.Add(String);
	EndDo;
	Items.DeviceName.Enabled = True;
	Items.DeviceName.ListChoiceMode = True;
	
	If IsBlankString(DeviceName) Then
		Return;
	EndIf;
	
	Items.ScannedImageFormat.Enabled = True;
	Items.Resolution.Enabled = True;
	Items.Chromaticity.Enabled = True;
	Items.CustomizeStandardSettings.Enabled = True;
	
	DuplexScanningNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "DUPLEX");
	
	Items.DuplexScanning.Enabled = (DuplexScanningNumber <> -1);
	
	If Not Resolution.IsEmpty() And Not Chromaticity.IsEmpty() Then
		Items.Rotation.Enabled = Not Rotation.IsEmpty();
		Items.PaperSize.Enabled = Not PaperSize.IsEmpty();
		Return;
	EndIf;
	
	PermissionNumber = FilesOperationsInternalClient.GetSetting(DeviceName, "XRESOLUTION");
	ChromaticityNumber  = FilesOperationsInternalClient.GetSetting(DeviceName, "PIXELTYPE");
	RotationNumber = FilesOperationsInternalClient.GetSetting(DeviceName, "ROTATION");
	PaperSizeNumber  = FilesOperationsInternalClient.GetSetting(DeviceName, "SUPPORTEDSIZES");
	
	Items.Rotation.Enabled = (RotationNumber <> -1);
	Items.PaperSize.Enabled = (PaperSizeNumber <> -1);
	
	DuplexScanning = ? ((DuplexScanningNumber = 1), True, False);
	SaveToSettingsScannerParameters(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
	
EndProcedure

&AtServer
Procedure SaveToSettingsScannerParameters(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber) 
	
	ConvertScannerParametersToEnums(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
			
	StructuresArray = New Array;
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	
	Item = New Structure;
	Item.Insert("Object", "ScanningSettings1/Resolution");
	Item.Insert("Setting", ClientID);
	Item.Insert("Value", Resolution);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ScanningSettings1/Chromaticity");
	Item.Insert("Setting", ClientID);
	Item.Insert("Value", Chromaticity);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ScanningSettings1/Rotation");
	Item.Insert("Setting", ClientID);
	Item.Insert("Value", Rotation);
	StructuresArray.Add(Item);
	
	Item = New Structure;
	Item.Insert("Object", "ScanningSettings1/PaperSize");
	Item.Insert("Setting", ClientID);
	Item.Insert("Value", PaperSize);
	StructuresArray.Add(Item);
	
	Common.CommonSettingsStorageSaveArray(StructuresArray);
	
EndProcedure

&AtClient
Procedure ReadScannerSettings()
	
	Items.ScannedImageFormat.Enabled = Not IsBlankString(DeviceName);
	Items.Resolution.Enabled = Not IsBlankString(DeviceName);
	Items.Chromaticity.Enabled = Not IsBlankString(DeviceName);
	Items.DuplexScanning.Enabled = False;
	Items.CustomizeStandardSettings.Enabled = Not IsBlankString(DeviceName);
	
	If IsBlankString(DeviceName) Then
		Items.Rotation.Enabled = False;
		Items.PaperSize.Enabled = False;
		Return;
	EndIf;
	
	PermissionNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "XRESOLUTION");
	
	ChromaticityNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "PIXELTYPE");
	
	RotationNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "ROTATION");
	
	PaperSizeNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "SUPPORTEDSIZES");
	
	DuplexScanningNumber = FilesOperationsInternalClient.GetSetting(
		DeviceName, "DUPLEX");
	
	Items.Rotation.Enabled = (RotationNumber <> -1);
	Items.PaperSize.Enabled = (PaperSizeNumber <> -1);
	
	Items.DuplexScanning.Enabled = (DuplexScanningNumber <> -1);
	DuplexScanning = ? ((DuplexScanningNumber = 1), True, False);
	
	ConvertScannerParametersToEnums(
		PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
		
EndProcedure

&AtServer
Procedure ConvertScannerParametersToEnums(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber) 
	
	Result = FilesOperationsInternal.ScannerParametersInEnumerations(PermissionNumber, ChromaticityNumber, RotationNumber, PaperSizeNumber);
	Resolution = Result.Resolution;
	Chromaticity = Result.Chromaticity;
	Rotation = Result.Rotation;
	PaperSize = Result.PaperSize;
	
EndProcedure

&AtServer
Function ConvertScanningFormatToStorageFormat(ScanningFormat)
	
	If ScanningFormat = Enums.ScannedImageFormats.BMP Then
		Return Enums.SinglePageFileStorageFormats.BMP;
	ElsIf ScanningFormat = Enums.ScannedImageFormats.GIF Then
		Return Enums.SinglePageFileStorageFormats.GIF;
	ElsIf ScanningFormat = Enums.ScannedImageFormats.JPG Then
		Return Enums.SinglePageFileStorageFormats.JPG;
	ElsIf ScanningFormat = Enums.ScannedImageFormats.PNG Then
		Return Enums.SinglePageFileStorageFormats.PNG; 
	ElsIf ScanningFormat = Enums.ScannedImageFormats.TIF Then
		Return Enums.SinglePageFileStorageFormats.TIF;
	EndIf;
	
	Return Enums.SinglePageFileStorageFormats.PNG; 
	
EndFunction	

&AtServer
Function ConvertStorageFormatToScanningFormat(StorageFormat)
	
	If StorageFormat = Enums.SinglePageFileStorageFormats.BMP Then
		Return Enums.ScannedImageFormats.BMP;
	ElsIf StorageFormat = Enums.SinglePageFileStorageFormats.GIF Then
		Return Enums.ScannedImageFormats.GIF;
	ElsIf StorageFormat = Enums.SinglePageFileStorageFormats.JPG Then
		Return Enums.ScannedImageFormats.JPG;
	ElsIf StorageFormat = Enums.SinglePageFileStorageFormats.PNG Then
		Return Enums.ScannedImageFormats.PNG; 
	ElsIf StorageFormat = Enums.SinglePageFileStorageFormats.TIF Then
		Return Enums.ScannedImageFormats.TIF;
	EndIf;
	
	Return ScannedImageFormat; 
	
EndFunction	

&AtServer
Procedure ProcessChangesUseImageMagick()
	
	If Not UseImageMagickToConvertToPDF Then
		MultipageStorageFormat = MultiPageTIFFormat;
		ScannedImageFormat = ConvertStorageFormatToScanningFormat(SinglePageStorageFormat);
		Items.ScannedImageFormat.Title = NStr("en = 'Format';");
	Else
		SinglePageStorageFormat = ConvertScanningFormatToStorageFormat(ScannedImageFormat);
		Items.ScannedImageFormat.Title = NStr("en = 'Type';");
	EndIf;	
	
	DecorationsVisible = (UseImageMagickToConvertToPDF And (SinglePageStorageFormat = SinglePagePDFFormat));
	Items.SinglePageStorageFormatDecoration.Visible = DecorationsVisible;
	Items.ScannedImageFormatDecoration.Visible = DecorationsVisible;
	
	ScanningFormatVisibility = (UseImageMagickToConvertToPDF And (SinglePageStorageFormat = SinglePagePDFFormat)) Or (Not UseImageMagickToConvertToPDF);
	Items.ScanningFormatGroup.Visible = ScanningFormatVisibility;
	
	Items.PathToConverterApplication.Enabled = UseImageMagickToConvertToPDF;
	Items.MultipageStorageFormat.Enabled = UseImageMagickToConvertToPDF;
	Items.StorageFormatGroup.Visible = UseImageMagickToConvertToPDF;	
	
EndProcedure

&AtServer
Procedure ProcessChangesSinglePageStorageFormat()
	
	Items.ScanningFormatGroup.Visible = (SinglePageStorageFormat = SinglePagePDFFormat);
	
	If SinglePageStorageFormat = SinglePagePDFFormat Then
		ScannedImageFormat = ConvertStorageFormatToScanningFormat(SinglePageStorageFormatPrevious);
	EndIf;	
	
	DecorationsVisible = (UseImageMagickToConvertToPDF And (SinglePageStorageFormat = SinglePagePDFFormat));
	Items.SinglePageStorageFormatDecoration.Visible = DecorationsVisible;
	Items.ScannedImageFormatDecoration.Visible = DecorationsVisible;
	
	If UseImageMagickToConvertToPDF Then
		If SinglePageStorageFormat = SinglePagePDFFormat Then
			Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
			Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
		Else	
			Items.JPGQuality.Visible = (SinglePageStorageFormat = SinglePageJPGFormat);
			Items.TIFFDeflation.Visible = (SinglePageStorageFormat = SinglePageTIFFormat);
		EndIf;
	Else	
		Items.JPGQuality.Visible = (ScannedImageFormat = JPGFormat);
		Items.TIFFDeflation.Visible = (ScannedImageFormat = TIFFormat);
	EndIf;
	
	SinglePageStorageFormatPrevious = SinglePageStorageFormat;
	
EndProcedure

#EndRegion
