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
	
	ChangeInTransaction = Parameters.ChangeInTransaction;
	ProcessRecursively = Parameters.ProcessRecursively;
	DeveloperMode = Parameters.DeveloperMode;
	DisableSelectionParameterConnections = Parameters.DisableSelectionParameterConnections;
	InterruptOnError = Parameters.InterruptOnError;
	
	HasDataAdministrationRight = AccessRight("DataAdministration", Metadata);
	WindowOptionsKey = ?(HasDataAdministrationRight, "HasDataAdministrationRight", "NoDataAdministrationRight");
	
	CanShowInternalAttributes = Not Parameters.ContextCall And HasDataAdministrationRight;
	Items.ShowInternalAttributesGroup.Visible = CanShowInternalAttributes;
	Items.DeveloperMode.Visible = CanShowInternalAttributes;
	Items.DisableSelectionParameterConnections.Visible = CanShowInternalAttributes;
	
	If CanShowInternalAttributes Then
		ShowInternalAttributes = Parameters.ShowInternalAttributes;
	EndIf;
	
	Items.ProcessRecursivelyGroup.Visible = Parameters.ContextCall And Parameters.IncludeHierarchy;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetFormItems();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChangeInTransactionOnChange(Item)
	
	SetFormItems();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionResult = New Structure;
	SelectionResult.Insert("ChangeInTransaction",            ChangeInTransaction);
	SelectionResult.Insert("ProcessRecursively",         ProcessRecursively);
	SelectionResult.Insert("BatchSetting",                BatchSetting);
	SelectionResult.Insert("ObjectsPercentageInBatch",         ObjectsPercentageInBatch);
	SelectionResult.Insert("InterruptOnError",             ChangeInTransaction Or InterruptOnError);
	SelectionResult.Insert("ShowInternalAttributes",   ShowInternalAttributes);
	SelectionResult.Insert("DeveloperMode",              DeveloperMode);
	SelectionResult.Insert("DisableSelectionParameterConnections", DisableSelectionParameterConnections);
	
	NotifyChoice(SelectionResult);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetFormItems()
	
	Items.AbortOnErrorGroup.Enabled = Not ChangeInTransaction;
	
EndProcedure

#EndRegion
