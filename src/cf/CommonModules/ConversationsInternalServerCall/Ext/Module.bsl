﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternal.Connected2();
	
EndFunction

Procedure Unlock() Export 
	
	ConversationsInternal.Unlock();
	
EndProcedure

#EndRegion