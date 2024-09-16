///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Checks whether data modification is prohibited when the user interactively edits 
// or when programmatically loading data from the exchange plan node of the nodelproverkisapretasload Node.
//
// Parameters:
//  DataOrFullName  - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - 
//                      - String - 
//                                 
//                                 
//                                 
//
//  DataID - CatalogRef
//                      - DocumentRef
//                      - ChartOfCharacteristicTypesRef
//                      - ChartOfAccountsRef
//                      - ChartOfCalculationTypesRef
//                      - BusinessProcessRef
//                      - TaskRef
//                      - ExchangePlanRef
//                      - Filter - 
//                                
//                      - Undefined -   
//                                       
//
//  ErrorDescription    - Null      -  the default value. Information about prohibitions is not required.
//                    - String    - 
//                    - Structure - 
//                                  
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef -  
//                                
//
// Returns:
//  Boolean - 
//
// Call options:
//   Changesnot allowed (reference Object...) - check the data in the passed object (set of records).
//   Changesnot allowed(String, reference Link...) - check the data received from the database 
//      by the full name of the metadata object and the link (selection of a set of records).
//   Changesnot allowed(reference Object..., reference link...) - check both 
//      the data in the passed object and the data in the database (i.e. "before" and "after" writing to the database, if the check is performed
//      before writing the object).
//
Function DataChangesDenied(DataOrFullName, DataID = Undefined,
	ErrorDescription = Null, ImportRestrictionCheckNode = Undefined) Export
	
	If TypeOf(DataOrFullName) = Type("String") Then
		MetadataObject = Common.MetadataObjectByFullName(DataOrFullName);
	Else
		MetadataObject = DataOrFullName.Metadata();
	EndIf;
	
	DataSources = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
	If DataSources.Get(MetadataObject.FullName()) = Undefined Then
		Return False; // 
	EndIf;
	
	PeriodClosingCheck = ImportRestrictionCheckNode = Undefined;
	
	If TypeOf(DataOrFullName) = Type("String") Then
		If TypeOf(DataID) = Type("Filter") Then
			DataManager = Common.ObjectManagerByFullName(DataOrFullName);
			Source = DataManager.CreateRecordSet();
			For Each FilterElement In DataID Do
				Source.Filter[FilterElement.Name].Set(FilterElement.Value, FilterElement.Use);
			EndDo;
			Source.Read();
		ElsIf Not ValueIsFilled(DataID) Then
			Return False;
		Else
			Source = DataID.GetObject();
		EndIf;
		
		If PeriodClosingDatesInternal.SkipClosingDatesCheck(Source,
				PeriodClosingCheck, ImportRestrictionCheckNode, "") Then
			Return False;
		EndIf;
		
		Return PeriodClosingDatesInternal.DataChangesDenied(DataOrFullName,
			DataID, ErrorDescription, ImportRestrictionCheckNode);
	EndIf;
	
	ObjectVersion = "";
	If PeriodClosingDatesInternal.SkipClosingDatesCheck(DataOrFullName,
			 PeriodClosingCheck, ImportRestrictionCheckNode, ObjectVersion) Then
		Return False;
	EndIf;
	
	Source      = DataOrFullName;
	Id = DataID;
	
	If ObjectVersion = "OldVersion" Then
		Source = MetadataObject.FullName();
		
	ElsIf ObjectVersion = "NewVersion" Then
		Id = Undefined;
	EndIf;
	
	Return PeriodClosingDatesInternal.DataChangesDenied(Source,
		Id, ErrorDescription, ImportRestrictionCheckNode);
	
EndFunction

// Checks whether the object or set of Data records is not allowed to load.
// This checks the old and new versions of the data. 
//
// Parameters:
//  Data              - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - ObjectDeletion
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - 
//
//  ImportRestrictionCheckNode  - ExchangePlanRef -  the node for which you want to check.
//
//  Cancel               - Boolean -  returned parameter: True if loading is prohibited.
//
//  ErrorDescription      - Null      -  the default value. Information about prohibitions is not required.
//                      - String    - 
//                      - Structure - 
//                                    
//
Procedure CheckDataImportRestrictionDates(Data, ImportRestrictionCheckNode, Cancel, ErrorDescription = Null) Export
	
	If TypeOf(Data) = Type("ObjectDeletion") Then
		MetadataObject = Data.Ref.Metadata();
	Else
		MetadataObject = Data.Metadata();
	EndIf;
	
	DataSources = PeriodClosingDatesInternal.DataSourcesForPeriodClosingCheck();
	If DataSources.Get(MetadataObject.FullName()) = Undefined Then
		Return; // 
	EndIf;
	
	AdditionalParameters = PeriodClosingDatesInternal.PeriodEndClosingDatesCheckParameters();
	AdditionalParameters.ImportRestrictionCheckNode = ImportRestrictionCheckNode;
	AdditionalParameters.ErrorDescription = ErrorDescription;
	IsRegister = Common.IsRegister(MetadataObject);
	
	Result = PeriodClosingDatesInternal.CheckDataImportRestrictionDates1(Data,
		IsRegister, IsRegister, TypeOf(Data) = Type("ObjectDeletion"), AdditionalParameters);
	
	ErrorDescription = Result.ErrorDescription;
	If Result.DataChangesDenied Then
		Cancel = True;
	EndIf;
		
