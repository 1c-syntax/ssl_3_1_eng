﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If AdditionalProperties.Property("NoteDeletionMark") And AdditionalProperties.NoteDeletionMark Then
		Return;
	EndIf;
	
	If ValueIsFilled(Parent) And Common.ObjectAttributeValue(Parent, "Author") <> Author Then
		Common.MessageToUser(NStr("en = 'You cannot specify a group that belongs to another user.';"));
		Cancel = True;
		Return;
	EndIf;
	
	If Not IsFolder Then 
		ChangeDate = CurrentSessionDate();
		SubjectPresentation = Common.SubjectString(SubjectOf);
		
		Position = StrFind(ContentText, Chars.LF);
		If Position > 0 Then
			Subject = Mid(ContentText, 1, Position - 1);
		Else
			Subject = ContentText;
		EndIf;
		
		If IsBlankString(Subject) Then 
			Subject = "<" + NStr("en = 'Blank note';") + ">";
		EndIf;
		
		MaxDescriptionLength = Metadata().DescriptionLength;
		If StrLen(Subject) > MaxDescriptionLength Then
			Subject = Left(Description, MaxDescriptionLength - 3) + "...";
		EndIf;
		
		Description = Subject;
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf