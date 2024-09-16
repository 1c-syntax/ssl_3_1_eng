///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns a table of prefix-forming details specified in the module to be overridden.
//
Function PrefixGeneratingAttributes() Export
	
	Objects = New ValueTable;
	Objects.Columns.Add("Object");
	Objects.Columns.Add("Attribute");
	
	ObjectsPrefixesOverridable.GetPrefixGeneratingAttributes(Objects);
	
	ObjectsAttributes = New Map;
	
	For Each ObjectAttribute In Objects Do
		ObjectsAttributes.Insert(ObjectAttribute.Object.FullName(), ObjectAttribute.Attribute);
	EndDo;
	
	Return New FixedMap(ObjectsAttributes);
	
EndFunction

#EndRegion
