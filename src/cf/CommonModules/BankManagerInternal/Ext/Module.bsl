///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Determines whether the classifier data needs to be updated.
//
Function ClassifierUpToDate() Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Return DataProcessors[DataProcessorName].ClassifierUpToDate();
	EndIf;
	
	Return True;
	
EndFunction

Function ClassifierEmpty()
	
	QueryText =
	"SELECT TOP 1
	|	BankClassifier.Ref AS Ref
	|FROM
	|	Catalog.BankClassifier AS BankClassifier";
	
	Query = New Query(QueryText);
	Return Query.Execute().IsEmpty();
	
EndFunction

Function PromptToImportClassifier() Export
	
	Return Not Common.DataSeparationEnabled() And ClassifierEmpty();
	
EndFunction

#EndRegion
