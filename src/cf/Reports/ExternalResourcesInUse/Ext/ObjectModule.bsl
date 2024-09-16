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

// To set up a report form.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.GenerateImmediately = True;
	Settings.OutputSelectedCellsTotal = False;
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ResultDocument.Clear();
	
	BeginTransaction(); // 
	Try
		SetPrivilegedMode(True);
		
		Constants.UseSecurityProfiles.Set(True);
		Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Set(True);
		
		DataProcessors.ExternalResourcesPermissionsSetup.ClearPermissions();
		PermissionsRequests = SafeModeManagerInternal.RequestsToUpdateApplicationPermissions();
		Manager = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionsApplicationManager(PermissionsRequests);
		
		SetPrivilegedMode(False);
		
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;	
	
	ResultDocument.Put(Manager.Presentation(True));
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf