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
	
	If ValueIsFilled(Parameters.DataAddress) Then
		If Parameters.AreLowPriorityHandlers Then
			Data = GetFromTempStorage(Parameters.DataAddress);
			LowPriorityHandlers.Load(Data);
			Items.TablesPages.CurrentPage = Items.PageLowPriorityHandlers;
			Title = NStr("en = 'Handlers with low priority';");
		Else
			Data = GetFromTempStorage(Parameters.DataAddress);
			Intersections.Load(Data);
			Items.TablesPages.CurrentPage = Items.IntersectionsPage;
			Title = NStr("en = 'Handler intersection objects';");
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion