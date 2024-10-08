﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function DefineFormType(FormName) Export
	
	Return NationalLanguageSupportServer.DefineFormType(FormName);
	
EndFunction

Function ConfigurationUsesOnlyOneLanguage(PresentationsInTabularSection) Export
	
	If Metadata.Languages.Count() = 1 Then
		Return True;
	EndIf;
	
	If PresentationsInTabularSection Then
		Return False;
	EndIf;
	
	If NationalLanguageSupportServer.FirstAdditionalLanguageUsed()
		Or NationalLanguageSupportServer.SecondAdditionalLanguageUsed() Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function ObjectContainsPMRepresentations(ReferenceOrFullMetadataName, AttributeName = "") Export
	
	If TypeOf(ReferenceOrFullMetadataName) = Type("String") Then
		MetadataObject = Common.MetadataObjectByFullName(ReferenceOrFullMetadataName);
		FullName = ReferenceOrFullMetadataName;
	Else
		MetadataObject = ReferenceOrFullMetadataName.Metadata();
		FullName = MetadataObject.FullName();
	EndIf;
	
	HaveTabularPart = False;
	If StrStartsWith(FullName, "Catalog")
		Or StrStartsWith(FullName, "Document")
		Or StrStartsWith(FullName, "ChartOfCharacteristicTypes")
		Or StrStartsWith(FullName, "Task")
		Or StrStartsWith(FullName, "BusinessProcess")
		Or StrStartsWith(FullName, "DataProcessor")
		Or StrStartsWith(FullName, "ChartOfCalculationTypes")
		Or StrStartsWith(FullName, "Report")
		Or StrStartsWith(FullName, "ChartOfAccounts")
		Or StrStartsWith(FullName, "ExchangePlan") Then
		
			HaveTabularPart = MetadataObject.TabularSections.Find("Presentations") <> Undefined;
			If HaveTabularPart And ValueIsFilled(AttributeName) Then
				HaveTabularPart = MetadataObject.TabularSections.Presentations.Attributes.Find(AttributeName) <> Undefined;
			EndIf;
		
	EndIf;
	
	Return HaveTabularPart;
	
EndFunction


Function LanguagesInformationRecords() Export
	
	Result = New Structure;
	
	Result.Insert("Language0", Common.DefaultLanguageCode());
	Result.Insert("Language1", NationalLanguageSupportServer.FirstAdditionalInfobaseLanguageCode());
	Result.Insert("Language2",  NationalLanguageSupportServer.SecondAdditionalInfobaseLanguageCode());
	Result.Insert("AdditionalLanguagesCount", 2);
	Result.Insert("DefaultLanguage", Common.DefaultLanguageCode());
	
	Return New FixedStructure(Result);
	
EndFunction

Function LanguageSuffix(Language) Export
	
	If StrCompare(Language, Constants.AdditionalLanguage1.Get()) = 0 And IsAdditionalLangUsed("Language1") Then
		Return "Language1";
	EndIf;
	
	If StrCompare(Language, Constants.AdditionalLanguage2.Get()) = 0 And IsAdditionalLangUsed("Language2") Then
		Return "Language2";
	EndIf;
	
	Return "";
	
EndFunction

Function IsAdditionalLangUsed(LanguageSuffix) Export
	
	ConstantName = ?(LanguageSuffix <> "Language1",
		StrReplace("UseAdditionalLanguage1", "Language1", LanguageSuffix),
		"UseAdditionalLanguage1");
	
	Return Constants[ConstantName].Get() = True;
	
EndFunction

Function MultilingualObjectAttributes(ObjectOrRef) Export
	
	ObjectType = TypeOf(ObjectOrRef);
	
	If ObjectType = Type("String") Then
		ObjectMetadata = Common.MetadataObjectByFullName(ObjectOrRef);
	ElsIf Common.IsReference(ObjectType) Then
		ObjectMetadata = ObjectOrRef.Metadata();
	Else
		ObjectMetadata = ObjectOrRef;
	EndIf;
	
	Return NationalLanguageSupportServer.DescriptionsOfObjectAttributesToLocalize(ObjectMetadata);
	
EndFunction

Function ThereareMultilingualDetailsintheHeaderoftheObject(MetadataObjectFullName) Export
	
	QueryText = "SELECT TOP 0
		|	*
		|FROM
		|	&MetadataObjectFullName AS SourceData";
	
	QueryText = StrReplace(QueryText, "&MetadataObjectFullName", MetadataObjectFullName);
	Query = New Query(QueryText);
	
	QueryResult = Query.Execute();
	
	For Each Column In QueryResult.Columns Do
		If (StrEndsWith(Column.Name, NationalLanguageSupportServer.FirstLanguageSuffix())
		 Or StrEndsWith(Column.Name, NationalLanguageSupportServer.SecondLanguageSuffix()))
		   And Not StrStartsWith(Column.Name, "Delete")Then
				Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// 
// 
// Parameters:
//  FullMetadataObjectName - String
// 
// Returns:
//  FixedArray of String
//
Function TabularSectionMultilingualAttributes(FullMetadataObjectName) Export
	
	MetadataObject = Metadata.FindByFullName(FullMetadataObjectName);
	
	Result = New Array;
	For Each Attribute In MetadataObject.TabularSections.Presentations.Attributes Do
		If StrCompare(Attribute.Name, "LanguageCode") = 0 Or StrStartsWith(Attribute.Name, "Delete") Then
			Continue;
		EndIf;
		Result.Add(Attribute.Name);
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

#EndRegion

