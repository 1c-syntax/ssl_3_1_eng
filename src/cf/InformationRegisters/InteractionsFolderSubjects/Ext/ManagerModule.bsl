///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(Interaction)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Creates an empty structure for writing information to the register of the subject of the interaction Folder.
//
// Returns:
//  Structure:
//   * SubjectOf - AnyRef
//   * Folder - CatalogRef.EmailMessageFolders
//   * Reviewed - Boolean
//   * ReviewAfter - Date
//   * CalculateReviewedItems - Boolean
//
Function InteractionAttributes() Export

	Result = New Structure;
	Result.Insert("SubjectOf"                , Undefined);
	Result.Insert("Folder"                  , Undefined);
	Result.Insert("Reviewed"            , Undefined);
	Result.Insert("ReviewAfter"       , Undefined);
	Result.Insert("CalculateReviewedItems", True);
	
	Return Result;
	
EndFunction

// Sets the folder, subject, and review details for interactions.
//
// Parameters:
//  Interaction - DocumentRef.IncomingEmail
//                 - DocumentRef.OutgoingEmail
//                 - DocumentRef.Meeting
//                 - DocumentRef.PlannedInteraction
//                 - DocumentRef.PhoneCall - 
//  Attributes    - See InformationRegisters.InteractionsFolderSubjects.InteractionAttributes.
//  RecordSet - InformationRegisterRecordSet.InteractionsFolderSubjects -  a set of register entries, if it was already created
//                 when the procedure was called.
//
Procedure WriteInteractionFolderSubjects(Interaction, Attributes, RecordSet = Undefined) Export
	
	Folder                   = Attributes.Folder;
	SubjectOf                 = Attributes.SubjectOf;
	Reviewed             = Attributes.Reviewed;
	ReviewAfter        = Attributes.ReviewAfter;
	CalculateReviewedItems = Attributes.CalculateReviewedItems;
	
	CreateAndWrite = (RecordSet = Undefined);
	
	If Folder = Undefined And SubjectOf = Undefined And Reviewed = Undefined
		And ReviewAfter = Undefined Then
		Return;
	EndIf;
		
	BeginTransaction();
	Try
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.InteractionsFolderSubjects");
		LockItem.SetValue("Interaction", Interaction);
		Block.Lock();
		
		If Folder = Undefined Or SubjectOf = Undefined Or Reviewed = Undefined 
			Or ReviewAfter = Undefined Then
			
			Query = New Query;
			Query.Text = "
			|SELECT
			|	InteractionsFolderSubjects.SubjectOf,
			|	InteractionsFolderSubjects.EmailMessageFolder,
			|	InteractionsFolderSubjects.Reviewed,
			|	InteractionsFolderSubjects.ReviewAfter
			|FROM
			|	InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
			|WHERE
			|	InteractionsFolderSubjects.Interaction = &Interaction";
			
			Query.SetParameter("Interaction", Interaction);
			
			Result = Query.Execute();
			If Not Result.IsEmpty() Then
				
				Selection = Result.Select();
				Selection.Next();
				
				If Folder = Undefined Then
					Folder = Selection.EmailMessageFolder;
				EndIf;
				
				If SubjectOf = Undefined Then
					SubjectOf = Selection.SubjectOf;
				EndIf;
				
				If Reviewed = Undefined Then
					Reviewed = Selection.Reviewed;
				EndIf;
				
				If ReviewAfter = Undefined Then
					ReviewAfter = Selection.ReviewAfter;
				EndIf;
				
			EndIf;
		EndIf;
		
		If CreateAndWrite Then
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Interaction.Set(Interaction);
		EndIf;
		Record = RecordSet.Add();
		Record.Interaction          = Interaction;
		Record.SubjectOf                 = SubjectOf;
		Record.EmailMessageFolder = Folder;
		Record.Reviewed             = Reviewed;
		Record.ReviewAfter        = ReviewAfter;
		RecordSet.AdditionalProperties.Insert("CalculateReviewedItems", CalculateReviewedItems);
		
		If CreateAndWrite Then
			RecordSet.Write();
		EndIf;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// 
// 
// Parameters:
//  Block - DataLock -  lock to be set
//  Interactions - Array
//                 - DocumentRef.PlannedInteraction
//                 - DocumentRef.Meeting
//                 - DocumentRef.PhoneCall
//                 - DocumentRef.SMSMessage
//                 - DocumentRef.IncomingEmail
//                 - DocumentRef.OutgoingEmail - 
//
Procedure BlockInteractionFoldersSubjects(Block, Interactions) Export
	
	LockItem = Block.Add("InformationRegister.InteractionsFolderSubjects"); 
	If TypeOf(Interactions) = Type("Array") Then
		For Each InteractionHyperlink In Interactions Do
			LockItem.SetValue("Interaction", InteractionHyperlink);
		EndDo	
	Else
		LockItem.SetValue("Interaction", Interactions);
	EndIf;	
	
EndProcedure

// Blocks the PC subject of the interaction Folder.
// 
// Parameters:
//  Block       - DataLock -  lock to be set.
//  DataSource   - ValueTable -  the data source for the lock.
//  NameSourceField - String -  name of the source field that will be used to set the interaction lock.
//
Procedure BlochFoldersSubjects(Block, DataSource, NameSourceField) Export
	
	LockItem = Block.Add("InformationRegister.InteractionsFolderSubjects"); 
	LockItem.DataSource = DataSource;
	LockItem.UseFromDataSource("Interaction", NameSourceField);
	
EndProcedure

#EndRegion

#EndIf
