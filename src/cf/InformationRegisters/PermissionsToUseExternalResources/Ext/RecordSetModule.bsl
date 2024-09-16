///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	// 
	// 
	SafeModeManagerInternal.OnSaveInternalData(ThisObject);
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	For Each Record In ThisObject Do
		
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Record.ProgramModuleType, Record.ModuleID);
		Record.SoftwareModulePresentation = String(ProgramModule);
		
		Owner = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Record.OwnerType, Record.OwnerID);
		Record.OwnerPresentation = String(Owner);
		
	EndDo;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf