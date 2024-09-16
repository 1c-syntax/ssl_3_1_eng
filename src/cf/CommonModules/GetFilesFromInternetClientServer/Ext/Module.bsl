///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the structure of parameters for retrieving a file from the Internet.
//
// Returns:
//  Structure:
//     * PathForSaving            - String       -  the path on the server (including the file name) to save the downloaded file.
//                                                     Not filled in when saving a file to temporary storage.
//     * User                 - String       -  the user on whose behalf the connection is established.
//     * Password                       - String       -  password of the user from whom the connection was established.
//     * Port                         - Number        -  port of the server to which the connection is established.
//     * Timeout                      - Number        -  timeout for getting the file in seconds.
//     * SecureConnection         - Boolean       -  indicates whether a secure ftps or https connection is being used.
//                                    - OpenSSLSecureConnection
//                                    - Undefined - 
//     * IsPackageDeliveryCheckOnErrorEnabled - Boolean - 
//
//    :
//     * Headers                    - Map - see the syntax assistant for a description of the Headers parameter of the NTTRQUERY object.
//     * UseOSAuthentication - Boolean       - 
//                                                     
//
//    :
//     * PassiveConnection          - Boolean       -  this flag indicates that the connection must be passive (or active).
//     * SecureConnectionUsageLevel - FTPSecureConnectionUsageLevel - see the description
//         of the property of the same name in the platform's syntax assistant. The default value is Auto.
//
Function FileGettingParameters() Export
	
	ReceivingParameters = New Structure;
	ReceivingParameters.Insert("PathForSaving", Undefined);
	ReceivingParameters.Insert("User", Undefined);
	ReceivingParameters.Insert("Password", Undefined);
	ReceivingParameters.Insert("Port", Undefined);
	ReceivingParameters.Insert("Timeout", AutomaticTimeoutDetermination());
	ReceivingParameters.Insert("SecureConnection", Undefined);
	ReceivingParameters.Insert("PassiveConnection", Undefined);
	ReceivingParameters.Insert("Headers", New Map);
	ReceivingParameters.Insert("UseOSAuthentication", False);
	ReceivingParameters.Insert("SecureConnectionUsageLevel", Undefined);
	ReceivingParameters.Insert("IsPackageDeliveryCheckOnErrorEnabled", True);
	
	Return ReceivingParameters;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
//
// Parameters:
//    URLOrProtocol - String -  url in the [Protocol] format://]<Server>/<The path to the file on the server>,
//                              or the Protocol ID (http, ftp,...).
//
// Returns:
//    InternetProxy - 
//                     
//                     
//
Function GetProxy(Val URLOrProtocol) Export
	
#If WebClient Then
	Raise NStr("en = 'Web client does not support proxy server.';");
#Else
	
	AcceptableProtocols = New Map();
	AcceptableProtocols.Insert("HTTP",  True);
	AcceptableProtocols.Insert("HTTPS", True);
	AcceptableProtocols.Insert("FTP",   True);
	AcceptableProtocols.Insert("FTPS",  True);
	
	ProxyServerSetting = ProxyServerSetting();
	
	If StrFind(URLOrProtocol, "://") > 0 Then
		Protocol = SplitURL(URLOrProtocol).Protocol;
	Else
		Protocol = Lower(URLOrProtocol);
	EndIf;
	
	If AcceptableProtocols[Upper(Protocol)] = Undefined Then
		Protocol = "HTTP";
	EndIf;
	
	Return NewInternetProxy(ProxyServerSetting, Protocol);
	
#EndIf
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//    URL - String -  link to a resource on the Internet.
//
// Returns:
//    Structure:
//        * Protocol            - String -  the Protocol to access the resource.
//        * ServerName          - String -  the server where the resource is located.
//        * PathToFileAtServer - String -  path to the resource on the server.
//
Function SplitURL(Val URL) Export
	
	URLStructure1 = CommonClientServer.URIStructure(URL);
	
	Result = New Structure;
	Result.Insert("Protocol", ?(IsBlankString(URLStructure1.Schema), "http", URLStructure1.Schema));
	Result.Insert("ServerName", URLStructure1.ServerName);
	Result.Insert("PathToFileAtServer", URLStructure1.PathAtServer);
	
	Return Result;
	
