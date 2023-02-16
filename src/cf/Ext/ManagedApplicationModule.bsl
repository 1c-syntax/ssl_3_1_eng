///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

// StandardSubsystems

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
Var ApplicationParameters Export;

// End StandardSubsystems

#EndRegion

#Region EventsHandlers

Procedure BeforeStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeStart();
	// End StandardSubsystems
	
	
	
EndProcedure

Procedure OnStart()
	
	// StandardSubsystems
	StandardSubsystemsClient.OnStart();
	// End StandardSubsystems
	
EndProcedure

Procedure BeforeExit(Cancel, WarningText)
	
	// StandardSubsystems
	StandardSubsystemsClient.BeforeExit(Cancel, WarningText);
	// End StandardSubsystems
	
EndProcedure

Procedure CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
			Form, ConversationID, Parameters, SelectedForm, StandardProcessing)
	
	// StandardSubsystems
	StandardSubsystemsClient.CollaborationSystemUsersChoiceFormGetProcessing(ChoicePurpose,
		Form, ConversationID, Parameters, SelectedForm, StandardProcessing);
	// End StandardSubsystems
	
EndProcedure

#EndRegion