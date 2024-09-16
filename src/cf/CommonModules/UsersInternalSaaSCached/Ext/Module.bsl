///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Reads information about registers from a constant and forms a match for the list of registrationsreferencesexternal Users.
//
Function RecordSetsWithRefsToUsersList() Export
	
	SetPrivilegedMode(True);
	MetadataDetails = RecordSetsWithRefsToUsers();
	
	MetadataList = New Map;
	For Each String In MetadataDetails Do
		MetadataList.Insert(Metadata[String.Collection][String.Object], String.Dimensions);
	EndDo;
	
	Return MetadataList;
	
EndFunction

#EndRegion

#Region Private

// Returns sets of records containing fields that have the reference Link type set as the value
// type.Users.
//
// Returns:
//   ValueTable:
//                         * Collection - String -  name of the metadata collection,
//                         * Object - String -  name of the metadata object,
//                         * Dimensions - Array of String -  dimension name.
//
Function RecordSetsWithRefsToUsers()
	
	MetadataDetails = New ValueTable;
	MetadataDetails.Columns.Add("Collection", New TypeDescription("String"));
	MetadataDetails.Columns.Add("Object", New TypeDescription("String"));
	MetadataDetails.Columns.Add("Dimensions", New TypeDescription("Array"));
	
	For Each InformationRegister In Metadata.InformationRegisters Do
		AddToMetadataList(MetadataDetails, InformationRegister, "InformationRegisters");
	EndDo;
	
	For Each Sequence In Metadata.Sequences Do
		AddToMetadataList(MetadataDetails, Sequence, "Sequences");
	EndDo;
	
	Return MetadataDetails;
	
EndFunction

Procedure AddToMetadataList(Val MetadataList, Val ObjectMetadata, Val CollectionName)
	
	UserRefType = Type("CatalogRef.Users");
	
	Dimensions = New Array;
	For Each Dimension In ObjectMetadata.Dimensions Do 
		
		If (Dimension.Type.ContainsType(UserRefType)) Then
			Dimensions.Add(Dimension.Name);
		EndIf;
		
	EndDo;
	
	If Dimensions.Count() > 0 Then
		String = MetadataList.Add();
		String.Collection = CollectionName;
		String.Object = ObjectMetadata.Name;
		String.Dimensions = Dimensions;
	EndIf;
	
EndProcedure

#EndRegion