///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

//@skip-check data-exchange-load
Procedure BeforeWrite(Cancel, Replacing)
	
	RecordsCount = Count();
	
	For Cnt = 1 To RecordsCount Do
		
		IndexOf = RecordsCount - Cnt;
		
		If Not ValueIsFilled(ThisObject[IndexOf].Ref) Then
			Delete(IndexOf);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf


