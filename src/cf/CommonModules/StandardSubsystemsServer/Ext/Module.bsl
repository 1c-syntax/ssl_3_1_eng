///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The call to this procedure must be placed in the session module in the session parameter Setting procedure
// according to the documentation.
//
// Parameters:
//  SessionParametersNames - Array of String
//                        - Undefined - 
//                                         
//                                         
//                                         
//                                         
//
// Returns:
//  Array of String - 
//
Function SessionParametersSetting(SessionParametersNames) Export
	
	// 
	// 
	// 
	SpecifiedParameters = New Array;
	
#If Not MobileStandaloneServer Then
	
	If SessionParametersNames <> Undefined
	   And SessionParametersNames.Find("ClientParametersAtServer") <> Undefined Then
		
		SessionParameters.ClientParametersAtServer = New FixedMap(New Map);
		SpecifiedParameters.Add("ClientParametersAtServer");
		If SessionParametersNames.Count() = 1 Then
			Return SpecifiedParameters;
		EndIf;
	EndIf;
	
	If SessionParametersNames = Undefined Then
		If SessionParameters.ClientParametersAtServer.Count() = 0 Then
			BlankTheClientSettings = New Map;
			BlankTheClientSettings.Insert("TheFirstServerCallIsMade",
				?(CurrentRunMode() = Undefined, Undefined, False));
			BlankTheClientSettings.Insert("StateBeforeCallAuthenticateCurrentUser", True);
			SessionParameters.ClientParametersAtServer = New FixedMap(BlankTheClientSettings);
		EndIf;
		Catalogs.ExtensionsVersions.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
		
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ModuleNationalLanguageSupportServer.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
		EndIf;
		
		// 
		BeforeStartApplication();
		Return SpecifiedParameters;
	EndIf;
	
	If Catalogs.MetadataObjectIDs.AllSessionParametersAreSet(
			SessionParametersNames, SpecifiedParameters) Then
		Return SpecifiedParameters;
	EndIf;
	
	If SessionParametersNames.Find("CachedDataKey") <> Undefined Then
		SessionParameters.CachedDataKey = New UUID;
		SpecifiedParameters.Add("CachedDataKey");
	EndIf;
	
	Catalogs.ExtensionsVersions.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.SessionParametersSetting(SessionParametersNames, SpecifiedParameters);
	EndIf;
	
	If SessionParametersNames.Find("Clipboard") <> Undefined Then
		SessionParameters.Clipboard = New FixedStructure(New Structure("Source, Data"));
		SpecifiedParameters.Add("Clipboard");
	EndIf;
	
	Handlers = New Map;
	SSLSubsystemsIntegration.OnAddSessionParameterSettingHandlers(Handlers);
	
	CustomHandlers = New Map;
	CommonOverridable.OnAddSessionParameterSettingHandlers(CustomHandlers);
	For Each Record In CustomHandlers Do
		Handlers.Insert(Record.Key, Record.Value);
	EndDo;
	
	ExecuteSessionParameterSettingHandlers(SessionParametersNames, Handlers, SpecifiedParameters);
	
	SSLSubsystemsIntegration.OnSetSessionParameters(SessionParametersNames);
	
#EndIf
	
	Return SpecifiedParameters;
	
EndFunction

#If Not MobileStandaloneServer Then

// Returns a flag indicating whether the configuration is basic.
// The basic version of the configuration software may have limitations, the effect of which
// it is possible to envisage using this feature.
// A configuration is considered basic if its name contains the term "basic",
// for example,"trade management".
//
// Returns:
//   Boolean - 
//
Function IsBaseConfigurationVersion() Export
	
	IsBaseConfigurationVersion = StrFind(Upper(Metadata.Name), NStr("en = 'BASE';")) > 0;
	CommonOverridable.WhenDefiningAFeatureThisIsTheBasicVersionOfTheConfiguration(IsBaseConfigurationVersion);
	
	Return IsBaseConfigurationVersion;
	
EndFunction

// 
// 
// 
//
// Returns:
//   Boolean - 
//
Function IsTrainingPlatform() Export
	
	SetPrivilegedMode(True);
	CurrentUser = InfoBaseUsers.CurrentUser();

	Try
		OSUser = CurrentUser.OSUser;
	Except
		// 
		Return True;
	EndTry;
	Return False;
	
EndFunction

// Updates metadata property caches to speed
// up session opening and information security updates, especially in the service model.
// They are updated before the IB is updated.
//
// For use in other libraries and configurations.
//
Procedure UpdateAllApplicationParameters() Export
	
	InformationRegisters.ApplicationRuntimeParameters.UpdateAllApplicationParameters();
	
EndProcedure

// Returns the version number of the" standard subsystem Library " (BSP)
// built into the configuration.
//
// Returns:
//  String - 
//
Function LibraryVersion() Export
	
	Return StandardSubsystemsCached.SubsystemsDetails().ByNames["StandardSubsystems"].Version;
	
EndFunction

// Gets a unique ID of the information database,
// which can be used to distinguish between different instances of information databases,
// for example, when collecting statistics or in external database management mechanisms.
// If the ID is empty, its value is automatically set and returned.
//
// The ID is stored in the ID constant of the information Database.
// The ID constant of the information Base should not be included in the exchange plans, so that it has
// different values in each information base (rib node).
//
// Returns:
//  String - 
//
Function InfoBaseID() Export
	
	InfoBaseID = Constants.InfoBaseID.Get();
	
	If IsBlankString(InfoBaseID) Then
		InfoBaseID = String(New UUID());
		
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		
		Constants.InfoBaseID.Set(InfoBaseID);
		
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	Return InfoBaseID;
	
EndFunction

// 
// 
// 
// 
// 
//
// Returns:
//  Structure - 
//               
//              
//              
//              
//              
//
Function AdministrationParameters() Export
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		
		If Not Users.IsFullUser() Then
			Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
		EndIf;
	Else
		If Not Users.IsFullUser(, True) Then
			Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	IBAdministrationParameters = Constants.IBAdministrationParameters.Get().Get();
	DefaultAdministrationParameters = DefaultAdministrationParameters();
	
	If TypeOf(IBAdministrationParameters) = Type("Structure") Then
		FillPropertyValues(DefaultAdministrationParameters, IBAdministrationParameters);
	EndIf;
	IBAdministrationParameters = DefaultAdministrationParameters;
	
	If Not Common.FileInfobase() Then
		ReadParametersFromConnectionString(IBAdministrationParameters);
	EndIf;
	
	Return IBAdministrationParameters;
	
EndFunction

// Saves the administration settings of an information base and cluster of servers.
// When saving, fields containing passwords will be cleared for security reasons.
//
// Parameters:
//  IBAdministrationParameters - See AdministrationParameters
//
// Example:
//  
//  
//  
//  
//
Procedure SetAdministrationParameters(IBAdministrationParameters) Export
	
	IBAdministrationParameters.ClusterAdministratorPassword = "";
	IBAdministrationParameters.InfobaseAdministratorPassword = "";
	Constants.IBAdministrationParameters.Set(New ValueStorage(IBAdministrationParameters));
	
EndProcedure

// Sets the representation of the Date field in lists containing details with the Date and Time composition.
// For more information, see the standard "Date field in lists".
//
// Parameters:
//   Form - ClientApplicationForm -  form with a list.
//   FullAttributeName - String -  full path to the "date" type of information in the format " < Listname>.<Field name>".
//   TagName - String -  name of the form element associated with the "date" list item.
//
// Example:
//
//	Procedure For Connecting To The Server(Failure, Standard Processing)
//		Standardsystem server.Set The Conditional Formalpolyadate(This Object);
//
Procedure SetDateFieldConditionalAppearance(Form, 
	FullAttributeName = "List.Date", TagName = "Date") Export
	
	CommonClientServer.CheckParameter(
		"StandardSubsystemsServer.SetDateFieldConditionalAppearance",
		"ThisObject", 
		Form, 
		Type("ClientApplicationForm"));
	
	FullNameParts1 = StrSplit(FullAttributeName, ".");
	
	If FullNameParts1.Count() <> 2 Then 
		// 
		// 
		Return;
	EndIf;
	
	ListName = FullNameParts1[0];
	AttributeList = Form[ListName];
	
	If TypeOf(AttributeList) = Type("DynamicList") Then 
		// 
		// 
		//  
		// 
		ConditionalAppearance = AttributeList.ConditionalAppearance;
		AttributePath1 = FullNameParts1[1];
		FormattedFieldName = AttributePath1;
	Else 
		// 
		// 
		ConditionalAppearance = Form.ConditionalAppearance;
		AttributePath1 = FullAttributeName;
		FormattedFieldName = TagName;
	EndIf;
	
	If Not ValueIsFilled(ConditionalAppearance.UserSettingID) Then
		ConditionalAppearance.UserSettingID = "MainAppearance";
	EndIf;
	
	// 
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", "DLF=D");
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	// 
	AppearanceItem = ConditionalAppearance.Items.Add();
	AppearanceItem.Use = True;
	AppearanceItem.Appearance.SetParameterValue("Format", NStr("en = 'DF=HH:mm';"));
	
	FormattedField = AppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField(FormattedFieldName);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.GreaterOrEqual;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfThisDay);
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField(AttributePath1);
	FilterElement.ComparisonType   = DataCompositionComparisonType.Less;
	FilterElement.RightValue = New StandardBeginningDate(StandardBeginningDateVariant.BeginningOfNextDay);
	
EndProcedure

// 
// 
// 
// 
// Returns:
//   Boolean - 
//            
// 
Function AskConfirmationOnExit() Export
	
	Result = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"AskConfirmationOnExit");
	
	If Result = Undefined Then
		Result = Common.CommonCoreParameters().AskConfirmationOnExit;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns descriptions of formats for saving a table document.
//
// Returns:
//  ValueTable:
//   * SpreadsheetDocumentFileType - SpreadsheetDocumentFileType -  value corresponding to the format;
//   * Ref - EnumRef.ReportSaveFormats      -  link to the metadata where the view is stored;
//   * Presentation - String -  representation of the file type (filled in from the enumeration);
//   * Extension    - String -  file type for the operating system;
//   * Picture      - Picture -  image format.
//
Function SpreadsheetDocumentSaveFormatsSettings() Export
	
	FormatsTable = New ValueTable;
	
	FormatsTable.Columns.Add("SpreadsheetDocumentFileType", New TypeDescription("SpreadsheetDocumentFileType"));
	FormatsTable.Columns.Add("Ref", New TypeDescription("EnumRef.ReportSaveFormats"));
	FormatsTable.Columns.Add("Presentation", New TypeDescription("String"));
	FormatsTable.Columns.Add("Extension", New TypeDescription("String"));
	FormatsTable.Columns.Add("Picture", New TypeDescription("Picture"));

	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = TableDocumentFileTypePDF();
	NewFormat.Ref = Enums.ReportSaveFormats.PDF;
	NewFormat.Extension = "pdf";
	NewFormat.Picture = PictureLib.PDFFormat;
	NewFormat.Presentation = FileTypeRepresentationOfATabularPDFDocument();
	
	StandardSubsystemsServerLocalization.OnSetupSpreadsheetSaveFormats(FormatsTable);
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.MXL;
	NewFormat.Ref = Enums.ReportSaveFormats.MXL;
	NewFormat.Extension = "mxl";
	NewFormat.Picture = PictureLib.MXLFormat;
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.XLSX;
	NewFormat.Ref = Enums.ReportSaveFormats.XLSX;
	NewFormat.Extension = "xlsx";
	NewFormat.Picture = PictureLib.ExcelFormat2007;

	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.XLS;
	NewFormat.Ref = Enums.ReportSaveFormats.XLS;
	NewFormat.Extension = "xls";
	NewFormat.Picture = PictureLib.ExcelFormat;

	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.ODS;
	NewFormat.Ref = Enums.ReportSaveFormats.ODS;
	NewFormat.Extension = "ods";
	NewFormat.Picture = PictureLib.OpenOfficeCalcFormat;
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.DOCX;
	NewFormat.Ref = Enums.ReportSaveFormats.DOCX;
	NewFormat.Extension = "docx";
	NewFormat.Picture = PictureLib.WordFormat2007;
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.HTML5;
	NewFormat.Ref = Enums.ReportSaveFormats.HTML;
	NewFormat.Extension = "html";
	NewFormat.Picture = PictureLib.HTMLFormat;
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.TXT;
	NewFormat.Ref = Enums.ReportSaveFormats.TXT;
	NewFormat.Extension = "txt";
	NewFormat.Picture = PictureLib.TXTFormat;
	
	// 
	NewFormat = FormatsTable.Add();
	NewFormat.SpreadsheetDocumentFileType = SpreadsheetDocumentFileType.ANSITXT;
	NewFormat.Ref = Enums.ReportSaveFormats.ANSITXT;
	NewFormat.Extension = "txt";
	NewFormat.Picture = PictureLib.TXTFormat;
	
	For Each SaveFormat In FormatsTable Do
		If Not ValueIsFilled(SaveFormat.Presentation) Then
			SaveFormat.Presentation = String(SaveFormat.Ref);
		EndIf;
	EndDo;
		
	Return FormatsTable;
	
EndFunction

// Returns the compatibility mode version in the revision and version numbering format, for example, 8.3.15.0.
//
// Returns:
//   String - 
//
Function CompatibilityModeVersion() Export 
	
	If Metadata.CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse Then 
		
		Information = New SystemInfo;
		Return Information.AppVersion;
		
	EndIf;
	
	CompatibilityModeDescription = StrSplit(Metadata.CompatibilityMode, "_");
	Symbols = StrLen(CompatibilityModeDescription[0]);
	
	EditionNumber = "";
	
	For CharacterNumber = 1 To Symbols Do 
		
		CurrentChar = Mid(CompatibilityModeDescription[0], CharacterNumber, 1);
		
		If StrFind("0123456789", CurrentChar) > 0 Then 
			EditionNumber = EditionNumber + CurrentChar;
		EndIf;
		
	EndDo;
	
	CompatibilityModeDescription.Set(0, EditionNumber);
	
	For IndexOf = CompatibilityModeDescription.Count() To 3 Do 
		CompatibilityModeDescription.Add("0");
	EndDo;
	
	Return StrConcat(CompatibilityModeDescription, ".");
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
//  
// 
//
// 
// 
// 
// 
//
// Parameters:
//  Form - ClientApplicationForm -  form for changing the font of group headers;
//  GroupNames - String -  a comma-separated list of form group names. If no group names are specified,
//                        the design will be applied to all groups on the form.
//
// Example:
//  Procedure For Connecting To The Server(Failure, Standard Processing)
//    Standardsystem server.Set The Display Of Group Headings(This Object);
//
Procedure SetGroupTitleRepresentation(Form, GroupNames = "") Export
	
	// 
	
EndProcedure

#EndRegion

// Returns whether to display a pop-up notification about installed
// program updates - dynamic program updates, new patches, and extensions.
//
// Returns:
//  Boolean - 
//
Function ShowInstalledApplicationUpdatesWarning() Export
	
	Return ShowWarningAboutInstalledUpdatesForUser();
	
EndFunction

#Region ForCallsFromOtherSubsystems

// 
// 
//
// 
// 
//
// Parameters:
//  NameOfAlert - String - 
//  ParametersVariants - Array of Structure:
//   * Parameters - Arbitrary - 
//   * SMSMessageRecipients - Map of KeyAndValue:
//      ** Key - UUID - 
//      ** Value - Array of See ServerNotifications.SessionKey
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
Procedure OnSendServerNotification(NameOfAlert, ParametersVariants) Export
	
	If NameOfAlert = "StandardSubsystems.Core.FunctionalOptionsModified" Then
		OnSendServerNotificationFunctionalOptionsModified(NameOfAlert, ParametersVariants);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

#EndRegion

#If Not MobileStandaloneServer Then

#Region Internal

// 
// 
// Parameters:
//  SendImmediately - See ServerNotifications.SendServerNotification.SendImmediately
//
Procedure NotifyAllSessionsAboutOutdatedCache(SendImmediately = False) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	ServerNotifications.SendServerNotification(
		"StandardSubsystems.Core.CachedValuesOutdated",
		"",
		Undefined,
		SendImmediately);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//  RaiseException1 - Boolean - 
//
// 
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String - 
//   * Value - String
//
Function ClientParametersAtServer(RaiseException1 = True) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ClientParameters = SessionParameters.ClientParametersAtServer;
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Not RaiseException1
	 Or CurrentRunMode() = Undefined
	   And ClientParameters.Get("TheFirstServerCallIsMade") = Undefined
	 Or ClientParameters.Get("TheFirstServerCallIsMade") = True Then
		
		Return ClientParameters;
	EndIf;
	
	If CurrentRunMode() <> Undefined Then
		// 
		// 
		RefreshReusableValues();
	EndIf;
	
	OnStart = ClientParameters.Get("TheFirstServerCallIsMade") = False;
	
	If OnStart Then
		CommentForTheLogWithoutACallStack = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed before initialization was completed in %1.';",
			     Common.DefaultLanguageCode()),
			     "StandardSubsystemsClient.BeforeStart");
	Else
		CommentForTheLogWithoutACallStack = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid access to uninitialized client parameters on the server.
			           |The call might have been executed after session parameters were cleared incorrectly without using %2.';",
			     Common.DefaultLanguageCode()),
			     "Common.ClearSessionParameters");
	EndIf;
	
	Try
		Raise CommentForTheLogWithoutACallStack;
	Except
		ErrorInfo = ErrorInfo();
	EndTry;
	CommentWithCallStack = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	EventName = NStr("en = 'The client parameters on the server are blank';",
		Common.DefaultLanguageCode());
	
	WriteLogEvent(EventName, EventLogLevel.Error,,, CommentWithCallStack);
	
	If Not OnStart Then
		ErrorText =
			NStr("en = 'Client parameters on the server are not initialized.
			           |To initialize them, retry the action or restart the session.';");
		Raise ErrorText;
	EndIf;
	
	Return ClientParameters;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Checks that the latest version of the program is available in the current session
// . otherwise, it throws an exception requiring you to restart the session.
//
// In old sessions, you can't update the program parameters, and
// you can't change some data so
// that the new version of data (obtained using the new version of the program) is not overwritten
// by the old version of data (obtained using the old version of the program).
//
Procedure CheckApplicationVersionDynamicUpdate() Export
	
	If ApplicationVersionUpdatedDynamically() Then
		RequireRestartDueToApplicationVersionDynamicUpdate();
	EndIf;
	
EndProcedure

// Checks that the current session has a dynamic database configuration change and
// there is no database update mode.
//
// Returns:
//  Boolean - 
//
Function ApplicationVersionUpdatedDynamically() Export
	
	If Not DataBaseConfigurationChangedDynamically() Then
		Return False;
	EndIf;
	
	// 
	// 
	// 
	
	If Common.DataSeparationEnabled() Then
		// 
		// 
		Return Not InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired();
	EndIf;
	
	Return Not InfobaseUpdate.InfobaseUpdateRequired();
	
EndFunction

// Raises an exception that requires you to restart the session due to an update to the program version.
Procedure RequireRestartDueToApplicationVersionDynamicUpdate() Export
	
	ErrorText = NStr("en = 'The app is updated. Restart the app.';");
	InstallRequiresSessionRestart(ErrorText);
	Raise ErrorText;
	
EndProcedure

// Raises an exception that requires you to restart the session due to updating program extensions.
Procedure RequireSessionRestartDueToDynamicUpdateOfProgramExtensions() Export
	
	If StandardSubsystemsCached.IsSeparatedModeWithoutDataAreaExtensions() Then
		ErrorText =
			NStr("en = 'To perform the required actions,
			           |start a session with the specified separators.
			           |
			           |Data area extensions are not applied when you log in to a data area in a session
			           |that is started without separators.';");
	Else
		ErrorText = NStr("en = 'Extensions are updated. Restart the app.';");
	EndIf;
	
	InstallRequiresSessionRestart(ErrorText);
	Raise ErrorText;
	
EndProcedure

// Returns:
//  Boolean
//
Function ThisIsSplitSessionModeWithNoDelimiters() Export
	
	If Not Common.DataSeparationEnabled()
	 Or Not Common.SeparatedDataUsageAvailable()
	 Or Not Common.SubsystemExists("CloudTechnology.Core") Then
		Return False;
	EndIf;
	
	ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
	Return ModuleSaaSOperations.SessionWithoutSeparators();
	
EndFunction

// 
// 
//
// Parameters:
//  BriefErrorDescription - String - 
//   
//   
//
Procedure InstallRequiresSessionRestart(BriefErrorDescription) Export
	
	If CurrentRunMode() <> Undefined Then
		Return;
	EndIf;
	
	CurrentSession = GetCurrentInfoBaseSession();
	If CurrentSession.ApplicationName <> "BackgroundJob" Then
		Return;
	EndIf;
	
	If SessionRestartRequired() Then
		Return;
	EndIf;
	
	CurrentParameters = New Structure(SessionParameters.InstalledExtensions);
	CurrentParameters.Insert("SessionRestartRequired", BriefErrorDescription);
	SessionParameters.InstalledExtensions = New FixedStructure(CurrentParameters);
	
EndProcedure

// 
// 
//
// Parameters:
//  BriefErrorDescription - String - 
//    
//
// Returns:
//  Boolean
//
Function SessionRestartRequired(BriefErrorDescription = "") Export
	
	If Not SessionParameters.InstalledExtensions.Property("SessionRestartRequired") Then
		Return False;
	EndIf;
	
	BriefErrorDescription = SessionParameters.InstalledExtensions.SessionRestartRequired;
	
	Return True;
	
EndFunction

// 
// 
//
// Parameters:
//  ErrorInfo - ErrorInfo
//
// Returns:
//  Boolean
//
Function ThisErrorRequirementRestartSession(ErrorInfo) Export
	
	ErrorText = "";
	If Not SessionRestartRequired(ErrorText) Then
		Return False;
	EndIf;
	
	Return TypeOf(ErrorInfo) = Type("ErrorInfo")
	      And ValueIsFilled(ErrorText)
	      And StrStartsWith(ErrorProcessing.BriefErrorDescription(ErrorInfo), ErrorText);
	
EndFunction

// Returns the value of the program operation parameter.
//
// In an old session (when the program version is updated dynamically),
// if the parameter does not exist, an exception is thrown that requires a restart,
// otherwise the value is returned without considering the version.
//
// In the split mode of the service model, if the parameter does not exist or
// the parameter version is not equal to the configuration version, an exception is thrown,
// because it is not possible to update undivided data.
//
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//
// Returns:
//  Arbitrary - 
//                 
//
Function ApplicationParameter(ParameterName) Export
	
	Return InformationRegisters.ApplicationRuntimeParameters.ApplicationParameter(ParameterName);
	
EndFunction

// Sets the value of the program operation parameter.
// You must set privileged mode before calling.
//
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//
//  Value     - Arbitrary -  a value that can be placed in the value store.
//
Procedure SetApplicationParameter(ParameterName, Value) Export
	
	InformationRegisters.ApplicationRuntimeParameters.SetApplicationParameter(ParameterName, Value);
	
EndProcedure

// Updates the value of the program operation parameter if it has changed.
// You must set privileged mode before calling.
//
// Parameters:
//  ParameterName   - String -  maximum of 128 characters. For Example,
//                   " Standard Subsystems.Report variantss.Report with settings".
//
//  Value       - Arbitrary -  a value that can be placed in the value store.
//
//  HasChanges  - Boolean -  the return value. True is set
//                   if the old and new parameter values do not match.
//
//  PreviousValue2 - Arbitrary -  the return value. Before the update.
//
Procedure UpdateApplicationParameter(ParameterName, Value, HasChanges = False, PreviousValue2 = Undefined) Export
	
	InformationRegisters.ApplicationRuntimeParameters.UpdateApplicationParameter(ParameterName,
		Value, HasChanges, PreviousValue2);
	
EndProcedure

// Returns changes to the program operation parameter based on the current
// configuration version and the current is version.
//
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//
// Returns:
//  Undefined - 
//                 
//  
//                 
//
Function ApplicationParameterChanges(ParameterName) Export
	
	Return InformationRegisters.ApplicationRuntimeParameters.ApplicationParameterChanges(ParameterName);
	
EndFunction

// Add changes to the program operation parameter when switching to the current version of the configuration metadata.
// In the future, the changes are used to conditionally add mandatory update handlers.
// At the initial filling of IB or undivided data, the addition of changes is skipped.
// 
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//
//  Changes    - Arbitrary -  fixed data that is registered as changes.
//                 Changes are not added if the parameter change value is not filled in.
//
Procedure AddApplicationParameterChanges(ParameterName, Changes) Export
	
	InformationRegisters.ApplicationRuntimeParameters.AddApplicationParameterChanges(ParameterName, Changes);
	
EndProcedure

// For internal use only.
Procedure RegisterPriorityDataChangeForSubordinateDIBNodes() Export
	
	If Common.IsSubordinateDIBNode()
	 Or Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsCached.DisableMetadataObjectsIDs() Then
		Catalogs.MetadataObjectIDs.RegisterTotalChangeForSubordinateDIBNodes();
	EndIf;
	
	DIBExchangePlansNodes = New Map;
	For Each ExchangePlan In Metadata.ExchangePlans Do
		If Not ExchangePlan.DistributedInfoBase Then
			Continue;
		EndIf;
		DIBNodes = New Array;
		DIBExchangePlansNodes.Insert(ExchangePlan.Content, DIBNodes);
		ExchangePlanManager = Common.ObjectManagerByFullName(ExchangePlan.FullName());
		Selection = ExchangePlanManager.Select();
		While Selection.Next() Do
			If Selection.Ref <> ExchangePlanManager.ThisNode() Then
				DIBNodes.Add(Selection.Ref);
			EndIf;
		EndDo;
	EndDo;
	
	If DIBExchangePlansNodes.Count() > 0 Then
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.Catalogs);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfCharacteristicTypes);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfAccounts);
		RegisterPredefinedItemChanges(DIBExchangePlansNodes, Metadata.ChartsOfCalculationTypes);
	EndIf;
	
EndProcedure

// Creates missing predefined elements in all lists with new links (unique identifiers).
// To call after disconnecting the subordinate rib node from the main one, or to automatically restore 
// missing predefined elements.
//
Procedure RestorePredefinedItems() Export
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Raise 
			NStr("en = 'Restore the predefined items in the master node of the distributed infobase.
			           |Then synchronize the other nodes with the master node.';");
	EndIf;
	
	MetadataObjects = MetadataObjectsOfAllPredefinedData();
	Block = New DataLock;
	For Each MetadataObject In MetadataObjects Do
		Block.Add(MetadataObject.FullName());
	EndDo;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		SetAllPredefinedDataInitialization(MetadataObjects);
		CreateMissingPredefinedData(MetadataObjects);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Function PredefinedDataAttributes() Export
	Result = New Structure;
	Result.Insert("PredefinedDataName",  "");
	Result.Insert("PredefinedSetName", "");
	Result.Insert("PredefinedKindName",   "");
	Result.Insert("PredefinedFolderType",   Undefined);
	Return Result;
EndFunction

Function ThisIsPredefinedData(Val Item, AttributeName = "", AttributeValue = "") Export // 
	
	// 
	// 
	AttributesValues = PredefinedDataAttributes();
	FillPropertyValues(AttributesValues, Item);
	If AttributesValues.PredefinedDataName = ""
		And AttributesValues.PredefinedSetName = ""
		And AttributesValues.PredefinedKindName = ""
		And Not ValueIsFilled(AttributesValues.PredefinedFolderType) Then
		Return False;
	EndIf;

	AttributeName = "";
	If AttributesValues.PredefinedSetName <> "" Then
		AttributeName = "PredefinedSetName";
	ElsIf AttributesValues.PredefinedKindName <> "" Then
		AttributeName = "PredefinedKindName";
	ElsIf ValueIsFilled(AttributesValues.PredefinedFolderType) Then
		AttributeName = "PredefinedFolderType";
	Else
		AttributeName = "PredefinedDataName";
	EndIf;
	AttributeValue = AttributesValues[AttributeName];
	
	Return True;
	
EndFunction

// Parameters:
//  References - Array of AnyRef
//         - FixedArray of AnyRef - 
//           
//  Attributes - Array of String
//            - FixedArray of String - 
//            - String - 
//
// Returns:
//  Map of KeyAndValue - :
//   * Key - AnyRef -  object reference;
//   * Value - Structure:
//    ** Key - String -  the name of the props;
//    ** Value - Arbitrary - 
// 
Function ObjectAttributeValuesIfExist(References, Val Attributes) Export
	
	AttributesValues = New Map;
	If References.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	If TypeOf(Attributes) = Type("String") Then
		Attributes = StrSplit(Attributes, ",");
	EndIf;
	
	TypesAttributes = New Map;
	RefsByTypes = New Map;
	For Each Ref In References Do
		Type = TypeOf(Ref);
		If Not Common.IsReference(Type) Then
			Continue;
		EndIf;
		
		If RefsByTypes[Type] = Undefined Then
			RefsByTypes[Type] = New Array;
		EndIf;
		ItemByType = RefsByTypes[Type]; // Array
		ItemByType.Add(Ref);
		
		If TypesAttributes[Type] = Undefined Then
			
			MetadataObject = Metadata.FindByType(Type); // MetadataObjectCatalog
			If MetadataObject = Undefined Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Invalid value of the %1 parameter, function %2:
						|The array values must be references.';"), 
					"References", "Common.ObjectAttributeValuesIfExist");
			EndIf;
			AttributesOfType = New Array;
			StandardAttributes = New Map;
			For Each StandardAttribute In MetadataObject.StandardAttributes Do
				StandardAttributes[StandardAttribute.Name] = True;	
			EndDo;
			StandardAttributes["DataVersion"] = True;

			For Each AttributeName In Attributes Do
				If StandardAttributes[AttributeName] <> Undefined 
					Or MetadataObject.Attributes.Find(AttributeName) <> Undefined Then
					AttributesOfType.Add(AttributeName);
				Else
					AttributesOfType.Add("UNDEFINED AS" + " " + AttributeName); // @query-part
				EndIf;
			EndDo;
			TypesAttributes[Type] = AttributesOfType;
			
		EndIf;
	EndDo;
	
	
	If RefsByTypes.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	QueriesTexts = New Array;
	Query = New Query;
	
	For Each RefsByType In RefsByTypes Do
		Type = RefsByType.Key;
		MetadataObject = Metadata.FindByType(Type);
		FullMetadataObjectName = MetadataObject.FullName();

		QueryText =
			"SELECT ALLOWED
			|	Ref,
			|	&Attributes
			|FROM
			|	&FullMetadataObjectName AS SpecifiedTableAlias
			|WHERE
			|	SpecifiedTableAlias.Ref IN (&References)";
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "ALLOWED", ""); // @query-part-1
		EndIf;
		AttributesQueryText = StrConcat(TypesAttributes[Type], ",");
		QueryText = StrReplace(QueryText, "&Attributes", AttributesQueryText);
		QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
		ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
		QueryText = StrReplace(QueryText, "&References", "&" + ParameterName); // @query-part-1
		Query.SetParameter(ParameterName, RefsByType.Value);

		QueriesTexts.Add(QueryText);
	EndDo;
	
	AttributesNames = StrConcat(Attributes, ",");
	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF); // @query-part
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result = New Structure(AttributesNames);
		FillPropertyValues(Result, Selection);
		AttributesValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributesValues;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns parameter values for the current version of extensions.
// If not filled in, returns Undefined.
//
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//  
//  IgnoreExtensionsVersion - Boolean
//  
//  IsAlreadyModified - Boolean - 
//                 
//                 
//                 
//             - Undefined - 
//
// Returns:
//  Arbitrary - 
//                 
//
Function ExtensionParameter(ParameterName, IgnoreExtensionsVersion = False, IsAlreadyModified = Undefined) Export
	
	Return InformationRegisters.ExtensionVersionParameters.ExtensionParameter(ParameterName,
		IgnoreExtensionsVersion, IsAlreadyModified);
	
EndFunction

// Sets the storage value of the parameter for the current version of extensions.
// Used to fill in parameter values.
// You must set the privileged mode before calling.
//
// Parameters:
//  ParameterName - String -  maximum of 128 characters. For Example,
//                 " Standard Subsystems.Report variantss.Report with settings".
//
//  Value     - Arbitrary -  parameter value.
//  IgnoreExtensionsVersion - Boolean
//
Procedure SetExtensionParameter(ParameterName, Value, IgnoreExtensionsVersion = False) Export
	
	InformationRegisters.ExtensionVersionParameters.SetExtensionParameter(ParameterName, Value, IgnoreExtensionsVersion);
	
EndProcedure

// Handler for a routine task for deleting old parameters for working with extension Versions.
Procedure DeleteObsoleteExtensionsVersionsParametersJobHandler() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters);
	
	SetPrivilegedMode(True);
	Catalogs.ExtensionsVersions.DeleteObsoleteParametersVersions();
	
EndProcedure

// 
//
// 
// 
//
Procedure FillExtensionsOperationParameters() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.FillExtensionsOperationParameters);
	
	SetPrivilegedMode(True);
	InformationRegisters.ExtensionVersionParameters.FillinAllJobParametersLatestVersionExtensions();
	InformationRegisters.ExtensionProperties.DeletePropertiesOfDeletedExtensions();
	
EndProcedure

