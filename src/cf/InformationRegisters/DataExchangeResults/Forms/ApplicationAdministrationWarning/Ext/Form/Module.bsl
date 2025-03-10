﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	Parameters.Property("LongDesc", LongDesc);
	Parameters.Property("WarningType", WarningType);
	Parameters.Property("InfobaseNode", InfobaseNode);
	Parameters.Property("HideWarning", HideWarning);
	Parameters.Property("OccurrenceDate", OccurrenceDate);
	Parameters.Property("UniqueKey", InformationRegisterRecordUniqueKey);
	Parameters.Property("WarningComment", WarningComment);
	
	HideFromListFlagUpdateRequired = False;
	CommentUpdateRequired = False;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ChangeThePictureOfTheScenery()
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HideWarningOnChange(Item)
	
	HideFromListFlagUpdateRequired = True;
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WarningCommentOnChange(Item)
	
	CommentUpdateRequired = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	BeforeCloseAtServer();
	
	If HideFromListFlagUpdateRequired
		Or CommentUpdateRequired Then
		
		Close(New Structure("TheListNeedsToBeUpdated", True));
		
	Else
		
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ChangeThePictureOfTheScenery()
	
	If HideWarning Then
		
		Items.PictureDecoration.Picture = PictureLib.Information32;
		
	Else
		
		Items.PictureDecoration.Picture = PictureLib.Error32;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	
	If Not HideFromListFlagUpdateRequired
		And Not CommentUpdateRequired Then
		
		Return;
		
	EndIf;
	
	RecordManager = InformationRegisters.DataExchangeResults.CreateRecordManager();
	RecordManager.IssueType = WarningType;
	RecordManager.InfobaseNode = InfobaseNode;
	RecordManager.UniqueKey = InformationRegisterRecordUniqueKey;
	
	RecordManager.Read(); // Read data to save the attributes that won't be passed to the form.
	If Not RecordManager.Selected() Then
		
		// Use case: A user opened the warning dialog and fixed the issue.
		Return;
		
	EndIf;

	RecordManager.OccurrenceDate = OccurrenceDate;
	RecordManager.Comment = WarningComment;
	RecordManager.IsSkipped = HideWarning;
	RecordManager.Write(True);
	
EndProcedure

#EndRegion