EndFunction

// Deprecated.
// 
// 
//
// Parameters:
//     URIString1 - String - :
//                          
//
// Returns:
//    Structure - :
//        * Schema         - String -  URI scheme.
//        * Login         - String -  user name.
//        * Password        - String -  user password.
//        * ServerName    - String -  part <host>:< port> of the input parameter.
//        * Host          - String -  server name.
//        * Port          - String -  server port.
//        * PathAtServer - String -  the <path>part?<characteristic>#< anchor> of the input parameter.
//
Function URIStructure(Val URIString1) Export
	
	Return CommonClientServer.URIStructure(URIString1);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ObsoleteProceduresAndFunctions

// Service information for displaying current proxy settings and States for performing diagnostics.
//
// Returns:
//  Structure:
//     * ProxyConnection - Boolean -  indicates that the connection should be made via a proxy.
//     * Presentation - String -  representation of the currently configured proxy.
//
Function ProxySettingsState() Export
	
#If WebClient Then
	
	Result = New Structure;
	Result.Insert("ProxyConnection", False);
	Result.Insert("Presentation", NStr("en = 'Web client does not support proxy server.';"));
	Return Result;
	
#Else
	
	Return GetFilesFromInternetInternalServerCall.ProxySettingsState();
	
#EndIf
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function AutomaticTimeoutDetermination() Export
	
	Return -1;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

#If Not WebClient Then

// Returns proxy by proxy settings for the specified Protocol.
//
// Parameters:
//   ProxyServerSetting -  Map of KeyAndValue:
//     * Key - String
//     * Value - Arbitrary
//    :
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
//   InternetProxy
//
Function NewInternetProxy(ProxyServerSetting, Protocol)
	
	If ProxyServerSetting = Undefined Then
		// 
		Return Undefined;
	EndIf;
	
	UseProxy = ProxyServerSetting.Get("UseProxy");
	If Not UseProxy Then
		// 
		Return New InternetProxy(False);
	EndIf;
	
	UseSystemSettings = ProxyServerSetting.Get("UseSystemSettings");
	If UseSystemSettings Then
		// 
		Return New InternetProxy(True);
	EndIf;
	
	// 
	Proxy = New InternetProxy;
	
	// 
	AdditionalSettings = ProxyServerSetting.Get("AdditionalProxySettings");
	ProxyByProtocol = Undefined;
	If TypeOf(AdditionalSettings) = Type("Map") Then
		ProxyByProtocol = AdditionalSettings.Get(Protocol);
	EndIf;
	
	UseOSAuthentication = ProxyServerSetting.Get("UseOSAuthentication");
	UseOSAuthentication = ?(UseOSAuthentication = True, True, False);
	
	If TypeOf(ProxyByProtocol) = Type("Structure") Then
		Proxy.Set(Protocol, ProxyByProtocol.Address, ProxyByProtocol.Port,
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	Else
		Proxy.Set(Protocol, ProxyServerSetting["Server"], ProxyServerSetting["Port"], 
			ProxyServerSetting["User"], ProxyServerSetting["Password"], UseOSAuthentication);
	EndIf;
	
	Proxy.BypassProxyOnLocal = ProxyServerSetting["BypassProxyOnLocal"];
	
	ExceptionsAddresses = ProxyServerSetting.Get("BypassProxyOnAddresses");
	If TypeOf(ExceptionsAddresses) = Type("Array") Then
		For Each ExceptionAddress In ExceptionsAddresses Do
			Proxy.BypassProxyOnAddresses.Add(ExceptionAddress);
		EndDo;
	EndIf;
	
	Return Proxy;
	
EndFunction

#EndIf

Function ProxyServerSetting()
	
	// 
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	ProxyServerSetting = GetFilesFromInternet.ProxySettingsAtServer();
#Else
	ProxyServerSetting = StandardSubsystemsClient.ClientRunParameters().ProxyServerSettings;
#EndIf
	
	// 
	
	Return ProxyServerSetting;
	
EndFunction

#EndRegion

#EndRegion