///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Calculates and fills in queue numbers for developed subsystems,
// and fills in redefined queue numbers for library handlers.
//
// Parameters:
//  UpdateIterations - Array of See InfobaseUpdateInternal.UpdateIteration
//
Procedure FillQueueNumber(UpdateIterations) Export
	
	HandlersDetails = DataProcessors.UpdateHandlersDetails.Create();
	HandlersDetails.FillQueueNumber(UpdateIterations);
	
EndProcedure

#EndRegion

#EndIf