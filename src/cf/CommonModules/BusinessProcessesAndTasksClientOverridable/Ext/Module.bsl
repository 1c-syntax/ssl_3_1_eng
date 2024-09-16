///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when the form is opened the choice of the contractor.
// Allows you to override the standard selection form.
//
// Parameters:
//  PerformerItem   - FormField -  element of the form where the performer is selected.
//  PerformerAttribute  - CatalogRef.Users -  previously selected artist.
//                         Used to set the current line in the artist selection form.
//  SimpleRolesOnly    - Boolean -  if True, it indicates that
//                         only roles without addressing objects should be used for selection.
//  NoExternalRoles      - Boolean -  if True, it indicates that only roles
//                         that do not have the external Role attribute set should be used for selection.
//  StandardProcessing - Boolean -  if False, you do not need to display the standard form for selecting an artist.
//
Procedure OnPerformerChoice(PerformerItem, PerformerAttribute, SimpleRolesOnly,
	NoExternalRoles, StandardProcessing) Export
	
EndProcedure

#EndRegion
