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
	Var ArrayOfExchangePlanNodes, SelectionOfExchangePlanNodes;
	
	Parameters.Property("ArrayOfExchangePlanNodes", ArrayOfExchangePlanNodes);
	Parameters.Property("SelectionOfExchangePlanNodes", SelectionOfExchangePlanNodes);
	
	If TypeOf(ArrayOfExchangePlanNodes) = Type("Array") Then
		
		ThereIsAValidSelection = (TypeOf(SelectionOfExchangePlanNodes) = Type("Array"));
		
		For Each Synchronization In ArrayOfExchangePlanNodes Do
			
			NewRow = SynchronizationsList.Add();
			NewRow.Synchronization = Synchronization;
			NewRow.Use = (ThereIsAValidSelection And SelectionOfExchangePlanNodes.Find(Synchronization) <> Undefined);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SelectionOfExchangePlanNodes = New Array;
	For Each SyncString In SynchronizationsList Do
		
		If Not SyncString.Use Then
			
			Continue;
			
		EndIf;
		
		SelectionOfExchangePlanNodes.Add(SyncString.Synchronization);
		
	EndDo;
	
	Close(SelectionOfExchangePlanNodes);
	
EndProcedure

&AtClient
Procedure Reset(Command)
	
	For Each TableRow In SynchronizationsList Do
		
		TableRow.Use = False;
		
	EndDo;
	
EndProcedure

#EndRegion
