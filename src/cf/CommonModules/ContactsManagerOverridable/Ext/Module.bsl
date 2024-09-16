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
// 
// 
// 
//
// Parameters:
//  Settings - Structure:
//    * ShouldShowIcons - Boolean
//    * DetailsOfCommands - See ContactsManager.DetailsOfCommands
//    * PositionOfAddButton - ItemHorizontalLocation - 
//                                                                  
//                                                                  
//                                                                  
//                                                                         
//                                                                         
//                                                                         
//                                                                         
//    * CommentFieldWidth - Number - 
//                                      
//                                      
//
//  Example:
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
//		    	
//		    	
//		  
//
//		  
//			
//	   
//
Procedure OnDefineSettings(Settings) Export

	
    
EndProcedure

// Gets names of types of contact information in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - :
//     * Key     - String - 
//     * Value - String -  name of the type of contact information for the transmitted language code.
//  LanguageCode - String -  language code. For example, "en".
//
// Example:
//  
//
Procedure OnGetContactInformationKindsDescriptions(Descriptions, LanguageCode) Export
	
	
	
EndProcedure

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	
	
EndProcedure

// See also updating the information base undefined.customizingmachine infillingelements
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles -  the object to fill in.
//  Data                  - ValueTableRow -  data for filling in the object.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable -  the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

#EndRegion
