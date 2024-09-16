///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Procedure WriteANode(Node, NodeBeforeWrite) Export
	
	ObjectNode = Node.GetObject();
	
	For Each KeyAndValue In NodeBeforeWrite Do
		
		Var_Key = KeyAndValue.Key;
		Value = KeyAndValue.Value;
		
		If TypeOf(Value) = Type("ValueTable") Then
			ObjectNode[Var_Key].Load(Value);
		Else
			ObjectNode[Var_Key] = Value;	
		EndIf;
		
	EndDo;
	
	BeginTransaction();
	
	Try
			
		Block = New DataLock;
		LockItem = Block.Add(Common.TableNameByRef(Node));
		LockItem.SetValue("Ref", Node);
		Block.Lock();

		ObjectNode.AdditionalProperties.Insert("DeferredNodeWriting");
		ObjectNode.Write();
		
		Cancel  = False;
		DataExchangeServer.NodeFormOnWriteAtServer(ObjectNode, Cancel);

		CommitTransaction();

	Except
	
		RollbackTransaction();
	    Raise;
		
	EndTry;
	
EndProcedure


#EndRegion

#EndIf