///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Overrides the setting of input commands on the base.
//
// Parameters:
//  Settings - Structure:
//   * UseInputBasedOnCommands - Boolean -  allows the use of program-based input commands
//                                                    instead of regular ones. The default value is: True.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
//   Objects - Array -  metadata objects (metadata Objects) with commands to create based on.
//
// Example:
//  Objects.Add (Metadata.Guides.Companies);
//
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	

EndProcedure

// Called to generate a list of create commands based on the create command base, once for when
// necessary, and then the result is cached using the module with repeated use of the return values.
// Here you can define base creation commands that are common to most configuration objects.
//
// Parameters:
//   GenerationCommands - ValueTable - :
//     
//     
//       * Id - String - 
//     
//     :
//       * Presentation - String   -  representation of the team in the form.
//       * Importance      - String   -  the group in the submenu to display this command in.
//                                    Allowed to use: "Important", "Normal" and "Stacie".
//       * Order       - Number    -  the order in which the command is placed in the submenu. Used for setting up for a specific
//                                    workplace.
//       * Picture      - Picture - 
//     
//     :
//       * ParameterType - TypeDescription -  types of objects that this command is intended for.
//       * VisibilityInForms    - String -  comma-separated form names that the command should be displayed in.
//                                        Used when the composition of teams differs for different forms.
//       * FunctionalOptions - String -  comma-separated names of functional options that define the visibility of the command.
//       * VisibilityConditions    - Array -  determines the visibility of the command depending on the context.
//                                        To register conditions, use the procedure
//                                        Pluggable commands.Dobasefinalization().
//                                        Conditions are combined by "And".
//       * ChangesSelectedObjects - Boolean - 
//                                        
//                                        
//                                        
//     
//     :
//       * MultipleChoice - Boolean
//                            - Undefined - 
//             
//             
//       * WriteMode - String -  actions related to writing an object that are performed before the command handler.
//             "Non-write" - the Object is not written, and the entire form is passed in the handler parameters instead of references
//                                       . In this mode, we recommend working directly with the form
//                                       that is passed in the structure of the 2 parameters of the command handler.
//             "Write new objects" - Write new objects.
//             "Write" - Write new and modified objects.
//             "Conduct" - Conduct documents.
//             The user is asked for confirmation before recording and conducting the session.
//             Optional. Default value: "Write".
//       * FilesOperationsRequired - Boolean - 
//             
//             
//     
//     :
//       * Manager - String -  the object responsible for executing the command.
//       * FormName - String -  name of the form to get for executing the command.
//             If no Handler is specified, the "Open" method is called for the form.
//       * FormParameters - Undefined
//                        - FixedStructure - 
//       * Handler - String - 
//             
//             :
//               
//               
//       * AdditionalParameters - FixedStructure -  optional. Parameters of the handler specified in the Handler.
//   
//   Parameters - Structure - :
//       * FormName - String -  full name of the form.
//
//   StandardProcessing - Boolean -  if set to False, the "add command to create Base" event of
//                                   the object Manager will not be called.
//
Procedure BeforeAddGenerationCommands(GenerationCommands, Parameters, StandardProcessing) Export

EndProcedure

// Defines a list of creation commands based on. Called before calling "
// add a command to create a Base" in the object Manager module.
//
// Parameters:
//  Object - MetadataObject -  object to add commands to.
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//  StandardProcessing - Boolean -  if set to False, the "add command to create Base" event of
//                                  the object Manager will not be called.
//
Procedure OnAddGenerationCommands(Object, GenerationCommands, Parameters, StandardProcessing) Export
	
	
	
EndProcedure

#EndRegion