﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
//
// Parameters:
//    DataCompositionSchema - DataCompositionSchema
//
Procedure AddFieldExtensionNum(DataCompositionSchema) Export
	IsNumberFieldFound = False;
	For Each DataSet In DataCompositionSchema.DataSets Do
		If Not DataSet.Fields.Count() Then
			QuerySchema = New QuerySchema;
			QuerySchema.SetQueryText(DataSet.Query);
			QueryFields = QuerySchema.QueryBatch[QuerySchema.QueryBatch.Count()-1].Columns;
			If QueryFields.Find("Number") <> Undefined Then
				IsNumberFieldFound = True;
				Break;
			EndIf;
		ElsIf DataSet.Fields.Find("Number") <> Undefined Then
			IsNumberFieldFound = True;
			Break;
		EndIf;
	EndDo;
	
	If IsNumberFieldFound And DataCompositionSchema.CalculatedFields.Find("Number.WithPrefix") = Undefined Then
		NewField = DataCompositionSchema.CalculatedFields.Add();
		NewField.Expression = "Number";
		NewField.Title = NStr("en = 'Number.With prefix';");
		NewField.DataPath = "Number.WithPrefix";
		NewField.ValueType = New TypeDescription("String");
	EndIf;
	
EndProcedure

// Performs actions to change the prefix of the information database
// Additionally, it allows data processing to continue numbering.
//
// Parameters:
//  Parameters - Structure - :
//   * NewIBPrefix - String -  new prefix of the information base.
//   * ContinueNumbering - Boolean -  indicates whether the numbering should continue.
//  ResultAddress - String -  address of the temporary storage where
//                                the result of the procedure should be placed.
//
Procedure ChangeIBPrefix(Parameters, ResultAddress = "") Export
	
	// 
	// 
	If Not Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		Return;
	EndIf;
	
	NewIBPrefix = Parameters.NewIBPrefix;
	ContinueNumbering = Parameters.ContinueNumbering;
	
	BeginTransaction();
	
	Try
		
		If ContinueNumbering Then
			ProcessDataToContinueNumbering(NewIBPrefix);
		EndIf;
		
		// 
		PrefixConstantName = "DistributedInfobaseNodePrefix";
		Constants[PrefixConstantName].Set(NewIBPrefix);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(EventLogEventReassignObjectsPrefixes(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		Raise NStr("en = 'Cannot change prefix.';");
		
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Returns whether the company or object date has changed.
//
// Parameters:
//  Ref - 
//  DateAfterChange - 
//  CompanyAfterChange - 
//
//  Returns:
//    Boolean - 
//            
//   
//
Function ObjectDateOrCompanyChanged(Ref, Val DateAfterChange, Val CompanyAfterChange) Export
	
	FullTableName = Ref.Metadata().FullName();
	QueryText = "
	|SELECT
	|	ObjectHeader.Date AS Date,
	|	ISNULL(ObjectHeader.CompanyAttributeName.Prefix, """") AS CompanyPrefixBeforeChange
	|FROM
	|	&TableName AS ObjectHeader
	|WHERE
	|	ObjectHeader.Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", FullTableName);
	QueryText = StrReplace(QueryText, "CompanyAttributeName", ObjectsPrefixesEvents.CompanyAttributeName(FullTableName));
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	CompanyPrefixAfterChange = Undefined;
	ObjectsPrefixesEvents.OnDetermineCompanyPrefix(CompanyAfterChange, CompanyPrefixAfterChange);
	
	// 
	CompanyPrefixAfterChange = ?(CompanyPrefixAfterChange = False, "", CompanyPrefixAfterChange);
	
	Return Selection.CompanyPrefixBeforeChange <> CompanyPrefixAfterChange
		Or Not ObjectDatesOfSamePeriod(Selection.Date, DateAfterChange, Ref);
	//
EndFunction

// Returns whether the object's company has changed.
//
// Parameters:
//  Ref - 
//  CompanyAfterChange - 
//
//  Returns:
//    Boolean - 
//
Function ObjectCompanyChanged(Ref, Val CompanyAfterChange) Export
	
	FullTableName = Ref.Metadata().FullName();
	QueryText = "
	|SELECT
	|	ISNULL(ObjectHeader.CompanyAttributeName.Prefix, """") AS CompanyPrefixBeforeChange
	|FROM
	|	&TableName AS ObjectHeader
	|WHERE
	|	ObjectHeader.Ref = &Ref
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", FullTableName);
	QueryText = StrReplace(QueryText, "CompanyAttributeName", ObjectsPrefixesEvents.CompanyAttributeName(FullTableName));
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	CompanyPrefixAfterChange = Undefined;
	ObjectsPrefixesEvents.OnDetermineCompanyPrefix(CompanyAfterChange, CompanyPrefixAfterChange);
	
	// 
	CompanyPrefixAfterChange = ?(CompanyPrefixAfterChange = False, "", CompanyPrefixAfterChange);
	
	Return Selection.CompanyPrefixBeforeChange <> CompanyPrefixAfterChange;
	
EndFunction

// Specifies whether two dates are equal for the metadata object.
// Dates are considered equal if they belong to the same time period: Year, Month, Day, etc.
//
// Parameters:
//   Date1 - 
//   Date2 - 
//   
//
//  Returns:
//    Boolean - 
//
Function ObjectDatesOfSamePeriod(Val Date1, Val Date2, Ref) Export
	
	ObjectMetadata = Ref.Metadata();
	
	If DocumentNumberPeriodicityYear(ObjectMetadata) Then
		
		DateDiff = BegOfYear(Date1) - BegOfYear(Date2);
		
	ElsIf DocumentNumberPeriodicityQuarter(ObjectMetadata) Then
		
		DateDiff = BegOfQuarter(Date1) - BegOfQuarter(Date2);
		
	ElsIf DocumentNumberPeriodicityMonth(ObjectMetadata) Then
		
		DateDiff = BegOfMonth(Date1) - BegOfMonth(Date2);
		
	ElsIf DocumentNumberPeriodicityDay(ObjectMetadata) Then
		
		DateDiff = BegOfDay(Date1) - BegOfDay(Date2);
		
	Else // 
		
		DateDiff = 0;
		
	EndIf;
	
	Return DateDiff = 0;
	
EndFunction

Function MetadataUsingPrefixesDetails(DiagnosticsMode = False) Export
	
	Result = NewMetadataUsingPrefixesDetails();
	
	ModuleSaaSOperations = Undefined;
	IsSAASSubsystem = Common.SubsystemExists("CloudTechnology.Core");
	If IsSAASSubsystem Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	EndIf;

	// 
	DataSeparationEnabled = Common.DataSeparationEnabled();
	For Each Subscription In Metadata.EventSubscriptions Do
		
		IBPrefixUsed = False;
		CompanyPrefixIsUsed = False;
		If Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetInfobaseAndCompanyPrefix") Then
			IBPrefixUsed = True;
			CompanyPrefixIsUsed = True;
		ElsIf Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetInfobasePrefix") Then
			IBPrefixUsed = True;
		ElsIf Upper(Subscription.Handler) = Upper("ObjectsPrefixesEvents.SetCompanyPrefix") Then
			CompanyPrefixIsUsed = True;
		Else
			// 
			Continue;
		EndIf;
		
		For Each SourceType In Subscription.Source.Types() Do
			
			SourceMetadata = Metadata.FindByType(SourceType);
			FullObjectName = SourceMetadata.FullName();
			
			IsSeparatedMetadataObject = False;
			If IsSAASSubsystem Then
				IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(FullObjectName);
			EndIf;
			
			// 
			// 
			If Not DiagnosticsMode Then
				
				If Result.Find(FullObjectName, "FullName") <> Undefined Then
					Continue;
				ElsIf DataSeparationEnabled Then
					
					If Not IsSeparatedMetadataObject Then
						Continue;
					EndIf;
					
				EndIf;
				
			EndIf;
			
			ObjectDetails = Result.Add();
			ObjectDetails.Name = SourceMetadata.Name;
			ObjectDetails.FullName = FullObjectName;
			ObjectDetails.IBPrefixUsed = IBPrefixUsed;
			ObjectDetails.CompanyPrefixIsUsed = CompanyPrefixIsUsed;
		
			// 
			ObjectDetails.IsCatalog             = Common.IsCatalog(SourceMetadata);
			ObjectDetails.IsChartOfCharacteristicTypes = Common.IsChartOfCharacteristicTypes(SourceMetadata);
			ObjectDetails.IsDocument               = Common.IsDocument(SourceMetadata);
			ObjectDetails.IsBusinessProcess          = Common.IsBusinessProcess(SourceMetadata);
			ObjectDetails.IsTask                 = Common.IsTask(SourceMetadata);
			
			ObjectDetails.SubscriptionName = Subscription.Name;
			
			ObjectDetails.IsSeparatedMetadataObject = IsSeparatedMetadataObject;
			
			Characteristics = New Structure("CodeLength, NumberLength", 0, 0);
			FillPropertyValues(Characteristics, SourceMetadata);
			
			If Characteristics.CodeLength = 0 And Characteristics.NumberLength = 0 Then
				
				If Not DiagnosticsMode Then
					
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'An error occurred while integrating subsystem %1 for metadata object %2.';"),
						Metadata.Subsystems.StandardSubsystems.Subsystems.ObjectsPrefixes, FullObjectName);
						
				EndIf;
				
			Else
				
				If ObjectDetails.IsCatalog Or ObjectDetails.IsChartOfCharacteristicTypes Then
					ObjectDetails.HasCode = True;
				Else
					ObjectDetails.HasNumber = True;
				EndIf;
				
			EndIf;
			
			// 
			NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Nonperiodical;
			If ObjectDetails.IsDocument Then
				NumberPeriodicity = SourceMetadata.NumberPeriodicity;
			ElsIf ObjectDetails.IsBusinessProcess Then
				If SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Year Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Year;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Day Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Day;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Quarter Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Quarter;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Month Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Month;
				ElsIf SourceMetadata.NumberPeriodicity = Metadata.ObjectProperties.BusinessProcessNumberPeriodicity.Nonperiodical Then
					NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Nonperiodical;
				EndIf;
			EndIf;
			ObjectDetails.NumberPeriodicity = NumberPeriodicity;
			
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction


////////////////////////////////////////////////////////////////////////////////
// 

// Determines whether the "post-load Data" event handler must be executed when exchanging data to the rib.
//
// Parameters:
//  NewIBPrefix - String -  required for calculating new element codes (numbers) after changing the prefix.
//  DataAnalysisMode - Boolean -  if True, no data changes occur, the function only calculates
//                                what data will be changed and how it will be changed. If False, changes to the object
//                                are recorded in the information database.
//
// Returns:
//   See ObjectsPrefixesInternal.MetadataUsingPrefixesDetails
//
Function ProcessDataToContinueNumbering(Val NewIBPrefix = "", DataAnalysisMode = False)
	
	MetadataUsingPrefixesDetails = MetadataUsingPrefixesDetails();
	
	SupplementStringWithZerosOnLeft(NewIBPrefix, 2);
	
	Result = NewMetadataUsingPrefixesDetails();
	Result.Columns.Add("Ref");
	Result.Columns.Add("Number");
	Result.Columns.Add("NewNumber");
	
	CurrentIBPrefix = "";
	ObjectsPrefixesEvents.OnDetermineInfobasePrefix(CurrentIBPrefix);
	SupplementStringWithZerosOnLeft(CurrentIBPrefix, 2);
	
	For Each ObjectDetails In MetadataUsingPrefixesDetails Do
		
		If Not DataAnalysisMode Then
			DataLock = New DataLock;
			DataLock.Add(ObjectDetails.FullName);
			DataLock.Lock();
		EndIf;
		
		// 
		ObjectDataForLastItemRenumbering = OneKindObjectDataForLastItemsRenumbering(
			ObjectDetails, CurrentIBPrefix);
		If ObjectDataForLastItemRenumbering.IsEmpty() Then
			Continue;
		EndIf;
		
		ObjectSelection = ObjectDataForLastItemRenumbering.Select();
		While ObjectSelection.Next() Do
			
			NewResultString = Result.Add();
			FillPropertyValues(NewResultString, ObjectDetails);
			FillPropertyValues(NewResultString, ObjectSelection);
			NewResultString.NewNumber = StrReplace(NewResultString.Number, CurrentIBPrefix + "-", NewIBPrefix + "-");
			
			If Not DataAnalysisMode Then
				RenumberingObject = NewResultString.Ref.GetObject();
				RenumberingObject[?(NewResultString.HasNumber, "Number", "Code")] = NewResultString.NewNumber;
				InfobaseUpdate.WriteData(RenumberingObject, True, False);
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function DocumentNumberPeriodicityYear(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Year;
	
EndFunction

Function DocumentNumberPeriodicityQuarter(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Quarter;
	
EndFunction

Function DocumentNumberPeriodicityMonth(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Month;
	
EndFunction

Function DocumentNumberPeriodicityDay(ObjectMetadata)
	
	Return ObjectMetadata.NumberPeriodicity = Metadata.ObjectProperties.DocumentNumberPeriodicity.Day;
	
EndFunction

Function OneKindObjectDataForLastItemsRenumbering(Val ObjectDetails, Val PreviousPrefix = "")
	
	FullObjectName = ObjectDetails.FullName;
	HasNumber = ObjectDetails.HasNumber;
	CompanyPrefixIsUsed = ObjectDetails.CompanyPrefixIsUsed;
	
	Query = New Query;
	
	BatchQueryText = New Array;
	Separator =
	"
	|;
	|/////////////////////////////////////////////////////////////
	|";

	QueryText =
	"SELECT
	|	SelectionByDateNumber.Ref AS Ref,
	|	&CompanyFieldName1 AS Organization,
	|	&CodeNumberFieldName AS Number
	|INTO SelectionByDateNumber
	|FROM
	|	&TableName AS SelectionByDateNumber
	|WHERE
	|	&ConditionByDate AND &CodeNumberFieldName LIKE &Prefix ESCAPE ""~""
	|
	|INDEX BY
	|	Number,
	|	Organization";
	
	QueryText = StrReplace(QueryText, "&ConditionByDate", ?(HasNumber, "SelectionByDateNumber.Date >= &Date", "TRUE"));
	QueryText = StrReplace(QueryText, "&CodeNumberFieldName", "SelectionByDateNumber." + ?(HasNumber, "Number", "Code"));
	QueryText = StrReplace(QueryText, "&TableName", FullObjectName);
	
	CompanyFieldName1 = ?(CompanyPrefixIsUsed,
		"SelectionByDateNumber." + ObjectsPrefixesEvents.CompanyAttributeName(FullObjectName), "Undefined");
	QueryText = StrReplace(QueryText, "&CompanyFieldName1", CompanyFieldName1);
	
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	MaxCodes.Organization AS Organization,
	|	MAX(MaxCodes.Number) AS Number
	|INTO MaxCodes
	|FROM
	|	SelectionByDateNumber AS MaxCodes
	|
	|GROUP BY
	|	MaxCodes.Organization
	|
	|INDEX BY
	|	Number,
	|	Organization";
	BatchQueryText.Add(QueryText);
	
	QueryText =
	"SELECT
	|	SelectionByDateNumber.Organization AS Organization,
	|	SelectionByDateNumber.Number AS Number,
	|	MAX(SelectionByDateNumber.Ref) AS Ref
	|FROM
	|	SelectionByDateNumber AS SelectionByDateNumber
	|		INNER JOIN MaxCodes AS MaxCodes
	|		ON (MaxCodes.Number = SelectionByDateNumber.Number
	|				AND MaxCodes.Organization = SelectionByDateNumber.Organization)
	|
	|GROUP BY
	|	SelectionByDateNumber.Organization,
	|	SelectionByDateNumber.Number";
	BatchQueryText.Add(QueryText);
	
	Query.Text = StrConcat(BatchQueryText, Separator);
	
	If HasNumber Then
		// 
		FromDate = BegOfDay(BegOfYear(CurrentSessionDate()));
		Query.SetParameter("Date", BegOfDay(FromDate));
	EndIf;
	
	// 
	Query.SetParameter("Prefix", 
		"%" + Common.GenerateSearchQueryString(PreviousPrefix) + "-%");
	
	Return Query.Execute();
	
EndFunction

Function NewMetadataUsingPrefixesDetails()
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	
	Result = New ValueTable;
	Result.Columns.Add("Name",                            TypesDetailsString);
	Result.Columns.Add("FullName",                      TypesDetailsString);
	
	Result.Columns.Add("HasCode",                        TypesDetailsBoolean);
	Result.Columns.Add("HasNumber",                      TypesDetailsBoolean);
	Result.Columns.Add("IsCatalog",                  TypesDetailsBoolean);
	Result.Columns.Add("IsChartOfCharacteristicTypes",      TypesDetailsBoolean);
	Result.Columns.Add("IsDocument",                    TypesDetailsBoolean);
	Result.Columns.Add("IsBusinessProcess",               TypesDetailsBoolean);
	Result.Columns.Add("IsTask",                      TypesDetailsBoolean);
	Result.Columns.Add("IBPrefixUsed",          TypesDetailsBoolean);
	Result.Columns.Add("CompanyPrefixIsUsed", TypesDetailsBoolean);
	
	Result.Columns.Add("NumberPeriodicity");
	
	Result.Columns.Add("SubscriptionName", TypesDetailsString);
	
	Result.Columns.Add("IsSeparatedMetadataObject", TypesDetailsBoolean);
	
	Return Result;
	
EndFunction

Procedure SupplementStringWithZerosOnLeft(String, StringLength)
	
	String = StringFunctionsClientServer.SupplementString(String, StringLength, "0", "Left");
	
EndProcedure

Function EventLogEventReassignObjectsPrefixes()
	
	Return NStr("en = 'Object prefixes. Infobase prefix changed.';",
		Common.DefaultLanguageCode());
	
EndFunction

#EndRegion