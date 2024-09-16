///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns data from the list of objects of the specified metadata object as a system view.
// 
// Parameters:
//  FullTableName - String -  name of the table corresponding to the metadata object.
// 
// Returns:
//  String - 
//
Function GetTableObjects(FullTableName) Export
	
	Return ValueToStringInternal(Common.ValueFromXMLString(DataExchangeServer.GetTableObjects(FullTableName)));
	
EndFunction

// Returns data from the list of objects of the specified metadata object as an XML string.
// 
// Parameters:
//  FullTableName - String -  name of the table corresponding to the metadata object.
// 
// Returns:
//  String - 
//
Function GetTableObjects_2_0_1_6(FullTableName) Export
	
	Return DataExchangeServer.GetTableObjects(FullTableName);
	
EndFunction

// Returns the specified properties (Synonym, Hierarchical) of the metadata object.
// 
// Parameters:
//  FullTableName - String -  name of the table corresponding to the metadata object.
// 
// Returns:
//  СтруктураНастроек - :
//    * Synonym - String -  synonym.
//    * Hierarchical - String -  the attribute is Hierarchical.
//
Function MetadataObjectProperties(FullTableName) Export
	
	Return DataExchangeServer.MetadataObjectProperties(FullTableName);
	
EndFunction

#EndRegion

#Region Internal

// Uploads data for the information database node to a temporary file.
// (For internal use only).
//
Procedure ExportForInfobaseNode(Cancel,
												ExchangePlanName,
												InfobaseNodeCode,
												FullNameOfExchangeMessageFile,
												ErrorMessageString = "") Export
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	If Common.FileInfobase() Then
		
		Try
			DataExchangeServer.ExportForInfobaseNodeViaFile(ExchangePlanName, InfobaseNodeCode, FullNameOfExchangeMessageFile);
		Except
			Cancel = True;
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
		
	Else
		
		Address = "";
		
		Try
			
			DataExchangeServer.ExportToTempStorageForInfobaseNode(ExchangePlanName, InfobaseNodeCode, Address);
			
			MessageData = GetFromTempStorage(Address); // BinaryData
			MessageData.Write(FullNameOfExchangeMessageFile);
			
			DeleteFromTempStorage(Address);
			
		Except
			Cancel = True;
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
		
	EndIf;
	
EndProcedure

// Puts an entry in the log about the beginning of data exchange.
// (For internal use only).
//
Procedure WriteLogEventDataExchangeStart(ExchangeSettingsStructure) Export
	
	DataExchangeServer.WriteLogEventDataExchangeStart(ExchangeSettingsStructure);
	
EndProcedure

// Records the end of data exchange over an external connection.
// (For internal use only).
//
Procedure WriteExchangeFinish(ExchangeSettingsStructureExternalConnection) Export
	
	ExchangeSettingsStructureExternalConnection.ExchangeExecutionResult = Enums.ExchangeExecutionResults[ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString];
	
	DataExchangeServer.WriteExchangeFinishUsingExternalConnection(ExchangeSettingsStructureExternalConnection);
	
EndProcedure

// Gets the read-out rules for converting objects by the name of the exchange plan.
// (For internal use only).
//
//  Returns:
//    Read the rules for converting objects.
//
Function GetObjectConversionRules(ExchangePlanName, GetCorrespondentRules = False) Export
	
	Return DataExchangeServer.GetObjectConversionRulesViaExternalConnection(ExchangePlanName, GetCorrespondentRules);
	
EndFunction

// Gets the structure of the exchange settings.
// (For internal use only).
//
Function ExchangeSettingsStructure(Structure) Export
	
	Return DataExchangeServer.ExchangeOverExternalConnectionSettingsStructure(DataExchangeEvents.CopyStructure(Structure));
	
EndFunction

// Checks the existence of an exchange plan with the specified name.
// (For internal use only).
//
Function ExchangePlanExists(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans.Find(ExchangePlanName) <> Undefined;
	
EndFunction

// Gets the default database prefix via an external connection.
// Wrapper for the function of the same name in the module being redefined.
// (For internal use only).
//
Function DefaultInfobasePrefix() Export
	
	InfobasePrefix = Undefined;
	DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(InfobasePrefix);
	
	Return InfobasePrefix;
	
EndFunction

// Checks whether version discrepancies should be checked in the conversion rules.
//
Function WarnAboutExchangeRuleVersionMismatch(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "WarnAboutExchangeRuleVersionMismatch");
	
EndFunction

// Returns whether the full Right role is available.
// (For internal use only).
//
Function RoleAvailableFullAccess() Export
	
	Return Users.IsFullUser(, True);
	
EndFunction

// Returns the name of the predefined exchange plan node.
// (For internal use only).
//
Function PredefinedExchangePlanNodeDescription(ExchangePlanName) Export
	
	Return DataExchangeServer.PredefinedExchangePlanNodeDescription(ExchangePlanName);
	
EndFunction

// Returns the code of the predefined exchange plan node.
// (For internal use only).
//
Function PredefinedExchangePlanNodeCode(ExchangePlanName) Export
	
	Return DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
	
EndFunction

// For internal use.
//
Function GetCommonNodesData(Val ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return ValueToStringInternal(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// For internal use.
//
Function GetCommonNodesData_2_0_1_6(Val ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return Common.ValueToXMLString(DataExchangeServer.DataForThisInfobaseNodeTabularSections(ExchangePlanName));
	
EndFunction

// For internal use.
//
Function GetInfobaseParameters(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return DataExchangeServer.GetInfobaseParameters(ExchangePlanName, NodeCode, ErrorMessage);
	
EndFunction

// For internal use.
//
Function GetInfobaseParameters_2_0_1_6(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return DataExchangeServer.GetInfobaseParameters_2_0_1_6(ExchangePlanName, NodeCode, ErrorMessage);
	
EndFunction

// For internal use.
//
Function GetInfobaseParameters_3_0_2_2(Val ExchangePlanName, Val NodeCode, ErrorMessage,
	AdditionalParameters = Undefined) Export 
	
	Return DataExchangeServer.GetInfobaseParameters_3_0_2_2(ExchangePlanName, NodeCode, ErrorMessage,
		AdditionalParameters);
	
EndFunction

#EndRegion
