///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#If Not MobileStandaloneServer Then

#Region Variables

// Object value before it is written (intended for the "OnWrite" event handler).
Var IsNew;
Var IBUserProcessingParameters; // Parameters to be populated when processing a user.

#EndRegion

// Область ПрограммныйИнтерфейс.
//
// Программный интерфейс объекта реализован через ДополнительныеСвойства.
//
// ОписаниеПользователяИБ - Структура со свойствами:
//   Действие - Строка - "Записать" или "Удалить".
//      1. Если Действие = "Удалить" другие свойства не требуются. Удаление
//      будет считаться успешным и в том случае, когда пользовательИБ
//      не найден по значению реквизита ИдентификаторПользователяИБ.
//      2. Если Действие = "Записать", тогда будет создан или обновлен
//      пользователь ИБ по указанным свойствам. Чтобы пользователь не создавался,
//      когда не найден, нужно вставить в структуру свойство "ТолькоОбновитьПользователяИБ".
//
//   ВходВПрограммуРазрешен - Неопределено - вычислить автоматически:
//                            если вход в приложение запрещен, тогда остается запрещен,
//                            иначе остается разрешен, кроме случая, когда
//                            все виды аутентификации установлены в  False.
//                          - Булево - если Истина, тогда установить аутентификацию, как
//                            указана или сохранена в значениях одноименных реквизитов;
//                            если  False, тогда снять все виды аутентификации у пользователя ИБ.
//                            Если свойство не указано - прямая установка сохраняемых и
//                            действующих видов аутентификации (для поддержки обратной совместимости).
//
//   ПотребоватьСменуПароляПриВходе - Булево - изменяет одноименный флажок карточки пользователя.
//                                  - Неопределено - флажок не изменяется (аналогично,
//                                        если свойство не указано).
//
//   АутентификацияСтандартная, АутентификацияOpenID, АутентификацияOpenIDConnect,
//   АутентификацияТокеномДоступа, АутентификацияОС - установить сохраняемые значения
//      видов аутентификации и действующие значения видов аутентификации
//      в зависимости от использования свойства ВходВПрограммуРазрешен.
// 
//   Остальные свойства.
//      Состав остальных свойств указывается аналогично составу свойств параметра.
//      ОбновляемыеСвойства для процедуры Пользователи.УстановитьСвойстваПользователяИБ(),
//      кроме свойства ПолноеИмя - устанавливается по Наименованию.
//
//      Для сопоставления существующего свободного пользователя ИБ с пользователем в справочнике,
//      с которым не сопоставлен другой существующий пользователь ИБ, нужно вставить свойство.
//      УникальныйИдентификатор. Если указать идентификатор пользователя ИБ, который
//      сопоставлен с текущим пользователем, ничего не изменится.
//
//   При выполнении действий "Записать" и "Удалить" реквизит ИдентификаторПользователяИБ
//   объекта обновляется автоматически, его не следует изменять.
//
//   После выполнения действия в структуру вставляются (обновляются) следующие свойства:
//   - РезультатДействия - Строка, содержащая одно из значений:
//      - когда действие "Записать": "ДобавленПользовательИБ", "ИзмененПользовательИБ", "УдаленПользовательИБ" и
 //         если вставлено свойство "ТолькоОбновитьПользователяИБ" может быть "ПропущеноДобавлениеПользователяИБ".
//      - когда действие "Удалить": "ОчищеноСопоставлениеСНесуществующимПользователемИБ",
//          "НеТребуетсяУдалениеПользовательИБ"
//   - УникальныйИдентификатор - УникальныйИдентификатор пользователя ИБ.
//
//   ОписаниеПользователяИБ обрабатывается в режиме ОбменДанными.Загрузка = Истина.
//
// СозданиеАдминистратора - Строка - свойство должно быть вставлено с непустой строкой,
//   чтобы вызвать событие ПриСозданииАдминистратора после обработки структуры ОписаниеПользователяИБ
//   когда у созданного или измененного пользователя ИБ имеются роли администратора.
//   Это нужно, чтобы сделать связанные действия при создании администратора, например,
//   автоматически добавить пользователя в группу доступа Администраторы.
//
// КонецОбласти

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	UsersInternal.UserObjectBeforeWrite(ThisObject, IBUserProcessingParameters);
	// ACC:75-on
	
	// ACC:75-off - The DataExchange.Load check must follow the locking of registers.
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(False);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	If DataExchange.Load And IBUserProcessingParameters <> Undefined Then
		UsersInternal.EndIBUserProcessing(
			ThisObject, IBUserProcessingParameters);
	EndIf;
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("NewUserGroup")
		And ValueIsFilled(AdditionalProperties.NewUserGroup) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.UserGroups");
		LockItem.SetValue("Ref", AdditionalProperties.NewUserGroup);
		Block.Lock();
		
		GroupObject1 = AdditionalProperties.NewUserGroup.GetObject(); // CatalogObject.UserGroups
		GroupObject1.Content.Add().User = Ref;
		GroupObject1.Write();
	EndIf;
	
	// Updating the content of "All users" auto group.
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	UsersInternal.UpdateUserGroupCompositionUsage(Ref, ChangesInComposition);
	UsersInternal.UpdateAllUsersGroupComposition(Ref, ChangesInComposition);
	
	UsersInternal.EndIBUserProcessing(ThisObject,
		IBUserProcessingParameters);
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// ACC:75-off - DataExchange.Load should be checked as needed after the infobase user is handled.
	UsersInternal.UserObjectBeforeDelete(ThisObject);
	// ACC:75-on
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	AdditionalProperties.Insert("CopyingValue", CopiedObject.Ref);
	
	IBUserID = Undefined;
	ServiceUserID = Undefined;
	Prepared = False;
	
	Properties = New Structure("ContactInformation");
	FillPropertyValues(Properties, ThisObject);
	If Properties.ContactInformation <> Undefined Then
		Properties.ContactInformation.Clear();
	EndIf;
	
	Comment = "";
	
EndProcedure

#EndRegion

#EndIf

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf