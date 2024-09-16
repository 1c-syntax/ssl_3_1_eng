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
	
	InfobasePublicationURL = Common.InfobasePublicationURL();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InfobasePublicationURLOnChange(Item)
	
	GenerateRefAddress();

EndProcedure

&AtClient
Procedure ObjectReferenceOnChange(Item)
	
	GenerateRefAddress();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Insert(Command)
	
	ClearMessages();
	
	Cancel = False;
	
	If IsBlankString(InfobasePublicationURL) Then
		
		MessageText = NStr("en = 'Infobase publication URL not specified.';");
		CommonClient.MessageToUser(MessageText,, "InfobasePublicationURL",, Cancel);
		
	EndIf;
	
	If IsBlankString(ObjectReference) Then
		
		MessageText = NStr("en = 'In-app link to the object is not specified.';");
		CommonClient.MessageToUser(MessageText,, "ObjectReference",, Cancel);
		
	EndIf;
	
	If Not Cancel Then
		NotifyChoice(GeneratedRef);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GenerateRefAddress()

	GeneratedRef = InfobasePublicationURL + "#"+ ObjectReference;

EndProcedure

#EndRegion
