///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Backward compatibility.
// Creates a description of the message template parameter table.
//
// Returns:
//   ValueTable - :
//    * ParameterName                - String -  parameter name.
//    * TypeDetails                - TypeDescription -  description of the parameter type.
//    * IsPredefinedParameter - Boolean -  whether the parameter is predefined.
//    * ParameterPresentation      - String -  representation of the argument.
//
Function ParametersTable() Export
	
	TemplateParameters = New ValueTable;
	
	TemplateParameters.Columns.Add("ParameterName"                , New TypeDescription("String",, New StringQualifiers(50, AllowedLength.Variable)));
	TemplateParameters.Columns.Add("TypeDetails"                , New TypeDescription("TypeDescription"));
	TemplateParameters.Columns.Add("IsPredefinedParameter" , New TypeDescription("Boolean"));
	TemplateParameters.Columns.Add("ParameterPresentation"      , New TypeDescription("String",, New StringQualifiers(150, AllowedLength.Variable)));
	
	Return TemplateParameters;
	
EndFunction

#EndRegion
