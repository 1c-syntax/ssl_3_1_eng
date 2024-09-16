///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns a list of undivided administrators
//
// Returns:
//   ValueList   - 
//
Function AdministratorsList() Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SharedUsers.IBUserID
		|FROM
		|	InformationRegister.SharedUsers AS SharedUsers";
	Selection = Query.Execute().Select();
	AdministratorsList = New ValueList;
	While Selection.Next() Do
		IBUser = InfoBaseUsers.FindByUUID(
			Selection.IBUserID);
		If IBUser = Undefined Then
			Continue;
		EndIf;		
		UserRole = Undefined;
		For Each Role In IBUser.Roles Do
			UserRole = Role;
			Break;
		EndDo;
		If UserRole = Undefined Then
			Continue;
		EndIf;		
		If Not Users.IsFullUser(IBUser, True) Then
			Continue;
		EndIf;
		AdministratorsList.Add(Selection.IBUserID, IBUser.Name);
	EndDo;
	AdministratorsList.SortByPresentation();
	Return AdministratorsList;
	
EndFunction

// Returns the maximum sequential number of an undivided user in the information database.
//
// Returns:
//  Number
//
Function MaxSequenceNumber() Export
	
	QueryText = "SELECT
	               |	ISNULL(MAX(SharedUsers.SequenceNumber), 0) AS SequenceNumber
	               |FROM
	               |	InformationRegister.SharedUsers AS SharedUsers";
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.SequenceNumber;
	Else
		Return 0;
	EndIf;
	
EndFunction

// Returns the sequence number of an undivided user in the information database
//
// Parameters:
//  Id - unique user ID of the information database.
//
// Returns:
//  Number
//
Function IBUserSequenceNumber(Id) Export
	
	Query = New Query;
	Query.SetParameter("IBUserID", Id);
	Query.Text =
	"SELECT
	|	SharedUsers.SequenceNumber AS SequenceNumber
	|FROM
	|	InformationRegister.SharedUsers AS SharedUsers
	|WHERE
	|	SharedUsers.IBUserID = &IBUserID";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	If Selection.Next() Then
		Return Selection.SequenceNumber;
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#EndIf