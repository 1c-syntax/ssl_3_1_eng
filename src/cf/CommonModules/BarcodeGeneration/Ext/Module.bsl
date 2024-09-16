///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// An empty structure for filling in the "barcode Parameterstriccode" parameter used to get the barcode image.
// 
// Returns:
//   Structure:
//   * Width - Number -  the width of the barcode image.
//   * Height - Number -  the height of the barcode image.
//   * CodeType - Number - 
//       :
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//      
//            
//            
//   * ShowText - Boolean -  display the test HRI for the barcode.
//   * FontSize - Number -  the HRI font size of the barcode test.
//   * CanvasRotation - Number -  the angle of rotation.
//      Possible values: 0, 90, 180, 270.
//   * Barcode - String -  the barcode value is in the form of a string or Base64.
//   * InputDataType - Number -  input data type 
//      Possible values: 0-String, 1-Base64
//   * BgTransparent - Boolean -  transparent background of the barcode image.
//   * QRErrorCorrectionLevel - Number -  the level of correction of the QR barcode.
//      Possible values: 0 - L, 1-M, 2-Q, 3-H.
//   * Zoomable - Boolean -    to scale the image of the barcode.
//   * MaintainAspectRatio - Boolean -  maintain the proportions of the barcode image.                                                              
//   * VerticalAlignment - Number -  vertical alignment of the barcode.
//      Possible values: 1-Top edge, 2-Center, 3 - Bottom edge
//   * GS1DatabarRowsCount - Number -  the number of lines in the GS1Databar barcode.
//   * RemoveExtraBackgroud - Boolean
//   * LogoImage - String -  a string with a base64 representation of the png image of the logo.
//   * LogoSizePercentFromBarcode - Number -  the percentage of the generated QR to fit the logo.
//
Function BarcodeGenerationParameters() Export
	
	BarcodeParameters = New Structure;
	BarcodeParameters.Insert("Width"            , 100);
	BarcodeParameters.Insert("Height"            , 100);
	BarcodeParameters.Insert("CodeType"           , 99);
	BarcodeParameters.Insert("ShowText"   , True);
	BarcodeParameters.Insert("FontSize"      , 12);
	BarcodeParameters.Insert("CanvasRotation"      , 0);
	BarcodeParameters.Insert("Barcode"          , "");
	BarcodeParameters.Insert("BgTransparent"     , True);
	BarcodeParameters.Insert("QRErrorCorrectionLevel", 1);
	BarcodeParameters.Insert("Zoomable"           , False);
	BarcodeParameters.Insert("MaintainAspectRatio"       , False);
	BarcodeParameters.Insert("VerticalAlignment" , 1); 
	BarcodeParameters.Insert("GS1DatabarRowsCount", 2);
	BarcodeParameters.Insert("InputDataType", 0);
	BarcodeParameters.Insert("RemoveExtraBackgroud" , False); 
	BarcodeParameters.Insert("LogoImage");
	BarcodeParameters.Insert("LogoSizePercentFromBarcode");       
	BarcodeParameters.Insert("NewChallengeComponents", False);  
	
	Return BarcodeParameters;
	
EndFunction                      

