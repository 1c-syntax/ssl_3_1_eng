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
	
	ReadOnly = True;
	
	FieldsCompositionDetails = FieldsCompositionDetails(Object.FieldsComposition);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
	ShowMessageBox(,
		NStr("en = 'It is recommended that you do not change the access key as it is mapped to different objects.
		           |To resolve the issue, delete the access key or
		           |delete the mapping between the key and the objects from the registers, and then run the access update.';"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FieldsCompositionDetails(FieldsComposition)
	
	CurrentCount1 = FieldsComposition;
	Details = "";
	
	TabularSectionNumber = 0;
	While CurrentCount1 > 0 Do
		Balance = CurrentCount1 - Int(CurrentCount1 / 16) * 16;
		If TabularSectionNumber = 0 Then
			Details = NStr("en = 'Header';") + ": " + Balance;
		Else
			Details = Details + ", " + NStr("en = 'Tabular section';") + " " + TabularSectionNumber + ": " + Balance;
		EndIf;
		CurrentCount1 = Int(CurrentCount1 / 16);
		TabularSectionNumber = TabularSectionNumber + 1;
	EndDo;
	
	Return Details;
	
EndFunction

#EndRegion
