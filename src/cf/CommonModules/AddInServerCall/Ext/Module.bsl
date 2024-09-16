///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Information about the external component by ID and version.
//
// Parameters:
//  Id - String - 
//  Version - String -  version of the component. 
//
// Returns:
//  Structure:
//      * Exists - Boolean -  indicates that the component is missing.
//      * EditingAvailable - Boolean -  indicates that the component can be changed by the scope administrator.
//      * ErrorDescription - String -  brief description of the error.
//      * Id - String - 
//      * Version - String -  version of the component.
//      * Description - String -  name and brief information about the component.
//
// Example:
//
//  Result = External Component Of The Server Call.Component Information ("InputDevice", " 8.1.7.10");
//
//  If The Result.There Is Then
//      ID = Result.ID;
//      Version = Result.Version;
//      Name = Result.Name;
//  Otherwise
//      General purpose clientserver.Inform The User(Result.Opisaniyami);
//  Conicelli;
//
Function AddInInformation(Id, Version = Undefined) Export
	
	Result = ResultInformationOnComponent();
	Result.Id = Id;
	
	Information = AddInsInternal.SavedAddInInformation(Id, Version);
	
	If Information.State = "NotFound1" Then
		Result.ErrorDescription = NStr("en = 'The add-in does not exist';");
		Return Result;
	EndIf;
	
	If Information.State = "DisabledByAdministrator" Then
		Result.ErrorDescription = NStr("en = 'Add-in is disabled';");
		Return Result;
	EndIf;
	
	Result.Exists = True;
	Result.EditingAvailable = True;
	
	If Information.State = "FoundInSharedStorage" Then
		Result.EditingAvailable = False;
	EndIf;
	
	Result.Version = Information.Attributes.Version;
	Result.Description = Information.Attributes.Description;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

Function ResultInformationOnComponent()
	
	Result = New Structure;
	Result.Insert("Exists", False);
	Result.Insert("EditingAvailable", False);
	Result.Insert("Id", "");
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("ErrorDescription", "");
	
	Return Result;
	
EndFunction

#EndRegion