///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.BankOperationsDiscontinuedPages.Visible = Object.OutOfBusiness Or Users.IsFullUser();
	Items.BankOperationsDiscontinuedPages.CurrentPage = ?(Users.IsFullUser(),
		Items.BankOperationsDiscontinuedCheckBoxPage, Items.BankOperationsDiscontinuedLabelPage);
		
	If Object.OutOfBusiness Then
		WindowOptionsKey = "OutOfBusiness";
		Items.BankOperationsDiscontinuedLabel.Title = BankManager.InvalidBankNote(Object.Ref);
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.HeaderGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.DomesticPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.InternationalPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.ObjectOnReadAtServer(CurrentObject, ReadOnly);
		
	EndIf;
	
EndProcedure

#EndRegion
