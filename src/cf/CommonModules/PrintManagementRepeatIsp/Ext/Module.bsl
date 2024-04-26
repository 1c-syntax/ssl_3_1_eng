///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function PrintSettings() Export
	
	Settings = PrintManagement.PrintSettings();
	
	PrintObjects = New Map;
	For Each PrintObject In Settings.PrintObjects Do
		PrintObjects.Insert(PrintObject, True);
	EndDo;
	
	Settings.PrintObjects = New FixedMap(PrintObjects);
	
	Return Settings;
	
EndFunction

Function ObjectsWithPrintCommands() Export
	
	ObjectsWithPrintCommands = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsWithPrintCommands(ObjectsWithPrintCommands); // 
	PrintManagementOverridable.OnDefineObjectsWithPrintCommands(ObjectsWithPrintCommands); // 
	
	Result = New Map;
	For Each PrintObject In ObjectsWithPrintCommands Do
		Result.Insert(PrintObject, True);
	EndDo;
		
	Return New FixedMap(Result);
	
EndFunction

#EndRegion
