///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the prefix of the subscription source according to the company's prefix. 
// The subscription source must contain
// the required details of the "Company" header, with the "reference Link" type.Companies".
//
// Parameters:
//  Source - Arbitrary -  source of the subscription event.
//             Any object from the set [Reference, Document, plan of types of characteristics, Business process, Task].
//  StandardProcessing - Boolean -  flag for standard subscription processing.
//  Prefix - String -  the prefix of the object you want to modify.
//
Procedure SetCompanyPrefix(Source, StandardProcessing, Prefix) Export
	
	SetPrefix(Source, Prefix, False, True);
	
EndProcedure

// Sets the prefix of the subscription source in accordance with the prefix of the information database.
// There are no restrictions on the source details.
//
// Parameters:
//  Source - Arbitrary -  source of the subscription event.
//             Any object from the set [Reference, Document, plan of types of characteristics, Business process, Task].
//  StandardProcessing - Boolean -  flag for standard subscription processing.
//  Prefix - String -  the prefix of the object you want to modify.
//
Procedure SetInfobasePrefix(Source, StandardProcessing, Prefix) Export
	
	SetPrefix(Source, Prefix, True, False);
	
EndProcedure

// Sets the prefix of the subscription source in accordance with the prefix of the information base and the prefix of the company.
// The subscription source must contain
// the required details of the "Company" header, with the "reference Link" type.Companies".
//
// Parameters:
//  Source - Arbitrary -  source of the subscription event.
//             Any object from the set [Reference, Document, plan of types of characteristics, Business process, Task].
//  StandardProcessing - Boolean -  flag for standard subscription processing.
//  Prefix - String -  the prefix of the object you want to modify.
//
Procedure SetInfobaseAndCompanyPrefix(Source, StandardProcessing, Prefix) Export
	
	SetPrefix(Source, Prefix, True, True);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether the company element of the reference list is modified.
// If the Company details are changed, the element Code is reset to zero.
// This is necessary to assign a new code to the element.
//
// Parameters:
//  Source - CatalogObject -  source of the subscription event.
//  Cancel    - Boolean -  flag of failure.
// 
Procedure CheckCatalogCodeByCompany(Source, Cancel) Export
	
	CheckObjectCodeByCompany(Source);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether the business process Date is modified.
// If the date is not included in the previous period, the business process number is reset to zero.
// This is necessary to assign a new number to the business process.
//
// Parameters:
//  Source - BusinessProcessObject -  source of the subscription event.
//  Cancel    - Boolean -  flag of failure.
// 
Procedure CheckBusinessProcessNumberByDate(Source, Cancel) Export
	
	CheckObjectNumberByDate(Source);
	
EndProcedure

// Checks whether the Date and Company of the business process are modified.
// If the date is not included in the previous period or the Company's details are changed, the business process number is reset to zero.
// This is necessary to assign a new number to the business process.
//
// Parameters:
//  Source - BusinessProcessObject -  source of the subscription event.
//  Cancel    - Boolean -  flag of failure.
// 
Procedure CheckBusinessProcessNumberByDateAndCompany(Source, Cancel) Export
	
	CheckObjectNumberByDateAndCompany(Source);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Checks whether the document Date is modified.
// If the date is not included in the previous period, the document number is reset to zero.
// This is necessary to assign a new number to the document.
//
// Parameters:
//  Source - DocumentObject -  source of the subscription event.
//  Cancel    - Boolean -  flag of failure.
//  WriteMode - DocumentWriteMode -  the current document recording mode is passed to the parameter.
//  PostingMode - DocumentPostingMode -  this parameter is passed to the current mode of the event.
//
Procedure CheckDocumentNumberByDate(Source, Cancel, WriteMode, PostingMode) Export
	
	CheckObjectNumberByDate(Source);
	
EndProcedure

// Checks whether the date and Company of the document are modified.
// If the date is not included in the previous period or the Company's details are changed, the document number is reset to zero.
// This is necessary to assign a new number to the document.
//
// Parameters:
//  Source - DocumentObject -  source of the subscription event.
//  Cancel    - Boolean -  flag of failure.
//  WriteMode - DocumentWriteMode -  the current document recording mode is passed to the parameter.
//  PostingMode - DocumentPostingMode -  this parameter is passed to the current mode of the event.
// 
Procedure CheckDocumentNumberByDateAndCompany(Source, Cancel, WriteMode, PostingMode) Export
	
	CheckObjectNumberByDateAndCompany(Source);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the prefix of this information base.
//
// Parameters:
//    InfobasePrefix - String -  returned value. Contains the prefix of the information base.
//
Procedure OnDetermineInfobasePrefix(InfobasePrefix) Export
	
	If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
		InfobasePrefix = ModuleDataExchangeServer.InfobasePrefix();
	Else
		InfobasePrefix = "";
	EndIf;
	
EndProcedure

// Returns the prefix of the company.
//
// Parameters:
//  Organization - DefinedType.Organization - 
//  CompanyPrefix - String -  the company's prefix.
//
Procedure OnDetermineCompanyPrefix(Val Organization, CompanyPrefix) Export
	
	If Metadata.DefinedTypes.Organization.Type.ContainsType(Type("String")) Then
		CompanyPrefix = "";
		Return;
	EndIf;
		
	FunctionalOptionName = "CompanyPrefixes";
	FunctionalOptionParameterName = "Organization";
	
	
	
	CompanyPrefix = GetFunctionalOption(FunctionalOptionName, 
		New Structure(FunctionalOptionParameterName, Organization));
	
