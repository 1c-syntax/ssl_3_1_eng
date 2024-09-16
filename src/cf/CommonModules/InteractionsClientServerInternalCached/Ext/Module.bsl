///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns:
//   FixedArray of See InteractionsClientServer.NewContactDescription
//
Function InteractionsContacts() Export

	Result = New Array();
	
	Contact = InteractionsClientServer.NewContactDescription();
	Contact.Type                               = Type("CatalogRef.Users");
	Contact.Name                               = "Users";
	Contact.Presentation                     = NStr("en = 'Users';");
	Contact.InteractiveCreationPossibility = False;
	Contact.SearchByDomain                    = True;
	Result.Add(Contact);
	
	InteractionsClientServerOverridable.OnDeterminePossibleContacts(Result);
	Return New FixedArray(Result);

EndFunction

Function InteractionsSubjects() Export
	
	Subjects = New Array;
	InteractionsClientServerOverridable.OnDeterminePossibleSubjects(Subjects);
	Return New FixedArray(Subjects);
	
EndFunction

#EndRegion
