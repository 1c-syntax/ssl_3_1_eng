///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Procedure WhenDeterminingRecipientOfTechnicalSupportRequest(Recipient) Export
	
	
EndProcedure

Procedure OnGetFilterForSelectingSignatures(Filter) Export
	
	
EndProcedure

Procedure OnGetChoiceListWithMRLOAs(Form, CurrentData, ChoiceList) Export
	
	
EndProcedure

Procedure OnSelectMRLOA(CompletionHandler, CurrentData) Export
	
	
EndProcedure

Procedure OnDefineMRLOAFiles(MRLOAFiles,
		SignaturesCollection) Export
		
	
EndProcedure

Async Function InstalledTokens(ComponentObject = Undefined, SuggestInstall = False) Export

	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Tokens", New Array);
	Result.Insert("Error", "");
	
	
	Return Result; 
	
EndFunction

Async Function TokenCertificates(Token, ComponentObject = Undefined, SuggestInstall = False) Export
	
	Result = New Structure;
	Result.Insert("CheckCompleted", False);
	Result.Insert("Certificates", New Array);
	Result.Insert("Error", "");
	
	
	Return Result;
	
EndFunction

Function ThisIsErrorIncorrectPinCode(ErrorText) Export
	Return False;
EndFunction 


#EndRegion
