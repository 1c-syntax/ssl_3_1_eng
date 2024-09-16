///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region UserNotification

//  
// 

// Generates and outputs a message that can be associated with a form control.
//
// See Common.MessageToUser
//
// Parameters:
//  MessageToUserText - String -  message text.
//  DataKey - AnyRef -  the object or key of the database record that this message refers to.
//  Field - String - 
//  DataPath - String -  data path (the path to the requisite shape).
//  Cancel - Boolean -  the output parameter is always set to True.
//
// Example:
//
//  1. to display a message in the field of the managed form associated with the object's details:
//  General Assignationclient.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Politikunterricht",
//   "Object");
//
//  Alternative use in the form of an object:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Object.Politikunterricht");
//
//  2. To display the message next to the managed form, associated with the requisite forms:
//  Observationnelle.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Markwesterby");
//
//  3. to display a message related to an object in the information database:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'"), Object Of The Information Base, "Responsible",, Refusal);
//
//  4. to display the message by reference to the object of the information database:
//  General purpose Client.Inform the user(
//   NSTR ("ru = 'Error message.'") The Link, ,,,, Failure);
//
//  Cases of incorrect use:
//   1. Passing the key Data and path Data parameters simultaneously.
//   2. Passing a different type of value in the key Data parameter.
//   3. Installation without field installation (and/or datapath).
//
Procedure MessageToUser(Val MessageToUserText,	Val DataKey = Undefined,
	Val Field = "", Val DataPath = "", Cancel = False) Export
	
	Message = CommonInternalClientServer.UserMessage(MessageToUserText,
		DataKey, Field, DataPath, Cancel);
	
	Message.Message()
	
EndProcedure

// 

#EndRegion

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a reference to a predefined element by its full name.
// Predefined elements can only be contained in the following objects:
//   - directories;
//   - plans of types of characteristics;
//   - chart of accounts;
//   - plans for calculation types.
// After changing the composition of the predefined ones, run the method
// Update the re-used values (), which will reset the Repeat cache in the current session.
//
// See Common.PredefinedItem
//
// Parameters:
//   FullPredefinedItemName - String - 
//     
//     :
//       
//       
//       
//
// Returns: 	
//   AnyRef - 
//   
//
Function PredefinedItem(FullPredefinedItemName) Export
	
	If CommonInternalClientServer.UseStandardGettingPredefinedItemFunction(
		FullPredefinedItemName) Then 
		
		Return PredefinedValue(FullPredefinedItemName);
	EndIf;
	
	PredefinedItemFields = CommonInternalClientServer.PredefinedItemNameByFields(FullPredefinedItemName);
	
	PredefinedValues = StandardSubsystemsClientCached.RefsByPredefinedItemsNames(
		PredefinedItemFields.FullMetadataObjectName);
	
	Return CommonInternalClientServer.PredefinedItem(
		FullPredefinedItemName, PredefinedItemFields, PredefinedValues);
	
EndFunction

// Returns the code of the main language of the information base, for example "ru".
// On which automatically generated strings are programmatically written to the information database.
// For example, when initially filling in the information database with data from the layout, auto-generating a comment
// on a transaction, or determining the value of the EventName parameter of the log record method.
//
// Returns:
//  String - 
//
Function DefaultLanguageCode() Export
	
	Return StandardSubsystemsClient.ClientParameter("DefaultLanguageCode");
	
EndFunction

#EndRegion

#Region ConditionCalls

////////////////////////////////////////////////////////////////////////////////
// 

// 
//  
// 
//
// 
// 
// 
//
// Parameters:
//  FullSubsystemName - String -  the full name of the subsystem metadata object
//                        without the words " Subsystem."and case-sensitive.
//                        For example: "Standard subsystems.Variants of reports".
//
// Example:
//  
//  	
//  	
//  
//
// Returns:
//  Boolean
//
Function SubsystemExists(FullSubsystemName) Export
	
	ParameterName = "StandardSubsystems.ConfigurationSubsystems";
	If ApplicationParameters[ParameterName] = Undefined Then
		SubsystemsNames = StandardSubsystemsClient.ClientParametersOnStart().SubsystemsNames;
		ApplicationParameters.Insert(ParameterName, SubsystemsNames);
	EndIf;
	SubsystemsNames = ApplicationParameters[ParameterName];
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

//  
// 
// 
//
// Parameters:
//  Name - String - 
//
// Returns:
//  CommonModule
//
// Example:
//	
//		
//		
//	
//
Function CommonModule(Name) Export
	
	Module = Eval(Name);
	
#If Not WebClient Then
	
	// 
	// 
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Common module ""%1"" does not exist.';"), 
			Name);
	EndIf;
	
#EndIf
	
	Return Module;
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// 

// Returns True if the client application is running on Windows.
//
// See Common.IsWindowsClient
//
// Returns:
//  Boolean - 
//
Function IsWindowsClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.Windows_x86
		Or ClientPlatformType = PlatformType.Windows_x86_64;
	
EndFunction

// Returns True if the client application is running under Linux.
//
// See Common.IsLinuxClient
//
// Returns:
//  Boolean - 
//
Function IsLinuxClient() Export
	
	SystemInfo = New SystemInfo;
	ClientPlatformType = SystemInfo.PlatformType;
	
#If MobileClient Then
	Return ClientPlatformType = PlatformType.Linux_x86
		Or ClientPlatformType = PlatformType.Linux_x86_64;
#EndIf
	
	Return ClientPlatformType = PlatformType.Linux_x86
		Or ClientPlatformType = PlatformType.Linux_x86_64
		Or CommonClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0
			And (ClientPlatformType = PlatformType["Linux_ARM64"]
			Or ClientPlatformType = PlatformType["Linux_E2K"]);
	
EndFunction

// Returns True if the client application is running on macOS.
//
// See Common.IsMacOSClient
//
// Returns:
//  Boolean - 
//
Function IsMacOSClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.MacOS_x86
		Or ClientPlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

// Returns True if the client application is connected to the database via a web server.
//
// See Common.ClientConnectedOverWebServer
//
// Returns:
//  Boolean - 
//
Function ClientConnectedOverWebServer() Export
	
	Return StrFind(Upper(InfoBaseConnectionString()), "WS=") = 1;
	
EndFunction

// Returns True if debugging mode is enabled.
//
// See Common.DebugMode
//
// Returns:
//  Boolean - 
//
Function DebugMode() Export
	
	Return StrFind(LaunchParameter, "DebugMode") > 0;
	
EndFunction

// Returns the amount of RAM available to the client application.
//
// See Common.RAMAvailableForClientApplication
//
// Returns:
//  Number - 
//  
//
Function RAMAvailableForClientApplication() Export
	
	SystemInfo = New SystemInfo;
	Return Round(SystemInfo.RAM / 1024, 1);
	
EndFunction

// Defines the operation mode of the information database: file (True) or server (False).
// When checking, the information database connection String is used, which can be specified explicitly.
//
// See Common.FileInfobase
//
// Parameters:
//  InfoBaseConnectionString - String -  this parameter is used if
//                 you need to check the connection string of a non-current database.
//
// Returns:
//  Boolean - 
//
Function FileInfobase(Val InfoBaseConnectionString = "") Export
	
	If Not IsBlankString(InfoBaseConnectionString) Then
		Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	EndIf;
	
	Return StandardSubsystemsClient.ClientParameter("FileInfobase");
	
EndFunction

// Returns the platform type of the client.
//
// Returns:
//  PlatformType, Undefined -  
//                               
//
Function ClientPlatformType() Export
	
	SystemData = New SystemInfo;
	Return SystemData.PlatformType;
	
EndFunction

// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - 
//           
//
Function DataSeparationEnabled() Export
	
	Return StandardSubsystemsClient.ClientParameter("DataSeparationEnabled");
	
EndFunction

// Returns whether split data (which is part of separators) can be accessed.
// This attribute is specific to the session, but may change during the session if partitioning was enabled
// in the session itself, so you should check it immediately before accessing the split data.
// 
// Returns True if the configuration can't work in data separation mode
// (it doesn't contain any General details intended for data separation).
//
// Returns:
//   Boolean - 
//                    
//            
//
Function SeparatedDataUsageAvailable() Export
	
	Return StandardSubsystemsClient.ClientParameter("SeparatedDataUsageAvailable");
	
EndFunction

#EndRegion

#Region Dates

////////////////////////////////////////////////////////////////////////////////
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
// Returns:
//  Date -  the current date of the session.
//
Function SessionDate() Export
	
	Adjustment = StandardSubsystemsClient.ClientParameter("SessionTimeOffset");
	Return CurrentDate() + Adjustment; // 
	
EndFunction

// Returns the universal session date obtained from the current session date.
//
// The function returns a time that is close to the result of the universal Time() function in the server context.
// The error is due to the server call execution time.
// It is intended to be used instead of the universal Time () function.
//
// Returns:
//  Date - 
//
Function UniversalDate() Export
	
	ClientParameters = StandardSubsystemsClient.ClientParameter();
	
	SessionDate = CurrentDate() + ClientParameters.SessionTimeOffset;
	Return SessionDate + ClientParameters.UniversalTimeCorrection;
	
EndFunction

// Converts a local date to the format" YYYY-MM-DDThh:mm:ssTZD " according to ISO 8601.
//
// See Common.LocalDatePresentationWithOffset
//
// Parameters:
//  LocalDate - Date -  date in the session's time zone.
// 
// Returns:
//   String - 
//
Function LocalDatePresentationWithOffset(LocalDate) Export
	
	Offset = StandardSubsystemsClient.ClientParameter("StandardTimeOffset");
	Return CommonInternalClientServer.LocalDatePresentationWithOffset(LocalDate, Offset);
	
EndFunction

#EndRegion

#Region Data

////////////////////////////////////////////////////////////////////////////////
// 

// Creates a complete copy of a structure, match, array, list, or table of values, recursively,
// with consideration for the types of child elements. However, the contents of object type values are
// (Reference object, document Object, etc.) are not copied, but references to the source object are returned.
//
// See Common.CopyRecursive
//
// Parameters:
//  Source - Structure
//           - FixedStructure
//           - Map
//           - FixedMap
//           - Array
//           - FixedArray
//           - ValueList - 
//  FixData - Boolean
//                    - Undefined - 
//                          
//
// Returns:
//  Structure
//  
//  
//  
//  
//  
//  
//
Function CopyRecursive(Source, FixData = Undefined) Export
	
	Var Receiver;
	
	SourceType = TypeOf(Source);
	
	If SourceType = Type("Structure")
		Or SourceType = Type("FixedStructure") Then
		Receiver = CommonInternalClient.CopyStructure(Source, FixData);
	ElsIf SourceType = Type("Map")
		Or SourceType = Type("FixedMap") Then
		Receiver = CommonInternalClient.CopyMap(Source, FixData);
	ElsIf SourceType = Type("Array")
		Or SourceType = Type("FixedArray") Then
		Receiver = CommonInternalClient.CopyArray(Source, FixData);
	ElsIf SourceType = Type("ValueList") Then
		Receiver = CommonInternalClient.CopyValueList(Source, FixData);
	Else
		Receiver = Source;
	EndIf;
	
	Return Receiver;
	
EndFunction

// Checks that an object of the expected type is passed in the parameter of the Parameter command.
// Otherwise, it returns a standard message and returns False.
// This situation is possible, for example, if a grouping row is selected in the list.
//
// For use in teams that work with dynamic list items in forms.
// 
// Parameters:
//  Parameter     - Array
//               - AnyRef - 
//  ExpectedType - Type                 -  the expected type of the parameter.
//
// Returns:
//  Boolean - 
//
// Example:
// 
//   If NOT the general purpose of the client.Check the Command parameters(
//      Elements.List.Highlighted links, Type("Taskslink.Task executor")) Then
//      Refund;
//   KonecEsli;
//   ...
//
Function CheckCommandParameterType(Val Parameter, Val ExpectedType) Export
	
	If Parameter = Undefined Then
		Return False;
	EndIf;
	
	Result = True;
	
	If TypeOf(Parameter) = Type("Array") Then
		// 
		Result = Not (Parameter.Count() = 1 And TypeOf(Parameter[0]) <> ExpectedType);
	Else
		Result = TypeOf(Parameter) = ExpectedType;
	EndIf;
	
	If Not Result Then
		ShowMessageBox(,NStr("en = 'The object does not support this type of operations.';"));
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Forms

////////////////////////////////////////////////////////////////////////////////
// 

// 
//  
// 
// 
// 
// 
// 
//
// Parameters:
//  SaveAndCloseNotification  - NotifyDescription -  contains the name of the procedure that is called when the " OK " button is clicked.
//  Cancel                        - Boolean -  return parameter that indicates that the action was rejected.
//  Exit             - Boolean -  indicates that the form is being closed while the application is shutting down.
//  WarningText          - String -  warning text displayed to the user. By default, it displays the text
//                                          "Data has been changed. Save changes?"
//  WarningTextOnExit - String -  returned parameter with the warning text displayed to the user 
//                                          when the application is terminated. If this parameter is specified, the text
//                                          " Data was changed. All changes will be lost.".
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
Procedure ShowFormClosingConfirmation(
		Val SaveAndCloseNotification, 
		Cancel, 
		Val Exit, 
		Val WarningText = "", 
		WarningTextOnExit = Undefined) Export
	
	Form = SaveAndCloseNotification.Module;
	If Not Form.Modified Then
		Return;
	EndIf;
	
	Cancel = True;
	
	If Exit Then
		If WarningTextOnExit = "" Then // 
			WarningTextOnExit = NStr("en = 'The data has been changed. All changes will be lost.';");
		EndIf;
		Return;
	EndIf;
	
	Parameters = New Structure();
	Parameters.Insert("SaveAndCloseNotification", SaveAndCloseNotification);
	Parameters.Insert("WarningText", WarningText);
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	
	CurrentParameters = ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"];
	If CurrentParameters <> Undefined
	   And CurrentParameters.SaveAndCloseNotification.Module = Parameters.SaveAndCloseNotification.Module Then
		Return;
	EndIf;
	
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Parameters;
	
	Form.Activate();
	AttachIdleHandler("ConfirmFormClosingNow", 0.1, True);
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  Form                        - ClientApplicationForm -  a form that calls the warning dialog.
//  Cancel                        - Boolean -  return parameter that indicates that the action was rejected.
//  Exit             - Boolean -  indicates that the program is shutting down.
//  WarningText          - String -  warning text displayed to the user.
//  CloseFormWithoutConfirmationAttributeName - String -  the name of the attribute that contains the indication of whether to
//                                 display a warning or not.
//  CloseNotifyDescription    - NotifyDescription -  contains the name of the procedure that is called when the "Yes" button is clicked.
//
// Example: 
//  
//  
//      
//
Procedure ShowArbitraryFormClosingConfirmation(
		Val Form, 
		Cancel, 
		Val Exit, 
		Val WarningText, 
		Val CloseFormWithoutConfirmationAttributeName, 
		Val CloseNotifyDescription = Undefined) Export
		
	If Form[CloseFormWithoutConfirmationAttributeName] Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	Parameters = New Structure();
	Parameters.Insert("Form", Form);
	Parameters.Insert("WarningText", WarningText);
	Parameters.Insert("CloseFormWithoutConfirmationAttributeName", CloseFormWithoutConfirmationAttributeName);
	Parameters.Insert("CloseNotifyDescription", CloseNotifyDescription);
	
	ParameterName = "StandardSubsystems.FormClosingConfirmationParameters";
	If ApplicationParameters[ParameterName] = Undefined Then
		ApplicationParameters.Insert(ParameterName, Undefined);
	EndIf;
	ApplicationParameters["StandardSubsystems.FormClosingConfirmationParameters"] = Parameters;
	
	AttachIdleHandler("ConfirmArbitraryFormClosingNow", 0.1, True);
	
EndProcedure

// Updates the program interface while maintaining the current active window.
//
Procedure RefreshApplicationInterface() Export
	
	CurrentActiveWindow = ActiveWindow();
	RefreshInterface();
	If CurrentActiveWindow <> Undefined Then
		CurrentActiveWindow.Activate();
	EndIf;
	
EndProcedure

// Notifies open forms and dynamic lists of changes to a single object.
//
// Parameters:
//  Source - AnyRef
//           - InformationRegisterRecordKeyInformationRegisterName
//           - AccumulationRegisterRecordKeyAccumulationRegisterName
//           - AccountingRegisterRecordKeyAccountingRegisterName
//           - CalculationRegisterRecordKeyCalculationRegisterName -  
//                 
//  AdditionalParameters - Arbitrary -  any parameters that need to be passed in the Notify method.
//
Procedure NotifyObjectChanged(Source, Val AdditionalParameters = Undefined) Export
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	Notify("Record_" + CommonInternalClient.MetadataObjectName(TypeOf(Source)), AdditionalParameters, Source);
	NotifyChanged(Source);
EndProcedure

