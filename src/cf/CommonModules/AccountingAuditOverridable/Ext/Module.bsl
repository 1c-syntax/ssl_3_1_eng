///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to set general subsystem settings.
//
// Parameters:
//   Settings - Structure:
//     * IssuesIndicatorPicture    - Picture -  which will be displayed as
//                                      an error indicator in the column of the dynamic list
//                                      list forms and on a special panel of object forms.
//     * IssuesIndicatorNote   - String -  an explanatory line to the error.
//     * IssuesIndicatorHyperlink - String -  the text of the hyperlink, when clicked on,
//                                      a report with errors will be generated and opened.
//
// Example:
//   Settings = New Structure;
//   Settings.Insert("The picture of the Problem Indicator", the Picture library.Warning);
//   Settings.Insert ("Problem Indicator explanation", Undefined);
//   Settings.Insert("Hyperlink Problem Indicator", Undefined);
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// It is designed to connect your own rules for checking accounting.
//
// Parameters:
//   ChecksGroups - ValueTable - :
//      * Description                 - String -  name of the verification group.
//      * GroupID          - String - : 
//                                       
//                                       
//      * Id                - String - 
//                                       :
//                                        
//                                       
//      * AccountingChecksContext - DefinedType.AccountingChecksContext -  a value that further
//                                       clarifies whether a group of accounting checks belongs to a certain
//                                       category.
//      * Comment                  - String -  comment on the verification group.
//
//   Checks - ValueTable - :
//      * GroupID          - String - : 
//                                                
//                                                 
//      * Description                 - String -  the name of the check displayed to the user.
//      * Reasons                      - String -  description of possible causes that lead to the problem.
//      * Recommendation                 - String -  recommendation for solving the problem.
//      * Id                - String - 
//                                                :
//                                                
//                                                
//      * CheckStartDate           - Date -  threshold date indicating the boundary of the objects to be checked
//                                              (only for objects with a date, for example, documents). Objects whose date 
//                                              is less than the specified date should not be checked. By default 
//                                              , it is not filled in (i.e. check everything).
//      * IssuesLimit                 - Number -  the number of objects to be checked. By default, 1000. 
//                                               If 0 is specified, then all objects should be checked.
//      * HandlerChecks           - String -  the name of the export procedure handler of the server shared module
//                                                in the form of a module name.Procedure name.
//      * GoToCorrectionHandler - String - 
//                                                  
//                                                  
//                                                  : 
//                                                    
//                                                      
//                                                      
//                                                               
//                                                    
//                                                  
//                                                 
//      * NoCheckHandler       - Boolean -  indicates a service check that does not have a handler procedure.
//      * ImportanceChangeDenied   - Boolean -  if True, the administrator will not be able to reconfigure 
//                                                the importance of this check.
//      * AccountingChecksContext - DefinedType.AccountingChecksContext -  a value that further 
//                                                clarifies whether the accounting check belongs to a certain group 
//                                                or category.
//      * AccountingCheckContextClarification - DefinedType.AccountingCheckContextClarification -  the second value, 
//                                                 which further clarifies whether the accounting check belongs 
//                                                 to a certain group or category.
//      * AdditionalParameters      - ValueStorage -  arbitrary additional verification information
//                                                 for programmatic use.
//      * Comment                  - String -  a text comment to the check.
//      * isDisabled                    - Boolean -  if True, then the check will not be performed in the background according to the schedule.
//      * SupportsRandomCheck - Boolean -  if True, then the check can be called to check a specific object.
//
// Example:
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
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
EndProcedure

// Allows you to adjust the position of the indicator about problems in the forms of objects.
//
// Parameters:
//   IndicationGroupParameters - Structure - :
//     * OutputAtBottom     - Boolean -  if True is specified, the indicator group will be displayed last 
//                           in the form or at the end of the specified group of elements of the Parent group name.
//                           By default, the False group is displayed at the beginning of the specified Parent Group name or 
//                           immediately under the command panel of the object form.
//     * GroupParentName - String -  defines the name of the group of elements of the object form, inside which 
//                           the display group should be located.
//     * DetailedKind      - Boolean -  if the truth is true and only one problem is found for the object
//                           , then its description will be immediately displayed in the card instead of a hyperlink with a transition to the list of problems.
//                           The default value is False.
//
//   ObjectWithIssueType - Type -  the type of link for which the parameters of the display group are being redefined.
//                     For Example, The Type("Document Link.Accrual of a fee").
//
Procedure OnDetermineIndicationGroupParameters(IndicationGroupParameters, Val ObjectWithIssueType) Export
	
EndProcedure

// Allows you to customize the appearance and position of the indicator column about problems in the forms of lists
// (with a dynamic list).
//
// Parameters:
//   IndicationColumnParameters - Structure - :
//     * OutputLast  - Boolean -  if True is specified, the indicator column will be displayed at the end.
//                            By default, the False column is displayed at the beginning.
//     * TitleLocation - FormItemTitleLocation -  sets the position of the indicator column header.
//     * Width             - Number -  the width of the indicator column.
//
//   FullName - String -  the full name of the object of the main table of the dynamic list.
//                        For example, Metadata.Documents.Accrual of the fee.Full name().
//
Procedure OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, FullName) Export
	
EndProcedure

// Allows you to fill in more information about the problem before registering it.
// In particular, you can fill in additional values to restrict access at the record level 
// to the list of accounting problems.
//
// Parameters:
//   Issue1 - Structure - :
//     * ObjectWithIssue         - AnyRef -  the object about which the problem is being recorded.
//                                                Or a reference to an element of the directory of identifiers of metadocts
//     * CheckRule          - CatalogRef.AccountingCheckRules -  a link to the completed check.
//     * CheckKind              - CatalogRef.ChecksKinds -  a reference to the type of check that 
//                                  the performed check belongs to.
//     * UniqueKey         - UUID -  the key to the uniqueness of the problem.
//     * IssueSummary        - String -  string-clarification of the found problem.
//     * IssueSeverity         - EnumRef.AccountingIssueSeverity -  the importance of the accounting problem
//                                  Information, Warning, Error, Useful advice and important information.
//     * EmployeeResponsible            - CatalogRef.Users -  filled in if it is possible
//                                  to identify the responsible person in the problem object.
//     * IgnoreIssue     - Boolean -  the flag for ignoring the problem. If the value is "True",
//                                  the problem record is ignored by the subsystem.
//     * AdditionalInformation - ValueStorage -  a service property with additional
//                                  information related to the identified problem.
//     * Detected                 - Date -  server identification time of the problem.
//
//   ObjectReference  - AnyRef -  a reference to the source object of the value for
//                     the additional dimensions being added.
//   Attributes       - MetadataObjectCollection -  a collection containing the details
//                     of the problem source object.
//
Procedure BeforeWriteIssue(Issue1, ObjectReference, Attributes) Export
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated: You should use the function when defining checks.
// It is designed to connect your own rules for checking accounting.
//
// Parameters:
//   ChecksGroups - ValueTable - :
//      * Description  - String -  the name of the verification group, for example: "System checks".
//      * Id - String -  the string ID of the group, for example: "System checks".
//
//   Checks - ValueTable - :
//      * Description                   - String -  name of the verification element. Required to fill in.
//      * Reasons                        - String -  possible reasons that led to the problem.
//                                                  Are displayed in the problem report. Optional to fill in.
//      * Recommendation                   - String -  recommendation for solving the problem.
//                                                  Are displayed in the problem report. Optional to fill in.
//      * Id                  - String -  the string ID of the check. Required to fill in.
//      * ParentID          - String -  the string ID of the verification group, for example: "System checks".
//                                                  Required to fill in.
//      * CheckStartDate             - Date -  threshold date indicating the boundary of the objects to be checked
//                                         (only for objects with a date). Objects whose date is less than
//                                         however, it should not be checked. By default, it is not filled in (i.e. check everything).
//      * IssuesLimit                   - Number -  the maximum number of objects to be checked.
//                                         By default, 0 - all objects should be checked.
//      * HandlerChecks             - String - 
//                                         
//                                         :
//                                           * Validation - CatalogRef.AccountingCheckRules -  an executable test.
//                                           * CheckParameters - Structure -  parameters of the check to be performed.
//                                                                             For more information, see the documentation.
//      * GoToCorrectionHandler - String -  
//                                         
//                                         :
//                                          * CheckID - String -  id of the check 
//                                                                    that identified the problem.
//                                          * CheckKind - CatalogRef.ChecksKinds -  a type of check 
//                                                          with additional information about the problem.
//      * AdditionalParameters        - ValueStorage -  additional verification information.
//
// Example:
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
Procedure OnDefineAppliedChecks(ChecksGroups, Checks) Export
	
EndProcedure

#EndRegion

#EndRegion



