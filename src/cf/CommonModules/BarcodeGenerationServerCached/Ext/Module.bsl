///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// The function connects the external component and sets it up for the first time.
// Connects an external component.
// The function returns Undefined if the component failed to load.
//
// Parameters:
//   PlatformTypeComponents - String -  platform type
//
// Returns:
//   AddInObject:
//    * ECL - Number
//    * GS1DatabarRowCount - Number
//    * AutoType - Boolean
//    * Version - String
//    * CodeVerticalAlign - Number
//    * CanvasYOffset - Number
//    * CodeShowCS - Boolean
//    * CodeAlignment - Number
//    * Height - Number
//    * CanvasXOffset - Number
//    * GraphicsPresent - Boolean
//    * CodeValue - String
//    * FileName - String
//    * ColumnCount - Number
//    * RowCount - Number
//    * FontCount - Number
//    * CodeCheckSymbol - String
//    * LogoImage - Picture 
//    * LogoSizePercentFromBarcode - Number
//    * MaxFontSizeForLowDPIPrinters - Number
//    * CodeMinHeight - Number
//    * CodeMinWidth - Number
//    * TextAlign - Number
//    * TextVisible - Boolean
//    * TextPos - Number
//    * BgTransparent - Boolean
//    * AspectRatio - String
//    * CodeSentinel - Number
//    * CanvasMargin - Number
//    * FontSize - Number
//    * Result - Number
//    * ContainsCS - Boolean
//    * CodeText - String
//    * InputDataType - Number
//    * CodeType - Number
//    * RemoveExtraBackgroud - Boolean
//    * CanvasRotation - Number
//    * QRErrorCorrectionLevel - Number
//    * BarColor - Number
//    * TextColor - Number
//    * BgColor - Number
//    * Width - Number
//    * Font - String
//   Undefined
//
Function ToConnectAComponentGeneratingAnImageOfTheBarcode(PlatformTypeComponents) Export
	
	Return BarcodeGeneration.ToConnectAComponentGeneratingAnImageOfTheBarcode();
	
EndFunction

#EndRegion