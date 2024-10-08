﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Generates a manifest for an additional report or processing.
// To call from external processing, prepare additional reports and workspublications of the service Model. epf,
// which is included in the delivery package of the service Manager.
//
// Parameters:
//  DataProcessorObject2 - CatalogObject.AdditionalReportsAndDataProcessors -  additional processing.
//  VersionObject1 - CatalogObject.AdditionalReportsAndDataProcessors -  additional processing.
//  ReportOptions - ValueTable:
//    * VariantKey - String -  key for the additional report option.
//    * Presentation - String -  presentation of a variant of an additional report.
//    * Purpose - ValueTable:
//       ** SectionOrGroup - String -  to map to the directory element IDs of metadata Objects.
//       ** Important - Boolean -  The truth is, if you are in the group important.
//       ** SeeAlso - Boolean - 
//  CommandsSchedules - Structure -  the keys contain the team IDs, and the values contain the schedule.
//  DataProcessorPermissions - Array of XDTODataObject
//                      - CatalogTabularSection.AdditionalReportsAndDataProcessors.Permissions
//                      - Undefined
//
// Returns:
//  XDTODataObject - 
//    
//
Function GenerateManifest(Val DataProcessorObject2, Val VersionObject1, Val ReportOptions = Undefined, 
	Val CommandsSchedules = Undefined, Val DataProcessorPermissions = Undefined) Export
	
	Try
		PermissionsCompatibilityMode = DataProcessorObject2.PermissionsCompatibilityMode;
	Except
		PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
	EndTry;
	
	If PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		Package = AdditionalReportsAndDataProcessorsSaaSManifestInterface.Package("1.0.0.1");
	Else
		Package = AdditionalReportsAndDataProcessorsSaaSManifestInterface.Package();
	EndIf;
	
	Manifest = XDTOFactory.Create(
		AdditionalReportsAndDataProcessorsSaaSManifestInterface.ManifestType(Package));
	
	Manifest.Name = DataProcessorObject2.Description;
	Manifest.ObjectName = VersionObject1.ObjectName;
	Manifest.Version = VersionObject1.Version;
	
	If PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		Manifest.SafeMode = VersionObject1.SafeMode;
	EndIf;
	
	Manifest.Description = VersionObject1.Information;
	Manifest.FileName = VersionObject1.FileName;
	Manifest.UseReportVariantsStorage = VersionObject1.UseOptionStorage;
	
	XDTOKind = Undefined;
	DataProcessorsKindsConversionDictionary =
		AdditionalReportsAndDataProcessorsSaaSManifestInterface.AdditionalReportsAndDataProcessorsKindsDictionary();
	For Each DictionaryFragment In DataProcessorsKindsConversionDictionary Do
		If DictionaryFragment.Value = VersionObject1.Kind Then
			XDTOKind = DictionaryFragment.Key;
		EndIf;
	EndDo;
	If Not ValueIsFilled(XDTOKind) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Additional report (data processor) type %1 is not supported in SaaS.';"),
			VersionObject1.Kind);
	EndIf;
	Manifest.Category = XDTOKind;
	
	If VersionObject1.Commands.Count() > 0 Then
		
		If DataProcessorObject2.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor 
			Or	DataProcessorObject2.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
			
			// 
			SelectedSections = VersionObject1.Sections.Unload();
			
			If DataProcessorObject2.Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalDataProcessor Then
				PossibleSections = AdditionalReportsAndDataProcessors.AdditionalDataProcessorSections();
			Else
				PossibleSections = AdditionalReportsAndDataProcessors.AdditionalReportSections();
			EndIf;
			
			StartPageName = AdditionalReportsAndDataProcessorsClientServer.StartPageName();
			
			XDTOAssignment = XDTOFactory.Create(
				AdditionalReportsAndDataProcessorsSaaSManifestInterface.AssignmentToSectionsType(Package));
			
			For Each Section In PossibleSections Do
				
				If Section = StartPageName Then
					SectionName = StartPageName;
					MetadataObjectID = Catalogs.MetadataObjectIDs.EmptyRef();
				Else
					SectionName = Section.FullName();
					MetadataObjectID = Common.MetadataObjectID(Section);
				EndIf;
				MetadataObjectPresentation = AdditionalReportsAndDataProcessors.SectionPresentation(Section);
				
				XDTORelatedObject = XDTOFactory.Create(
					AdditionalReportsAndDataProcessorsSaaSManifestInterface.TypeRelatedObject(Package));
				XDTORelatedObject.ObjectName = SectionName;
				XDTORelatedObject.ObjectType = "SubSystem";
				XDTORelatedObject.Representation = MetadataObjectPresentation;
				XDTORelatedObject.Enabled = SelectedSections.Find(MetadataObjectID, "Section") <> Undefined;
				Objects = XDTOAssignment.Objects; // XDTOList
				Objects.Add(XDTORelatedObject);
				
			EndDo;
			
		Else
			
			// 
			SelectedRelatedObjects = VersionObject1.Purpose.Unload();
			
			PossibleRelatedObjects = New Array();
			AttachedMetadataObjects = AdditionalReportsAndDataProcessors.AttachedMetadataObjects(DataProcessorObject2.Kind);
			For Each AttachedMetadataObject In AttachedMetadataObjects Do
				PossibleRelatedObjects.Add(AttachedMetadataObject.Metadata);
			EndDo;
			
			XDTOAssignment = XDTOFactory.Create(
				AdditionalReportsAndDataProcessorsSaaSManifestInterface.AssignmentToCatalogsAndDocumentsType(Package));
			
			For Each RelatedObject In PossibleRelatedObjects Do
				
				MetadataObjectID = Common.MetadataObjectID(RelatedObject);
				
				XDTORelatedObject = XDTOFactory.Create(
					AdditionalReportsAndDataProcessorsSaaSManifestInterface.TypeRelatedObject(Package));
				XDTORelatedObject.ObjectName = RelatedObject.FullName();
				If Common.IsCatalog(RelatedObject) Then
					XDTORelatedObject.ObjectType = "Catalog";
				ElsIf Common.IsDocument(RelatedObject) Then
					XDTORelatedObject.ObjectType = "Document";
				ElsIf Common.IsBusinessProcess(RelatedObject) Then
					XDTORelatedObject.ObjectType = "BusinessProcess";
				ElsIf Common.IsTask(RelatedObject) Then
					XDTORelatedObject.ObjectType = "Task";
				EndIf;
				XDTORelatedObject.Representation = RelatedObject.Presentation();
				XDTORelatedObject.Enabled = SelectedRelatedObjects.Find(MetadataObjectID, "RelatedObject") <> Undefined;
				
				Objects = XDTOAssignment.Objects; // XDTOList
				Objects.Add(XDTORelatedObject);
				
			EndDo;
			
			XDTOAssignment.UseInListsForms = VersionObject1.UseForListForm;
			XDTOAssignment.UseInObjectsForms = VersionObject1.UseForObjectForm;
			
		EndIf;
		
		Manifest.Assignment = XDTOAssignment;
		
		For Each CommandDetails In VersionObject1.Commands Do
			
			XDTOCommand = XDTOFactory.Create(
				AdditionalReportsAndDataProcessorsSaaSManifestInterface.CommandType(Package));
			XDTOCommand.Id = CommandDetails.Id;
			XDTOCommand.Representation = CommandDetails.Presentation;
			
			XDTOStartType = Undefined;
			CallMethodsConversionDictionary =
				AdditionalReportsAndDataProcessorsSaaSManifestInterface.AdditionalReportsAndDataProcessorsCallMethodsDictionary();
			For Each DictionaryFragment In CallMethodsConversionDictionary Do
				If DictionaryFragment.Value = CommandDetails.StartupOption Then
					XDTOStartType = DictionaryFragment.Key;
				EndIf;
			EndDo;
			If Not ValueIsFilled(XDTOStartType) Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Launch method of additional reports and data processors %1 is not supported in SaaS.';"),
					CommandDetails.StartupOption);
			EndIf;
			XDTOCommand.StartupType = XDTOStartType;
			XDTOCommand.ShowNotification = CommandDetails.ShouldShowUserNotification;
			XDTOCommand.Modifier = CommandDetails.Modifier;
			
			If ValueIsFilled(CommandsSchedules) Then
				CommandSchedule = Undefined;
				If CommandsSchedules.Property(CommandDetails.Id, CommandSchedule) Then
					XDTOCommand.DefaultSettings = XDTOFactory.Create(
						AdditionalReportsAndDataProcessorsSaaSManifestInterface.CommandSettingsType(Package));
					XDTOCommand.DefaultSettings.Schedule = XDTOSerializer.WriteXDTO(CommandSchedule);
				EndIf;
			EndIf;
			Commands = Manifest.Commands; // XDTOList
			Commands.Add(XDTOCommand);
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(ReportOptions) Then
		
		For Each ReportVariant In ReportOptions Do
			
			XDTOVariety = XDTOFactory.Create(
				AdditionalReportsAndDataProcessorsSaaSManifestInterface.ReportOptionType1(Package));
			XDTOVariety.VariantKey = ReportVariant.VariantKey;
			XDTOVariety.Representation = ReportVariant.Presentation;
			
			If ReportVariant.Purpose <> Undefined Then
				
				For Each ReportOptionAssignment In ReportVariant.Purpose Do
					
					XDTOAssignment = XDTOFactory.Create(
						AdditionalReportsAndDataProcessorsSaaSManifestInterface.ReportOptionAssignmentType(Package));
					
					XDTOAssignment.ObjectName = ReportOptionAssignment.FullName;
					XDTOAssignment.Representation = ReportOptionAssignment.Presentation;
					XDTOAssignment.Parent = ReportOptionAssignment.FullParentName;
					XDTOAssignment.Enabled = ReportOptionAssignment.Use;
					
					If ReportOptionAssignment.Important Then
						XDTOAssignment.Importance = "High";
					ElsIf ReportOptionAssignment.SeeAlso Then
						XDTOAssignment.Importance = "Low";
					Else
						XDTOAssignment.Importance = "Ordinary";
					EndIf;
					
					Jobs = XDTOVariety.Assignments; // XDTOList
					Jobs.Add(XDTOAssignment);
					
				EndDo;
				
			EndIf;
			
			ReportOptions = Manifest.ReportVariants; // XDTOList
			ReportOptions.Add(XDTOVariety);
			
		EndDo;
		
	EndIf;
	
	If DataProcessorPermissions = Undefined Then
		
		DataProcessorPermissions = DataProcessorObject2.Permissions;
		
	EndIf;
	
	For Each Resolution In DataProcessorPermissions Do // CatalogTabularSectionRow.AdditionalReportsAndDataProcessors.Permissions
		
		If TypeOf(Resolution) = Type("XDTODataObject") Then
			Permissions = Manifest.Permissions; // XDTOList
			Permissions.Add(Resolution);
		Else
			
			If PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
				XDTOPermission = XDTOFactory.Create(
					XDTOFactory.Type(
						"http://www.1c.ru/1cFresh/ApplicationExtensions/Permissions/1.0.0.1",
						Resolution.PermissionKind));
			Else
				XDTOPermission = XDTOFactory.Create(
					XDTOFactory.Type(
						"http://www.1c.ru/1cFresh/Application/Permissions/1.0.0.1",
						Resolution.PermissionKind));
			EndIf;
			
			Parameters = Resolution.Parameters.Get();
			If Parameters <> Undefined Then
				For Each Parameter In Parameters Do
					XDTOPermission[Parameter.Key] = Parameter.Value;
				EndDo;
			EndIf;
			Permissions = Manifest.Permissions; // XDTOList
			Permissions.Add(XDTOPermission);
			
		EndIf;
		
	EndDo;
	
	Return Manifest;
	
EndFunction

// Populates object Processing, object Conversion, and report Options with data that is read from the manifest
// of an additional report or processing.
//
// Parameters:
//  Manifest - XDTODataObject -  Xdto object {http://www.1c.ru/1cFresh/ApplicationExtensions/Manifest/a.b.c.d} ExtensionManifest-
//    additional report or processing manifest.
//  DataProcessorObject2 - CatalogObject.AdditionalReportsAndDataProcessors -  an object whose property values will be set
//    by the values of additional report or processing properties from the manifest.
//  VersionObject1 - CatalogObject.AdditionalReportsAndDataProcessors -  an object whose property values will be set
//    by the property values of the additional report or processing version from the manifest.
//  ReportOptions - ValueTable - :
//    * VariantKey - String -  key for the additional report option.
//    * Presentation - String -  presentation of a variant of an additional report.
//    * Purpose - ValueTable:
//       ** SectionOrGroup - String -  to map an item to the reference list of object IDs of Metadata,
//       ** Important - Boolean  -  The truth is, if you are in the group important.
//       ** SeeAlso - Boolean - 
//
Procedure ReadManifest(Val Manifest, DataProcessorObject2, VersionObject1, ReportOptions) Export
	
	If Manifest.Type().NamespaceURI = AdditionalReportsAndDataProcessorsSaaSManifestInterface.Package("1.0.0.1") Then
		DataProcessorObject2.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3;
	ElsIf Manifest.Type().NamespaceURI = AdditionalReportsAndDataProcessorsSaaSManifestInterface.Package("1.0.0.2") Then
		DataProcessorObject2.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_2_2;
	EndIf;
	
	DataProcessorObject2.Description = Manifest.Name;
	VersionObject1.ObjectName = Manifest.ObjectName;
	VersionObject1.Version = Manifest.Version;
	If DataProcessorObject2.PermissionsCompatibilityMode = Enums.AdditionalReportsAndDataProcessorsPermissionCompatibilityModes.Version_2_1_3 Then
		VersionObject1.SafeMode = Manifest.SafeMode;
	Else
		VersionObject1.SafeMode = True;
	EndIf;
	VersionObject1.Information = Manifest.Description;
	VersionObject1.FileName = Manifest.FileName;
	VersionObject1.UseOptionStorage = Manifest.UseReportVariantsStorage;
	
	DataProcessorsKindsConversionDictionary = AdditionalReportsAndDataProcessorsSaaSManifestInterface.AdditionalReportsAndDataProcessorsKindsDictionary();
	VersionObject1.Kind = DataProcessorsKindsConversionDictionary[Manifest.Category];
	
	VersionObject1.Commands.Clear();
	For Each Command In Manifest.Commands Do
		
		CommandString = VersionObject1.Commands.Add();
		CommandString.Id = Command.Id;
		CommandString.Presentation = Command.Representation;
		CommandString.ShouldShowUserNotification = Command.ShowNotification;
		CommandString.Modifier = Command.Modifier;
		
		CallMethodsConversionDictionary =
			AdditionalReportsAndDataProcessorsSaaSManifestInterface.AdditionalReportsAndDataProcessorsCallMethodsDictionary();
		CommandString.StartupOption = CallMethodsConversionDictionary[Command.StartupType];
		
	EndDo;
	
	VersionObject1.Permissions.Clear();
	For Each Permission In Manifest.Permissions Do
		
		XDTOType = Permission.Type(); // XDTOObjectType
		
		Resolution = VersionObject1.Permissions.Add();
		Resolution.PermissionKind = XDTOType.Name;
		
		Parameters = New Structure();
		
		For Each XDTOProperty In XDTOType.Properties Do
			
			Container = Permission.GetXDTO(XDTOProperty.Name);
			
			If Container <> Undefined Then
				Parameters.Insert(XDTOProperty.Name, Container.Value);
			Else
				Parameters.Insert(XDTOProperty.Name);
			EndIf;
			
		EndDo;
		
		Resolution.Parameters = New ValueStorage(Parameters);
		
	EndDo;
	
EndProcedure

#EndRegion