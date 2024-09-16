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
	
	If Parameters.Key.IsEmpty() Then
		IsNewRecord = True;
		Items.LatestUpdatedItemDate.ReadOnly = True;
		Items.UniqueKey.ReadOnly = True;
		Items.RegisterRecordChangeDate.ReadOnly = True;
		Record.JobSize = 3;
	EndIf;
	
	ReadOnly = True;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not IsNewRecord Then
		Return;
	EndIf;
	
	CurrentObject.LatestUpdatedItemDate = AccessManagementInternal.MaxDate();
	CurrentObject.UniqueKey = New UUID;
	CurrentObject.RegisterRecordChangeDate = CurrentSessionDate();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	IsNewRecord = False;
	
	Items.LatestUpdatedItemDate.ReadOnly = False;
	Items.UniqueKey.ReadOnly = False;
	Items.RegisterRecordChangeDate.ReadOnly = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion
