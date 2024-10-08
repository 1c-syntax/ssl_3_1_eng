﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Count() = 1 Then
		Folder = Get(0).Folder;
		Path = Get(0).Path;
		
		If IsBlankString(Path) Then
			Return;
		EndIf;						
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	FilesFolders.Ref,
			|	FilesFolders.Description
			|FROM
			|	Catalog.FilesFolders AS FilesFolders
			|WHERE
			|	FilesFolders.Parent = &Ref";
		
		Query.SetParameter("Ref", Folder);
		
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			
			WorkingDirectory = Path;
			//  
			//  
			WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
			
			WorkingDirectory = WorkingDirectory + Selection.Description;
			WorkingDirectory = CommonClientServer.AddLastPathSeparator(WorkingDirectory);
			
			FilesOperationsInternal.SaveFolderWorkingDirectory(
				Selection.Ref, WorkingDirectory);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf