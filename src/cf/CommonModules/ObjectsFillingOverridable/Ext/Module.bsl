///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a fill command that forms commands for filling objects.
// For the syntax of the Add Completion Commands procedure, see the documentation.
//
// Parameters:
//   Objects - Array of MetadataObject -  metadata objects with fill-in commands.
//
// Example:
//  Objects.Add (Metadata.Guides.Companies);
//
Procedure OnDefineObjectsWithFIllingCommands(Objects) Export
	
EndProcedure

// Defines General fill-in commands.
//
// Parameters:
//   FillingCommands - ValueTable - :
//     
//     
//       * Id - String - 
//     
//     :
//       * Presentation - String   -  representation of the team in the form.
//       * Importance      - String   -  the group in the submenu to display this command in.
//                                    Options: "Important", "Normal" and "Stacie".
//       * Order       - Number    -  the order in which the command is placed in the submenu. Used for setting up for a specific
//                                    workplace.
//       * Picture      - Picture - 
//     
//     :
//       * ParameterType - TypeDescription -  types of objects that this command is intended for.
//       * VisibilityInForms    - String -  comma-separated form names that the command should be displayed in.
//                                        Used when the composition of the teams is different for different shapes.
//       * FunctionalOptions - String -  comma-separated names of functional options that define the visibility of the command.
//       * VisibilityConditions    - Array - 
//                                        
//                                        
//                                        
//     
//     :
//       * MultipleChoice - Boolean
//                            - Undefined - 
//             
//       * WriteMode - String - :
//            
//                                      
//            
//                                      
//                                      
//            
//            
//       * FilesOperationsRequired - Boolean - 
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
//       * AdditionalParameters - FixedStructure -  parameters of the handler specified in the Handler.
//   
//   Parameters - Structure - :
//       * FormName - String -  full name of the form.
//   StandardProcessing - Boolean -  if set to False, then the event Dobasefinalization Manager object is not
//                                   be invoked.
//
Procedure BeforeAddFillCommands(FillingCommands, Parameters, StandardProcessing) Export
	
EndProcedure

#EndRegion