// Formation of the image of the barcode.
//
// Parameters: 
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters.
//
// Returns: 
//   Structure:
//      The result is a Boolean-the result of barcode generation.
//      Binary Data-Binary Data - Binary barcode image data.
//      Picture-Picture - picture with the generated barcode or UNDEFINED.
//
Function TheImageOfTheBarcode(BarcodeParameters) Export
	
	SystemInfo = New SystemInfo;
	PlatformTypeComponents = String(SystemInfo.PlatformType);
	
	AddIn = BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode(PlatformTypeComponents);
	
	If AddIn = Undefined Then
		ModuleCommon = ModuleCommon();
		MessageText = NStr("en = 'An error occurred while attaching the barcode printing add-in.';", ModuleCommon.DefaultLanguageCode());
	#If Not MobileAppServer Then
		WriteLogEvent(NStr("en = 'Barcode generation error';", 
			ModuleCommon.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			MessageText);
	#EndIf
		Raise MessageText;
	EndIf;
	
	If BarcodeParameters.Property("NewChallengeComponents") And BarcodeParameters.NewChallengeComponents Then
		Return PrepareABarcodeImage(AddIn, BarcodeParameters); 
	Else
		Return PrepareBarcodeImageOfProperty(AddIn, BarcodeParameters); 
	EndIf;
	 
EndFunction

// Returns binary data for generating a QR code.
//
// Parameters:
//  QRString         - String -  data to be placed in the QR code.
//
//  CorrectionLevel - Number - 
//                             
//                     :
//                     
//
//  Size           - Number -  specifies the length of the side of the output image in pixels.
//                     If the minimum possible image size is larger than this parameter, the code will not be generated.
//
// Returns:
//  BinaryData  - 
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
//
//  
//  
//
Function QRCodeData(QRString, CorrectionLevel, Size) Export
	
	BarcodeParameters = BarcodeGenerationParameters();
	BarcodeParameters.Width = Size;
	BarcodeParameters.Height = Size;
	BarcodeParameters.Barcode = QRString;
	BarcodeParameters.QRErrorCorrectionLevel = CorrectionLevel;
	BarcodeParameters.CodeType = 16; // QR
	BarcodeParameters.RemoveExtraBackgroud = True;
	
	Try
		TheResultOfTheFormationOfBarcode = TheImageOfTheBarcode(BarcodeParameters);
		BinaryPictureData = TheResultOfTheFormationOfBarcode.BinaryData;
	Except
	#If Not MobileAppServer Then
		ModuleCommon = ModuleCommon();
		WriteLogEvent(NStr("en = 'Barcode generation error';", 
			ModuleCommon.DefaultLanguageCode()),
			EventLogLevel.Error,,, 
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	#EndIf
	EndTry;
	
	Return BinaryPictureData;
	
EndFunction

#EndRegion

#Region Internal

// Connects an external component.
//
// Returns: 
//   AddInObject
//   Undefined - if the component failed to load.
//
Function ToConnectAComponentGeneratingAnImageOfTheBarcode() Export
	
	AddIn = Undefined;
	ObjectName = ComponentDetails().ObjectName;
	FullTemplateName = ComponentDetails().FullTemplateName;
	
	ModuleCommon = ModuleCommon();
	If ModuleCommon.SubsystemExists("EquipmentSupport") Then
		// 
		ModuleExternalComponentsOfBPO = ModuleCommon.CommonModule("AddInsCEL");
		AddIn = ModuleExternalComponentsOfBPO.AttachAddInSSL(ObjectName, FullTemplateName);
	Else
		// 
		// 
#If Not MobileAppServer Then
		SetSafeModeDisabled(True);
		If ModuleCommon.SeparatedDataUsageAvailable() Then
			If ModuleCommon.SubsystemExists("StandardSubsystems.AddIns") Then   
				ModuleAddInsServer = ModuleCommon.CommonModule("AddInsServer");
				ConnectionParameters = ModuleAddInsServer.ConnectionParameters();
				ConnectionResult = ModuleAddInsServer.AttachAddInSSL(ObjectName);
				If ConnectionResult.Attached Then
					AddIn = ConnectionResult.Attachable_Module;
				EndIf;
			EndIf;
		EndIf;
		If AddIn = Undefined Then 
			AddIn = ModuleCommon.AttachAddInFromTemplate(ObjectName, FullTemplateName);
		EndIf;
#EndIf
		// 
	EndIf;
	
	If AddIn = Undefined Then 
		Return Undefined;
	EndIf;
	
	// 
	// 
	If AddIn.FindFont("Tahoma") Then
		// 
		AddIn.Font = "Tahoma";
	Else
		// 
		// 
		For Cnt = 0 To AddIn.FontCount -1 Do
			// 
			CurrentFont = AddIn.FontAt(Cnt);
			// 
			If CurrentFont <> Undefined Then
				// 
				AddIn.Font = CurrentFont;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// 
	AddIn.FontSize = 12;
	
	Return AddIn;
	
EndFunction

// 
//
// Returns:
//  Structure:
//   * FullTemplateName - String
//   * ObjectName      - String
//
Function ComponentDetails() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectName", "Barcode");
	Parameters.Insert("FullTemplateName", "CommonTemplate.BarcodePrintingAddIn");
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private
 // Prepare barcode images.
//
// Parameters: 
//   AddIn - See BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters
//
// Returns: 
//   Structure:
//      The result is a Boolean-the result of barcode generation.
//      Binary Data-Binary Data - Binary barcode image data.
//      Picture-Picture - picture with the generated barcode or UNDEFINED.
//
Function PrepareABarcodeImage(AddIn, BarcodeParameters)
	
	XMLWriter = New XMLWriter; 
	XMLWriter.SetString("UTF-8");
	XMLWriter.WriteXMLDeclaration();
	
	XMLWriter.WriteStartElement("MakeBarcode");
	XMLWriter.WriteStartElement("Parameters");   
	
	// 
	XMLWriter.WriteStartElement("Font");   
	XMLWriter.WriteText(AddIn.Font);
	XMLWriter.WriteEndElement();
	// 	  
	TheWidthOfTheBarcode = ?(BarcodeParameters.Width <= 0, 1, Round(BarcodeParameters.Width));
	XMLWriter.WriteStartElement("Width");   
	XMLWriter.WriteText(String(TheWidthOfTheBarcode));
	XMLWriter.WriteEndElement();
	// 
	TheHeightOfTheBarcode = ?(BarcodeParameters.Height <= 0, 1, Round(BarcodeParameters.Height));
	XMLWriter.WriteStartElement("Height");   
	XMLWriter.WriteText(String(TheHeightOfTheBarcode));
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("BgTransparent");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.BgTransparent));
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("RemoveExeedBackgroud");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.RemoveExtraBackgroud));
	XMLWriter.WriteEndElement();
	//      
	CanvasRotation = Number(?(BarcodeParameters.Property("CanvasRotation"), BarcodeParameters.CanvasRotation, 0));
	XMLWriter.WriteStartElement("CanvasRotation");   
	XMLWriter.WriteText(XMLString(CanvasRotation));
	XMLWriter.WriteEndElement();
	//     
	QRErrorCorrectionLevel = Number(?(BarcodeParameters.Property("QRErrorCorrectionLevel"), BarcodeParameters.QRErrorCorrectionLevel, 1));
	XMLWriter.WriteStartElement("QRErrorCorrectionLevel");   
	XMLWriter.WriteText(XMLString(QRErrorCorrectionLevel));
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("TextVisible");   
	XMLWriter.WriteText(XMLString(BarcodeParameters.ShowText));
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("FontSize");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.FontSize)));
	XMLWriter.WriteEndElement();
	// 
	// 
	XMLWriter.WriteStartElement("CodeVerticalAlign");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.VerticalAlignment)));
	XMLWriter.WriteEndElement();   
	// 
	XMLWriter.WriteStartElement("GS1DatabarRowCount");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.GS1DatabarRowsCount)));
	XMLWriter.WriteEndElement();
	// 
	If BarcodeParameters.CodeType = 16 Then 
		If ValueIsFilled(BarcodeParameters.LogoImage) Then 
			XMLWriter.WriteStartElement("LogoImageBase64");   
			XMLWriter.WriteText(XMLString(BarcodeParameters.LogoImage));
			XMLWriter.WriteEndElement();
		EndIf;
		If Not IsBlankString(BarcodeParameters.LogoSizePercentFromBarcode) Then 
			XMLWriter.WriteStartElement("LogoSizePercentFromBarcode");   
			XMLWriter.WriteText(XMLString(Number(BarcodeParameters.LogoSizePercentFromBarcode)));
			XMLWriter.WriteEndElement();
		EndIf;
	EndIf;                            
	// 
	AutoBarcodeType = (BarcodeParameters.CodeType = 99);
	XMLWriter.WriteStartElement("CodeAuto");   
	XMLWriter.WriteText(XMLString(AutoBarcodeType));
	XMLWriter.WriteEndElement();
	If Not AutoBarcodeType Then          
		XMLWriter.WriteStartElement("CodeType");   
		XMLWriter.WriteText(XMLString(Number(BarcodeParameters.CodeType)));
		XMLWriter.WriteEndElement();
	EndIf;                     
	// ECL
	XMLWriter.WriteStartElement("ECL");   
	XMLWriter.WriteText("1");
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("InputDataType");   
	XMLWriter.WriteText(XMLString(Number(BarcodeParameters.InputDataType)));
	XMLWriter.WriteEndElement();
	// 
	XMLWriter.WriteStartElement("CodeValue");   
	XMLWriter.WriteText(XMLString(String(BarcodeParameters.Barcode)));
	XMLWriter.WriteEndElement();
	
	XMLWriter.WriteEndElement();
	XMLWriter.WriteEndElement();
	
	XMLGenerationParameters = XMLWriter.Close();
	
	XMLResult = "";
	AddIn.MakeBarcode(XMLGenerationParameters, XMLResult);
	
	// Result 
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("BinaryData");
	OperationResult.Insert("Picture");
	
	If Not IsBlankString(XMLResult) Then
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLResult);
		XMLReader.MoveToContent();
		ParameterAttributes = Undefined;
		If XMLReader.Name = "MakeBarcodeResult" And XMLReader.NodeType = XMLNodeType.StartElement Then
			While XMLReader.Read() Do  
				If XMLReader.Name = "Result" And XMLReader.NodeType = XMLNodeType.StartElement And XMLReader.Read() Then
					OperationResult.Result = Number(XMLReader.Value) = 0;
				ElsIf XMLReader.Name = "ImageBase64" And XMLReader.NodeType = XMLNodeType.StartElement And XMLReader.Read() Then  
					PictureBase64 = XMLReader.Value;    
					BinaryPictureData = Base64Value(PictureBase64);   
					// 
					If BinaryPictureData <> Undefined Then
						OperationResult.BinaryData = BinaryPictureData;
						OperationResult.Picture = New Picture(BinaryPictureData); // 
					EndIf;
				EndIf; 
			EndDo;
		EndIf;  
	EndIf; 
	
	Return OperationResult;
	
EndFunction

// Prepare barcode images.
//
// Parameters: 
//   AddIn - See BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters
//
// Returns: 
//   Structure:
//      The result is a Boolean-the result of barcode generation.
//      Binary Data-Binary Data - Binary barcode image data.
//      Picture-Picture - picture with the generated barcode or UNDEFINED.
//
Function PrepareBarcodeImageOfProperty(AddIn, BarcodeParameters)
	
	// Result 
	OperationResult = New Structure();
	OperationResult.Insert("Result", False);
	OperationResult.Insert("BinaryData");
	OperationResult.Insert("Picture");
	
	// 
	TheWidthOfTheBarcode = Round(BarcodeParameters.Width);
	TheHeightOfTheBarcode = Round(BarcodeParameters.Height);
	If TheWidthOfTheBarcode <= 0 Then
		TheWidthOfTheBarcode = 1
	EndIf;
	If TheHeightOfTheBarcode <= 0 Then
		TheHeightOfTheBarcode = 1
	EndIf;
	AddIn.Width = TheWidthOfTheBarcode;
	AddIn.Height = TheHeightOfTheBarcode;
	AddIn.AutoType = False;
	
	TimeBarcode = String(BarcodeParameters.Barcode); // 
	
	If BarcodeParameters.CodeType = 99 Then
		AddIn.AutoType = True;
	Else
		AddIn.AutoType = False;
		AddIn.CodeType = BarcodeParameters.CodeType;
	EndIf;
	
	If BarcodeParameters.Property("Transparent") Then
		AddIn.BgTransparent = BarcodeParameters.BgTransparent;
	EndIf;
	
	If BarcodeParameters.Property("InputDataType") Then
		AddIn.InputDataType = BarcodeParameters.InputDataType;
	EndIf;
	
	If BarcodeParameters.Property("GS1DatabarRowsCount") Then
		AddIn.GS1DatabarRowCount = BarcodeParameters.GS1DatabarRowsCount;
	EndIf;
	
	If BarcodeParameters.Property("RemoveExtraBackgroud") Then
		AddIn.RemoveExtraBackgroud = BarcodeParameters.RemoveExtraBackgroud;
	EndIf;
	
	AddIn.TextVisible = BarcodeParameters.ShowText;
	// 
	AddIn.CodeValue = TimeBarcode;
	// 
	AddIn.CanvasRotation = ?(BarcodeParameters.Property("CanvasRotation"), BarcodeParameters.CanvasRotation, 0);
	// 
	AddIn.QRErrorCorrectionLevel = ?(BarcodeParameters.Property("QRErrorCorrectionLevel"), BarcodeParameters.QRErrorCorrectionLevel, 1);
	
	// 
	If Not BarcodeParameters.Property("Zoomable")
		Or (BarcodeParameters.Property("Zoomable") And BarcodeParameters.Zoomable) Then
		
		If Not BarcodeParameters.Property("MaintainAspectRatio")
				Or (BarcodeParameters.Property("MaintainAspectRatio") And Not BarcodeParameters.MaintainAspectRatio) Then
			// 
			If AddIn.Width < AddIn.CodeMinWidth Then
				AddIn.Width = AddIn.CodeMinWidth;
			EndIf;
			// 
			If AddIn.Height < AddIn.CodeMinHeight Then
				AddIn.Height = AddIn.CodeMinHeight;
			EndIf;
		ElsIf BarcodeParameters.Property("MaintainAspectRatio") And BarcodeParameters.MaintainAspectRatio Then
			While AddIn.Width < AddIn.CodeMinWidth 
				Or AddIn.Height < AddIn.CodeMinHeight Do
				// 
				If AddIn.Width < AddIn.CodeMinWidth Then
					AddIn.Width = AddIn.CodeMinWidth;
					AddIn.Height = Round(AddIn.CodeMinWidth / TheWidthOfTheBarcode) * TheHeightOfTheBarcode;
				EndIf;
				// 
				If AddIn.Height < AddIn.CodeMinHeight Then
					AddIn.Height = AddIn.CodeMinHeight;
					AddIn.Width = Round(AddIn.CodeMinHeight / TheHeightOfTheBarcode) * TheWidthOfTheBarcode;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	// 
	If BarcodeParameters.Property("VerticalAlignment") And (BarcodeParameters.VerticalAlignment > 0) Then
		AddIn.CodeVerticalAlign = BarcodeParameters.VerticalAlignment;
	EndIf;
	
	If BarcodeParameters.Property("FontSize") And (BarcodeParameters.FontSize > 0) 
		And (BarcodeParameters.ShowText) And (AddIn.FontSize <> BarcodeParameters.FontSize) Then
			AddIn.FontSize = BarcodeParameters.FontSize;
	EndIf;
	
	If BarcodeParameters.CodeType = 16 Then // QR
		If BarcodeParameters.Property("LogoImage") And ValueIsFilled(BarcodeParameters.LogoImage) Then 
			AddIn.LogoImage = BarcodeParameters.LogoImage;    
		Else
			AddIn.LogoImage = "";
		EndIf;
		If BarcodeParameters.Property("LogoSizePercentFromBarcode") And Not IsBlankString(BarcodeParameters.LogoSizePercentFromBarcode) Then 
			AddIn.LogoSizePercentFromBarcode = BarcodeParameters.LogoSizePercentFromBarcode;
		EndIf;
	EndIf;
		
	// 
	BinaryPictureData = AddIn.GetBarcode();
	OperationResult.Result = AddIn.Result = 0;
	// 
	If BinaryPictureData <> Undefined Then
		OperationResult.BinaryData = BinaryPictureData;
		OperationResult.Picture = New Picture(BinaryPictureData); // 
	EndIf;
	
	Return OperationResult;
	
EndFunction

Function ModuleCommon()
	
	If Metadata.Subsystems.Find("EquipmentSupport") = Undefined Then
		// 
		Return Eval("Common");
		// 
	Else
		Return Eval("CommonCEL");
	EndIf;
	
EndFunction

#EndRegion