///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModifiedObjects = UnloadColumn("Object");
		ModifiedObjects = CommonClientServer.CollapseArray(ModifiedObjects);

		If ModifiedObjects.Count() = 0 Then
			If ValueIsFilled(Filter.Object.Value) Then
				ModifiedObjects.Add(Filter.Object.Value);
			Else
				ModifiedObjects = AllObjects();
			EndIf;
		EndIf;
		
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		SetPrivilegedMode(True);
		
		For Each Ref In ModifiedObjects Do
			If Common.IsRecordSetDeletion(Replacing) Then
				ObjectRecords = New Array;
			Else
				AllRecords = Unload();
				ObjectRecords = AllRecords.FindRows(New Structure("Object", Ref));
			EndIf;
			
			ModifiedObject = Ref.GetObject();
			If ModifiedObject <> Undefined Then
				ModifiedObject.AdditionalProperties.Insert("WrittenAdditionalInfo", ObjectRecords);
				ModuleObjectsVersioning.WriteObjectVersion(ModifiedObject);
			EndIf;
		EndDo;
		
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function AllObjects()
	
	QueryText =
	"SELECT
	|	AdditionalInfo.Object AS Object
	|FROM
	|	InformationRegister.AdditionalInfo AS AdditionalInfo
	|GROUP BY
	|	AdditionalInfo.Object";
	
	Query = New Query(QueryText);
	Return Query.Execute().Unload().UnloadColumn("Object");
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf