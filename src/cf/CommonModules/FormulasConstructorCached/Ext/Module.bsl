///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function PictureByName(IconName) Export
	
	Return PictureLib[IconName];	
	
EndFunction   

Function EnumsMetadata() Export 
	
	TypesArray = New Array;
	
	For Each EnumerationMetadata In Metadata.Enums Do
		TypesArray.Add(EnumerationMetadata);
	EndDo;   
	
	Return New FixedArray(TypesArray);
	
EndFunction

#EndRegion