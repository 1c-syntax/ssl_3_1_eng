///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Start connecting the interaction system.
//
// Parameters:
//   CompletionDetails - NotifyDescription -  
//                                             :
//                          * Result - Undefined
//                          * AdditionalParameters - Undefined
//                                                    - Structure
//
Procedure ShowConnection(CompletionDetails = Undefined) Export
	ConversationsInternalClient.ShowConnection(CompletionDetails);
EndProcedure

// Start off a system of interaction.
//
Procedure ShowDisconnection() Export
	ConversationsInternalClient.ShowDisconnection();
EndProcedure

//  
//
// 
//  
// 
// 
// Returns:
//   Boolean
//
Function ConversationsAvailable() Export
	
	Return ConversationsInternalServerCall.Connected2();
	
EndFunction

#EndRegion