// For internal use only.
Procedure FillAllExtensionParametersBackgroundJob(Parameters) Export
	
	InformationRegisters.ExtensionVersionParameters.FillAllExtensionParametersBackgroundJob(Parameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Registers object changes on all nodes of the exchange plan.
// For split configurations, the following conditions must be met:
//  - the exchange plan must be divided,
//  - the registered object must be undivided.
//
//  Parameters:
//    Object         - CatalogObject
//                   - DocumentObject
//                   - BusinessProcessObject
//                   - TaskObject
//                   - ChartOfCalculationTypesObject
//                   - ChartOfCharacteristicTypesObject
//                   - ChartOfAccountsObject
//                   - ExchangePlanObject
//
//    ExchangePlanName - String -  name of the exchange plan to register the object on all nodes.
//                              The exchange plan must be split, otherwise an exception will be thrown.
//
//    IncludeMasterNode - Boolean -  if False, then the slave node
//                         will not register for the master node.
// 
//
Procedure RecordObjectChangesInAllNodes(Val Object, Val ExchangePlanName, Val IncludeMasterNode = True) Export
	
	If Metadata.ExchangePlans[ExchangePlanName].Content.Find(Object.Metadata()) = Undefined Then
		Return;
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SeparatedDataUsageAvailable() Then
			Raise NStr("en = 'Register changes of shared data in separated mode.';");
		EndIf;
		
		ModuleSaaSOperations = Undefined;
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		EndIf;
		
		If ModuleSaaSOperations <> Undefined Then
			IsSeparatedExchangePlan = ModuleSaaSOperations.IsSeparatedMetadataObject(
				"ExchangePlan." + ExchangePlanName, ModuleSaaSOperations.MainDataSeparator());
		Else
			IsSeparatedExchangePlan = False;
		EndIf;
		
		If Not IsSeparatedExchangePlan Then
			Raise NStr("en = 'Shared exchange plans don''t support registration of changes.';");
		EndIf;
		
		If ModuleSaaSOperations <> Undefined Then
			IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(
				Object.Metadata().FullName(), ModuleSaaSOperations.MainDataSeparator());
		Else
			IsSeparatedMetadataObject = False;
		EndIf;
		
		If IsSeparatedMetadataObject Then
				Raise NStr("en = 'Separated objects don''t support registration of changes.';");
		EndIf;
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	#ExchangePlanTable AS ExchangePlan
		|WHERE
		|	ExchangePlan.RegisterChanges
		|	AND NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		For Each Recipient In Recipients Do
			
			Object.DataExchange.Recipients.Add(Recipient);
			
		EndDo;
		
	Else
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Recipient
		|FROM
		|	#ExchangePlanTable AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Recipients = Query.Execute().Unload().UnloadColumn("Recipient");
		
		MasterNode = ExchangePlans.MasterNode();
		
		For Each Recipient In Recipients Do
			If Not IncludeMasterNode And Recipient = MasterNode Then
				Continue;
			EndIf;
			Object.DataExchange.Recipients.Add(Recipient);
		EndDo;
		
	EndIf;
	
EndProcedure

// Saves a reference to the master node in the main Node constant for recovery.
Procedure SaveMasterNode() Export
	
	MasterNodeManager = Constants.MasterNode.CreateValueManager();
	MasterNodeManager.Value = ExchangePlans.MasterNode();
	InfobaseUpdate.WriteData(MasterNodeManager);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
// 
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  InitialImageCreating - Boolean
//  Recipient - ExchangePlanObject
// 
Procedure OnSendDataToSlave(DataElement, ItemSend, Val InitialImageCreating, Val Recipient) Export
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// 
	IgnoreSendingMetadataObjectIDs(DataElement, ItemSend, InitialImageCreating);
	IgnoreSendingDataProcessedOnMasterDIBNodeOnInfobaseUpdate(DataElement, InitialImageCreating, Recipient);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// 
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnSendDataToRecipient(DataElement, ItemSend, InitialImageCreating, Recipient, False);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
	SSLSubsystemsIntegration.OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Recipient);
		
		If ItemSend = DataItemSend.Ignore Then
			Return;
		EndIf;
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataExportPercentage(Recipient, InitialImageCreating);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//  Sender - ExchangePlanObject
// 
Procedure OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Val Sender) Export
	
	// 
	IgnoreGettingMetadataObjectIDs(DataElement, ItemReceive);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	SSLSubsystemsIntegration.OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender);
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// 
	CommonOverridable.OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Sender);
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// 
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromSlaveInEnd(DataElement, ItemReceive, Sender);
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataImportPercentage(Sender);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// 
// Parameters:
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//  Sender - ExchangePlanObject
//
Procedure OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender = Undefined) Export
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	DataExchangeSubsystemExists1 = Common.SubsystemExists("StandardSubsystems.DataExchange");
	
	// 
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromMasterInBeginning(DataElement, ItemReceive, SendBack, Sender);
		
		If ItemReceive = DataItemReceive.Ignore Then
			Return;
		EndIf;
		
	EndIf;
	
	SSLSubsystemsIntegration.OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Sender);
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// 
	CommonOverridable.OnReceiveDataFromMaster(Sender, DataElement, ItemReceive, SendBack);
	
	// 
	If DataExchangeSubsystemExists1
		And Not InitialImageCreating(DataElement) Then
		
		ModuleDataExchangeEvents = Common.CommonModule("DataExchangeEvents");
		ModuleDataExchangeEvents.OnReceiveDataFromMasterInEnd(DataElement, ItemReceive, Sender);
		
	EndIf;
	
	If DataExchangeSubsystemExists1 Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataImportPercentage(Sender);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the type of reference or record key of the specified metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject -  case or reference object.
//
//  Returns:
//   Type
//
Function MetadataObjectReferenceOrMetadataObjectRecordKeyType(MetadataObject) Export
	
	If Common.IsRegister(MetadataObject) Then
		
		If Common.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf Common.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf Common.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf Common.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordKey." + MetadataObject.Name);
	Else
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Type = TypeOf(Manager.EmptyRef());
	EndIf;
	
	Return Type;
	
EndFunction

// Returns the type of object or record set of the specified metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject -  case or reference object.
//
//  Returns:
//   Type
//
Function MetadataObjectOrMetadataObjectRecordSetType(MetadataObject) Export
	
	If Common.IsRegister(MetadataObject) Then
		
		If Common.IsInformationRegister(MetadataObject) Then
			RegisterType = "InformationRegister";
			
		ElsIf Common.IsAccumulationRegister(MetadataObject) Then
			RegisterType = "AccumulationRegister";
			
		ElsIf Common.IsAccountingRegister(MetadataObject) Then
			RegisterType = "AccountingRegister";
			
		ElsIf Common.IsCalculationRegister(MetadataObject) Then
			RegisterType = "CalculationRegister";
		EndIf;
		Type = Type(RegisterType + "RecordSet." + MetadataObject.Name);
	Else
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		ObjectKind = Common.ObjectKindByType(TypeOf(Manager.EmptyRef()));
		Type = Type(ObjectKind + "Object." + MetadataObject.Name);
	EndIf;
	
	Return Type;
	
EndFunction

// Checks that the passed object is of the reference Object type.IDs of metadata objectsreferences.
//
// Parameters:
//  Object - Arbitrary
// 
// Returns:
//  Boolean
//
Function IsMetadataObjectID(Object) Export
	
	Return TypeOf(Object) = Type("CatalogObject.MetadataObjectIDs");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Sets the form assignment key (use assignment key and
// window position retention key). If necessary, copies the current form settings,
// if they have not yet been recorded for the corresponding new key.
//
// Parameters:
//  Form - ClientApplicationForm -  form Precontamination is attached to the key.
//  Var_Key  - String -  a new key assignment form.
//  LocationKey - String
//  SetSettings - Boolean -  set the settings saved for the current key to the new key.
//
Procedure SetFormAssignmentKey(Form, Var_Key, LocationKey = "", SetSettings = True) Export
	
	SetFormAssignmentUsageKey(Form, Var_Key, SetSettings);
	SetFormWindowOptionsSaveKey(Form, ?(LocationKey = "", Var_Key, LocationKey), SetSettings);
	
EndProcedure

Procedure ResetWindowLocationAndSize(Form) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	FormName = Form.FormName;
	NewKeyForSavingTheWindowPosition = StrReplace(String(New UUID), "-", "_");
	StorageObjectKey = FormName + "/TemporaryKeysForSavingTheWindowPosition";
	UserName = UserName();
	BegOfDay = BegOfDay(CurrentUniversalDate());
	TheBoundaryOfObsolescence = BegOfDay - 2*24*60*60;
	
	Keys = SystemSettingsStorage.Load(StorageObjectKey);
	
	If TypeOf(Keys) = Type("Map") Then
		SettingsNames = New Array;
		SettingsNames.Add("/ThinClientWindowSettings");
		SettingsNames.Add("/Taxi/ThinClientWindowSettings");
		SettingsNames.Add("/WebClientWindowSettings");
		SettingsNames.Add("/MobileClientWindowSettings");
		SettingsNames.Add("/Taxi/WebClientWindowSettings");
		SettingsNames.Add("/Taxi/MobileClientWindowSettings");
		CurrentKeys = New Map(New FixedMap(Keys));
		For Each KeyAndValue In CurrentKeys Do
			CurrentDay = KeyAndValue.Key;
			If TypeOf(CurrentDay) <> Type("Date") Then
				Keys = Undefined;
				Break;
			EndIf;
			If CurrentDay > TheBoundaryOfObsolescence Then
				Continue;
			EndIf;
			KeysOfTheCurrentDay = KeyAndValue.Value;
			If TypeOf(KeysOfTheCurrentDay) <> Type("Array") Then
				Keys = Undefined;
				Break;
			EndIf;
			For Each CurrentKey In KeysOfTheCurrentDay Do
				TheBeginningOfTheObjectKey = FormName + "/" + CurrentKey;
				For Each SettingName In SettingsNames Do
					SystemSettingsStorage.Delete(TheBeginningOfTheObjectKey + SettingName, "", UserName);
				EndDo;
			EndDo;
			Keys.Delete(CurrentDay);
		EndDo;
	EndIf;
	
	ClearOldKeys = TypeOf(Keys) <> Type("Map");
	If ClearOldKeys Then
		Keys = New Map;
	EndIf;
	
	KeysOfTheDay = Keys.Get(BegOfDay);
	If TypeOf(KeysOfTheDay) <> Type("Array") Then
		KeysOfTheDay = New Array;
		Keys.Insert(BegOfDay, KeysOfTheDay);
	EndIf;
	KeysOfTheDay.Add(NewKeyForSavingTheWindowPosition);
	SystemSettingsStorage.Save(StorageObjectKey,, Keys);
	
	Form.WindowOptionsKey = NewKeyForSavingTheWindowPosition;
	
	If Not ClearOldKeys Then
		Return;
	EndIf;
	
	Filter = New Structure("User", UserName);
	Selection = SystemSettingsStorage.Select(Filter);
	KeySearchRussian = "НастройкиОкнаТонкогоКлиента"; // @Non-NLS
	SearchKeyEnglish = "ThinClientWindowSettings";
	While True Do
		Try
			ThereIsAnotherOne = Selection.Next();
		Except
			ErrorInfo = ErrorInfo();
			WriteLogEvent(
				NStr("en = 'Runtime error';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo));
			Break;
		EndTry;
		If Not ThereIsAnotherOne Then
			Break;
		EndIf;
		If Not StrStartsWith(Selection.ObjectKey, FormName)
		 Or Selection.SettingsKey <> ""
		 Or Selection.ObjectKey = StorageObjectKey Then
			Continue;
		EndIf;
		ObjectKeyParts1 = StrSplit(Selection.ObjectKey, "/");
		If ObjectKeyParts1.Count() < 2 Then
			Continue;
		EndIf;
		TheLastPartOfTheKey = ObjectKeyParts1[ObjectKeyParts1.UBound()];
		If StrFind(TheLastPartOfTheKey, KeySearchRussian) > 0
		 Or StrFind(TheLastPartOfTheKey, SearchKeyEnglish) > 0 Then
			SystemSettingsStorage.Delete(Selection.ObjectKey, "", UserName);
		EndIf;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns callouts when there are problems with the program parameters.
// 
// Returns:
//  String
//
Function ApplicationRunParameterErrorClarificationForDeveloper() Export
	
	Return Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString( 
		NStr("en = 'Perhaps, some service data requires an update.
			|Do one of the following:
			| • Run external data processor
			|""Development tools: Service data update.""
			| • Run the app with command-line option:
			|/C %1.
			| • Update the app to a later version.
			|The data update procedures will start automatically at launch.';"),
		"StartInfobaseUpdate");
	
EndFunction

// Returns the current user of the information database.
// 
// Returns:
//  InfoBaseUser
//
Function CurrentUser() Export
	
	// 
	// 
	// 
	CurrentUser = InfoBaseUsers.FindByUUID(
		InfoBaseUsers.CurrentUser().UUID);
	
	If CurrentUser = Undefined Then
		CurrentUser = InfoBaseUsers.CurrentUser();
	EndIf;
	
	Return CurrentUser;
	
EndFunction

// Converts a string to a valid column name in the table of values, replacing invalid
// characters with the character code limited to an underscore.
//
// Parameters:
//  String - String -  string to convert.
// 
// Returns:
//  String - 
//
Function TransformStringToValidColumnDescription(String) Export
	
	InvalidChars = ":;!@#$%^&-~`'.,?{}[]+=*/|\ ()_""";
	Result = "";
	For IndexOf = 1 To StrLen(String) Do
		Char =  Mid(String, IndexOf, 1);
		If StrFind(InvalidChars, Char) > 0 Or (CharCode(Char) > 126 And CharCode(Char) < 256) Then
			Result = Result + "_" + CharCode(Char) + "_";
		Else
			Result = Result + Char;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Convert an adapted column name in which invalid
// characters are replaced with the code of a character limited by an underscore to a regular string.
//
// Parameters:
//  ColumnDescription - String -  adapted the name column.
// 
// Returns:
//  String - 
//
Function TransformAdaptedColumnDescriptionToString(ColumnDescription) Export
	
	Result = "";
	For IndexOf = 1 To StrLen(ColumnDescription) Do
		Char = Mid(ColumnDescription, IndexOf, 1);
		If Char = "_" Then
			ClosingCharacterPosition = StrFind(ColumnDescription, "_", SearchDirection.FromBegin, IndexOf + 1);
			CharCode = Mid(ColumnDescription, IndexOf + 1, ClosingCharacterPosition - IndexOf - 1);
			Result = Result + Char(CharCode);
			IndexOf = ClosingCharacterPosition;
		Else
			Result = Result + Char;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Generates information necessary for notifying the client of open forms and dynamic lists
// about mass changes to objects that occurred on the server.
//
// Parameters:
//   ModifiedObjects - AnyRef
//                     - Type
//                     - Array - 
//                       
//                       
//
// Returns:
//   Map of KeyAndValue:
//     * Key - Type -  for example, a document link.Customer's order.
//     * Value - Structure:
//        ** EventName - String -  for example, "Supistaminen".
//        ** EmptyRef - AnyRef
// 
Function PrepareFormChangeNotification(ModifiedObjects) Export
	
	Result = New Map;
	If ModifiedObjects = Undefined Then
		Return Result;
	EndIf;
	
	TypesArray = New Array;
	RefOrTypeOrArrayType = TypeOf(ModifiedObjects);
	If RefOrTypeOrArrayType = Type("Array") Then
		For Each Item In ModifiedObjects Do
			ElementType = TypeOf(Item);
			If ElementType = Type("Type") Then
				ElementType = Item;
			EndIf;
			If TypesArray.Find(ElementType) = Undefined Then
				TypesArray.Add(ElementType);
			EndIf;
		EndDo;
	Else
		TypesArray.Add(ModifiedObjects);
	EndIf;
	
	For Each ElementType In TypesArray Do
		MetadataObject = Metadata.FindByType(ElementType);
		If TypeOf(MetadataObject) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		EventName = "Record_" + MetadataObject.Name;
		Try
			EmptyRef = PredefinedValue(MetadataObject.FullName() + ".EmptyRef");
		Except
			EmptyRef = Undefined;
		EndTry;
		Result.Insert(ElementType, New Structure("EventName,EmptyRef", EventName, EmptyRef));
	EndDo;
	Return Result;
	
EndFunction

// Sets the overall shape Pasteurisation on the Desk with a blank composition forms.
//
// To display the split desktop correctly in the web client
// , the undivided desktop must have a non-empty form set, and Vice versa.
//
Procedure SetBlankFormOnBlankHomePage() Export
	
	ObjectKey = "Common/HomePageSettings";
	
	CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	If CurrentSettings = Undefined Then
		CurrentSettings = New HomePageSettings;
	EndIf;
	
	CurrentFormComposition = CurrentSettings.GetForms();
	
	If CurrentFormComposition.LeftColumn.Count() = 0
	   And CurrentFormComposition.RightColumn.Count() = 0 Then
		
		CurrentFormComposition.LeftColumn.Add("CommonForm.BlankHomePage");
		CurrentSettings.SetForms(CurrentFormComposition);
		SystemSettingsStorage.Save(ObjectKey, "", CurrentSettings);
	EndIf;
	
EndProcedure

// Checks whether the current user can view the list of documents.
//
// Parameters:
//  DocumentsList - Array -  documents for verification.
//
// Returns:
//  Boolean - 
//
Function HasRightToPost(DocumentsList) Export
	DocumentTypes = New Array;
	For Each Document In DocumentsList Do
		DocumentType = TypeOf(Document);
		If DocumentTypes.Find(DocumentType) <> Undefined Then
			Continue;
		Else
			DocumentTypes.Add(DocumentType);
		EndIf;
		If AccessRight("Posting", Metadata.FindByType(DocumentType)) Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

// Checks that the passed table is a register.
// 
// Parameters:
//  TableName - String -  full name of the table.
// 
// Returns:
//  Boolean 
//
Function IsRegisterTable(TableName) Export
	InRegTableName = Upper(TableName);
	If StrStartsWith(InRegTableName, Upper("InformationRegister"))
		Or StrStartsWith(InRegTableName, Upper("AccumulationRegister"))
		Or StrStartsWith(InRegTableName, Upper("AccountingRegister"))
		Or StrStartsWith(InRegTableName, Upper("CalculationRegister")) Then
		Return True;
	EndIf;
	
	Return False;
EndFunction

// Returns a view of the home page.
//
// Returns:
//   String
//
Function HomePagePresentation() Export 
	
	Return NStr("en = 'Main';");
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.MetadataObjectIDs.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
	// 
	TableRow = CatalogsToImport.Find(Metadata.Catalogs.ExtensionObjectIDs.FullName(), "FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;
	
EndProcedure

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.MetadataObjectIDs.FullName(), "AttributesToEditInBatchProcessing");
	Objects.Insert(Metadata.Catalogs.ExtensionObjectIDs.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.SafeDataStorage.Dimensions.Owner);
	RefSearchExclusions.Add(Metadata.InformationRegisters.SafeDataAreaDataStorage.Dimensions.Owner);
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	AddClientRunParameters(Parameters);
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	// FunctionalOptionsModified
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.Core.FunctionalOptionsModified");
	
	Notification.NotificationSendModuleName  = "StandardSubsystemsServer";
	Notification.NotificationReceiptModuleName = "StandardSubsystemsClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
	// CachedValuesOutdated
	Notification = ServerNotifications.NewServerNotification(
		"StandardSubsystems.Core.CachedValuesOutdated");
	
	Notification.NotificationReceiptModuleName = "StandardSubsystemsClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

// See ExportImportDataOverridable.OnFillCommonDataTypesSupportingRefMappingOnExport.
Procedure OnFillCommonDataTypesSupportingRefMappingOnExport(Types) Export
	
	Types.Add(Metadata.Catalogs.MetadataObjectIDs);
	
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.Constants.InfobasePublicationURL);
	Types.Add(Metadata.Constants.LocalInfobasePublishingURL);
	Types.Add(Metadata.Constants.InfoBaseID);
	Types.Add(Metadata.Constants.DeliverServerNotificationsWithoutCollaborationSystem);
	Types.Add(Metadata.Constants.RegisterServerNotificationsIndicators);
	ModuleExportImportData = Common.CommonModule("ExportImportData");
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.ExtensionsVersions,
		ModuleExportImportData.ActionWithLinksDoNotChange());
	ModuleExportImportData.AddTypeExcludedFromUploadingUploads(Types,
		Metadata.Catalogs.ExtensionObjectIDs,
		ModuleExportImportData.ActionWithLinksDoNotChange());
	Types.Add(Metadata.InformationRegisters.SafeDataAreaDataStorage);
	Types.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs);
	Types.Add(Metadata.InformationRegisters.ExtensionVersionParameters);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions = New Array();
	
	Permissions.Add(ModuleSafeModeManager.PermissionToUseTempDirectory(True, True,
		NStr("en = 'Basic permissions required to run the app.';")));
	Permissions.Add(ModuleSafeModeManager.PermissionToUsePrivilegedMode());
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
	AddRequestForPermissionToUseExtensions(PermissionsRequests);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	Id = "DynamicApplicationUpdateControl";
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = Id;
	ToDoItem.HasToDoItems      = DataBaseConfigurationChangedDynamically()
	                     Or Catalogs.ExtensionsVersions.ExtensionsChangedDynamically();
	ToDoItem.Important        = False;
	ToDoItem.Presentation = NStr("en = 'Application update installed';");
	ToDoItem.Form         = "CommonForm.DynamicUpdateControl";
	ToDoItem.Owner      = NStr("en = 'Application performance';");
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If ModuleToDoListServer.UserTaskDisabled("SpeedupRecommendation") Then
		Return;
	EndIf;
	
	Id = "SpeedupRecommendation";
	ToDoItem = ToDoList.Add();
	ToDoItem.Id = Id;
	ToDoItem.HasToDoItems      = MustShowRAMSizeRecommendations();
	ToDoItem.Important        = True;
	ToDoItem.Presentation = NStr("en = 'Application performance degraded';");
	ToDoItem.Form         = "DataProcessor.SpeedupRecommendation.Form";
	ToDoItem.Owner      = NStr("en = 'Application performance';");
	
EndProcedure

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// 
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.SystemAdministrator.Name);
	
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.Administration.Name);
	
	RolesAssignment.ForSystemAdministratorsOnly.Add(
		Metadata.Roles.UpdateDataBaseConfiguration.Name);
	
	// 
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartThickClient.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartExternalConnection.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.StartAutomation.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.TechnicianMode.Name);
	
	RolesAssignment.ForSystemUsersOnly.Add(
		Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors.Name);
	
	// 
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles.BasicAccessExternalUserSSL.Name);
	
	// 
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartThinClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartWebClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.StartMobileClient.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.OutputToPrinterFileClipboard.Name);
	
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles.SaveUserData.Name);
	
EndProcedure

// See JobsQueueOverridable.OnGetTemplateList.
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters.Name);
	JobTemplates.Add(Metadata.ScheduledJobs.FillExtensionsOperationParameters.Name);
	
EndProcedure

// See ExportImportDataOverridable.AfterImportData.
Procedure AfterImportData(Container) Export
	
	// 
	InformationRegisters.ExtensionVersionParameters.EnableFillingExtensionsWorkParameters(False, True);
	If Common.DataSeparationEnabled() Then
		InformationRegisters.ExtensionVersionParameters.StartFillingWorkParametersExtensions(
			NStr("en = 'Start and wait after importing area data';"),
			True);
	EndIf;
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.SetConstantDoNotUseSeparationByDataAreas";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExclusiveMode = True;
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "StandardSubsystemsServer.MarkVersionCacheRecordsObsolete";
	Handler.Priority = 99;
	Handler.SharedData = True;
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "InfobaseUpdateInternal.InitialFillingOfPredefinedData";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.7.149";
	Handler.Procedure = "StandardSubsystemsServer.EnableConstantToDeliverServerAlertsWithoutInteractionSystem";
	Handler.SharedData = True;
	Handler.InitialFilling = True;
	Handler.ExecutionMode = "Seamless";
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export

	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.IntegrationServicesProcessing;
	Dependence.UseExternalResources = True;
	
EndProcedure

// See SSLSubsystemsIntegration.OnDefineObjectsToExcludeFromCheck
Procedure OnDefineObjectsToExcludeFromCheck(Objects) Export
	Objects.Add(Metadata.InformationRegisters.ExtensionVersionObjectIDs);
EndProcedure

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	ParameterName = "StandardSubsystems.Core.DynamicUpdateControl";
	CheckParameters = Parameters.Get(ParameterName);
	If CheckParameters = Undefined Then
		Return;
	EndIf;
	
	// ConfigurationOrExtensionsWasModified
	UserMessage = Undefined;
	ConfigurationOrExtensionModifiedDuringRepeatedCheck(UserMessage);
	If UserMessage = Undefined Then
		Return;
	EndIf;
	
	Results.Insert(ParameterName, UserMessage);
	
EndProcedure

// See UsersOverridable.OnGetOtherSettings.
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	CurrentSchedule = Common.SystemSettingsStorageLoad("DynamicUpdateControl",
		"PatchCheckSchedule",,,
		UserInfo.InfobaseUserName);
	If CurrentSchedule <> Undefined Then
		SettingProperties = New Structure;
		SettingProperties.Insert("SettingName1", NStr("en = 'Schedule to check for new patches';"));
		SettingProperties.Insert("PictureSettings", PictureLib.Calendar);
		SettingProperties.Insert("SettingsList", New ValueList);
		SettingProperties.SettingsList.Add(CurrentSchedule);
		Settings.Insert("PatchCheckSchedule", SettingProperties);
	EndIf;
	
EndProcedure

// See UsersOverridable.OnSaveOtherSetings.
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	If Settings.SettingID = "PatchCheckSchedule" Then
		If Settings.SettingValue.Count() = 1 Then
			Schedule = Settings.SettingValue[0].Value;
			
			Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule",
				Schedule,,
				UserInfo.InfobaseUserName);
		EndIf;
	EndIf;
	
EndProcedure

// See UsersOverridable.OnDeleteOtherSettings.
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	If Settings.SettingID = "PatchCheckSchedule" Then
		Common.SystemSettingsStorageDelete("DynamicUpdateControl",
			"PatchCheckSchedule",
			UserInfo.InfobaseUserName);
	EndIf;
	
EndProcedure

// Generates text to display to the user when dynamic updates are required.
// 
// Parameters:
//  DynamicConfigurationChanges - See Catalogs.ExtensionsVersions.DynamicallyChangedExtensions
//  
// Returns:
//  String 
//
Function MessageTextOnDynamicUpdate(DynamicConfigurationChanges) Export
	
	Messages = New Array;
	
	If DynamicConfigurationChanges.DataBaseConfigurationChangedDynamically Then
		MessageTextConfiguration = NStr("en = 'The application is updated (the infobase configuration is modified).';");
		Messages.Add(MessageTextConfiguration);
	EndIf;
	
	If DynamicConfigurationChanges.Corrections <> Undefined Then
		If DynamicConfigurationChanges.Corrections.Added2 > 0
			And DynamicConfigurationChanges.Corrections.Deleted > 0 Then
			MessageTextPatches = NStr("en = 'New patches: %1, deleted: %2.';");
		ElsIf DynamicConfigurationChanges.Corrections.Added2 = 1 Then
			MessageTextPatches = NStr("en = 'New patch.';");
		ElsIf DynamicConfigurationChanges.Corrections.Added2 > 0 Then
			MessageTextPatches = NStr("en = 'New patches: %1.';");
		ElsIf DynamicConfigurationChanges.Corrections.Deleted > 0 Then
			MessageTextPatches = NStr("en = 'Patches deleted: %2.';");
		EndIf;
		MessageTextPatches = StringFunctionsClientServer.SubstituteParametersToString(MessageTextPatches,
			DynamicConfigurationChanges.Corrections.Added2,
			DynamicConfigurationChanges.Corrections.Deleted);
		Messages.Add(MessageTextPatches);
	EndIf;
	
	If DynamicConfigurationChanges.Extensions <> Undefined Then
		If DynamicConfigurationChanges.Extensions.Added2 > 0 Then
			MessageTextExtensions = NStr("en = 'New extensions: %1.';");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.Added2);
			Messages.Add(MessageTextExtensions);
		EndIf;
		
		If DynamicConfigurationChanges.Extensions.Deleted > 0 Then
			MessageTextExtensions = NStr("en = 'Extensions deleted: %1.';");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.Deleted);
			Messages.Add(MessageTextExtensions);
		EndIf;
		
		If DynamicConfigurationChanges.Extensions.IsChanged > 0 Then
			MessageTextExtensions = NStr("en = 'Extensions modified: %1.';");
			MessageTextExtensions = StringFunctionsClientServer.SubstituteParametersToString(MessageTextExtensions,
				DynamicConfigurationChanges.Extensions.IsChanged);
			Messages.Add(MessageTextExtensions);
		EndIf;
	EndIf;
		
	Return StrConcat(Messages, Chars.LF);
	
EndFunction

// Defines the format for saving to PDF, depending on the platform used.
// 
// Returns:
//  SpreadsheetDocumentFileType
//
Function TableDocumentFileTypePDF() Export
	
	Return SpreadsheetDocumentFileType["PDF_A_3"];
	
EndFunction

// Defines a custom representation of the PDF save format, depending on the platform used.
// 
// Returns:
//  String
//
Function FileTypeRepresentationOfATabularPDFDocument() Export
	
	Return NStr("en = 'PDF/A document (.pdf)';");
	
EndFunction

Function ConfigurationLanguages() Export
	
	Languages = New Array;
	For Each Language In Metadata.Languages Do
		Languages.Add(Language.LanguageCode);
	EndDo;
	
	Return Languages;
	
EndFunction

// Parameters:
//  Headers - Map - see the syntax assistant for a description of the Headers parameter of the NTTROVET object.
// 
// Returns:
//  Map
//
Function HTTPHeadersInLowercase(Headers) Export
	
	Result = New Map;
	For Each Title In Headers Do
		Result.Insert(Lower(Title.Key), Title.Value);
	EndDo;
	Return Result;
	
EndFunction

// Parameters:
//  Id - String -  ID of the component.
//  Location - String -  the location of the component layout (without specifying the version).
//  AddIn - Undefined
//                    - Structure - :
//                       * Id - String -  id of the component in the directory.
//                       * Version - String -  version.
//                       * Location - String -  location.
//                       * Available - Boolean -  the availability criterion.
//
// Returns:
//  Structure:
//   * Id - String -  id of the component in the directory.
//   * Location - String -  the layout of the component, the address of the link in the directory.
//   * Version - String -  version.
//
Function TheComponentOfTheLatestVersion(Id, Location, AddIn = Undefined) Export
		
	TheComponentOfTheLatestVersion = New Structure;
	TheComponentOfTheLatestVersion.Insert("Id", Id);
	TheComponentOfTheLatestVersion.Insert("Location", "");
	TheComponentOfTheLatestVersion.Insert("Version", "");
	
	// 
	If AddIn <> Undefined And AddIn.Available Then
		TheLatestVersionOfTheExternalComponent = New Structure("Version, Location", 
			AddIn.Version, AddIn.Location);
	Else
		TheLatestVersionOfTheExternalComponent = Undefined;
	EndIf;
	
	// 
	If ValueIsFilled(Location) Then
		TheLatestVersionOfComponentsFromTheLayout = StandardSubsystemsCached.TheLatestVersionOfComponentsFromTheLayout(
			Location);
	Else
		TheLatestVersionOfComponentsFromTheLayout = Undefined;
	EndIf;
	
	If TheLatestVersionOfTheExternalComponent <> Undefined And TheLatestVersionOfComponentsFromTheLayout <> Undefined Then
		
		If StringFunctionsClientServer.OnlyNumbersInString(StrReplace(TheLatestVersionOfTheExternalComponent.Version, ".",
			"")) Then
			VersionParts = StrSplit(TheLatestVersionOfTheExternalComponent.Version, ".");
			If VersionParts.Count() = 4 And CommonClientServer.CompareVersions(
				TheLatestVersionOfTheExternalComponent.Version, TheLatestVersionOfComponentsFromTheLayout.Version) <= 0 Then
				FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfComponentsFromTheLayout);
				Return TheComponentOfTheLatestVersion;
			EndIf;
		EndIf;
		
		// 
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfTheExternalComponent);
		Return TheComponentOfTheLatestVersion;
		
	ElsIf TheLatestVersionOfComponentsFromTheLayout <> Undefined Then
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfComponentsFromTheLayout);
		Return TheComponentOfTheLatestVersion;
	ElsIf TheLatestVersionOfTheExternalComponent <> Undefined Then
		FillPropertyValues(TheComponentOfTheLatestVersion, TheLatestVersionOfTheExternalComponent);
		Return TheComponentOfTheLatestVersion;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Add-in with ID %1 does not exist';"), Id);
	
EndFunction

// Returns:
//  String -  
//
Function TechnicalInfoOnExtensionsAndSubsystemsVersions() Export
	
	SubsystemsDetails = Common.SubsystemsDetails();
	
	TechnicalInfoOnExtensionsAndSubsystemsVersions = NStr("en = 'Subsystem versions';") + ":" + Chars.LF;
	For Each SubsystemDetails In SubsystemsDetails Do
		TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions
			+ SubsystemDetails.Name + " - "
			+ SubsystemDetails.Version + Chars.LF;
	EndDo;
		
	TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions + Chars.LF;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Extensions = ConfigurationExtensions.Get();
	For Each Extension In Extensions Do
		
		TechnicalInfoOnExtensionsAndSubsystemsVersions = TechnicalInfoOnExtensionsAndSubsystemsVersions
			+ Extension.Name + " - " + Extension.Synonym + " - "
			+ Format(Extension.Active, NStr("en = 'BF=Disabled; BT=Enabled';")) + Chars.LF;
		
	EndDo;
	
	Return TechnicalInfoOnExtensionsAndSubsystemsVersions;
	
EndFunction

#EndRegion

#Region Private

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed
// information database.
//
// Parameters:
//   see the description of the event handler sent to the main() in the syntax assistant.
// 
Procedure OnSendDataToMaster(DataElement, ItemSend, Val Recipient)
	
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	// 
	IgnoreSendingMetadataObjectIDs(DataElement, ItemSend);
	If ItemSend = DataItemSend.Ignore Then
		Return;
	EndIf;
	
	SSLSubsystemsIntegration.OnSendDataToMaster(DataElement, ItemSend, Recipient);
	
	// 
	CommonOverridable.OnSendDataToMaster(DataElement, ItemSend, Recipient);
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		ModuleDataExchangeServer.CalculateDIBDataExportPercentage(Recipient, False);
	EndIf;
	
EndProcedure

// Fills in the structure of parameters required for the client code
// of this subsystem to work when running the configuration, i.e. in event handlers.
// - Before the system operation starts,
// - At the beginning of the system's work.
//
// Important: you can't use commands to reset the cache
// of reusable modules when starting, otherwise starting may lead
// to unpredictable errors and unnecessary server calls.
//
// Parameters:
//   Parameters   - Structure -  structure of parameters.
//
// Returns:
//   Boolean   - 
//
Function AddClientParametersOnStart(Parameters) Export
	
	IsCallBeforeStart = Parameters.RetrievedClientParameters <> Undefined;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
	Else
		IsSeparatedConfiguration = False;
	EndIf;
	
	// 
	Parameters.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());
	Parameters.Insert("SeparatedDataUsageAvailable", 
		Common.SeparatedDataUsageAvailable());
	Parameters.Insert("IsSeparatedConfiguration", IsSeparatedConfiguration);
	// 
	Parameters.Insert("HasAccessForUpdatingPlatformVersion", Users.IsFullUser(,True));
	
	Parameters.Insert("SubsystemsNames", StandardSubsystemsCached.SubsystemsNames());
	Parameters.Insert("IsBaseConfigurationVersion", IsBaseConfigurationVersion());
	Parameters.Insert("IsTrainingPlatform", IsTrainingPlatform());
	Parameters.Insert("UserCurrentName", CurrentUser().Name);
	// 
	Parameters.Insert("COMConnectorName", CommonClientServer.COMConnectorName());
	Parameters.Insert("DefaultLanguageCode", Common.DefaultLanguageCode());
	
	UserSettings = ErrorProcessing.GetUserSettings();
	Parameters.Insert("ErrorInfoSendingSettings",
		New Structure("SendOutMode, SendOutAddress",
			UserSettings.SendReport,
			UserSettings.ErrorProcessingServiceAddress));
	
	Parameters.Insert("AskConfirmationOnExit", AskConfirmationOnExit());
	
	CommonParameters = Common.CommonCoreParameters();
	Parameters.Insert("MinPlatformVersion",   CommonParameters.MinPlatformVersion);
	Parameters.Insert("RecommendedPlatformVersion", CommonParameters.RecommendedPlatformVersion);
	// 
	Parameters.Insert("MinPlatformVersion1", CommonParameters.MinPlatformVersion1);
	Parameters.Insert("MustExit",            CommonParameters.MustExit);
	
	Parameters.Insert("RecommendedRAM", CommonParameters.RecommendedRAM);
	Parameters.Insert("MustShowRAMSizeRecommendations", MustShowRAMSizeRecommendations()
		And Not Common.SubsystemExists("StandardSubsystems.ToDoList"));
	
	Parameters.Insert("IsExternalUserSession", Users.IsExternalUserSession());
	Parameters.Insert("IsFullUser",  Users.IsFullUser());
	Parameters.Insert("IsSystemAdministrator",      Users.IsFullUser(, True));
	Parameters.Insert("FileInfobase",   Common.FileInfobase());
	
	If InvalidPlatformVersionUsed() Then
		Parameters.Insert("InvalidPlatformVersionUsed");
	EndIf;
	
	If IsCallBeforeStart Then
		Parameters.Insert("StyleItems", StyleElementsSet());
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("InterfaceOptions") Then
		Parameters.Insert("InterfaceOptions", StandardSubsystemsCached.InterfaceOptions());
	EndIf;
	
	If IsCallBeforeStart Then
		ErrorInsufficientRightsForAuthorization = UsersInternal.ErrorInsufficientRightsForAuthorization(
			Not Parameters.RetrievedClientParameters.Property("ErrorInsufficientRightsForAuthorization"));
		
		If ValueIsFilled(ErrorInsufficientRightsForAuthorization) Then
			Parameters.Insert("ErrorInsufficientRightsForAuthorization", ErrorInsufficientRightsForAuthorization);
			Return False;
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		
		ModuleWorkLockWithExternalResources = Common.CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.OnAddClientParametersOnStart(
			Parameters, IsCallBeforeStart);
		
		If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
			Parameters.Insert("OperationsWithExternalResourcesLocked");
		EndIf;
		
	EndIf;
	
	If Not InfobaseUpdateInternal.AddClientParametersOnStart(Parameters)
	   And IsCallBeforeStart Then
		Return False;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ShowDeprecatedPlatformVersion")
	   And ShowDeprecatedPlatformVersion(Parameters) Then
		
		Parameters.Insert("ShowDeprecatedPlatformVersion");
		StandardSubsystemsServerCall.HideDesktopOnStart();
		Return False;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ReconnectMasterNode")
	   And Not Common.DataSeparationEnabled() Then
	   
		SetPrivilegedMode(True);
		ReconnectMasterNode = ExchangePlans.MasterNode() = Undefined
			And ValueIsFilled(Constants.MasterNode.Get());
		SetPrivilegedMode(False);
	   
		If ReconnectMasterNode Then 
			Parameters.Insert("ReconnectMasterNode", Users.IsFullUser(, True));
			StandardSubsystemsServerCall.HideDesktopOnStart();
			Return False;
		EndIf;
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ServerNotifications") Then
		
		ServerNotifications.OnAddClientParametersOnStart(Parameters);
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("SelectInitialRegionalIBSettings")
	   And RegionalInfobaseSettingsRequired() Then
		
		Parameters.Insert("SelectInitialRegionalIBSettings",
			Users.IsFullUser(, True, False));
		StandardSubsystemsServerCall.HideDesktopOnStart();
		Return False;
	EndIf;
	
	If IsCallBeforeStart And Common.SubsystemExists("CloudTechnology") Then
		
		ErrorDescription = "";
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		ModuleSaaSOperations.OnCheckDataAreaLockOnStart(ErrorDescription);
		If Not IsBlankString(ErrorDescription) Then
			Parameters.Insert("DataAreaLocked", ErrorDescription);
			// 
			Return False;
		EndIf;
		
	EndIf;
	
	If SessionParameters.IBUpdateInProgress <> Undefined // 
		And Not Parameters.DataSeparationEnabled
		And InfobaseUpdate.InfobaseUpdateRequired()
		And InfobaseUpdateInternal.UncompletedHandlersStatus(True) = "UncompletedStatus" Then
		Parameters.Insert("MustRunDeferredUpdateHandlers");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		ModuleSafeModeManagerInternal.OnAddClientParametersOnStart(Parameters, True);
	EndIf;
	
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("RetryDataExchangeMessageImportBeforeStart")
	   And Common.IsSubordinateDIBNode()
	   And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ModuleDataExchangeInternal = Common.CommonModule("DataExchangeInternal");
		If ModuleDataExchangeInternal.RetryDataExchangeMessageImportBeforeStart() Then
			Parameters.Insert("RetryDataExchangeMessageImportBeforeStart");
			Return False;
		EndIf;
	EndIf;
	
	// 
	If IsCallBeforeStart
	   And Not Parameters.RetrievedClientParameters.Property("ApplicationParametersUpdateRequired")
	   And Not Parameters.Property("SimplifiedInfobaseUpdateForm") Then
		
		SubordinateDIBNodeSetup = False;
		If InformationRegisters.ApplicationRuntimeParameters.UpdateRequired1(SubordinateDIBNodeSetup) Then
			// 
			Parameters.Insert("ApplicationParametersUpdateRequired");
			
			If SubordinateDIBNodeSetup
			   And Common.FileInfobase() Then
				
				ErrorTemplate =
					NStr("en = 'Cannot enable exclusive mode to set up the distributed infobase node. Reason:
					           |%1';");
				EnableExclusiveModeAtStartup(True, ErrorTemplate);
			EndIf;
			Return False;
		EndIf;
	EndIf;
	
	// 
	Parameters.Insert("DetailedInformation", Metadata.DetailedInformation);
	
	If InfobaseUpdateInternal.SharedInfobaseDataUpdateRequired() Then
		Parameters.Insert("SharedInfobaseDataUpdateRequired");
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		ModuleSafeModeManagerInternal.OnAddClientParametersOnStart(Parameters);
	EndIf;
	
	If Not Parameters.SeparatedDataUsageAvailable Then
		Return True;
	EndIf;
	
	// 
	// 
	
	If InfobaseUpdate.InfobaseUpdateRequired() Then
		Parameters.Insert("InfobaseUpdateRequired");
		StandardSubsystemsServerCall.HideDesktopOnStart();
	EndIf;
	
	If Not Parameters.DataSeparationEnabled
		And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		If ModuleDataExchangeServer.LoadDataExchangeMessage() Then
			Parameters.Insert("LoadDataExchangeMessage");
		EndIf;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		If ModuleStandaloneMode.ContinueStandaloneWorkstationSetup(Parameters) Then
			Return False;
		EndIf;
	EndIf;
	
	Cancel = False;
	If IsCallBeforeStart Then
		UsersInternal.OnAddClientParametersOnStart(Parameters, Cancel, True);
	EndIf;
	If Cancel Then
		Return False;
	EndIf;
	
	AddCommonClientParameters(Parameters);
	
	If IsCallBeforeStart
	   And (Parameters.Property("InfobaseUpdateRequired")
	      Or InfobaseUpdate.InfobaseUpdateInProgress()) Then
		// 
		// 
		Return False;
	EndIf;
	
	EnableExclusiveModeAtStartup(False);
	
	Return True;
	
EndFunction

// Fills in the structure of parameters required for the client code
// of this subsystem. 
//
// Parameters:
//   Parameters - Structure
//
Procedure AddClientRunParameters(Parameters)
	
	Parameters.Insert("SubsystemsNames", StandardSubsystemsCached.SubsystemsNames());
	Parameters.Insert("SeparatedDataUsageAvailable",
		Common.SeparatedDataUsageAvailable());
	Parameters.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());
	
	// 
	Parameters.Insert("IsBaseConfigurationVersion", IsBaseConfigurationVersion());
	// 
	Parameters.Insert("IsTrainingPlatform", IsTrainingPlatform());
	// 
	Parameters.Insert("COMConnectorName", CommonClientServer.COMConnectorName());
	Parameters.Insert("StyleItems", StyleElementsSet());
	
	AddCommonClientParameters(Parameters);
	
	Parameters.Insert("ConfigurationName",     Metadata.Name);
	Parameters.Insert("ConfigurationSynonym", Metadata.Synonym);
	Parameters.Insert("ConfigurationVersion",  Metadata.Version);
	Parameters.Insert("DetailedInformation", Metadata.DetailedInformation);
	Parameters.Insert("DefaultLanguageCode",   Common.DefaultLanguageCode());
	
	Parameters.Insert("AskConfirmationOnExit",
		AskConfirmationOnExit());
	
	Parameters.Insert("FileInfobase", Common.FileInfobase());
	
	If ScheduledJobsServer.OperationsWithExternalResourcesLocked() Then
		Parameters.Insert("OperationsWithExternalResourcesLocked");
	EndIf;
	
	Parameters.Insert("CompatibilityModeVersion", CompatibilityModeVersion());
	
EndProcedure

// Fills in the structure of parameters required for the client code
// to work when starting the configuration and later while working with it. 
//
// Parameters:
//   Parameters   - Structure -  structure of parameters.
//
Procedure AddCommonClientParameters(Parameters)
	
	If Not Parameters.DataSeparationEnabled Or Parameters.SeparatedDataUsageAvailable Then
		
		SetPrivilegedMode(True);
		Parameters.Insert("AuthorizedUser", Users.AuthorizedUser());
		Parameters.Insert("ApplicationCaption", TrimAll(Constants.SystemTitle.Get()));
		SetPrivilegedMode(False);
		
	EndIf;
	
	Parameters.Insert("IsMasterNode1", Not Common.IsSubordinateDIBNode());
	
	Parameters.Insert("DIBNodeConfigurationUpdateRequired",
		Common.SubordinateDIBNodeConfigurationUpdateRequired());
	
EndProcedure

// Returns the version numbers supported by the program interface interface Name.
// See Common.GetInterfaceVersionsViaExternalConnection.
//
// Parameters:
//   InterfaceName - String -  name of the program interface.
//
// Returns:
//  Array - 
//
Function SupportedVersions(InterfaceName) Export
	
	VersionsArray = Undefined;
	SupportedVersionsStructure = New Structure;
	
	SSLSubsystemsIntegration.OnDefineSupportedInterfaceVersions(SupportedVersionsStructure);
	SupportedVersionsStructure.Property(InterfaceName, VersionsArray);
	
	If VersionsArray = Undefined Then
		Return Common.ValueToXMLString(New Array);
	Else
		Return Common.ValueToXMLString(VersionsArray);
	EndIf;
	
EndFunction

// Sets the General empty workbench Form to the desktop.
Procedure SetBlankFormOnHomePage() Export
	
	ObjectKey = "Common/HomePageSettings";
	CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	
	If TypeOf(CurrentSettings) = Type("HomePageSettings") Then
		CurrentFormComposition = CurrentSettings.GetForms();
		If CurrentFormComposition.RightColumn.Count() = 0
		   And CurrentFormComposition.LeftColumn.Count() = 1
		   And CurrentFormComposition.LeftColumn[0] = "CommonForm.BlankHomePage" Then
			Return;
		EndIf;
	EndIf;
	
	FormContent = New HomePageForms;
	FormContent.LeftColumn.Add("CommonForm.BlankHomePage");
	Settings = New HomePageSettings;
	Settings.SetForms(FormContent);
	SystemSettingsStorage.Save(ObjectKey, "", Settings);
	
EndProcedure

// Parameters:
//  Set - Boolean
//  ErrorTemplate - String
//
Procedure EnableExclusiveModeAtStartup(Set, ErrorTemplate = "")
	
	If Set And ExclusiveMode() Then
		Return;
	EndIf;
	
	ParameterName = "IsExclusiveModeEnabledAtStartup";
	
	SetPrivilegedMode(True);
	If Set Then
		Try
			SetExclusiveMode(True);
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Raise ErrorText;
		EndTry;
		
		CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
		CurrentParameters.Insert(ParameterName, True);
		SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
		
	ElsIf SessionParameters.ClientParametersAtServer.Get(ParameterName) <> Undefined Then
		
		If ExclusiveMode() Then
			SetExclusiveMode(False);
		EndIf;
		
		CurrentParameters = New Map(SessionParameters.ClientParametersAtServer);
		CurrentParameters.Insert(ParameterName, True);
		SessionParameters.ClientParametersAtServer = New FixedMap(CurrentParameters);
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

// Handler of the same-named routine task.
//
Procedure IntegrationServicesProcessing() Export
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.IntegrationServicesProcessing);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	IntegrationServices.ExecuteProcessing();
EndProcedure

// Parameters:
//  UserName - String
//
// Returns:
//  Boolean
//
Function ShowWarningAboutInstalledUpdatesForUser(UserName = Undefined)
	
	Result = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"ShowInstalledApplicationUpdatesWarning",,,
		UserName);
	
	If Result = Undefined Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
//
Procedure SetConstantDoNotUseSeparationByDataAreas(Parameters) Export
	
	NewValues = New Map;
	If Constants.UseSeparationByDataAreas.Get() Then
		NewValues.Insert("NotUseSeparationByDataAreas", False);
		NewValues.Insert("StandardSubsystemsStandaloneMode", False);
	ElsIf Common.IsStandaloneWorkplace() Then
		NewValues.Insert("NotUseSeparationByDataAreas", False);
		NewValues.Insert("StandardSubsystemsStandaloneMode", True);
	Else
		NewValues.Insert("NotUseSeparationByDataAreas", True);
		NewValues.Insert("StandardSubsystemsStandaloneMode", False);
	EndIf;
	
	ThisDataExchangeInServiceModel = Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS");
	For Each NewValue In NewValues Do
		
		If ThisDataExchangeInServiceModel 
			And NewValue.Key = "StandardSubsystemsStandaloneMode" Then
			PreviousValue = Common.IsStandaloneWorkplace();
			//  
			Constants[NewValue.Key].Set(NewValue.Value); 
		Else
			PreviousValue = Constants[NewValue.Key].Get();
		EndIf;
		
		If PreviousValue <> NewValue.Value Then
				
			If Not Parameters.ExclusiveMode Then
				Parameters.ExclusiveMode = True;
				Return; // 
			EndIf;
				
			Constants[NewValue.Key].Set(NewValue.Value);
			
			If ThisDataExchangeInServiceModel
				And NewValue.Key = "StandardSubsystemsStandaloneMode" 
				And PreviousValue Then
				ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
				ModuleStandaloneMode.DisablePropertyIB();
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Resets the update date of all version cache entries,
// so all cache entries are considered outdated.
//
Procedure MarkVersionCacheRecordsObsolete() Export
	
	BeginTransaction();
	Try
		RecordSet = InformationRegisters.ProgramInterfaceCache.CreateRecordSet();
		
		Block = New DataLock;
		Block.Add("InformationRegister.ProgramInterfaceCache");
		Block.Lock();
		
		RecordSet.Read();
		For Each Record In RecordSet Do
			Record.UpdateDate = Undefined;
		EndDo;
		
		InfobaseUpdate.WriteData(RecordSet);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure EnableConstantToDeliverServerAlertsWithoutInteractionSystem() Export
	
	Constants.DeliverServerNotificationsWithoutCollaborationSystem.Set(True);
	
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	OldName = "Role.BasicAccess";
	NewName  = "Role.BasicAccessSSL";
	Common.AddRenaming(Total, "3.0.1.19", OldName, NewName, Library);
	
	OldName = "Role.BasicAccessExternalUser";
	NewName  = "Role.BasicAccessExternalUserSSL";
	Common.AddRenaming(Total, "3.0.1.19", OldName, NewName, Library);
	
	OldName = "Role.AllFunctionsMode";
	NewName  = "Role.TechnicianMode";
	Common.AddRenaming(Total, "3.1.5.153", OldName, NewName, Library);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Event handler Before recording predefined elements.
//
Procedure ProcessPredefinedItemsBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ThisIsPredefinedData(Source) Then
		Return;
	EndIf;
	
	DenySettingDeletionMarksToPredefinedItemsBeforeWrite(Source);
	
	InfobaseUpdateInternal.DetermineModifiedAttributesInPredefinedItems(Source);
	
EndProcedure

