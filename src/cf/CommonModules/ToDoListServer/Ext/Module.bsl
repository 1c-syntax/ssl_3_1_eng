///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Table of the user's current affairs.
// It is passed to the handlers when filling in the current data.
//
// Returns:
//  ValueTable - :
//    * Id  - String -  internal case ID used by the subsystem.
//    * HasToDoItems       - Boolean -  if True, the case is displayed in the user's to-do list.
//    * Important         - Boolean -  if True, the case will be highlighted in red.
//    * OutputInNotifications - Boolean -  if True, the case notification will be duplicated by a pop
//                             -up notification and displayed in the notification center.
//    * HideInSettings - Boolean -  if True, the case will be hidden in the current Affairs settings form.
//                            You can use it for cases that do not require multiple
//                            use, i.e. after they are completed, they
//                            will no longer be displayed for this information base.
//    * Presentation  - String -  view of the case that is displayed to the user.
//    * Count     - Number  -  quantitative indicator of the case, displayed in the title bar of the case.
//    * Form          - String -  full path to the form to open when you click on the to-do hyperlink
//                                in the Current Affairs panel.
//    * FormParameters - Structure -  parameters to open the metric form with.
//    * Owner       - String
//                     - MetadataObject -  string ID of the case that will be the owner for the current
//                       or metadata object subsystem.
//    * ToolTip      - String -  hint text.
//    * ToDoOwnerObject - String -  full name of the metadata object where the case completion handler is located.
//
Function ToDoList() Export
	
	UserTasks1 = New ValueTable;
	UserTasks1.Columns.Add("Id", New TypeDescription("String", New StringQualifiers(250)));
	UserTasks1.Columns.Add("HasToDoItems", New TypeDescription("Boolean"));
	UserTasks1.Columns.Add("Important", New TypeDescription("Boolean"));
	UserTasks1.Columns.Add("Presentation", New TypeDescription("String", New StringQualifiers(250)));
	UserTasks1.Columns.Add("HideInSettings", New TypeDescription("Boolean"));
	UserTasks1.Columns.Add("OutputInNotifications", New TypeDescription("Boolean"));
	UserTasks1.Columns.Add("Count", New TypeDescription("Number"));
	UserTasks1.Columns.Add("Form", New TypeDescription("String", New StringQualifiers(250)));
	UserTasks1.Columns.Add("FormParameters", New TypeDescription("Structure"));
	UserTasks1.Columns.Add("Owner");
	UserTasks1.Columns.Add("ToolTip", New TypeDescription("String", New StringQualifiers(250)));
	UserTasks1.Columns.Add("ToDoOwnerObject", New TypeDescription("String", New StringQualifiers(256)));
	UserTasks1.Columns.Add("HasUserTasks"); // 
	
	Return UserTasks1;
	
EndFunction

// Returns an array of command interface subsystems that include the passed
// metadata object.
//
// Parameters:
//  MetadataObjectName - String -  full name of the metadata object.
//
// Returns: 
//  Array - 
//
Function SectionsForObject(MetadataObjectName) Export
	ObjectsBelonging = ToDoListInternalCached.ObjectsBelongingToCommandInterfaceSections();
	
	CommandInterfaceSubsystems = New Array;
	SubsystemsNames                 = ObjectsBelonging.Get(MetadataObjectName);
	If SubsystemsNames <> Undefined Then
		For Each SubsystemName In SubsystemsNames Do
			CommandInterfaceSubsystems.Add(Common.MetadataObjectByFullName(SubsystemName));
		EndDo;
	EndIf;
	
	If CommandInterfaceSubsystems.Count() = 0 Then
		CommandInterfaceSubsystems.Add(DataProcessors.ToDoList);
	EndIf;
	
	Return CommandInterfaceSubsystems;
EndFunction

// Determines whether to display a task in the user's to-do list.
//
// Parameters:
//  ToDoItemID - String -  ID of the task to search for in the disabled list.
//
// Returns:
//  Boolean - 
//
Function UserTaskDisabled(ToDoItemID) Export
	ToDoItemsToDisable = New Array;
	SSLSubsystemsIntegration.OnDisableToDos(ToDoItemsToDisable);
	ToDoListOverridable.OnDisableToDos(ToDoItemsToDisable);
	
	Return (ToDoItemsToDisable.Find(ToDoItemID) <> Undefined)
	
EndFunction

// Returns the structure of common values used for calculating current cases.
//
// Returns:
//  Structure:
//    * User - CatalogRef.Users
//                   - CatalogRef.ExternalUsers - 
//    * IsFullUser - Boolean -  True if the user is a full-fledged user.
//    * CurrentDate - Date -  the current date of the session.
//    * DateEmpty  - Date -  an empty date.
//
Function CommonQueryParameters() Export
	Return ToDoListInternal.CommonQueryParameters();
EndFunction

// Sets General parameters of the queries for calculation of current Affairs.
//
// Parameters:
//  Query                 - Query    -  a query that
//                                       needs to fill in the General parameters.
//  CommonQueryParameters - Structure -  common values for the calculation of the indicators.
//
Procedure SetQueryParameters(Query, CommonQueryParameters) Export
	ToDoListInternal.SetCommonQueryParameters(Query, CommonQueryParameters);
EndProcedure

// Retrieves numeric case values from the passed request.
//
// The data request must contain only one row with an arbitrary number of fields.
// The values of these fields must be the values of the corresponding indicators.
//
// For example, such a request might look like this:
//   CHOOSE
//      Count(*) from <Name of a predefined element measure of the number of documents>.
//   FROM
//      the Document.<Document name>.
//
// Parameters:
//  Query - Query -  the request being executed.
//  CommonQueryParameters - Structure -  the total value to calculate the current Affairs.
//
// Returns:
//  Structure:
//     * Key     - String -  name of the current Affairs indicator.
//     * Value - Number -  numeric value of the indicator.
//
Function NumericUserTasksIndicators(Query, CommonQueryParameters = Undefined) Export
	Return ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
EndFunction

#EndRegion

