﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsSubordinateDIBNode = Common.IsSubordinateDIBNode();
	HasRightsToAddApp = AccessRight("Insert", Metadata.Catalogs.DigitalSignatureAndEncryptionApplications);
	
	If ValueIsFilled(Parameters.Application) Then
		FillPropertyValues(ThisObject, Parameters.Application);
		
		Title = Parameters.Application.Presentation;
		
		ApplicationPath = Parameters.Application.PathToAppAuto;
		Items.ApplicationPath.Visible = ValueIsFilled(ApplicationPath);
		
		PathToAppAtServer = Parameters.Application.PathToAppAuto;
		Items.PathToAppAtServer.Visible = ValueIsFilled(PathToAppAtServer);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)

	AddToCatalog(PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.SetupDone"));

EndProcedure

&AtClient
Procedure Disable(Command)

	AddToCatalog(PredefinedValue(
		"Enum.DigitalSignatureAppUsageModes.NotUsed"));

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AddToCatalog(UsageMode)
	
	If Not HasRightsToAddApp Then
		ShowMessageBox( , NStr("en = 'To configure the app, contact the administrator.';"));
	ElsIf IsSubordinateDIBNode Then
		ShowMessageBox( , NStr("en = 'To configure the app, you should add a new item to the catalog in the master node.';"));
	Else
		FormParameters = New Structure("Application, UsageMode", Parameters.Application, UsageMode);
		OpenForm("Catalog.DigitalSignatureAndEncryptionApplications.ObjectForm", FormParameters,,,,,,
			FormWindowOpeningMode.Independent);
		Close();
	EndIf;
	
EndProcedure

#EndRegion