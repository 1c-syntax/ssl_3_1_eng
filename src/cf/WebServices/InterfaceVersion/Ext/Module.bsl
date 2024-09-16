///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns an array of version number names supported by the InterfaceName subsystem.
//
// Parameters:
//   InterfaceName - String -  name of the subsystem.
//
// Returns:
//   Array of String
//
// :
//
// 	
// 	
//  //
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
//			
//			
//		
//
//		
//			
//
//	
//
Function GetVersions(InterfaceName)
	
	VersionsArray = Undefined;
	
	SupportedVersionsStructure = New Structure;
	
	SSLSubsystemsIntegration.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	CommonOverridable.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	
	SupportedVersionsStructure.Property(InterfaceName, VersionsArray);
	
	If VersionsArray = Undefined Then
		Return XDTOSerializer.WriteXDTO(New Array);
	Else
		Return XDTOSerializer.WriteXDTO(VersionsArray);
	EndIf;
	
EndFunction

#EndRegion