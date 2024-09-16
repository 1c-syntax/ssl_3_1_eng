///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a report on object versions in version comparison mode.
//
// Parameters:
//  Ref                       - AnyRef -  the reference to the versioned object;
//  SerializedObjectAddress - String -  address of the binary data
//                                          of the object version being compared in temporary storage.
//
Procedure OpenReportOnChanges(Ref, SerializedObjectAddress) Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Ref);
	Parameters.Insert("SerializedObjectAddress", SerializedObjectAddress);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", Parameters);
	
EndProcedure

// Shows the saved version of the object.
//
// Parameters:
//  Ref                       - AnyRef -  the reference to the versioned object;
//  SerializedObjectAddress - String -  address of the binary data of the object version in temporary storage.
//
Procedure OpenReportOnObjectVersion(Ref, SerializedObjectAddress) Export
	
	Parameters = New Structure;
	Parameters.Insert("Ref", Ref);
	Parameters.Insert("SerializedObjectAddress", SerializedObjectAddress);
	Parameters.Insert("ByVersion", True);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", Parameters);
	
EndProcedure

// Event handler for the message Processing event for the form where you want to display the check box for storing the change history.
//
// Parameters:
//   EventName - String -  name of the event that was received by the event handler on the form.
//   StoreChangeHistory - Number -  the props that the value will be placed in.
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Versioning objects") Then
//		Modulversion Of Objectsclient = General Purposeclient.General Module ("Versioning Of Client Objects");
//		Modulversion of client objects.Processingreferencesfurther Readinghistory (
//			Event Name, 
//			Storehistory of changes);
//	Conicelli;
//
Procedure StoreHistoryCheckBoxChangeNotificationProcessing(Val EventName, StoreChangeHistory) Export
	
	If EventName = "ChangelogStorageModeChanged" Then
		StoreChangeHistory = ObjectsVersioningInternalServerCall.StoreHistoryCheckBoxValue();
	EndIf;
	
EndProcedure

// Handler for the Change event for the checkbox that switches the change history storage mode.
// The flag must be associated with a Boolean attribute.
// 
// Parameters:
//   StoreChangesHistoryCheckBoxValue - Boolean -  the new value of the checkbox that you want to process.
// 
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Versioning objects") Then
//		Modulversion Of Objectsclient = General Purposeclient.General Module ("Versioning Of Client Objects");
//		Modulversion of client objects.When Changing The Storehistory (Storehistory Of Changes);
//	Conicelli;
//
Procedure OnStoreHistoryCheckBoxChange(StoreChangesHistoryCheckBoxValue) Export
	
	ObjectsVersioningInternalServerCall.SetChangeHistoryStorageMode(
		StoreChangesHistoryCheckBoxValue);
	
	Notify("ChangelogStorageModeChanged");
	
EndProcedure

// Opens the object versioning control form.
// Don't forget to set the command that executes the procedure call 
// to depend on the use object Versioning function option.
//
// Example:
//	If The General Purpose Is A Client.Subsystems Exist ("Standard Subsystems.Versioning objects") Then
//		Modulversion Of Objectsclient = General Purposeclient.General Module ("Versioning Of Client Objects");
//		Modulversion of client objects.Parasitisation();
//	Conicelli;
//
Procedure ShowSetting() Export
	
	OpenForm("InformationRegister.ObjectVersioningSettings.ListForm");
	
EndProcedure

#EndRegion

#Region Internal

// Opens the report about the version or compare versions.
//
// Parameters:
//  Ref - AnyRef -  object reference;
//  VersionsToCompare - Array -  collection of compared versions. If there is only one version, the version report opens.
//
Procedure OpenVersionComparisonReport(Ref, VersionsToCompare) Export
	
	ReportParameters = New Structure;
	ReportParameters.Insert("Ref", Ref);
	ReportParameters.Insert("VersionsToCompare", VersionsToCompare);
	OpenForm("InformationRegister.ObjectsVersions.Form.ObjectVersionsReport", ReportParameters);
	
EndProcedure

// Opens the list of object versions.
//
// Parameters:
//  Ref        - AnyRef -  versioned object;
//  OwnerForm - ClientApplicationForm -  the form that opens the change history.
//
Procedure ShowChangeHistory(Ref, OwnerForm) Export
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Ref", Ref);
	OpeningParameters.Insert("ReadOnly", OwnerForm.ReadOnly);
	
	OpenForm("InformationRegister.ObjectsVersions.Form.SelectStoredVersions", OpeningParameters, OwnerForm, Ref);
	
EndProcedure

#EndRegion