// Event handler Before recording predefined elements.
//
Procedure DenySettingDeletionMarksToPredefinedItemsBeforeWrite(Source)
	
	If Source.DeletionMark <> True Then
		Return;
	EndIf;
	
	AttributeName = "";
	AttributeValue = "";
	If Not ThisIsPredefinedData(Source, AttributeName, AttributeValue) Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Raise
			NStr("en = 'Cannot create a predefined item that is marked for deletion.';");
	EndIf;
	
	PreviousProperties = Common.ObjectAttributesValues(Source.Ref, 
		"DeletionMark, PredefinedDataName" 
			+ ?(AttributeName <> "PredefinedDataName", ", " + AttributeName, ""));
	
	If (PreviousProperties.PredefinedDataName <> "" Or AttributeName <> "" And ValueIsFilled(PreviousProperties[AttributeName]))
	   And PreviousProperties.DeletionMark <> True And Not IsOwnerMarkedForDeletion(Source.Ref) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot mark the predefined item for deletion:
			           |""%1.""';"),
			String(Source.Ref));
	ElsIf (ValueIsFilled(AttributeValue) And Not ValueIsFilled(PreviousProperties[AttributeName])
	      Or PreviousProperties.PredefinedDataName = "")
	        And PreviousProperties.DeletionMark = True Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot map a predefined item name to an item marked for deletion:
			           |""%1.""';"),
			String(Source.Ref));
	EndIf;
	
EndProcedure

// Event handler Before deleting predefined elements.
Procedure DenyPredefinedItemDeletionBeforeDelete(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not ThisIsPredefinedData(Source) Then
		Return;
	EndIf;
	
	AttributesValues = New Structure("Owner");
	FillPropertyValues(AttributesValues, Source);
	
	If ValueIsFilled(AttributesValues.Owner) Then
		OwnerDetailsValues = New Structure("DeletionMark");
		OwnerDeletionMark = Common.ObjectAttributeValue(AttributesValues.Owner, "DeletionMark");
		If OwnerDeletionMark <> False Then // 
			Return;
		EndIf;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Cannot delete the predefined item 
			|""%1.""';"),
		String(Source.Ref));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
// 
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  InitialImageCreating - Boolean
// 
Procedure OnSendDataToSubordinateEvent(Source, DataElement, ItemSend, InitialImageCreating) Export
	
	OnSendDataToSlave(DataElement, ItemSend, InitialImageCreating, Source);
	
	If ItemSend <> DataItemSend.Ignore Then
		// 
		CommonOverridable.OnSendDataToSlave(Source, DataElement, ItemSend, InitialImageCreating);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemSend - DataItemSend
//  
Procedure OnSendDataToMasterEvent(Source, DataElement, ItemSend) Export
	
	OnSendDataToMaster(DataElement, ItemSend, Source);
	
	If ItemSend <> DataItemSend.Ignore Then
		// 
		CommonOverridable.OnSendDataToMaster(Source, DataElement, ItemSend);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
// 
Procedure OnReceiveDataFromSubordinateEvent(Source, DataElement, ItemReceive, SendBack) Export
	
	OnReceiveDataFromSlave(DataElement, ItemReceive, SendBack, Source);
	
	If ItemReceive <> DataItemReceive.Ignore Then
		// 
		CommonOverridable.OnReceiveDataFromSlave(Source, DataElement, ItemReceive, SendBack);
	EndIf;
	
EndProcedure

// 
// 
// 
// 
// Parameters:
//  Source - ExchangePlanObject
//  DataElement - Arbitrary
//  ItemReceive - DataItemReceive
//  SendBack - Boolean
//
Procedure OnReceiveDataFromMasterEvent(Source, DataElement, ItemReceive, SendBack) Export
	
	OnReceiveDataFromMaster(DataElement, ItemReceive, SendBack, Source);
	
	If ItemReceive <> DataItemReceive.Ignore Then
		// 
		CommonOverridable.OnReceiveDataFromMaster(Source, DataElement, ItemReceive, SendBack);
	EndIf;
	
EndProcedure

// Procedure-handler for subscribing to the pre-Record event for the Planobmenaobject.
// Used to call the handler for the event after data Is received when exchanging data in a distributed information system.
// 
// Parameters:
//  Source - ExchangePlanObject
//  Cancel - Boolean
//
Procedure AfterGetData(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Source.Metadata().DistributedInfoBase Then
		Return;
	EndIf;
	
	If Source.IsNew()
		Or Source.ReceivedNo = Common.ObjectAttributeValue(Source.Ref, "ReceivedNo") Then
		Return;
	EndIf;
	
	GetFromMasterNode = (ExchangePlans.MasterNode() = Source.Ref);
	SSLSubsystemsIntegration.AfterGetData(Source, Cancel, GetFromMasterNode);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//  Array of MetadataObject
//
Function MetadataObjectsOfAllPredefinedData()
	
	DataSeparationEnabled  = Common.DataSeparationEnabled();
	IsSeparatedSession = Common.SeparatedDataUsageAvailable();
	
	MetadataCollections = New Array;
	MetadataCollections.Add(Metadata.Catalogs);
	MetadataCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataCollections.Add(Metadata.ChartsOfAccounts);
	MetadataCollections.Add(Metadata.ChartsOfCalculationTypes);
	
	MetadataObjects = New Array;
	
	For Each Collection In MetadataCollections Do
		For Each MetadataObject In Collection Do
			
			If DataSeparationEnabled Then 
				
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
				
				If (   IsSeparatedSession And Not IsSeparatedMetadataObject)
				 Or (Not IsSeparatedSession And    IsSeparatedMetadataObject) Then 
					Continue;
				EndIf;
				
			EndIf;
			
			MetadataObjects.Add(MetadataObject);
		EndDo;
	EndDo;
	
	Return MetadataObjects;
	
EndFunction

Procedure SetAllPredefinedDataInitialization(MetadataObjects)
	
	DataSeparationEnabled  = Common.DataSeparationEnabled();
	IsSeparatedSession = Common.SeparatedDataUsageAvailable();
	
	For Each MetadataObject In MetadataObjects Do
		Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
		Manager.SetPredefinedDataInitialization(True);
	EndDo;
	
	If Not DataSeparationEnabled Or Not IsSeparatedSession Then 
		SetInfoBasePredefinedDataUpdate(PredefinedDataUpdate.Auto);
	EndIf;
	
EndProcedure

Procedure CreateMissingPredefinedData(MetadataObjects)
	
	Query = New Query;
	QueryText =
		"SELECT
		|	SpecifiedTableAlias.Ref AS Ref,
		|	SpecifiedTableAlias.DataVersion AS DataVersion,
		|	ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """") AS ParentName,
		|	SpecifiedTableAlias.PredefinedDataName AS Name
		|FROM
		|	&CurrentTable AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Predefined";
	
	SavedItemsDescriptions = New Array;
	TablesWithoutSavedData = New Array;
	For Each MetadataObject In MetadataObjects Do
		
		If MetadataObject.PredefinedDataUpdate
				= Metadata.ObjectProperties.PredefinedDataUpdate.DontAutoUpdate Then
			Continue;
		EndIf;
		
		FullName = MetadataObject.FullName();
		Query.Text = StrReplace(QueryText, "&CurrentTable", FullName);
		
		If Metadata.ChartsOfAccounts.Contains(MetadataObject)
		 Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
		 Or Not MetadataObject.Hierarchical Then
			
			Query.Text = StrReplace(Query.Text,
				"ISNULL(SpecifiedTableAlias.Parent.PredefinedDataName, """")", """""");
		EndIf;
		
		// 
		// 
		NameTable = Query.Execute().Unload();
		// 
		NameTable.Indexes.Add("Name");
		Names = MetadataObject.GetPredefinedNames();
		SaveExistingPredefinedObjectsBeforeCreateMissingOnes(MetadataObject,
			FullName, NameTable, Names, Query, SavedItemsDescriptions, TablesWithoutSavedData);
	EndDo;
	
	// 
	For Each SavedItemsDescription In SavedItemsDescriptions Do
		Manager = Common.ObjectManagerByFullName(SavedItemsDescription.FullName);
		Manager.SetPredefinedDataInitialization(False);
		InitializePredefinedData();
		
		Query.Text = SavedItemsDescription.QueryText;
		// 
		// 
		NameTable = Query.Execute().Unload();
		// 
		NameTable.Indexes.Add("Name");
		For Each SavedItemDescription In SavedItemsDescription.NameTable Do
			If Not SavedItemDescription.ObjectExist Then
				Continue;
			EndIf;
			String = NameTable.Find(SavedItemDescription.Name, "Name");
			If String <> Undefined Then
				NewObject = String.Ref.GetObject();
				If SavedItemsDescription.IsChartOfAccounts Then
					If SavedItemDescription.Object.DataVersion <> String.DataVersion Then
						UpdateTheInvoiceObject(SavedItemDescription.Object);
					EndIf;
					AddNewExtraAccountDimensionTypes(SavedItemDescription.Object, NewObject);
				EndIf;
				// 
				InfobaseUpdate.DeleteData(NewObject);
				// 
				String.Name = "";
			EndIf;
			// 
			InfobaseUpdate.WriteData(SavedItemDescription.Object);
			// 
		EndDo;
		For Each TableRow In NameTable Do
			If Not ValueIsFilled(TableRow.Name)
			 Or Not ValueIsFilled(TableRow.ParentName) Then
				Continue;
			EndIf;
			ParentLevelRow = DetailsOfSavedObject(SavedItemsDescription.NameTable, TableRow.ParentName);
			If ParentLevelRow <> Undefined Then
				NewObject = TableRow.Ref.GetObject();
				NewObject.Parent = ParentLevelRow.Ref;
				// 
				InfobaseUpdate.WriteData(NewObject);
				// 
			EndIf;
		EndDo;
	EndDo;
	
	For Each FullName In TablesWithoutSavedData Do
		Manager = Common.ObjectManagerByFullName(FullName);
		Manager.SetPredefinedDataInitialization(False);
	EndDo;
	
	InitializePredefinedData();
	
EndProcedure

// Returns:
//  ValueTableRow:
//    * Ref - CatalogRef,
//             - ChartOfCharacteristicTypesRef
//             - ChartOfAccountsRef
//             - ChartOfCalculationTypesRef
//    * Name - String
//    * DataVersion- String
//    * ParentName - String
//    * Object - CatalogObject
//             - ChartOfCharacteristicTypesObject
//             - ChartOfAccountsObject
//             - ChartOfCalculationTypesObject
//    * ObjectExist - Boolean
//  Undefined
//
Function DetailsOfSavedObject(NameTable, ParentName)
	Return NameTable.Find(ParentName, "Name");
EndFunction

// Parameters:
//  OldObject - ChartOfAccountsObject
//
Procedure UpdateTheInvoiceObject(OldObject)
	
	NewObject = OldObject.Ref.GetObject();
	NewObject.PredefinedDataName = OldObject.PredefinedDataName;
	For Each ExtraDimensionKindRow In OldObject.ExtDimensionTypes Do
		If ExtraDimensionKindRow.Predefined Then
			NewLineIExtDimensionType = NewObject.ExtDimensionTypes.Find(
				ExtraDimensionKindRow.ExtDimensionType, "ExtDimensionType");
			If NewLineIExtDimensionType <> Undefined Then
				NewLineIExtDimensionType.Predefined = True;
			EndIf;
		EndIf;
	EndDo;
	
	OldObject = NewObject;
	
EndProcedure

// Parameters:
//  Account - ChartOfAccountsObject
//  SampleAccount - ChartOfAccountsObject
// 
Procedure AddNewExtraAccountDimensionTypes(Account, SampleAccount)
	
	For Each ExtDimensionType In SampleAccount.ExtDimensionTypes Do
		IndexOf = SampleAccount.ExtDimensionTypes.IndexOf(ExtDimensionType);
		If Account.ExtDimensionTypes.Count() > IndexOf Then
			If Account.ExtDimensionTypes[IndexOf].ExtDimensionType <> ExtDimensionType.ExtDimensionType Then
				WriteLogEvent(
					NStr("en = 'Data exchange.Disconnection from the master node';", Common.DefaultLanguageCode()),
					EventLogLevel.Error,
					Account.Metadata(),
					Account,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'The extra dimension #%2 ""%3"" in chart of accounts ""%1"" does not match the predefined extra dimension ""%4.""';"),
						String(Account),
						IndexOf + 1,
						String(Account.ExtDimensionTypes[IndexOf].ExtDimensionType),
						String(ExtDimensionType.ExtDimensionType)),
					EventLogEntryTransactionMode.Transactional);
			ElsIf Not Account.ExtDimensionTypes[IndexOf].Predefined Then
				Account.ExtDimensionTypes[IndexOf].Predefined = True;
			EndIf;
		Else
			FillPropertyValues(Account.ExtDimensionTypes.Add(), ExtDimensionType);
		EndIf;
	EndDo;
	
EndProcedure

Procedure SaveExistingPredefinedObjectsBeforeCreateMissingOnes(
		MetadataObject, FullName, NameTable, Names, Query, SavedItemsDescriptions, TablesWithoutSavedData)
	
	InitializationRequired = False;
	PredefinedItemsExist = False;
	NameTable.Columns.Add("ObjectExist", New TypeDescription("Boolean"));
	
	For Each Name In Names Do
		TableRows = NameTable.FindRows(New Structure("Name", Name));
		If TableRows.Count() = 0 Then
			InitializationRequired = True;
		Else
			For Each TableRow In TableRows Do
				TableRow.ObjectExist = True;
			EndDo;
			PredefinedItemsExist = True;
		EndIf;
	EndDo;
	
	If Not InitializationRequired Then
		Return;
	EndIf;
	
	If PredefinedItemsExist Then
		IsChartOfAccounts = Metadata.ChartsOfAccounts.Contains(MetadataObject);
		SavedItemsDescription = New Structure;
		SavedItemsDescription.Insert("FullName",     FullName);
		SavedItemsDescription.Insert("QueryText",  Query.Text);
		SavedItemsDescription.Insert("NameTable",   NameTable);
		SavedItemsDescription.Insert("IsChartOfAccounts", IsChartOfAccounts);
		SavedItemsDescriptions.Add(SavedItemsDescription);
		
		NameTable.Columns.Add("Object");
		For Each TableRow In NameTable Do
			Object = TableRow.Ref.GetObject();
			Object.PredefinedDataName = "";
			If IsChartOfAccounts Then
				PredefinedExtraDimensionKindRows = New Array;
				For Each ExtraDimensionKindRow In Object.ExtDimensionTypes Do
					If ExtraDimensionKindRow.Predefined Then
						ExtraDimensionKindRow.Predefined = False;
						PredefinedExtraDimensionKindRows.Add(ExtraDimensionKindRow);
					EndIf;
				EndDo;
			EndIf;
			// 
			InfobaseUpdate.WriteData(Object);
			// 
			If IsChartOfAccounts Then
				For Each ExtraDimensionKindRow In PredefinedExtraDimensionKindRows Do
					ExtraDimensionKindRow.Predefined = True;
				EndDo;
			EndIf;
			If TableRow.ObjectExist Then
				Object.PredefinedDataName = TableRow.Name;
			EndIf;
			TableRow.Object = Object;
		EndDo;
	Else
		TablesWithoutSavedData.Add(FullName);
	EndIf;
	
EndProcedure

Procedure BeforeStartApplication()
	
	// 
	
	If TimeConsumingOperations.ShouldSkipHandlerBeforeAppStartup() Then
		Return;
	EndIf;
	
	// 
	CurrentLanguageOf1CEnterpriseLanguage = Metadata.ObjectProperties.ScriptVariant["English"];
	If Metadata.ScriptVariant <> CurrentLanguageOf1CEnterpriseLanguage Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The built-in configuration language option ""%1"" is not supported.
			           |Use language option ""%2"" instead.';"),
			Metadata.ScriptVariant,
			Metadata.ObjectProperties.ScriptVariant["English"]);
	EndIf;
	
	// 
	SystemInfo = New SystemInfo;
	CurrentPlatformVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	MinPlatformVersion = Min1CEnterpriseVersionForStart();
	
	AssemblyNumbers = StrSplit(MinPlatformVersion, "; ", False);
	MinBuildNumberForCurrent1CEnterpriseVersion = AssemblyNumbers[AssemblyNumbers.UBound()];
	
	For Each BuildNumber In AssemblyNumbers Do
		If StrStartsWith(BuildNumber, CurrentPlatformVersion + ".") Then
			MinBuildNumberForCurrent1CEnterpriseVersion = BuildNumber;
			Break;
		EndIf;
	EndDo;
	
	If CommonClientServer.CompareVersions(SystemInfo.AppVersion, 
		MinBuildNumberForCurrent1CEnterpriseVersion) < 0 Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The application requires 1C:Enterprise version %1 or later.';"), 
			MinBuildNumberForCurrent1CEnterpriseVersion);
	EndIf;
	
	// 
	MinPlatformVersions = Min1CEnterpriseVersionForUse();
	MinPlatformVersion = MinPlatformVersions[MinPlatformVersions.Count() - 1].Value;
	CompatibilityModeVersion = Common.CompatibilityModeVersion();
	
	If MinPlatformVersions.FindByValue(CompatibilityModeVersion) = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Configuration compatibility mode ""Version %1"" is not supported. 
			           |To start the application, set the compatibility mode to ""None"" (on 1C:Enterprise version %2)
			           | or to ""Version %2"" (on a later 1C:Enterprise version).';"),
			CompatibilityModeVersion, MinPlatformVersion);
	EndIf;
	
	// 
	If IsBlankString(Metadata.Version) Then
		Raise NStr("en = 'The Version configuration property is blank.';");
	EndIf;

	Try
		ZeroVersion = CommonClientServer.CompareVersions(Metadata.Version, "0.0.0.0") = 0;
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The Version configuration property has invalid value: %1.
						|Use the following format: 1.2.3.45.';"),
			Metadata.Version);
	EndTry;
	If ZeroVersion Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The Version configuration property has invalid value: %1.
						|The version cannot be zero.';"),
			Metadata.Version);
	EndIf;
	
	If Not Metadata.DefaultRoles.Contains(Metadata.Roles.SystemAdministrator)
		Or Not Metadata.DefaultRoles.Contains(Metadata.Roles.FullAccess) Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Standard roles %2 and %3 are not specified in property %1 in the configuration.';"),
			"DefaultRoles", Metadata.Roles.SystemAdministrator.Name, Metadata.Roles.FullAccess.Name);
	EndIf;
	
	// 
	CheckIfCanStart();
	
	If Not ValueIsFilled(InfoBaseUsers.CurrentUser().Name)
	   And (Not Common.DataSeparationEnabled()
	      Or Not Common.SeparatedDataUsageAvailable())
	   And InfobaseUpdateInternal.IBVersion("StandardSubsystems",
	       Common.DataSeparationEnabled()) = "0.0.0.0" Then
		
		UsersInternal.SetInitialSettings("");
	EndIf;
	
	SSLSubsystemsIntegration.BeforeStartApplication();
	CommonOverridable.BeforeStartApplication();
	
	CorrectSharedUserHomePage();
	HandleCopiedSettingsQueue();
	
