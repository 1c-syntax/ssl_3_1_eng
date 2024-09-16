///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure SessionParametersSetting(SessionParametersNames)
	
	// StandardSubsystems
	StandardSubsystemsServer.SessionParametersSetting(SessionParametersNames);
	// End StandardSubsystems
	
EndProcedure

#EndRegion

#EndIf