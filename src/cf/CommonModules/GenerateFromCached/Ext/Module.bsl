///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function ObjectsWithCreationBasedOnCommands() Export
	
	Objects = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands(Objects);
	
	Result = New Map;
	For Each MetadataObject In Objects Do
		Result.Insert(MetadataObject.FullName(), True);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion

