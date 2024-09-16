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
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Top;
		Items.FileVersionsComparisonMethod.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	StructuresArray = New Array;
	
	Item = New Structure;
	Item.Insert("Object", "FileComparisonSettings");
	Item.Insert("Setting", "FileVersionsComparisonMethod");
	Item.Insert("Value", FileVersionsComparisonMethod);
	StructuresArray.Add(Item);
	
	CommonServerCall.CommonSettingsStorageSaveArray(StructuresArray, True);
	
	SelectionResult = DialogReturnCode.OK;
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
