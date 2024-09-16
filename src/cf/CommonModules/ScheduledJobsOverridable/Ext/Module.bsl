///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines the following properties of routine tasks:
//  - dependence on functional options;
//  - ability to run in different modes of the program;
//  - other parameters.
//
// Parameters:
//  Settings - ValueTable:
//    * ScheduledJob - MetadataObjectScheduledJob -  routine task.
//    * FunctionalOption - MetadataObjectFunctionalOption -  functional option
//        that the scheduled task depends on.
//    * DependenceByT      - Boolean -  if a routine task depends on more than
//        one functional option and needs to be enabled only
//        when all functional options are enabled, then specify True
//        for each dependency.
//        By default, False - if at least one functional option is enabled,
//        the routine task is also enabled.
//    * EnableOnEnableFunctionalOption - Boolean
//                                              - Undefined - 
//        
//        
//        
//    * AvailableInSubordinateDIBNode - Boolean
//                                  - Undefined - 
//        
//        
//    * AvailableAtStandaloneWorkstation - Boolean
//                                      - Undefined - 
//        
//        
//    * AvailableSaaS - Boolean
//                             - Undefined - 
//        
//        
//        
//    * UseExternalResources  - Boolean -  True if the scheduled task modifies data
//        in external sources (receiving mail, syncing data, etc.). Do not set
//        the value to True for scheduled tasks that do not modify data in external sources.
//        For example, a routine task for uploading courses in Currency. Routine tasks that work with external resources
//        are automatically disabled in the database copy. By default, it is False.
//    * IsParameterized             - Boolean -  True if the routine task is parameterized.
//        By default, it is False.
//
// Example:
//	Customization = Customization.Add ();
//	Settings.Routine Task = Metadata.Routine tasks.Obnovlenchestva;
//	Customization.Functional Option = Metadata.Functional options.Use postclient;
//	Customization.Testopenmailrelay = False;
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	
EndProcedure

// Allows you to override the default subsystem settings.
//
// Parameters:
//  Settings - Structure:
//    * UnlockCommandPlacement - String -  determines the location of the command to remove
//                                                     the lock on working with external resources
//                                                     when moving the information base.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure


#EndRegion