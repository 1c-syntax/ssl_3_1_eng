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
	
	Resolution = Parameters.Resolution;
	Chromaticity = Parameters.Chromaticity;
	Rotation = Parameters.Rotation;
	PaperSize = Parameters.PaperSize;
	DuplexScanning = Parameters.DuplexScanning;
	UseImageMagickToConvertToPDF = Parameters.UseImageMagickToConvertToPDF;
	ShowScannerDialog = Parameters.ShowScannerDialog;
	ScannedImageFormat = Parameters.ScannedImageFormat;
	JPGQuality = Parameters.JPGQuality;
	TIFFDeflation = Parameters.TIFFDeflation;
	SinglePageStorageFormat = Parameters.SinglePageStorageFormat;
	MultipageStorageFormat = Parameters.MultipageStorageFormat;
	
	Items.Rotation.Visible = Parameters.RotationAvailable;
	Items.PaperSize.Visible = Parameters.PaperSizeAvailable;
	Items.DuplexScanning.Visible = Parameters.DuplexScanningAvailable;
	
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
	
	Items.MultipageStorageFormat.Enabled = UseImageMagickToConvertToPDF;
	SinglePageStorageFormatPrevious = SinglePageStorageFormat;
	
	If Not UseImageMagickToConvertToPDF Then
		Items.ScannedImageFormat.Title = NStr("en = 'Format';");
	Else
		Items.ScannedImageFormat.Title = NStr("en = 'Type';");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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
Procedure SinglePageStorageFormatOnChange(Item)
	
	ProcessChangesSinglePageStorageFormat();
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	If Not CheckFilling() Then 
		Return;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("ShowScannerDialog",  ShowScannerDialog);
	SelectionResult.Insert("Resolution",               Resolution);
	SelectionResult.Insert("Chromaticity",                Chromaticity);
	SelectionResult.Insert("Rotation",                  Rotation);
	SelectionResult.Insert("PaperSize",             PaperSize);
	SelectionResult.Insert("DuplexScanning", DuplexScanning);
	
	SelectionResult.Insert("UseImageMagickToConvertToPDF",
		UseImageMagickToConvertToPDF);
	
	SelectionResult.Insert("ScannedImageFormat", ScannedImageFormat);
	SelectionResult.Insert("JPGQuality",                     JPGQuality);
	SelectionResult.Insert("TIFFDeflation",                      TIFFDeflation);
	SelectionResult.Insert("SinglePageStorageFormat",    SinglePageStorageFormat);
	SelectionResult.Insert("MultipageStorageFormat",   MultipageStorageFormat);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

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
