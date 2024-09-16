///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Adds currencies from the classifier to the currency directory.
// If there is no processing of course Uploadsvalue currencies are added with the name "currency",
// the character code corresponds to a digital one.
//
// Parameters:
//   Codes - Array -  digital codes of the added currencies.
//
// Returns:
//   Array, CatalogRef.Currencies - 
//
Function AddCurrenciesByCode(Val Codes) Export
	
	Result = New Array();
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		Result = DataProcessors["CurrenciesRatesImport"].AddCurrenciesByCode(Codes);
	Else
		For Each Code In Codes Do
			CurrencyRef = Catalogs.Currencies.FindByCode(Code);
			If CurrencyRef.IsEmpty() Then
				CurrencyObject = Catalogs.Currencies.CreateItem();
				CurrencyObject.Code = Code;
				CurrencyObject.Description = Code;
				CurrencyObject.DescriptionFull = NStr("en = 'Currency';");
				CurrencyObject.RateSource = Enums.RateSources.ManualInput;
				CurrencyObject.Write();
				CurrencyRef = CurrencyObject.Ref;
			EndIf;
			Result.Add(CurrencyRef);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the currency exchange rate on the date.
//
// Parameters:
//   Currency    - CatalogRef.Currencies -  the currency for which the exchange rate is obtained.
//   DateOfCourse - Date -  the date on which the course is obtained.
//
// Returns: 
//   Structure:
//    * Rate      - Number -  currency exchange rate on the specified date.
//    * Repetition - Number -  multiple of the currency on the specified date.
//    * Currency    - CatalogRef.Currencies -  the reference currency.
//    * DateOfCourse - Date -  date the course was received.
//
Function GetCurrencyRate(Currency, DateOfCourse) Export
	
	Result = InformationRegisters.ExchangeRates.GetLast(DateOfCourse, New Structure("Currency", Currency));
	
	Result.Insert("Currency",    Currency);
	Result.Insert("DateOfCourse", DateOfCourse);
	
	Return Result;
	
EndFunction

// Generates a representation of the amount in words in the specified currency.
//
// Parameters:
//   AmountAsNumber - Number -  the amount to be presented in words.
//   Currency - CatalogRef.Currencies -  the currency in which to submit the amount.
//   OmitFractionalPart - Boolean -  specify True if you want to get the amount without a fractional part (without kopecks).
//   LanguageCode - String -  the language in which you want to get the amount in words.
//                       It consists of the ISO 639-1 language code and, optionally, the ISO 3166-1 country code, separated
//                       by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_RU".
//                       The default value is the configuration language.
//   IsFractionalPartInWords - Boolean
//
// Returns:
//   String - 
//
Function GenerateAmountInWords(AmountAsNumber, Currency, OmitFractionalPart = False, Val LanguageCode = Undefined, IsFractionalPartInWords = False) Export
	
	AmountInWordsParameters = Common.ObjectAttributeValue(Currency, "AmountInWordsParameters", , LanguageCode);
	
	If Not ValueIsFilled(LanguageCode) Then
		LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	
	Sum = ?(AmountAsNumber < 0, -AmountAsNumber, AmountAsNumber);
	Format = StrTemplate("L=%1;DP=%2", LanguageCode, ?(IsFractionalPartInWords, "True", "False"));
	Result = NumberInWords(Sum, Format, AmountInWordsParameters); // 
	If OmitFractionalPart And Int(Sum) = Sum Then
		Result = Left(Result, StrFind(Result, "0") - 1);
	EndIf;
	
	Return Result;
	
EndFunction

// Converts the amount from one currency to another.
//
// Parameters:
//  Sum          - Number -  amount to be recalculated;
//  SourceCurrency - CatalogRef.Currencies -  currency to be converted;
//  NewCurrency    - CatalogRef.Currencies -  the currency in which you want to convert;
//  Date           - Date -  date of currency exchange rates.
//
// Returns:
//  Number - 
//
Function ConvertToCurrency(Sum, SourceCurrency, NewCurrency, Date) Export
	
	Return CurrencyRateOperationsClientServer.ConvertAtRate(Sum,
		GetCurrencyRate(SourceCurrency, Date),
		GetCurrencyRate(NewCurrency, Date));
		
EndFunction

