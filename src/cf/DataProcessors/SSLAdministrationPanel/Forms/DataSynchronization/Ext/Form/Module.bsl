///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataSeparationEnabled = Common.DataSeparationEnabled();
	
	SubsystemExistsDataExchange         = Common.SubsystemExists("StandardSubsystems.DataExchange");
	SubsystemExistsPeriodClosingDates = Common.SubsystemExists("StandardSubsystems.PeriodClosingDates");
	
	SetVisibility1();
	SetAvailability();
	
	ApplicationSettingsOverridable.DataSynchronizationOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	NotificationsHandler(EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseDataSynchronizationOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

&AtClient
Procedure DataExchangeMessageDirectoryForWindowsOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

&AtClient
Procedure DataExchangeMessageDirectoryForLinuxOnChange(Item)
	
	RefreshSecurityProfilesPermissions(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DataSyncSettings(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeClient = CommonClient.CommonModule("DataExchangeClient");
		ModuleDataExchangeClient.OpenDataSynchronizationSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureImportRestrictionDates(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDatesInternalClient = CommonClient.CommonModule("PeriodClosingDatesInternalClient");
		ModulePeriodClosingDatesInternalClient.OpenDataImportRestrictionDates(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeIBPrefix(Command)
	
	FormParameters = New Structure("Prefix", ConstantsSet.DistributedInfobaseNodePrefix);
	
	OpenForm("DataProcessor.DataExchangeCreationWizard.Form.ChangeInfobaseNodePrefix",FormParameters,,,,,, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Processing notifications from other open forms.
//
// Parameters:
//   EventName - String -  event name. It can be used to identify messages by the forms that accept them.
//   Parameter - Arbitrary -  the parameter of the message. Any necessary data can be transmitted.
//   Source - Arbitrary -  event source. For example, a different form may be specified as the source.
//
// Example:
//   If EventName = " Setconstant.Prefix Of The Distributed Information Database " Then
//     Setconstant.Prefix Of The Distributed Information Database = Parameter;
//   Conicelli;
//
&AtClient
Procedure NotificationsHandler(EventName, Parameter, Source)
	
	
	
EndProcedure

&AtClient
Procedure RemovingDataSynchronizationAlerts(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ArrayOfExchangePlanNodes", New Array);
	OpeningParameters.Insert("SelectionByDateOfOccurrence", New StandardPeriod);
	OpeningParameters.Insert("SelectionOfExchangeNodes", New Array);
	OpeningParameters.Insert("SelectingTypesOfWarnings", New Array); 
	OpeningParameters.Insert("OnlyHiddenRecords", False);
	
	OpenForm("InformationRegister.DataExchangeResults.Form.ObsoleteWarningsDeletion", OpeningParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshSecurityProfilesPermissions(Item)
	
	ClosingNotification1 = New NotifyDescription("RefreshSecurityProfilesPermissionsCompletion", ThisObject, Item);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		
		QueriesArray = CreateRequestToUseExternalResources(Item.Name);
		
		If QueriesArray = Undefined Then
			Return;
		EndIf;
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(
			QueriesArray, ThisObject, ClosingNotification1);
	Else
		ExecuteNotifyProcessing(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

&AtServer
Function CreateRequestToUseExternalResources(ConstantName)
	
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() = ConstantValue Then
		Return Undefined;
	EndIf;
	
	If ConstantName = "UseDataSynchronization" Then
		
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		If ConstantValue Then
			Query = ModuleDataExchangeServer.RequestToUseExternalResourcesOnEnableExchange();
		Else
			Query = ModuleDataExchangeServer.RequestToClearPermissionsToUseExternalResources();
		EndIf;
		Return Query;
		
	Else
		
		ValueManager = ConstantManager.CreateValueManager();
		ConstantID = Common.MetadataObjectID(ValueManager.Metadata());
		
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		If IsBlankString(ConstantValue) Then
			
			Query = ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(ConstantID);
			
		Else
			
			Permissions = CommonClientServer.ValueInArray(
				ModuleSafeModeManager.PermissionToUseFileSystemDirectory(ConstantValue, True, True));
			Query = ModuleSafeModeManager.RequestToUseExternalResources(Permissions, ConstantID);
			
		EndIf;
		
		Return CommonClientServer.ValueInArray(Query);
		
	EndIf;
	
EndFunction

&AtClient
Procedure RefreshSecurityProfilesPermissionsCompletion(Result, Item) Export
	
	If Result = DialogReturnCode.OK Then
	
		Attachable_OnChangeAttribute(Item);
		
	Else
		
		Read();
	
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetVisibility1()
	
	If DataSeparationEnabled Then
		Items.SectionDetails.Title = NStr("en = 'Sync data with my applications.';");
	EndIf;
	
	If SubsystemExistsDataExchange Then
		AvailableVersionsArray = New Map;
		ModuleDataExchangeOverridable = Common.CommonModule("DataExchangeOverridable");
		ModuleDataExchangeOverridable.OnGetAvailableFormatVersions(AvailableVersionsArray);
		
		Items.EnterpriseDataLoadingGroup.Visible = ?(AvailableVersionsArray.Count() = 0, False, True);
		
		Items.DistributedInfobaseNodePrefixGroup.ExtendedTooltip.Title =
			Metadata.Constants.DistributedInfobaseNodePrefix.Tooltip;
			
		If DataSeparationEnabled Then
			Items.UseDataSynchronizationGroup.Visible   = False;
			Items.TemporaryServerClusterDirectoriesGroup.Visible = False;
			
			Items.DistributedInfobaseNodePrefix.Title = NStr("en = 'Prefix in this application';");
			
			Items.PerformanceMonitorGroup.Visible = False;
		Else
			Items.TemporaryServerClusterDirectoriesGroup.Visible = Not Common.FileInfobase()
				And Users.IsFullUser(, True);
		EndIf;
	Else
		Items.GroupDataSynchronization.Visible = False;
		Items.DistributedInfobaseNodePrefixGroup.Visible = False;
		Items.DataSynchronizationMoreGroup.Visible  = False;
		Items.TemporaryServerClusterDirectoriesGroup.Visible = False;
	EndIf;
	
	If SubsystemExistsPeriodClosingDates Then
		ModulePeriodClosingDatesInternal = Common.CommonModule("PeriodClosingDatesInternal");
		SectionsProperties = ModulePeriodClosingDatesInternal.SectionsProperties();
		
		Items.ImportRestrictionDatesGroup.Visible = SectionsProperties.ImportRestrictionDatesImplemented;
		
		If DataSeparationEnabled
			And SectionsProperties.ImportRestrictionDatesImplemented Then
			Items.UseImportForbidDates.ExtendedTooltip.Title =
				NStr("en = 'Importing closed period data from other applications is restricted.
				           |This has no effect on importing data from standalone computers.';");
		EndIf;
	Else
		Items.ImportRestrictionDatesGroup.Visible = False;
	EndIf;
		
EndProcedure

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseImportForbidDates"
			Or DataPathAttribute = "")
		And SubsystemExistsPeriodClosingDates Then
		
		Items.ConfigureImportRestrictionDates.Enabled = ConstantsSet.UseImportForbidDates;
		
	EndIf;
	
	If SubsystemExistsDataExchange Then
		 
		If (DataPathAttribute = "ConstantsSet.UsePerformanceMonitoringOfDataSynchronization"
				Or DataPathAttribute = "")  Then
			
			Items.ExchangeSessions.Enabled = ConstantsSet["UsePerformanceMonitoringOfDataSynchronization"];
			
		EndIf;
		
		If (DataPathAttribute = "ConstantsSet.UseDataSynchronization"
				Or DataPathAttribute = "") Then
			
			Items.DataSyncSettings.Enabled            = ConstantsSet["UseDataSynchronization"];
			Items.ImportRestrictionDatesGroup.Enabled               = ConstantsSet["UseDataSynchronization"];
			Items.DataSynchronizationResults.Enabled           = ConstantsSet["UseDataSynchronization"];
			Items.TemporaryServerClusterDirectoriesGroup.Enabled = ConstantsSet["UseDataSynchronization"];
			Items.PerformanceMonitorGroup.Enabled          = ConstantsSet["UseDataSynchronization"];
			
		EndIf;
		
	EndIf;
	
EndProcedure


#EndRegion
