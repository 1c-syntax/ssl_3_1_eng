///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Redefining the settings of attached files.
//
// Parameters:
//   Settings - Structure:
//     * DontClearFiles - Array of MetadataObject -  objects whose files should not be displayed in 
//                        the file cleaning settings (for example, service documents).
//     * NotSynchronizeFiles - Array of MetadataObject -  objects whose files should not be displayed in 
//                        the synchronization settings with cloud services (for example, service documents).
//     * DontCreateFilesByTemplate - Array of MetadataObject -  objects for which the ability 
//                        to create files based on templates is disabled.
//
// Example:
//       
//       
//       
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Allows you to redefine file storage directories by owner type.
// 
// Parameters:
//  TypeFileOwner  - Type -  the reference type of the object to which the file is being added.
//
//  CatalogNames - Map of KeyAndValue:
//    * Key - String     - 
//    * Value - Boolean -  
//                           
//
// Example:
//       
//       	
//       	
//       
//
Procedure OnDefineFileStorageCatalogs(TypeFileOwner, CatalogNames) Export
	
EndProcedure

// Allows you to cancel the capture of a file based on the analysis of the structure with the file data.
//
// Parameters:
//  FileData    - See FilesOperations.FileData.
//  ErrorDescription - String -  error text if the file cannot be occupied.
//                   If it is not empty, the file cannot be occupied.
//
Procedure OnAttemptToLockFile(FileData, ErrorDescription = "") Export
	
EndProcedure

// Called when creating a file. For example, it can be used to process logically related data
// that should change when creating new files.
//
// Parameters:
//  File - DefinedType.AttachedFile -  link to the created file.
//
Procedure OnCreateFile(File) Export
	
EndProcedure

// 
// 
//
// Parameters:
//  NewFile    - CatalogRef.Files -  the link to the new file that need to be filled.
//  SourceFile - CatalogRef.Files -  link to the source file where you need to copy the details.
//
Procedure FillFileAtributesFromSourceFile(NewFile, SourceFile) Export
	
EndProcedure

// Called when a file is captured. Allows you to change the structure with the file data before capturing.
//
// Parameters:
//  FileData             - See FilesOperations.FileData.
//  UUID - UUID -  unique form ID.
//
Procedure OnLockFile(FileData, UUID) Export
	
EndProcedure

// Called when a file is released. Allows you to change the structure with file data when releasing.
//
// Parameters:
//  FileData - See FilesOperations.FileData.
//  UUID -  UUID -  unique form ID.
//
Procedure OnUnlockFile(FileData, UUID) Export
	
EndProcedure

// Allows you to define email parameters before sending the file by mail.
//
// Parameters:
//  SendOptions - See EmailOperationsClient.EmailSendOptions.
//  FilesToSend  - Array of DefinedType.AttachedFile - 
//  FilesOwner    - DefinedType.AttachedFilesOwner -  object that owns the files.
//  UUID - UUID -  a unique identifier
//                that must be used if data needs to be placed in temporary storage.
//
Procedure OnSendFilesViaEmail(SendOptions, FilesToSend, FilesOwner, UUID) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//  StampParameters - Structure - :
//      * MarkText         - String -  description of the location of the original signed document.
//      * Logo              - Picture -  the logo that will be displayed in the stamp.
//  Certificate      - CryptoCertificate -  the certificate used to generate the electronic signature stamp.
//
Procedure OnPrintFileWithStamp(StampParameters, Certificate) Export
	
EndProcedure

// 
//
// Parameters:
//    Form - ClientApplicationForm - :
//      * FilesStorageCatalogName - String
//      * FileOwner - DefinedType.FilesOwner
//
Procedure OnCreateFilesListForm(Form) Export
	
EndProcedure

// 
//
// Parameters:
//    Form - ClientApplicationForm - :
//      * Object - DefinedType.AttachedFile
//
Procedure OnCreateFilesItemForm(Form) Export
	
EndProcedure

// Allows you to change the structure of parameters for placing hyperlinks of attached files on the form.
//
// Parameters:
//  HyperlinkParameters - See FilesOperations.FilesHyperlink.
//
// Example:
//  Parameter of the hyperlink.Placement = " Command Panel";
//
Procedure OnDefineFilesHyperlink(HyperlinkParameters) Export
	
EndProcedure

#EndRegion

