///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the types of interaction items, such as orders, vacancies, and so on.
// Used if at least one interaction item is defined in the configuration. 
//
// Parameters:
//  SubjectsTypes  - Array -  interaction items (String),
//                            for example, " document Link.Customer's order", etc.
//
Procedure OnDeterminePossibleSubjects(SubjectsTypes) Export
	
	
	
EndProcedure

// Sets descriptions of possible types of contacts and interactions, for example: partners, contact persons, and so on.
// Used if the configuration defines at least one type of interaction contacts
// other than the users directory. 
//
// Parameters:
//  ContactsTypes - Array - :
//     * Type                               - Type    -  type of contact link.
//     * Name                               - String -  name of the contact type as defined in the metadata.
//     * Presentation                     - String -  representation of the contact type to display to the user.
//     * Hierarchical                     - Boolean -  indicates whether the directory is hierarchical.
//     * HasOwner                      - Boolean -  indicates that the contact has an owner.
//     * OwnerName                      - String -  name of the contact owner, as defined in the metadata.
//     * SearchByDomain                    - Boolean -  indicates that contacts of this type will be selected
//                                                    by matching the domain, and not by the full email address.
//     * Link                             - String -  describes the possible connection of this contact with another contact,
//                                                    if the current contact is a detail of another contact.
//                                                    Described by the following line " table Name.Requestname".
//     * ContactPresentationAttributeName - String -  name of the contact details that the contact view will be received from
//                                                    . If not specified,
//                                                    the standard name is used.
//     * InteractiveCreationPossibility - Boolean - 
//                                                    
//     * NewContactFormName            - String -  full name of the form for creating a new contact.
//                                                    For Example, " Directory.Partners.Form.Assistant Manager".
//                                                    If not filled in, the default element form opens.
//
Procedure OnDeterminePossibleContacts(ContactsTypes) Export

	

EndProcedure

#EndRegion



