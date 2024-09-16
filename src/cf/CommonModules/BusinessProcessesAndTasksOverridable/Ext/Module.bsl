///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called to update business process data in the business Process data register.
//
// Parameters:
//  Record - InformationRegisterRecord.BusinessProcessesData -  recording business process data.
//
Procedure OnWriteBusinessProcessesList(Record) Export
	
EndProcedure

// Called to check the current user's rights to stop and continue the business process
// .
//
// Parameters:
//  BusinessProcess        - DefinedType.BusinessProcessObject
//  HasRights            - Boolean -  if you set it to False, you have no rights.
//  StandardProcessing - Boolean -  if set to False, the standard rights check will not be performed.
//
Procedure OnCheckStopBusinessProcessRights(BusinessProcess, HasRights, StandardProcessing) Export
	
EndProcedure

// Called to fill in the main Task details from the fill-in data.
//
// Parameters:
//  BusinessProcessObject  - DefinedType.BusinessProcessObject
//  FillingData     - Arbitrary        -  fill-in data that is passed to the fill-in handler.
//  StandardProcessing - Boolean              -  if set to False, the standard fill-in processing will not be
//                                               performed.
//
Procedure OnFillMainBusinessProcessTask(BusinessProcessObject, FillingData, StandardProcessing) Export
	
EndProcedure

// Called to fill in the task form parameters.
//
// Parameters:
//  BusinessProcessName           - String                         - 
//  TaskRef                - TaskRef.PerformerTask
//  BusinessProcessRoutePoint - BusinessProcessRoutePointRef.Job -  action.
//  FormParameters              - Structure:
//   * FormName       -  
//   * FormParameters - 
//
// Example:
//  If Process_name = "Task" Then
//      Formname = " Business Process.Task.Form.Fresnedilla" + Of Stockmarketandinvesting.Name;
//      Form parameters.Insert ("Formname", Formname);
//  Conicelli;
//
Procedure OnReceiveTaskExecutionForm(BusinessProcessName, TaskRef,
	BusinessProcessRoutePoint, FormParameters) Export
	
EndProcedure

// Fills in the list of business processes that are connected to the subsystem
// and whose Manager modules contain the following export procedures and functions:
//  - Redirection of the task.
//  - Task completion form.
//  - Processing of the default execution.
//
// Parameters:
//   AttachedBusinessProcesses - Map of KeyAndValue:
//     * Key - String -  full name of the metadata object connected to the subsystem;
//     * Value - String -  empty string.
//
// Example:
//   Connected business processes.Insert (Metadata.business process.Setting a role forwarding.Full name(), "");
//
Procedure OnDetermineBusinessProcesses(AttachedBusinessProcesses) Export
	
	
	
EndProcedure

// It is called from the modules of the Business Process Task subsystem objects to
// be able to configure the constraint logic in the application solution.
//
// For an example of filling in access value sets, see in the comments
// to the Access control procedure.Fill in the set of access values.
//
// Parameters:
//  Object - BusinessProcessObject.Job -  the object for which you need to fill sets.
//  Table - See AccessManagement.AccessValuesSetsTable
//
Procedure OnFillingAccessValuesSets(Object, Table) Export
	
	
	
EndProcedure

// Called from the executor roles directory Manager module when
// the executor roles are initially filled in in the application solution.
//
// Parameters:
//  LanguagesCodes - Array of String -  list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable -  fill-in data. The composition of columns corresponds to the set of details 
//                                 in the roles of Performers directory.
//  TabularSections - Structure - :
//   * Key - String -  name of the table part;
//   * Value - ValueTable - 
//                                  :
//                                  
//                                  
//                                  
//
Procedure OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections) Export
	
	
	
EndProcedure

// Called from the executor roles directory Manager module when
// the executor role element in the application solution is initially filled in.
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles -  the object to fill in.
//  Data                  - ValueTableRow -  fill-in data.
//  AdditionalParameters - Structure
//
Procedure AtInitialPerformerRoleFilling(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

// It is called from the task Manager module of the adressingtask objects when
// the task addressing objects are initially filled in in the application solution.
// The standard value type detail should be filled in in the procedure for the initial filling in of the address object element of the Task.
//
// Parameters:
//  LanguagesCodes - Array of String -  list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable -  fill-in data. The columns correspond to the set of requisites of the object PVC Objectarraylist.
//  TabularSections - Structure - :
//   * Key - String -  name of the table part;
//   * Value - ValueTable - 
//                                  :
//                                  
//                                  
//                                  
//
Procedure OnInitialFillingTasksAddressingObjects(LanguagesCodes, Items, TabularSections) Export
	
	
	
EndProcedure

// Called from the PVC Manager module of the task redirection Object when
// the task addressing element is initially filled in in the application solution.
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.TaskAddressingObjects -  the object to fill in.
//  Data                  - ValueTableRow -  fill-in data.
//  AdditionalParameters - Structure
//
Procedure OnInitialFillingTaskAddressingObjectItem(Object, Data, AdditionalParameters) Export
	
	
	
EndProcedure

#EndRegion
