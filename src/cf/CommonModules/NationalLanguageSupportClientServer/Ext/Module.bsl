///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when getting a representation of an object or reference, depending on the language
// used by the user.
//
// Parameters:
//  Data               - Structure -  contains the values of the fields that form the view.
//  Presentation        - String -  the generated view should be placed in this parameter.
//  StandardProcessing - Boolean -  this parameter is passed to indicate that the standard view is formed.
//  AttributeName         - String -  specifies which props store the view in the main language.
//
Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing, AttributeName = "Description") Export
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If NationalLanguageSupportServer.IsMainLanguage() Then
			Return;
		EndIf;
		
		LanguageSuffix = NationalLanguageSupportServer.CurrentLanguageSuffix();
		If ValueIsFilled(LanguageSuffix) Then
	
			If Data.Property(AttributeName + LanguageSuffix) Then
				
				Presentation = Data[AttributeName + LanguageSuffix];
				If IsBlankString(Presentation) And Data.Property(AttributeName) Then
					Presentation = Data[AttributeName];
					If IsBlankString(Presentation) Then
						Return;
					EndIf;
				EndIf;
				
				StandardProcessing = False;
				Return;
				
			EndIf;
	
		EndIf;
			
		If Data.Property("Ref") Or Data.Ref <> Undefined Then
			If NationalLanguageSupportServer.ObjectContainsPMRepresentations(Data.Ref, AttributeName) Then
				QueryText = 
				"SELECT TOP 1
				|	&AttributeName AS Description
				|FROM
				|	&Presentations AS Presentations
				|WHERE
				|	Presentations.LanguageCode = &Language
				|	AND Presentations.Ref = &Ref";
				
				QueryText = StrReplace(QueryText, "&AttributeName", "Presentations." + AttributeName);
				QueryText = StrReplace(QueryText, "&Presentations", Data.Ref.Metadata().FullName() + ".Presentations");
				
				Query = New Query(QueryText);
				
				Query.SetParameter("Ref", Data.Ref);
				Query.SetParameter("Language",   CurrentLanguage().LanguageCode);
				
				QueryResult = Query.Execute();
				If Not QueryResult.IsEmpty() Then
					StandardProcessing = False;
					Presentation = QueryResult.Unload()[0].Description;
				EndIf;
			EndIf;
			
		EndIf;
		
	#EndIf
	
EndProcedure

// Called to form the composition of fields that form the representation of an object or reference.
// The fields are formed based on the user's current language.
//
// Parameters:
//  Fields                 - Array -  an array containing the names of fields that are needed to form a representation of an object
//                                  or reference.
//  StandardProcessing - Boolean -  this parameter is passed to indicate that standard (system) event processing is performed.
//                                  If this parameter is set to False in the body of the handler procedure,
//                                  standard event processing will not be performed.
//  AttributeName         - String -  specifies which props store the view in the main language.
//
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing, AttributeName = "Description") Export
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If NationalLanguageSupportServer.IsMainLanguage() Then
			Return;
		EndIf;
		
		StandardProcessing = False;
		Fields.Add(AttributeName);
		Fields.Add("Ref");
		
		If NationalLanguageSupportServer.FirstAdditionalLanguageUsed() Then
			Fields.Add(AttributeName + "Language1");
		EndIf;
		
		If NationalLanguageSupportServer.SecondAdditionalLanguageUsed() Then
			Fields.Add(AttributeName +"Language2");
		EndIf;
	
	#EndIf
	
EndProcedure

#EndRegion