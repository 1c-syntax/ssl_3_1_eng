///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ClientID")
		Or Not Parameters.Property("ClientSecret") Then
		
		Raise NStr("en = 'Эта форма не предназначена для непосредственного открытия.'",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	HTMLField = DataProcessors.ExchangeMessageTransportYandexDisk.GetTemplate("ReceiveToken_ru").GetText();
	
	FillPropertyValues(ThisObject, Parameters, "ClientID,ClientSecret");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GetToken(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ClientID", ClientID);
	
	Notification = New CallbackDescription("GetTokenCompletion", ThisObject);
	
	OpenForm("DataProcessor.ExchangeMessageTransportYandexDisk.Form.AuthorizationForm",
		FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GetTokenCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Code = Result;
	
	Result = GetEndTokenOnServer();
		
	Close(Result);
	
EndProcedure

&AtServer
Function GetEndTokenOnServer()

	ServerName = "oauth.yandex.ru";
	ResourceAddress = "/token";
	
	QueryString = "grant_type=authorization_code" +
		"&code=" + Code + 
		"&client_id=" + ClientID + 
		"&client_secret=" + ClientSecret;
	
	Headers = New Map;
	Headers.Insert("Content-Type", "application/x-www-form-urlencoded");
	Headers.Insert("Content-Length", Format(StrLen(QueryString), "NG="));
	
	Query = New HTTPRequest(ResourceAddress, Headers);
	Query.SetBodyFromString(QueryString);
	
	SecureConnection = CommonClientServer.NewSecureConnection();
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Proxy = ModuleNetworkDownload.GetProxy("https");
	EndIf;
	Join = New HTTPConnection(ServerName, 443,,, Proxy, 20, SecureConnection);
	Response = Join.Post(Query);
	ResponseBody = Response.GetBodyAsString(TextEncoding.UTF8);
	QueryResult = ExchangeMessagesTransport.JSONValue(ResponseBody);
		
	If Response.StatusCode <> 200 Then
		
		ErrorMessage = QueryResult["message"];
		Common.MessageToUser(ErrorMessage);
		
		Return Undefined;
		
	EndIf;
	
	Result = New Structure();
	Result.Insert("AccessToken", QueryResult["access_token"]);
	Result.Insert("RefreshToken", QueryResult["refresh_token"]);
	Result.Insert("ExpiresIn", CurrentSessionDate() + QueryResult["expires_in"]);
	Result.Insert("ClientID", ClientID);
	Result.Insert("ClientSecret", ClientSecret);
	
	Return Result;
	
EndFunction

#EndRegion