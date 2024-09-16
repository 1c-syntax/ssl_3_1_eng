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

	OriginalStates = SourceDocumentsOriginalsRecording.AllStates();
	For Each State In OriginalStates Do 
		OriginalStatesList.Add(State,,False);
	EndDo;
	OriginalStatesList.Add("Statesnotable",NStr("en = '<Unknown state>';"),False);

	For Each State In Parameters.StatesList Do
		 FoundState = OriginalStatesList.FindByValue(State.Value);
		 If Not FoundState = Undefined Then
			FoundState.Check=True;
		EndIf;
	EndDo;


EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)

	NotifyChoice(OriginalStatesList);

EndProcedure

&AtClient
Procedure SelectAllCheckBoxes(Command)

	For Each CurrentFilter In OriginalStatesList Do
		CurrentFilter.Check = True;
	EndDo;

EndProcedure

&AtClient
Procedure ClearAllCheckBoxes(Command)

	For Each CurrentFilter In OriginalStatesList Do
		CurrentFilter.Check = False;
	EndDo;

EndProcedure

#EndRegion