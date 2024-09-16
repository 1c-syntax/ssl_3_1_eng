///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Retrieves a file from the Internet via http(s) or ftp and saves it to the specified path on the client.
// Not available when working in the web client. When working in the web client, you must use the same
// server procedures for downloading files.
//
// Parameters:
//   URL                - String -  url of the file in the format [Protocol://]<Server>/<Path to the file on the server>.
//   ReceivingParameters - See GetFilesFromInternetClientServer.FileGettingParameters.
//   WriteError1   - Boolean -  indicates whether an error should be recorded in the log when the file is received.
//
// Returns:
//   Structure - :
//      * Status            - Boolean -  True if the file was received successfully.
//      * Path              - String -  the path to the file on the client, the key is used only if the status is True.
//      * ErrorMessage - String -  error message if the status is False.
//      * Headers         - Map - see the syntax assistant for a description of the Headers parameter of the NTTROVET object.
//      * StatusCode      - Number - 
//                                    
//
Function DownloadFileAtClient(Val URL, Val ReceivingParameters = Undefined, Val WriteError1 = True) Export
	
#If WebClient Then
	Raise NStr("en = 'Cannot download files in the web client.';");
#Else
	
	Result = GetFilesFromInternetInternalServerCall.DownloadFile(URL, ReceivingParameters, WriteError1);
	
	If ReceivingParameters <> Undefined
		And ReceivingParameters.PathForSaving <> Undefined Then
		
		PathForSaving = ReceivingParameters.PathForSaving;
	Else
		PathForSaving = GetTempFileName(); // 
	EndIf;
	
	If Result.Status Then
		// 
		GetFile(Result.Path, PathForSaving, False); 
		// 
		Result.Path = PathForSaving;
	EndIf;
	
	Return Result;
	
#EndIf
	
EndFunction

// Opens a form to enter the parameters of the proxy server.
//
// Parameters:
//    FormParameters - Structure -  parameters of the form to open.
//
Procedure OpenProxyServerParametersForm(FormParameters = Undefined) Export
	
	OpenForm("CommonForm.ProxyServerParameters", FormParameters);
	
EndProcedure

#EndRegion