// Notifies open forms and dynamic lists of changes to several objects at once.
//
// Parameters:
//  Source - Type
//           - TypeDescription -  
//                             
//           - Array -  
//                      
//  AdditionalParameters - Arbitrary -  any parameters that need to be passed in the Notify method.
//
Procedure NotifyObjectsChanged(Source, Val AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	
	If TypeOf(Source) = Type("Type") Then
		NotifyChanged(Source);
		Notify("Record_" + CommonInternalClient.MetadataObjectName(Source), AdditionalParameters);
	ElsIf TypeOf(Source) = Type("TypeDescription") Then
		For Each Type In Source.Types() Do
			NotifyChanged(Type);
			Notify("Record_" + CommonInternalClient.MetadataObjectName(Type), AdditionalParameters);
		EndDo;
	ElsIf TypeOf(Source) = Type("Array") Then
		If Source.Count() = 1 Then
			NotifyObjectChanged(Source[0], AdditionalParameters);
		Else
			NotifiedTypes = New Map;
			For Each Ref In Source Do
				NotifiedTypes.Insert(TypeOf(Ref));
			EndDo;
			For Each Type In NotifiedTypes Do
				NotifyChanged(Type.Key);
				Notify("Record_" + CommonInternalClient.MetadataObjectName(Type.Key), AdditionalParameters);
			EndDo;
		EndIf;
	EndIf;

EndProcedure

// Opens a form to select the format of attachments.
//
// Parameters:
//  NotifyDescription  - NotifyDescription -  handler for the selection result.
//  FormatSettings - Structure - :
//   * PackToArchive   - Boolean -  indicates whether attachments need to be archived.
//   * SaveFormats - Array -  list of selected attachment formats.
//   * TransliterateFilesNames - Boolean -  convert Cyrillic characters to Latin characters.
//  Owner - ClientApplicationForm -  the form from which the attachment selection form is called.
//
Procedure ShowAttachmentsFormatSelection(NotifyDescription, FormatSettings, Owner = Undefined) Export
	FormParameters = New Structure("FormatSettings", FormatSettings);
	OpenForm("CommonForm.SelectAttachmentFormat", FormParameters, , , , ,
		NotifyDescription, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#EndRegion

#Region EditingForms

////////////////////////////////////////////////////////////////////////////////
// 
// 

// Opens a form for editing custom multi-line text.
//
// Parameters:
//  ClosingNotification1     - NotifyDescription -  contains a description of the procedure that will be called 
//                            after closing the text input form with the same parameters as for the method
//                            Show the text lines.
//  MultilineText      - String -  any text you want to edit;
//  Title               - String -  the text that you want to display in the header of the form.
//
// Example:
//
//   Alert = New Description Of The Announcement ("Completion Comment", This Object);
//   General purpose client.Show The Form Of Editing A Single Line Of Text(Alert, Element.Text editing);
//
//   &Naciente
//   Comment Completion Procedure (Value Of The Entered Text, Value Of Additional Parameters) Export
//      If The Entered Text = Undefined Then
//		   Return;
//   	Conicelli;	
//	
//	   An object.Multi-line comment = Entered text;
//	   Modified = True;
//   End of procedure
//
Procedure ShowMultilineTextEditingForm(Val ClosingNotification1, 
	Val MultilineText, Val Title = Undefined) Export
	
	If Title = Undefined Then
		ShowInputString(ClosingNotification1, MultilineText,,, True);
	Else
		ShowInputString(ClosingNotification1, MultilineText, Title,, True);
	EndIf;
	
EndProcedure

// Opens the multi-line comment editing form.
//
// Parameters:
//  MultilineText - String -  arbitrary text that you want to edit.
//  OwnerForm      - ClientApplicationForm -  a form where you can enter a comment in the field.
//  AttributeName       - String -  name of the form details that the user entered comment will be placed in.
//                                By default, " Object.Comment".
//  Title          - String -  the text that you want to display in the header of the form.
//                                By default, "Comment".
//
// Example:
//  General purpose client.Show The Form Of Editing The Comment(
//  	Element.Edit Text, This Is An Object, " Object.Comment");
//
Procedure ShowCommentEditingForm(
	Val MultilineText, 
	Val OwnerForm, 
	Val AttributeName = "Object.Comment", 
	Val Title = Undefined) Export
	
	Context = New Structure;
	Context.Insert("OwnerForm", OwnerForm);
	Context.Insert("AttributeName", AttributeName);
	
	Notification = New NotifyDescription(
		"CommentInputCompletion", 
		CommonInternalClient, 
		Context);
	
	FormCaption = ?(Title <> Undefined, Title, NStr("en = 'Comment';"));
	
	ShowMultilineTextEditingForm(Notification, MultilineText, FormCaption);
	
EndProcedure

#EndRegion

#Region UserSettings

// Saves the user's personal settings.
//
// Parameters:
//  Settings - Structure:
//   * RemindAboutFileSystemExtensionInstallation  - Boolean -  indicates whether you need
//                                                               to be reminded to install the extension.
//   * AskConfirmationOnExit - Boolean -  request confirmation when the job is completed.
//
Procedure SavePersonalSettings(Settings) Export
	
	If Settings.Property("RemindAboutFileSystemExtensionInstallation") Then
		ApplicationParameters["StandardSubsystems.SuggestFileSystemExtensionInstallation"] = 
			Settings.RemindAboutFileSystemExtensionInstallation;
	EndIf;
	
	If Settings.Property("AskConfirmationOnExit") Then
		StandardSubsystemsClient.SetClientParameter("AskConfirmationOnExit",
			Settings.AskConfirmationOnExit);
	EndIf;
		
	If Settings.Property("PersonalFilesOperationsSettings") Then
		StandardSubsystemsClient.SetClientParameter("PersonalFilesOperationsSettings",
			Settings.PersonalFilesOperationsSettings);
	EndIf;
	
EndProcedure

#EndRegion

#Region Styles

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Parameters:
//  StyleColorName - String
//
// Returns:
//  Color
//
Function StyleColor(StyleColorName) Export
	
	Return CommonClientCached.StyleColor(StyleColorName);
	
EndFunction

// 
//
// Parameters:
//  StyleFontName - String
//
// Returns:
//  Font
//
Function StyleFont(StyleFontName) Export
	
	Return CommonClientCached.StyleFont(StyleFontName);
	
EndFunction

#EndRegion

#Region AddIns

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
// Returns:
//  Structure:
//      * Cached           - Boolean -  (default is True) use the component caching mechanism on the client.
//      * SuggestInstall - Boolean -  (default is True) offer to install.
//      * SuggestToImport  - Boolean -  (False by default) offer to download the component from ITS website.
//      * ExplanationText       - String -  what the component is needed for and what won't work if you don't install it.
//      * ObjectsCreationIDs - Array - the ID of creating an instance of an object module,
//                 used only for components that have multiple object creation IDs,
//                 when setting the ID parameter, it will be ignored.
//      * Isolated - Boolean, Undefined - 
//                 
//                 
//                 :
//                 
//                 See https://its.1c.eu/db/v83doc
//      * AutoUpdate - Boolean -  
//                 
//
//
// Example:
//
//  
//  
//                                             
//
Function AddInAttachmentParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("SuggestToImport", False);
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", Undefined);
	Parameters.Insert("AutoUpdate", True);
	
	Return Parameters;
	
EndFunction

// Connects a native API and COM component in asynchronous mode.
// The component must be stored in the configuration layout as a ZIP archive.
// The web client offers a dialog that prompts the user for installation actions.
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** Attached         - Boolean -  indicates whether the connection is enabled.
//          ** Attachable_Module - AddInObject  -  instance of an external component object;
//                                - FixedMap of KeyAndValue -  
//                                     :
//                                    *** Key - String -  id of the external component;
//                                    *** Value - AddInObject -  an instance of the object.
//          ** Location     - String - 
//                                           
//          ** SymbolicName   - String - 
//               
//               
//               
//          ** ErrorDescription     - String -  brief description of the error. When canceled by the user, an empty string.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  Id        - String - 
//  FullTemplateName      - String -  the full name of the layout used as the component location.
//  ConnectionParameters - Structure
//                       - Undefined - see the Component Connection parametersfunction.
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
Procedure AttachAddInFromTemplate(Notification, Id, FullTemplateName,
	ConnectionParameters = Undefined) Export
	
	Parameters = AddInAttachmentParameters();
	If ConnectionParameters <> Undefined Then
		FillPropertyValues(Parameters, ConnectionParameters);
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, Parameters);
	Context.Notification = Notification;
	Context.Id = Id;
	Context.Location = FullTemplateName;
	
	CommonInternalClient.AttachAddInSSL(Context);
	
EndProcedure

// 
//
// Returns:
//  Structure:
//      * ExplanationText - String -  what the component is needed for and what won't work if you don't install it.
//
// Example:
//
//  
//  
//                                           
//
Function AddInInstallParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ExplanationText", "");
	
	Return Parameters;
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// The component must be stored in the configuration layout as a ZIP archive.
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** IsSet    - Boolean -  indicates the installation.
//          ** ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  FullTemplateName    - String                  -  the full name of the layout used as the component location.
//  InstallationParameters - Structure
//                     - Undefined - see the function parameterstablement components.
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
Procedure InstallAddInFromTemplate(Notification, FullTemplateName, InstallationParameters = Undefined) Export
	
	Parameters = AddInInstallParameters();
	If InstallationParameters <> Undefined Then
		FillPropertyValues(Parameters, InstallationParameters);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Notification", Notification);
	Context.Insert("Location", FullTemplateName);
	Context.Insert("ExplanationText", Parameters.ExplanationText);
	Context.Insert("Id", FullTemplateName);
	
	CommonInternalClient.InstallAddInSSL(Context);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// 
// 
// 
// 
//
// Parameters:
//  FullTemplateName    - String                  -  the full name of the layout used as the component location.
//  InstallationParameters - Structure
//                     - Undefined - see the function parameterstablement components.
//
// Returns:
//		Structure - :
//          * IsSet    - Boolean -  indicates the installation.
//          * ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//
Async Function InstallAddInFromTemplateAsync(FullTemplateName, InstallationParameters = Undefined) Export
	
	Parameters = AddInInstallParameters();
	If InstallationParameters <> Undefined Then
		FillPropertyValues(Parameters, InstallationParameters);
	EndIf;
	
	Context = New Structure;
	Context.Insert("Location", FullTemplateName);
	Context.Insert("ExplanationText", Parameters.ExplanationText);
	Context.Insert("Id", FullTemplateName);
	
	Return Await CommonInternalClient.InstallAddInSSLAsync(Context);
	
EndFunction

// 
// 
//
// Parameters:
//  Id        - String - 
//  FullTemplateName      - String -  the full name of the layout used as the component location.
//  ConnectionParameters - Structure
//                       - Undefined - See AddInAttachmentParameters.
//
// Returns:
// 	 Structure - :
//    * Attached         - Boolean -  indicates whether the connection is enabled.
//    * Attachable_Module - AddInObject  -  instance of an external component object;
//                         - FixedMap of KeyAndValue -  
//                           :
//                             ** Key - String -  id of the external component;
//                             ** Value - AddInObject -  an instance of the object.
//    * Location     - String - 
//                                    
//    * SymbolicName   - String - 
//         
//         
//    * ErrorDescription     - String -  brief description of the error. When canceled by the user, an empty string.
//
Async Function AttachAddInFromTemplateAsync(Id, FullTemplateName,
	ConnectionParameters = Undefined) Export
	
	Parameters = AddInAttachmentParameters();
	If ConnectionParameters <> Undefined Then
		FillPropertyValues(Parameters, ConnectionParameters);
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, Parameters);
	Context.Id = Id;
	Context.Location = FullTemplateName;
	
	Return Await CommonInternalClient.AttachAddInSSLAsync(Context);
	
