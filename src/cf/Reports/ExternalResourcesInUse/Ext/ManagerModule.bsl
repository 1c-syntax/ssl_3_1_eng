///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//   ReportSettings - See ReportsOptions.DescriptionOfReport.
//
Procedure CustomizeReportOptions(Settings, ReportSettings) Export
	
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	
	ReportSettings.DefineFormSettings = True;
	
	OptionSettings = ModuleReportsOptions.OptionDetails(Settings, Metadata.Reports.ExternalResourcesInUse, "");
	OptionSettings.Description = NStr("en = 'External resources that the app and additional modules use';");
	OptionSettings.LongDesc = 
		NStr("en = 'Online resources, add-ins, COM classes, and more.
		           |Environment parameters that will help administrator 
		           |to configure the computer and perform security audit.';");
	OptionSettings.SearchSettings.FieldDescriptions = 
		NStr("en = 'Name and ID of COM class
		           |Computer name
		           |Address
		           |Read data
		           |Save data
		           |Name of template or file component
		           |Checksum
		           |Command line template
		           |Protocol
		           |IP address of the resource
		           |Port';");
	
	// 
	OptionSettings.SearchSettings.FilterParameterDescriptions = "#";
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region Private

// For internal use only.
//
Function RequestsForPermissionsToUseExternalResoursesPresentation(Val AdministrationOperations, Val PermissionsToAddDetails, Val PermissionsToDeleteDetails, Val AsRequired = False) Export
	
	Template = GetTemplate("PermissionsPresentations");
	OffsetArea = Template.GetArea("Indent");
	SpreadsheetDocument = New SpreadsheetDocument();
	
	AllProgramModules = New Map();
	
	For Each LongDesc In AdministrationOperations Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each LongDesc In PermissionsToAddDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	For Each LongDesc In PermissionsToDeleteDetails Do
		
		Ref = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			LongDesc.ProgramModuleType, LongDesc.ModuleID);
		
		If AllProgramModules.Get(Ref) = Undefined Then
			AllProgramModules.Insert(Ref, True);
		EndIf;
		
	EndDo;
	
	ModulesTable = New ValueTable();
	ModulesTable.Columns.Add("ProgramModule", Common.AllRefsTypeDetails());
	ModulesTable.Columns.Add("IsConfiguration", New TypeDescription("Boolean"));
	
	For Each KeyAndValue In AllProgramModules Do
		String = ModulesTable.Add();
		String.ProgramModule = KeyAndValue.Key;
		String.IsConfiguration = (KeyAndValue.Key = Catalogs.MetadataObjectIDs.EmptyRef());
	EndDo;
	
	ModulesTable.Sort("IsConfiguration DESC");
	
	For Each ModulesTableRow In ModulesTable Do
		
		SpreadsheetDocument.Put(OffsetArea);
		
		Properties = SafeModeManagerInternal.PropertiesForPermissionRegister(
			ModulesTableRow.ProgramModule);
		
		Filter = New Structure();
		Filter.Insert("ProgramModuleType", Properties.Type);
		Filter.Insert("ModuleID", Properties.Id);
		
		GenerateOperationsPresentation(SpreadsheetDocument, Template, AdministrationOperations.FindRows(Filter));
		
		IsConfigurationProfile = (Properties.Type= Catalogs.MetadataObjectIDs.EmptyRef());
		
		If IsConfigurationProfile Then
			
			Dictionary = ConfigurationModuleDictionary();
			ModuleDescription = Metadata.Synonym;
			
		Else
			
			ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
				Properties.Type, Properties.Id);
			
			ExternalModuleManager = SafeModeManagerInternal.ExternalModuleManager(ProgramModule);
			
			Dictionary = ExternalModuleManager.ExternalModuleContainerDictionary();
			Pictogram = ExternalModuleManager.ExternalModuleIcon(ProgramModule);
			ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
			
		EndIf;
		
		ItemsToAdd = PermissionsToAddDetails.Copy(Filter);
		If ItemsToAdd.Count() > 0 Then
			
			If AsRequired Then
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%2 %1 requires the following external resources:';"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
				
			Else
				
				HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The following permissions to use external resources will be granted for %2 %1:';"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
				
			EndIf;
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Pictogram"] = Pictogram;
				
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			SpreadsheetDocument.Put(OffsetArea);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, ItemsToAdd, AsRequired);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		ItemsToDelete = PermissionsToDeleteDetails.Copy(Filter);
		If ItemsToDelete.Count() > 0 Then
			
			If AsRequired Then
				Raise NStr("en = 'Incorrect permission request';");
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The following granted permissions to use external resources will be removed for %2 %1:';"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
				Area.Parameters["Pictogram"] = Pictogram;
			EndIf;
			
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.StartRowGroup(, True);
			
			GeneratePermissionsPresentation(SpreadsheetDocument, Template, ItemsToDelete, False);
			
			SpreadsheetDocument.EndRowGroup();
			
		EndIf;
		
		If ItemsToAdd.Count() > 0 Or ItemsToDelete.Count() > 0 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Creates a view of operations for managing permissions to use external resources.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument -  to which the operations view will be output,
//  Template - SpreadsheetDocument -  obtained from the report layout of Predstavleniyami,
//  AdministrationOperations - ValueTable - see
//                              Processing.Setting up the permission to use external resources.Operationsadministration in queries().
//
Procedure GenerateOperationsPresentation(SpreadsheetDocument, Val Template, Val AdministrationOperations)
	
	PictureToRemove = PictureLib.Delete;
	For Each LongDesc In AdministrationOperations Do
		
		If LongDesc.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			
			IsConfigurationProfile = (LongDesc.ProgramModuleType = Catalogs.MetadataObjectIDs.EmptyRef());
			
			If IsConfigurationProfile Then
				
				Dictionary = ConfigurationModuleDictionary();
				ModuleDescription = Metadata.Synonym;
				
			Else
				
				ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
					LongDesc.ProgramModuleType, LongDesc.ModuleID);
				Dictionary = SafeModeManagerInternal.ExternalModuleManager(ProgramModule).ExternalModuleContainerDictionary();
				ModuleDescription = Common.ObjectAttributeValue(ProgramModule, "Description");
				
			EndIf;
			
			HeaderText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Security profile will be deleted for %2 %1.';"),
					Lower(Dictionary.Genitive),
					ModuleDescription);
			
			Area = Template.GetArea("Header");
			
			Area.Parameters["HeaderText"] = HeaderText;
			If Not IsConfigurationProfile Then
				Area.Parameters["ProgramModule"] = ProgramModule;
			EndIf;
			Area.Parameters["Pictogram"] = PictureToRemove;
			SpreadsheetDocument.Put(Area);
			SpreadsheetDocument.PutHorizontalPageBreak();
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Generates a view of permissions.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument -  document to display the operations view in,
//  PermissionsSets - 
//  
//  AsRequired - Boolean -  flag for using terms like "the following resources are required "instead
//                          of"the following resources will be provided" in the view.
//
Procedure GeneratePermissionsPresentation(Val SpreadsheetDocument, Val Template, Val PermissionsSets, Val AsRequired = False)
	
	OffsetArea = Template.GetArea("Indent");
	
	Types = PermissionsSets.Copy(); // ValueTable
	Types.GroupBy("Type");
	Types.Columns.Add("Order", New TypeDescription("Number"));
	
	SortingOrder = PermissionsTypesSortingOrder();
	For Each TypeRow In Types Do
		TypeRow.Order = SortingOrder[TypeRow.Type];
	EndDo;
	
	Types.Sort("Order ASC");
	
	For Each TypeRow In Types Do
		
		PermissionType = TypeRow.Type;
		
		Filter = New Structure();
		Filter.Insert("Type", TypeRow.Type);
		PermissionsRows = PermissionsSets.FindRows(Filter);
		
		Count = 0;
		For Each PermissionsRow In PermissionsRows Do
			Count = Count + PermissionsRow.Permissions.Count();
		EndDo;
		
		If Count > 0 Then
			
			GroupArea = Template.GetArea("Group" + PermissionType);
			FillPropertyValues(GroupArea.Parameters, New Structure("Count", Count));
			SpreadsheetDocument.Put(GroupArea);
			
			SpreadsheetDocument.StartRowGroup(PermissionType, True);
			
			HeaderArea = Template.GetArea("Header" + PermissionType);
			SpreadsheetDocument.Put(HeaderArea);
			
			RowArea = Template.GetArea("Row" + PermissionType);
			
			For Each PermissionsRow In PermissionsRows Do
				
				For Each KeyAndValue In PermissionsRow.Permissions Do
					
					Resolution = Common.XDTODataObjectFromXMLString(KeyAndValue.Value);
					
					If PermissionType = "AttachAddin" Then
						
						FillPropertyValues(RowArea.Parameters, Resolution);
						SpreadsheetDocument.Put(RowArea);
						
						SpreadsheetDocument.StartRowGroup(Resolution.TemplateName);
						
						PermissionAddition = PermissionsRow.PermissionsAdditions.Get(KeyAndValue.Key);
						If PermissionAddition = Undefined Then
							PermissionAddition = New Structure();
						Else
							PermissionAddition = Common.ValueFromXMLString(PermissionAddition);
						EndIf;
						
						For Each AdditionKeyAndValue In PermissionAddition Do
							
							FileRowArea = Template.GetArea("AttachAddinRowAdditional");
							
							FillPropertyValues(FileRowArea.Parameters, AdditionKeyAndValue);
							SpreadsheetDocument.Put(FileRowArea);
							
						EndDo;
						
						SpreadsheetDocument.EndRowGroup();
						
					Else
						
						PermissionAddition = New Structure();
						
						If PermissionType = "FileSystemAccess" Then
							
							If Resolution.Path = "/temp" Then
								PermissionAddition.Insert("Path", NStr("en = 'Temporary files folder';"));
							EndIf;
							
							If Resolution.Path = "/bin" Then
								PermissionAddition.Insert("Path", NStr("en = 'Folder where 1C:Enterprise server is installed';"));
							EndIf;
							
						EndIf;
						
						FillPropertyValues(RowArea.Parameters, Resolution);
						FillPropertyValues(RowArea.Parameters, PermissionAddition);
						
						SpreadsheetDocument.Put(RowArea);
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
			SpreadsheetDocument.EndRowGroup();
			
			SpreadsheetDocument.Put(OffsetArea);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use only.
//
Function PermissionsTypesSortingOrder()
	
	Result = New Structure();
	
	Result.Insert("InternetResourceAccess", 1);
	Result.Insert("FileSystemAccess", 2);
	Result.Insert("AttachAddin", 3);
	Result.Insert("CreateComObject", 4);
	Result.Insert("RunApplication", 5);
	Result.Insert("ExternalModule", 6);
	Result.Insert("ExternalModulePrivilegedModeAllowed", 7);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns a dictionary of configuration properties.
//
// Returns:
//   Structure:
//                         * Nominative - 
//                         * Genitive - 
//
Function ConfigurationModuleDictionary()
	
	Result = New Structure();
	
	Result.Insert("Nominative", NStr("en = 'App';"));
	Result.Insert("Genitive", NStr("en = 'Apps';"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf