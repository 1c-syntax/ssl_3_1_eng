///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Initializes the parameter structure for retrieving file data.  See FilesOperations.FileData.
//
// Returns:
//  Structure:
//    * FormIdentifier             - UUID -  unique ID of the form
//                                     to put the file in temporary storage and return the address in the link property of the binary data File.
//                                     The default value is Undefined.
//    * GetBinaryDataRef - Boolean -  if passed False, the binary data reference in the binary data file
//                                     reference Will not be received, which will significantly speed up execution for large binary data.
//                                     The default value is True.
//    * ForEditing              - Boolean -  if set to True, the file will be captured for editing.
//                                     The default value is False.
//    * RaiseException1             - Boolean -  if you specify False, the function will not throw exceptions in exceptional situations
//                                     and will return Undefined. The default value is True.
//
Function FileDataParameters() Export
	
	DataParameters = New Structure;
	DataParameters.Insert("ForEditing",              False);
	DataParameters.Insert("FormIdentifier",             Undefined);
	DataParameters.Insert("RaiseException1",             True);
	DataParameters.Insert("GetBinaryDataRef", True);
	Return DataParameters;
	
EndFunction

// Handler for subscribing to the event processingform Receipt to redefine the file form.
//
// Parameters:
//  Source                 - CatalogManager -  directory Manager with the name "*Attached files".
//  FormType                 - String -  name of the standard form.
//  Parameters                - Structure -  shape parameter.
//  SelectedForm           - String -  name or metadata object of the form to open.
//  AdditionalInformation - Structure -  additional information for opening the form.
//  StandardProcessing     - Boolean -  indicates whether standard (system) event processing is performed.
//
Procedure DetermineAttachedFileForm(Source, FormType, Parameters,
	SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	FilesOperationsInternalServerCall.DetermineAttachedFileForm(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
		
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * ShowScannerDialog - Boolean
//   * DeviceName - String - 
//   * ScannedImageFormat - EnumRef.ScannedImageFormats
//   * ShouldSaveAsPDF - Boolean
//   * MultipageStorageFormat - EnumRef.MultipageFileStorageFormats 
//   * Resolution - EnumRef.ScannedImageResolutions
//   * Chromaticity - EnumRef.ImageColorDepths
//   * Rotation - EnumRef.PictureRotationOptions
//   * PaperSize - EnumRef.PaperSizes
//   * DuplexScanning - Boolean
//   * DocumentAutoFeeder - Boolean
//   * UseImageMagickToConvertToPDF - Boolean
//   * JPGQuality - Number
//   * TIFFDeflation - EnumRef.TIFFCompressionTypes
//   * PathToConverterApplication - String
//
Function UserScanSettings() Export
	Result = New Structure;
	Result.Insert("ShowScannerDialog", False);
	Result.Insert("DeviceName", "");
	Result.Insert("ScannedImageFormat");
	Result.Insert("ShouldSaveAsPDF", False);
	Result.Insert("MultipageStorageFormat");
	Result.Insert("Resolution");
	Result.Insert("Chromaticity");
	Result.Insert("Rotation");
	Result.Insert("PaperSize");
	Result.Insert("DuplexScanning", False);
	Result.Insert("DocumentAutoFeeder", False);
	Result.Insert("UseImageMagickToConvertToPDF", False);
	Result.Insert("JPGQuality", 0);
	Result.Insert("TIFFDeflation");
	Result.Insert("PathToConverterApplication", "");
	Result.Insert("ScanLogCatalog");
	Result.Insert("UseScanLogDirectory", False);
	Return Result;
EndFunction

#EndRegion

#Region Internal

// Initializes a structure with information about the file.
//
// Parameters:
//   Mode        - String -  "File" or "Failurea".
//   SourceFile - File   -  the file that is used to fill in the structure properties.
//
// Returns:
//   Structure:
//    * BaseName             - String -  file name without extension.
//    * ExtensionWithoutPoint           - String -  file extension.
//    * Modified               - Date   -  date and time when the file was modified.
//    * ModificationTimeUniversal  - Date   -  UTC date and time when the file was modified.
//    * Size                       - Number  -  file size in bytes.
//    * TempFileStorageAddress  - String
//                                     - ValueStorage - 
//                                       
//    * TempTextStorageAddress - String
//                                     - ValueStorage - 
//                                       
//    * IsWebClient                 - Boolean -  True if the call comes from a web client.
//    * Author                        - CatalogRef.Users -  author of the file. If Undefined, then the current
//                                                                     user.
//    * Comment                  - String -  comment on the file.
//    * WriteToHistory             - Boolean -  write to the user's work history.
//    * StoreVersions                - Boolean -  allow storing versions of a file in the IB;
//                                              when creating a new version-create a new version, or change
//                                              an existing one (False).
//    * Encrypted                   - Boolean -  the file is encrypted.
//
Function FileInfo1(Val Mode, Val SourceFile = Undefined) Export
	
	Result = New Structure;
	Result.Insert("BaseName");
	Result.Insert("Comment", "");
	Result.Insert("TempTextStorageAddress");
	Result.Insert("Author");
	Result.Insert("FilesStorageCatalogName", "Files");
	Result.Insert("TempFileStorageAddress");
	Result.Insert("ExtensionWithoutPoint");
	Result.Insert("Modified", Date('00010101'));
	Result.Insert("ModificationTimeUniversal", Date('00010101'));
	Result.Insert("Size", 0);
	Result.Insert("Encrypted");
	Result.Insert("WriteToHistory", False);
	Result.Insert("Encoding");
	Result.Insert("NewTextExtractionStatus");
	If Mode = "FileWithVersion" Then
		Result.Insert("StoreVersions", True);
		Result.Insert("RefToVersionSource");
		Result.Insert("NewVersionCreationDate");
		Result.Insert("NewVersionAuthor");
		Result.Insert("NewVersionComment");
		Result.Insert("NewVersionVersionNumber");
	Else
		Result.Insert("StoreVersions", False);
	EndIf;
	
	If SourceFile <> Undefined Then
		Result.BaseName            = SourceFile.BaseName;
		Result.ExtensionWithoutPoint          = CommonClientServer.ExtensionWithoutPoint(SourceFile.Extension);
		Result.Modified              = SourceFile.GetModificationTime();
		Result.ModificationTimeUniversal = SourceFile.GetModificationUniversalTime();
		Result.Size                      = SourceFile.Size();
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// 
//
// Parameters:
//  FileData  - Structure -  the structure of the data file.
//  MessageText - String - 
//                            
//
// Returns:
//  Boolean - 
//           
//
Function WhetherPossibleLockFile(FileData, MessageText = "") Export
	
	If FileData.DeletionMark Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot edit file ""%1""
				|as it is marked for deletion.';"),
			String(FileData.Ref));
		Return False;
	EndIf;
	
	If FileData.IsInternal Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot edit service file ""%1"".';"),
			String(FileData.Ref));
		Return False;
	EndIf;

	Result = Not ValueIsFilled(FileData.BeingEditedBy) Or FileData.CurrentUserEditsFile;  
	If Not Result Then
		If ValueIsFilled(FileData.LockedDate) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1""
					| is locked for editing by user ""%2"" on %3.';"),
				String(FileData.Ref), String(FileData.BeingEditedBy), Format(FileData.LockedDate, "DLF=DT"));
		Else
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'File ""%1""
					| is locked for editing by user
					|""%2"".';"),
				String(FileData.Ref), String(FileData.BeingEditedBy));
		EndIf;
	EndIf;
		
	Return Result;
	
EndFunction

Function OneFileOnlyText() Export
	Return "OneFileOnly";
EndFunction

Function CommandsPrefix() Export
	Return "AttachedFilesManagement";
EndFunction

Function ImportFileCommandName() Export
	Return "ImportFile_";
EndFunction

Function CreateFromTemplateCommandName() Export
	Return "CreateByTemplate";
EndFunction

Function ScanCommandName() Export
	Return "Scan";
EndFunction

Function OpenListCommandName() Export
	Return "OpenList";
EndFunction

Function SelectFileCommandName() Export
	Return "SelectFile";
EndFunction

Function ViewFileCommandName() Export
	Return "ViewFile1";
EndFunction

Function ClearCommandName() Export
	Return "Clear";
EndFunction

Function OpenFormCommandName() Export
	Return "OpenForm";
EndFunction

Function EditFileCommandName() Export
	Return "EditFile";
EndFunction

Function PutFileCommandName() Export
	Return "PutFile";
EndFunction

Function CancelEditCommandName() Export
	Return "CancelEdit";
EndFunction

Function NameOfAdditionalCommandFromContextMenu() Export
	Return "FromContextMenu";
EndFunction

#EndRegion