EndProcedure

// Event handler for the account form in the Server, which is embedded in the forms of reference items,
// documents, register entries, etc.to block the form if the change is prohibited.
//
// Parameters:
//  Form               - ClientApplicationForm -  form of an object element or register entry.
//
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - InformationRegisterRecordManager - 
//
// Returns:
//  Boolean - 
//
Function ObjectOnReadAtServer(Form, CurrentObject) Export
	
	MetadataObject = Metadata.FindByType(TypeOf(CurrentObject));
	FullName = MetadataObject.FullName();
	
	EffectiveDates = PeriodClosingDatesInternal.EffectiveClosingDates();
	DataSources = EffectiveDates.DataSources.Get(FullName);
	If DataSources = Undefined Then
		Return False;
	EndIf;
	
	If Common.IsRegister(MetadataObject) Then
		// 
		DataManager = Common.ObjectManagerByFullName(FullName);
		Source = DataManager.CreateRecordSet();
		For Each FilterElement In Source.Filter Do
			FilterElement.Set(CurrentObject[FilterElement.Name], True);
		EndDo;
		FillPropertyValues(Source.Add(), CurrentObject);
	Else
		Source = CurrentObject;
	EndIf;
	
	If PeriodClosingDatesInternal.SkipClosingDatesCheck(Source,
			True, Undefined, "") Then
		Return True;
	EndIf;
	
	If DataChangesDenied(Source) Then
		Form.ReadOnly = True;
	EndIf;
	
	Return False;
	
EndFunction

// Adds a data source description string to check whether changes are not allowed.
// Used in the procedure to
// fill in the data source for checking the change Order of the General module of the change order Datesdeterminable.
// 
// Parameters:
//  Data      - ValueTable -  passed to the procedure to fill in the data source for checking the change Request.
//  Table     - String -  the full name of the metadata object, such as " Document.Prikhodnayanakladnaya".
//  DateField    - String -  name of the object's or table part's details, for example: "Date", " Products.Upload date".
//  Section      - String -  the name of a predefined item Provideopportunities.Rostelecomgarantiya.
//  ObjectField - String -  name of the item's or table part's details, for example: "Company", " Products.Warehouse".
//
Procedure AddRow(Data, Table, DateField, Section = "", ObjectField = "") Export
	
	NewRow = Data.Add();
	NewRow.Table     = Table;
	NewRow.DateField    = DateField;
	NewRow.Section      = Section;
	NewRow.ObjectField = ObjectField;
	
EndProcedure

// Find the ban dates based on the data being checked for the specified user or exchange plan node.
//
// Parameters:
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate
//
//  PeriodEndMessageParameters - See PeriodClosingDates.PeriodEndMessageParameters
//                             - Undefined - you don't need to generate the text of the ban message.
//
//  ErrorDescription    - Null      -  the default value. Information about prohibitions is not required.
//                    - String    - 
//                    - Structure - :
//                        * DataPresentation - String -  the data representation used in the error header.
//                        * ErrorTitle     - String - :
//                                                
//                        * PeriodEnds - ValueTable - :
//                          ** Date            - Date         -  the date to check.
//                          ** Section          - String       -  name of the section that was searched for bans. if
//                                                 the string is empty, it means that the date that is valid for all sections was searched.
//                          ** Object          - AnyRef  -  link to the object that was used to search for the ban date.
//                                             - Undefined - 
//                          ** PeriodEndClosingDate     - Date         -  found the date of the ban.
//                          ** SingleDate       - Boolean       -  if True, it means that the ban date found is valid for
//                                                 all sections, not just for the section that was searched.
//                          ** ForAllObjects - Boolean       -  if True, it means that the ban date found is valid for
//                                                 all objects, not just for the object that was searched for.
//                          ** Addressee         - DefinedType.PeriodClosingTarget -  the user or node
//                                                 of the exchange plan that the found ban date is set for.
//                          ** LongDesc        - String - :
//                            
//                            
//
//  ImportRestrictionCheckNode - Undefined -  perform a data change check.
//                              - ExchangePlanRef - 
//
// Returns:
//  Boolean - 
//
Function PeriodEndClosingFound(Val DataToCheck,
                                    PeriodEndMessageParameters = Undefined,
                                    ErrorDescription = Null,
                                    ImportRestrictionCheckNode = Undefined) Export
	
	If PeriodClosingDatesInternal.PeriodEndClosingDatesCheckDisabled(
			ImportRestrictionCheckNode = Undefined, ImportRestrictionCheckNode) Then
		Return False;
	EndIf;
	
	Return PeriodClosingDatesInternal.PeriodEndClosingFound(DataToCheck,
		PeriodEndMessageParameters, ErrorDescription, ImportRestrictionCheckNode);
	
EndFunction

// Returns the parameters for creating a message on the prohibition of recording or uploading data. 
// For use in the date-change function.Nagasubramanian.
//
// Returns:
//   Structure:
//    * NewVersion - Boolean -  if True, the ban message must
//                    be generated for the new version, otherwise for the old version.
//    * Data - AnyRef
//             - CatalogObject
//             - DocumentObject
//             - InformationRegisterRecordSet
//             - AccumulationRegisterRecordSet
//             - AccountingRegisterRecordSet 
//             - CalculationRegisterRecordSet - 
//                  
//             - Structure:
//                 ** Register - String -  full name of the register.
//                            - InformationRegisterRecordSet
//                            - AccumulationRegisterRecordSet
//                            - AccountingRegisterRecordSet 
//                            - CalculationRegisterRecordSet - 
//                 ** Filter   - Filter -  selecting a set of records.
//             - String - 
//                        
//				 
Function PeriodEndMessageParameters() Export
	
	Result = New Structure;
	Result.Insert("Data", "");
	Result.Insert("NewVersion", False);
	Return Result;
	
EndFunction	

// Returns a new table of values with the date, Section, and Object columns
// to fill in and then pass to the Datesreference function.Nagasubramanian.
//
// Returns:
//  ValueTable:
//   * Date   - Date   -  a date without a time to check if it belongs to the established prohibitions.
//   * Section - String -  one of the section names specified in the procedure
//                       Datesrecognizationdeterminable.When fillingdelegationsreferencesexternal links
//   * Object - AnyRef -  one of the object types specified for the section in the procedure 
//                       Datesrecognizationdeterminable.When filling in the dividesdatesreferences.
//
Function DataToCheckTemplate() Export
	
	DataToCheck = New ValueTable;
	
	DataToCheck.Columns.Add(
		"Date", New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date)));
	
	DataToCheck.Columns.Add(
		"Section", New TypeDescription("String,ChartOfCharacteristicTypesRef.PeriodClosingDatesSections"));
	
	DataToCheck.Columns.Add(
		"Object", Metadata.ChartsOfCharacteristicTypes.PeriodClosingDatesSections.Type);
	
	Return DataToCheck;
	
EndFunction

// In the current session, disables and enables checking the dates when data changes and uploads are not allowed.
// It is required to implement special logic and speed up batch data processing
// when writing an object or a set of records when the flag is Broken.Download is not installed.
// 
// Full rights or privileged mode are required for use.
//
// Recommended:
// - bulk loading of data from a file (if the data does not fall within the prohibited period);
// - mass loading of data during data exchange (if the data does not fall within the prohibited period);
// - if you want to disable checking the ban dates for more than one object,
//   by inserting the skip check of the ban Changes property in the Additional properties of the object,
//   but for all objects that will be recorded within the record of this object.
//
// Parameters:
//  Disconnect - Boolean -  True-disables checking the dates when data changes and uploads are not allowed.
//                       False-enables checking the dates when data changes and uploads are not allowed.
//
// Example:
//
//  
//
//	
//	
//	
//		
//		
//	
//		
//		
//		
//	
//	
//
//  
//
//	
//	
//	
//	
//		
//		
//		
//		
//		
//	
//		
//		
//		
//		
//	
//	
//
Procedure DisablePeriodEndClosingDatesCheck(Disconnect) Export
	
	SessionParameters.SkipPeriodClosingCheck = Disconnect;
	
