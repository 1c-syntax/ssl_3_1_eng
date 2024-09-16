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
	
	Name = Parameters.Name;
	MiddleName = Parameters.MiddleName;
	NameAndPatronymic = Parameters.Name + ?(ValueIsFilled(Parameters.MiddleName)," " + Parameters.MiddleName, "");
	NewNameAndPatronymic = NameAndPatronymic;
	Items.NewNameAndPatronymic.TextColor = WebColors.Green;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure NameOnChange(Item)
	SetColorInscriptionsNameAndPatronymic();
EndProcedure

&AtClient
Procedure MiddleNameOnChange(Item)
	SetColorInscriptionsNameAndPatronymic();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If NewNameAndPatronymic = NameAndPatronymic Then
		Close(New Structure("Name, MiddleName", TrimR(Name), TrimR(MiddleName)));
	Else
		ShowMessageBox( , StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'First name and middle name must be equal to %1';"), NameAndPatronymic));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetColorInscriptionsNameAndPatronymic()
	
	NewNameAndPatronymic = TrimR(Name) + ?(IsBlankString(MiddleName), "", " " + TrimR(MiddleName));
	If NewNameAndPatronymic = NameAndPatronymic Then
		Items.NewNameAndPatronymic.TextColor = WebColors.Green;
	Else
		Items.NewNameAndPatronymic.TextColor = WebColors.Red;
	EndIf; 
	
EndProcedure

#EndRegion
