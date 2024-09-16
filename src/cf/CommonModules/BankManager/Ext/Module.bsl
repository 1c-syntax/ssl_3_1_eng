﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Provides data from the BIC Directory.
// 
// Parameters:
//  BIC      - String -  bank identification code.
//  CorrAccount - String -  Bank's correspondent account.
//  CurrentOnly - Boolean -  if True, then only the active participants of the calculations are included in the search result.
//
// Returns:
//  ValueTable:
//   * Ref - CatalogRef.BankClassifier
//   * BIC - String
//   * CorrAccount - String
//   * Description - String
//   * City - String
//   * Address- String
//   * Phones - String
//   * TIN - String
//   * OutOfBusiness - Boolean
//   * SWIFTBIC - String
//   * InternationalDescription - String
//   * CityInternationalFormat - String
//   * InternationalAddress - String
//   * Country - 
//   * CashSettlementCenterBIC - String
//   * TheNameOfTheRomanCatholicChurch - String
//   * CorrespondentAccountOfTheRCC - String
//   * CityOfTheRCC - String
//   * AddressOfTheRCC - String
//   * UNRCC - String
//
Function BICInformation(Val BIC, Val CorrAccount = Undefined, CurrentOnly = True) Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Return DataProcessors[DataProcessorName].BICInformation(BIC, CorrAccount, CurrentOnly);
	EndIf;
	
	QueryText =
	"SELECT
	|	CatalogBIC.Ref AS Ref,
	|	CatalogBIC.Code AS BIC,
	|	CatalogBIC.Description AS Description,
	|	CatalogBIC.CorrAccount AS CorrAccount,
	|	CatalogBIC.City AS City,
	|	CatalogBIC.Address AS Address,
	|	CatalogBIC.Phones AS Phones,
	|	CatalogBIC.OutOfBusiness AS OutOfBusiness,
	|	CatalogBIC.SWIFTBIC AS SWIFTBIC,
	|	CatalogBIC.InternationalDescription AS InternationalDescription,
	|	CatalogBIC.CityInternationalFormat AS CityInternationalFormat,
	|	CatalogBIC.InternationalAddress AS InternationalAddress,
	|	CatalogBIC.Country AS Country
	|FROM
	|	Catalog.BankClassifier AS CatalogBIC
	|WHERE
	|	CatalogBIC.Code = &BIC
	|	AND CASE
	|			WHEN &CorrAccount = UNDEFINED
	|				THEN TRUE
	|			ELSE CatalogBIC.CorrAccount = &CorrAccount
	|		END
	|	AND CASE
	|			WHEN &CurrentOnly
	|				THEN NOT CatalogBIC.OutOfBusiness
	|			ELSE TRUE
	|		END";
	
	Query = New Query(QueryText);
	Query.SetParameter("BIC", BIC);
	Query.SetParameter("CorrAccount", CorrAccount);
	Query.SetParameter("CurrentOnly", CurrentOnly);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns a text description of the reason why the Bank is marked as invalid.
//
// Parameters:
//  Bank - CatalogRef.BankClassifier -  the Bank for which you need to get the explanation text.
//
// Returns:
//  FormattedString - 
//
Function InvalidBankNote(Bank) Export
	
	BankDescription = String(Bank);
	
	QueryText =
	"SELECT
	|	BankClassifier.Ref,
	|	BankClassifier.Code AS BIC
	|FROM
	|	Catalog.BankClassifier AS BankClassifier
	|WHERE
	|	BankClassifier.Ref <> &Ref
	|	AND BankClassifier.Description = &Description
	|	AND NOT BankClassifier.OutOfBusiness";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Bank);
	Query.SetParameter("Description", BankDescription);
	Selection = Query.Execute().Select();
	
	NewBankDetails = Undefined;
	If Selection.Next() Then
		NewBankDetails = New Structure("Ref, BIC", Selection.Ref, Selection.BIC);
	EndIf;
	
	If ValueIsFilled(Bank) And ValueIsFilled(NewBankDetails) Then
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Bank code was changed to <a href = ""%1"">%2</a>';"),
			GetURL(NewBankDetails.Ref), NewBankDetails.BIC);
	Else
		Result = NStr("en = 'Bank activity is ceased';");
	EndIf;
	
	Return StringFunctions.FormattedString(Result);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// Parameters:
