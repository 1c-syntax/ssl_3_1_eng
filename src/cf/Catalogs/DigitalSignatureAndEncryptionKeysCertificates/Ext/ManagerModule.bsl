///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
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

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowCertificatesPage");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Update handlers.

// Registers objects, 
// for which it is necessary to update register records on the InfobaseUpdate exchange plan.
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

// Update register records.
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Selection = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	If Selection.Count() > 0 Then
		ProcessNotificationStatementsAndValidityOfCertificates(Selection);
	EndIf;

	ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionKeysCertificates");
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

#EndRegion

#Region Private

Procedure ProcessNotificationStatementsAndValidityOfCertificates(Selection)
	
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
							Certificate, DigitalSignatureInternal.TimeAddition(), CertificateBinaryData);
						If CertificateObject.ValidBefore <> CertificateProperties.ValidBefore Then
							SearchString = Format(CertificateObject.ValidBefore, "DF=MM.yyyy");
							ReplacementString = Format(CertificateProperties.ValidBefore, "DF=MM.yyyy");
							CertificateObject.Description = StrReplace(CertificateObject.Description, SearchString, ReplacementString);
							CertificateObject.ValidBefore = CertificateProperties.ValidBefore;
							WriteObject = True;
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
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Не удалось обработать сертификат: %1 по причине:
					 |%2';"), RepresentationOfTheReference, ErrorProcessing.DetailErrorDescription(ErrorInfo()));

			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning, Selection.Ref.Metadata(), Selection.Ref, MessageText);

		EndTry;

	EndDo;

	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Не удалось обработать некоторые сертификаты (пропущены): %1';"),
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,
			Metadata.Catalogs.DigitalSignatureAndEncryptionKeysCertificates,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Обработана очередная порция сертификатов: %1';"), ObjectsProcessed));
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
