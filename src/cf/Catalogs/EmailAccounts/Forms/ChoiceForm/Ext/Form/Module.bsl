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
	
	Items.ShowPersonalUsersAccounts.Visible =
		Users.IsFullUser();
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		Users.CurrentUser());
	
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	
	If ValueIsFilled(Parameters.Filter) Then
		Filter = New Structure;
		Filter.Insert("UseForSending", True);
		Filter.Insert("UseForReceiving", True);
		
		FillPropertyValues(Filter, Parameters.Filter);
		
		SuggestMailSetup = EmailOperations.CanSendEmails() 
			And EmailOperations.AvailableEmailAccounts(
			Filter.UseForSending, Filter.UseForReceiving, True).Count() = 0;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowPersonalUsersAccountsOnChange(Item)
	
	SwitchPersonalAccountsVisibility(List,
		ShowPersonalUsersAccounts,
		UsersClient.CurrentUser());
	
	Items.AccountOwner.Visible = ShowPersonalUsersAccounts;
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SwitchPersonalAccountsVisibility(List, ShowPersonalUsersAccounts, CurrentUser)
	UsersList = New Array;
	UsersList.Add(PredefinedValue("Catalog.Users.EmptyRef"));
	UsersList.Add(CurrentUser);
	CommonClientServer.SetDynamicListFilterItem(
		List, "AccountOwner", UsersList, DataCompositionComparisonType.InList, ,
			Not ShowPersonalUsersAccounts);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If SuggestMailSetup Then
		AttachIdleHandler("ConfigureMail", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Procedure ConfigureMail()
	
	EmailOperationsClient.CheckAccountForSendingEmailExists(Undefined);
	
EndProcedure


#EndRegion