//  BIC          - String -  bank identification code.
//  CorrAccount     - String -  Bank's correspondent account.
//  RecordAboutBank - CatalogRef
//               - String - 
//
Procedure GetClassifierData(BIC = "", CorrAccount = "", RecordAboutBank = "") Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		Parameters = New Structure;
		Parameters.Insert("BIC", BIC);
		Parameters.Insert("CorrAccount", CorrAccount);
		Parameters.Insert("RecordAboutBank", RecordAboutBank);
		StandardProcessing = True;
		DataProcessors[DataProcessorName].WhenReceivingClassifierData(Parameters, StandardProcessing);
		If Not StandardProcessing Then
			BIC = Parameters.BIC;
			CorrAccount = Parameters.CorrAccount;
			RecordAboutBank = Parameters.RecordAboutBank;
			Return;
		EndIf;
	EndIf;
	
	If Not IsBlankString(BIC) Then
		RecordAboutBank = Catalogs.BankClassifier.FindByCode(BIC);
	ElsIf Not IsBlankString(CorrAccount) Then
		RecordAboutBank = Catalogs.BankClassifier.FindByAttribute("CorrAccount", CorrAccount);
	Else
		RecordAboutBank = "";
	EndIf;
	If RecordAboutBank = Catalogs.BankClassifier.EmptyRef() Then
		RecordAboutBank = "";
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.BankClassifier.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.BankClassifier.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment.
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.AddEditBanks.Name);
	
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.BankClassifier);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) = Undefined Then
		Return;
	EndIf;
	
	If Not Common.SubsystemExists("OnlineUserSupport.ClassifiersOperations") Then
		Return;
	EndIf;
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Common.DataSeparationEnabled() // 
		Or Common.IsSubordinateDIBNode() // 
		Or Not AccessRight("Update", Metadata.Catalogs.BankClassifier)
		Or ModuleToDoListServer.UserTaskDisabled("BankClassifier") Then
		Return;
	EndIf;
	
	Result = DataProcessors[DataProcessorName].RelevanceOfBankClassifier();
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.Catalogs.BankClassifier.FullName());
	
	For Each Section In Sections Do
		
		IdentifierBanks = "BankClassifier" + StrReplace(Section.FullName(), ".", "");
		
		HasToDoItems = Result.ClassifierIsExpired 
			Or Result.UpdateAvailable <> Undefined And Result.UpdateAvailable;
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = IdentifierBanks;
		ToDoItem.HasToDoItems       = HasToDoItems;
		ToDoItem.Important         = Result.ClassifierIsExpired;
		ToDoItem.Presentation  = NStr("en = 'Bank codes catalog is outdated';");
		ToDoItem.ToolTip      = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The last update was %1 ago.';"), Result.AmountOfDelayByLine);
		ToDoItem.Form          = "DataProcessor.ImportBankClassifier.Form";
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	OutputMessageOnInvalidity = (
		Not Common.DataSeparationEnabled() // 
		And Not Common.IsSubordinateDIBNode() // 
		And AccessRight("Update", Metadata.Catalogs.BankClassifier) // 
		And Not BankManagerInternal.ClassifierUpToDate()); // 
	
	If Not Common.DataSeparationEnabled() Then
		EnableNotifications = False;
	Else
		EnableNotifications = Not Common.SubsystemExists("StandardSubsystems.ToDoList");
		BankManagerOverridable.OnDetermineIfOutdatedClassifierWarningRequired(EnableNotifications);
	EndIf;
	
	Parameters.Insert("Banks", New FixedStructure("OutputMessageOnInvalidity", (OutputMessageOnInvalidity And EnableNotifications)));
	
EndProcedure

#EndRegion
