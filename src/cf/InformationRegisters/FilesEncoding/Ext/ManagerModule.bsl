///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the encoding of the file version.
//
// Parameters:
//   VersionRef - DefinedType.AttachedFile -  file version.
//
// Returns:
//   String
//
Function FileVersionEncoding(VersionRef) Export
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.FilesEncoding.CreateRecordManager();
	RecordManager.File = VersionRef;
	RecordManager.Read();
	
	Return RecordManager.Encoding;
	
EndFunction

// Records the encoding of the file version.
//
// Parameters:
//   VersionRef - DefinedType.AttachedFile -  link to the file version.
//   Encoding - String -  new encoding of the file version.
//
Procedure WriteFileVersionEncoding(VersionRef, Encoding) Export
	
	If Not ValueIsFilled(Encoding) Then
		Return;
	EndIf;
	
	If ValueIsFilled(InformationRegisters.FilesEncoding.FileVersionEncoding(VersionRef)) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RecordManager = InformationRegisters.FilesEncoding.CreateRecordManager();
	RecordManager.File = VersionRef;
	RecordManager.Encoding = Encoding;
	RecordManager.Write(True);
	
EndProcedure

// Automatically detects and returns the encoding of a text file.
//
// Parameters:
//  AttachedFile - DefinedType.AttachedFile
//  Extension         - String -  file extension.
//
// Returns:
//  String
//
Function DefineFileEncoding(AttachedFile, Extension) Export
	
	Encoding = FileVersionEncoding(AttachedFile);
	If ValueIsFilled(Encoding) Then
		Return Encoding;
	EndIf;
		
	CommonSettings = FilesOperationsInternalCached.FilesOperationSettings().CommonSettings;
	EncodingAutoDetection = FilesOperationsInternalClientServer.FileExtensionInList(
		CommonSettings.TextFilesExtensionsList, Extension);
	If Not EncodingAutoDetection Then
		Return Encoding;
	EndIf;
		
	BinaryData = FilesOperations.FileBinaryData(AttachedFile, False);
	Encoding = FilesOperationsInternalClientServer.DetermineBinaryDataEncoding(BinaryData, Extension);
	Return Encoding;
	
EndFunction

#EndRegion

#EndIf
