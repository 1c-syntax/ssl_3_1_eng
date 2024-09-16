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
	
	CreateMode = Parameters.CreateMode;
	
	If Parameters.ScanCommandAvailable Then
		If Parameters.ScanCommandAvailable Then
			Items.CreateMode.ChoiceList.Add(3, NStr("en = 'From scanner';"));
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateFileExecute()
	Close(CreateMode);
EndProcedure

#EndRegion