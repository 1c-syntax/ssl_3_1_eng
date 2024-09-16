///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPriority(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	MD5Hash = New DataHashing(HashFunction.MD5);
	MD5Hash.Append(Name);
	NameHashTmp = MD5Hash.HashSum;
	NameHash = StrReplace(String(NameHashTmp), " ", "");
EndProcedure

#EndRegion

#Region Private

Procedure CheckPriority(Cancel)
	
	If AdditionalProperties.Property(PerformanceMonitorClientServer.DoNotCheckPriority()) Or Priority = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Priority", Priority);
	Query.SetParameter("Ref", Ref);
	Query.Text = 
	"SELECT TOP 1
	|	KeyOperations.Ref AS Ref,
	|	KeyOperations.Description AS Description
	|FROM
	|	Catalog.KeyOperations AS KeyOperations
	|WHERE
	|	KeyOperations.Priority = &Priority
	|	AND KeyOperations.Ref <> &Ref";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		MessageText = NStr("en = 'Key operation priority %1 is not unique (%2 has the same priority).';");
		MessageText = StrReplace(MessageText, "%1", String(Priority));
		MessageText = StrReplace(MessageText, "%2", Selection.Description);
		WriteLogEvent(NStr("en = 'Performance monitor';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,, Selection.Ref, MessageText);
		PerformanceMonitorInternal.MessageToUser(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If Not PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		IndexTargetTime = CheckedAttributes.Find("ResponseTimeThreshold");
		If IndexTargetTime <> Undefined Then
			CheckedAttributes.Delete(IndexTargetTime);
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf