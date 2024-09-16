///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// You can define your own types of plug-in commands,
// in addition to those already provided in the standard delivery (printed forms, reports, and fill-in commands).
//
// Parameters:
//   AttachableCommandsKinds - ValueTable - :
//       * Name         - String            -  name of the command type. It must meet the requirements for naming variables and
//                                           be unique (not the same as the names of other types).
//                                           Can match the name of the subsystem responsible for the output of these commands.
//                                           The following names are reserved: "Print", "Reports", "populating Objects".
//       * SubmenuName  - String            -  name of the submenu for placing commands of this type on object forms.
//       * Title   - String            -  the name of the submenu that will be displayed to the user.
//       * Picture    - Picture          -  picture of the submenu.
//       * Representation - ButtonRepresentation -  the display mode submenu.
//       * Order     - Number             -  the order of submenus in the object form command panel in relation 
//                                           to other submenus. Used when automatically creating a submenu 
//                                           in the object form.
//
// Example:
//
//	View = View of pluggable commands.Add ();
//	View.Name = " Motivators";
//	View.Submenu Name = " Submenu Of Motivators";
//	View.Title = NSTR ("ru = 'Motivators'");
//	View.Picture = Of Bibliotecarios.Information;
//	View.Display = Display buttons.Picture text;
//	
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	
	
EndProcedure

// Allows you to extend the configuration parameter of the procedure for defining Customizations in the modules of report and 
// processing managers included in the pluggable reports and Processing subsystem, so that reports and processing can 
// report that they provide certain types of commands and interact with subsystems through their 
// program interface.
//
// Parameters:
//  InterfaceSettings4 - ValueTable:
//   * Key              - String        -  name of the setting, such as "add Motivators".
//   * TypeDescription     - TypeDescription -  type of setting, for example: New Apisination("Boolean").
//   * AttachableObjectsKinds - String -  names of the types of metadata objects that this setting will be available for,
//                                             separated by commas. For example: "Report" or "Report Processing".
//
// Example:
//  In order to provide a custom attribute for the add-ins of the processing module, add Motivators:
//  procedure for setting-Ins(Settings) Export
//    Customization.Dobasefinalization = True; // called procedure Dobasefinalization
//    Customization.Accommodation.Add (Metadata.Documents.Questionnaires);
//  End
//
//  of the procedure you should implement the following code:
//  Customization = Program interface settings.Add ();
//  Settings.Key = " Add Motivators";
//  Customization.Apisination = New Apisination("Boolean");
//  Customization.Viewable Objects = " Processing";
//
Procedure OnDefineAttachableObjectsSettingsComposition(InterfaceSettings4) Export
	
	
	
EndProcedure

// Called once during the first generation of the list of commands displayed in the form of a specific configuration object.
// The list of added commands should be returned in the Commands parameter.
// The result is cached using the module with repeated use of return values (in the context of form names).
//
// Parameters:
//   FormSettings - Structure - :
//         * FormName - String -  full name of the form that displays the plug-in commands. 
//                               For Example, " Document.Questionnaire.Formaspace".
//   
//   Sources - ValueTree -  
//         
//         :
//         * Metadata - MetadataObject -  the metadata object.
//         * FullName  - String           -  full name of the object. For example: "Document.Document name".
//         * Kind        - String           -  object type in uppercase. For example: "GUIDE".
//         * Manager   - Arbitrary     -  object Manager module, or Undefined if the object 
//                                           does not have a Manager module or if it could not be retrieved.
//         * Ref     - CatalogRef.MetadataObjectIDs -  link to the metadata object.
//         * IsDocumentJournal - Boolean -  True if the object is a document log.
//         * DataRefType     - Type
//                               - TypeDescription - 
//   
//   AttachedReportsAndDataProcessors - ValueTable -  
//         :
//         * FullName - String       -  full name of the metadata object.
//         * Manager  - Arbitrary -  the metadata object manager module.
//         For the composition of the columns, see the Pluggable command is undefined.When defining the set-up of the connected objects.
//   
//   Commands - ValueTable - : 
//       * Kind - String -  type of team.
//           More detailed  See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
//       * Id - String -  the ID of the team.
//       
//       1) Appearance settings.
//       * Presentation - String   -  representation of the team in the form.
//       * Importance      - String   -  suffix of the subgroup in the menu where this command should be displayed.
//                                    Allowed to use: "Important", "Normal" and "Stacie".
//       * Order       - Number    -  the order in which the team is placed in the group. Used for setting up for a specific
//                                    workplace. You can set it in the range from 1 to 100. By default, the order is 50.
//       * Picture      - Picture -  picture of the team. Optional.
//       * Shortcut - Shortcut -  keyboard shortcut to quickly call a command. Optional.
//       * OnlyInAllActions - Boolean -  display the command only in the More menu.
//       * CheckMarkValue - String -  
//                                    
//                                    :
//                                     
//                                                                                        
//                                    
//     
//       
//       * ParameterType - TypeDescription -  types of objects that this command is intended for.
//       * VisibilityInForms    - String -  comma-separated form names that the command should be displayed in.
//                                        Used when the composition of the teams is different for different shapes.
//       * Purpose          - String -  
//                                        :
//                                         
//                                         
//                                        
//       * FunctionalOptions - String -  comma-separated names of functional options that define the visibility of the command.
//       * VisibilityConditions    - Array -  determines the visibility of the command depending on the context.
//                                        To register conditions, use the procedure
//                                        Pluggable commands.Dobasefinalization().
//                                        Conditions are combined by "And".
//       * ChangesSelectedObjects - Boolean -  determines the availability of the command in a situation
//                                        when the user does not have rights to change the object.
//                                        If True, then in the situation described above, the button will be unavailable.
//                                        Optional. The default value is False.
//     
//       3) Execution process settings.
//       * MultipleChoice - Boolean -  if True, the command supports multiple selection.
//             In this case, a list of links will be passed in the execution parameter.
//             Optional. The default value is True.
//       * WriteMode - String - :
//             
//                                          
//                                          
//             
//             
//             
//             
//             
//       * FilesOperationsRequired - Boolean -  if True, then the web client is offered
//             to install an extension to work with 1C:Enterprise. Optional. The default value is False.
//     
//       4) Handler settings.
//       * Manager - String -  the object responsible for executing the command.
//       * FormName - String -  name of the form to get for executing the command.
//           If no Handler is specified, the "Open" method is called for the form.
//       * FormParameterName - String -  name of the form parameter to pass the link or array of links to.
//       * FormParameters - Undefined
//                        - Structure - 
//       * Handler - String - :
//           
//           
//             
//             
//           
//           
//            See AttachableCommandsClient.CommandExecuteParameters
//       * AdditionalParameters - Structure -  parameters of the handler specified in the Handler. Optional.
//
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	
	
EndProcedure

#EndRegion
