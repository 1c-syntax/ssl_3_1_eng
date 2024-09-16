///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Types of publishing additional treatments available in the program.
Function AvaliablePublicationKinds() Export
	
	Result = New Array();
	
	Values = Metadata.Enums.AdditionalReportsAndDataProcessorsPublicationOptions.EnumValues;
	PublicationKindsToExcept = AdditionalReportsAndDataProcessors.NotAvailablePublicationKinds();
	
	For Each Value In Values Do
		If PublicationKindsToExcept.Find(Value.Name) = Undefined Then
			Result.Add(Enums.AdditionalReportsAndDataProcessorsPublicationOptions[Value.Name]);
		EndIf;
	EndDo;
	
	Return New FixedArray(Result);
	
EndFunction

// Settings for the form of the assigned object.
Function AssignedObjectFormParameters(FullFormName, FormType = Undefined) Export
	If Not AccessRight("Read", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Return "";
	EndIf;
	
	Result = New Structure("IsObjectForm, FormType, ParentRef");
	
	MetadataForm = Metadata.FindByFullName(FullFormName);
	If MetadataForm = Undefined Then
		PointPosition = StrLen(FullFormName);
		While Mid(FullFormName, PointPosition, 1) <> "." Do
			PointPosition = PointPosition - 1;
		EndDo;
		FullParentName = Left(FullFormName, PointPosition - 1);
		MetadataParent = Metadata.FindByFullName(FullParentName);
	Else
		MetadataParent = MetadataForm.Parent();
	EndIf;
	If MetadataParent = Undefined Or TypeOf(MetadataParent) = Type("ConfigurationMetadataObject") Then
		Return "";
	EndIf;
	Result.ParentRef = Common.MetadataObjectID(MetadataParent);
	
	If FormType <> Undefined Then
		If Upper(FormType) = Upper(AdditionalReportsAndDataProcessorsClientServer.ObjectFormType()) Then
			Result.IsObjectForm = True;
		ElsIf Upper(FormType) = Upper(AdditionalReportsAndDataProcessorsClientServer.ListFormType()) Then
			Result.IsObjectForm = False;
		Else
			Result.IsObjectForm = (MetadataParent.DefaultObjectForm = MetadataForm);
		EndIf;
	Else
		Collection = New Structure("DefaultObjectForm");
		FillPropertyValues(Collection, MetadataParent);
		Result.IsObjectForm = (Collection.DefaultObjectForm = MetadataForm);
	EndIf;
	
	If Result.IsObjectForm Then // 
		Result.FormType = AdditionalReportsAndDataProcessorsClientServer.ObjectFormType();
	Else // List form
		Result.FormType = AdditionalReportsAndDataProcessorsClientServer.ListFormType();
	EndIf;
	
	Return New FixedStructure(Result);
EndFunction

#EndRegion
