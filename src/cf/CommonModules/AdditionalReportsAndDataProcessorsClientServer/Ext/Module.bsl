///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 

// Printed form.
//
// Returns:
//   String - 
//
Function DataProcessorKindPrintForm() Export
	
	Return "PrintForm"; // 
	
EndFunction

// Filling in the object.
//
// Returns:
//   String - 
//
Function DataProcessorKindObjectFilling() Export
	
	Return "ObjectFilling"; // 
	
EndFunction

// The creation of related objects.
//
// Returns:
//   String - 
//
Function DataProcessorKindRelatedObjectCreation() Export
	
	Return "RelatedObjectsCreation"; // 
	
EndFunction

// Assignable report.
//
// Returns:
//   String - 
//
Function DataProcessorKindReport() Export
	
	Return "Report"; // 
	
EndFunction

// The creation of related objects.
//
// Returns:
//   String - 
//
Function DataProcessorKindMessageTemplate() Export
	
	Return "MessageTemplate"; // 
	
EndFunction

// Additional processing.
//
// Returns:
//   String - 
//
Function DataProcessorKindAdditionalDataProcessor() Export
	
	Return "AdditionalDataProcessor"; // 
	
EndFunction

// Additional report.
//
// Returns:
//   String - 
//
Function DataProcessorKindAdditionalReport() Export
	
	Return "AdditionalReport"; // 
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
//   
//   
//   
//       
//       //
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
//       //
//       
//       	
//       
//   
//   
//       
//       //
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
//       //
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
//       
//       
//       //
//       
//       	
//       
//   
//   
//       
//       //
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
//       
//       //
//       
//       	
//       
//   
//   
//       
//       //
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
//       
//       //
//       
//       	
//       
//
// Returns:
//   String - 
//
Function CommandTypeServerMethodCall() Export
	
	Return "ServerMethodCall"; // 
	
EndFunction

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
//   
//   
//     
//     
//     
//
// Returns:
//   String - 
//
Function CommandTypeClientMethodCall() Export
	
	Return "ClientMethodCall"; // 
	
EndFunction

// Returns the name of the type of commands to open the form. When executing these commands
// , the main form of the external object opens with the following parameters.
//
//   General parameters:
//       Command Identifier - String - the name of the command defined in the function informationinternational processing().
//       Additional processing Link - Reference link.Additional processing reports are the reference of this object.
//           It can be used to read and save processing parameters.
//           It can also be used for background execution of long-term operations.
//           For more information, see the subsystem documentation, section "Background execution of long-term operations".
//       Formname - String - name of the owner form from which this command is called.
//   
//   Auxiliary parameters for processing the creation of related objects (View = "Creation of related objects"),
//   filling processing (View = "Object filling") and contextual reports (View = "Report"):
//       Object Assignments - Array - References of objects for which the command is called.
//   
//   Example of reading general parameters:
//       Objectlink = General purpose Clientserver.Structure properties(Parameters, "Additional Processing Link");
//       Command ID = The general purpose of the Client Server.Structure properties (Parameters, "Command Identifier");
//   
//   Example of reading the values of additional settings:
//       If the value is filled in (Object link) Then
//       	StoragesbUildings = General purpose.The value of the object's Session(Object link, "Storage settings");
//       	Settings = Storage Settings.Get();
//       	If the type is LCH(Settings) = Type("Structure") Then
//       		Fill in the values of the properties (this is the object, "<Name of the settings>");
//       	Endings;
//       Endings;
//   
//   Example of saving the values of additional settings:
//       Settings = New Structure ("<Name of settings>", <Values of settings>);
//       Additional Processing Object = Link object.Get an object();
//       Additional processing object.StoragesbUildings = New Storage Values(Settings);
//       Additional processing object.Write();
//
// Returns:
//   String - 
//
Function CommandTypeOpenForm() Export
	
	Return "OpeningForm"; // 
	
EndFunction

// 
//   
//   
//       
//       //
//       
//       
//       
//       
//       
//       
//       
//       
//       
//       //
//       
//       	
//       
//
// Returns:
//   String - 
//
Function CommandTypeFormFilling() Export
	
	Return "FillingForm"; // 
	
EndFunction

// 
//   
//   
//   
//       
//       //
//       
//       
//       
//       
//       
//       
//       //
//       
//       	
//       
//       
//       
//       //
//       
//       
//       
//       
//       
//       
//       
//       //
//       
//       	
//       
//       
//       
//       //
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
//       //
//       
//       	
//       
//
// Returns:
//   String - 
//
Function CommandTypeDataImportFromFile() Export
	
	Return "ImportDataFromFile"; // 
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// ID of the list form.
//
// Returns:
//   String - 
//
Function ListFormType() Export
	
	Return "ListForm"; // 
	
EndFunction

// ID of the object form.
//
// Returns:
//   String - 
//
Function ObjectFormType() Export
	
	Return "ObjectForm"; // 
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Filter for dialogs for selecting or saving additional reports and treatments.
//
// Returns:
//   String - 
//
Function SelectingAndSavingDialogFilter() Export
	
	Filter = NStr("en = 'External reports and data processors (*.%1, *.%2)|*.%1;*.%2|External reports (*.%1)|*.%1|External data processors (*.%2)|*.%2';");
	Filter = StringFunctionsClientServer.SubstituteParametersToString(Filter, "erf", "epf");
	Return Filter;
	
EndFunction

// Name of the section corresponding to the home page.
//
// Returns:
//   String - 
//
Function StartPageName() Export
	
	Return "Desktop"; 
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Returns:
//   String
//
Function DesktopID() Export
	
	Return "Desktop"; 
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Determines whether the scheduled task schedule is set.
//
// Parameters:
//   Schedule - JobSchedule -  schedule of a routine task.
//
// Returns:
//   Boolean - 
//
Function ScheduleSpecified(Schedule) Export
	
	Return Schedule = Undefined
		Or String(Schedule) <> String(New JobSchedule);
	
EndFunction

#EndRegion
