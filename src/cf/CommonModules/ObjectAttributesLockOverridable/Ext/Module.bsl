///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
//
// 
// See ObjectAttributesLock.DescriptionOfAttributeToLock
//
// 
// 
//
// Parameters:
//   Objects - Map of KeyAndValue:
//     * Key - String -  full name of the metadata object connected to the subsystem;
//     * Value - String -  empty string.
//
// Example:
//   
//
//   
//   // See ObjectAttributesLockOverridable.OnDefineLockedAttributes.LockedAttributes
//   
//   	
//   	
//   	
//   	
//   	
//   	
//   	
//   	
//   	
//   
//
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	
	
	
EndProcedure

// Allows you to redefine the list of blocked details set in the object manager module.
//
// Parameters:
//   MetadataObjectName - String -  for example, " Directory.Files".
//   LockedAttributes - Array of See ObjectAttributesLock.DescriptionOfAttributeToLock
//
Procedure OnDefineLockedAttributes(MetadataObjectName, LockedAttributes) Export
	
EndProcedure

#EndRegion
