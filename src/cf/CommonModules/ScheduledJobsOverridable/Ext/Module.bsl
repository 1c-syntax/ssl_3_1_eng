///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Determines the following properties of scheduled jobs:
//  - dependence on functional options.
//  - ability of execution in different application modes.
//  - other parameters.
//
// Parameters:
//  Settings - ValueTable:
//    * ScheduledJob - MetadataObjectScheduledJob - a scheduled job.
//    * FunctionalOption - MetadataObjectFunctionalOption - functional option
//        the scheduled job depends on.
//    * DependenceByT      - Boolean - if the scheduled job depends on more than
//        one functional option and you want to enable it only
//        when all functional options are enabled, specify True
//        for each dependency.
//        The default value is False - if one or more functional options are enabled,
//        the scheduled job is also enabled.
//    * EnableOnEnableFunctionalOption - Boolean
//                                              - Undefined - if False, the scheduled job
//        will not be enabled if the functional option is enabled. The
//        Undefined value corresponds to True.
//        The default value is Undefined.
//    * AvailableInSubordinateDIBNode - Boolean
//                                  - Undefined - True or Undefined if the scheduled
//        job is available in the DIB node.
//        The default value is Undefined.
//    * AvailableAtStandaloneWorkstation - Boolean
//                                      - Undefined - True or Undefined if the scheduled
//        job is available in the standalone workplace.
//        The default value is Undefined.
//    * AvailableSaaS - Boolean
//                             - Undefined - — False if scheduled job
//        execution (including queue jobs) in the infobase with enabled separator must be locked.
//        The Undefined value is read as True.
//        Default value: Undefined.
//    * UseExternalResources  - Boolean - "True" if the scheduled job modifies data
//        in external sources (receiving emails, synchronizing data, etc.). Do not set the
//        value to True for scheduled jobs that do not modify data in external sources.
//        For example, CurrencyRateImport scheduled job. Scheduled jobs operating with external resources are
//        automatically disabled in the copy of the infobase and are blocked if the
//        "Allow access to web services" functional option is disabled. The default value is False.
//    * CanAccessExternalResources - Boolean - If UseExternalResources is set to False, but the scheduled job accesses external resources
//        (web services), for example, the ImportCurrenciesRates job,
//        then this flag should be set to True. By default, it equals the UseExternalResources parameter.
//        Scheduled jobs that work with Internet services will not run if the "Allow access to web services"
//        functional option is disabled.
//    * IsParameterized             - Boolean - True if the scheduled job is parameterized.
//        The default value is False.
//
// Example:
//	Setting = Settings.Add();
//	Setting.ScheduledJob = Metadata.ScheduledJobs.SMSDeliveryStatusUpdate;
//	Setting.FunctionalOption = Metadata.FunctionalOptions.UseEmailClient;
//	Setting.AvailableInSaaS = False;
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	
EndProcedure

// Allows to overwrite the default subsystem settings.
//
// Parameters:
//  Settings - Structure:
//    * UnlockCommandPlacement - String - determines unlock
//                                                     command location for operations with external resources
//                                                     on infobase movement.
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure


#EndRegion