﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Download the full list of all-time courses.
//
Procedure ImportCurrencyRates() Export
	
	If Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	Descriptors = ModuleSuppliedData.DescriptorsOfSuppliedDataFromManager("ExchangeRates");
	
	If Descriptors.Descriptor.Count() < 1 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'The service manager has no data of type ""%1""';"), "ExchangeRates");
	EndIf;
	
	ExRates = ModuleSuppliedData.ReferencesSuppliedDataFromCache("OneCurrencyRates");
	For Each Rate In ExRates Do
		ModuleSuppliedData.DeleteSuppliedDataFromCache(Rate);
	EndDo; 
	
	ModuleSuppliedData.UploadAndProcessData(Descriptors.Descriptor[0]);
	
EndProcedure

// Called when changing the method of setting the currency exchange rate.
//
// Parameters:
//  Currency - CatalogObject.Currencies
//
Procedure ScheduleCopyCurrencyRates(Val Currency) Export
	
	If Not Common.SubsystemExists("CloudTechnology.JobsQueue")
		Or Currency.RateSource <> Enums.RateSources.DownloadFromInternet Then
		Return;
	EndIf;
	
	MethodParameters = New Array;
	MethodParameters.Add(Currency.Code);

	JobParameters = New Structure;
	JobParameters.Insert("MethodName", "CurrencyRateOperationsInternal.CopyCurrencyRates");
	JobParameters.Insert("Parameters", MethodParameters);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	SetPrivilegedMode(True);
	ModuleJobsQueue.AddJob(JobParameters);

EndProcedure

// Called after loading data to the area or when changing the way the currency exchange rate is set.
// Copies the exchange rates of a single currency for all dates from 
// an undivided xml file to a case-separated format.
// 
// Parameters:
//  CurrencyCode_ - String
//
Procedure CopyCurrencyRates(Val CurrencyCode_) Export
	
	If Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	CurrencyRef = Catalogs.Currencies.FindByCode(CurrencyCode_);
	If CurrencyRef.IsEmpty() Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Currency with code %1 is not found in the catalog. Exchange rate import is canceled.';"), CurrencyCode_);
		WriteLogEvent(NStr("en = 'Default master data.Distribute exchange rates to data areas';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorText);
		Return;
	EndIf;
	
	Filter = New Array;
	Filter.Add(New Structure("Code, Value", "Currency", CurrencyCode_));
	ExRates = ModuleSuppliedData.ReferencesSuppliedDataFromCache("OneCurrencyRates", Filter);
	If ExRates.Count() = 0 Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'There are no exchange rates for the currency with code %1 in the default master data.';"), CurrencyCode_);
		WriteLogEvent(NStr("en = 'Default master data.Distribute exchange rates to data areas';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorText);
		Return;
	EndIf;
	
	PathToFile = GetTempFileName();
	ModuleSuppliedData.SuppliedDataFromCache(ExRates[0]).Write(PathToFile);
	RateTable = ReadRateTable(PathToFile, True);
	DeleteFiles(PathToFile);
	
	RateTable.Columns.Date.Name = "Period";
	RateTable.Columns.Add("Currency");
	RateTable.FillValues(CurrencyRef, "Currency");
	
	BeginTransaction();
	Try
		InformationRegisters.ExchangeRates.SetTotalsUsing(False);
		
		RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
		RecordSet.Filter.Currency.Set(CurrencyRef);
		RecordSet.Load(RateTable);
		RecordSet.DataExchange.Load = True;
		
		RecordSet.Write();
		
		InformationRegisters.ExchangeRates.SetTotalsUsing(True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	InformationRegisters.ExchangeRates.RecalcTotals();
	
	// 
	CurrencyRateOperations.CheckCurrencyRateAvailabilityFor01011980(CurrencyRef);

EndProcedure

// Called after loading data into the area.
// Updates currency rates from the supplied data.
//
Procedure UpdateCurrencyRates() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Currencies.Code
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)";
	Selection = Query.Execute().Select();
	
	// 
	//  
	// 
	// 
	While Selection.Next() Do
		CopyCurrencyRates(Selection.Code);
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Called when a notification of new data is received.
// In the body, check whether the application needs this data, 
// and if so, select the Upload checkbox.
// 
// Parameters:
//   Descriptor - XDTODataObject -  descriptor.
//   ToImport - Boolean -  True if loaded, False otherwise.
//
Procedure NewDataAvailable(Val Descriptor, ToImport) Export
	
	// 
	// 
	// 
	//
	If Descriptor.DataType = "CurrencyRatesForDay" Then
		ToImport = True;
	//  
	//  
	// 
	// 
	// 
	ElsIf Descriptor.DataType = "ExchangeRates" Then
		ToImport = True;
	EndIf;
	
EndProcedure

// Called after calling available Data, allows you to parse the data.
//
// Parameters:
//   Descriptor - XDTODataObject -  descriptor.
//   PathToFile - String -  full name of the extracted file. The file will be automatically deleted 
//                  after the procedure is completed. If the
//                  file was not specified in the service Manager, the argument value is Undefined.
//
Procedure ProcessNewData(Val Descriptor, Val PathToFile) Export
	
	If Descriptor.DataType = "CurrencyRatesForDay" Then
		HandleSuppliedRatesPerDay(Descriptor, PathToFile);
	ElsIf Descriptor.DataType = "ExchangeRates" Then
		HandleSuppliedRates(Descriptor, PathToFile);
	EndIf;
	
EndProcedure

// Called when data processing is canceled in the event of a failure.
//
// Parameters:
//   Descriptor - XDTODataObject -  descriptor.
//
Procedure DataProcessingCanceled(Val Descriptor) Export 
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		ModuleSuppliedData = Common.CommonModule("SuppliedData");
		ModuleSuppliedData.AreaProcessed(Descriptor.FileGUID, "CurrencyRatesForDay", Undefined);
	EndIf;
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("CurrencyRateOperationsInternal.CopyCurrencyRates");
	NamesAndAliasesMap.Insert("CurrencyRateOperationsInternal.UpdateCurrencyRates");
	
EndProcedure

// See SuppliedDataOverridable.GetHandlersForSuppliedData.
Procedure OnDefineSuppliedDataHandlers(Handlers) Export
	
	RegisterSuppliedDataHandlers(Handlers);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	If Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		// 
		UpdateCurrencyRates();
	EndIf;
	
EndProcedure

Function HasRightToChangeExchangeRates() Export
	
	Return AccessRight("Update", Metadata.InformationRegisters.ExchangeRates);
	
EndFunction

#EndRegion

#Region Private

// Registers handlers of delivered data for the day and for the entire time.
//
// Parameters:
//     Handlers - ValueTable - :
//       * DataKind - String -  code of the data type processed by the handler.
//       * HandlerCode - String -  it will be used when restoring data processing after a failure.
//       * Handler - CommonModule - :
//                                            
//                                          
//                                          
//
Procedure RegisterSuppliedDataHandlers(Val Handlers)
	
	Handler = Handlers.Add();
	Handler.DataKind = "CurrencyRatesForDay";
	Handler.HandlerCode = "CurrencyRatesForDay";
	Handler.Handler = CurrencyRateOperationsInternal;
	
	Handler = Handlers.Add();
	Handler.DataKind = "ExchangeRates";
	Handler.HandlerCode = "ExchangeRates";
	Handler.Handler = CurrencyRateOperationsInternal;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Writes a file in the format of the delivered data.
//
// Parameters:
//  RateTable - ValueTable -  with the Code, date, Multiplicity, and Course columns.
//  File - 
//
Procedure SaveRateTable(Val RateTable, Val File)
	
	If TypeOf(File) = Type("String") Then
		TextWriter = New TextWriter(File);
	Else
		TextWriter = File;
	EndIf;
	
	For Each TableRow In RateTable Do
			
		XMLRate = StrReplace(
		StrReplace(
		StrReplace(
			StrReplace("<Rate Code=""%1"" Date=""%2"" Factor=""%3"" Rate=""%4""/>", 
			"%1", TableRow.Code),
			"%2", Left(XDTOSerializer.XMLString(TableRow.Date), 10)),
			"%3", XDTOSerializer.XMLString(TableRow.Repetition)),
			"%4", XDTOSerializer.XMLString(TableRow.Rate));
		
		TextWriter.WriteLine(XMLRate);
	EndDo; 
	
	If TypeOf(File) = Type("String") Then
		TextWriter.Close();
	EndIf;
	
EndProcedure

// Reads the file in the supplied data format.
//
// Parameters:
//  PathToFile - String -  file name.
//  SearchDuplicate - Boolean -  collapses records with the same date.
//
// Returned value
//  Table of values - with columns Code, date, Multiplicity, Rate.
//
Function ReadRateTable(Val PathToFile, Val SearchDuplicate = False)
	
	RateDataType = XDTOFactory.Type("http://www.1c.ru/SaaS/SuppliedData/CurrencyRates", "Rate");
	RateTable = New ValueTable();
	RateTable.Columns.Add("Code", New TypeDescription("String", , New StringQualifiers(200)));
	RateTable.Columns.Add("Date", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	RateTable.Columns.Add("Repetition", New TypeDescription("Number", New NumberQualifiers(9, 0)));
	RateTable.Columns.Add("Rate", New TypeDescription("Number", New NumberQualifiers(20, 4)));
	
	Read = New TextReader(PathToFile);
	CurrentRow = Read.ReadLine();
	While CurrentRow <> Undefined Do
		
		XMLReader = New XMLReader();
		XMLReader.SetString(CurrentRow);
		Rate = XDTOFactory.ReadXML(XMLReader, RateDataType);
		
		If SearchDuplicate Then
			For Each Duplicate In RateTable.FindRows(New Structure("Date", Rate.Date)) Do
				RateTable.Delete(Duplicate);
			EndDo;
		EndIf;
		
		WriteCurrencyRate = RateTable.Add();
		WriteCurrencyRate.Code    = Rate.Code;
		WriteCurrencyRate.Date    = Rate.Date;
		WriteCurrencyRate.Repetition = Rate.Factor;
		WriteCurrencyRate.Rate      = Rate.Rate;

		CurrentRow = Read.ReadLine();
	EndDo;
	Read.Close();
	
	RateTable.Indexes.Add("Code");
	RateTable.Sort("Date Desc");
	
	Return RateTable;
		
EndFunction

// Called when data of the "currency exchange Rate" type is received.
//
// Parameters:
//   Descriptor   - 
//   PathToFile   - String -  full name of the extracted file.
//
Procedure HandleSuppliedRates(Val Descriptor, Val PathToFile)
	
	If Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	RateTable = ReadRateTable(PathToFile);
	
	// 
	CodeTable = RateTable.Copy( , "Code");
	CodeTable.GroupBy("Code");
	For Each CodeString In CodeTable Do
		
		TempFileName = GetTempFileName();
		SaveRateTable(RateTable.FindRows(New Structure("Code", CodeString.Code)), TempFileName);
		
		CacheDescriptor = New Structure;
		CacheDescriptor.Insert("DataKind", "OneCurrencyRates");
		CacheDescriptor.Insert("AddedOn", CurrentUniversalDate());
		CacheDescriptor.Insert("FileID", New UUID);
		CacheDescriptor.Insert("Characteristics", New Array);
		
		CacheDescriptor.Characteristics.Add(New Structure("Code, Value, KeyStructure", "Currency", CodeString.Code, True));
		
		ModuleSuppliedData.SaveSuppliedDataToCache(CacheDescriptor, TempFileName);
		DeleteFiles(TempFileName);
		
	EndDo;
	
	AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(
		Descriptor.FileGUID, "ExchangeRates");
	
	DistributeRatesByDataAreas(Undefined, RateTable, AreasForUpdate, 
		Descriptor.FileGUID, "ExchangeRates");

EndProcedure

// Called after receiving new data of the form Kursyvalyutzaden.
//
// Parameters:
//   Descriptor   - 
//   PathToFile   - String -  full name of the extracted file.
//
Procedure HandleSuppliedRatesPerDay(Val Descriptor, Val PathToFile)
	
	If Not Common.SubsystemExists("CloudTechnology.SuppliedData") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	
	RateTable = ReadRateTable(PathToFile);
	
	RatesDate = "";
	For Each Characteristic In Descriptor.Properties.Property Do
		If Characteristic.Code = "Date" Then
			RatesDate = Date(Characteristic.Value); 		
		EndIf;
	EndDo; 
	
	If RatesDate = "" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Data of type ""%1"" does not contain characteristics ""%2"". Cannot update exchange rates.';"),
			"CurrencyRatesForDay", "Date");
	EndIf;
	
	AreasForUpdate = ModuleSuppliedData.AreasRequiringProcessing(Descriptor.FileGUID, "CurrencyRatesForDay", True);
	
	CommonRateIndex = AreasForUpdate.Find(-1);
	If CommonRateIndex <> Undefined Then
		
		RateCache = ModuleSuppliedData.DescriptorsOfSuppliedDataFromCache("OneCurrencyRates", , False);
		If RateCache.Count() > 0 Then
			For Each RateString In RateTable Do
				
				CurrentCache = Undefined;
				For	Each CacheDescriptor In RateCache Do
					If CacheDescriptor.Characteristics.Count() > 0 
						And CacheDescriptor.Characteristics[0].Code = "Currency"
						And CacheDescriptor.Characteristics[0].Value = RateString.Code Then
						CurrentCache = CacheDescriptor;
						Break;
					EndIf;
				EndDo;
				
				TempFileName = GetTempFileName();
				If CurrentCache <> Undefined Then
					Data = ModuleSuppliedData.SuppliedDataFromCache(CurrentCache.FileID);
					Data.Write(TempFileName);
				Else
					CurrentCache = New Structure;
					CurrentCache.Insert("DataKind", "OneCurrencyRates");
					CurrentCache.Insert("AddedOn", CurrentUniversalDate());
					CurrentCache.Insert("FileID", New UUID);
					CurrentCache.Insert("Characteristics", New Array);
					
					CurrentCache.Characteristics.Add(New Structure("Code, Value, KeyStructure", "Currency", RateString.Code, True));
				EndIf;
				
				TextWriter = New TextWriter(TempFileName, TextEncoding.UTF8, 
				Chars.LF, True);
				
				TableToWrite = New Array;
				TableToWrite.Add(RateString);
				SaveRateTable(TableToWrite, TextWriter);
				TextWriter.Close();
				
				ModuleSuppliedData.SaveSuppliedDataToCache(CurrentCache, TempFileName);
				DeleteFiles(TempFileName);
			EndDo;
			
		EndIf;
		
		AreasForUpdate.Delete(CommonRateIndex);
	EndIf;
	
	DistributeRatesByDataAreas(RatesDate, RateTable, AreasForUpdate, 
		Descriptor.FileGUID, "CurrencyRatesForDay");

EndProcedure

// Copies courses to all ODS
//
// Parameters:
//  RatesDate - Date, Undefined -  courses are added for the specified date or for the entire time.
//  RateTable - 
//  AreasForUpdate - 
//  FileID - 
//  HandlerCode - String -   the handler code.
//
Procedure DistributeRatesByDataAreas(Val RatesDate, Val RateTable, Val AreasForUpdate, Val FileID, Val HandlerCode)
	
	If Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return;
	EndIf;
	
	ModuleSuppliedData = Common.CommonModule("SuppliedData");
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	
	AreaCurrencies = New Map();
	
	CommonQuery = New Query();
	CommonQuery.TempTablesManager = New TempTablesManager;
	CommonQuery.SetParameter("SuppliedRates", RateTable);
	CommonQuery.SetParameter("OneDayOnly", RatesDate <> Undefined);
	CommonQuery.SetParameter("RatesDate", RatesDate);
	CommonQuery.SetParameter("RateDeliveryStart", Date("19800101"));
	
	For Each DataArea In AreasForUpdate Do
		
		Try
			ModuleSaaSOperations.SignInToDataArea(DataArea);
		Except
			ModuleSaaSOperations.SignOutOfDataArea();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Couldn''t set session separation for %1. Reason:
				|%2';", Common.DefaultLanguageCode()),
				Format(DataArea, "NZ=0; NG=0"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(NStr("en = 'Default master data.Distribute exchange rates to data areas';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorText);
				
			ScheduleExchangeRatesUpdate(DataArea);
			Continue;
			
		EndTry;
		
		AreaCurrenciesString = Common.ValueToXMLString(AreaCurrencies);
		
		BeginTransaction();
		Try
			// 
			ProcessTransactionedAreaRates(CommonQuery, AreaCurrencies, RateTable);
			ModuleSaaSOperations.SignOutOfDataArea();
			ModuleSuppliedData.AreaProcessed(FileID, HandlerCode, DataArea);

			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			AreaCurrencies = Common.ValueFromXMLString(AreaCurrenciesString);
			ModuleSaaSOperations.SignOutOfDataArea();
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Cannot update the exchange rates in data area ""%1"". Reason:
				|%2';", Common.DefaultLanguageCode()),
				Format(DataArea, "NZ=0; NG=0"),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(NStr("en = 'Default master data.Distribute exchange rates to data areas';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorText);
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure ScheduleExchangeRatesUpdate(DataArea)

	If Not Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		Return;
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("MethodName", "CurrencyRateOperationsInternal.UpdateCurrencyRates");
	JobParameters.Insert("DataArea", DataArea);
	
	ModuleJobsQueue = Common.CommonModule("JobsQueue");
	
	SetPrivilegedMode(True);
	ModuleJobsQueue.AddJob(JobParameters);

EndProcedure

Function SuppliedCurrencyProperties(AreaCurrencies, CurrencyCode_, RateTable, CommonQuery)
	
	CurrencyProperties = AreaCurrencies.Get(CurrencyCode_);
	
	If CurrencyProperties <> Undefined Then 
		
		Return CurrencyProperties;
		
	EndIf;
	
	SuppliedRates = RateTable.Copy(New Structure("Code", CurrencyCode_));
	
	CurrencyProperties = New Structure("Supplied_3, SequenceNumber", False, Undefined);
	
	If SuppliedRates.Count() = 0 Then
		
		AreaCurrencies.Insert(CurrencyCode_, CurrencyProperties);
		Return CurrencyProperties;
		
	EndIf;
	
	SequenceNumber = Format(CommonQuery.TempTablesManager.Tables.Count() + 1, "NZ=0; NG=0");
	
	QueryText = 
	"SELECT
	|	SuppliedRates.Date AS Date,
	|	SuppliedRates.Repetition AS Repetition,
	|	SuppliedRates.Rate AS Rate
	|INTO CurrencyRatesNNN
	|FROM
	|	&SuppliedRates AS SuppliedRates
	|WHERE
	|	SuppliedRates.Code = &CurrencyCode_
	|	AND SuppliedRates.Date > &RateDeliveryStart
	|	AND CASE
	|			WHEN &OneDayOnly
	|				THEN SuppliedRates.Date = &RatesDate
	|			ELSE TRUE
	|		END";
	
	CommonQuery.Text = StrReplace(QueryText, "NNN", SequenceNumber);
	CommonQuery.Execute();
	
	CurrencyProperties.Supplied_3 = True;
	CurrencyProperties.SequenceNumber = SequenceNumber;
	
	AreaCurrencies.Insert(CurrencyCode_, CurrencyProperties);
	
	Return CurrencyProperties;
	
EndFunction

Procedure ProcessTransactionedAreaRates(CommonQuery, AreaCurrencies, RateTable)
	
	CurrencyQuery = New Query;
	CurrencyQuery.Text = 
	"SELECT
	|	Currencies.Ref,
	|	Currencies.Code
	|FROM
	|	Catalog.Currencies AS Currencies
	|WHERE
	|	Currencies.RateSource = VALUE(Enum.RateSources.DownloadFromInternet)";
	
	CurrencySelection1 = CurrencyQuery.Execute().Select(); // 
	
	While CurrencySelection1.Next() Do
		
		CommonQuery.SetParameter("Currency", CurrencySelection1.Ref);
		CommonQuery.SetParameter("CurrencyCode_", CurrencySelection1.Code);
		
		// 
		CurrencyProperties = SuppliedCurrencyProperties(AreaCurrencies, CurrencySelection1.Code, RateTable, CommonQuery);
		
		If Not CurrencyProperties.Supplied_3 Then
			Continue;
		EndIf;
		
		QueryText = 
		"SELECT
		|	Comparison.Date AS Date,
		|	Comparison.Repetition AS Repetition,
		|	Comparison.Rate AS Rate,
		|	MAX(Comparison.InFile) AS InFile,
		|	MAX(Comparison.InData) AS InData
		|FROM
		|	(SELECT
		|		SuppliedRates.Date AS Date,
		|		SuppliedRates.Repetition AS Repetition,
		|		SuppliedRates.Rate AS Rate,
		|		1 AS InFile,
		|		0 AS InData
		|	FROM
		|		CurrencyRatesNNN AS SuppliedRates
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ExchangeRates.Period,
		|		ExchangeRates.Repetition,
		|		ExchangeRates.Rate,
		|		0,
		|		1
		|	FROM
		|		InformationRegister.ExchangeRates AS ExchangeRates
		|	WHERE
		|		ExchangeRates.Currency = &Currency
		|		AND ExchangeRates.Period > &RateDeliveryStart
		|		AND CASE
		|				WHEN &OneDayOnly
		|					THEN ExchangeRates.Period = &RatesDate
		|				ELSE TRUE
		|			END) AS Comparison
		|
		|GROUP BY
		|	Comparison.Date,
		|	Comparison.Repetition,
		|	Comparison.Rate
		|
		|HAVING
		|	MAX(Comparison.InFile) <> MAX(Comparison.InData)
		|
		|ORDER BY
		|	Date DESC,
		|	InData";
		
		CommonQuery.Text = StrReplace(QueryText, "NNN", CurrencyProperties.SequenceNumber);
		
		// 
		CommonResult1 = CommonQuery.Execute();
		CommonSelection = CommonResult1.Select();
		
		CurDate = Undefined;
		FirstIterationByDate = True;
		
		While CommonSelection.Next() Do
			
			If CurDate <> CommonSelection.Date Then
				FirstIterationByDate = True;
				CurDate = CommonSelection.Date;
			EndIf;
			
			If Not FirstIterationByDate Then
				Continue;
			EndIf;
			
			FirstIterationByDate = False;
			
			RecordSet = InformationRegisters.ExchangeRates.CreateRecordSet();
			RecordSet.Filter.Currency.Set(CurrencySelection1.Ref);
			RecordSet.Filter.Period.Set(CommonSelection.Date);
			If Not CommonQuery.Parameters.OneDayOnly Then
				// 
				RecordSet.DataExchange.Load = True;
			EndIf;
			
			If CommonSelection.InFile = 1 Then
				
				Record = RecordSet.Add();
				Record.Currency = CurrencySelection1.Ref;
				Record.Period = CommonSelection.Date;
				Record.Repetition = CommonSelection.Repetition;
				Record.Rate = CommonSelection.Rate;
				
			EndIf;
			
			// 
			
			Write = True;
			If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
				ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
				Write = Not ModulePeriodClosingDates.DataChangesDenied(RecordSet);
			EndIf;
			
			If Write Then
				RecordSet.Write();
			Else
				Comment = NStr("en = 'The %1 exchange rate import as of %2 is canceled due to a period-end closing date violation.';"); 
				Comment = StringFunctionsClientServer.SubstituteParametersToString(Comment, CurrencySelection1.Code, CommonSelection.Date);
				EventName = NStr("en = 'Default master data.Cancel exchange rates import';", Common.DefaultLanguageCode());
				WriteLogEvent(EventName, EventLogLevel.Information,, CurrencySelection1.Ref, Comment);
				Break;
			EndIf;
			
		EndDo;
		
		// 
		CurrencyRateOperations.CheckCurrencyRateAvailabilityFor01011980(CurrencySelection1.Ref);
		
	EndDo;
	
EndProcedure

Function WritingInWordsInputForms() Export
	
	CollectionsOfForms = New Array;
	CollectionsOfForms.Add(Metadata.CommonForms);
	CollectionsOfForms.Add(Metadata.Catalogs.Currencies.Forms);
	If Metadata.DataProcessors.Find("CurrenciesRatesImport") <> Undefined Then
		CollectionsOfForms.Add(Metadata.DataProcessors["CurrenciesRatesImport"].Forms);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport.Print") Then
		PrintManagementModuleNationalLanguageSupport = Common.CommonModule("PrintManagementNationalLanguageSupport");
		ValidLanguageCodes = PrintManagementModuleNationalLanguageSupport.AvailableLanguages();
	Else
		ValidLanguageCodes = StandardSubsystemsServer.ConfigurationLanguages();
	EndIf;
	
	FoundForms = New Map;
	For Each LanguageCode In ValidLanguageCodes Do
		FoundForms.Insert(LanguageCode, "");
	EndDo;
	
	Result = New ValueList;
	
	For Each FormsCollection In CollectionsOfForms Do
		For Each Form In FormsCollection Do
			NameParts = StrSplit(Form.Name, "_", True);
			Suffix = NameParts[NameParts.UBound()];
			If FoundForms[Suffix] <> Undefined Then
				FoundForms[Suffix] = Form.FullName();
			EndIf;
		EndDo;
	EndDo;
	
	AddTheCurrencyRegistrationParametersFormInOtherLanguages = False;
	
	For Each LanguageCode In ValidLanguageCodes Do
		If ValueIsFilled(FoundForms[LanguageCode]) Then
			Result.Add(LanguageCode, FoundForms[LanguageCode]);
		Else
			AddTheCurrencyRegistrationParametersFormInOtherLanguages = True;
		EndIf;
	EndDo;
	
	If AddTheCurrencyRegistrationParametersFormInOtherLanguages Then
		Result.Add("", "CurrencyInWordsInOtherLanguagesParameters");
	EndIf;
	
	Return Result;
	
EndFunction

Function LanguagePresentation(LanguageCode) Export
	
	Presentation = LocaleCodePresentation(LanguageCode);
	StringParts1 = StrSplit(Presentation, " ", True);
	StringParts1[0] = Title(StringParts1[0]);
	Presentation = StrConcat(StringParts1, " ");
	
	Return Presentation;
	
EndFunction

#EndRegion