EndFunction

// 

#EndRegion

#EndRegion

#Region ExternalConnection

////////////////////////////////////////////////////////////////////////////////
// 

// Performs component registration "comcntr.dll" for the current version of the platform.
// If the registration is successful, it prompts the user to restart the client session 
// in order for the registration to take effect.
//
// Called before client code that uses the COM connection Manager (V83. COMConnector)
// and is initiated by interactive user actions.
// 
// Parameters:
//  RestartSession - Boolean -  if True,
//      the session restart dialog will be called after registering the COM connector.
//  Notification - NotifyDescription - :
//      * IsRegistered - Boolean -  True if the COM connector is registered without errors.
//      * AdditionalParameters - Arbitrary -  the value that was specified 
//            when creating the object of the announcement description.
//
// Example:
//  Zaregistrirovatsya();
//
Procedure RegisterCOMConnector(Val RestartSession = True, 
	Val Notification = Undefined) Export
	
	Context = New Structure;
	Context.Insert("RestartSession", RestartSession);
	Context.Insert("Notification", Notification);
	
	If CommonInternalClient.RegisterCOMConnectorRegistrationIsAvailable() Then 
	
		ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
#If Not WebClient And Not MobileClient Then
		ApplicationStartupParameters.CurrentDirectory = BinDir();
#EndIf
		ApplicationStartupParameters.Notification = New NotifyDescription(
			"RegisterCOMConnectorOnCheckRegistration", CommonInternalClient, Context);
		ApplicationStartupParameters.WaitForCompletion = True;
		
		CommandText = "regsvr32.exe /n /i:user /s comcntr.dll";
		
		FileSystemClient.StartApplication(CommandText, ApplicationStartupParameters);
		
	Else 
		
		CommonInternalClient.RegisterCOMConnectorNotifyOnError(Context);
		
	EndIf;
	
EndProcedure

// Establishes an external connection to the information base based on the passed connection parameters and returns it.
//
// See Common.EstablishExternalConnectionWithInfobase.
//
// Parameters:
//  Parameters - See CommonClientServer.ParametersStructureForExternalConnection
// 
// Returns:
//  Structure:
//    * Join - COMObject
//                 - Undefined - 
//    * BriefErrorDetails - String -  short description of the error;
//    * DetailedErrorDetails - String -  detailed description of the error;
//    * AddInAttachmentError - Boolean -  COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	ConnectionNotAvailable = IsLinuxClient() Or IsMacOSClient();
	BriefErrorDetails = NStr("en = 'Only Windows clients support direct infobase connections.';");
	
	Return CommonInternalClientServer.EstablishExternalConnectionWithInfobase(Parameters, ConnectionNotAvailable, BriefErrorDetails);
	
EndFunction

#EndRegion

#Region Backup

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether it is possible to perform a backup in user mode.
//
// Returns:
//  Boolean - 
//
Function PromptToBackUp() Export
	
	Result = False;
	SSLSubsystemsIntegrationClient.OnCheckIfCanBackUpInUserMode(Result);
	Return Result;
	
EndFunction

// Prompts the user to create a backup.
Procedure PromptUserToBackUp() Export
	
	SSLSubsystemsIntegrationClient.OnPromptUserForBackup();
	
EndProcedure

#EndRegion
#Region ObsoleteProceduresAndFunctions

// Deprecated.
//  
//  
//  
//
// 
// 
//
// Parameters:
//  Ref - String -  link to go to.
//
Procedure GoToLink(Ref) Export
	
	#If ThickClientOrdinaryApplication Then
		// 
		Notification = New NotifyDescription;
		BeginRunningApplication(Notification, Ref);
	#Else
		GotoURL(Ref);
	#EndIf
	
EndProcedure

