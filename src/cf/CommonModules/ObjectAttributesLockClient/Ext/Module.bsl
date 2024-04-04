///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// 
// 
// 
// 
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - 
//          :
//    * Object - FormDataStructure
//             - CatalogObject
//             - DocumentObject
//
//  ContinuationHandler - Undefined -  no actions after completing the procedure.
//                       - NotifyDescription - 
//                         :
//                           
//                           
//                                    
//
//  OnlyVisible - Boolean -  to get and unlock all the details of the object, you need to specify a Lie.
//
Procedure AllowObjectAttributeEdit(Val Form, ContinuationHandler = Undefined, OnlyVisible = True) Export
	
	LockedAttributes = Attributes(Form, , OnlyVisible);
	
	If LockedAttributes.Count() = 0 Then
		ShowAllVisibleAttributesUnlockedWarning(
			New NotifyDescription("AllowObjectAttributeEditAfterWarning",
				ObjectAttributesLockInternalClient, ContinuationHandler));
		Return;
	EndIf;
	
	DetailsOfAttributesToLock = New Array;
	
	For Each AttributeDetails In Form.AttributeEditProhibitionParameters Do
		If LockedAttributes.Find(AttributeDetails.AttributeName) = Undefined Then
			Continue;
		EndIf;
		LongDesc = New Structure("AttributeName, Presentation, EditingAllowed,
			|ItemsToLock, RightToEdit, IsFormAttribute");
		FillPropertyValues(LongDesc, AttributeDetails);
		DetailsOfAttributesToLock.Add(LongDesc);
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("LockedAttributes", LockedAttributes);
	FormParameters.Insert("Ref", Form.Object.Ref);
	
	NameOfUnlockForm = Form.FullNameOfAttributeUnlockForm;
	If Not ValueIsFilled(NameOfUnlockForm) Then
		NameOfUnlockForm = "CommonForm.AttributeUnlocking";
		FormParameters.Insert("FullObjectName", Form.FullNameOfAttributesUnlockingObject);
		FormParameters.Insert("DetailsOfAttributesToLock", DetailsOfAttributesToLock);
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("Form", Form);
	Parameters.Insert("LockedAttributes", LockedAttributes);
	Parameters.Insert("ContinuationHandler", ContinuationHandler);
	
	NotifyDescription = New NotifyDescription("AllowEditingObjectAttributesAfterFormClosed",
		ObjectAttributesLockInternalClient, Parameters);
	
	OpenForm(NameOfUnlockForm, FormParameters, , , , , NotifyDescription);
	
EndProcedure

// Sets the availability of form elements associated with the specified details
// for which the change permission is set. If you pass an array of Bank details,
// then the list of Bank details that are allowed to be changed will be updated first.
//   If the unblocking of form elements associated with the specified details
// is disabled for all details, then the edit permission button is blocked.
//
// Parameters:
//  Form        - ClientApplicationForm -  the form where you want to allow
//                 editing of form elements and specified details.
//  
//  Attributes    - Array - Values:
//                  * String - 
//                    
//               - Undefined - 
//                 
//                 
//
Procedure SetFormItemEnabled(Val Form, Val Attributes = Undefined) Export
	
	SetAttributeEditEnabling(Form, Attributes);
	
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		If DescriptionOfAttributeToLock.EditingAllowed Then
			For Each FormItemToLock In DescriptionOfAttributeToLock.ItemsToLock Do
				FormItem = Form.Items.Find(FormItemToLock.Value);
				If FormItem <> Undefined Then
					If TypeOf(FormItem) = Type("FormField")
					   And FormItem.Type <> FormFieldType.LabelField
					 Or TypeOf(FormItem) = Type("FormTable") Then
						FormItem.ReadOnly = False;
					Else
						FormItem.Enabled = True;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

// Sets whether editing is allowed for the details that are described in the form.
//  Used when the accessibility of form elements changes independently, without
// using the set accessibility of form Elements function.
//
// Parameters:
//  Form        - ClientApplicationForm - :
//    * Items - FormAllItems:
//        ** AllowObjectAttributeEdit - FormButton
//  Attributes    - Array of String -  the names of the details that you want to mark as resolved to change.
//  EditingAllowed - Boolean -  the value of the permission to edit the details to be set.
//                            The value will not be set to True if you don't have the right to edit the details.
//                          - Undefined - 
//  RightToEdit - Boolean -  allows you to redefine or redefine the ability to unlock
//                        Bank details, which is calculated automatically using the access Rights method.
//                      - Undefined - 
// 
Procedure SetAttributeEditEnabling(Val Form, Val Attributes,
			Val EditingAllowed = True, Val RightToEdit = Undefined) Export
	
	If TypeOf(Attributes) = Type("Array") Then
		
		For Each Attribute In Attributes Do
			AttributeDetails = Form.AttributeEditProhibitionParameters.FindRows(New Structure("AttributeName", Attribute))[0];
			If TypeOf(RightToEdit) = Type("Boolean") Then
				AttributeDetails.RightToEdit = RightToEdit;
			EndIf;
			If TypeOf(EditingAllowed) = Type("Boolean") Then
				AttributeDetails.EditingAllowed = AttributeDetails.RightToEdit And EditingAllowed;
			EndIf;
		EndDo;
	EndIf;
	
	// 
	AllAttributesUnlocked = True;
	
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		If DescriptionOfAttributeToLock.RightToEdit
		And Not DescriptionOfAttributeToLock.EditingAllowed Then
			AllAttributesUnlocked = False;
			Break;
		EndIf;
	EndDo;
	
	If AllAttributesUnlocked Then
		Form.Items.AllowObjectAttributeEdit.Enabled = False;
	EndIf;
	
EndProcedure

// Returns an array of the names of the details specified in the form parametersreaditingrequests Property
// based on the names of the details specified in the object Manager module, excluding the details
// that have the edit Right = False.
//
// Parameters:
//  Form         - ClientApplicationForm -  object form with the required standard "Object"attribute.
//  OnlyBlocked - Boolean -  for auxiliary purposes, you can set False to
//                  get a list of all visible details that can be unlocked.
//  OnlyVisible - Boolean -  to get and unlock all the details of the object, you need to specify a Lie.
//
// Returns:
//  Array of String - 
//
Function Attributes(Val Form, Val OnlyBlocked = True, OnlyVisible = True) Export
	
	Attributes = New Array;
	
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		
		If DescriptionOfAttributeToLock.RightToEdit
		   And (    DescriptionOfAttributeToLock.EditingAllowed = False
		      Or OnlyBlocked = False) Then
			
			AddAttribute = False;
			For Each FormItemToLock In DescriptionOfAttributeToLock.ItemsToLock Do
				FormItem = Form.Items.Find(FormItemToLock.Value);
				If FormItem <> Undefined And (FormItem.Visible Or Not OnlyVisible) Then
					AddAttribute = True;
					Break;
				EndIf;
			EndDo;
			If AddAttribute Then
				Attributes.Add(DescriptionOfAttributeToLock.AttributeName);
			EndIf;
		EndIf;
	EndDo;
	
	Return Attributes;
	
EndFunction

// Displays a warning that all visible banking details are unlocked.
// The need for a warning occurs when the unlock command
// remains enabled due to the presence of invisible unblocked details.
//
// Parameters:
//  ContinuationHandler - Undefined -  no actions after completing the procedure.
//                       - NotifyDescription - 
//
Procedure ShowAllVisibleAttributesUnlockedWarning(ContinuationHandler = Undefined) Export
	
	ShowMessageBox(ContinuationHandler,
		NStr("en = 'Editing visible attributes of the object is already allowed.';"));
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// 
//
// Parameters:
//  Parameters - See NewParametersAllowEditingObjectAttributes
//
Procedure AllowObjectsAttributesEdit(Parameters) Export

	FormParameters = New Structure;
	FormParameters.Insert("BatchEditObjects", True);
	FormParameters.Insert("LockedAttributes",   Parameters.LockedAttributes);
	FormParameters.Insert("AddressOfRefsToObjects",       Parameters.AddressOfRefsToObjects);
	FormParameters.Insert("MarkedAttribute",         Parameters.MarkedAttribute);
	
	FullNameOfStandardForm = "CommonForm.AttributeUnlocking";
	FullFormName = Parameters.FullObjectName + ".Form.AttributeUnlocking";
	
	Try
		// 
		ObtainedForm = GetForm(FullFormName);
		// 
		If Not ObtainedForm.Parameters.Property("BatchEditObjects") Then
			FullFormName = FullNameOfStandardForm;
		EndIf;
	Except
		FullFormName = FullNameOfStandardForm;
	EndTry;
	
	If FullFormName = FullNameOfStandardForm Then
		FormParameters.Insert("FullObjectName", Parameters.FullObjectName);
	EndIf;
	
	OpenForm(FullFormName, FormParameters, , , , , Parameters.ResultProcessing);
	
EndProcedure

// 
//
// Returns:
//  Structure:
//   * ResultProcessing - NotifyDescription - 
//             
//             
//
//   * FullObjectName - String - 
//
//   * LockedAttributes - Array of String - 
//            
//
//   * MarkedAttribute - String - 
//            
//
//   * AddressOfRefsToObjects - String - 
//            
//
Function NewParametersAllowEditingObjectAttributes() Export
	
	NewParameters = New Structure;
	NewParameters.Insert("ResultProcessing");
	NewParameters.Insert("FullObjectName", "");
	NewParameters.Insert("LockedAttributes", New Array);
	NewParameters.Insert("MarkedAttribute", "");
	NewParameters.Insert("AddressOfRefsToObjects", "");
	
	Return NewParameters;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
//
// 
// 
//
// Parameters:
//  ContinuationHandler - NotifyDescription - 
//                         :
//                           
//                           
//                                    
//  ReferencesArrray         - Array - Values:
//                           * Ref - 
//  AttributesSynonyms   - Array - Values:
//                           * String - 
//
Procedure CheckObjectRefs(Val ContinuationHandler, Val ReferencesArrray, Val AttributesSynonyms) Export
	
	DialogTitle = NStr("en = 'Allow attribute edit';");
	
	AttributesPresentation = "";
	For Each AttributeSynonym In AttributesSynonyms Do
		AttributesPresentation = AttributesPresentation + AttributeSynonym + "," + Chars.LF;
	EndDo;
	AttributesPresentation = Left(AttributesPresentation, StrLen(AttributesPresentation) - 2);
	
	If AttributesSynonyms.Count() > 1 Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'To prevent data inconsistency, the following attributes have been locked:
			           |%1.
			           |
			           |Before you allow editing, view the occurrences of these attributes
			           |and consider possible data implications.
			           |Generating the list of occurrences might take a while.
			           |';"),
			AttributesPresentation);
	Else
		If ReferencesArrray.Count() = 1 Then
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'To prevent data inconsistency, attribute %1 has been locked.
				           |
				           |Before you allow editing, view the occurrences of %2
				           |and consider possible data implications.
				           |Generating the list of occurrences might take a while.';"),
				AttributesPresentation, ReferencesArrray[0]);
		Else
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'To prevent data inconsistency, attribute %1 has been locked.
				           |
				           |Before you allow editing, view the occurrences of the selected items (%2)
				           |and consider possible data implications.
				           |Generating the list of occurrences might take a while.';"),
				AttributesPresentation, ReferencesArrray.Count());
		EndIf;
	EndIf;
	
	Parameters = New Structure;
	Parameters.Insert("ReferencesArrray", ReferencesArrray);
	Parameters.Insert("AttributesSynonyms", AttributesSynonyms);
	Parameters.Insert("DialogTitle", DialogTitle);
	Parameters.Insert("ContinuationHandler", ContinuationHandler);
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("en = 'View and allow';"));
	Buttons.Add(DialogReturnCode.No, NStr("en = 'Cancel';"));
	
	ShowQueryBox(
		New NotifyDescription("CheckObjectReferenceAfterValidationConfirm",
			ObjectAttributesLockInternalClient, Parameters),
		QueryText, Buttons, , DialogReturnCode.Yes, DialogTitle);
	
EndProcedure

#EndRegion

#EndRegion
