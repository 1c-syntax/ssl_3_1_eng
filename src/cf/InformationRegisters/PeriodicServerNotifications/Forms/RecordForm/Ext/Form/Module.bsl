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
	
	IBUserID = Record.IBUserID;
	
	Store = FormAttributeToValue("Record").Notifications;
	
	Items.PageNotifications.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Notifications (size, bytes: %1)';"),
		String(Base64Value(XMLString(Store)).Size()));
	
	StorageContents = Store.Get();
	Try
		Notifications = Common.ValueToXMLString(StorageContents);
	Except
		Notifications = ValueToStringInternal(StorageContents);
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion
