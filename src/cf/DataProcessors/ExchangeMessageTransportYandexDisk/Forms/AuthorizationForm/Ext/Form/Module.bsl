///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not Parameters.Property("ClientID") Then
		
		Raise NStr("en = 'Эта форма не предназначена для непосредственного открытия.'",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	HTMLField = "https://oauth.yandex.ru/authorize?response_type=code&client_id=" + Parameters.ClientID;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HTMLFieldDocumentComplete(Item)
	
	Position = StrFind(Item.Document.URL, "code=");
	If Position Then 
		
		Code = Mid(Item.Document.URL, Position + 5);
		
		Close(Code);
		
	EndIf;
	
EndProcedure

#EndRegion