///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandsEventHandlers

&AtClient
Procedure Font_Arial(Command)
	
	Close("Arial");
	
EndProcedure

&AtClient
Procedure Font_Verdana(Command)
	
	Close("Verdana");
	
EndProcedure

&AtClient
Procedure Font_TimesNewRoman(Command)
	
	Close("Times New Roman");
	
EndProcedure

&AtClient
Procedure Other(Command)
	
	Close(-1);
	
EndProcedure

&AtClient
Procedure DefaultFont(Command)
	
	NewShreadsheet = New SpreadsheetDocument;
	Font = NewShreadsheet.Area(1,1,1,1).Font; 
	Close(Font.Name);
	
EndProcedure

#EndRegion
