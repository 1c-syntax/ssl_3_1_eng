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
	
	If Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'My additional data processors (%1)';"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	ElsIf Parameters.DataProcessorsKind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'My additional reports (%1)';"), 
			AdditionalReportsAndDataProcessors.SectionPresentation(Parameters.SectionRef));
	EndIf;
	
	CommandsTypes = New Array;
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ClientMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.ServerMethodCall);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.OpeningForm);
	CommandsTypes.Add(Enums.AdditionalDataProcessorsCallMethods.SafeModeScenario);
	
	Query = AdditionalReportsAndDataProcessors.NewQueryByAvailableCommands(Parameters.DataProcessorsKind, Parameters.SectionRef, , CommandsTypes, False);
	ResultTable1 = Query.Execute().Unload();
	UsedCommands.Load(ResultTable1);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UncheckAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = False;
	EndDo;
EndProcedure

&AtClient
Procedure CheckAll(Command)
	For Each TableRow In UsedCommands Do
		TableRow.Use = True;
	EndDo;
EndProcedure

&AtClient
Procedure OK(Command)
	WriteUserDataProcessorsSet();
	NotifyChoice("MyReportsAndDataProcessorsSetupDone");
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteUserDataProcessorsSet()
	Table = UsedCommands.Unload();
	Table.Columns.Ref.Name        = "AdditionalReportOrDataProcessor";
	Table.Columns.Id.Name = "CommandID";
	Table.Columns.Use.Name = "Available";
	DimensionValues = New Structure("User", Users.AuthorizedUser());
	ResourcesValues  = New Structure;
	SetPrivilegedMode(True);
	InformationRegisters.DataProcessorAccessUserSettings.WriteSettingsPackage(Table, DimensionValues, ResourcesValues, False);
EndProcedure

#EndRegion