EndProcedure

#EndRegion

#Region Private

Procedure SetPrefix(Source, Prefix, SetInfobasePrefix, SetCompanyPrefix)
	
	InfobasePrefix = "";
	CompanyPrefix        = "";
	
	If SetInfobasePrefix Then
		
		OnDetermineInfobasePrefix(InfobasePrefix);
		
		SupplementStringWithZerosOnLeft(InfobasePrefix, 2);
	EndIf;
	
	If SetCompanyPrefix Then
		
		If CompanyAttributeAvailable(Source) Then
			
			OnDetermineCompanyPrefix(
				Source[CompanyAttributeName(Source.Metadata())], CompanyPrefix);
			// 
			If CompanyPrefix = False Then
				
				CompanyPrefix = "";
				
			EndIf;
			
		EndIf;
		
		SupplementStringWithZerosOnLeft(CompanyPrefix, 2);
	EndIf;
	
	PrefixTemplate = "[COMP][IB]-[Prefix]";
	PrefixTemplate = StrReplace(PrefixTemplate, "[COMP]", CompanyPrefix);
	PrefixTemplate = StrReplace(PrefixTemplate, "[IB]", InfobasePrefix);
	PrefixTemplate = StrReplace(PrefixTemplate, "[Prefix]", Prefix);
	
	Prefix = PrefixTemplate;
	
EndProcedure

Procedure SupplementStringWithZerosOnLeft(String, StringLength)
	
	String = StringFunctionsClientServer.SupplementString(String, StringLength, "0", "Left");
	
EndProcedure

Procedure CheckObjectNumberByDate(Object)
	
	If Object.DataExchange.Load Or Object.IsNew() Then
		Return;
	EndIf;
	
	ObjectMetadata = Object.Metadata();
	
	QueryText = 
	"SELECT
	|	ObjectHeader.Date AS Date
	|FROM
	|	&MetadataTableName AS ObjectHeader
	|WHERE
	|	ObjectHeader.Ref = &Ref";
	
	QueryText = StrReplace(QueryText, "&MetadataTableName", ObjectMetadata.FullName());
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Not ObjectsPrefixesInternal.ObjectDatesOfSamePeriod(Selection.Date, Object.Date, Object.Ref) Then
		
		Object.Number = "";
		
	EndIf;
	
EndProcedure

Procedure CheckObjectNumberByDateAndCompany(Object)
	
	If Object.DataExchange.Load Or Object.IsNew() Then
		Return;
	EndIf;
	
	If ObjectsPrefixesInternal.ObjectDateOrCompanyChanged(Object.Ref, Object.Date,
		Object[CompanyAttributeName(Object.Metadata())]) Then
		
		Object.Number = "";
		
	EndIf;
	
EndProcedure

Procedure CheckObjectCodeByCompany(Object)
	
	If Object.DataExchange.Load Or Object.IsNew() Or Not CompanyAttributeAvailable(Object) Then
		Return;
	EndIf;
	
	If ObjectsPrefixesInternal.ObjectCompanyChanged(Object.Ref,	
		Object[CompanyAttributeName(Object.Metadata())]) Then
		
		Object.Code = "";
		
	EndIf;
	
EndProcedure

Function CompanyAttributeAvailable(Object)
	
	// 
	Result = True;
	
	ObjectMetadata = Object.Metadata();
	
	If   (Common.IsCatalog(ObjectMetadata)
		Or Common.IsChartOfCharacteristicTypes(ObjectMetadata))
		And ObjectMetadata.Hierarchical Then
		
		CompanyAttributeName = CompanyAttributeName(ObjectMetadata);
		
		CompanyAttribute1 = ObjectMetadata.Attributes.Find(CompanyAttributeName);
		
		If CompanyAttribute1 = Undefined Then
			
			If Common.IsStandardAttribute(ObjectMetadata.StandardAttributes, CompanyAttributeName) Then
				
				// 
				Return True;
				
			EndIf;
			
			MessageString = NStr("en = 'The %2 attribute is not defined for the %1 metadata object.';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ObjectMetadata.FullName(), CompanyAttributeName);
			Raise MessageString;
		EndIf;
			
		If CompanyAttribute1.Use = Metadata.ObjectProperties.AttributeUse.ForFolder And Not Object.IsFolder Then
			
			Result = False;
			
		ElsIf CompanyAttribute1.Use = Metadata.ObjectProperties.AttributeUse.ForItem And Object.IsFolder Then
			
			Result = False;
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

// For internal use.
Function CompanyAttributeName(Object) Export
	
	If TypeOf(Object) = Type("MetadataObject") Then
		FullName = Object.FullName();
	Else
		FullName = Object;
	EndIf;
	
	Attribute = ObjectsPrefixesCached.PrefixGeneratingAttributes().Get(FullName);
	
	If Attribute <> Undefined Then
		Return Attribute;
	EndIf;
	
	Return "Organization";
	
EndFunction

#EndRegion
