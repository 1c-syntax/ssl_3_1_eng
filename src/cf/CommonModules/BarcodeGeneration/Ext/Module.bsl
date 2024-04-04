///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// A blank structure for filling the "BarcodeParameters" parameter that is used for receiving a barcode image.
// 
// Returns:
//   Structure:
//   * Width - Number - width of a barcode image.
//   * Height - Number - height of a barcode image.
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
//   * ShowText - Boolean - display the HRI text for a barcode.
//   * FontSize - Number - font size of the HRI text for a barcode.
//   * CanvasRotation - Number - rotation angle.
//      Possible values: 0, 90, 180, 270.
//   * Barcode - String - a barcode value as a row or Base64.
//   * InputDataType - Number - input data type 
//      Possible values: 0 - Row, 1 - Base64
//   * BgTransparent - Boolean - transparent background of a barcode image.
//   * QRErrorCorrectionLevel - Number - correction level of the QR barcode.
//      Possible values: 0 - L, 1 - M, 2 - Q, 3 - H.
//   * Zoomable - Boolean -  scale a barcode image.
//   * MaintainAspectRatio - Boolean - save proportions of a barcode image.                                                              
//   * VerticalAlignment - Number - vertical alignment of a barcode.
//      Possible values: 1 - Top, 2 - Center, 3 - Bottom
//   * GS1DatabarRowsCount - Number - a number of rows in the GS1Databar barcode.
//   * RemoveExtraBackgroud - Boolean
//   * LogoImage - String - a string with base64 presentation of a PNG logo image.
//   * LogoSizePercentFromBarcode - Number - a percentage of the generated QR code to add a logo.
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

// Barcode image generation.
//
// Parameters: 
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters.
//
// Returns: 
//   Structure:
//      Result - Boolean - barcode generation result.
//      BinaryData - BinaryData - binary data of a barcode image.
//      Picture - Picture - a picture with the generated barcode or UNDEFINED.
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
//  QRString         - String - data to be placed in the QR code.
//
//  CorrectionLevel - Number - an image defect level, at which it is still possible to completely recognize this QR
//                             code.
//                     The parameter must have an integer type and have one of the following possible values:
//                     0 (7% defect allowed), 1 (15% defect allowed), 2 (25% defect allowed), 3 (35% defect allowed).
//
//  Size           - Number - determines the size of the output image side, in pixels.
//                     If the smallest possible image size is greater than this parameter, the code is not generated.
//
// Returns:
//  BinaryData  - a buffer that contains the bytes of the QR code image in PNG format.
// 
// Example:
//  
//  // Printing a QR code containing information encrypted according to UFEBM.
//
//  QRString = PrintManagement.UFEBMFormatString(PaymentDetails);
//  ErrorText = "";
//  QRCodeData = AccessManagement.QRCodeData(QRString, 0, 190, ErrorText);
//  If Not BlankString (ErrorText)
//      Common.MessageToUser(ErrorText);
//  EndIf;
//
//  QRCodePicture = New Picture(QRCodeData);
//  TemplateArea.Pictures.QRCode.Picture = QRCodePicture;
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

// Attaches the add-in.
//
// Returns: 
//   AddInObject
//   Undefined - if failed to import the add-in.
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
		// Set as the picture font.
		AddIn.Font = "Tahoma";
	Else
		// 
		// 
		For Cnt = 0 To AddIn.FontCount -1 Do
			// Get another available font.
			CurrentFont = AddIn.FontAt(Cnt);
			// Search for the font.
			If CurrentFont <> Undefined Then
				// Set as the barcode font.
				AddIn.Font = CurrentFont;
				Break;
			EndIf;
		EndDo;
	EndIf;
	// Set the font size.
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
 // Prepare a barcode image.
//
// Parameters: 
//   AddIn - See BarcodeGenerationServerCached.ToConnectAComponentGeneratingAnImageOfTheBarcode
//   BarcodeParameters - See BarcodeGeneration.BarcodeGenerationParameters
//
// Returns: 
//   Structure:
//      Result - Boolean - a barcode generation result.
//      BinaryData - BinaryData - binary data of a barcode image.
//      Picture - Picture - a picture with the generated barcode or UNDEFINED.
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
	
	// Result. 
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
					// If the picture is generated successfully.
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