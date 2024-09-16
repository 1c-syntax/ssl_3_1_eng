///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Opens a report on all problems of the transmitted type of problems.
//
// Parameters:
//   ChecksKind - CatalogRef.ChecksKinds -  link to the type of check.
//               - String - 
//               - Array of String - 
//   ExactMap - Boolean - 
//                 
//
// Example:
//   Open a Problem report ("System Checks");
//
Procedure OpenIssuesReport(ChecksKind, ExactMap = True) Export
	
	// 
	// 
	
	AccountingAuditInternalClient.OpenIssuesReport(ChecksKind, ExactMap);
	
EndProcedure

// Opens the report form when clicking on the hyperlink signaling the presence of problems.
//
//  Parameters:
//     Form                - ClientApplicationForm -  the shape of the problem object.
//     ObjectWithIssue     - AnyRef -  a reference to the problem object.
//     StandardProcessing - Boolean -  a sign of
//                            standard (system) event processing is passed to this parameter.
//
// Example:
//    Monitoring of the accounting of the client.Open Reportproblemobject(This is an object, an object.Link, standard processing);
//
Procedure OpenObjectIssuesReport(Form, ObjectWithIssue, StandardProcessing) Export
	
	// 
	// 
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectReference", ObjectWithIssue);
	
	OpenForm("Report.AccountingCheckResults.Form", FormParameters);
	
EndProcedure

// Opens the report form by double-clicking on the table cell of the list form with an image
// indicating the presence of problems with the selected object.
//
//  Parameters:
//     Form                   - ClientApplicationForm -  the shape of the problem object.
//     ListName               - String -  the name of the target dynamic list as the form's props.
//     Field                    - FormField -  the column in which the picture is located,
//                               signaling the presence of problems.
//     StandardProcessing    - Boolean -  a sign of
//                               standard (system) event processing is passed to this parameter.
//     AdditionalParameters - Structure
//                             - Undefined - 
//                               
//
// Example:
//    Monitoring of the accounting of the client.Open the reportproblem of the list (this is an object, a "List", a field, standard processing);
//
Procedure OpenListedIssuesReport(Form, ListName, Field, StandardProcessing, AdditionalParameters = Undefined) Export
	
	ProcedureName = "AccountingAuditClient.OpenListedIssuesReport";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "ListName", ListName, Type("String"));
	CommonClientServer.CheckParameter(ProcedureName, "Field", Field, Type("FormField"));
	CommonClientServer.CheckParameter(ProcedureName, "StandardProcessing", StandardProcessing, Type("Boolean"));
	If AdditionalParameters <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalParameters", AdditionalParameters, Type("Structure"));
	EndIf;
	
	AdditionalProperties = Form[ListName].SettingsComposer.Settings.AdditionalProperties;
	
	If Not (AdditionalProperties.Property("IndicatorColumn")
		And AdditionalProperties.Property("MetadataObjectKind")
		And AdditionalProperties.Property("MetadataObjectName")
		And AdditionalProperties.Property("ListName")) Then
		StandardProcessing = True;
	Else
		
		FormTable   = Form.Items.Find(AdditionalProperties.ListName);
		
		If Field.Name <> AdditionalProperties.IndicatorColumn Then
			StandardProcessing = True;
		Else
			CurrentData = Form.Items[ListName].CurrentData;
			If CurrentData[Field.Name] = 0 Then
				Return; // 
			EndIf;
			
			StandardProcessing = False;
			
			ContextData = New Structure;
			ContextData.Insert("SelectedRows",     FormTable.SelectedRows);
			ContextData.Insert("MetadataObjectKind", AdditionalProperties.MetadataObjectKind);
			ContextData.Insert("MetadataObjectName", AdditionalProperties.MetadataObjectName);
			
			FormParameters = New Structure;
			FormParameters.Insert("ContextData", ContextData);
			OpenForm("Report.AccountingCheckResults.Form", FormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
