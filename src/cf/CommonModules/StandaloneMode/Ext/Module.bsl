///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The event handler for the account form in the Server, which
// is embedded in the forms of data elements
// (directory elements, documents, register entries, etc.)
// to block the form if it is an attempt to change undivided data
// received from the application in an offline workplace.
//
// Parameters:
//  CurrentObject       - CatalogObject
//                      - DocumentObject
//                      - ChartOfCharacteristicTypesObject
//                      - ChartOfAccountsObject
//                      - ChartOfCalculationTypesObject
//                      - BusinessProcessObject
//                      - TaskObject
//                      - ExchangePlanObject
//                      - InformationRegisterRecordManager - 
//  ReadOnly - Boolean -  the form view property Only.
//
Procedure ObjectOnReadAtServer(CurrentObject, ReadOnly) Export
	
	If Not ReadOnly Then
		
		MetadataObject = Metadata.FindByType(TypeOf(CurrentObject));
		StandaloneModeInternal.DefineDataChangeCapability(MetadataObject, ReadOnly);
		
	EndIf;
	
EndProcedure

// Disables automatic syncing between the app on the Internet
// and the offline workplace in cases when a password is not set to establish a connection.
//
// Parameters:
//  Source - InformationRegisterRecordSet.DataExchangeTransportSettings -  record of the transport settings register
//             that was changed.
//
Procedure DisableAutoDataSyncronizationWithWebApplication(Source) Export
	
	StandaloneModeInternal.DisableAutoDataSyncronizationWithWebApplication(Source);
	
EndProcedure

// Reads and sets the alarm setting for continuous synchronization of the workstation.
//
// Parameters:
//   FlagValue1     - Boolean -  set the value of the flag
//   SettingDetails - Structure -  takes a value to describe the setting.
//
// Returns:
//   Boolean, Undefined - 
//
Function LongSynchronizationQuestionSetupFlag(FlagValue1 = Undefined, SettingDetails = Undefined) Export
	
	Return StandaloneModeInternal.LongSynchronizationQuestionSetupFlag(FlagValue1, SettingDetails);
	
EndFunction

// Returns the address for restoring the app's Internet account password.
//
// Returns:
//   String - 
//
Function AccountPasswordRecoveryAddress() Export
	
	Return StandaloneModeInternal.AccountPasswordRecoveryAddress();
	
EndFunction

// Configures a standalone workstation for the first time.
// Fills in the list of users and other settings.
// Called before user authorization. You may need to restart.
//
// Parameters:
//   Parameters - Structure -  structure of parameters.
//
// Returns:
//   Boolean - 
//
Function ContinueStandaloneWorkstationSetup(Parameters) Export
	
	If Not StandaloneModeInternal.MustPerformStandaloneWorkstationSetupOnFirstStart() Then
		Return False;
	EndIf;
		
	Try
		StandaloneModeInternal.PerformStandaloneWorkstationSetupOnFirstStart();
		Parameters.Insert("RestartAfterStandaloneWorkstationSetup");
	Except
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(StandaloneModeInternal.StandaloneWorkstationCreationEventLogMessageText(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		
		Parameters.Insert("StandaloneWorkstationSetupError",
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Internal

Function ConstantNameArmBasicFunctionality() Export
	
	Return "StandardSubsystemsStandaloneMode";
	
EndFunction

Procedure DisablePropertyIB() Export
	
	IsStandaloneWorkplace = Constants.IsStandaloneWorkplace.CreateValueManager();
	IsStandaloneWorkplace.Read();
	If IsStandaloneWorkplace.Value Then
		
		IsStandaloneWorkplace.Value = False;
		ModuleUpdatingInfobase = Common.CommonModule("InfobaseUpdate");
		ModuleUpdatingInfobase.WriteData(IsStandaloneWorkplace);
		
	EndIf;
	
	ConstantName = ConstantNameArmBasicFunctionality();
	If Metadata.Constants.Find(ConstantName) <> Undefined Then
		
		If Constants[ConstantName].Get() = True Then
			
			Constants[ConstantName].Set(False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// 
// See CommonForm.ReconnectToMasterNode.
//
Procedure WhenConfirmingDisconnectionOfCommunicationWithTheMasterNode() Export
	
	ConstantName = ConstantNameArmBasicFunctionality();
	IsConstantBaseFunctionality = (Metadata.Constants.Find(ConstantName) <> Undefined);
	
	If Constants.IsStandaloneWorkplace.Get() = False
		And 
		(IsConstantBaseFunctionality 
			And Constants[ConstantName].Get() = False) Then
		
		Return;
		
	EndIf;
	
	DisablePropertyIB();
	
	NotUseSeparationByDataAreas = Constants.NotUseSeparationByDataAreas.CreateValueManager();
	NotUseSeparationByDataAreas.Read();
	If Not Constants.UseSeparationByDataAreas.Get()
		And Not NotUseSeparationByDataAreas.Value Then
		
		NotUseSeparationByDataAreas.Value = True;
		
		ModuleUpdatingInfobase = Common.CommonModule("InfobaseUpdate");
		ModuleUpdatingInfobase.WriteData(NotUseSeparationByDataAreas);
		
	EndIf;
		
EndProcedure

#EndRegion