﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ObjectWithIssue", ObjectWithIssue);
	Parameters.Property("LongDesc", LongDesc);
	Parameters.Property("WarningType", WarningType);
	Parameters.Property("InfobaseNode", InfobaseNode);
	Parameters.Property("VersionFromOtherApplication", VersionFromOtherApplication);
	Parameters.Property("ThisApplicationVersion", ThisApplicationVersion);
	Parameters.Property("HideWarning", HideWarning);
	Parameters.Property("OccurrenceDate", OccurrenceDate);
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
Procedure ObjectWithIssueClick(Item, StandardProcessing)
	
	HideFromListFlagUpdateRequired = True;
	
EndProcedure

&AtClient
Procedure WarningCommentOnChange(Item)
	
	CommentUpdateRequired = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenVersion(Command)
	
	If Not ValueIsFilled(ObjectWithIssue) Then
		
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(VersionFromOtherApplication);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);
	
EndProcedure

&AtClient
Procedure OpenVersionInThisApplication(Command)
	
	If Not ValueIsFilled(ObjectWithIssue)
		 Then
		
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(ThisApplicationVersion);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);

EndProcedure

&AtClient
Procedure AcceptVersionDeclined(Command)
	
	QueryText = NStr("en = 'Do you want to accept the version even though import is restricted?';", CommonClient.DefaultLanguageCode());
	
	NotifyDescription = New NotifyDescription("AcceptVersionCompletion", ThisObject);
	
	ShowQueryBox(NotifyDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure AcceptVersionCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		
		Return;
		
	EndIf;
	
	ClearMessages();
	
	ErrorMessage = "";
	AcceptRejectVersionAtServer(ErrorMessage);
	
	If IsBlankString(ErrorMessage) Then
		
		HideWarning = True;
		HideFromListFlagUpdateRequired = True;
		
	Else
		
		ShowMessageBox(, ErrorMessage);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowDifferences(Item)
	
	If ThisApplicationVersion = 0
		Or VersionFromOtherApplication = 0 Then
		
		CommonClient.MessageToUser(NStr("en = 'There must be two object versions for comparison.';"), CommonClient.DefaultLanguageCode());
		Return;
		
	EndIf;
	
	VersionsToCompare = New Array;
	VersionsToCompare.Add(ThisApplicationVersion);
	VersionsToCompare.Add(VersionFromOtherApplication);
	
	OpenVersionComparisonReport(ObjectWithIssue, VersionsToCompare);
	
EndProcedure

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

&AtClient
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OpenVersionComparisonReport(Ref, VersionsToCompare);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AcceptRejectVersionAtServer(ErrorMessage)
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Return;
		
	EndIf;
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	Try
		
		ModuleObjectsVersioning.OnStartUsingNewObjectVersion(ObjectWithIssue, VersionFromOtherApplication);
		
	Except
		
		ObjectPresentation	= ?(Common.RefExists(ObjectWithIssue), ObjectWithIssue, ObjectWithIssue.Metadata());
		ExceptionText			= ErrorProcessing.BriefErrorDescription(ErrorInfo());
		TextTemplate1			= NStr("en = 'Cannot accept the object version ""%1"" due to:%2 %3.';", Common.DefaultLanguageCode());
		ExceptionText			= StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ObjectPresentation, Chars.LF, ExceptionText);
		
		Common.MessageToUser(ExceptionText);
		
	EndTry;
	
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	
	If Not Common.SubsystemExists("StandardSubsystems.ObjectsVersioning")
		Or (Not HideFromListFlagUpdateRequired 
			And Not CommentUpdateRequired) Then
		
		Return;
		
	EndIf;
	
	RegisterEntryParameters = New Structure;
	RegisterEntryParameters.Insert("Ref", ObjectWithIssue);
	RegisterEntryParameters.Insert("VersionNumber", VersionFromOtherApplication);
	RegisterEntryParameters.Insert("VersionIgnored", HideWarning);
	RegisterEntryParameters.Insert("Comment", WarningComment);
	
	ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
	ModuleObjectsVersioning.ChangeTheSyncWarning(RegisterEntryParameters, True);
	
EndProcedure

#EndRegion
