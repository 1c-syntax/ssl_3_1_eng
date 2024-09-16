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
	
	Title = Parameters.Title;
	
	PresentationsArray = ?(Parameters.IsFilter,
		StringFunctionsClientServer.SplitStringIntoSubstringsArray(Parameters.Purpose, ", "),
		Undefined);
	
	If Parameters.SelectUsersAllowed Then
		AddTypeRow(Catalogs.Users.EmptyRef(), Type("CatalogRef.Users"), PresentationsArray);
	EndIf;
	
	If ExternalUsers.UseExternalUsers() Then
		
		BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
		For Each EmptyRef In BlankRefs Do
			AddTypeRow(EmptyRef, TypeOf(EmptyRef), PresentationsArray);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(Purpose);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddTypeRow(Value, Type, PresentationsArray)
	
	Presentation = Metadata.FindByType(Type).Synonym;
	
	If Parameters.IsFilter Then
		Check = PresentationsArray.Find(Presentation) <> Undefined;
	Else
		FilterParameters = New Structure;
		FilterParameters.Insert("UsersType", Value);
		FoundRows = Parameters.Purpose.FindRows(FilterParameters);
		Check = FoundRows.Count() = 1;
	EndIf;
	
	Purpose.Add(Value, Presentation, Check);
	
EndProcedure

#EndRegion