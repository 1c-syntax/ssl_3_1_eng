///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If SimplifiedInterface() Then
		VariantKey = "UsersRightsToTables";
		
		Filter = New Structure;
		Filter.Insert("AccessGroup", CommandParameter);
		Filter.Insert("CanSignIn", True);
		
		ReportParameters = New Structure;
		ReportParameters.Insert("GenerateOnOpen", True);
		ReportParameters.Insert("Filter", Filter);
		ReportParameters.Insert("VariantKey", VariantKey);
		ReportParameters.Insert("PurposeUseKey", VariantKey);
		
		OpenForm("Report.AccessRightsAnalysis.Form", ReportParameters, ThisObject);
		
	Else
		FormParameters = New Structure;
		FormParameters.Insert("Profile", CommandParameter);
		OpenForm("Catalog.AccessGroups.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	EndIf;
	
EndProcedure

&AtServer
Function SimplifiedInterface()
	
	Return AccessManagementInternal.SimplifiedAccessRightsSetupInterface();
	
EndFunction

#EndRegion