EndProcedure

// 
// 
// 
// 
// 
// Returns:
//  String - 
//
Function Min1CEnterpriseVersionForStart() Export
	
	Return "8.3.21.1622; 8.3.22.1704"; // 
	
EndFunction

//  
// 
// 
// 
// 
//
// Returns:
//  ValueList:
//   * Value      - String - 
//   * Presentation - String - 
//
Function Min1CEnterpriseVersionForUse() Export
	
	// 
	Versions = New ValueList;
	Versions.Add("8.3.21", "8.3.21.1775; 8.3.22.1923");
	Versions.Add("8.3.22", "8.3.22.2355; 8.3.23.2011; 8.3.24.1548; 8.3.25.1286");
	Versions.Add("8.3.23", "8.3.23.2011; 8.3.24.1548; 8.3.25.1286");
	Versions.Add("8.3.24", "8.3.24.1548; 8.3.25.1286");
	
	Return Versions;
	
EndFunction

// 
//  
// 
//
Function SecureSoftwareSystemVersions() Export  // 
	
	Versions = New Array;
	Versions.Add("8.3.21.1676");
	Versions.Add("8.3.21.1901");
	Versions.Add("8.3.24.1440");
	Versions.Add("8.3.24.1599");
	
	Return Versions;

EndFunction

// 
// 
//
Function ReplacementVersionForRevoked1CEnterprise(CurrentBuild) Export
	
	If StrFind("8.3.22.1672,8.3.22.1603", CurrentBuild) Then
		Return "8.3.22.1709";
		
	ElsIf StrFind("8.3.21.1607,8.3.21.1508,8.3.21.1484", CurrentBuild) Then
		Return "8.3.21.1624";
		
	EndIf;
	
	Return "";
	
EndFunction

// For the procedure before starting the Program.
Procedure CorrectSharedUserHomePage()
	
	If CurrentRunMode() = Undefined
	 Or Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = False;
	EndIf;
	
	If Not SessionWithoutSeparators Then
		Return;
	EndIf;
	
	ObjectKey  = "Core";
	SettingsKey = "MetadataHomePageFormComposition";
	
	PreviousFormCompositionInMetadata = CommonSettingsStorage.Load(ObjectKey, SettingsKey);
	If PreviousFormCompositionInMetadata = Undefined Then
		// 
		SetBlankFormOnHomePage();
	Else
		SetBlankFormOnBlankHomePage();
	EndIf;
	
	// 
	NewSettings1 = New HomePageSettings;
	FormCompositionInMetadata = NewSettings1.GetForms();
	
	If TypeOf(PreviousFormCompositionInMetadata) <> Type("Structure")
	 Or Not PreviousFormCompositionInMetadata.Property("LeftColumn")
	 Or TypeOf(PreviousFormCompositionInMetadata.LeftColumn) <> Type("Array")
	 Or Not PreviousFormCompositionInMetadata.Property("RightColumn")
	 Or TypeOf(PreviousFormCompositionInMetadata.RightColumn) <> Type("Array") Then
		
		PreviousFormCompositionInMetadata = New HomePageForms;
		
	ElsIf FormCompositionMatches(PreviousFormCompositionInMetadata.LeftColumn,  FormCompositionInMetadata.LeftColumn)
	        And FormCompositionMatches(PreviousFormCompositionInMetadata.RightColumn, FormCompositionInMetadata.RightColumn) Then
		
		// 
		Return;
	EndIf;
	
	CompensateChangesOfFormCompositionInHomePageMetadata(PreviousFormCompositionInMetadata);
	
	SavedFormCompositionInMetadata = New Structure("LeftColumn, RightColumn");
	FillPropertyValues(SavedFormCompositionInMetadata, FormCompositionInMetadata);
	
	CommonSettingsStorage.Save(ObjectKey, SettingsKey, SavedFormCompositionInMetadata);
	
EndProcedure

// For the procedure, adjust the initial page of the user's account.
Function FormCompositionMatches(PreviousFormsInMetadata, FormsInMetadata)
	
	If PreviousFormsInMetadata.Count() <> FormsInMetadata.Count() Then
		Return False;
	EndIf;
	
	For Each FormName In FormsInMetadata Do
		If PreviousFormsInMetadata.Find(FormName) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

// For the procedure, adjust the initial page of the user's account.
Procedure CompensateChangesOfFormCompositionInHomePageMetadata(PreviousFormCompositionInMetadata)
	
	// 
	// 
	
	ObjectKey         = "Common/HomePageSettings";
	StorageObjectKey = "Common/HomePageSettingsBeforeClear";
	SavedSettings = SystemSettingsStorage.Load(StorageObjectKey, "");
	SettingsSaved   = TypeOf(SavedSettings) = Type("ValueStorage");
	
	If SettingsSaved Then
		CurrentSettings = SavedSettings.Get();
	Else
		CurrentSettings = SystemSettingsStorage.Load(ObjectKey);
	EndIf;
	If TypeOf(CurrentSettings) = Type("HomePageSettings") Then
		FormContent = CurrentSettings.GetForms();
	Else
		FormContent = New HomePageForms;
	EndIf;
	
	NewSettings1 = New HomePageSettings;
	FormCompositionInMetadata = NewSettings1.GetForms();
	
	DeleteNewHomePageForms(FormContent.LeftColumn,
		PreviousFormCompositionInMetadata.LeftColumn, FormCompositionInMetadata.LeftColumn);
	
	DeleteNewHomePageForms(FormContent.RightColumn,
		PreviousFormCompositionInMetadata.RightColumn, FormCompositionInMetadata.RightColumn);
	
	CurrentSettings = New HomePageSettings;
	CurrentSettings.SetForms(FormContent);
	
	If SettingsSaved Then
		SavingSettings = New ValueStorage(CurrentSettings);
		SystemSettingsStorage.Save(StorageObjectKey, "", SavingSettings);
		SetBlankFormOnHomePage();
	Else
		SystemSettingsStorage.Save(ObjectKey, "", CurrentSettings);
	EndIf;
	
EndProcedure

// For the procedure to compensate for changes in the composition of the formmetadannyinternational Page.
Procedure DeleteNewHomePageForms(CurrentForms, PreviousFormsInMetadata, FormsInMetadata)
	
	For Each FormName In FormsInMetadata Do
		If PreviousFormsInMetadata.Find(FormName) <> Undefined Then
			Continue;
		EndIf;
		IndexOf = CurrentForms.Find(FormName);
		If IndexOf <> Undefined Then
			CurrentForms.Delete(IndexOf);
		EndIf;
	EndDo;
	
EndProcedure

Procedure HandleCopiedSettingsQueue()
	
	If CurrentRunMode() = Undefined Then
		Return;
	EndIf;
	
	SettingsQueue = CommonSettingsStorage.Load("SettingsQueue", "NotAppliedSettings");
	If TypeOf(SettingsQueue) <> Type("ValueStorage") Then
		Return;
	EndIf;
	SettingsQueue = SettingsQueue.Get();
	If TypeOf(SettingsQueue) <> Type("Map") Then
		Return;
	EndIf;
	
	For Each QueueItem In SettingsQueue Do
		Try
			Setting = SystemSettingsStorage.Load(QueueItem.Key, QueueItem.Value);
		Except
			Continue;
		EndTry;
		SystemSettingsStorage.Save(QueueItem.Key, QueueItem.Value, Setting);
	EndDo;
	
	CommonSettingsStorage.Save("SettingsQueue", "NotAppliedSettings", Undefined);
	
EndProcedure

Procedure ExecuteSessionParameterSettingHandlers(SessionParametersNames, Handlers, SpecifiedParameters)
	
	// 
	// 
	SessionParameterKeys = New Array;
	
	For Each Record In Handlers Do
		If StrFind(Record.Key, "*") > 0 Then
			ParameterKey = TrimAll(Record.Key);
			SessionParameterKeys.Add(Left(ParameterKey, StrLen(ParameterKey)-1));
		EndIf;
	EndDo;
	
	For Each ParameterName In SessionParametersNames Do
		If SpecifiedParameters.Find(ParameterName) <> Undefined Then
			Continue;
		EndIf;
		
		Handler = Handlers.Get(ParameterName);
		If Handler <> Undefined Then
			HandlerParameters = New Array();
			HandlerParameters.Add(ParameterName);
			HandlerParameters.Add(SpecifiedParameters);
			Common.ExecuteConfigurationMethod(Handler, HandlerParameters);
			Continue;
		EndIf;
		
		For Each ParameterKeyName In SessionParameterKeys Do
			If StrStartsWith(ParameterName, ParameterKeyName) Then
				Handler = Handlers.Get(ParameterKeyName + "*");
				HandlerParameters = New Array();
				HandlerParameters.Add(ParameterName);
				HandlerParameters.Add(SpecifiedParameters);
				Common.ExecuteConfigurationMethod(Handler, HandlerParameters);
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure IgnoreSendingMetadataObjectIDs(DataElement, ItemSend, Val InitialImageCreating = False)
	
	If Not InitialImageCreating
		And MetadataObject(DataElement) = Metadata.Catalogs.MetadataObjectIDs Then
		
		ItemSend = DataItemSend.Ignore;
		
	EndIf;
	
EndProcedure

Procedure IgnoreGettingMetadataObjectIDs(DataElement, ItemReceive)
	
	If MetadataObject(DataElement) = Metadata.Catalogs.MetadataObjectIDs Then
		ItemReceive = DataItemReceive.Ignore;
	EndIf;
	
EndProcedure

Function MetadataObject(Val DataElement)
	
	Return ?(TypeOf(DataElement) = Type("ObjectDeletion"), DataElement.Ref.Metadata(), DataElement.Metadata());
	
EndFunction

Function InitialImageCreating(Val DataElement)
	
	Return ?(TypeOf(DataElement) = Type("ObjectDeletion"), False, DataElement.AdditionalProperties.Property("InitialImageCreating"));
	
EndFunction

Function ShowDeprecatedPlatformVersion(Parameters)
	
	If Parameters.DataSeparationEnabled Then
		Return False;
	EndIf;
	
	// 
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("IBUserID",
		InfoBaseUsers.CurrentUser().UUID);
	
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExternalUsers AS ExternalUsers
	|WHERE
	|	ExternalUsers.IBUserID = &IBUserID";
	
	If Not Query.Execute().IsEmpty() Then
		Return False;
	EndIf;
	
	SystemInfo = New SystemInfo;
	Current       = SystemInfo.AppVersion;
	Min   = Parameters.MinPlatformVersion;
	Recommended = Parameters.RecommendedPlatformVersion;
	
	Return CommonClientServer.CompareVersions(Current, Min) < 0
		Or CommonClientServer.CompareVersions(Current, Recommended) < 0;
	
EndFunction

Function DefaultAdministrationParameters()
	
	ClusterAdministrationParameters = ClusterAdministration.ClusterAdministrationParameters();
	IBAdministrationParameters = ClusterAdministration.ClusterInfobaseAdministrationParameters();
	
	// 
	AdministrationParameterStructure = ClusterAdministrationParameters;
	For Each Item In IBAdministrationParameters Do
		AdministrationParameterStructure.Insert(Item.Key, Item.Value);
	EndDo;
	
	AdministrationParameterStructure.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", False);
	
	Return AdministrationParameterStructure;
	
EndFunction

Procedure ReadParametersFromConnectionString(AdministrationParameterStructure)
	
	ConnectionStringSubstrings = StrSplit(InfoBaseConnectionString(), ";");
	
	ServerNameString = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[0], 7));
	AdministrationParameterStructure.NameInCluster = StringFunctionsClientServer.RemoveDoubleQuotationMarks(Mid(ConnectionStringSubstrings[1], 6));
	
	ClusterServerList = StrSplit(ServerNameString, ",");
	If ClusterServerList.Count() = 1 Then 
		ClusterServerList = StrSplit(ServerNameString, ";");
	EndIf;
	
	ServerName = ClusterServerList[0];
	
	// 
	If StrStartsWith(Upper(ServerName), "TCP://") Then
		ServerName = Mid(ServerName, 7);
	EndIf;
	
	// 
	StartPosition = StrFind(ServerName, "]");
	If StartPosition <> 0 Then
		PortSeparator = StrFind(ServerName, ":",, StartPosition);
	Else
		PortSeparator = StrFind(ServerName, ":");
	EndIf;
	
	If PortSeparator > 0 Then
		ServerAgentAddress = Mid(ServerName, 1, PortSeparator - 1);
		ClusterPort = Number(Mid(ServerName, PortSeparator + 1));
		If AdministrationParameterStructure.ClusterPort = 1541 Then
			AdministrationParameterStructure.ClusterPort = ClusterPort;
		EndIf;
	Else
		ServerAgentAddress = ServerName;
	EndIf;
	
	AdministrationParameterStructure.ServerAgentAddress = ServerAgentAddress;
	
EndProcedure

// Checks whether session parameter setting 
// handlers, update handlers, and other basic configuration mechanisms 
// that execute configuration code by the full procedure name can be executed.
//
// If it is not possible to execute handlers with the current security profile settings (in the server cluster and in the information database) 
// , an exception is generated
// that contains a description of the cause and a list of actions to resolve it.
//
Procedure CheckIfCanStart()
	
	If Common.FileInfobase(InfoBaseConnectionString()) Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
	Else
		InfobaseProfile = "";
	EndIf;
	
	If ValueIsFilled(InfobaseProfile) Then
		
		// 
		// 
		
		SetSafeMode(InfobaseProfile);
		If SafeMode() <> InfobaseProfile Then
			
			// 
			
			SetSafeMode(False);
			
			Try
				PrivilegedModeAvailable = CanExecuteHandlersWithoutSafeMode();
			Except
				PrivilegedModeAvailable = False;
			EndTry;
				
			If Not PrivilegedModeAvailable Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Couldn''t set session parameters. Reason: Security profile %1 is not found in 1C:Enterprise server cluster or it cannot be applied in safe mode.
						|
						|To restore the app functionality, disable the security profile using the cluster console and reconfigure the security profiles using the configuration interface (see the commands in the app settings section).';"),
					InfobaseProfile);
			EndIf;
			
		EndIf;
		
		PrivilegedModeAvailable = SwichingToPrivilegedModeAvailable();
		
		SetSafeMode(False);
		
		If Not PrivilegedModeAvailable Then
			
			// 
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot set the session parameters. Reason: Security profile %1 does not contain the permission to set the privileged mode. Probably it was edited using the cluster console.
					|
					|To restore the app functionality, disable the security profile using the cluster console and reconfigure the security profiles using the configuration interface (see the commands in the app settings section).';"),
				InfobaseProfile);
			
		EndIf;
		
	Else
		
		// 
		// 
		
		Try
			PrivilegedModeAvailable = CanExecuteHandlersWithoutSafeMode();
		Except
			
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot set the session parameters. Reason: %1.
					|
					|Probably a security profile that does not allow execution of external modules in unsafe mode was set using the cluster console. If this is the case, to restore the application functionality, disable the security profile using the cluster console and reconfigure the security profiles using the configuration interface (see the commands in the application settings section). The app will be automatically configured to use the enabled security profiles.';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Checks whether handlers can be executed without setting safe mode.
//
// Returns:
//   Boolean
//
Function CanExecuteHandlersWithoutSafeMode()
	
	// 
	// 
	Return Eval("SwichingToPrivilegedModeAvailable()"); // 
		
EndFunction

// Checks whether it is possible to switch to privileged mode from the current safe mode.
//
// Returns:
//   Boolean
//
Function SwichingToPrivilegedModeAvailable()
	
	SetPrivilegedMode(True);
	Return PrivilegedMode();
	
EndFunction

// For the procedure, register a change in the priority data for the subordinate nodes of the Library.
Procedure RegisterPredefinedItemChanges(DIBExchangePlansNodes, MetadataCollection)
	
	Query = New Query;
	
	For Each MetadataObject In MetadataCollection Do
		DIBNodes = New Array;
		
		For Each ExchangePlanNodes In DIBExchangePlansNodes Do
			If Not ExchangePlanNodes.Key.Contains(MetadataObject) Then
				Continue;
			EndIf;
			For Each DIBNode In ExchangePlanNodes.Value Do
				DIBNodes.Add(DIBNode);
			EndDo;
		EndDo;
		
		If DIBNodes.Count() = 0 Then
			Continue;
		EndIf;
		
		Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
		Query.Text = StrReplace(Query.Text, "&CurrentTable", MetadataObject.FullName());
		// 
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			ExchangePlans.RecordChanges(DIBNodes, Selection.Ref);
		EndDo;
	EndDo;
	