// Deprecated.
// 
// 
//
// Parameters:
//   OnCloseNotifyDescription    - NotifyDescription - 
//                                    :
//                                      
//                                      
//                                                                               
//   SuggestionText                - String -  message text. If omitted, the default text is displayed.
//   CanContinueWithoutInstalling - Boolean -  if True, the continue button will be shown
//                                              . If False, the Cancel button will be shown.
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
Procedure ShowFileSystemExtensionInstallationQuestion(
		OnCloseNotifyDescription, 
		SuggestionText = "", 
		CanContinueWithoutInstalling = True) Export
	
	FileSystemClient.AttachFileOperationsExtension(
		OnCloseNotifyDescription, 
		SuggestionText, 
		CanContinueWithoutInstalling);
	
EndProcedure

// Deprecated.
// 
// 
// 
// 
//
// Parameters:
//  OnCloseNotifyDescription - NotifyDescription - 
//                                                     :
//                                                      
//                                                      
//  SuggestionText    - String -  text with a suggestion to connect the extension to work with 1C:Company. 
//                                 If omitted, the default text is displayed.
//  WarningText - String -  text of the warning that the operation cannot be continued. 
//                                 If omitted, the default text is displayed.
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
Procedure CheckFileSystemExtensionAttached(OnCloseNotifyDescription, Val SuggestionText = "", 
	Val WarningText = "") Export
	
	Parameters = New Structure("OnCloseNotifyDescription,WarningText", 
		OnCloseNotifyDescription, WarningText, );
	Notification = New NotifyDescription("CheckFileSystemExtensionAttachedCompletion",
		CommonInternalClient, Parameters);
	FileSystemClient.AttachFileOperationsExtension(Notification, SuggestionText);
	
EndProcedure

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function SuggestFileSystemExtensionInstallation() Export
	
	SystemInfo = New SystemInfo();
	ClientID = SystemInfo.ClientID;
	Return CommonServerCall.CommonSettingsStorageLoad(
		"ApplicationSettings/SuggestFileSystemExtensionInstallation", ClientID, True);
	
EndFunction

// Deprecated.
// 
// 
//
// Parameters:
//  PathToFile - String - 
//  Notification - NotifyDescription - 
//      :
//      * ApplicationStarted - Boolean -  True if the external application did not cause errors when opening.
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//
// Example:
//  General purpose client.Open the file in the preview program (document catalog () + " test. pdf");
//  General purpose client.OpenFile in the preview program (document Catalog() + "test.xlsx");
//
Procedure OpenFileInViewer(PathToFile, Val Notification = Undefined) Export
	
	If Notification = Undefined Then 
		FileSystemClient.OpenFile(PathToFile);
	Else
		OpeningParameters = FileSystemClient.FileOpeningParameters();
		OpeningParameters.ForEditing = True;
		FileSystemClient.OpenFile(PathToFile, Notification,, OpeningParameters);
	EndIf;
	
EndProcedure

// Deprecated.
// 
// 
//
// Parameters:
//  PathToDirectoryOrFile - String -  full path to the file or directory.
//
// Example:
//  
//  
//  
//  
//  
//  
//
Procedure OpenExplorer(PathToDirectoryOrFile) Export
	
	FileSystemClient.OpenExplorer(PathToDirectoryOrFile);
	
EndProcedure

// Deprecated.
// 
//
// 
//
// 
//  See OpenExplorer.
//  See OpenFileInViewer.
//
// Parameters:
//  URL - String -  the link to open.
//  Notification - NotifyDescription - 
//      :
//      * ApplicationStarted - Boolean -  True if the external application did not cause errors when opening.
//      * AdditionalParameters - Arbitrary -  the value that was specified when creating the message Description object.
//
// Example:
//  General purpose client.Open the navigation link ("e1cib/navigationpoint/startpage"); / / home page.
//  General purpose client.Open the navigation link ("v8help://1cv8/QueryLanguageFullTextSearchInData");
//  General purpose client.Open the navigation link("https://1c.com");
//  General purpose client.Open the navigation link ("mailto:help@1c.com");
//  General purpose client.Open the navigation link ("skype: echo123?call");
//
Procedure OpenURL(URL, Val Notification = Undefined) Export
	
	FileSystemClient.OpenURL(URL, Notification);
	
EndProcedure

// Deprecated.
// 
//
// Parameters:
//  Notification - NotifyDescription - :
//      * DirectoryName             - String -  path to the created folder.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  Extension - String -  a suffix in the folder name that will help you identify the folder during analysis.
//
Procedure CreateTemporaryDirectory(Val Notification, Extension = "") Export 
	
	FileSystemClient.CreateTemporaryDirectory(Notification, Extension);
	
EndProcedure

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function IsOSXClient() Export
	
	ClientPlatformType = ClientPlatformType();
	Return ClientPlatformType = PlatformType.MacOS_x86
		Or ClientPlatformType = PlatformType.MacOS_x86_64;
	
EndFunction

#EndRegion

#EndRegion
