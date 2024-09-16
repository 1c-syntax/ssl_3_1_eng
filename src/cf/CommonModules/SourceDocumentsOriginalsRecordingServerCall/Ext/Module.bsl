///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called to write the States of the original printed forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList -  list of links to print objects.
//  PrintList - ValueList -  a list with the names of the models and views printed forms.
//   Written1 - Boolean -  indicates that the status of the document is recorded in the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") And Not Users.IsExternalUserSession() Then
		SourceDocumentsOriginalsRecording.WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList);
		If PrintList.Count() = 0 Then
			Return;
		EndIf;
		InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintList, Written1);
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Records the new state of the original document.
//	
// Parameters:
//  RecordData - Array of Structure - :
//                 * OverallState 						- Boolean -  True if the current state is shared;
//                 * Ref 								- DocumentRef -  link to the document for which you want to change the state of the original;
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           current status of the original primary document;
//                 * SourceDocument 					- String -  id of the primary document. Set if this state is not shared;
//                 * FromOutside 								- Boolean -  True if the primary document was added manually by the user. Set if this state is not shared. 
//               - DocumentRef -  a link to the document for which you want to change the state of the original.
//  StateName - String -  set state.
// 
// Returns:
//  String - 
//            
//            
//
Function SetNewOriginalState(Val RecordData, Val StateName) Export

	Return SourceDocumentsOriginalsRecording.SetNewOriginalState(RecordData, StateName);

EndFunction

// Returns a reference to the document by the barcode of the tabular document
//
// Parameters:
//  Barcode - String -  scanned barcode of the document.
//
Procedure ProcessBarcode(Barcode) Export
	
	SourceDocumentsOriginalsRecording.ProcessBarcode(Barcode);

EndProcedure

// Returns a structure with data about the current General state of the original document by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef -  a link to the document for which you want to get information about the general state. 
//
//  Returns:
//    Structure - :
//    * Ref - DocumentRef -  link to the document;
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -  the current
//        state of the original document.
//
Function OriginalStateInfoByRef(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OriginalStateInfoByRef(DocumentRef);
	
EndFunction

// Fills in the drop-down list for selecting States on the form.
// 
//	Parameters:
//  OriginalStatesChoiceList - ValueList -  the states of the original, allowed to users, and used when
//                                                    changing the state of the original.
//
Procedure FillOriginalStatesChoiceList(OriginalStatesChoiceList) Export
	
	OriginalStatesChoiceList.Clear();
	OriginalsStates = SourceDocumentsOriginalsRecording.UsedStates();
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description);
		EndIf;

	EndDo;
EndProcedure

// Checks and returns whether the referenced document is an original document.
//
//	Parameters:
//  ObjectRef - DocumentRef -  link to the document that you want to check.
//
//	Returns:
//  Boolean - 
//
Function IsAccountingObject(ObjectRef) Export
	
	Return SourceDocumentsOriginalsRecording.IsAccountingObject(ObjectRef);

EndFunction

// Returns the key for recording the General state register of the original document by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef -  link to the document for which you need to get the shared state record key.
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates - 
//
Function OverallStateRecordKey(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OverallStateRecordKey(DocumentRef);

EndFunction

#EndRegion
