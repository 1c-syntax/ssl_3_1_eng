///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Owner.IsEmpty() Then
		MessageText = NStr("en = 'This form can be opened only from survey questions.';");
		Common.MessageToUser(MessageText);
		Cancel = True;
		Return;
	EndIf;

	Object.Owner = Parameters.Owner;
	If Not Parameters.ReplyType.IsEmpty() Then
		Items.OpenEndedQuestion.Visible = (Parameters.ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor);
	Else
		ReplyType = Common.ObjectAttributeValue(Object.Owner, "ReplyType");
		Items.OpenEndedQuestion.Visible = (ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor);
	EndIf;

	If Not IsBlankString(Parameters.Description) Then
		Object.Description = Parameters.Description;
	EndIf;

EndProcedure

#EndRegion