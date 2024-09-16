///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// See CommonClient.StyleColor
Function StyleColor(Val StyleColorName) Export
	
	Return CommonServerCall.StyleColor(StyleColorName);
	
EndFunction

// See CommonClient.StyleFont
Function StyleFont(Val StyleFontName) Export
	
	Return CommonServerCall.StyleFont(StyleFontName);
	
EndFunction

#EndRegion
