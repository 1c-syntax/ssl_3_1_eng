///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft<plch id="1">
// </plch>All rights reserved. This software and the related materials<plch id="1"> 
// </plch>are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).<plch id="1">
// </plch>To view the license terms, follow the link:<plch id="1">
// </plch>https://creativecommons.org/licenses/by/4.0/legalcode<plch id="1">
///////////////////////////////////////////////////////////////////////////////////////////////////////
//</plch>

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	Items.FormEnableEditing.Enabled = False;
	
EndProcedure

#EndRegion
