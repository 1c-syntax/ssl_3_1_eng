///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Not Object.Ref.IsEmpty() Then
		SetPrivilegedMode(True);
		PasswordIsSet = Common.ReadDataFromSecureStorage(Object.Ref) <> "";
		SetPrivilegedMode(False);
		ApplicationPassword = ?(PasswordIsSet, UUID, "");
		PasswordChanged = False;
		EmailOperationsInternal.CheckoutPasswordField(Items.ApplicationPassword);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If PasswordChanged Then
		SetPrivilegedMode(True);
		Common.WriteDataToSecureStorage(CurrentObject.Ref, ApplicationPassword, "ApplicationPassword");
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplicationPasswordEditTextChange(Item, Text, StandardProcessing)
	
	Items.ApplicationPassword.ChoiceButton = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationPasswordStartChoice(Item, ChoiceData, StandardProcessing)
	
	EmailOperationsClient.PasswordFieldStartChoice(Item, ApplicationPassword, StandardProcessing);
	
EndProcedure

#EndRegion
