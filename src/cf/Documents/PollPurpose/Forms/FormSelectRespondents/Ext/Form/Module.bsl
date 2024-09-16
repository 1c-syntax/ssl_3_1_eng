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
	
	If Catalogs.AllRefsType().ContainsType(TypeOf(Parameters.RespondentType)) Then
		
		ListPropertiesStructure = Common.DynamicListPropertiesStructure();
		ListPropertiesStructure.MainTable = Parameters.RespondentType.Metadata().FullName();
		
		Common.SetDynamicListProperties(Items.Respondents, ListPropertiesStructure);
		
	Else
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RespondentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ArrayToPass = New Array;
	
	For Each ArrayElement In RowSelected Do
		If Not Items.Respondents.RowData(ArrayElement).Property("IsFolder") 
			Or Not Items.Respondents.RowData(ArrayElement).IsFolder Then
			ArrayToPass.Add(ArrayElement);
		EndIf;
	EndDo;
	
	ProcessRespondentChoice(ArrayToPass);
	
EndProcedure

&AtClient
Procedure RespondentsValueChoice(Item, Value, StandardProcessing)
	
	ProcessRespondentChoice(Value);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessRespondentChoice(ChoiceArray)
	
	Notify("SelectRespondents",New Structure("SelectedRespondents",ChoiceArray));
	
EndProcedure

#EndRegion



