///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("IsInternal");
	NotAttributesToEdit.Add("IBUserID");
	NotAttributesToEdit.Add("ServiceUserID");
	NotAttributesToEdit.Add("DeleteInfobaseUserProperties");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

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
	|	IsAuthorizedUser(Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// Standard subsystems.Pluggable commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - 
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleGeneration = Common.CommonModule("GenerateFrom");
		Return ModuleGeneration.AddGenerationCommand(GenerationCommands, Metadata.Catalogs.Users);
	EndIf;
	
	Return Undefined;
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Filter.Property("Invalid") Then
		Parameters.Filter.Insert("Invalid", False);
	EndIf;
	
	If Not Parameters.Filter.Property("IsInternal") Then
		Parameters.Filter.Insert("IsInternal", False);
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ChoiceForm" Or Parameters.Property("ChoiceMode") Then
		
		DefaultSelectedForm = SelectedForm;
		UsersOverridable.OnDefineUsersSelectionForm(SelectedForm, Parameters);
	    If DefaultSelectedForm <> SelectedForm Then
			StandardProcessing = False;
		EndIf;
		
	EndIf;
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 
	
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	UsersList = UsersInternal.UsersToEnablePasswordRecovery();
	
	If UsersList.Count() > 0 Then
		EnableStandardPasswordRecoverySettings();
		InfobaseUpdate.MarkForProcessing(Parameters, UsersList);
	EndIf;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UserRef = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Users");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	ErrorList = New Array;
	
	While UserRef.Next() Do
		Result = UsersInternal.UpdateEmailForPasswordRecovery(UserRef.Ref);
		
		If Result.Status = "Error" Then
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			ErrorList.Add(Result.ErrorText);
		Else
			ObjectsProcessed = ObjectsProcessed + 1;
			InfobaseUpdate.MarkProcessingCompletion(UserRef.Ref);
		EndIf;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Users");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some external user information records: %1
			|%2';"), ObjectsWithIssuesCount, StrConcat(ErrorList, Chars.LF));
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.Users,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Yet another batch of user information records is processed: %1';"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

Procedure EnableStandardPasswordRecoverySettings()
	
	Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings();
	Settings.PasswordRecoveryMethod = InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeByStandardService;
	AdditionalAuthenticationSettings.SetPasswordRecoverySettings(Settings);
	
EndProcedure

#EndRegion

#EndIf

#EndIf