// It is intended for use in the constructor of the Number type for money fields.
//
// Parameters:
//  AllowedSignOfField - AllowedSign -  specifies the valid character of the number. The default value is a valid Sign.Any.
// 
// Returns:
//  TypeDescription - 
//
Function MoneyFieldTypeDescription(Val AllowedSignOfField = Undefined) Export
	
	If AllowedSignOfField = Undefined Then
		AllowedSignOfField = AllowedSign.Any;
	EndIf;
	
	If AllowedSignOfField = AllowedSign.Any Then
		Return Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type;
	EndIf;
	
	Return Metadata.DefinedTypes.MonetaryAmountNonNegative.Type;
	
EndFunction

// 
// 
// 
// Parameters:
//  PrintDataSources - See PrintManagementOverridable.OnDefinePrintDataSources.PrintDataSources
//
Procedure ConnectPrintDataSourceNumberWritten(PrintDataSources) Export
	
	PrintDataSources.Add(SchemaDataPrintAmountWords(), "DataPrintAmountWords");	
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	MetadataObject = Metadata.DataProcessors.Find("CurrenciesRatesImport");
	If MetadataObject = Undefined Then
		Return;
	EndIf;

	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Common.DataSeparationEnabled() // 
		Or Common.IsStandaloneWorkplace()
		Or Not CurrencyRateOperationsInternal.HasRightToChangeExchangeRates()
		Or ModuleToDoListServer.UserTaskDisabled("CurrencyClassifier") Then
		Return;
	EndIf;
	
	RatesUpToDate = RatesUpToDate();
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(MetadataObject.FullName());
	
	For Each Section In Sections Do
		
		CurrencyID = "CurrencyClassifier" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = CurrencyID;
		ToDoItem.HasToDoItems       = Not RatesUpToDate;
		ToDoItem.Presentation  = NStr("en = 'Outdated exchange rates';");
		ToDoItem.Important         = True;
		ToDoItem.Form          = "DataProcessor.CurrenciesRatesImport.Form";
		ToDoItem.FormParameters = New Structure("OpeningFromList", True);
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.Currencies.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.Currencies.FullName(), "AttributesToEditInBatchProcessing");
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings.
Procedure OnDefineScheduledJobSettings(Settings) Export
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		DataProcessors["CurrenciesRatesImport"].OnDefineScheduledJobSettings(Settings);
	EndIf;
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment.
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.ReadCurrencyRates.Name);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	ShouldNotifyWhenExchageRatesOutdated = ShouldNotifyWhenExchageRatesOutdated();
	
	Parameters.Insert("Currencies", New FixedStructure("ExchangeRatesUpdateRequired",
		ShouldNotifyWhenExchageRatesOutdated And Not RatesUpToDate()));
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.ExchangeRates.FullName());
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions()));
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		DataProcessors["CurrenciesRatesImport"].OnAddUpdateHandlers(Handlers);
	EndIf;
	
EndProcedure

// See OnlineUserSupportOverridable.OnChangeOnlineSupportAuthenticationData.
Procedure OnChangeOnlineSupportAuthenticationData(UserData) Export
	
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		DataProcessors["CurrenciesRatesImport"].OnChangeOnlineSupportAuthenticationData(UserData);
	EndIf;
	
EndProcedure

// Checks whether there is a set exchange rate and currency multiplicity as of January 1, 1980.
// In case of absence, sets the rate and multiplicity equal to one.
//
// Parameters:
//  Currency - 
//
Procedure CheckCurrencyRateAvailabilityFor01011980(Currency) Export
	
	DateOfCourse = Date("19800101");
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExchangeRates");
	LockItem.SetValue("Currency", Currency);
	LockItem.SetValue("Period", DateOfCourse);
	
	BeginTransaction();
	Try
		Block.Lock();
		RateStructure = InformationRegisters.ExchangeRates.GetLast(DateOfCourse, New Structure("Currency", Currency));
		
		If (RateStructure.Rate = 0) Or (RateStructure.Repetition = 0) Then
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(Currency);
			RecordSet.Filter.Period.Set(DateOfCourse);
			Record = RecordSet.Add();
			Record.Currency = Currency;
			Record.Period = DateOfCourse;
			Record.Rate = 1;
			Record.Repetition = 1;
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// See PrintManagementOverridable.WhenPreparingPrintData
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, DataCompositionSchemaId, LanguageCode,
	AdditionalParameters) Export
	
	If DataCompositionSchemaId = "DataPrintAmountWords" Then
		ExternalDataSets.Insert("Data", DataPrintAmountWords(AdditionalParameters.DataSourceDescriptions, LanguageCode));
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure ImportActualRate(ImportParameters = Undefined, ResultAddress = Undefined) Export
	
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		DataProcessors["CurrenciesRatesImport"].ImportActualRate(ImportParameters, ResultAddress);
	EndIf;
	
EndProcedure

// Returns a list of permissions for loading currency rates from external resources.
//
// Returns:
//  Array
//
Function Permissions()
	
	Permissions = New Array;
	DataProcessorName = "CurrenciesRatesImport";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		DataProcessors[DataProcessorName].AddPermissions(Permissions);
	EndIf;
	
	Return Permissions;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns an array of currencies whose exchange rates are loaded from external resources.
//
Function CurrenciesToImport() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Ref AS Ref
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND NOT Currencies.DeletionMark
	|
	|ORDER BY
	|	Currencies.DescriptionFull";

	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function FillCurrencyRateData(SelectedCurrency) Export
	
	RateData = New Structure("DateOfCourse, Rate, Repetition");
	
	Query = New Query;
	
	Query.Text = "SELECT RegRates.Period, RegRates.Rate, RegRates.Repetition
	              | FROM InformationRegister.ExchangeRates.SliceLast(&ImportPeriodEnd, Currency = &SelectedCurrency) AS RegRates";
	Query.SetParameter("SelectedCurrency", SelectedCurrency);
	Query.SetParameter("ImportPeriodEnd", CurrentSessionDate());
	
	SelectionRate = Query.Execute().Select();
	SelectionRate.Next();
	
	RateData.DateOfCourse = SelectionRate.Period;
	RateData.Rate      = SelectionRate.Rate;
	RateData.Repetition = SelectionRate.Repetition;
	
	Return RateData;
	
EndFunction

