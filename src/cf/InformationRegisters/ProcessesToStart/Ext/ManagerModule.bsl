///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Adds information about the successful start of the process.
//
// Parameters:
//   - 
//
Procedure RegisterProcessStart(Process_) Export
	
	Record = CreateRecordManager();
	Record.Owner = Process_;
	Record.Read();
	
	If Not Record.Selected() Then
		Return;
	EndIf;
	
	Record.Delete();
	
EndProcedure

// Adds information about canceling the start of the process.
//
// Parameters:
//   - 
//
Procedure RegisterStartCancellation(Process_, CancellationReason) Export
	
	Record = CreateRecordManager();
	Record.Owner = Process_;
	Record.Read();
	
	If Not Record.Selected() Then
		Return;
	EndIf;
	
	Record.State = Enums.ProcessesStatesForStart.StartCanceled;
	Record.StartCancelReason = CancellationReason;
	
	Record.Write();
	
EndProcedure

#EndRegion

#EndIf