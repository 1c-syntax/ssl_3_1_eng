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
	
	If Not ValueIsFilled(Parameters.AttributesOfDateType) Then // 
		Return;
	EndIf;
	
	HasOnlyOneAttribute = Parameters.AttributesOfDateType.Count() = 1;
	
	For Each Attribute In Parameters.AttributesOfDateType Do
		Items.DateTypeAttribute.ChoiceList.Add(Attribute.Value, Attribute.Presentation);
		If HasOnlyOneAttribute Then
			DateTypeAttribute = Attribute.Value;
		EndIf;
	EndDo;
	
	If Common.IsMobileClient() Then
		Items.IntervalException.TitleLocation = FormItemTitleLocation.Top;
		Items.DateTypeAttribute.TitleLocation = FormItemTitleLocation.Top;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ResultingStructure = New Structure();
	ResultingStructure.Insert("IntervalException", IntervalException);
	ResultingStructure.Insert("DateTypeAttribute", DateTypeAttribute);
	
	NotifyChoice(ResultingStructure);

EndProcedure

#EndRegion