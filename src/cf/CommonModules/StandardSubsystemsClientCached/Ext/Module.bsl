///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// See StandardSubsystemsClient.ClientParametersOnStart
// ().
Function ClientParametersOnStart() Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	CheckIfAppStartupFinished(True);
	
	ApplicationStartParameters = ApplicationParameters["StandardSubsystems.ApplicationStartParameters"];
	
	Parameters = New Structure;
	Parameters.Insert("RetrievedClientParameters", Undefined);
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		And TypeOf(ApplicationStartParameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.Insert("RetrievedClientParameters", CommonClient.CopyRecursive(
			ApplicationStartParameters.RetrievedClientParameters));
	EndIf;
	
	If ApplicationStartParameters.Property("SkipClearingDesktopHiding") Then
		Parameters.Insert("SkipClearingDesktopHiding");
	EndIf;
	
	If ApplicationStartParameters.Property("InterfaceOptions")
	   And TypeOf(Parameters.RetrievedClientParameters) = Type("Structure") Then
		
		Parameters.RetrievedClientParameters.Insert("InterfaceOptions");
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillInTheClientParametersOnTheServer(Parameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.FillInTheClientParametersOnTheServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	ClientParameters = StandardSubsystemsServerCall.ClientParametersOnStart(Parameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsServerCall.ClientParametersOnStart");
	
	If Indicators <> Undefined And ValueIsFilled(ClientParameters.PerformanceIndicators_) Then
		CommonClientServer.SupplementArray(Indicators,
			ClientParameters.PerformanceIndicators_);
	EndIf;
	
	If ApplicationStartParameters.Property("RetrievedClientParameters")
		And ApplicationStartParameters.RetrievedClientParameters <> Undefined
		And Not ApplicationStartParameters.Property("InterfaceOptions") Then
		
		ApplicationStartParameters.Insert("InterfaceOptions", ClientParameters.InterfaceOptions);
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillClientParameters(ClientParameters);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.FillClientParameters");
	
	// Updating the desktop hiding status on client by the state on server.
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.HideDesktopOnStart(
		Parameters.HideDesktopOnStart, True);
	AddMainIndicator(True, Indicators, StartMoment,
		"StandardSubsystemsClient.HideDesktopOnStart");
	
	AddMainIndicator(True, Indicators, CommonStartTime,
		"StandardSubsystemsClientCached.ClientParametersOnStart", True);
	
	Return ClientParameters;
	
EndFunction

// See StandardSubsystemsClient.ClientRunParameters
// ().
Function ClientRunParameters() Export
	
	CommonStartTime = CurrentUniversalDateInMilliseconds();
	Indicators = ?(StandardSubsystemsClientServer.ShouldRegisterPerformanceIndicators(),
		New Array, Undefined);
	
	CheckIfAppStartupFinished();
	
	ClientProperties = New Structure;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillInTheClientParametersOnTheServer(ClientProperties);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsClient.FillInTheClientParametersOnTheServer");
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	ClientParameters = StandardSubsystemsServerCall.ClientRunParameters(ClientProperties);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsServerCall.ClientRunParameters");
	
	If Indicators <> Undefined And ValueIsFilled(ClientParameters.PerformanceIndicators_) Then
		CommonClientServer.SupplementArray(Indicators,
			ClientParameters.PerformanceIndicators_);
	EndIf;
	
	StartMoment = CurrentUniversalDateInMilliseconds();
	StandardSubsystemsClient.FillClientParameters(ClientParameters);
	AddMainIndicator(False, Indicators, StartMoment,
		"StandardSubsystemsClient.FillClientParameters");
	
	AddMainIndicator(False, Indicators, CommonStartTime,
		"StandardSubsystemsClientCached.ClientRunParameters", True);
	
	Return ClientParameters;
	
EndFunction

// See StandardSubsystemsCached.RefsByPredefinedItemsNames
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	Return StandardSubsystemsServerCall.RefsByPredefinedItemsNames(FullMetadataObjectName);
	
EndFunction

Procedure CheckIfAppStartupFinished(OnlyBeforeSystemStartup = False)
	
	ParameterName = "StandardSubsystems.ApplicationStartCompleted";
	If ApplicationParameters[ParameterName] = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Exception occurred during startup.
			           |
			           |Technical details:
			           |Invalid %1 call during startup.
			           |The first procedure that is called from the %2 event handler must be %3.'"),
			"StandardSubsystemsClient.ClientRunParameters",
			"BeforeStart", 
			"StandardSubsystemsClient.BeforeStart");
		Raise ErrorText;
	EndIf;
	
	If OnlyBeforeSystemStartup Then
		Return;
	EndIf;
	
	If Not StandardSubsystemsClient.ApplicationStartCompleted() Then
		If StandardSubsystemsClient.ApplicationStartupLogicDisabled() Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The action is unavailable when running with the %1 parameter.'"),
				"DisableSystemStartupLogic");
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An exception occurred during startup.
			           |
			           |Details:
			           |Invalid %1 call during startup. Call %2 while the procedure %3 is still running.
			           |The invoked procedures (most recent first):
			           |%4'"),
				"StandardSubsystemsClient.ClientRunParameters", 
				"StandardSubsystemsClient.ClientParametersOnStart",
				"StandardSubsystemsClient.BeforeStart",
				StandardSubsystemsClient.CalledProceduresBeforeStart());
		EndIf;
		Raise ErrorText;
	EndIf;

EndProcedure

Procedure AddMainIndicator(OnStart, Indicators, StartMoment, ProcedureName, Shared = False)
	
	If Indicators = Undefined Then
		Return;
	EndIf;
	
	Duration = CurrentUniversalDateInMilliseconds() - StartMoment;
	If Not Shared And Not ValueIsFilled(Duration) Then
		Return;
	EndIf;
	
	Text = Format(Duration / 1000, "ND=6; NFD=3; NZ=000,000; NLZ=") + " " + ProcedureName;
	
	If Shared Then
		Indicators.Insert(0, Text);
		WriteIndicators(OnStart, Indicators, Duration);
		Return;
	Else
		Indicators.Add("  " + Text);
	EndIf;
	
EndProcedure

Procedure WriteIndicators(OnStart, Indicators, TotalDuration)
	
	Comment = StrConcat(Indicators, Chars.LF);
	
	CallStack = "";
	Try
		Raise NStr("en = 'Call stack:'");
	Except
		CallStack = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	StandardSubsystemsServerCall.WritePerformanceIndicators(OnStart, Comment, CallStack);
	
EndProcedure

#Region ForMetadataObjectIDsCatalog

// See Catalogs.MetadataObjectIDs.IDPresentation
Function MetadataObjectIDPresentation(Ref) Export
	
	Return StandardSubsystemsServerCall.MetadataObjectIDPresentation(Ref);
	
EndFunction

#EndRegion

#EndRegion