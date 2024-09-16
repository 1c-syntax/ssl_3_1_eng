///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	ValueList = New ValueList;
	ValueList.Add(Enums.CryptographySignatureTypes.BasicCAdESBES);
	ValueList.Add(Enums.CryptographySignatureTypes.WithTimeCAdEST);
	ValueList.Add(Enums.CryptographySignatureTypes.ArchivalCAdESAv3);
	
	ChoiceData = ValueList;
	
EndProcedure

#EndRegion

#EndIf