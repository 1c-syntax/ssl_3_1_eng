///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function NonWorkDaysPeriods(BusinessCalendar) Export
	
	Query = New Query;
	Query.SetParameter("BusinessCalendar", BusinessCalendar);
	Query.Text = 
		"SELECT
		|	CalendarNonWorkDaysPeriods.BusinessCalendar AS BusinessCalendar,
		|	CalendarNonWorkDaysPeriods.PeriodNumber AS PeriodNumber,
		|	CalendarNonWorkDaysPeriods.StartDate AS StartDate,
		|	CalendarNonWorkDaysPeriods.EndDate AS EndDate,
		|	CalendarNonWorkDaysPeriods.Basis AS Basis
		|FROM
		|	InformationRegister.CalendarNonWorkDaysPeriods AS CalendarNonWorkDaysPeriods
		|WHERE
		|	CalendarNonWorkDaysPeriods.BusinessCalendar = &BusinessCalendar
		|
		|ORDER BY
		|	PeriodNumber";
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndIf	