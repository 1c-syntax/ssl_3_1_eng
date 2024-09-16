///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Retrieves a file from the Internet via http(s) or ftp and saves it to the specified path on the server.
//
// Parameters:
//   URL                - String -  url of the file in the format [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters
//   WriteError1   - Boolean -  indicates whether an error should be recorded in the log when the file is received.
//
// Returns:
//   Structure:
//      * Status            - Boolean -  the result of getting the file.
//      * Path   - String   -  the path to the file on the server, the key is used only if the status is True.
//      * ErrorMessage - String -  error message if the status is False.
//      * Headers         - Map - see the syntax assistant for a description of the Headers parameter of the NTTROVET object.
//      * StatusCode      - Number - 
//                                    
//
Function DownloadFileAtServer(Val URL, ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "Server");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError1);
	
EndFunction

// Retrieves a file from the Internet via http(s) or ftp and saves it to temporary storage.
// Note: after receiving the file, you must clear the temporary storage yourself
// using the delete temporary Storage method. If you do not do this, the file will remain
// in the server's memory until the end of the session.
//
// Parameters:
//   URL                - String -  url of the file in the format [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters.
//   WriteError1   - Boolean -  indicates whether an error should be recorded in the log when the file is received.
//
// Returns:
//   Structure:
//      * Status            - Boolean -  the result of getting the file.
//      * Path              - String   -  address of temporary storage with binary file data,
//                            the key is used only if the status is True.
//      * ErrorMessage - String -  error message if the status is False.
//      * Headers         - Map - see the syntax assistant for a description of the Headers parameter of the NTTROVET object.
//      * StatusCode      - Number - 
//                                    
//
Function DownloadFileToTempStorage(Val URL, ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
	SavingSetting = New Map;
	SavingSetting.Insert("StorageLocation", "TemporaryStorage");
	
	Return GetFilesFromInternetInternal.DownloadFile(URL,
		ReceivingParameters, SavingSetting, WriteError1);
	
EndFunction

// Returns the proxy server setting for client-side Internet access
// for the current user.
//
// Returns:
//    Map of KeyAndValue:
//      * Key - String
//      * Value - Arbitrary
//    :
//      
//      
//      
//      
//      
//      
//      
//
Function ProxySettingsAtClient() Export
	
	UserName = Undefined;
	
	If Common.FileInfobase() Then
		
		// 
		// 
		
		CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
		BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
		IsScheduledJobSession = BackgroundJob <> Undefined And BackgroundJob.ScheduledJob <> Undefined;
		
		If IsScheduledJobSession Then
			
			If Not ValueIsFilled(BackgroundJob.ScheduledJob.UserName) Then 
				
				// 
				// 
				// 
				
				Sessions = GetInfoBaseSessions(); // Array of InfoBaseSession
				For Each Session In Sessions Do 
					If Session.ComputerName = CurrentInfobaseSession1.ComputerName Then 
						UserName = Session.User.Name;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Common.CommonSettingsStorageLoad("ProxyServerSetting", "",,, UserName);
	
EndFunction

// Returns proxy server settings on the 1C server side:Companies.
//
// Returns:
//   Map of KeyAndValue:
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
Function ProxySettingsAtServer() Export
	
	If Common.FileInfobase() Then
		Return ProxySettingsAtClient();
	Else
		SetPrivilegedMode(True);
		ProxySettingsAtServer = Constants.ProxyServerSetting.Get().Get();
		Return ?(TypeOf(ProxySettingsAtServer) = Type("Map"),
			ProxySettingsAtServer,
			Undefined);
	EndIf;
	
EndFunction

// Returns an object of Internetproxy to access the Internet.
// Acceptable protocols for creating an Internet Proxy are http, https, ftp, and ftps.
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
	
	Return GetFilesFromInternetInternal.NewInternetProxy(ProxySettingsAtServer(), URLOrProtocol);
	
EndFunction

// Starts diagnostics of the network resource.
// The service model returns only the error description.
//
// Parameters:
//  URL - String -  url of the resource to diagnose.
//  WriteError1 - Boolean -  indicates whether errors should be recorded in the log.
//  IsPackageDeliveryCheckEnabled - Boolean - 
//
// Returns:
//  Structure:
//    *  ErrorDescription    - String -  brief description of the error.
//    *  DiagnosticsLog - String -  detailed diagnostic log with technical details.
//
// Example:
//	
//	
//	
//	
//	
//
Function ConnectionDiagnostics(URL, WriteError1 = True, IsPackageDeliveryCheckEnabled = True) Export
	
	LongDesc = New Array;
	LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Accessing URL: %1.';"), 
		URL));
	LongDesc.Add(GetFilesFromInternetInternal.DiagnosticsLocationPresentation());
	
	If Common.DataSeparationEnabled() Then
		LongDesc.Add(
			NStr("en = 'Please contact the administrator.';"));
		
		ErrorDescription = StrConcat(LongDesc, Chars.LF);
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorDescription);
		Result.Insert("DiagnosticsLog", "");
		
		Return Result;
	EndIf;
	
	Log = New Array;
	If IsPackageDeliveryCheckEnabled Then
		Log.Add(
			NStr("en = 'Diagnostics log:
			           |Server availability test.
			           |See the error description in the next log record.';"));
	Else
		Log.Add(
			NStr("en = 'Diagnostics log:
			           |Monitoring server availability test.
			           |See the error details in the next log record.';"));
	EndIf;
	Log.Add();
	
	RefStructure = CommonClientServer.URIStructure(URL);
	
	ProxySettingsState = GetFilesFromInternetInternal.ProxySettingsState(RefStructure.Schema);
	ProxyConnection = ProxySettingsState.ProxyConnection;
	Log.Add(ProxySettingsState.Presentation);
	
	If ProxyConnection And Not ProxySettingsState.SystemProxySettingsUsed Then 
		
		LongDesc.Add(
			NStr("en = 'Connection diagnostics are not performed because a proxy server is configured.
			           |Please contact the administrator.';"));
		
	Else 
		
		ResourceServerAddress = RefStructure.Host;
		VerificationServerAddress = "google.com";
		
		If Metadata.CommonModules.Find("GetFilesFromInternetInternalLocalization") <> Undefined Then
			ModuleNetworkDownloadInternalLocalization = Common.CommonModule("GetFilesFromInternetInternalLocalization");
			VerificationServerAddress = ModuleNetworkDownloadInternalLocalization.VerificationServerAddress();
		EndIf;
		
		If IsPackageDeliveryCheckEnabled Then
			ResourceAvailabilityResult = GetFilesFromInternetInternal.CheckServerAvailability(ResourceServerAddress);
			
			Log.Add();
			Log.Add("1) " + ResourceAvailabilityResult.DiagnosticsLog);
		
			If ResourceAvailabilityResult.Available Then 
				
				LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Attempted to access a resource that does not exist on server %1,
					           |or some issues occurred on the remote server.';"),
					ResourceServerAddress));
				
			Else 
				
				VerificationResult = GetFilesFromInternetInternal.CheckServerAvailability(VerificationServerAddress);
				Log.Add("2) " + VerificationResult.DiagnosticsLog);
				
				If Not VerificationResult.Available Then
					
					LongDesc.Add(
						NStr("en = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall, antivirus, or other software.';"));
					
				Else 
					
					LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Server %1 is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall, antivirus, or other software.
						           |- Server is disabled or undergoing maintenance.';"),
						ResourceServerAddress));
					
					TraceLog = GetFilesFromInternetInternal.ServerRouteTraceLog(ResourceServerAddress);
					Log.Add("3) " + TraceLog);
					
				EndIf;
				
			EndIf;
		Else
			VerificationResult = GetFilesFromInternetInternal.CheckServerAvailability(VerificationServerAddress);
				Log.Add("1) " + VerificationResult.DiagnosticsLog);
				
				If Not VerificationResult.Available Then
					
					LongDesc.Add(
						NStr("en = 'No Internet access. Possible reasons:
						           |- Computer is not connected to the Internet.
						           | - Internet provider issues.
						           |- Access blocked by firewall, antivirus, or other software.';"));
					
				Else 
					
					LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Server %1 is currently unavailable. Possible reasons:
						           |- Internet provider issues.
						           |- Access blocked by firewall, antivirus, or other software.
						           |- Server is disabled or undergoing maintenance.';"),
						ResourceServerAddress));
					
					TraceLog = GetFilesFromInternetInternal.ServerRouteTraceLog(ResourceServerAddress);
					Log.Add("2) " + TraceLog);
					
				EndIf;
		EndIf;
		
	EndIf;
	
	ErrorDescription = StrConcat(LongDesc, Chars.LF);
	
	Log.Insert(0);
	Log.Insert(0, ErrorDescription);
	
	DiagnosticsLog = StrConcat(Log, Chars.LF);
	
	If WriteError1 Then
		WriteLogEvent(
			NStr("en = 'Connection diagnostics';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, DiagnosticsLog);
	EndIf;
	
	Result = New Structure;
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("DiagnosticsLog", DiagnosticsLog);
	
	Return Result;
	
EndFunction

// 
// 
// 
// 
//
// Parameters:
//  Size - Number -  file size in bytes.
//
// Returns:
//  Number
//
Function FileImportTimeout(Size) Export
	
	BytesInMegabyte = 1048576;
	
	Timeout = Round(Size / BytesInMegabyte * 128);
	If Timeout > 43200 Then
		Timeout = 43200;
	ElsIf Timeout < 30 Then
			Timeout = 30;
	EndIf;
	
	Return Timeout;
	
EndFunction

#EndRegion
