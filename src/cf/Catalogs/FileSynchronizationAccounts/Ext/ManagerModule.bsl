///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// Standard subsystems.Forbidding editingrequisitobjects

// Returns:
//   See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("Service; ServicePresentation");
	Result.Add("RootDirectory");
	
	Return Result;
	
EndFunction

// End StandardSubsystems.ObjectAttributesLock

#EndRegion

#EndRegion

#EndIf
