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
	
	If Parameters.Deduplication Then
		Title = NStr("en = 'Invalid data found when deduplicating files';");
	EndIf;
	Explanation = Parameters.Explanation;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = DataProcessors.FileTransfer.GetTemplate("ReportTemplate");
	
	HeaderArea_ = Template.GetArea("Title");
	SpreadsheetDocument.Put(HeaderArea_);
	
	AreaRow = Template.GetArea("String");
	
	For Each Error In Parameters.FilesWithErrors Do
		AreaRow.Parameters.Name1 = Error.FileName;
		AreaRow.Parameters.Version = Error.Version;
		AreaRow.Parameters.Error = Error.Error;
		AreaRow.Parameters.Location = FileOwnerPresentation(Error.Version);
		
		Area = SpreadsheetDocument.Put(AreaRow);
		Area.RowHeight = 0;
		Area.AutoRowHeight = True;
	EndDo;
	
	Report.Put(SpreadsheetDocument);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReportSelection(Item, Area, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(Area.Details) Then
		Return;
	EndIf;
	ShowValue(Undefined, Area.Details);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FileOwnerPresentation(Val File)
	If TypeOf(File) = Type("CatalogRef.FilesVersions") Then
		File = Common.ObjectAttributeValue(File, "Owner");
	EndIf;
	
	FileOwner = Common.ObjectAttributeValue(File, "FileOwner");
	Return ?(FileOwner.IsEmpty(), 
		Common.ListPresentation(FileOwner.Metadata()),
		Common.SubjectString(FileOwner));
EndFunction	

#EndRegion
