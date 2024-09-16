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
	
	If Parameters.FillingValues.Property("Application")
	   And ValueIsFilled(Parameters.FillingValues.Application) Then
		
		AutoTitle = False;
		Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Path to application %1 on Linux server';"),
			Parameters.FillingValues.Application);
		
		Items.Application.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// 
	// 
	RefreshReusableValues();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_PathsToDigitalSignatureAndEncryptionApplicationsOnLinuxServers",
		New Structure("Application", Record.Application), Record.SourceRecordKey);
	
EndProcedure

#EndRegion
