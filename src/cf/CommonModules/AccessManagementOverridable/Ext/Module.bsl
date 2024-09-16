///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Fills in the access types used in access restrictions.
// Note: access types Users and external Users are predefined,
// but you can remove them from the list of access Types if they are not required to restrict access rights.
//
// Parameters:
//  AccessKinds - ValueTable:
//   * Name                    - String -  the name used in the description of the supplied
//                                       access group profiles and the text of the ODD.
//   * Presentation          - String -  represents the type of access in profiles and access groups.
//   * ValuesType            - Type    -  the link type values access
//                                       for example, the Type (the"Spravochniki.Nomenclature").
//   * ValuesGroupsType       - Type    -  the type of reference group values access
//                                       for example, the Type (the"Spravochniki.Propylacetophenone").
//   * MultipleValuesGroups - Boolean -  True indicates that
//                                       multiple groups of values (item access Groups) can be selected for an access value (Item).
//
// Example:
//  1. To configure access rights in the context of companies:
//  Widthstep = Type of access.Add ();
//  Access View.Name = " Companies";
//  Type of access.Submission = NSTR ("ru = 'Companies'");
//  Type of access.Tipscasino = Type("Spravochniki.Companies");
//
//  2. To configure access rights by groups of partners:
//  Widthstep = Type of access.Add ();
//  Access View.Name = " Partner Group";
//  Type of access.Submission = NSTR ("ru = ' partner Groups'");
//  Type of access.Tipscasino = Type("Spravochniki.Partners");
//  Type of access.Topgroupname = Type("Spravochniki.Propylacetophenone");
//
Procedure OnFillAccessKinds(AccessKinds) Export
	
	
	
EndProcedure

// 
// 
//
//
// See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
////
//
//	
//  
//  
//  
//  
//  
//	
//
//
// 
// 
//
// Parameters:
//  Lists - Map of KeyAndValue - :
//             * Key     - MetadataObject -  list with restricted access.
//             * Value - Boolean -  True-text of the restriction in the Manager module,
//                                   False-the text of the restriction in this redefined
//                          module in the procedure for filling in access Restrictions.
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	
	
EndProcedure

// Fills in the descriptions of the supplied access group profiles and
// overrides the parameters for updating profiles and access groups.
//
// To automatically prepare the procedure content, use
// the developer tools for the access Control subsystem.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription,
//                               See AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean -  the initial value is True.
//   * DenyProfilesChange - Boolean -  the initial value is True.
//       If set to False, then the supplied profiles can not only be viewed, but also edited.
//   * UpdatingAccessGroups     - Boolean -  the initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean -  the initial value is False.
//       If set to True, the value settings made by the administrator for
//       the type of access that was removed from the profile will also be removed from the access groups.
//
// Example:
//  Profile Description = Access Management.New Descriptionprofile Access Group();
//  Description of the profile.Name = "Manager";
//  Description of the profile.ID = "75fa0ecb-98aa-11df-b54f-e0cb4ed5f655";
//  Description of the profile.Name = NStr("ru = 'Sales Manager'", General purpose.Main Language Code());
//  Description of the profile.Roles.Add("Launching a Web Client");
//  Description of the profile.Roles.Add("Launching a Client");
//  Description of the profile.Roles.Add("Basic Right");
//  Description of the profile.Roles.Add("Subsystem_Sales");
//  Description of the profile.Roles.Add("Adding and changing the documents of purchasers");
//  Description of the profile.Roles.Add("View the Purchase Book");
//  Descriptionprofiles.Add(Profile Description);
//
//  Folder description = Access Control.New Description of the folder of the Profile of the Access Group();
//  Description of the folder.Name = "Additional profiles";
//  Description of the folder.ID = "69a066e7-ce81-11eb-881c-b06ebfbf08c7";
//  Description of the folder.Name = NStr("ru = 'Additional profiles'", general purpose.Main Language Code());
//  Descriptionprofiles.Add(Folder Description);
//
//  Profile Description = Access Management.New Descriptionprofile Access Group();
//  Description of the profile.Parent = "Additional profiles";
//  Description of the profile.ID = "70179f20-2315-11e6-9bff-d850e648b60c";
//  Description of the profile.Name = NStr("ru = 'Editing, sending by mail, saving printed forms to a file (optional)'",
//  	General purpose.Main Language Code());
//  Description of the profile.Description = NStr("ru = 'Additionally assigned to users who should be able to edit,
//  	|before printing, sending by mail and saving the generated printed forms to a file.'");
//  Description of the profile.Roles.Add("Edit Printable forms");
//  Descriptionprofiles.Add(Profile Description);
//
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	
	
EndProcedure

// Fills in the dependencies of the access rights of the "subordinate" object (for example, the task of the task Executor)
// on the "master" object (for example, the business process Task), which differ from the standard ones.
//
// Rights dependencies are used in the standard access restriction template for the "Object" access type.
// 1. as a Standard, when reading a "subordinate" object
//    , it checks whether the "master" object has read rights and
//    checks whether the "master" object has no read restrictions.
// 2. as a Standard, when adding, changing, or deleting a "subordinate" object
//    , the right to change the "master" object
//    is checked, and the absence of restrictions on changing the "master" object is checked.
//
// Only one reassignment is allowed compared to the standard one -
// in point 2, instead of checking the right to change the "master" object, set
// the check for the right to read the "master" object.
//
// Parameters:
//  RightsDependencies - ValueTable:
//   * LeadingTable     - String -  for example, Metadata.business process.Task.Full name().
//   * SubordinateTable - String -  for example, Metadata.Tasks.Executor's task.Full name().
//
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	
	
EndProcedure

// Fills in a description of the possible rights to be assigned to objects of the specified types.
//
// Parameters:
//  AvailableRights - ValueTable:
//   * RightsOwner - String -  full name of the access value table.
//
//   * Name          - String -  ID of the right, such as changing Folders. The right named manage
//                  Rights must be defined for the General rights configuration form "access Rights".
//                  Rights managementis the right to change rights by the rights owner, which is checked
//                  when opening a General Form.Astronavtov.
//
//   * Title    - String - :
//                  
//                  
//
//   * ToolTip    - String -  a hint to the rights title,
//                  such as "Add, edit, and mark delete folders".
//
//   * InitialValue - Boolean -  the initial value of the rights check box when adding a new row
//                  in the access Rights form.
//
//   * RequiredRights1 - Array of String -  names of the rights required for this right -
//                  for example, the "add Files" right requires the "modify Files" right.
//
//   * ReadInTables - Array of String -  full names of tables for which this right indicates the Read right.
//                  It is possible to use the " * " symbol, which means "for all other tables",
//                  since the Read right can only depend on the Read right, then only the " * " symbol makes sense
//                  (required for access restriction templates to work).
//
//   * ChangeInTables - Array of String -  full names of tables for which this right indicates the Change right.
//                  You can use the " * " symbol, which means "for all other tables"
//                  (required for access restriction templates to work).
//
Procedure OnFillAvailableRightsForObjectsRightsSettings(AvailableRights) Export
	
EndProcedure

// Defines the type of user interface used to configure access.
//
// Parameters:
//  SimplifiedInterface - Boolean -  the initial value is False.
//
Procedure OnDefineAccessSettingInterface(SimplifiedInterface) Export
	
EndProcedure

// Fills in the use of access types depending on the functional configuration options,
// for example, use the access group of the Nomenclature.
//
// Parameters:
//  AccessKind    - String -  the name of the access type specified in the procedure for filling in the individual Access.
//  Use - Boolean -  the initial value is True.
// 
Procedure OnFillAccessKindUsage(AccessKind, Use) Export
	
	
	
EndProcedure

// Allows you to override the restriction specified in the metadata object Manager module.
//
// Parameters:
//  List - MetadataObject -  the list for which you want to return the text limit.
//                              In the procedure for populating the list with access Restrictions, you must
//                              specify the value False for the list, otherwise the call will not be made.
//
//  Restriction - Structure:
//    * Text                             - String -  restricting access for users.
//                                          If the string is empty, it means that access is allowed.
//    * TextForExternalUsers1      - String -  restricting access for external users.
//                                          If the string is empty, it means that access is denied.
//    * ByOwnerWithoutSavingAccessKeys - Undefined -  to determine automatically.
//                                        - Boolean - 
//                                          
//                                          
//                                          
//   * ByOwnerWithoutSavingAccessKeysForExternalUsers - Undefined, Boolean -  the
//                                          same as for the parameter for the owner of the record of the key access.
//
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	
	
EndProcedure

// Fills in the list of access types used for restricting the rights of metadata objects.
// If the list of access types is not filled in, the access Rights report will show incorrect information.
//
// You must fill in only the access types used in the access restriction templates
// explicitly, and the access types used in access value sets can be obtained from the current
// state of the access Value set information register.
//
//  To automatically prepare the procedure content, use
// the developer tools for the access Control subsystem.
//
// Parameters:
//  LongDesc     - String -  multi-line string in the <table>format.<Right>.<Access view>[.Object table],
//                 for example, " Document.Parish payday.Reading.Companies",
//                           " Document.Parish payday.Reading.Contractors",
//                           " Document.Parish payday.Change.Companies",
//                           " Document.Parish payday.Change.Contractors",
//                           " Document.Electronic writing.Reading.An object.Document.Electronic Signature",
//                           " Document.Electronic writing.Change.An object.Document.Electronic Signature",
//                           " Document.Files.Reading.An object.Guide.Folders",
//                           " Document.Files.Reading.An object.Document.E-Mail",
//                           " Document.Files.Change.An object.Guide.Folders",
//                           " Document.Files.Change.An object.Document.Electronic writing".
//                 The access type of the Object is predefined as a literal. This type of access is used in
//                 access restriction templates as a "reference" to another object that
//                 the current table object is restricted to.
//                 When the "Object" access type is set, you also need to specify the table types
//                 that are used for this type of access. In other words, list the types
//                 that correspond to the field used in the access restriction template
//                 paired with the "Object"access type. When enumerating types by the "Object" access
//                 type, you only need to list the field types
//                 that the data Registers field has.Sets of access values.Object, other types are unnecessary.
// 
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	
	
EndProcedure

// Allows you to overwrite dependent sets of access values for other objects.
//
// Called from procedures
//  Upravleniyuosobymi.Write down a set of access values,
//  Upravleniyuosobymi.Write down the dependentenabor access values.
//
// Parameters:
//  Ref - AnyRef -  a reference to the object for which access value sets are written.
//
//  RefsToDependentObjects - Array -  array of reference Link, document Link, and so on elements.
//                 Contains references to objects with dependent sets of access values.
//                 The initial value is an empty array.
//
Procedure OnChangeAccessValuesSets(Ref, RefsToDependentObjects) Export
	
	
	
EndProcedure

#EndRegion