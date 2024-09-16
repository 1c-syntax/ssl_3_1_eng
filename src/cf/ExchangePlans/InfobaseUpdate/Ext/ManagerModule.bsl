///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns links to nodes with a queue smaller than the one passed.
//
// Parameters:
//  Queue	 - Number -  data processing queue.
// 
// Returns:
//   Array of ExchangePlanRef.InfobaseUpdate 
//
Function EarlierQueueNodes(Queue) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InfobaseUpdate.Ref AS Ref
	|FROM
	|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
	|WHERE
	|	InfobaseUpdate.Queue < &Queue
	|	AND NOT InfobaseUpdate.ThisNode
	|	AND NOT InfobaseUpdate.Temporary
	|	AND InfobaseUpdate.Queue <> 0";
	
	Query.SetParameter("Queue", Queue);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Searches for the exchange plan node in turn and returns a link to it.
// If the node doesn't exist yet, it will be created.
//
// Parameters:
//  Queue - Number -  data processing queue.
//  Temporary - Boolean - 
// 
// Returns:
//  ExchangePlanRef.InfobaseUpdate
//
Function NodeInQueue(Queue, Temporary = False) Export
	
	If TypeOf(Queue) <> Type("Number") Or Queue = 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get the node of exchange plan %1 because the position in queue is not provided.';"),
			"InfobaseUpdate");
	EndIf;
	
	Query = New Query(
		"SELECT
		|	InfobaseUpdate.Ref AS Ref
		|FROM
		|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
		|WHERE
		|	InfobaseUpdate.Queue = &Queue
		|	AND InfobaseUpdate.Temporary = &Temporary
		|	AND NOT InfobaseUpdate.ThisNode");
	Query.SetParameter("Queue", Queue);
	Query.SetParameter("Temporary", Temporary);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Node = Selection.Ref;
	Else
		BeginTransaction();
		
		Try
			Locks = New DataLock;
			Block = Locks.Add("ExchangePlan.InfobaseUpdate");
			Block.SetValue("Queue", Queue);
			Block.SetValue("Temporary", Temporary);
			Locks.Lock();
			
			Selection = Query.Execute().Select();
			
			If Selection.Next() Then
				Node = Selection.Ref;
			Else
				QueueString = String(Queue);
				ObjectNode = CreateNode();
				ObjectNode.Queue = Queue;
				ObjectNode.Temporary = Temporary;
				ObjectNode.SetNewCode(QueueString);
				ObjectNode.Description = QueueString + ?(Temporary, " " + NStr("en = 'New for restart';"), "");
				ObjectNode.Write();
				Node = ObjectNode.Ref;
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
	Return Node;
	
EndFunction

#EndRegion

#EndIf