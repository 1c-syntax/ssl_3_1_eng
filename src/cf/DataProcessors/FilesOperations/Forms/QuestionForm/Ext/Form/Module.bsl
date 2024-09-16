///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MessageQuestion = Parameters.MessageQuestion;
	MessageTitle = Parameters.MessageTitle;
	Title = Parameters.Title;
	Files = Parameters.Files;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFiles

&AtClient
Procedure FilesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	FileRef = Files[RowSelected].Value;
	
	PersonalSettings = FilesOperationsInternalClient.PersonalFilesOperationsSettings();
	HowToOpen = PersonalSettings.ActionOnDoubleClick;
	If HowToOpen = "OpenCard" Then
		FormParameters = New Structure;
		FormParameters.Insert("Key", FileRef);
		OpenForm("Catalog.Files.ObjectForm", FormParameters, ThisObject);
		Return;
	EndIf;
	
	FileData = FilesOperationsInternalServerCall.FileDataToOpen(FileRef, Undefined,UUID);
	FilesOperationsInternalClient.OpenFileWithNotification(Undefined, FileData);
	
EndProcedure

#EndRegion
