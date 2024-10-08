﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load
		Or AdditionalProperties.Property("DataDeletion")
		Or AdditionalProperties.Property("FileConversion")
		Or AdditionalProperties.Property("FilePlacementInVolumes") Then
		
		Return;
	EndIf;
	
	DetailsOfOwner = Common.ObjectAttributesValues(Owner, "CurrentVersion, DeletionMark");
	
	If IsNew() Then
		ParentVersion = DetailsOfOwner.CurrentVersion;
	EndIf;
	
	// 
	PictureIndex = FilesOperationsInternalClientServer.IndexOfFileIcon(Extension);
	
	If TextExtractionStatus.IsEmpty() Then
		TextExtractionStatus = Enums.FileTextExtractionStatuses.NotExtracted;
	EndIf;
	
	If DetailsOfOwner.CurrentVersion = Ref Then
		If DeletionMark = True And DetailsOfOwner.DeletionMark <> True Then
			Raise NStr("en = 'Cannot delete the active version.';");
		EndIf;
	ElsIf ParentVersion.IsEmpty() Then
		If DeletionMark = True And DetailsOfOwner.DeletionMark <> True Then
			Raise NStr("en = 'Cannot delete the first version.';");
		EndIf;
	ElsIf DeletionMark = True And DetailsOfOwner.DeletionMark <> True Then
		//  
		// 
		Query = New Query;
		Query.Text = 
			"SELECT
			|	FilesVersions.Ref AS Ref
			|FROM
			|	&DirectoryNameFileVersions AS FilesVersions
			|WHERE
			|	FilesVersions.ParentVersion = &ParentVersion";
		
		DirectoryNameFileVersions = "Catalog." + Metadata.FindByType(TypeOf(Ref)).Name;
		Query.Text = StrReplace(Query.Text, "&DirectoryNameFileVersions", DirectoryNameFileVersions);
		Query.SetParameter("ParentVersion", Ref);
		
		Result = Query.Execute();
		BeginTransaction();
		Try
			If Not Result.IsEmpty() Then
				Selection = Result.Select();
				Selection.Next();
				
				DataLock = New DataLock;
				DataLockItem = DataLock.Add(Metadata.FindByType(TypeOf(Selection.Ref)).FullName());
				DataLockItem.SetValue("Ref", Selection.Ref);
				DataLock.Lock();
				
				Object = Selection.Ref.GetObject();
				
				LockDataForEdit(Object.Ref);
				Object.ParentVersion = ParentVersion;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf