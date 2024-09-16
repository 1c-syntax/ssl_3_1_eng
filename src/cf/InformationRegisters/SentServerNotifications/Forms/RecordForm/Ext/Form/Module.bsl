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
	
	ReadOnly = True;
	
	Store = FormAttributeToValue("Record").NotificationContent;
	Items.PageContent.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Content (size, bytes: %1)';"),
		String(Base64Value(XMLString(Store)).Size()));
	
	StorageContents = Store.Get();
	Try
		NotificationContent = Common.ValueToXMLString(StorageContents);
	Except
		NotificationContent = ValueToStringInternal(StorageContents);
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion
