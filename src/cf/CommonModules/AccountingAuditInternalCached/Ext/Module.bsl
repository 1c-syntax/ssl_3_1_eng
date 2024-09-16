///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Forms the structure of check tables and check groups for further use.
//
// Returns:
//    Structure:
//       * ChecksGroups - See AccountingAuditInternalCached.ChecksGroupsNewTable
//       * Checks       - See AccountingAuditInternalCached.NewChecksTable
//
Function AccountingChecks() Export
	
	ChecksGroups = ChecksGroupsNewTable();
	Checks       = NewChecksTable();
	
	AddAccountingSystemChecks(ChecksGroups, Checks);
	
	SSLSubsystemsIntegration.OnDefineChecks(ChecksGroups, Checks);
	AccountingAuditOverridable.OnDefineChecks(ChecksGroups, Checks);
	
	// 
	AccountingAuditOverridable.OnDefineAppliedChecks(ChecksGroups, Checks);
	ProvideReverseCompatibility(Checks);
	
	Return New FixedStructure("ChecksGroups, Checks", ChecksGroups, Checks);
	
EndFunction

// Returns an array of types that includes all possible object types of the configuration.
//
// Returns:
//    Array - 
//
Function TypeDetailsAllObjects() Export
	
	TypesArray = New Array;
	
	MetadataKindsArray = New Array;
	MetadataKindsArray.Add(Metadata.Documents);
	MetadataKindsArray.Add(Metadata.Catalogs);
	MetadataKindsArray.Add(Metadata.ExchangePlans);
	MetadataKindsArray.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKindsArray.Add(Metadata.ChartsOfAccounts);
	MetadataKindsArray.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKindsArray.Add(Metadata.Tasks);
	
	For Each MetadataKind In MetadataKindsArray Do
		For Each MetadataObject In MetadataKind Do
			
			SeparatedName = StrSplit(MetadataObject.FullName(), ".");
			If SeparatedName.Count() < 2 Then
				Continue;
			EndIf;
			
			TypesArray.Add(Type(SeparatedName.Get(0) + "Object." + SeparatedName.Get(1)));
			
		EndDo;
	EndDo;
	
	Return New FixedArray(TypesArray);
	
EndFunction

Function ObjectsToExcludeFromCheck() Export
	
	Objects = New Array;
	SSLSubsystemsIntegration.OnDefineObjectsToExcludeFromCheck(Objects);
	
	Names = New Array;
	For Each Object In Objects Do
		Names.Add(Object.FullName());
	EndDo;
	
	Return New FixedArray(Names);
	
EndFunction

#EndRegion

#Region Private

// See AccountingAuditOverridable.OnDefineChecks
Procedure AddAccountingSystemChecks(ChecksGroups, Checks)
	
	ChecksGroup = ChecksGroups.Add();
	ChecksGroup.Description                 = NStr("en = 'System checks';");
	ChecksGroup.Id                = "SystemChecks";
	ChecksGroup.AccountingChecksContext = "SystemChecks";
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("en = 'Check for empty required attributes';");
	Validation.Reasons                      = NStr("en = 'Invalid data synchronization with external applications or data import.';");
	Validation.Recommendation                 = NStr("en = 'Reconfigure data synchronization or fill the mandatory attributes manually.
		|Batch modification of attributes (the Administration section) can be used for this purpose.
		|If unfilled mandatory attributes are found in registers,
		| generally, you only need to fill in the corresponding fields in the recorder document to eliminate this issue.';");
	Validation.Id                = "StandardSubsystems.CheckBlankMandatoryAttributes";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckUnfilledRequiredAttributes";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.SupportsRandomCheck = True;
	Validation.isDisabled                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("en = 'Reference integrity check';");
	Validation.Reasons                      = NStr("en = 'Accidental or intentional data deletion without reference integrity control, equipment failures, invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';");
	Validation.Recommendation                 = NStr("en = 'Depending on the situation, select one of the following options:
		|• Restore deleted data from backup.
		|• Clear references to deleted data (if this is no longer needed).';");
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF + Chars.LF 
			+ NStr("en = 'To clear references to deleted data, do the following:
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			| For more information, see <link https://kb.1ci.com/1C_Enterprise_Platform/Guides/Administrator_Guides/1C_Enterprise_8.3.22_Administrator_Guide/Chapter_6._Infobase_administration/6.10._Verifying_and_repairing_an_infobase/>1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';");
	
	EndIf;
	Validation.Recommendation = Validation.Recommendation + Chars.LF
		+ NStr("en = 'If some dead references are detected in registers, usually, it is enough to remove dead references
		|in recording documents to eliminate the issue.';");
	Validation.Id                = "StandardSubsystems.CheckReferenceIntegrity1";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckReferenceIntegrity";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.SupportsRandomCheck = True;
	Validation.isDisabled                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID            = ChecksGroup.Id;
	Validation.Description                   = NStr("en = 'Check for circular references';");
	Validation.Reasons                        = NStr("en = 'Invalid data synchronization with external applications or data import.';");
	Validation.Recommendation                   = NStr("en = 'In one of the items, remove a reference to the parent item (click the hyperlink below to fix the issue automatically).
		|For distributed infobases, run the repair procedure for the master node only.
		|After that, perform synchronization with subordinate nodes.';");
	Validation.Id                  = "StandardSubsystems.CheckCircularRefs1";
	Validation.HandlerChecks             = "AccountingAuditInternal.CheckCircularRefs";
	Validation.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	Validation.AccountingChecksContext   = "SystemChecks";
	Validation.isDisabled                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID            = ChecksGroup.Id;
	Validation.Description                   = NStr("en = 'Check for missing predefined items';");
	Validation.Reasons                        = NStr("en = 'Invalid data synchronization with external applications or data import, errors in third-party tools (such as external data processors or extensions).';");
	Validation.Recommendation                   = NStr("en = 'Depending on the situation, do one of the following:
		|• Select and specify one of existing items in the list as a predefined item. 
		|• Restore predefined items from backup.
		|• Create missing predefined items again (to do this, click the link below).';"); 
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF
			+ NStr("en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';");
	EndIf;
	Validation.Id                  = "StandardSubsystems.CheckNoPredefinedItems";
	Validation.HandlerChecks             = "AccountingAuditInternal.CheckMissingPredefinedItems";
	Validation.GoToCorrectionHandler = "Report.AccountingCheckResults.Form.AutoCorrectIssues";
	Validation.AccountingChecksContext   = "SystemChecks";
	Validation.isDisabled                      = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("en = 'Check for duplicate predefined items';");
	Validation.Reasons                      = NStr("en = 'Invalid data synchronization with external applications or data import.';");
	Validation.Recommendation                 = NStr("en = 'Run duplicate cleaner in the Administration section.';");
	If Not Common.DataSeparationEnabled() Then
		Validation.Recommendation = Validation.Recommendation + Chars.LF  
			+ NStr("en = 'For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';");
	EndIf;
	Validation.Id                = "StandardSubsystems.CheckDuplicatePredefinedItems1";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckDuplicatePredefinedItems";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.isDisabled                    = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("en = 'Check for missing predefined nodes in exchange plan';");
	Validation.Reasons                      = NStr("en = 'Incorrect application behavior when running on an obsolete 1C:Enterprise version';");
	If Common.DataSeparationEnabled() Then
		Validation.Recommendation             = NStr("en = 'Contact technical service support.';");
	Else	
		Validation.Recommendation             = NStr("en = '• Upgrade 1C:Enterprise to 8.3.9.2033 or later
			|• Terminate all user sessions, lock the application, and create an infobase backup.
			|• Start Designer, open the Administration – Verify and repair menu, and select checkboxes for the logical integrity check and the referential integrity check.
			|  For more information, see <link https://kb.1ci.com/1C_Enterprise_Platform/Guides/Administrator_Guides/1C_Enterprise_8.3.22_Administrator_Guide/Chapter_6._Infobase_administration/6.10._Verifying_and_repairing_an_infobase/>1C:Enterprise Administrator Guide</>
			|• Wait for verification and repair to complete, and unlock the application.
			|
			|For distributed infobases, run the repair procedure for the master node only.
			|After that, perform synchronization with subordinate nodes.';");
	EndIf;
	Validation.Id                = "StandardSubsystems.CheckNoPredefinedExchangePlansNodes";
	Validation.HandlerChecks           = "AccountingAuditInternal.CheckPredefinedExchangePlanNodeAvailability";
	Validation.AccountingChecksContext = "SystemChecks";
	Validation.isDisabled                    = True;
	
EndProcedure

// Creates a table of check groups
//
// Returns:
//   ValueTable:
//      * Description                 - String -  name of the verification group.
//      * GroupID          - String - : 
//                                       
//                                       
//      * Id                - String - 
//                                       :
//                                       
//                                       
//      * AccountingChecksContext - DefinedType.AccountingChecksContext -  a value that further
//                                       clarifies whether a group of accounting checks belongs to a certain category.
//      * Comment                  - String -  comment on the verification group.
//
Function ChecksGroupsNewTable() Export
	
	ChecksGroups        = New ValueTable;
	ChecksGroupColumns = ChecksGroups.Columns;
	ChecksGroupColumns.Add("Description",                 New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("Id",                New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("GroupID",          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksGroupColumns.Add("AccountingChecksContext", Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksGroupColumns.Add("Comment",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	
	Return ChecksGroups;
	
EndFunction

// Creates a table of checks.
//
// Returns:
//   ValueTable:
//      * GroupID                    - String - : 
//                                                 
//                                                 
//      * Description                           - String -  the name of the check displayed to the user.
//      * Reasons                                - String -  description of possible causes that lead to
//                                                 the problem.
//      * Recommendation                           - String -  recommendation for solving the problem.
//      * Id                          - String - 
//                                                 :
//                                                 
//                                                 
//      * CheckStartDate                     - Date -  threshold date indicating the boundary of the objects to be checked
//                                                 (only for objects with a date). Objects whose date is less than
//                                                 however, it should not be checked. By default, it is not filled in (i.e.
//                                                 check everything).
//      * IssuesLimit                           - Number -  the number of objects to be checked. By default, 1000. 
//                                                 If 0 is specified, then all objects should be checked.
//      * HandlerChecks                     - String -  the name of the export procedure handler of the server shared 
//                                                 module in the form of a module name.Procedure name. 
//      * GoToCorrectionHandler         - String -  the name of the export procedure-handler of the client common 
//                                                 module for the transition to fixing the problem in the form of a module name.Procedure name.
//      * NoCheckHandler                 - Boolean -  indicates a service check that does not have a handler procedure.
//      * ImportanceChangeDenied             - Boolean -  if True, the administrator will not be able to reconfigure 
//                                                 the importance of this check.
//      * AccountingChecksContext           - DefinedType.AccountingChecksContext -  a value that further 
//                                                 clarifies whether the accounting check belongs to a certain group 
//                                                 or category.
//      * AccountingCheckContextClarification - DefinedType.AccountingCheckContextClarification -  the second value, 
//                                                 which further clarifies whether the accounting check belongs 
//                                                 to a certain group or category.
//      * AdditionalParameters                - ValueStorage -  additional verification information for software
//                                                 use.
//      * Comment                            - String -  review comment.
//      * isDisabled                              - Boolean -  if True, then the check will not be performed in the background according to the schedule.
//
Function NewChecksTable() Export
	
	Checks        = New ValueTable;
	ChecksColumns = Checks.Columns;
	ChecksColumns.Add("GroupID",                    New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Description",                           New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Reasons",                                New TypeDescription("String"));
	ChecksColumns.Add("Recommendation",                           New TypeDescription("String"));
	ChecksColumns.Add("Id",                          New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("CheckStartDate",                     New TypeDescription("Date", , , , , New DateQualifiers(DateFractions.DateTime)));
	ChecksColumns.Add("IssuesLimit",                           New TypeDescription("Number", , , New NumberQualifiers(8, 0, AllowedSign.Nonnegative)));
	ChecksColumns.Add("HandlerChecks",                     New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("GoToCorrectionHandler",         New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("NoCheckHandler",                 New TypeDescription("Boolean"));
	ChecksColumns.Add("ImportanceChangeDenied",             New TypeDescription("Boolean"));
	ChecksColumns.Add("AccountingChecksContext",           Metadata.DefinedTypes.AccountingChecksContext.Type);
	ChecksColumns.Add("AccountingCheckContextClarification", Metadata.DefinedTypes.AccountingCheckContextClarification.Type);
	ChecksColumns.Add("AdditionalParameters",                New TypeDescription("ValueStorage"));
	ChecksColumns.Add("ParentID",                  New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("Comment",                            New TypeDescription("String", , , , New StringQualifiers(256)));
	ChecksColumns.Add("isDisabled",                              New TypeDescription("Boolean"));
	ChecksColumns.Add("SupportsRandomCheck",         New TypeDescription("Boolean"));
	Checks.Indexes.Add("Id");
	
	Return Checks;
	
EndFunction

Procedure ProvideReverseCompatibility(Checks)
	
	For Each Validation In Checks Do
		
		If ValueIsFilled(Validation.GroupID) Then
			Continue;
		EndIf;
		
		Validation.GroupID = Validation.ParentID;
		
	EndDo;
	
EndProcedure

#EndRegion