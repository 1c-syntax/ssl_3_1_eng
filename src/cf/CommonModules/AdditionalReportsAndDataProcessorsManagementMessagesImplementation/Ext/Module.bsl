///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}InstallExtension
//
// Parameters:
//  InstallationDetails - Structure:
//    * Id - UUID -  the unique identifier links
//      element of the directory of ПоставляемыеДополнительныеОтчетыиобработки,
//    * Presentation - String -  representation of the installation of the supplied additional
//      processing (will be used as the name of the reference element
//      Dopolnitelnuyu),
//    * Installation - UUID -  unique ID of the installation
//      of the supplied additional processing (will be used as
//      the unique ID of the reference reference for additional processing Reports),
//  CommandsSettings - ValueTable - 
//      :
//    * Id - String -  command ID,
//    * QuickAccess - Array -  unique identifiers (unique Identifier)
//      that define the service users to whom the command should be included in
//      quick access,
//    * Schedule - JobSchedule -  schedule for setting
//      an additional processing command (if the command is set to run as
//      a scheduled task),
//  Sections - ValueTable - 
//      :
//    * Section - CatalogRef.MetadataObjectIDs
//  CatalogsAndDocuments - ValueTable - 
//      :
//    * RelatedObject - CatalogRef.MetadataObjectIDs
//  AdditionalReportOptions - Array -  keys for additional report report options (Row).
//  ServiceUserID - UUID -  defines
//    the service user who initiated the installation of the supplied additional processing.
//
Procedure SetAdditionalReportOrDataProcessor(Val InstallationDetails,
		Val CommandsSettings, Val CommandsPlacementSettings, Val Sections, Val CatalogsAndDocuments, Val AdditionalReportOptions,
		Val ServiceUserID) Export
	
	// 
	QuickAccess = New ValueTable();
	QuickAccess.Columns.Add("CommandID", New TypeDescription("String"));
	QuickAccess.Columns.Add("User", New TypeDescription("CatalogRef.Users"));
	
	Jobs = New ValueTable();
	Jobs.Columns.Add("Id", New TypeDescription("String"));
	Jobs.Columns.Add("ScheduledJobSchedule", New TypeDescription("ValueList"));
	Jobs.Columns.Add("ScheduledJobUsage", New TypeDescription("Boolean"));
	
	UsersIDs = New Array;
	For Each CommandSetting In CommandsSettings Do
		If ValueIsFilled(CommandSetting.QuickAccess) Then
			For Each UserIdentificator In CommandSetting.QuickAccess Do
				UsersIDs.Add(UserIdentificator);
			EndDo;
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("ServiceUsersIDs", UsersIDs);
	Query.Text =
		"SELECT
		|	Users.Ref
		|FROM
		|	Catalog.Users AS Users
		|WHERE
		|	Users.ServiceUserID IN (&ServiceUsersIDs)";
	QuickAccessUsers = Query.Execute().Unload().UnloadColumn("Ref");
	
	For Each CommandSetting In CommandsSettings Do
		If ValueIsFilled(CommandSetting.QuickAccess) Then
			For Each User In QuickAccessUsers Do
				QuickAccessItem = QuickAccess.Add();
				QuickAccessItem.CommandID = CommandSetting.Id;
				QuickAccessItem.User = User;
			EndDo;
		EndIf;
		
		If CommandSetting.Schedule <> Undefined Then
			Job = Jobs.Add();
			Job.Id = CommandSetting.Id;
			ScheduledJobSchedule = New ValueList();
			ScheduledJobSchedule.Add(CommandSetting.Schedule);
			Job.ScheduledJobSchedule= ScheduledJobSchedule;
			Job.ScheduledJobUsage = True;
		EndIf;
	EndDo;
	
	AdditionalReportsAndDataProcessorsSaaS.InstallSuppliedDataProcessorToDataArea(
		InstallationDetails,
		QuickAccess,
		Jobs,
		Sections,
		CatalogsAndDocuments,
		CommandsPlacementSettings,
		AdditionalReportOptions,
		GetAreaUserByServiceUserID(
			ServiceUserID));
	
EndProcedure

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DeleteExtension
//
// Parameters:
//  SuppliedDataProcessorID - UUID -  the link to the item
//    Handbook of ПоставляемыеДополнительныеОтчетыиобработки;
//  IDOfDataProcessorToUse - UUID -  link to an element
//    in the additional reports and Processing reference list.
//
Procedure DeleteAdditionalReportOrDataProcessor(Val SuppliedDataProcessorID, Val IDOfDataProcessorToUse) Export
	
	SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
			SuppliedDataProcessorID);
	
	AdditionalReportsAndDataProcessorsSaaS.DeleteSuppliedDataProcessorFromDataArea(
		SuppliedDataProcessor,
		IDOfDataProcessorToUse);
	
EndProcedure

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DisableExtension
//
// Parameters:
//  ExtensionID - UUID -  the link to the item
//                            Handbook of ПоставляемыеДополнительныеОтчетыиобработки,
//  DisableReason - EnumRef.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS
//
Procedure DisableAdditionalReportOrDataProcessor(Val ExtensionID, Val DisableReason = Undefined) Export
	
	If DisableReason = Undefined Then
		DisableReason = Enums.ReasonsForDisablingAdditionalReportsAndDataProcessorsSaaS.LockByServiceAdministrator;
	EndIf;
	
	SetPrivilegedMode(True);
	SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
		ExtensionID);
	
	If Common.RefExists(SuppliedDataProcessor) Then
		
		Object = SuppliedDataProcessor.GetObject();
		
		Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled;
		Object.DisableReason = DisableReason;
		
		Object.Write();
		
	EndIf;
	
EndProcedure

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}EnableExtension
//
// Parameters:
//  ExtensionID - UUID -  link to
//                            the reference list item deliveredadditional reports and Processing.
//
Procedure EnableAdditionalReportOrDataProcessor(Val ExtensionID) Export
	
	SetPrivilegedMode(True);
	SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
		ExtensionID);
	
	If Common.RefExists(SuppliedDataProcessor) Then
		
		Object = SuppliedDataProcessor.GetObject();
		
		Object.Publication =
			Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
		
		Object.Write();
	EndIf;
	
EndProcedure

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DropExtension
//
// Parameters:
//  Extension ID - unique Identifier-a link to
//                            the reference list item supplied with additional reports and Processing.
//
Procedure RevokeAdditionalReportOrDataProcessor(Val SuppliedDataProcessorID) Export
	
	SetPrivilegedMode(True);
	SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
		SuppliedDataProcessorID);
	
	If Common.RefExists(SuppliedDataProcessor) Then
		AdditionalReportsAndDataProcessorsSaaS.RevokeSuppliedAdditionalDataProcessor(
			SuppliedDataProcessor);
	EndIf;
	
EndProcedure

// Processing incoming messages with the {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}SetExtensionSecurityProfile
//
// Parameters:
//  SuppliedDataProcessorID - UUID -  the link to the item
//                            Handbook of ПоставляемыеДополнительныеОтчетыиобработки;
//  IDOfDataProcessorToUse - UUID -  link to an element
//                            in the additional reports and Processing reference list.
//
Procedure SetModeOfAdditionalReportOrDataProcessorAttachmentInDataArea(Val SuppliedDataProcessorID, Val IDOfDataProcessorToUse, Val AttachmentMode) Export
	
	SuppliedDataProcessor = Catalogs.SuppliedAdditionalReportsAndDataProcessors.GetRef(
		SuppliedDataProcessorID);
	
	DataProcessorToUse = Catalogs.AdditionalReportsAndDataProcessors.GetRef(
		IDOfDataProcessorToUse);
	
	If Common.RefExists(DataProcessorToUse) Then
		SSLSubsystemsIntegration.OnSetAdditionalReportOrDataProcessorAttachmentModeInDataArea(SuppliedDataProcessor, AttachmentMode);
	EndIf;
	
EndProcedure

Function GetAreaUserByServiceUserID(Val ServiceUserID)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Users.Ref AS Ref
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	Users.ServiceUserID = &ServiceUserID";
	Query.SetParameter("ServiceUserID", ServiceUserID);
	
	Block = New DataLock;
	Block.Add("Catalog.Users");
	
	BeginTransaction();
	Try
		Block.Lock();
		Result = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Result.IsEmpty() Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The user with service user ID %1 is not found';"), ServiceUserID);
		Raise(MessageText);
	EndIf;
	
	Return Result.Unload()[0].Ref;
	
EndFunction

#EndRegion
