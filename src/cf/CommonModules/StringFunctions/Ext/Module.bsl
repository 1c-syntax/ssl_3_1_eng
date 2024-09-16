///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Formats the string according to the specified template.
// The possible values of the tags in the template:
// - <span style= " property Name: Style element name" > String</span> - forms the text
//      with the style elements described in the style attribute.
// - <b> String </b> - selects a string with an important typescript Style element
//      that corresponds to a bold font.
// - <a href="link">String</a> - adds a hyperlink.
// - <img src= "Calendar" > - adds an image from the image library.
// The style attribute is used for text formatting. The attribute can be used for the span and a tags.
// First comes the name of the style property, then the name of the style element separated by a colon.
// Style properties:
//  - color-Defines the color of the text. For example, color: hyperlink Color;
//  - background-color-Defines the background color of the text. For example, background-color: Togetherby;
//  - font-Defines the font of the text.For example, the font: Mainelement of the list.
// Style properties are separated by semicolons. For example, style= " color: hyperlink Color; font: Mainelement of the list"
// Nested tags are not supported.
//
// Parameters:
//  StringPattern - String -  a string containing formatting tags.
//  Parameter<n> - String-value of the parameter to be substituted.
//
// Returns:
//  FormattedString - 
//
// Example:
//  
//        
//       
//  
//       
//       
//  
//       
//
Function FormattedString(Val StringPattern, Val Parameter1 = Undefined, Val Parameter2 = Undefined,
	Val Parameter3 = Undefined, Val Parameter4 = Undefined, Val Parameter5 = Undefined) Export
	
	StyleItems = StandardSubsystemsServer.StyleItems();
	Return StringFunctionsClientServer.GenerateFormattedString(StringPattern, StyleItems, Parameter1, Parameter2, Parameter3, Parameter4, Parameter5);
	
EndFunction

// Converts the source string to a transliteration.
// It can be used for sending SMS messages in Latin letters or for saving
// files and folders to allow them to be transferred between different operating systems.
// Reverse conversion from Latin characters is not provided.
//
// Parameters:
//  Value - String -  arbitrary string.
//
// Returns:
//  String - 
//
Function LatinString(Val Value) Export
	
	TransliterationRules = New Map;
	StandardSubsystemsClientServerLocalization.OnFillTransliterationRules(TransliterationRules);
	Return CommonInternalClientServer.LatinString(Value, TransliterationRules);
	
EndFunction

// Returns the period representation in lowercase or uppercase
//  if the phrase (sentence) begins with it.
//  For example, if you want to output a representation of the period in the report header
//  in the format of "Sales in [Datacache] - [Datacentre]", it is expected that
//  the result will look like this: "Sales for February 2020 - March 2020".
//  Ie - line, since "February 2020 - March 2020" is not the beginning of a sentence.
//
// Parameters:
//  StartDate - Date -  the beginning of the period.
//  EndDate - Date -  end of period.
//  FormatString - String -  specifies the formatting style of the period.
//  Capitalize - Boolean -  True if the offer starts with the period representation.
//                    By default, it is False.
//
// Returns:
//   String - 
//
Function PeriodPresentationInText(StartDate, EndDate, FormatString = "", Capitalize = False) Export 
	
	Return CommonInternalClientServer.PeriodPresentationInText(
		StartDate, EndDate, FormatString, Capitalize);
	
EndFunction

#EndRegion

