///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

Function SendAuthorizationCode(Query)
	
	Try
		
		QueryOptions = QueryOptions(Query);
		SendServerNotification(QueryOptions);
		
		ResponseCode = ResponseCodes().Success;
		ResponseText = TextOfSuccessfulResponse();
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		If ErrorInfo.Code = "UnknownRequest" Then
			ResponseCode = ResponseCodes().UnknownRequest;
		Else
			ResponseCode = ResponseCodes().InternalError;
		EndIf;
		
		ResponseText = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		EventName = EventName() + "." + NStr("en = 'Exception while sending authorization code'", DefaultLanguageCode());
		WriteLogEvent(EventName, EventLogLevel.Error, , , ResponseText);
		
	EndTry;
	
	Response = New HTTPServiceResponse(ResponseCode);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString(ResponseText);
	
	Return Response;
	
EndFunction

Function CheckServiceAvailability(Query)
	
	ResponseCode = ResponseCodes().Success;
	
	Response = New HTTPServiceResponse(ResponseCode);
	Response.Headers.Insert("Content-Type", "text/html; charset=utf-8");
	Response.SetBodyFromString("soccess");
	
	Return Response;
	
EndFunction

#EndRegion

#Region Private

Function QueryOptions(Query)
	
	IncomingRequestParameters = Query.QueryOptions;
	
	ProcessedRequestParameters = New Structure;
	ProcessedRequestParameters.Insert("AuthorizationCode");
	ProcessedRequestParameters.Insert("SessionNumber");
	ProcessedRequestParameters.Insert("AreaNumber");
	ProcessedRequestParameters.Insert("QueryID");
	ProcessedRequestParameters.Insert("UserIdentificator");
	
	FillInAuthorizationCode(IncomingRequestParameters, ProcessedRequestParameters);
	FillInSessionNumber(IncomingRequestParameters, ProcessedRequestParameters);
	FillInAreaNumber(IncomingRequestParameters, ProcessedRequestParameters);
	FillInRequestId(IncomingRequestParameters, ProcessedRequestParameters);
	FillInUserId(IncomingRequestParameters, ProcessedRequestParameters);
	
	Return ProcessedRequestParameters;
	
EndFunction

Procedure FillInAuthorizationCode(Source, Receiver)
	
	AuthorizationCode = Source.Get("code");
	
	If AuthorizationCode = Undefined Then
		ResponseText = NStr("en = 'The required request parameter ""code"" is not filled in.'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndIf;
	
	Receiver.AuthorizationCode = AuthorizationCode;
	
EndProcedure

Procedure FillInSessionNumber(Source, Receiver)
	
	SessionNumber = Source.Get("session");
	
	If SessionNumber = Undefined Then
		ResponseText = NStr("en = 'The required request parameter ""session"" is not filled in.'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndIf;
	
	Try
		SessionNumber = Number(SessionNumber);
	Except
		ResponseText = NStr("en = 'Request parameter ""session"" is not a number'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndTry;
	
	Receiver.SessionNumber = SessionNumber;
	
EndProcedure

Procedure FillInAreaNumber(Source, Receiver)
	
	AreaNumber = Source.Get("zone");
	
	If AreaNumber = Undefined Then
		ResponseText = NStr("en = 'The required request parameter ""zone"" is not filled in.'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndIf;
	
	Try
		AreaNumber = Number(AreaNumber);
	Except
		ResponseText = NStr("en = 'Request parameter ""zone"" is not a number'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndTry;
	
	Receiver.AreaNumber = AreaNumber;
	
EndProcedure

Procedure FillInRequestId(Source, Receiver)
	
	QueryID = Source.Get("request_id");
	
	If QueryID = Undefined Then
		ResponseText = NStr("en = 'The required request parameter ""request_id"" is not filled in.'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndIf;
	
	Try
		QueryID = New UUID(QueryID);
	Except
		ResponseText = NStr("en = 'Request parameter ""request_id"" is not a unique ID'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndTry;
	
	Receiver.QueryID = QueryID;
	
EndProcedure

Procedure FillInUserId(Source, Receiver)
	
	UserIdentificator = Source.Get("user_id");
	
	If UserIdentificator = Undefined Then
		ResponseText = NStr("en = 'The required request parameter ""user_id"" is not filled in.'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndIf;
	
	Try
		UserIdentificator = New UUID(UserIdentificator);
	Except
		ResponseText = NStr("en = 'Request parameter ""user_id"" is not a unique ID'", DefaultLanguageCode());
		Raise(ResponseText, , "UnknownRequest");
	EndTry;
	
	Receiver.UserIdentificator = UserIdentificator;
	
EndProcedure

Procedure SendServerNotification(QueryOptions)
	
	Context = New Structure;
	Context.Insert("AuthorizationCode", QueryOptions.AuthorizationCode);
	Context.Insert("QueryID", QueryOptions.QueryID);
	
	ServerNotificationParameters = New Structure;
	ServerNotificationParameters.Insert("EventName", "OpenAuthorizationOfMailService");
	ServerNotificationParameters.Insert("Context", Context);
	
	ServerNotificationName = EmailOperationsInternalClientServer.ServerNotificationName();
	RecipientsOfServerNotification = RecipientsOfServerNotification(QueryOptions);
	
	ServerNotifications.SendServerNotification(
		ServerNotificationName,
		ServerNotificationParameters,
		RecipientsOfServerNotification,
		True);
	
EndProcedure

Function RecipientsOfServerNotification(QueryOptions)
	
	RecipientsOfServerNotification = New Map;
	
	ActiveSessionsOfMonthEndClosing = GetInfoBaseSessions();
	RequiredSession = Undefined;
	
	For Each ActiveSession In ActiveSessionsOfMonthEndClosing Do
		If ActiveSession.SessionNumber = QueryOptions.SessionNumber Then
			RequiredSession = ActiveSession;
			Break;
		EndIf;
	EndDo;
	
	SessionKey = CommonClientServer.ValueInArray(ServerNotifications.SessionKey(RequiredSession));
	RecipientsOfServerNotification.Insert(QueryOptions.UserIdentificator, SessionKey);
	
	Return RecipientsOfServerNotification;
	
EndFunction

Function TextOfSuccessfulResponse()
	
	TextOfSuccessfulResponse = "<!DOCTYPE html>
		|<html>
		|<head>
		|    <meta charset='utf-8'>
		|    <title>Authorization completed_</title>
		|    <style>
		|        * { margin: 0; padding: 0; box-sizing: border-box; }
		|        body {
		|            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
		|            text-align: center;
		|            padding: 60px 20px;
		|            background: #F7FAFC url(" + CatDataURL() + ") no-repeat center bottom;
		|            background-size: contain;
		|            color: #2D3748;
		|            min-height: 100vh;
		|            display: flex;
		|            align-items: center;
		|            justify-content: center;
		|        }
		|        .container {
		|            max-width: 420px;
		|            background: rgba(255,255,255,0.9);
		|            padding: 40px 30px;
		|            border-radius: 16px;
		|            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
		|        }
		|        .message {
		|            font-size: 24px;
		|            margin-bottom: 12px;
		|            font-weight: 600;
		|        }
		|        p {
		|            font-size: 18px;
		|            color: #4A5568;
		|            line-height: 1.6;
		|        }
		|    </style>
		|</head>
		|<body>
		|    <div class='container'>
		|        <div class='message'>Authorization completed_</div>
		|        <p>ThisOne tab can close</p>
		|    </div>
		|    <script>
		|        if (window.history && window.history.replaceState) {
		|            window.history.replaceState({}, document.title, window.location.pathname);
		|        }
		|        window.close();
		|    </script>
		|</body>
		|</html>";
		
	Return TextOfSuccessfulResponse;
	
EndFunction

Function CatDataURL()
	
	Picture = PictureLib.CatOpenAuthorizationOfMailService;
	BinaryData = Picture.GetBinaryData();
	
	Base64Row = Base64String(BinaryData);
	Base64Row = StrReplace(Base64Row, Chars.CR, "");
	Base64Row = StrReplace(Base64Row, Chars.LF, "");
	
	CatDataURL = "data:image/svg+xml;base64," + Base64Row;
	
	Return CatDataURL;
	
EndFunction

Function ResponseCodes()
	
	ResponseCodes = New Structure;
	ResponseCodes.Insert("Success", 200);
	ResponseCodes.Insert("UnknownRequest", 400);
	ResponseCodes.Insert("InternalError", 500);
	
	Return ResponseCodes;
	
EndFunction

Function DefaultLanguageCode()
	
	Return Common.DefaultLanguageCode();
	
EndFunction

Function EventName()
	
	Return NStr("en = 'Open authorization of the email service'", DefaultLanguageCode());
	
EndFunction

#EndRegion
