///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
// 
// See BatchEditObjectsClient.ChangeSelectedItems
// 
// Parameters:
//  Objects - Array of MetadataObject
//
// Example:
//	
//	
//
Procedure OnDefineObjectsWithBatchObjectsModificationCommand(Objects) Export

	

EndProcedure

// Define metadata objects whose Manager modules restrict the ability 
// to edit details during group changes.
//
// Parameters:
//   Objects - Map of KeyAndValue - 
//                             
//                            :
//                            
//                            
//                            
//                            
//
// Example: 
//   Objects.Insert (Metadata.Documents.Customer's order.Full name(), "*"); // both functions are defined.
//   Objects.Insert (Metadata.business process.Setting a role forwarding.FullName (), " Requisites Editable By The Groupreferences");
//   Objects.Insert (Metadata.Guides.Partners.FullName (), " Requisites Editable By The Groupreferences
//		|Requisites for editable groupprocessing");
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	
	
EndProcedure

// 
// 
// 
// 
// 
// Parameters:
//  Object - MetadataObject - 
//  AttributesToEdit - Undefined, Array of String - 
//                                                            
//  AttributesToSkip - Undefined, Array of String - 
// 
Procedure OnDefineEditableObjectAttributes(Object, AttributesToEdit, AttributesToSkip) Export

EndProcedure

#EndRegion
