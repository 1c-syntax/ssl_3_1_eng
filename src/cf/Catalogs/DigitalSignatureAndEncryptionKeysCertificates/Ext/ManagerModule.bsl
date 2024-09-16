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

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("IssuedTo");
	NotAttributesToEdit.Add("Firm");
	NotAttributesToEdit.Add("LastName");
	NotAttributesToEdit.Add("Name");
	NotAttributesToEdit.Add("MiddleName");
	NotAttributesToEdit.Add("JobTitle");
	NotAttributesToEdit.Add("IssuedBy");
	NotAttributesToEdit.Add("ValidBefore");
	NotAttributesToEdit.Add("Signing");
	NotAttributesToEdit.Add("Encryption");
	NotAttributesToEdit.Add("Thumbprint");
	NotAttributesToEdit.Add("CertificateData");
	NotAttributesToEdit.Add("Application");
	NotAttributesToEdit.Add("Revoked");
	NotAttributesToEdit.Add("EnterPasswordInDigitalSignatureApplication");
	NotAttributesToEdit.Add("Organization");
	NotAttributesToEdit.Add("User");
	NotAttributesToEdit.Add("Added");
	
	If Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
		ProcessingApplicationForNewQualifiedCertificateIssue.AttributesToSkipInBatchProcessing(
			NotAttributesToEdit);
	EndIf;
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Defines a list of report commands.
//
// Parameters:
//  ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//  Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	If Not AccessRight("View", Metadata.Reports.DigitalSignatureCertificates) Then
		Return;
	EndIf;
	
	If Parameters.FormName = "CommonForm.DigitalSignatureAndEncryptionSettings" Then
		Command = ReportsCommands.Add();
		Command.VariantKey      = "DigitalSignatureCertificates";
		Command.Presentation     = NStr("en = 'Digital signature certificates';");
		Command.Id     = "DigitalSignatureCertificates";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "ExpiringSoon";
		Command.Presentation     = NStr("en = 'Expiring certificates';");
		Command.Id     = "ExpiringSoon";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "EmployeesCertificates";
		Command.Presentation     = NStr("en = 'Employees'' certificates';");
		Command.Id     = "EmployeesCertificates";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "IndividualCertificateIssuanceRequired";
		Command.Presentation     = NStr("en = 'Individual''s certificate issuance required';");
		Command.Id     = "IndividualCertificateIssuanceRequired";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
		
		Command = ReportsCommands.Add();
		Command.VariantKey      = "MRLOARequired";
		Command.Presentation     = NStr("en = 'Certificates that require MR LOA';");
		Command.Id     = "MRLOARequired";
		Command.Manager          = "Report.DigitalSignatureCertificates";
		Command.IsNonContextual     = True;
	EndIf;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowPage", "Certificates");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// Registers objects
// that need to be updated in the register on the exchange plan for updating the information Database.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref,
	|	COUNT(ElectronicSignatureAndEncryptionKeyCertificatesUsers.User) AS User
	|INTO OneUserInTableSection
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates.Users AS
	|		ElectronicSignatureAndEncryptionKeyCertificatesUsers
	|GROUP BY
	|	ElectronicSignatureAndEncryptionKeyCertificatesUsers.Ref
	|HAVING
	|	COUNT(ElectronicSignatureAndEncryptionKeyCertificatesUsers.User) = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DigitalSignatureAndEncryptionKeysCertificates.Ref AS Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionKeysCertificates AS DigitalSignatureAndEncryptionKeysCertificates
	|		LEFT JOIN OneUserInTableSection AS OneUserInTableSection
	|		ON DigitalSignatureAndEncryptionKeysCertificates.Ref = OneUserInTableSection.Ref
	|WHERE
	|	DigitalSignatureAndEncryptionKeysCertificates.DeleteUserNotifiedOfExpirationDate
	|	OR &StatementCondition
	|	OR DigitalSignatureAndEncryptionKeysCertificates.ValidBefore > &CurrentDate
	|	OR NOT OneUserInTableSection.Ref IS NULL";

	
	If DigitalSignature.CommonSettings().CertificateIssueRequestAvailable Then
		
		ModuleApplicationForIssuingANewQualifiedCertificate = Common.CommonModule(
			"DataProcessors.ApplicationForNewQualifiedCertificateIssue");
		Query.Text = StrReplace(Query.Text, "&StatementCondition",
			"DigitalSignatureAndEncryptionKeysCertificates.DeleteStatementStatement <> &EmptyRef");
		Query.SetParameter("EmptyRef", 
			ModuleApplicationForIssuingANewQualifiedCertificate.StatementStatusEmptyRef());
		
	Else
		Query.Text = StrReplace(Query.Text, "OR &StatementCondition", "");
	EndIf;
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());

	ReferencesArrray = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkForProcessing(Parameters, ReferencesArrray);
	
EndProcedure

// 
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	If Selection.Count() > 0 Then
		ProcessCertificatesRequestsNotificationsAndValidityPeriods(Selection);
	EndIf;

	ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#Region Private

Procedure ProcessCertificatesRequestsNotificationsAndValidityPeriods(Selection)
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;

	CertificateIssueRequestAvailable = DigitalSignature.CommonSettings().CertificateIssueRequestAvailable;
	
	If CertificateIssueRequestAvailable Then
		ProcessingApplicationForNewQualifiedCertificateIssue =
			Common.ObjectManagerByFullName(
				"DataProcessor.ApplicationForNewQualifiedCertificateIssue");
	EndIf;
	
	While Selection.Next() Do

		RepresentationOfTheReference = String(Selection.Ref);

		BeginTransaction();
		Try

			Block = New DataLock;
			LockItem = Block.Add("Catalog.DigitalSignatureAndEncryptionKeysCertificates");
			LockItem.SetValue("Ref", Selection.Ref);
			LockItem.Mode = DataLockMode.Shared;
			Block.Lock();
			
			WriteObject = False;

			CertificateObject = Selection.Ref.GetObject(); // CatalogObject.DigitalSignatureAndEncryptionKeysCertificates
			
			// 
			If CertificateObject.DeleteUserNotifiedOfExpirationDate Then
				AlertRecordset = InformationRegisters.CertificateUsersNotifications.CreateRecordSet();
				AlertRecordset.Filter.Certificate.Set(Selection.Ref);

				If CertificateObject.Users.Count() > 0 Then
					
					UsersTable = CertificateObject.Users.Unload();
					UsersTable.GroupBy("User");
					
					For Each UserString In UsersTable Do
						WriteAlertSet = AlertRecordset.Add();
						WriteAlertSet.Certificate = Selection.Ref;
						WriteAlertSet.User = UserString.User;
						WriteAlertSet.IsNotified = True;
					EndDo;
					
				ElsIf ValueIsFilled(CertificateObject.User) Then
					WriteAlertSet = AlertRecordset.Add();
					WriteAlertSet.Certificate = Selection.Ref;
					WriteAlertSet.User = CertificateObject.User;
					WriteAlertSet.IsNotified = True;
				EndIf;
				If AlertRecordset.Count() > 0 Then
					InfobaseUpdate.WriteRecordSet(AlertRecordset, True);
				EndIf;
				CertificateObject.DeleteUserNotifiedOfExpirationDate = False;
				WriteObject = True;
			EndIf;
			
			// 
			If CertificateIssueRequestAvailable
			   And ValueIsFilled(CertificateObject.DeleteStatementStatement) Then
				
				ProcessingApplicationForNewQualifiedCertificateIssue.ProcessDataForMigrationToNewVersion(
					CertificateObject, WriteObject);

			EndIf;
			
			If CertificateObject.Users.Count() = 1 Then
				CertificateObject.User = CertificateObject.Users[0].User;
				CertificateObject.Users.Clear();
				WriteObject = True;
			EndIf;
			
			If CertificateObject.ValidBefore > CurrentSessionDate() Then
				CertificateBinaryData = CertificateObject.CertificateData.Get();
				If TypeOf(CertificateBinaryData) = Type("BinaryData") Then
					Try
						Certificate = New CryptoCertificate(CertificateBinaryData);
					Except
						Certificate = Undefined;
					EndTry;

					If Certificate <> Undefined Then
						CertificateProperties = DigitalSignatureInternalClientServer.CertificateProperties(
							Certificate, DigitalSignatureInternal.UTCOffset(),
							CertificateBinaryData);
						If CertificateObject.ValidBefore <> CertificateProperties.ValidBefore Then
							SearchString = Format(CertificateObject.ValidBefore, "DF=MM.yyyy");
							ReplacementString = Format(CertificateProperties.ValidBefore, "DF=MM.yyyy");
							CertificateObject.Description = StrReplace(CertificateObject.Description, SearchString,
								ReplacementString);
							CertificateObject.ValidBefore = CertificateProperties.ValidBefore;
							WriteObject = True;
						EndIf;

						If ValueIsFilled(CertificateObject.Application) And TypeOf(CertificateObject.Application) = Type(
							"CatalogRef.DigitalSignatureAndEncryptionApplications") Then

							CertificateAlgorithm = DigitalSignatureInternalClientServer.CertificateSignAlgorithm(
								CertificateBinaryData, False, True);
							If DigitalSignatureInternalClientServer.IsGOSTCertificate(CertificateAlgorithm) Then

								ApplicationDetails = Common.ObjectAttributesValues(
									CertificateObject.Application,
									"IsBuiltInCryptoProvider, SignAlgorithm, HashAlgorithm");

								If Not ApplicationDetails.IsBuiltInCryptoProvider Then

									Result = DigitalSignatureInternalClientServer.SignAlgorithmCorrespondsToCertificate(
										"", CertificateAlgorithm, ApplicationDetails.SignAlgorithm, ApplicationDetails.HashAlgorithm);

									If Result <> True Then

										CertificateObject.Application = Catalogs.DigitalSignatureAndEncryptionApplications.EmptyRef();
										WriteObject = True;

									EndIf;
								EndIf;

							EndIf;
						EndIf;

					EndIf;
				EndIf;
			EndIf;

			If WriteObject Then
				InfobaseUpdate.WriteObject(CertificateObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;

			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();

		Except

			RollbackTransaction();
			// 
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			
			InfobaseUpdate.WriteErrorToEventLog(
				Selection.Ref,
				RepresentationOfTheReference,
				ErrorInfo());
		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t process (skipped) some certificates: %1';"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Another batch of certificates is processed: %1';"), ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
