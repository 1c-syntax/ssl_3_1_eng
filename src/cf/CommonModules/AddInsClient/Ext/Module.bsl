///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Parameters for calling the external component Client procedure.Connect a component.
//
// Returns:
//  Structure:
//      * Cached - Boolean -  (default is True) use the component caching mechanism on the client.
//      * SuggestInstall - Boolean -  (default is True) suggest installing the component.
//      * SuggestToImport - Boolean -  (True by default) offer to download the component from ITS website.
//      * ExplanationText - String -  what the component is needed for and what won't work if you don't install it.
//      * ObjectsCreationIDs - Array -  array of object module instance creation ID strings,
//                used only for components that have multiple object creation IDs
//                . when setting the ID parameter, It will only be used to define the component.
//      * Isolated - Boolean, Undefined - 
//                
//                
//                :
//                
//                See https://its.1c.eu/db/v83doc
//      * AutoUpdate - Boolean - 
//                
//
// Example:
//
//  
//   
//      
//                 
//
Function ConnectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Cached", True);
	Parameters.Insert("SuggestInstall", True);
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated", Undefined);
	Parameters.Insert("AutoUpdate", True);
	
	Return Parameters;
	
EndFunction

// Connects a component executed using the Native API or COM technology on the client computer.
// The web client offers a dialog that prompts the user for installation actions.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** Attached - Boolean -  the sign connection;
//          ** Attachable_Module - AddInObject -  instance of an external component object;
//                                - FixedMap of KeyAndValue - 
//                                      :
//                                    *** Key - String -  id of the external component;
//                                    *** Value - AddInObject -  an instance of an external component object.
//          ** ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  Id - String - 
//  Version        - String -  version of the component.
//  ConnectionParameters - See AddInsClient.ConnectionParameters.
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
Procedure AttachAddInSSL(Notification, Id, Version = Undefined,
	ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		ConnectionParameters = ConnectionParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, ConnectionParameters);
	Context.Notification = Notification;
	Context.Id = Id;
	Context.Version = Version;
	
	AddInsInternalClient.AttachAddInSSL(Context);
	
EndProcedure

// Connects a COM component from the Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C 7.7 components). 
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** Attached - Boolean -  indicates whether the connection is enabled.
//          ** Attachable_Module - AddInObject  -  an instance of an external component object.
//          ** ErrorDescription - String -  brief description of the error.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  Id - String - 
//  ObjectCreationID - String -  id of the object module instance creation
//          (only for components whose object creation ID differs from the ProgID).
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
Procedure AttachAddInFromWindowsRegistry(Notification, Id,
	ObjectCreationID = Undefined) Export 
	
	Context = AddInsInternalClient.ConnectionContextComponentsFromTheWindowsRegistry();
	Context.Notification = Notification;
	Context.Id = Id;
	Context.ObjectCreationID = ObjectCreationID;
	
	AddInsInternalClient.AttachAddInFromWindowsRegistry(Context);
	
EndProcedure

// 
//
// Returns:
//  Structure:
//      * ExplanationText - String -  what the component is needed for and what won't work if you don't install it.
//      * SuggestToImport - Boolean -  offer to download the component from ITS website
//      * SuggestInstall - Boolean -  (False by default) suggest installing the component.
//
// Example:
//
//  
//   
//      
//                 
//
Function InstallationParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ExplanationText", "");
	Parameters.Insert("SuggestToImport", True);
	Parameters.Insert("SuggestInstall", False);
	
	Return Parameters;
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** IsSet - Boolean -  indicates the installation.
//          ** ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  Id - String - 
//  Version - String -  version of the component.
//  InstallationParameters - See InstallationParameters.
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
Procedure InstallAddInSSL(Notification, Id, Version = Undefined, 
	InstallationParameters = Undefined) Export
	
	If InstallationParameters = Undefined Then
		InstallationParameters = InstallationParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	Context.Notification = Notification;
	Context.Id = Id;
	Context.Version = Version;
	Context.ExplanationText = InstallationParameters.ExplanationText;
	Context.SuggestToImport = InstallationParameters.SuggestToImport;
	Context.SuggestInstall = InstallationParameters.SuggestInstall;
		
	AddInsInternalClient.InstallAddInSSL(Context);
	
EndProcedure


// 
// 
//
// Returns:
//  Structure:
//      * XMLFileName - String -  (optional) name of the file in the component to extract information from.
//      * XPathExpression - String -  (optional) XPath path to the information in the file.
//
// Example:
//
//  Boot parameters = Vneshneekonomicheskie.Parametersdiscoveringinformation();
//  Boot parameters.Filename XML = " INFO.XML";
//  Boot parameters.Expressionxpath = " //drivers/component/@type";
//
Function AdditionalInformationSearchParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("XMLFileName", "");
	Parameters.Insert("XPathExpression", "");
	
	Return Parameters;
	
EndFunction

// 
//
// Returns:
//  Structure:
//      * Id - String -(optional) ID of the external component object.
//      * Version - String -  (optional) version of the component.
//      * AdditionalInformationSearchParameters - Map of KeyAndValue - :
//          ** Key - String -  the identifier of the additional requested information.
//          ** Value - See AdditionalInformationSearchParameters.
// Example:
//
//  Boot parameters = Vneshneekonomicheskie.Boot parameters();
//  Boot parameters.ID = " InputDevice";
//  Boot parameters.Version = " 8.1.7.10";
//
Function ImportParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("Id", Undefined);
	Parameters.Insert("Version", Undefined);
	Parameters.Insert("AdditionalInformationSearchParameters", New Map);
	
	Return Parameters;
	
EndFunction

// Loads the components file to the external components directory in asynchronous mode. 
//
// Parameters:
//  Notification - NotifyDescription - :
//      * Result - Structure - :
//          ** Imported1 - Boolean -  indicates whether it is loading.
//          ** Id  - String - 
//          ** Version - String -  version of the downloaded component.
//          ** Description - String -  name of the loaded component.
//          ** AdditionalInformation - Map of KeyAndValue - 
//                     :
//               *** Key - See AdditionalInformationSearchParameters.
//               *** Value - See AdditionalInformationSearchParameters.
//      * AdditionalParameters - Structure -  the value that was specified when creating the message Description object.
//  ImportParameters - See ImportParameters.
//
// Example:
//
//  Boot parameters = Vneshneekonomicheskie.Boot parameters();
//  Boot parameters.ID = " InputDevice";
//  Boot parameters.Version = " 8.1.7.10";
//
//  Alert = New Message Description ("Load Componentfile After Loading Components", This Object);
//
//  Vneshneekonomicheskie.Upload A Component Of The File(Notification, Upload Parameters);
//
//  &Naciente
//  Procedure To Load A Component From A File After Loading Components(Result, Additional Parameters) Export
//
//      If The Result.Uploaded Then 
//          ID = Result.ID;
//          Version = Result.Version;
//      Conicelli;
//
//  End of procedure
//
Procedure ImportAddInFromFile(Notification, ImportParameters = Undefined) Export
	
	If ImportParameters = Undefined Then 
		ImportParameters = ImportParameters();
	EndIf;
	
	Context = AddInsInternalClient.ContextForLoadingComponentsFromAFile();
	Context.Notification = Notification;
	Context.Id = ImportParameters.Id;
	Context.Version = ImportParameters.Version;
	Context.AdditionalInformationSearchParameters = ImportParameters.AdditionalInformationSearchParameters;
	
	AddInsInternalClient.ImportAddInFromFile(Context);
	
EndProcedure

#Region ForCallsFromOtherSubsystems

// 
// 
// 
// 
//
// Parameters:
//  Id - String - 
//  Version        - String -  version of the component.
//  ConnectionParameters - See AddInsClient.ConnectionParameters.
//
//  Returns:  
//  	Structure - :
//          * Attached - Boolean -  the sign connection;
//          * Attachable_Module - AddInObject -  instance of an external component object;
//                                - FixedMap of KeyAndValue - 
//                                      :
//                                    *** 
//                                    *** 
//          * ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//
Async Function AttachAddInSSLAsync(Id, Version = Undefined,
	ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		ConnectionParameters = ConnectionParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	FillPropertyValues(Context, ConnectionParameters);
	Context.Id = Id;
	Context.Version = Version;
	
	Return Await AddInsInternalClient.AttachAddInSSLAsync(Context);
	
EndFunction

// Sets a component executed using the Native API technology and in asynchronous mode.
// Checks whether the component can be executed on the user's current client.
//
// Parameters:
//  Id - String - 
//  Version - String -  version of the component.
//  InstallationParameters - See InstallationParameters.
//
//  Returns:
//    Structure - :
//          * IsSet - Boolean -  indicates the installation.
//          * ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//
Async Function InstallAddInSSLAsync(Id, Version = Undefined, 
	InstallationParameters = Undefined) Export
	
	If InstallationParameters = Undefined Then
		InstallationParameters = InstallationParameters();
	EndIf;
	
	Context = CommonInternalClient.AddInAttachmentContext();
	Context.Id = Id;
	Context.Version = Version;
	Context.ExplanationText = InstallationParameters.ExplanationText;
	Context.SuggestToImport = InstallationParameters.SuggestToImport;
	Context.SuggestInstall = InstallationParameters.SuggestInstall;
		
	Return Await AddInsInternalClient.InstallAddInSSLAsync(Context);
	
EndFunction

// Connects a COM component from the Windows registry in asynchronous mode.
// (not recommended for backward compatibility with 1C 7.7 components). 
//
// Parameters:
//  Id - String - 
//  ObjectCreationID - String -  id of the object module instance creation
//          (only for components whose object creation ID differs from the ProgID).
//
//  Returns:
//  	Structure - :
//          * Attached - Boolean -  the sign connection;
//          * Attachable_Module - AddInObject -  instance of an external component object;
//                                - FixedMap of KeyAndValue - 
//                                      :
//                                    *** 
//                                    *** 
//          * ErrorDescription - String -  brief description of the error. When canceled by the user, an empty string.
//
Async Function AttachAddInFromWindowsRegistryAsync(Id,
	ObjectCreationID = Undefined) Export 
	
	Context = AddInsInternalClient.ConnectionContextComponentsFromTheWindowsRegistry();
	Context.Id = Id;
	Context.ObjectCreationID = ObjectCreationID;
	
	Return Await AddInsInternalClient.AttachAddInFromWindowsRegistryAsync(Context);
	
EndFunction

// End EquipmentSupport

#EndRegion

#EndRegion

#Region Internal

Procedure ShowAddIns() Export
	
	OpenForm("Catalog.AddIns.ListForm");
	
EndProcedure

#EndRegion