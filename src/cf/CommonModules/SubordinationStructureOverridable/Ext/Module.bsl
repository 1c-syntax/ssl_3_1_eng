///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called to retrieve the settings of the subsystem.
//
// Parameters:
//  Settings - Structure:
//   * Attributes - Map of KeyAndValue -  to redefine the names of object details that contain information 
//                                about the amount and currency displayed in the list of related documents. 
//                                The key specifies the full name of the metadata object, and the value 
//                                indicates that the Currency and document Totals correspond to the actual details of the object. 
//                                If not specified, the values are read from the details of the Currency and Somedocument.
//   * AttributesForPresentation - Map of KeyAndValue -  to override the representation of objects displayed
//                                in the list of related documents. The key specifies the full name of the metadata object, and the
//                                value specifies an array of names of the details whose values are involved in the formation of the view.
//                                To form a representation of the objects listed here 
//                                , the procedure structuresponderable will be called.Preprocessordirective.
//
// Example:
//	Bank Details = New Match;
//	Requisites.Insert ("Document Summary", Metadata.Documents.Invoice to the buyer.Requisites.The payment amount.Name);
//	Requisites.Insert ("Currency", Metadata.Documents.Invoice to the buyer.Requisites.Currency of the document.Name);
//	Customization.Requisites.Insert (Metadata.Documents.Invoice to the buyer.Full Name (), Bank Details);
//		
//	Equitytapready = new array;
//	Props for the presentation.Add (Metadata.Documents.E-mail outgoing.Requisites.Date of dispatch.Name);
//	Props for the presentation.Add (Metadata.Documents.E-mail outgoing.Requisites.Topic.Name);
//	Props for the presentation.Add (Metadata.Documents.E-mail outgoing.Requisites.List of recipientsreferences.Name);
//	Customization.Props for the presentation.Insert (Metadata.Documents.E-mail outgoing.Paloema(), 
//		Equitytapready);
//
Procedure OnDefineSettings(Settings) Export
	
	
	
EndProcedure

// Called to get a view of objects displayed in the list of related documents.
// Only for those objects that are listed in the properties property for the Representation Of the configuration parameter
// of the structuresponsibility procedure Undefined.When defining settings.
//
// Parameters:
//  DataType - AnyRef -  the reference type of the output object, see the property Type of the selection criterion of the linked documents.
//  Data    - QueryResultSelection
//            - Structure - :
//               * Ref - AnyRef -  reference of the object displayed in the list of related documents.
//               * AdditionalAttribute1 - Arbitrary -  value of the first attribute specified in the array 
//                 Details to represent The configuration parameter of the procedure when defining Customizations.
//               * AdditionalAttribute2 - Arbitrary -  the value of the second prop...
//               ...
//  Presentation - String -  put the calculated representation of the object in this parameter. 
//  StandardProcessing - Boolean -  set this parameter to False if the value of the View parameter is set.
//
Procedure OnGettingPresentation(DataType, Data, Presentation, StandardProcessing) Export
	
	
	
EndProcedure	

// Allows you to influence the output of objects in the Linked documents report.
//  Output has not started yet - data is being received.
//
// Parameters:
//  Object - CatalogRef
//         - DocumentRef
//         - TaskRef
//         - BusinessProcessRef
//         - ChartOfCharacteristicTypesRef -
//           
//  ObjectProperties - Structure - :
//    * IsMain2 - Boolean -  if True, this is the object for which the structure is formed.
//    * IsInternal - Boolean -  if True, the object is not required to be output. By default, it is False.
//    * IsSubordinateDocument - Boolean -  if True, then the object is subordinate to the main one.
//    * WasOutput - Structure - :
//        * InTotal - Number -  total output frequency of the object.
//        * InSubordinates - Number -  the frequency of the output of the object in the subordinate.
//  Cancel - Boolean -  if True, the object will not be displayed in the report.
//          However, this does not prevent the output of subordinate objects.
//
Procedure BeforeOutputLinkedObject(Object, ObjectProperties, Cancel) Export 
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//  
// 
// Parameters: 
//  DocumentName - String -  document name.
//
// Returns:
//   Array -  
//
Function ObjectAttributesArrayForPresentationGeneration(DocumentName) Export
	
	Return New Array;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//  Selection - QueryResultSelection -  a structure or selection from the query results
//            that contains additional details
//            that can be used to create an overridden view 
//            of the document for output to the "subordination Structure" report.
//
// Returns:
//   - String
//   - Undefined - 
//                    
//
Function ObjectPresentationForReportOutput(Selection) Export
	
	Return Undefined;
	
EndFunction

// Deprecated.
// 
// 
// 
// 
// 
// 
//
// Parameters:
//  DocumentName  - String -  name of the document to get the details name for.
//  Attribute      - String -  a string that can take the values "currency" and "document Sum".
//
// Returns:
//   String   - 
//
Function DocumentAttributeName(DocumentName, Attribute) Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion
