///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// For internal use.
// 
Procedure SaveCertificateForDistributionRecipient(BulkEmailRecipient, CertificateToEncrypt) Export
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock();
		LockItem = Block.Add("InformationRegister.CertificatesOfReportDistributionRecipients");
		LockItem.SetValue("BulkEmailRecipient", BulkEmailRecipient);
		Block.Lock();
		
		RecordManager = CreateRecordManager();
		RecordManager.BulkEmailRecipient= BulkEmailRecipient;
		RecordManager.Read();
		
		RecordManager.BulkEmailRecipient = BulkEmailRecipient;
		RecordManager.CertificateToEncrypt = CertificateToEncrypt;

		RecordManager.Write(True);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
EndProcedure

#EndRegion

#EndIf
