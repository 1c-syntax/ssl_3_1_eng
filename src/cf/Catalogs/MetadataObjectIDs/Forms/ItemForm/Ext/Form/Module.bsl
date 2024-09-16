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
	
	Catalogs.MetadataObjectIDs.ItemFormOnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

&AtClient
Procedure FullNameOnChange(Item)
	
	FullName = Object.FullName;
	UpdateIDProperties();
	
	If FullName <> Object.FullName Then
		Object.FullName = FullName;
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Metadata object is not found by full name:
			           |%1.';"),
			FullName));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateIDProperties()
	
	Catalogs.MetadataObjectIDs.UpdateIDProperties(Object);
	
EndProcedure

#EndRegion
