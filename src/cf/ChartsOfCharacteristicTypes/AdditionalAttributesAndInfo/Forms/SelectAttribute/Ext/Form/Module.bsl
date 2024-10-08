﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AttributesTable = GetFromTempStorage(Parameters.ObjectAttributes);
	ValueToFormAttribute(AttributesTable, "ObjectAttributes");
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectCommand(Command)
	SelectItemAndClose();
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure ObjectAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	SelectItemAndClose();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectItemAndClose()
	RowSelected = Items.ObjectAttributes.CurrentData;
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("Attribute", RowSelected.Attribute);
	ChoiceParameters.Insert("Presentation", RowSelected.Presentation);
	ChoiceParameters.Insert("ValueType", RowSelected.ValueType);
	ChoiceParameters.Insert("ChoiceMode", RowSelected.ChoiceMode);
	
	Notify("PropertiesObjectAttributeSelection", ChoiceParameters);
	
	Close();
EndProcedure

#EndRegion