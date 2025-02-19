///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.PrintCommands) <> Type("Array") Then
		Cancel = True;
		Return;
	EndIf;
	
	Cnt = 0;
	For Each Command In Parameters.PrintCommands Do
		Cnt = Cnt + 1;
		If Command.DefaultPrintForm Then
			Items.DefaultPrintForm.ChoiceList.Add(Cnt, Command.Presentation, False);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAndGenerate(Command)
	
	If CheckFilling() Then
		Close(DefaultPrintForm - 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion
