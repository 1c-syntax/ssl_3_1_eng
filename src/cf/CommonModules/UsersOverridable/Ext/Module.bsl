///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Overrides the standard behavior of the Users subsystem.
//
// Parameters:
//  Settings - Structure:
//   * CommonAuthorizationSettings - Boolean - 
//          
//          
//          
//          
//
//   * EditRoles - Boolean -  determines whether the interface for changing roles 
//          in the user, external user, and external user group cards
//          is available (including for the administrator). The default value is True.
//
//   * IndividualUsed - Boolean - 
//          
//
//   * IsDepartmentUsed  - Boolean - 
//          
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Allows you to specify roles whose assignment will be controlled in a special way.
// Most configuration roles do not need to be specified here, because they are intended for any users 
// other than external users.
//
// Parameters:
//  RolesAssignment - Structure:
//   * ForSystemAdministratorsOnly - Array - 
//     
//     :
//       
//     
//       
//       
//       
//     
//
//   * ForSystemUsersOnly - Array - 
//     
//     
//     :
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
//   * ForExternalUsersOnly - Array - 
//     :
//       
//     
//
//   * BothForUsersAndExternalUsers - Array - 
//     :
//       
//     
//
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	
	
EndProcedure

// Overrides the behavior of the user form and the external user form
// , or the external user group, when it should differ from the default behavior.
//
// For example, you need to hide/show or allow changing/blocking
// certain properties in cases that are defined by the application logic.
//
// Parameters:
//  UserOrGroup - CatalogRef.Users
//                        - CatalogRef.ExternalUsers
//                        - CatalogRef.ExternalUsersGroups - 
//                          
//
//  ActionsOnForm - Structure:
//         * Roles                   - String -  "", "View", "Edit".
//                                             For example, when roles are edited in another form, you can hide
//                                             them in this form or only block editing.
//         * ContactInformation   - String -  "", "View", "Edit".
//                                             This property is missing for external user groups.
//                                             For example, you may need to hide contact information
//                                             from the user if you don't have application rights to view the CI.
//         * IBUserProperies - String -  "", "View", "Edit".
//                                             This property is missing for external user groups.
//                                             For example, you may need to show the properties of the information security user
//                                             for a user who has application rights to this information.
//         * ItemProperties       - String -  "", "View", "Edit".
//                                             For example, if the Name is the full name of the is user,
//                                             you may need to allow editing the name
//                                             for a user who has application rights to personnel operations.
//
Procedure ChangeActionsOnForm(Val UserOrGroup, Val ActionsOnForm) Export
	
EndProcedure

// Defines additional actions when recording an information database user.
// For example, if you need to update a record in the corresponding register synchronously, and so on.
// Called from the Users procedure.Ostrovityanova if the user was really modified.
// If the Name field in the old Property structure is not filled in, a new is user is created.
//
// Parameters:
//  PreviousProperties - See Users.NewIBUserDetails.
//  NewProperties  - See Users.NewIBUserDetails.
//
Procedure OnWriteInfobaseUser(Val PreviousProperties, Val NewProperties) Export
	
EndProcedure

// Defines actions after deleting the user of the information database.
// For example, if you need to update a record in the corresponding register synchronously, and so on.
// Called from the delete Userib procedure if the user was deleted.
//
// Parameters:
//  PreviousProperties - See Users.NewIBUserDetails.
//
Procedure AfterDeleteInfobaseUser(Val PreviousProperties) Export
	
EndProcedure

// Overrides the interface settings that are set for new users.
// For example, you can set initial settings for the location of command interface sections.
//
// Parameters:
//  InitialSettings1 - Structure:
//   * ClientSettings    - ClientSettings           -  configure the client application.
//   * InterfaceSettings - CommandInterfaceSettings            -  command interface settings (
//                                                                      section panels, navigation panels, and action panels).
//   * TaxiSettings      - ClientApplicationInterfaceSettings -  customize the interface of the client application
//                                                                      (composition and arrangement of panels).
//
//   * IsExternalUser - Boolean -  if True, this is an external user.
//
Procedure OnSetInitialSettings(InitialSettings1) Export
	
	
	
EndProcedure

// 
// 
//  (See OnSaveOtherSetings)
//  (See OnDeleteOtherSettings)
//
// 
//
// Parameters:
//  UserInfo - Structure - :
//       * UserRef  - CatalogRef.Users -  the user
//                               to get the settings from.
//       * InfobaseUserName - String -  the user of the information base
//                                             to get the settings from.
//  Settings - Structure - :
//       * Key     - String -  string ID of the setting to use later
//                             for copying and clearing this setting.
//       * Value - Structure:
//              ** SettingName1  - String -  the name that will be displayed in the settings tree.
//              ** PictureSettings  - Picture -  the image that will be displayed in the settings tree.
//              ** SettingsList     - ValueList -  list of received settings.
//
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//  Settings - Structure:
//       * SettingID - String -  string ID of the setting to copy.
//       * SettingValue      - ValueList - 
//  :
//       * UserRef - CatalogRef.Users -  the user
//                              who needs to copy the setting.
//       * InfobaseUserName - String -  the user of the information base
//                                             who needs to copy the setting.
//
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//  Settings - Structure:
//       * SettingID - String -  string ID of the setting to clear.
//       * SettingValue      - ValueList - 
//  :
//       * UserRef - CatalogRef.Users -  the user
//                              who needs to clear the setting.
//       * InfobaseUserName - String -  the user of the information base
//                                             who needs to clear the setting.
//
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	
	
EndProcedure

// Allows you to specify your own user selection form.
//
// In the form being developed, you must:
// - set the Official selection = False, the selection should be removed only under full rights;
// - if the selection is Invalid = False, the selection must be removed under any user.
//
// When implementing a custom form, you must support the form parameters or use a standard form:
// - Close the selection
// - Multiple selections
// -  Fibrocartilage
//
// To work as a form for selecting participants in the discussion, you must:
// - send the selection result to the closing notification
// - the selection result must be represented by an array of user IDs
//   of the interaction system.
//
// Parameters:
//   SelectedForm - String -  name of the form to open.
//   FormParameters - Structure - :
//   * CloseOnChoice - Boolean -  contains an indication that the form
// 									should be closed after the selection is made.
// 									If the property is set to False, you can use
// 									the form to select multiple positions or elements.
//   * MultipleChoice - Boolean -  allows or disables selecting multiple rows from the list.
//   * SelectConversationParticipants - Boolean -  if True, the form is called as a form for selecting participants in the discussion.
// 										   The form must return an array of system user IDs
// 										   Interactions.
//
//   * PickingCompletionButtonTitle - String -  title of the selection completion button.
//   * HideUsersWithoutMatchingIBUsers - Boolean -  if True, users without
// 													  an is user ID should not be displayed in the list.
//   * UsersGroupsSelection - Boolean -  allow selecting user groups.
// 										 If user groups are used and the parameter is not supported,
// 										 then you cannot assign rights to the user group via the selection form.
//   * UsersToHide - ValueList -  users who are not displayed in the selection form.
//                            - Undefined
//   * CurrentRow - CatalogRef.UserGroups - 
//                       
//                   - Undefined - 
//
//   * AdvancedPick - Boolean -  if True, you can view user Groups.
//   * ExtendedPickFormParameters - String - :
//   ** SelectedUsers - Array of CatalogRef.Users - 
//                                
//   ** PickFormHeader - String - 
//   ** PickingCompletionButtonTitle - String - 
//
Procedure OnDefineUsersSelectionForm(SelectedForm, FormParameters) Export

EndProcedure

// 
// 
// 
// 
// 
//
// Parameters:
//  Settings - Array of EventLogAccessEventUseDescription
//
Procedure OnDefineRegistrationSettingsForDataAccessEvents(Settings) Export
	
EndProcedure

#EndRegion
