///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// 
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Retrieves previously saved header and footer settings. If there are no settings,
// the empty settings structure is returned.
//
// Returns:
//   Structure - 
//
Function HeaderOrFooterSettings() Export
	Var Settings;
	
	Store = Constants.HeaderOrFooterSettings.Get();
	If TypeOf(Store) = Type("ValueStorage") Then
		Settings = Store.Get();
		If TypeOf(Settings) = Type("Structure") Then
			If Not Settings.Property("Header") 
				Or Not Settings.Property("Footer") Then
				Settings = Undefined;
			Else
				AddHeaderOrFooterSettings(Settings.Header);
				AddHeaderOrFooterSettings(Settings.Footer);
			EndIf;
		EndIf;
	EndIf;
	
	If Settings = Undefined Then
		Settings = BlankHeaderOrFooterSettings();
	EndIf;
	
	Return Settings;
EndFunction

#EndRegion

#Region Private

// Saves the header and footer settings passed in the parameter for future use.
//
// Parameters:
//  Settings - Structure -  values of header and footer settings to save.
//
Procedure SaveHeadersAndFootersSettings(Settings) Export
	Constants.HeaderOrFooterSettings.Set(New ValueStorage(Settings));
EndProcedure

// Sets the values of the Report Name and User parameters in the template string.
//
// Parameters:
//   Template - String -  setting up a footer with parameter values not yet set.
//   ReportTitle - String -  the value of the parameter to be inserted in the template.
//   User - CatalogRef.Users -  the value of the parameter to be inserted in the template.
//
// Returns:
//   String - 
//
Function PropertyValueFromTemplate(Template, ReportTitle, User)
	Result = StrReplace(Template, "[&ReportTitle]", TrimAll(ReportTitle));
	Result = StrReplace(Result, "[&User]"  , TrimAll(User));
	
	Return Result;
EndFunction

// Sets headers and footers in a table document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument -  the document to set the headers and footers in.
//  ReportTitle - String -  the value of the parameter to be inserted in the template.
//  User - CatalogRef.Users -  the value of the parameter to be inserted in the template.
//  HeaderOrFooterSettings - Structure -  individual settings for headers and footers.
//
Procedure SetHeadersAndFooters(SpreadsheetDocument, ReportTitle = "", User = Undefined, HeaderOrFooterSettings = Undefined) Export
	If User = Undefined Then
		User = Users.AuthorizedUser();
	EndIf;
	
	If HeaderOrFooterSettings = Undefined Then 
		HeaderOrFooterSettings = HeaderOrFooterSettings();
	EndIf;
	
	If Not HeaderOrFooterSet(SpreadsheetDocument.Header) Then 
		HeaderOrFooterProperties = HeaderOrFooterProperties(HeaderOrFooterSettings.Header, ReportTitle, User);
		FillPropertyValues(SpreadsheetDocument.Header, HeaderOrFooterProperties);
	EndIf;
	
	If Not HeaderOrFooterSet(SpreadsheetDocument.Footer) Then 
		HeaderOrFooterProperties = HeaderOrFooterProperties(HeaderOrFooterSettings.Footer, ReportTitle, User);
		FillPropertyValues(SpreadsheetDocument.Footer, HeaderOrFooterProperties);
	EndIf;
EndProcedure

// Returns whether the footer is set.
//
// Parameters:
//  HeaderOrFooter - SpreadsheetDocumentHeaderFooter -  header or footer of a table document.
//
// Returns:
//   Boolean - 
//
Function HeaderOrFooterSet(HeaderOrFooter)
	Return ValueIsFilled(HeaderOrFooter.LeftText)
		Or ValueIsFilled(HeaderOrFooter.CenterText)
		Or ValueIsFilled(HeaderOrFooter.RightText);
EndFunction

// Returns the values of the header and footer properties.
//
// Parameters:
//  HeaderOrFooterSettings1 - See BlankHeaderOrFooterSettings
//  ReportTitle - String -  the value to be inserted in the template [&report Name].
//  User - CatalogRef.Users -  the value to be inserted in the template [&User].
//
// Returns:
//   Structure - 
//
Function HeaderOrFooterProperties(HeaderOrFooterSettings1, ReportTitle, User)
	HeaderOrFooterProperties = New Structure;
	If ValueIsFilled(HeaderOrFooterSettings1.LeftText)
		Or ValueIsFilled(HeaderOrFooterSettings1.CenterText)
		Or ValueIsFilled(HeaderOrFooterSettings1.RightText) Then
		
		HeaderOrFooterProperties.Insert("Enabled", True);
		HeaderOrFooterProperties.Insert("HomePage", HeaderOrFooterSettings1.HomePage);
		HeaderOrFooterProperties.Insert("VerticalAlign", HeaderOrFooterSettings1.VerticalAlign);
		HeaderOrFooterProperties.Insert("LeftText", PropertyValueFromTemplate(
			HeaderOrFooterSettings1.LeftText, ReportTitle, User));
		HeaderOrFooterProperties.Insert("CenterText", PropertyValueFromTemplate(
			HeaderOrFooterSettings1.CenterText, ReportTitle, User));
		HeaderOrFooterProperties.Insert("RightText", PropertyValueFromTemplate(
			HeaderOrFooterSettings1.RightText, ReportTitle, User));
		
		If HeaderOrFooterSettings1.Property("Font") And HeaderOrFooterSettings1.Font <> Undefined Then
			HeaderOrFooterProperties.Insert("Font", HeaderOrFooterSettings1.Font);
		Else
			HeaderOrFooterProperties.Insert("Font", New Font);
		EndIf;
	Else
		HeaderOrFooterProperties.Insert("Enabled", False);
	EndIf;
	
	Return HeaderOrFooterProperties;
EndFunction

// Header and footer settings constructor.
//
// Returns:
//   Structure - 
//
Function BlankHeaderOrFooterSettings()
	Header = New Structure;
	Header.Insert("LeftText", "");
	Header.Insert("CenterText", "");
	Header.Insert("RightText", "");
	Header.Insert("Font", New Font);
	Header.Insert("VerticalAlign", VerticalAlign.Bottom);
	Header.Insert("HomePage", 0);
	
	Footer = New Structure;
	Footer.Insert("LeftText", "");
	Footer.Insert("CenterText", "");
	Footer.Insert("RightText", "");
	Footer.Insert("Font", New Font);
	Footer.Insert("VerticalAlign", VerticalAlign.Top);
	Footer.Insert("HomePage", 0);
	
	Return New Structure("Header, Footer", Header, Footer);
EndFunction

Procedure AddHeaderOrFooterSettings(HeaderOrFooterSettings1)
	If Not HeaderOrFooterSettings1.Property("LeftText")
		Or TypeOf(HeaderOrFooterSettings1.LeftText) <> Type("String") Then
		HeaderOrFooterSettings1.Insert("LeftText", "");
	EndIf;
	If Not HeaderOrFooterSettings1.Property("CenterText")
		Or TypeOf(HeaderOrFooterSettings1.CenterText) <> Type("String") Then
		HeaderOrFooterSettings1.Insert("CenterText", "");
	EndIf;
	If Not HeaderOrFooterSettings1.Property("RightText")
		Or TypeOf(HeaderOrFooterSettings1.RightText) <> Type("String") Then
		HeaderOrFooterSettings1.Insert("RightText", "");
	EndIf;
	If Not HeaderOrFooterSettings1.Property("Font")
		Or TypeOf(HeaderOrFooterSettings1.Font) <> Type("Font") Then
		HeaderOrFooterSettings1.Insert("Font", New Font);
	EndIf;
	If Not HeaderOrFooterSettings1.Property("VerticalAlign")
		Or TypeOf(HeaderOrFooterSettings1.VerticalAlign) <> Type("VerticalAlign") Then
		HeaderOrFooterSettings1.Insert("VerticalAlign", VerticalAlign.Center);
	EndIf;
	If Not HeaderOrFooterSettings1.Property("HomePage")
		Or TypeOf(HeaderOrFooterSettings1.HomePage) <> Type("Number")
		Or HeaderOrFooterSettings1.HomePage < 0 Then
		HeaderOrFooterSettings1.Insert("HomePage", 0);
	EndIf;
EndProcedure

// Determines whether the settings are standard and/or empty.
//
// Parameters:
//  Settings - See HeaderOrFooterSettings
//
// Returns:
//   Structure - :
//     * Standard1 - Boolean -  True if the passed settings correspond to the standard (General)
//                     settings stored in the header Settings constant.
//     * Empty1 - Boolean -  True if the passed settings match the empty
//                ones returned by the empty header and footer () function.
//
Function HeadersAndFootersSettingsStatus(Settings) Export 
	SettingsStatus = New Structure("Standard1, Empty1");
	SettingsStatus.Standard1 = Common.DataMatch(Settings, HeaderOrFooterSettings());
	SettingsStatus.Empty1 = Common.DataMatch(Settings, BlankHeaderOrFooterSettings());
	
	Return SettingsStatus;
EndFunction

#EndRegion