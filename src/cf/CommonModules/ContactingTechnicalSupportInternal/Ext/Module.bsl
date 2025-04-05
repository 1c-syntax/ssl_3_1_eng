///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
// 
//
// Parameters:
//  Form - ClientApplicationForm - :
//    * Items - FormAllItems - :
//      * AssistanceRequiredGroup           - FormGroup - 
//                                                        
//                                                        
//
//      * DescriptionOfSupportRequest     - FormDecoration - 
//                                                           
//                                                           
//                                                           
//                                                           
//                                                           
//
//      * QuestionInSupport                - FormButton - 
//                                                        
//
//      * InformationToSendToSupport - FormButton - 
//                                                        
//
Procedure OnCreateAtServer(Form) Export
	
	FormItems = Form.Items;
	
	If Users.IsExternalUserSession() Then
		HideHelpNeededSection(FormItems);
		Return;
	EndIf;
	
	DetermineAvailabilityOfFormElements(FormItems);
	FillInDescriptionOfSupportRequest(FormItems);
	
EndProcedure

// 
//
// Parameters:
//  FormItems - FormAllItems - 
//
Procedure HideHelpNeededSection(FormItems) Export
	
	CommonClientServer.SetFormItemProperty(
		FormItems, "AssistanceRequiredGroup", "Visible", False);
	
EndProcedure

// 
// 
//
// Parameters:
//  FormItems - FormAllItems - 
//
Procedure ShowHelpNeededSection(FormItems) Export
	
	If Users.IsExternalUserSession() Then
		Return;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		FormItems, "AssistanceRequiredGroup", "Visible", True);
	
EndProcedure

#EndRegion

#Region Private

Procedure DetermineAvailabilityOfFormElements(FormItems)
	
	QuestionInSupportIsAvailable = QuestionInSupportIsAvailable();
	
	CommonClientServer.SetFormItemProperty(
		FormItems,
		"QuestionInSupport",
		"Visible",
		QuestionInSupportIsAvailable);
	
EndProcedure

Procedure FillInDescriptionOfSupportRequest(FormItems)
	
	DescriptionOfSupportRequest = DescriptionOfSupportRequest();
	
	If Not InteractionViaNavigationLinkIsUsed(FormItems) Then
		DescriptionOfSupportRequest = String(DescriptionOfSupportRequest);
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		FormItems,
		"DescriptionOfSupportRequest",
		"Title",
		DescriptionOfSupportRequest);
	
EndProcedure

Function InteractionViaNavigationLinkIsUsed(FormItems)
	
	Result = FormItems.Find("QuestionInSupport") = Undefined
		And FormItems.Find("InformationToSendToSupport") = Undefined;
	
	Return Result;
	
EndFunction

Function DescriptionOfSupportRequest()
	
	QuestionInSupportIsAvailable = QuestionInSupportIsAvailable();
	
	If QuestionInSupportIsAvailable Then
		DescriptionOfSupportRequest = StringFunctions.FormattedString(
			NStr("en = 'При возникновении затруднений обратитесь в <a href = %1>службу поддержки</a>. В случае необходимости предоставьте <a href = %2>техническую информацию</a> о возникшей проблеме.'"),
			"QuestionInSupport",
			"InformationToSendToSupport");
	Else
		DescriptionOfSupportRequest = StringFunctions.FormattedString(
			NStr("en = 'При возникновении затруднений обратитесь в службу поддержки. В случае необходимости предоставьте <a href = %1>техническую информацию</a> о возникшей проблеме.'"),
			"InformationToSendToSupport");
	EndIf;
	
	ContactingTechnicalSupportLocalization.WhenDefiningDescriptionOfSupportRequest(
		DescriptionOfSupportRequest,
		QuestionInSupportIsAvailable);
	
	Return DescriptionOfSupportRequest;
	
EndFunction

Function QuestionInSupportIsAvailable()
	
	TechnicalSupportMessagesAreAvailable = Common.SubsystemExists(
		"OnlineUserSupport.MessagesToTechSupportService");
	
	WorkWithMailMessagesIsAvailable = Common.SubsystemExists(
		"StandardSubsystems.EmailOperations");
	
	Return TechnicalSupportMessagesAreAvailable Or WorkWithMailMessagesIsAvailable;
	
EndFunction

#EndRegion