EndProcedure

// Returns the status of disabling ban dates performed
// by the disable checkdate of a Secret procedure.
//
// Returns:
//  Boolean
//
Function PeriodEndClosingDatesCheckDisabled() Export
	
	SetPrivilegedMode(True);
	PeriodEndClosingDatesCheckDisabled = SessionParameters.SkipPeriodClosingCheck;
	SetPrivilegedMode(False);
	
	Return PeriodEndClosingDatesCheckDisabled;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Handler for subscribing to the pre-Recording event to check whether changes are forbidden.
//
// Parameters:
//  Source   - CatalogObject
//             - ChartOfCharacteristicTypesObject
//             - ChartOfAccountsObject
//             - ChartOfCalculationTypesObject
//             - BusinessProcessObject
//             - TaskObject
//             - ExchangePlanObject -  a data object that is passed to the pre-Recording event subscription.
//
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel);
	
EndProcedure

// Handler for subscribing to the pre-Recording event to check whether changes are forbidden.
//
// Parameters:
//  Source        - DocumentObject -  a data object that is passed to the pre-Recording event subscription.
//  Cancel           - Boolean -  parameter passed to the event subscription before Recording.
//  WriteMode     - Boolean -  parameter passed to the event subscription before Recording.
//  PostingMode - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeWriteDocument(Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	Source.AdditionalProperties.Insert("WriteMode", WriteMode);
	
	CheckPeriodClosingDates(Source, Cancel);
	
EndProcedure

// Handler for subscribing to the pre-Recording event to check whether changes are forbidden.
//
// Parameters:
//  Source   - InformationRegisterRecordSet
//             - AccumulationRegisterRecordSet - 
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//  Replacing  - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeWriteRecordSet(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel, True, Replacing);
	
EndProcedure

// Handler for subscribing to the pre-Recording event to check whether changes are forbidden.
//
// Parameters:
//  Source    - AccountingRegisterRecordSet -  a set of records that is passed
//                to the pre-Recording event subscription.
//  Cancel       - Boolean -  parameter passed to the event subscription before Recording.
//  WriteMode - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeWriteAccountingRegisterRecordSet(
		Source, Cancel, WriteMode) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel, True);
	
EndProcedure

// Handler for subscribing to the pre-Recording event to check whether changes are forbidden.
//
// Parameters:
//  Source     - CalculationRegisterRecordSet -  a set of records that is passed
//                 to the pre-Recording event subscription.
//  Cancel        - Boolean -  parameter passed to the event subscription before Recording.
//  Replacing    - Boolean -  parameter passed to the event subscription before Recording.
//  WriteOnly - Boolean -  parameter passed to the event subscription before Recording.
//  WriteActualActionPeriod - Boolean -  parameter passed to the event subscription before Recording.
//  WriteRecalculations - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeWriteCalculationRegisterRecordSet(
		Source,
		Cancel,
		Replacing,
		WriteOnly,
		WriteActualActionPeriod,
		WriteRecalculations) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel, True, Replacing);
	
EndProcedure

// Handler for subscribing to the pre-Delete event to check whether changes are not allowed.
//
// Parameters:
//  Source   - CatalogObject
//             - DocumentObject
//             - ChartOfCharacteristicTypesObject
//             - ChartOfAccountsObject
//             - ChartOfCalculationTypesObject
//             - BusinessProcessObject
//             - TaskObject
//             - ExchangePlanObject -  a data object that is passed to the pre-Recording event subscription.
//
//  Cancel      - Boolean -  parameter passed to the event subscription before Recording.
//
Procedure CheckPeriodEndClosingDateBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.DeletionMark Then
		Return;
	EndIf;
	
	CheckPeriodClosingDates(Source, Cancel, , , True);
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// You do not need to call it, because the update is performed automatically.
Procedure UpdatePeriodClosingDatesSections() Export
	
	PeriodClosingDatesInternal.UpdatePeriodClosingDatesSections();
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

// For procedures, check the date of the change*.
Procedure CheckPeriodClosingDates(
		Source, Cancel, SourceRegister = False, Replacing = True, Delete = False)
	
	Result = PeriodClosingDatesInternal.CheckDataImportRestrictionDates1(
		Source, SourceRegister, Replacing, Delete);
	If Result.DataChangesDenied Then
		Raise Result.ErrorDescription;
	EndIf;		
	
EndProcedure

#EndRegion
