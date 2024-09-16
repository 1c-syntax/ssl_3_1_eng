///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 

// Gets all the necessary information for printing in one call: object data by layout, binary
// layout data, and description of layout areas.
// To call from client modules to print forms based on office document layouts.
//
// Parameters:
//   PrintManagerName - String -  name for accessing the object Manager, such as " Document.<Document name>".
//   TemplatesNames       - String -  names of layouts that will be used for forming printed forms.
//   DocumentsComposition   - Array -  links to information database objects (must be of the same type).
//
// Returns:
//  Map of KeyAndValue - :
//   * Key - AnyRef -  link to the information base object;
//   * Value - Structure:
//       ** Key - String -  layout name;
//       ** Value - Structure -  object data.
//
Function TemplatesAndObjectsDataToPrint(Val PrintManagerName, Val TemplatesNames, Val DocumentsComposition) Export
	
	Return PrintManagement.TemplatesAndObjectsDataToPrint(PrintManagerName, TemplatesNames, DocumentsComposition);
	
EndFunction

#EndRegion

#Region Private

// Form printing forms for direct output to the printer.
//
// For more information, see description of the print management.Form a printable form for fast printing().
//
Function GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames, ObjectsArray,	PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrint(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Generate printing forms for direct output to the printer in a regular application.
//
// For more information, see description of the print management.Form a printable form for a quick printable custom application().
//
Function GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames, ObjectsArray, PrintParameters) Export
	
	Return PrintManagement.GeneratePrintFormsForQuickPrintOrdinaryApplication(PrintManagerName, TemplatesNames,
		ObjectsArray,	PrintParameters);
	
EndFunction

// Returns true if there is a holding right for at least one document.
Function HasRightToPost(DocumentsList) Export
	Return StandardSubsystemsServer.HasRightToPost(DocumentsList);
EndFunction

// See PrintManagement.DocumentsPackage.
Function DocumentsPackage(SpreadsheetDocuments, PrintObjects, PrintInSets, Copies = 1) Export
	
	Return PrintManagement.DocumentsPackage(SpreadsheetDocuments, PrintObjects,
		PrintInSets, Copies);
	
EndFunction

#Region PrintingInBackgroundJob

Function StartGeneratingPrintForms(ParametersForOpeningIncoming) Export
	
	OpeningParameters = Common.CopyRecursive(ParametersForOpeningIncoming);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(OpeningParameters.StorageUUID);
	ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, OpeningParameters.StorageUUID);
	StoragesContents = Undefined;
	ExtractFromRepositories(OpeningParameters.PrintParameters, StoragesContents);
	OpeningParameters.Insert("StoragesContents", StoragesContents);
	If Not ValueIsFilled(OpeningParameters.DataSource) Then 
		CommonClientServer.Validate(TypeOf(OpeningParameters.CommandParameter) = Type("Array") Or Common.RefTypeValue(OpeningParameters.CommandParameter),
			StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"en = 'Invalid parameter value. %1 parameter, %2 method.
				|Expected value: %3, %4.
				|Passed value: %5.';"),
				"CommandParameter",
				"PrintManagementClient.ExecutePrintCommand",
				"Array",
				"AnyRef",
				 TypeOf(OpeningParameters.CommandParameter)));
	EndIf;

	// 
	PrintParameters = OpeningParameters.PrintParameters;
	If OpeningParameters.PrintParameters = Undefined Then
		PrintParameters = New Structure;
	EndIf;
	If Not PrintParameters.Property("AdditionalParameters") Then
		OpeningParameters.PrintParameters = New Structure("AdditionalParameters", PrintParameters);
		For Each PrintParameter In PrintParameters Do
			OpeningParameters.PrintParameters.Insert(PrintParameter.Key, PrintParameter.Value);
		EndDo;
	EndIf;
			
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "PrintManagement.GeneratePrintFormsInBackground", OpeningParameters);
EndFunction 

Procedure ExtractFromRepositories(ParametersStructure, StoragesContents)
	If StoragesContents = Undefined Then
		StoragesContents = New Map;
	EndIf;
	
	ParametersType = TypeOf(ParametersStructure);
	If ParametersType = Type("String") And IsTempStorageURL(ParametersStructure) Then
		StoragesContents.Insert(ParametersStructure, GetFromTempStorage(ParametersStructure));
	ElsIf ParametersType = Type("Array") Or ParametersType = Type("ValueTable") 
		Or ParametersType = Type("ValueTableRow") Or ParametersType = Type("ValueTreeRow") Then
		
		For Each Item In ParametersStructure Do
			ExtractFromRepositories(Item, StoragesContents);
		EndDo;
	ElsIf ParametersType = Type("Structure") Or ParametersType = Type("Map") Then
		
		For Each Item In ParametersStructure Do
			ExtractFromRepositories(Item.Value, StoragesContents);
		EndDo;
		
		If ParametersType = Type("Map") Then
			For Each Item In ParametersStructure Do
				ExtractFromRepositories(Item.Key, StoragesContents);
			EndDo;
		EndIf;

	ElsIf  ParametersType = Type("ValueTree") Then
		For Each Item In ParametersStructure.Rows Do
			ExtractFromRepositories(Item, StoragesContents);
		EndDo;
	EndIf;
	
EndProcedure
#EndRegion

#EndRegion
