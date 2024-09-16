///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	Result = New Array;
	Result.Add("*");
	Return Result;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not StandardProcessing 
		Or Not Parameters.Property("AllowClassifierData")
		Or Not Parameters.AllowClassifierData Then
		Return;
	EndIf;
	
	ContactsManagerInternal.ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
EndProcedure

#EndRegion

#Region Internal

// Defines country data based on the country directory or country classifier.
// We recommend using contact information Management.Data from the world.
//
// Parameters:
//    CountryCode    - String
//                 - Number - 
//    Description - String        -  name of the country. If not specified, the search by name is not performed.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//          * Ref             - CatalogRef.WorldCountries
//    Undefined - the country does not exist.
//
Function WorldCountryData(Val CountryCode = Undefined, Val Description = Undefined) Export
	Return ContactsManager.WorldCountryData(CountryCode, Description);
EndFunction

// Defines the information countries the classification of countries.
// We recommend using contact information Management.Data classifierstranmirapocode.
//
// Parameters:
//    Code - String
//        - Number - 
//    CodeType - String -  Options: country code (default), ALPHA2, Alpha3.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//    Undefined - the country does not exist.
//
Function WorldCountryClassifierDataByCode(Val Code, CodeType = "CountryCode") Export
	Return ContactsManager.WorldCountryClassifierDataByCode(Code, CodeType);
EndFunction

// Defines the data of the country for the classifier.
// We recommend using contact information Management.Dataclassificatorstranmiraname.
//
// Parameters:
//    Description - String -  name of the country.
//
// Returns:
//    Structure:
//          * Code                - String
//          * Description       - String
//          * DescriptionFull - String
//          * CodeAlpha2          - String
//          * CodeAlpha3          - String
//    Undefined - the country does not exist.
//
Function WorldCountryClassifierDataByDescription(Val Description) Export
	Return ContactsManager.WorldCountryClassifierDataByDescription(Description);
EndFunction

#EndRegion

#Region Private

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	If ContactsManagerInternalCached.AreAddressManagementModulesAvailable() Then
		ModuleAddressManager = Common.CommonModule("AddressManager");
		ModuleAddressManager.OnInitialItemsFilling(LanguagesCodes, Items, TabularSections);
	EndIf;
	
EndProcedure

#Region InfobaseUpdate

// Registers for processing countries of the world.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		// 
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("UpdateMode", "MultilingualStrings");
		
		InfobaseUpdate.RegisterPredefinedItemsToUpdate(Parameters,
			Metadata.Catalogs.WorldCountries, AdditionalParameters);
	
	EndIf;
	
	CountryList = ContactsManager.CustomEAEUCountries();
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "203";
	NewRow.Description       = NStr("en = 'CZECH REPUBLIC';");
	NewRow.CodeAlpha2          = "CZ";
	NewRow.CodeAlpha3          = "CZE";
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "270";
	NewRow.Description       = NStr("en = 'GAMBIA';");
	NewRow.CodeAlpha2          = "GM";
	NewRow.CodeAlpha3          = "GMB";
	NewRow.DescriptionFull = NStr("en = 'Republic of the Gambia';");
	
	NewRow                    = CountryList.Add();
	NewRow.Code                = "807";
	NewRow.Description       = NStr("en = 'REPUBLIC OF MACEDONIA';");
	NewRow.CodeAlpha2          = "MK";
	NewRow.CodeAlpha3          = "MKD";
	NewRow.DescriptionFull =  NStr("en = 'REPUBLIC OF MACEDONIA';");
	
	Query = New Query;
	Query.Text = "SELECT
		|	CountryList.Code AS Code,
		|	CountryList.Description AS Description,
		|	CountryList.CodeAlpha2 AS CodeAlpha2,
		|	CountryList.CodeAlpha3 AS CodeAlpha3,
		|	CountryList.DescriptionFull AS DescriptionFull
		|INTO CountryList
		|FROM
		|	&CountryList AS CountryList
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	WorldCountries.Ref AS Ref
		|FROM
		|	CountryList AS CountryList
		|		INNER JOIN Catalog.WorldCountries AS WorldCountries
		|		ON (WorldCountries.Code = CountryList.Code)
		|			AND (WorldCountries.Description = CountryList.Description)
		|			AND (WorldCountries.CodeAlpha2 = CountryList.CodeAlpha2)
		|			AND (WorldCountries.CodeAlpha3 = CountryList.CodeAlpha3)
		|			AND (WorldCountries.DescriptionFull = CountryList.DescriptionFull)";
	
	Query.SetParameter("CountryList", CountryList);
	QueryResult = Query.Execute().Unload();
	CountriesToProcess = QueryResult.UnloadColumn("Ref");
	
	InfobaseUpdate.MarkForProcessing(Parameters, CountriesToProcess);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	WorldCountryForProcessing = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.WorldCountries");
	SettingsOfUpdate = Undefined;
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		SettingsOfUpdate = ModuleNationalLanguageSupportServer.SettingsPredefinedDataUpdate(Metadata.Catalogs.WorldCountries);
	EndIf;
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	
	While WorldCountryForProcessing.Next() Do
		
		WorldCountryRef = WorldCountryForProcessing.Ref; // CatalogRef.WorldCountries
		RepresentationOfTheReference = String(WorldCountryRef);
		
		Try
			
			CountryCode = Common.ObjectAttributeValue(WorldCountryRef, "Code");
			ClassifierData = ContactsManager.WorldCountryClassifierDataByCode(CountryCode);
			
			If ClassifierData <> Undefined Then
				
				Block = New DataLock();
				LockItem = Block.Add("Catalog.WorldCountries");
				LockItem.SetValue("Ref", WorldCountryRef);
				
				BeginTransaction();
				Try
					
					Block.Lock();
					
					WorldCountry = WorldCountryRef.GetObject();
					FillPropertyValues(WorldCountry, ClassifierData);
					InfobaseUpdate.WriteData(WorldCountry);
					
					CommitTransaction();
					
				Except
					RollbackTransaction();
					Raise;
				EndTry;
				
			Else
				InfobaseUpdate.MarkProcessingCompletion(WorldCountryRef);
			EndIf;
			
			// 
			If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
				If SettingsOfUpdate.ObjectAttributesToLocalize.Count() > 0 Then
					ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
					ModuleNationalLanguageSupportServer.UpdateMultilanguageStringsOfPredefinedItem(WorldCountryRef, SettingsOfUpdate);
				EndIf;
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
		Except
			// 
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				WorldCountryRef,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.WorldCountries");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some countries: %1';"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.WorldCountries,,
			StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The update procedure processed another portion of world countries: %1';"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

