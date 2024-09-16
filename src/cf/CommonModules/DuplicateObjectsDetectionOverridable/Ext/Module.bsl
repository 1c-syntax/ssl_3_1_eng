///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Define metadata objects whose Manager modules provide the ability to parameterize 
// the duplicate search algorithm using the export procedures Parameterssearchable, Subsearchable, 
// and element substitution.
//
// Parameters:
//   Objects - Map of KeyAndValue - :
//       * Key     - String -  the full name of the metadata object connected to the Duplicate Search and Delete subsystem.
//                              For example, " Directory.Counterparties".
//       * Value - String - :
//                              
//                              
//                              
//                              
//                              
//
// Example:
//  1. The Handbook defines all of the procedure-handlers:
//  Objects.Insert (Metadata.Guides.Contractors.Full name(), "");
//
//  2.only the procedures are Defined for the parameters of searchable and near-Searchable:
//  Objects.Insert (Metadata.Guides.Tasks of the project.Paloema(), "Parametrictable
//                   |Preposterously");
//
Procedure OnDefineObjectsWithSearchForDuplicates(Objects) Export
	
	
	
EndProcedure

// 
// 
// See DuplicateObjectsDetectionClient.MergeSelectedItems
// 
// Parameters:
//     Objects - Array of MetadataObject
//
// Example:
//	
//	
//
Procedure OnDefineObjectsWithReferenceReplacementDuplicatesMergeCommands(Objects) Export

	

EndProcedure

// Allows you to implement additional checks for pairs of links to replace one with another.
// For example, you can prohibit replacing different types of items with each other.
// Basic checks to prevent replacing groups and links of different types are performed before calling 
// this handler.
//
// Parameters:
//     MetadataObjectName - String -  full name of the metadata reference object whose elements are being replaced.
//                                     For Example, " Directory.Contractors".
//     ReplacementPairs - Map of KeyAndValue:
//       * Key - AnyRef -  what will be replaced
//       * Value - AnyRef -  what will be replaced with
//     ReplacementParameters - Structure - :
//        * DeletionMethod - String - :
//                         
//                                             
//                         
//                                             
//                         
//     ProhibitedReplacements - Map of KeyAndValue:
//       * Key - AnyRef -  replacement link
//       * Value - String -  description of why the replacement is not allowed. If all substitutions are valid, an empty match is returned
//
Procedure OnDefineItemsReplacementAvailability(Val MetadataObjectName, Val ReplacementPairs, Val ReplacementParameters, ProhibitedReplacements) Export
	
EndProcedure

// Is called to determine the application parameters of the search takes.
// For example, you can prohibit replacing different types of items with each other for the item reference list.
//
// Parameters:
//     MetadataObjectName - String -  full name of the metadata reference object whose elements are being replaced.
//                                     For Example, " Directory.Contractors".
//     SearchParameters - Structure - :
//       * SearchRules - ValueTable - :
//         ** Attribute - String -  name of the prop to compare.
//         ** Rule  - String -  the rule of comparison: "Equal" - for exact equality, "Like" - similar strings,
//                                "" - do not compare.
//       * StringsComparisonForSimilarity - Structure - :
//          ** StringsMatchPercentage   - Number -  minimum match percentage for strings (from 0 to 100).
//                The match percentage is calculated based on the Levenshtein-Damerau distance, taking into account common 
//                types of errors: different case of characters, random insertion, deletion of one character, 
//                replacement of one character with another. Also, the order of words in the strings does not matter, 
//                i.e. for example, the strings "first second word" and "second first word" have a 100% match.
//                By default, 90.
//          ** SmallStringsMatchPercentage - Number -  minimum match percentage for small strings (from 0 to 100).
//                By default, 80.
//          ** SmallStringsLength - Number -  if the string length is less than or equal to the specified length, the string is considered small.
//                By default, 30.
//          ** ExceptionWords - Array of String -  a list of words to skip when comparing for similarity.
//                               For example, for companies and contractors, this may be: sole proprietor, state unitary enterprise, LLC, JSC, etc.
//       * FilterComposer - DataCompositionSettingsComposer -  initialized by the linker to 
//                             the pre-selection. It can be changed, for example, to enhance selections.
//       * ComparisonRestrictions - Array of Structure - :
//         ** Presentation      - String -  text description of the restriction rule.
//         ** AdditionalFields - String -  a comma-separated list of Bank details whose values are
//                                          required for analysis in the searchable list.
//       * ItemsCountToCompare - Number - 
//                                                   
//     AdditionalParameters - Arbitrary - 
//                               
//     StandardProcessing - Boolean -  specify False if the output parameter of the search Parameter is filled in and the call
//                            to the search handler is required. By default, True.
//
Procedure OnDefineDuplicatesSearchParameters(Val MetadataObjectName, SearchParameters, Val AdditionalParameters,
	StandardProcessing) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//     MetadataObjectName - String -  full name of the metadata reference object whose elements are being replaced.
//                                     For Example, " Directory.Contractors".
//     ItemsDuplicates - ValueTable - :
//         * Ref1  - AnyRef -  link to the first element.
//         * Ref2  - AnyRef -  link to the second element.
//         * IsDuplicates - Boolean      -  indicates that the candidates are duplicates. False by default. 
//                                    Can be set to True to mark duplicates.
//         * Fields1    - Structure   - 
//                                    
//                                    :
//             ** Code - String 
//             ** Description - String
//             ** DeletionMark - Boolean
//         * Fields2    - Structure   - :
//             ** Code - String 
//             ** Description - String
//             ** DeletionMark - Boolean
//     AdditionalParameters - Arbitrary - 
//                               
//
Procedure OnSearchForDuplicates(Val MetadataObjectName, Val ItemsDuplicates, Val AdditionalParameters) Export
	
EndProcedure

#EndRegion
