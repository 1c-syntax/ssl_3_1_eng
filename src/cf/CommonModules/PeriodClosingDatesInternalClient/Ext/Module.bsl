///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

Procedure OpenPeriodEndClosingDates(OwnerForm) Export
	
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates",, OwnerForm);
	
EndProcedure	

Procedure OpenDataImportRestrictionDates(OwnerForm) Export
	
	FormParameters = New Structure("DataImportRestrictionDates", True);
	OpenForm("InformationRegister.PeriodClosingDates.Form.PeriodClosingDates", FormParameters, OwnerForm);
	
EndProcedure	

#EndRegion
