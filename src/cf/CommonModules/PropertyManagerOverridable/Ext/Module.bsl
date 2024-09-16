///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets a description of predefined sets of properties.
//
// Parameters:
//  Sets - ValueTree:
//     * Name           - String -  name of the property set. Formed from the full name
//          of the metadata object by replacing the "." character with "_".
//          For Example, "Customer's Document_order".
//     * Id - UUID -  unique identifier of a predefined set of properties.
//          Must not be repeated in other property sets.
//          The format of the Random UUID identifier (Version 4).
//          To get the ID, you need to use 1C mode:You can calculate the value of
//          the platform constructor "New Unique Identifier" or use an online generator,
//          for example, https://www.uuidgenerator.net/version4.
//     * Used  - Undefined
//                     - Boolean - 
//          
//          
//     * IsFolder     - Boolean -  True if the property set is a group.
//
Procedure OnGetPredefinedPropertiesSets(Sets) Export
	
	
	
EndProcedure

// Gets the names of second-level property sets in different languages.
//
// Parameters:
//  Descriptions - Map of KeyAndValue - :
//     * Key     - String -  name of the property set. For Example, " Directory_Partneriba".
//     * Value - String -  name of the set for the transmitted language code.
//  LanguageCode - String -  language code. For example, "en".
//
// Example:
//  Names ["Directory_Partneriba"] = NBC("EN='General'; en= 'General';", language Code);
//
Procedure OnGetPropertiesSetsDescriptions(Descriptions, LanguageCode) Export
	
	
	
EndProcedure

// Fills in the object's property sets. Usually required if there are more than one sets.
//
// Parameters:
//  Object       - AnyRef      -  a reference to an object with properties.
//               - ClientApplicationForm - 
//               - FormDataStructure - 
//
//  RefType    - Type -  type of property owner reference.
//
//  PropertiesSets - ValueTable:
//     * Set - CatalogRef.AdditionalAttributesAndInfoSets
//     * SharedSet - Boolean - 
//                             
//    
//    
//    
//
//    
//
//    
//     * Height                   - Number
//     * Title                - String
//     * ToolTip                - String
//     * VerticalStretch   - Boolean
//     * HorizontalStretch - Boolean
//     * ReadOnly           - Boolean
//     * TitleTextColor      - Color
//     * Width                   - Number
//     * TitleFont           - Font
//                    
//    
//     * Group              - ChildFormItemsGroup
//
//    
//     * Representation              - UsualGroupRepresentation
//
//    
//     * Picture                 - Picture
//     * ShowTitle      - Boolean
//
//  StandardProcessing - Boolean -  initial value is True. Specifies whether to get
//                         the main set when the set of Properties is set.The number() is zero.
//
//  AssignmentKey   - Undefined -  (initial value) - specifies to calculate
//                      the destination key automatically and add the
//                      use key And save key to the form property values,
//                      So that changes to the form (settings, position, and size)are saved
//                      separately for different sets.
//                      For example, each item type has its own set composition.
//
//                   - String - 
//                      
//                      
//                      
//
//                    
//                    
//                    
//                    
//
Procedure FillObjectPropertiesSets(Val Object, RefType, PropertiesSets, StandardProcessing, AssignmentKey) Export
	
	
	
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

