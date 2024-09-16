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
	
	Title = NStr("en = 'Update handler';") + " " + Record.HandlerName;
	
	If ValueIsFilled(Record.Comment) Then
		Items.GroupComment.Title = NStr("en = 'Comment';") + " *";
	Else
		Items.GroupComment.Title = NStr("en = 'Comment';");
	EndIf;
	
	If ValueIsFilled(Record.ErrorInfo) Then
		Items.GroupErrorInfo.Title = NStr("en = 'Error details';") + " *";
	Else
		Items.GroupErrorInfo.Title = NStr("en = 'Error details';");
	EndIf;
	
	DataToProcess = NStr("en = 'Open';");
	
	Data = FormAttributeToValue("Record").DataToProcess;
	ProcessedDataStorage = PutToTempStorage(Data, UUID);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_UpdateHandlers", WriteParameters);
EndProcedure

#EndRegion
