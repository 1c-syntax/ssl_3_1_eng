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
	
	// 
	
	UsedSections = New Array;
	If Parameters.DataProcessorKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalDataProcessorSections();
	Else
		UsedSections = AdditionalReportsAndDataProcessors.AdditionalReportSections();
	EndIf;
	
	Desktop = AdditionalReportsAndDataProcessorsClientServer.StartPageName();
	
	For Each Section In UsedSections Do
		NewRow = Sections.Add();
		If Section = Desktop Then
			NewRow.Section = Catalogs.MetadataObjectIDs.EmptyRef();
		Else
			NewRow.Section = Common.MetadataObjectID(Section);
		EndIf;
		NewRow.Presentation = AdditionalReportsAndDataProcessors.SectionPresentation(NewRow.Section);
	EndDo;
	
	Sections.Sort("Presentation Asc");
	
	// 
	
	For Each ListItem In Parameters.Sections Do
		FoundRow = Sections.FindRows(New Structure("Section", ListItem.Value));
		If FoundRow.Count() = 1 Then
			FoundRow[0].Used = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New ValueList;
	
	For Each ItemSection In Sections Do
		If ItemSection.Used Then
			SelectionResult.Add(ItemSection.Section);
		EndIf;
	EndDo;
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
