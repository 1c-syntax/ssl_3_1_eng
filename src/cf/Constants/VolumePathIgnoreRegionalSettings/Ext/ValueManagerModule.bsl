﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers
		
Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	PreviousValue = 	Constants.VolumePathIgnoreRegionalSettings.Get();
	
	If PreviousValue <> Value 
			And FilesOperationsInVolumesInternal.HasFileStorageVolumes() Then
		
		Common.MessageToUser(
			NStr("en = 'Changing a method of the volume path generation is restricted. There are files in volumes.';"),
			,,,Cancel);
	EndIf;
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf