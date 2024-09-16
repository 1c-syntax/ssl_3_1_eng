///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the correspondence of metadata objects and command interface subsystems.
//
// Returns: 
//  Map of KeyAndValue:
//    * Key - String -  full name of the object.
//    * Value - Array of String -  the full names of the subsystems of the program
//                                    's command interface that this object belongs to.
//
Function ObjectsBelongingToCommandInterfaceSections() Export
	
	ObjectsAndSubsystemsMap = New Map;
	
	For Each Subsystem In Metadata.Subsystems Do
		If Not Subsystem.IncludeInCommandInterface
			Or Not AccessRight("View", Subsystem)
			Or Not Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
			Continue;
		EndIf;
		
		For Each Object In Subsystem.Content Do
			ObjectSubsystems = ObjectsAndSubsystemsMap[Object.FullName()];
			If ObjectSubsystems = Undefined Then
				ObjectSubsystems = New Array;
			ElsIf ObjectSubsystems.Find(Subsystem.FullName()) <> Undefined Then
				Continue;
			EndIf;
			ObjectSubsystems.Add(Subsystem.FullName());
			ObjectsAndSubsystemsMap.Insert(Object.FullName(), ObjectSubsystems);
		EndDo;
		
		AddSubordinateSubsystemsObjects(Subsystem, ObjectsAndSubsystemsMap);
	EndDo;
	
	Return New FixedMap(ObjectsAndSubsystemsMap);
	
EndFunction

#EndRegion

#Region Private

// For internal use only.
//
Procedure AddSubordinateSubsystemsObjects(FirstLevelSubsystem, ObjectsAndSubsystemsMap, SubsystemParent = Undefined)
	
	Subsystems = ?(SubsystemParent = Undefined, FirstLevelSubsystem, SubsystemParent);
	
	For Each Subsystem In Subsystems.Subsystems Do
		If Subsystem.IncludeInCommandInterface
			And AccessRight("View", Subsystem)
			And Common.MetadataObjectAvailableByFunctionalOptions(Subsystem) Then
			
			For Each Object In Subsystem.Content Do
				ObjectSubsystems = ObjectsAndSubsystemsMap[Object.FullName()];
				If ObjectSubsystems = Undefined Then
					ObjectSubsystems = New Array;
				ElsIf ObjectSubsystems.Find(FirstLevelSubsystem.FullName()) <> Undefined Then
					Continue;
				EndIf;
				ObjectSubsystems.Add(FirstLevelSubsystem.FullName());
				ObjectsAndSubsystemsMap.Insert(Object.FullName(), ObjectSubsystems);
			EndDo;
			
			AddSubordinateSubsystemsObjects(FirstLevelSubsystem, ObjectsAndSubsystemsMap, Subsystem);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion