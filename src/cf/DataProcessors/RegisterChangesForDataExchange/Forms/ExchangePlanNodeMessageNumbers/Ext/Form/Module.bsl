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
	
	If Not Parameters.Property("ExchangeNodeReference", ExchangeNodeReference) Then
		Cancel = True;
		Return;
	EndIf;
	
	Title = ExchangeNodeReference;
	
	ReadMessageNumbers();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Writes the changed data and closes the form.
//
&AtClient
Procedure WriteNodeChanges(Command)
	
	WriteMessageNumbers();
	Notify("ExchangeNodeDataEdit", ExchangeNodeReference, ThisObject);
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ThisObject() 
	
	Return FormAttributeToValue("Object");
	
EndFunction

&AtServer
Procedure ReadMessageNumbers()
	
	Data = ThisObject().GetExchangeNodeParameters(ExchangeNodeReference, "SentNo, ReceivedNo");
	FillPropertyValues(ThisObject, Data);
	
EndProcedure

&AtServer
Procedure WriteMessageNumbers()
	
	Data = New Structure("SentNo, ReceivedNo", SentNo, ReceivedNo);
	ThisObject().SetExchangeNodeParameters(ExchangeNodeReference, Data);
	
EndProcedure

#EndRegion