Function DependentCurrenciesList(BaseCurrency, AdditionalProperties = Undefined) Export
	
	Cached = (TypeOf(AdditionalProperties) = Type("Structure"));
	
	If Cached Then
		
		DependentCurrencies = AdditionalProperties.DependentCurrencies.Get(BaseCurrency);
		
		If TypeOf(DependentCurrencies) = Type("ValueTable") Then
			Return DependentCurrencies;
		EndIf;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CurrencyCatalog.Ref,
	|	CurrencyCatalog.Markup,
	|	CurrencyCatalog.RateSource,
	|	CurrencyCatalog.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CurrencyCatalog
	|WHERE
	|	CurrencyCatalog.MainCurrency = &BaseCurrency
	|
	|UNION ALL
	|
	|SELECT
	|	CurrencyCatalog.Ref,
	|	CurrencyCatalog.Markup,
	|	CurrencyCatalog.RateSource,
	|	CurrencyCatalog.RateCalculationFormula
	|FROM
	|	Catalog.Currencies AS CurrencyCatalog
	|WHERE
	|	CurrencyCatalog.RateCalculationFormula LIKE &AlphabeticCode ESCAPE ""~""";
	
	Query.SetParameter("BaseCurrency", BaseCurrency);
	Query.SetParameter("AlphabeticCode", "%" +  Common.GenerateSearchQueryString(BaseCurrency) + "%");
	DependentCurrencies = Query.Execute().Unload();	
	If Cached Then		
		AdditionalProperties.DependentCurrencies.Insert(BaseCurrency, DependentCurrencies);		
	EndIf;
	
	Return DependentCurrencies;
	
EndFunction

Procedure UpdateCurrencyRate(Parameters, ResultAddress) Export
	
	DependentCurrency = Parameters.Currency;
	ListOfCurrencies = Parameters.Currency.CurrenciesUsedInCalculatingTheExchangeRate;
	
	QueryText =
	"SELECT
	|	ExchangeRates.Period AS Period,
	|	ExchangeRates.Currency AS Currency
	|FROM
	|	InformationRegister.ExchangeRates AS ExchangeRates
	|WHERE
	|	ExchangeRates.Currency IN(&Currency)
	|
	|GROUP BY
	|	ExchangeRates.Period,
	|	ExchangeRates.Currency
	|
	|ORDER BY
	|	Period";
	
	Query = New Query(QueryText);
	Query.SetParameter("Currency", ListOfCurrencies);
	
	Selection = Query.Execute().Select();
	
	UpdatedPeriods = New Map;
	While Selection.Next() Do
		If UpdatedPeriods[Selection.Period] <> Undefined Then 
			Continue;
		EndIf;
		
		BeginTransaction();
		Try
			For Each Currency In ListOfCurrencies Do
				Block = New DataLock;
				LockItem = Block.Add("InformationRegister.ExchangeRates");
				LockItem.SetValue("Currency", Currency);
				LockItem.SetValue("Period", Selection.Period);
			EndDo;
			Block.Lock();
			
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(Selection.Currency);
			RecordSet.Filter.Period.Set(Selection.Period);
			RecordSet.Read();
			RecordSet.AdditionalProperties.Insert("UpdateSubordinateCurrencyRate", DependentCurrency);
			RecordSet.AdditionalProperties.Insert("CurrencyCodes", Parameters.CurrencyCodes);
			RecordSet.AdditionalProperties.Insert("UpdatedPeriods", UpdatedPeriods);
			RecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			RecordSet.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		UpdatedPeriods.Insert(Selection.Period, True);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks the current exchange rates of all currencies.
//
Function RatesUpToDate() Export
	QueryText =
	"SELECT
	|	Currencies.Ref AS Ref
	|INTO ttCurrencies
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)
	|	AND Currencies.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	1 AS Field1
	|FROM
	|	ttCurrencies AS Currencies
	|		LEFT JOIN InformationRegister.ExchangeRates AS ExchangeRates
	|		ON Currencies.Ref = ExchangeRates.Currency
	|			AND (ExchangeRates.Period = &CurrentDate)
	|WHERE
	|	ExchangeRates.Currency IS NULL ";
	
	Query = New Query;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.Text = QueryText;
	
	Return Query.Execute().IsEmpty();
EndFunction

// 
//
Function ShouldNotifyWhenExchageRatesOutdated()
	
	// 
	If Common.DataSeparationEnabled() Or Common.IsStandaloneWorkplace() 
		Or Not CurrencyRateOperationsInternal.HasRightToChangeExchangeRates() Then
		Return False;
	EndIf;
	
	EnableNotifications = Not Common.SubsystemExists("StandardSubsystems.ToDoList");
	CurrencyRateOperationsOverridable.OnDetermineWhetherCurrencyRateUpdateWarningRequired(EnableNotifications);
	
	Return EnableNotifications;
	
EndFunction

Function SchemaDataPrintAmountWords()
	
	If Common.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManager = Common.CommonModule("PrintManagement");
	
		FieldList = ModulePrintManager.PrintDataFieldTable();
		
		Field = FieldList.Add();
		Field.Id = "Ref";
		Field.Presentation = NStr("en = 'Ref';");
		Field.ValueType = New TypeDescription();	
	
		Field = FieldList.Add();
		Field.Id = "Currency";
		Field.Presentation = NStr("en = 'Currency';");
		Field.ValueType = New TypeDescription();	
	
		Field = FieldList.Add();
		Field.Id = "NumberInWords";
		Field.Presentation = NStr("en = 'Amount in words';");
		Field.ValueType = New TypeDescription("String");
		
		Return ModulePrintManager.SchemaCompositionDataPrint(FieldList);
	EndIf;
	
EndFunction

Function DataPrintAmountWords(DataSourceDescriptions, LanguageCode)
	
	PrintData = New ValueTable();
	PrintData.Columns.Add("Ref");
	PrintData.Columns.Add("Currency");
	PrintData.Columns.Add("NumberInWords");
	
	For Each SourceDetails In DataSourceDescriptions Do
		TableRow = PrintData.Add();
		TableRow.Ref = SourceDetails.Value;
		If Common.IsReference(TypeOf(SourceDetails.Owner)) Then
			MetadataObject = Metadata.FindByType(TypeOf(SourceDetails.Owner));
			For Each Attribute In MetadataObject.Attributes Do
				If Attribute.Type.ContainsType(Type("CatalogRef.Currencies")) Then
					Currency = Common.ObjectAttributeValue(SourceDetails.Owner, Attribute.Name);
					If ValueIsFilled(Currency) Then
						TableRow.Currency = Currency;
						TableRow.NumberInWords = GenerateAmountInWords(
							SourceDetails.Value, Currency, , LanguageCode);
						Break;
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return PrintData;
	
EndFunction

#EndRegion
