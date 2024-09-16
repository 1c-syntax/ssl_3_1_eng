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

// Adding fields that will be used to form the business process view.
//
// Parameters:
//  ObjectManager      - BusinessProcessManager -  business process Manager.
//  Fields                 - Array -  fields that form the business process view.
//  StandardProcessing - Boolean -  if set to False, the standard fill-in processing will not be
//                                  performed.
//
Procedure BusinessProcessPresentationFieldsGetProcessing(ObjectManager, Fields, StandardProcessing) Export
	
	Fields.Add("Description");
	Fields.Add("Date");
	StandardProcessing = False;

EndProcedure

// 

// 
//
// Parameters:
//  ObjectManager      - BusinessProcessManager -  business process Manager.
//  Data               - Structure - : 
//  Presentation        - String -  representation of the business process.
//  StandardProcessing - Boolean -  if set to False, the standard fill-in processing will not be
//                                  performed.
//
Procedure BusinessProcessPresentationGetProcessing(ObjectManager, Data, Presentation, StandardProcessing) Export
	
#If Server Or ThickClientOrdinaryApplication Or ThickClientManagedApplication Or ExternalConnection Then
	Date = Format(Data.Date, ?(GetFunctionalOption("UseDateAndTimeInTaskDeadlines"), "DLF=DT", "DLF=D"));
	Presentation = Metadata.FindByType(TypeOf(ObjectManager)).Presentation();
#Else	
	Date = Format(Data.Date, "DLF=D");
	Presentation = NStr("en = 'Business process';");
#EndIf
	
	BusinessProcessRepresentation(ObjectManager, Data, Date, Presentation, StandardProcessing);
	
EndProcedure

// 

#EndRegion

#Region Private

// Processing getting a business process view based on data fields.
//
// Parameters:
//  ObjectManager      - BusinessProcessManager -  business process Manager.
//  Data               - Structure - :
//   * Description      - String -  name of the business process.
//  Date                 - Date   -  date when the business process was created.
//  Presentation        - String -  representation of the business process.
//  StandardProcessing - Boolean -  if set to False, the standard fill-in processing will not be
//                                  performed.
//
Procedure BusinessProcessRepresentation(ObjectManager, Data, Date, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	TemplateOfPresentation  = NStr("en = '%1, started on %2 (%3)';");
	Description         = ?(IsBlankString(Data.Description), NStr("en = 'No details';"), Data.Description);
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation, Description, Date, Presentation);
	
EndProcedure

#EndRegion