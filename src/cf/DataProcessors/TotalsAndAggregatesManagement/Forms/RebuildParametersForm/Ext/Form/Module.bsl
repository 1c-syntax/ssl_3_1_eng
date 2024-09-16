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
	
	RelativeSize = Parameters.RelativeSize;
	MinimumEffect = Parameters.MinimumEffect;
	Items.MinimumEffect.Visible = Parameters.RebuildMode;
	Title = ?(Parameters.RebuildMode,
	              NStr("en = 'Rebuild parameters';"),
	              NStr("en = 'Parameter of optimal aggregate calculation';"));
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure("RelativeSize, MinimumEffect");
	FillPropertyValues(SelectionResult, ThisObject);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion
