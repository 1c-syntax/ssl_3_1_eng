///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Takes as a parameter the form of the object to which the subsystem is connected,
//  and prohibits editing the specified details,
//  and also adds a command to "All actions" to allow editing them.
//
// Parameters:
//  Form - ClientApplicationForm
//        - ManagedFormExtensionForObjects - :
//    * Object - FormDataStructure
//             - CatalogObject
//             - DocumentObject
//    * Items - FormAllItems:
//        ** AllowObjectAttributeEdit - FormButton
//  LockButtonGroup  - FormGroup -  overrides the standard placement
//                            of the deny button in the object form.
//  LockButtonTitle  - String -  the title of the button. By default, the "Allow edit account details".
//  Object                  - Undefined -  take an object from the props of the "Object" form.
//                          - FormDataStructure - 
//                          - CatalogObject
//                          - DocumentObject
//
Procedure LockAttributes(Form, LockButtonGroup = Undefined, LockButtonTitle = "",
		Object = Undefined) Export
	
	ObjectDetails = ?(Object = Undefined, Form.Object, Object);
	
	// 
	FormPrepared = False;
	FormAttributes = Form.GetAttributes();
	For Each FormAttribute In FormAttributes Do
		If FormAttribute.Name = "AttributeEditProhibitionParameters" Then
			FormPrepared = True;
			Break;
		EndIf;
	EndDo;
	
	If Not FormPrepared Then
		ObjectAttributesLockInternal.PrepareForm(Form,
			ObjectDetails.Ref, LockButtonGroup, LockButtonTitle);
	EndIf;
	
	IsNewObject = ObjectDetails.Ref.IsEmpty();
	
	// 
	For Each DescriptionOfAttributeToLock In Form.AttributeEditProhibitionParameters Do
		For Each FormItemDescription In DescriptionOfAttributeToLock.ItemsToLock Do
			
			DescriptionOfAttributeToLock.EditingAllowed =
				DescriptionOfAttributeToLock.RightToEdit And IsNewObject;
			If DescriptionOfAttributeToLock.EditingAllowed Then
				Continue;
			EndIf;
			
			FormItem = Form.Items.Find(FormItemDescription.Value);
			If FormItem = Undefined Then
				Continue;
			EndIf;
			
			If TypeOf(FormItem) = Type("FormField")
			   And FormItem.Type <> FormFieldType.LabelField
			 Or TypeOf(FormItem) = Type("FormTable") Then
				FormItem.ReadOnly = Not DescriptionOfAttributeToLock.EditingAllowed;
			Else
				FormItem.Enabled = DescriptionOfAttributeToLock.EditingAllowed;
			EndIf;
		EndDo;
	EndDo;
	
	If Form.Items.Find("AllowObjectAttributeEdit") <> Undefined Then
		Form.Items.AllowObjectAttributeEdit.Enabled = True;
	EndIf;
	
EndProcedure

// Returns a list of details and table parts of the object for which editing is prohibited.
// 
// Parameters:
//  ObjectName - String -  full name of the metadata object.
//
// Returns:
//  Array of String 
//
Function ObjectAttributesToLock(ObjectName) Export
	
	AttributesDetails2 = ObjectAttributesLockInternal.BlockedObjectDetailsAndFormElements(ObjectName);
	
	Result = New Array;
	For Each AttributeDetails In AttributesDetails2 Do
		If ValueIsFilled(AttributeDetails.Name) Then
			Result.Add(AttributeDetails.Name);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// 
// 
//
// Returns:
//  Structure:
//   * Name - String - 
//                    
//   * FormItems - Array of String - 
//        
//        
//   * Warning - String - 
//                       
//   * Group - String - 
//                       
//                       
//   * GroupPresentation - String - 
//                       
//                       
//   * WarningForGroup - String - 
//                       
//   * Warning - String - 
//                       
//
Function NewAttributeToLock() Export
	
	Result = New Structure;
	Result.Insert("Name", "");
	Result.Insert("FormItems", New Array);
	Result.Insert("Group", "");
	Result.Insert("GroupPresentation", "");
	Result.Insert("Warning", "");
	Result.Insert("WarningForGroup", "");
	
	Return Result;
	
EndFunction

#Region ForCallsFromOtherSubsystems

// 
// 
//
// Returns:
//  String - 
//             
//             
//               
//             
//
//   See NewAttributeToLock
//
Function DescriptionOfAttributeToLock() Export
	
	Return "";
	
EndFunction

#EndRegion

#EndRegion