EndProcedure

// For the procedure, set the form assignment Key.
Procedure SetFormAssignmentUsageKey(Form, Var_Key, SetSettings)
	
	If Not ValueIsFilled(Var_Key)
	 Or Form.PurposeUseKey = Var_Key Then
		
		Return;
	EndIf;
	
	If Not SetSettings Then
		Form.PurposeUseKey = Var_Key;
		Return;
	EndIf;
	
	SettingsTypes1 = New Array;
	// 
	SettingsTypes1.Add("/CurrentVariantKey");
	SettingsTypes1.Add("/CurrentUserSettingsKey");
	SettingsTypes1.Add("/CurrentUserSettings");
	SettingsTypes1.Add("/CurrentDataSettingsKey");
	SettingsTypes1.Add("/CurrentData");
	SettingsTypes1.Add("/FormSettings");
	// 
	SettingsTypes1.Add("/CurrentVariantKey");
	SettingsTypes1.Add("/CurrentUserSettingsKey");
	SettingsTypes1.Add("/CurrentUserSettings");
	SettingsTypes1.Add("/CurrentDataSettingsKey");
	SettingsTypes1.Add("/CurrentData");
	SettingsTypes1.Add("/FormSettings");
	If SystemSettingsStorage.Load(Var_Key, "FormAssignmentRuleKey") <> True 
		 And AccessRight("SaveUserData", Metadata) Then
		SetSettingsForKey(Var_Key, SettingsTypes1, Form.FormName, Form.PurposeUseKey);
		SystemSettingsStorage.Save(Var_Key, "FormAssignmentRuleKey", True);
	EndIf;
	
	Form.PurposeUseKey = Var_Key;
	
EndProcedure

// For the procedure, set the form assignment Key.
Procedure SetFormWindowOptionsSaveKey(Form, Var_Key, SetSettings)
	
	If Not ValueIsFilled(Var_Key)
	 Or Form.WindowOptionsKey = Var_Key Then
		
		Return;
	EndIf;
	
	If Not SetSettings Then
		Form.WindowOptionsKey = Var_Key;
		Return;
	EndIf;
	
	SettingsTypes1 = New Array;
	// 
	SettingsTypes1.Add("/ThinClientWindowSettings"); // @Non-NLS
	SettingsTypes1.Add("/Taxi/ThinClientWindowSettings"); // @Non-NLS
	SettingsTypes1.Add("/WebClientWindowSettings"); // @Non-NLS
	SettingsTypes1.Add("/Taxi/WebClientWindowSettings"); // 
	// 
	SettingsTypes1.Add("/ThinClientWindowSettings");
	SettingsTypes1.Add("/Taxi/ThinClientWindowSettings");
	SettingsTypes1.Add("/WebClientWindowSettings");
	SettingsTypes1.Add("/Taxi/WebClientWindowSettings");
	
	If SystemSettingsStorage.Load(Var_Key, "FormWindowOptionsKey") <> True 
		And AccessRight("SaveUserData", Metadata) Then
		SetSettingsForKey(Var_Key, SettingsTypes1, Form.FormName, Form.WindowOptionsKey);
		SystemSettingsStorage.Save(Var_Key, "FormWindowOptionsKey", True);
	EndIf;
	
	Form.WindowOptionsKey = Var_Key;
	
EndProcedure

// For procedures, set the form's purpose key, set the save key, and the form's location Key.
Procedure SetSettingsForKey(Var_Key, SettingsTypes1, FormName, CurrentKey)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	NewKey = "/" + Var_Key;
	Filter = New Structure;
	Filter.Insert("User", InfoBaseUsers.CurrentUser().Name);
	
	For Each SettingsType1 In SettingsTypes1 Do
		Filter.Insert("ObjectKey", FormName + NewKey + SettingsType1);
		Selection = SystemSettingsStorage.Select(Filter);
		If Selection.Next() Then
			Return; // 
		EndIf;
	EndDo;
	
	If ValueIsFilled(CurrentKey) Then
		CurrentKey = "/" + CurrentKey;
	EndIf;
	
	// 
	For Each SettingsType1 In SettingsTypes1 Do
		Filter.Insert("ObjectKey", FormName + CurrentKey + SettingsType1);
		Selection = SystemSettingsStorage.Select(Filter);
		ObjectKey = FormName + NewKey + SettingsType1;
		While Selection.Next() Do
			SettingsDescription = New SettingsDescription;
			SettingsDescription.Presentation = Selection.Presentation;
			SystemSettingsStorage.Save(ObjectKey, Selection.SettingsKey,
				Selection.Settings, SettingsDescription);
		EndDo;
	EndDo;
	
EndProcedure

// 

// See OnReceiptRecurringClientDataOnServer
Procedure ConfigurationOrExtensionModifiedDuringRepeatedCheck(UserMessage)
	
	
	SetPrivilegedMode(True);
	
	UserName = InfoBaseUsers.CurrentUser().Name;
	
	YouCanNotify = ShowWarningAboutInstalledUpdatesForUser(UserName);
	If Not YouCanNotify Then
		Return;
	EndIf;
	
	DateRemindTomorrow = Common.SystemSettingsStorageLoad(
		"DynamicUpdateControl", "DateRemindTomorrow",,, UserName);
	
	If TypeOf(DateRemindTomorrow) = Type("Date")
	   And CurrentSessionDate() < DateRemindTomorrow Then
		Return;
	EndIf;
	
	DataBaseConfigurationChangedDynamically = DataBaseConfigurationChangedDynamically();
	DynamicChanges = Catalogs.ExtensionsVersions.DynamicallyChangedExtensions(
		Catalogs.ExtensionsVersions.InstalledExtensionsOnStartup(), True);
	
	If Not DataBaseConfigurationChangedDynamically
	   And Not ValueIsFilled(DynamicChanges.Extensions)
	   And Not ValueIsFilled(DynamicChanges.Corrections) Then
		Return;
	EndIf;
	
	If DynamicChanges.Corrections <> Undefined
		And DynamicChanges.Extensions = Undefined
		And Not DataBaseConfigurationChangedDynamically
		// 
		And DynamicChanges.Corrections.Added2 <> 0
		And DynamicChanges.Corrections.Deleted = 0 Then
	
		NotificationSchedule = Common.SystemSettingsStorageLoad(
			"DynamicUpdateControl", "PatchCheckSchedule",,, UserName);
		
		If TypeOf(NotificationSchedule) = Type("Structure")
			And NotificationSchedule.Property("Schedule")
			And TypeOf(NotificationSchedule.Schedule) = Type("JobSchedule") Then
			
			CurrentSessionDate = CurrentSessionDate();
			YouCanNotify = NotificationSchedule.Schedule.ExecutionRequired(CurrentSessionDate,
				NotificationSchedule.LastAlert);
			
			If YouCanNotify Then
				NotificationSchedule.LastAlert = CurrentSessionDate;
				Common.SystemSettingsStorageSave("DynamicUpdateControl",
					"PatchCheckSchedule", NotificationSchedule,, UserName);
			EndIf;
		Else
			OnceADay = New JobSchedule;
			OnceADay.DaysRepeatPeriod = 1;
			
			PatchCheckSchedule = New Structure;
			PatchCheckSchedule.Insert("Id", "Once");
			PatchCheckSchedule.Insert("Presentation", NStr("en = 'Once a day';"));
			PatchCheckSchedule.Insert("Schedule", OnceADay);
			PatchCheckSchedule.Insert("LastAlert", CurrentSessionDate());

			Common.SystemSettingsStorageSave("DynamicUpdateControl", "PatchCheckSchedule", PatchCheckSchedule);
		EndIf;
	EndIf;
	
	If Not YouCanNotify Then
		Return;
	EndIf;
	
	DynamicChanges.Insert("DataBaseConfigurationChangedDynamically",
		DataBaseConfigurationChangedDynamically);
		
	Messages = New Array;
	Messages.Add(MessageTextOnDynamicUpdate(DynamicChanges));
	Messages.Add(NStr("en = 'Click here to start or postpone patch application.';"));
	UserMessage = StrConcat(Messages, Chars.LF);
	
EndProcedure

// See OnSendServerNotification
Procedure OnSendServerNotificationFunctionalOptionsModified(NameOfAlert, ParametersVariants)
	
	ParameterName = "StandardSubsystems.Core.EnabledFunctionalOptions";
	PreviousValue2 = ExtensionParameter(ParameterName, True);
	
	NewTypeCollection = New Array;
	FunctionalOptionsByTypes = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		StorageObject = FunctionalOption.Location;
		If Not Metadata.Constants.Contains(StorageObject) Then
			Continue;
		EndIf;
		Type = Type("ConstantManager." + StorageObject.Name);
		FunctionalOptionsByTypes.Insert(Type, FunctionalOption);
		If GetFunctionalOption(FunctionalOption.Name) = True Then
			NewTypeCollection.Add(Type);
		EndIf;
	EndDo;
	NewValue = New TypeDescription(NewTypeCollection);
	If PreviousValue2 = NewValue Then
		Return;
	EndIf;
	
	If TypeOf(PreviousValue2) = Type("TypeDescription") Then
		TypesChangeList = New Map;
		For Each Type In NewValue.Types() Do
			TypesChangeList.Insert(Type, True);
		EndDo;
		For Each Type In PreviousValue2.Types() Do
			If TypesChangeList.Get(Type) = Undefined Then
				TypesChangeList.Insert(Type, True);
			Else
				TypesChangeList.Delete(Type);
			EndIf;
		EndDo;
		
		Objects = New Map;
		For Each KeyAndValue In TypesChangeList Do
			FunctionalOption = FunctionalOptionsByTypes.Get(KeyAndValue.Key);
			If FunctionalOption = Undefined Then
				Continue;
			EndIf;
			AddFunctionalOptionObjects(Objects, FunctionalOption);
		EndDo;
		
		SMSMessageRecipients = New Map;
		For Each ParametersVariant In ParametersVariants Do
			For Each Addressee In ParametersVariant.SMSMessageRecipients Do
				IBUser = InfoBaseUsers.FindByUUID(Addressee.Key);
				If IBUser = Undefined Then
					Continue;
				EndIf;
				For Each KeyAndValue In Objects Do
					If AccessRight(KeyAndValue.Value, KeyAndValue.Key, IBUser) Then
						SMSMessageRecipients.Insert(Addressee.Key, Addressee.Value);
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
		If ValueIsFilled(SMSMessageRecipients) Then
			ServerNotifications.SendServerNotification(NameOfAlert, "", SMSMessageRecipients);
		EndIf;
	EndIf;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ExtensionVersionParameters");
	LockItem.SetValue("ExtensionsVersion", Catalogs.ExtensionsVersions.EmptyRef());
	LockItem.SetValue("ParameterName", ParameterName);
	
	BeginTransaction();
	Try
		Block.Lock();
		PreviousValue2 = ExtensionParameter(ParameterName, True);
		If PreviousValue2 <> NewValue Then
			SetExtensionParameter(ParameterName, NewValue, True);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

Procedure AddFunctionalOptionObjects(Objects, FunctionalOption)
	
	BaseTypesNames =
	"
	|Subsystem
	|CommonAttribute
	|ExchangePlan
	|FilterCriterion
	|CommonForm
	|CommonCommand
	|Constant
	|Catalog
	|Document
	|DocumentJournal
	|Report
	|DataProcessor
	|ChartOfCharacteristicTypes
	|ChartOfAccounts
	|ChartOfCalculationTypes
	|InformationRegister
	|AccumulationRegister
	|AccountingRegister
	|CalculationRegister
	|BusinessProcess
	|Task
	|";
	
	For Each CompositionItem In FunctionalOption.Content Do
		Object = CompositionItem.Object;
		If Objects.Get(Object) <> Undefined
		 Or TypeOf(Object) <> Type("MetadataObject") Then
			Continue;
		EndIf;
		Try
			FullName = Object.FullName();
		Except
			FullName = "";
		EndTry;
		NameParts = StrSplit(FullName, ".", False);
		If NameParts.Count() < 2 Then
			Continue;
		EndIf;
		BaseTypeName = NameParts[0];
		If StrFind(BaseTypesNames, Chars.LF + BaseTypeName + Chars.LF) = 0 Then
			Continue;
		EndIf;
		If NameParts.Count() > 2 Then
			If BaseTypeName <> "Subsystem" Then
				Object = Common.MetadataObjectByFullName(NameParts[0] + "." + NameParts[1]);
				If Object = Undefined
				 Or Objects.Get(Object) <> Undefined Then
					Continue;
				EndIf;
			EndIf;
		EndIf;
		Objects.Insert(Object, "View");
	EndDo;
	
EndProcedure

// 

Function RegionalInfobaseSettingsRequired() Export
		
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		Return ModuleNationalLanguageSupportServer.RegionalInfobaseSettingsRequired();
	EndIf;
	
	Return False;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Function StyleItems() Export
	
	StyleElementsSet = New Structure;
	For Each StyleItem In Metadata.StyleItems Do
		StyleElementsSet.Insert(StyleItem.Name, StyleItem.Value);
	EndDo;
	
	Return New FixedStructure(StyleElementsSet);
	
EndFunction

// Returns a serializable set of style elements.
// 
// Returns:
//  Structure:
//   * Key - String -   name of the style element.
//   * Value - String
//              - MetadataObjectStyleItem - 
//                           
//
Function StyleElementsSet()
	
	StyleElementsSet = New Structure;
	For Each StyleItem In Metadata.StyleItems Do
		
		If CurrentRunMode() = ClientRunMode.OrdinaryApplication Then
			StyleElementsSet.Insert(StyleItem.Name, New ValueStorage(StyleItem.Value));
		Else
			StyleElementsSet.Insert(StyleItem.Name, StyleItem.Value);
		EndIf;
		
	EndDo;
	
	Return New FixedStructure(StyleElementsSet);
	
EndFunction

// For the procedure for filling in permissions for accessing external Resources.
Procedure AddRequestForPermissionToUseExtensions(PermissionsRequests)
	
	If Common.DataSeparationEnabled()
	   And Common.SeparatedDataUsageAvailable() Then
		
		Return;
	EndIf;
	
	Permissions = New Array;
	AllExtensions = ConfigurationExtensions.Get();
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	For Each Extension In AllExtensions Do
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			Extension.Name, Base64String(Extension.HashSum)));
	EndDo;
	
	PermissionsRequests.Add(ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters")));

EndProcedure

Function MustShowRAMSizeRecommendations()
	
	If Common.IsWebClient()
	 Or Not Common.FileInfobase() Then
		Return False;
	EndIf;
	
	RAM = ClientParametersAtServer().Get("RAM");
	If TypeOf(RAM) <> Type("Number") Then
		Return False; // 
	EndIf;
	
	RecommendedSize = Common.CommonCoreParameters().RecommendedRAM;
	SavedRecommendation = Common.CommonSettingsStorageLoad("UserCommonSettings",
		"RAMRecommendation");
	
	Recommendation = New Structure;
	Recommendation.Insert("Show", True);
	Recommendation.Insert("PreviousShowDate", Date(1, 1, 1));
	
	If TypeOf(SavedRecommendation) = Type("Structure") Then
		FillPropertyValues(Recommendation, SavedRecommendation);
	EndIf;
	
	Return RAM < RecommendedSize
		And (Recommendation.Show
		   Or (CurrentSessionDate() - Recommendation.PreviousShowDate) > 60*60*24*60)
	
EndFunction

Procedure IgnoreSendingDataProcessedOnMasterDIBNodeOnInfobaseUpdate(DataElement, InitialImageCreating, Recipient)
	
	If Recipient <> Undefined
		And Not InitialImageCreating
		And TypeOf(DataElement) = Type("InformationRegisterRecordSet.DataProcessedInMasterDIBNode") Then
		
		IndexOf = DataElement.Count() - 1;
		While IndexOf >= 0 Do
			SetRow = DataElement[IndexOf];
			If SetRow.ExchangePlanNode <> Recipient Then
				DataElement.Delete(SetRow);
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		
	EndIf;

EndProcedure

Function InvalidPlatformVersionUsed()
	
	SystemInfo = New SystemInfo;
	DeprecatedPlatformVersions = Common.InvalidPlatformVersions();
	
	Return StrFind(DeprecatedPlatformVersions, SystemInfo.AppVersion);
	
EndFunction

Function IsOwnerMarkedForDeletion(RemovableObject)
	
	SourceMetadata = RemovableObject.Metadata();
	If SourceMetadata.Owners.Count() = 0 Then
		Return False;
	EndIf;

	Query = New Query;
	Query.Text = "
	|SELECT
	|	OwnerTable.Owner.DeletionMark AS DeletionMark
	|FROM
	|	&TableName AS OwnerTable
	|WHERE 
	|	OwnerTable.Ref = &Ref";
	
	Query.Text = StrReplace(Query.Text, "&TableName", SourceMetadata.FullName());
	Query.SetParameter("Ref", RemovableObject);
		
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DeletionMark;
	EndIf;
	Return False;
	
EndFunction

#EndRegion

#EndIf