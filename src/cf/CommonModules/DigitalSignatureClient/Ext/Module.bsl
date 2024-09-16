///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the current setting for using electronic signatures.
//
// Returns:
//  Boolean - 
//
Function UseDigitalSignature() Export
	
	Return CommonSettings().UseDigitalSignature;
	
EndFunction

// Returns the current encryption usage setting.
//
// Returns:
//  Boolean - 
//
Function UseEncryption() Export
	
	Return CommonSettings().UseEncryption;
	
EndFunction

// Returns the current setting for verifying electronic signatures on the server.
//
// Returns:
//  Boolean - 
//
Function VerifyDigitalSignaturesOnTheServer() Export
	
	Return CommonSettings().VerifyDigitalSignaturesOnTheServer;
	
EndFunction

// Returns the current setting for creating electronic signatures on the server.
// The configuration also involves encryption and decryption on the server.
//
// Returns:
//  Boolean - 
//
Function GenerateDigitalSignaturesAtServer() Export
	
	Return CommonSettings().GenerateDigitalSignaturesAtServer;
	
EndFunction

// Signs the data, returns the signature, and adds the signature to the object, if specified.
//
// A General approach to processing property values with the message Description type in the data Description parameter.
//  When processing an alert, a parameter structure is passed to it, which always has
//  the "Alert" property of the message Description type, which must be processed in order to continue.
//  In addition, the structure always has a data Descriptionproperty that is obtained when calling the procedure.
//  When calling an alert, a structure must be passed as the value. If an
//  error occurs during asynchronous execution, then insert the error Descriptionproperty of the String type into this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String -  header of the data signing form, such as file Signing.
//    * DataTitle      - String -  title of an element or data set, such as a File.
//    * NotifyOnCompletion  - Boolean - 
//                           
//    * ShowComment  - Boolean -  (optional) - allows entering a comment in
//                           the data signing form. If omitted, it means False.
//    * CertificatesFilter    - Array -  (optional) - contains links to directory elements.
//                           Electronic signature decryption certificates that can be selected
//                           by the user. Selection blocks the ability to select other certificates
//                           from the personal storage.
//                           - Structure:
//                             * Organization - DefinedType.Organization -  contains a link to the company
//                                 for which the selection will be set in the list of user certificates.
//    * NoConfirmation     - Boolean - 
//                           :
//                           
//                           
//                           
//                           
//                           
//    * BeforeExecute     - NotifyDescription - 
//                           
//                           
//                           
//                           
//                           
//                           
//    * ExecuteAtServer   - Undefined
//                           - Boolean - 
//                           
//                           
//                           
//                           
//                           
//    * AdditionalActionParameters - Arbitrary -  (optional) - if specified, it is passed
//                           to the server in the procedure for pre-Moderation of the shared module
//                           The electronic signature is defined as input Parameters.
//    * OperationContext     - Undefined - 
//                           
//                            
//                           
//                           
//                           
//                           - Arbitrary - 
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//    * StopExecution - Arbitrary -  if the property exists and an error occurs during asynchronous execution
//                           , execution stops without displaying the operation form or closing this form
//                           if it was open.
//
//    Option 1.
//    * Data              - BinaryData -  data for signing.
//                          - String - 
//                          - NotifyDescription - 
//                          
//                          
//                          - Structure:
//                             * XMLEnvelope       - See DigitalSignatureClient.XMLEnvelope
//                             * XMLDSigParameters - See DigitalSignatureClient.XMLDSigParameters
//                          - Structure:
//                             * CMSParameters - See DigitalSignatureClient.CMSParameters
//                             * Data  - String -  custom string for signing,
//                                       - BinaryData - 
//    * Object              - AnyRef -  (optional) - a reference to the object to add the signature to.
//                          If omitted, the signature does not need to be added.
//                          - NotifyDescription - 
//                          
//                          
//                          
//                          
//    * ObjectVersion       - String -  (optional) - the version of the object data to check and
//                          lock the object before adding a signature.
//    * Presentation       - AnyRef -  (optional), if the parameter is not specified,
//                                  then the representation is calculated by the value of the Object property.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - NotifyDescription - 
//                             ** Presentation - String -  representation of the value.
//    Option 2.
//    * DataSet         - Array -  structures with the properties described in Option 1.
//    * SetPresentation - String -  representations of multiple data set elements, such as " Files (%1)".
//                          In this view, the %1 parameter is filled with the number of elements.
//                          You can use the hyperlink to open the list.
//                          If the dataset 1 element, then use the value
//                          in the property View properties Nabetani, if not specified, then
//                          performance is calculated on the value of the item Object of the data set.
//    * PresentationsList - ValueList
//                          - Array - 
//                          
//                          
//                          
//
//  Form - ClientApplicationForm -  a form from which you need to get a unique identifier
//                                that will be used when blocking an object.
//        - UUID - 
//                                
//        - Undefined     - 
//
//  ResultProcessing - NotifyDescription -
//     
//     :
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
//                        * SignatureType  - EnumRef.CryptographySignatureTypes
//                        * DateActionLastTimestamp - Date, Undefined - 
//                                                                                   
//                        * DateSignedFromLabels - Date, Undefined - 
//                        * UnverifiedSignatureDate - Date - 
//                        * Certificate  - BinaryData - 
//                        * Thumbprint           - String -  the thumbprint of the certificate in Base64 string format.
//                        * CertificateOwner - String -  
//         
//                       
//  SignatureParameters - See NewSignatureType
//
Procedure Sign(DataDetails, Form = Undefined, ResultProcessing = Undefined, SignatureParameters = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			DataDetails.OperationContext.PerformSigning(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("en = 'Data signing';"));
	ServerParameters1.Insert("DataTitle",     NStr("en = 'Data';"));
	ServerParameters1.Insert("ShowComment", False);
	ServerParameters1.Insert("CertificatesFilter");
	ServerParameters1.Insert("ExecuteAtServer");
	ServerParameters1.Insert("AdditionalActionParameters");
	ServerParameters1.Insert("NotifyOfCertificateAboutToExpire", True);
	FillPropertyValues(ServerParameters1, DataDetails);
	
	ServerParameters1.Insert("SignatureType", SignatureParameters);
	
	DigitalSignatureInternalClient.OpenNewForm("DataSigning",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// 
// 
// 
// Parameters:
//  SignatureType - EnumRef.CryptographySignatureTypes
// 
// Returns:
//  Structure:
//   * SignatureTypes - Array - 
//   * Visible - Boolean - 
//   * Enabled - Boolean - 
//   * CanSelectLetterOfAuthority - Boolean - 
//   * VerifyCertificate - String - :
//        
//                                      
//       
//                                   
//       
//
Function NewSignatureType(SignatureType = Undefined) Export
	
	Structure = New Structure;
	Structure.Insert("SignatureTypes", New Array);
	Structure.Insert("Visible", False);
	Structure.Insert("Enabled", False);
	Structure.Insert("CanSelectLetterOfAuthority", False);
	Structure.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.CheckQualified());
	
	If ValueIsFilled(SignatureType) Then
		Structure.SignatureTypes.Add(SignatureType);
	EndIf;
	
	Return Structure;
	
EndFunction

// Prompts the user to select the signature files to add to the object and adds them.
//
// A General approach to processing property values with the message Description type in the data Description parameter.
//  When processing an alert, a parameter structure is passed to it, which always has
//  the "Alert" property of the message Description type, which must be processed in order to continue.
//  In addition, the structure always has a data Descriptionproperty that is obtained when calling the procedure.
//  When calling an alert, a structure must be passed as the value. If an
//  error occurs during asynchronous execution, then insert the error Descriptionproperty of the String type into this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * DataTitle      - String -  title of the data element, such as a File.
//    * ShowComment  - Boolean -  (optional) - allows you to enter
//                             a comment in the caption form. If omitted, it means False.
//    * Object               - AnyRef -  (optional) - a reference to the object to add the signature to.
//                           - NotifyDescription - 
//                             
//                             
//    * ObjectVersion        - String -  (optional) - the version of the object data to check and
//                             lock the object before adding a signature.
//    * Presentation        - AnyRef
//                           - String - 
//                             
//    * Data               - BinaryData -  (optional) - data for signature verification.
//                           - String - 
//                           - NotifyDescription - 
//                             
//
//  Form - ClientApplicationForm -  a form from which you need to get a unique identifier
//        that will be used when blocking an object.
//        - UUID - 
//        
//        - Undefined - 
//
//  ResultProcessing - NotifyDescription -
//     
//     :
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
Procedure AddSignatureFromFile(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	DataDetails.Insert("Success", False);
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("DataTitle", NStr("en = 'Data';"));
	ServerParameters1.Insert("ShowComment", False);
	FillPropertyValues(ServerParameters1, DataDetails);
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails",      DataDetails);
	ClientParameters.Insert("Form",               Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	DigitalSignatureInternalClient.SetDataPresentation(ClientParameters, ServerParameters1);
	
	AdditionForm = OpenForm("CommonForm.AddDigitalSignatureFromFile", ServerParameters1,,,,,
		New NotifyDescription("RegularlyCompletion", DigitalSignatureInternalClient, ClientParameters));
	
	If AdditionForm = Undefined Then
		If ResultProcessing <> Undefined Then
			ExecuteNotifyProcessing(ResultProcessing, DataDetails);
		EndIf;
		Return;
	EndIf;
	
	AdditionForm.ClientParameters = ClientParameters;
	
	Context = New Structure;
	Context.Insert("ResultProcessing", ResultProcessing);
	Context.Insert("AdditionForm", AdditionForm);
	Context.Insert("CheckCryptoManagerAtClient", True);
	Context.Insert("DataDetails", DataDetails);
	
	If (VerifyDigitalSignaturesOnTheServer()
		Or GenerateDigitalSignaturesAtServer())
		And Not ValueIsFilled(AdditionForm.CryptographyManagerOnServerErrorDescription) Then
		
		Context.CheckCryptoManagerAtClient = False;
		DigitalSignatureInternalClient.AddSignatureFromFileAfterCreateCryptoManager(
			Undefined, Context);
	Else
		
		CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
		CreationParameters.ShowError = Undefined;
		
		DigitalSignatureInternalClient.CreateCryptoManager(
			New NotifyDescription("AddSignatureFromFileAfterCreateCryptoManager",
				DigitalSignatureInternalClient, Context),
			"", CreationParameters);
			
	EndIf;
	
EndProcedure

// Prompts the user to select signatures to save along with the object data.
//
// A General approach to processing property values with the message Description type in the data Description parameter.
//  When processing an alert, a parameter structure is passed to it, which always has
//  the "Alert" property of the message Description type, which must be processed in order to continue.
//  In addition, the structure always has a data Descriptionproperty that is obtained when calling the procedure.
//  When calling an alert, a structure must be passed as the value. If an
//  error occurs during asynchronous execution, then insert the error Descriptionproperty of the String type into this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * DataTitle      - String -  title of the data element, such as a File.
//    * ShowComment  - Boolean -  (optional) - allows you to enter
//                           a comment in the caption form. If omitted, it means False.
//    * Presentation        - AnyRef
//                           - String - 
//                           
//    * Object               - AnyRef -  link to the object to get the list of signatures from.
//                           - String - 
//                           
//    * Data               - NotifyDescription - 
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
//  ResultProcessing - NotifyDescription -
//     A Boolean -True parameter is passed to the result if everything was successful.
//
Procedure SaveDataWithSignature(DataDetails, ResultProcessing = Undefined) Export
	
	DigitalSignatureInternalClient.SaveDataWithSignature(DataDetails, ResultProcessing);
	
EndProcedure

// Checks the validity of the signature and certificate.
// The certificate is always checked on the server if the administrator
// has configured electronic signature verification on the server.
//
// Parameters:
//   Notification           - NotifyDescription - :
//             
//             
//             
//             See DigitalSignatureClientServer.SignatureVerificationResult
//             
//   RawData       - BinaryData -  binary data that has been signed.
//                          Mathematical verification is performed on the client side, even when
//                          the administrator has configured the verification of electronic signatures on the server,
//                          if a cryptography manager is specified or it was obtained without error.
//                          This improves performance as well as security when the signature
//                          in the decrypted file is verified (it will not be transmitted to the server).
//                        - String - 
//                        - Structure:
//                           * XMLEnvelope       - String -  signed envelopexml,
//                                                         see also the envelopexml function.
//                           * XMLDSigParameters - See DigitalSignatureClient.XMLDSigParameters
//                        - Structure:
//                           * CMSParameters - See DigitalSignatureClient.CMSParameters
//                           * Data  - String -  custom string for signing,
//                                     - BinaryData - 
//   Signature              - BinaryData -  binary data of the electronic signature.
//                        - String         - 
//                        - Undefined   - 
//   CryptoManager - Undefined -  get the default cryptography Manager
//                          (Manager of the first program in the list, as configured by the administrator).
//                        - CryptoManager - 
//   OnDate               - Date - 
//                          
//                          
//                          
//   CheckParameters    - See SignatureVerificationParameters
//                        
//
Procedure VerifySignature(Notification, RawData, Signature,
	CryptoManager = Undefined,
	OnDate = Undefined,
	CheckParameters = Undefined) Export
	
	DigitalSignatureInternalClient.VerifySignature(
		Notification, RawData, Signature, CryptoManager, OnDate, CheckParameters);
	
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * ShowCryptoManagerCreationError - Boolean -  
//              
//   * ResultAsStructure - Boolean - 
//      See DigitalSignatureClientServer.SignatureVerificationResult
//   * VerifyCertificate - String - 
//      
//        
//                                      
//       
//                                   
//       
//
Function SignatureVerificationParameters() Export
	
	Structure = New Structure;
	Structure.Insert("ShowCryptoManagerCreationError", True);
	Structure.Insert("ResultAsStructure", False);
	Structure.Insert("VerifyCertificate", DigitalSignatureInternalClientServer.CheckQualified());
	
	Return Structure;
	
EndFunction

// Encrypts data, returns encryption certificates, and adds them to the object, if specified.
// 
// A General approach to processing property values with the message Description type in the data Description parameter.
//  When processing an alert, a parameter structure is passed to it, which always has
//  the "Alert" property of the message Description type, which must be processed in order to continue.
//  In addition, the structure always has a data Descriptionproperty that is obtained when calling the procedure.
//  When calling an alert, a structure must be passed as the value. If an
//  error occurs during asynchronous execution, then insert the error Descriptionproperty of the String type into this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String -  header of the data encryption form, such as file Encryption.
//    * DataTitle      - String -  title of an element or data set, such as a File.
//    * NotifyOnCompletion  - Boolean -  (optional) - if False, it will not be shown the notification about successful
//                           the completion of the operation to present information that is specified next to the title.
//    * CertificatesSet    - String -  (optional) address of the temporary storage containing the array described below.
//                           - Array - 
//                           
//                           
//                           - AnyRef - 
//    * ChangeSet        - Boolean -  if True and the set of Certificates is set and contains only references
//                           to certificates, then you will be able to change the composition of certificates.
//    * NoConfirmation     - Boolean -  (optional) - skip the user for confirmation
//                           if you specify a property Ombrellificio.
//    * ExecuteAtServer   - Undefined
//                           - Boolean - 
//                           
//                           
//                           
//                           
//                           
//    * OperationContext     - Undefined -  (optional) - if specified, then the property will
//                           be set to a specific value of any type that allows
//                           you to perform the action with the same encryption certificates again (the user
//                           is not asked to confirm the action).
//                           - Arbitrary - 
//                           
//                           
//                           
//                           
//    * StopExecution - Arbitrary -  if the property exists and an error occurs during asynchronous execution
//                           , execution stops without displaying the operation form or closing this form
//                           if it was open.
//
//    Option 1.
//    * Data                - BinaryData -  data for encryption.
//                            - String - 
//                            - NotifyDescription - 
//                            
//    * ResultPlacement  - Undefined -  (optional) - describes where to put the encrypted data.
//                            If omitted or Undefined, then use the result Processing parameter.
//                            - NotifyDescription - 
//                            
//                            
//                            
//                            
//    * Object                - AnyRef -  (optional) - a reference to the object to be encrypted.
//                            If omitted, you do not need to add encryption certificates.
//    * ObjectVersion         - String -  (optional) - the version of object data to check and
//                            lock the object before adding encryption certificates.
//    * Presentation       - AnyRef -  (optional), if the parameter is not specified,
//                                  then the representation is calculated by the value of the Object property.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - NotifyDescription - 
//                             ** Presentation - String -  representation of the value.
//
//    Option 2.
//    * DataSet           - Array -  structures with the properties described in Option 1.
//    * SetPresentation   - String -  representations of multiple data set elements, such as " Files (%1)".
//                            In this view, the %1 parameter is filled with the number of elements.
//                            You can use the hyperlink to open the list.
//                            If the dataset 1 element, then use the value
//                            in the property View properties Nabetani, if not specified, then
//                            performance is calculated on the value of the item Object of the data set.
//    * PresentationsList   - ValueList
//                            - Array - 
//                            
//                            
//                            
//
//  Form - ClientApplicationForm  -  a form from which you need to get a unique identifier that will
//        be used when placing encrypted data in temporary storage.
//        - UUID - 
//        
//        - Undefined      - 
//
//  ResultProcessing - NotifyDescription -
//     
//     :
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
Procedure Encrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataEncryption" Then
			DataDetails.OperationContext.ExecuteEncryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("en = 'Data encryption';"));
	ServerParameters1.Insert("DataTitle",     NStr("en = 'Data';"));
	ServerParameters1.Insert("CertificatesSet");
	ServerParameters1.Insert("ChangeSet");
	ServerParameters1.Insert("ExecuteAtServer");
	FillPropertyValues(ServerParameters1, DataDetails);
	
	DigitalSignatureInternalClient.OpenNewForm("DataEncryption",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// Decrypts data, returns it, and puts it in an object, if specified.
// 
// A General approach to processing property values with the message Description type in the data Description parameter.
//  When processing an alert, a parameter structure is passed to it, which always has
//  the "Alert" property of the message Description type, which must be processed in order to continue.
//  In addition, the structure always has a data Descriptionproperty that is obtained when calling the procedure.
//  When calling an alert, a structure must be passed as the value. If an
//  error occurs during asynchronous execution, then insert the error Descriptionproperty of the String type into this structure.
// 
// Parameters:
//  DataDetails - Structure:
//    * Operation             - String -  header of the data decryption form, for example, file Decryption.
//    * DataTitle      - String -  title of an element or data set, such as a File.
//    * NotifyOnCompletion  - Boolean - 
//                           
//    * CertificatesFilter    - Array -  (optional) - contains links to directory elements.
//                           Electronic signature decryption certificates that can be selected
//                           by the user. Selection blocks the ability to select other certificates
//                           from the personal storage.
//    * NoConfirmation     - Boolean - 
//                           :
//                           
//                           
//                           
//                           
//                           
//    * IsAuthentication    - Boolean -  (optional) - if True,
//                           the OK button will be displayed instead of the Decrypt button. Also, some labels have been corrected.
//                           In addition, the report Completion parameter is set to False.
//    * BeforeExecute     - NotifyDescription -  (optional) - description of the handler for additional
//                           data preparation after selecting the certificate with which the data will be decrypted.
//                           In this handler, you can fill in the Data parameter, if necessary.
//                           At the time of the call, the selected certificate has already been inserted into the data description, as the selected certificate
//                           (see below). The general approach should be taken into account (see above).
//    * ExecuteAtServer   - Undefined
//                           - Boolean - 
//                           
//                           
//                           
//                           
//                           
//    * AdditionalActionParameters - Arbitrary -  (optional) - if specified, it is passed
//                           to the server in the procedure for pre-Moderation of the shared module.
//                           The electronic signature is undefined as input Parameters.
//    * OperationContext     - Undefined - 
//                           
//                            
//                           
//                           
//                           
//                           - Arbitrary - 
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//                           
//    * StopExecution - Arbitrary -  if the property exists and an error occurs during asynchronous execution
//                           , execution stops without displaying the operation form or closing this form
//                           if it was open.
// 
//    Option 1.
//    * Data                - BinaryData -  data to decrypt.
//                            - String - 
//                            - NotifyDescription - 
//                            
//                            
//    * ResultPlacement  - Undefined -  (optional) - describes where to put the decrypted data.
//                            If omitted or Undefined, then use the result Processing parameter.
//                            - NotifyDescription - 
//                            
//                            
//                            
//                            
//    * Object                - AnyRef -  (optional) - a reference to the object that you want to decrypt,
//                            and also clear record of the information register of Certificatesfree
//                            after successful completion of the decryption.
//                            If omitted, certificates do not need to be retrieved from the object and cleared.
//                            - String - 
//                              
//                                 
//                                 
//                                                     
//                                 
//                                                     
//    * Presentation       - AnyRef -  (optional), if the parameter is not specified,
//                                  then the representation is calculated by the value of the Object property.
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - NotifyDescription - 
//                             ** Presentation - String -  representation of the value.
// 
//    Option 2.
//    * DataSet           - Array -  structures with the properties described in Option 1.
//    * SetPresentation   - String -  representations of multiple data set elements, such as " Files (%1)".
//                            In this view, the %1 parameter is filled with the number of elements.
//                            You can use the hyperlink to open the list.
//                            If the dataset 1 element, then use the value
//                            in the property View properties Nabetani, if not specified, then
//                            performance is calculated on the value of the item Object of the data set.
//    * PresentationsList   - ValueList
//                            - Array - 
//                            
//                            
//                            
//    * EncryptionCertificates - Array -  (optional) values like the Object parameter. Used
//                            to extract lists of encryption certificates for items specified
//                            in the list of Representations parameter (the order must match).
//                            When specified, the Object parameter is not used.
//
//  Form - ClientApplicationForm -  a form from which you need to get a unique identifier that will
//        be used when placing decrypted data in temporary storage.
//        - UUID - 
//        
//        - Undefined - 
//
//  ResultProcessing - NotifyDescription -
//     
//     :
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
Procedure Decrypt(DataDetails, Form = Undefined, ResultProcessing = Undefined) Export
	
	ClientParameters = New Structure;
	ClientParameters.Insert("DataDetails", DataDetails);
	ClientParameters.Insert("Form", Form);
	ClientParameters.Insert("ResultProcessing", ResultProcessing);
	
	CompletionProcessing = New NotifyDescription("RegularlyCompletion",
		DigitalSignatureInternalClient, ClientParameters);
	
	If DataDetails.Property("OperationContext")
	   And TypeOf(DataDetails.OperationContext) = Type("ClientApplicationForm") Then
		
		DigitalSignatureInternalClient.ExtendStoringOperationContext(DataDetails);
		FormNameBeginning = "Catalog.DigitalSignatureAndEncryptionKeysCertificates.Form.";
		
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataDecryption" Then
			DataDetails.OperationContext.ExecuteDecryption(ClientParameters, CompletionProcessing);
			Return;
		EndIf;
		If DataDetails.OperationContext.FormName = FormNameBeginning + "DataSigning" Then
			ClientParameters.Insert("SpecifiedContextOfOtherOperation");
		EndIf;
	EndIf;
	
	ServerParameters1 = New Structure;
	ServerParameters1.Insert("Operation",            NStr("en = 'Data decryption';"));
	ServerParameters1.Insert("DataTitle",     NStr("en = 'Data';"));
	ServerParameters1.Insert("CertificatesFilter");
	ServerParameters1.Insert("EncryptionCertificates");
	ServerParameters1.Insert("IsAuthentication");
	ServerParameters1.Insert("ExecuteAtServer");
	ServerParameters1.Insert("AdditionalActionParameters");
	ServerParameters1.Insert("AllowRememberPassword");
	FillPropertyValues(ServerParameters1, DataDetails);
	
	If DataDetails.Property("Data") Then
		If TypeOf(ServerParameters1.EncryptionCertificates) <> Type("Array")
		   And DataDetails.Property("Object") Then
			
			ServerParameters1.Insert("EncryptionCertificates", DataDetails.Object);
		EndIf;
		
	ElsIf TypeOf(ServerParameters1.EncryptionCertificates) <> Type("Array") Then
		
		ServerParameters1.Insert("EncryptionCertificates", New Array);
		For Each DataElement In DataDetails.DataSet Do
			If DataElement.Property("Object") Then
				ServerParameters1.EncryptionCertificates.Add(DataElement.Object);
			Else
				ServerParameters1.EncryptionCertificates.Add(Undefined);
			EndIf;
		EndDo;
	EndIf;
	
	DigitalSignatureInternalClient.OpenNewForm("DataDecryption",
		ClientParameters, ServerParameters1, CompletionProcessing);
	
EndProcedure

// 
//
// Parameters:
//  DataDetails - Structure:
//    * SignatureType          - EnumRef.CryptographySignatureTypes - 
//                           
//                           
//    * AddArchiveTimestamp - Boolean - 
//                           
//   
//    * Signature             - BinaryData - 
//                          - String - 
//                          - Structure:
//                             ** SignedObject - AnyRef - 
//                             ** SequenceNumber - Number -  serial number of the signature.
//                                                - Array - 
//                                                - Undefined - 
//                             ** Signature - BinaryData - 
//                                        
//                                        - String - 
//                                                         
//                          - Array of BinaryData
//                          - Array of String - 
//                          - Array of Structure - 
//   
//    * Presentation       - AnyRef - 
//                                  
//                          - String
//                          - Structure:
//                             ** Value      - AnyRef
//                                              - NotifyDescription - 
//                             ** Presentation - String - 
//                          - ValueList
//                          - Array - 
//                          
//                          
//                          
//
//  Form - ClientApplicationForm -  a form from which you need to get a unique identifier
//                                that will be used when blocking an object.
//        - UUID - 
//                                
//
//  AbortArrayProcessingOnError  - Boolean - 
//  ShouldIgnoreCertificateValidityPeriod - Boolean - 
//                                                 
//
//  
//     
//     :
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
//                           See DigitalSignatureClientServer.NewSignatureProperties
//                             
//                          
//                           
//                        
//
Procedure EnhanceSignature(DataDetails, Form, ResultProcessing = Undefined,
	AbortArrayProcessingOnError = True, ShouldIgnoreCertificateValidityPeriod = False) Export
	
	Context = New Structure;
	Context.Insert("ResultProcessing", ResultProcessing);
	
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("DataDetails",      DataDetails);
	If TypeOf(Form) = Type("ClientApplicationForm") Then
		ExecutionParameters.Insert("FormIdentifier", Form.UUID);
	Else
		ExecutionParameters.Insert("FormIdentifier", Form);
	EndIf;
	ExecutionParameters.Insert("AbortArrayProcessingOnError",  AbortArrayProcessingOnError);
	ExecutionParameters.Insert("ShouldIgnoreCertificateValidityPeriod", ShouldIgnoreCertificateValidityPeriod);
		
	Context.Insert("ExecutionParameters", ExecutionParameters);
	
	DigitalSignatureInternalClient.EnhanceSignature(Context);

EndProcedure

// Checks the validity of the cryptography certificate.
//
// Parameters:
//   Notification           - NotifyDescription -  notification of the result of the following types of execution
//             = Boolean       - True if the check is successful.
//             = String - description of the certificate verification error.
//             = Undefined - failed to get a cryptography manager (when not specified).
//
//   Certificate           - CryptoCertificate -  certificate.
//                        - BinaryData -  binary data of the certificate.
//                        - String - 
//
//   CryptoManager - Undefined -  to the Manager of the cryptographic automatically.
//                        - CryptoManager - 
//                          
//
//   OnDate               - Date -  check the certificate for the specified date.
//                          If the parameter is omitted or an empty date is specified,
//                          then check for the current session date.
//   CheckParameters - See CertificateVerificationParameters.
//
Procedure CheckCertificate(Notification, Certificate, CryptoManager = Undefined, OnDate = Undefined, CheckParameters = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCertificate(Notification, Certificate, CryptoManager, OnDate, CheckParameters);
	
EndProcedure

// 
// 
// Returns:
//  Structure - :
//   * PerformCAVerification - String - :
//        
//                                      
//       
//                                   
//       
//   * IgnoreCertificateRevocationStatus - Boolean - 
//
Function CertificateVerificationParameters() Export
	
	Structure = New Structure;
	Structure.Insert("IgnoreCertificateRevocationStatus", False);
	Structure.Insert("PerformCAVerification", DigitalSignatureInternalClientServer.CheckQualified());
	Return Structure;
	
EndFunction

// Opens the certificate Verification form and returns the verification result.
//
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the certificate to verify.
//
//  AdditionalParameters - Undefined -  normal certificate verification.
//                          - Structure - :
//    * FormOwner          - ClientApplicationForm -  other form.
//    * FormCaption         - String -  if specified, then replaces the form header.
//    * CheckOnSelection      - Boolean -  if True, then the Check button will be called
//                             "Check and continue" and the Close button will be called "Cancel".
//    * ResultProcessing    - NotifyDescription -  called immediately after verification,
//                             the result is passed to the procedure.The checks are passed (see below) with the initial value False.
//                             In the Check-Selection mode, if the Truth is not set,
//                             the form will not be closed after returning from the notification procedure and
//                             a warning about the impossibility of continuing will be shown.
//    * NoConfirmation       - Boolean -  if set to True, then if you have a password
//                             , the verification will be performed immediately without opening the form.
//                             If the check mode is Selected and the result Processing parameter is set, the
//                             form will not be opened if the check Pass parameter is set to True.
//    * CompletionProcessing    - NotifyDescription -  called when the form is closed, the result
//                             is passed Undefined or the value of the check is passed (see below).
//    * OperationContext       - Arbitrary -  if you pass the context returned by the procedures, Sign,
//                             Decrypt, etc., the password entered for the certificate can be used
//                             as if it was saved for the duration of the session.
//                             When called again, the no Confirmation parameter is considered to be True.
//    * DontShowResults - Boolean -  if the parameter is set to True and the Contextoperation parameter
//                             contains the context of the previous operation, the validation results will not be shown
//                             to the user.
//    * SignatureType             - EnumRef.CryptographySignatureTypes -  
//                             
//    * PerformCAVerification - 
//    * IgnoreCertificateRevocationStatus - 
//    * Result              - Undefined -  the check was never performed.
//                             - Structure - :
//         * ChecksPassed  - Boolean -  the return value. It is set in the procedure of the Result processing parameter.
//         * ChecksAtServer - Undefined - :
//                             - Structure - 
//         * ChecksAtClient - Structure:
//             * CertificateExists  - Boolean
//                                   - Undefined - 
//                                     
//                                     
//                                     
//             * CertificateData   - Boolean
//                                   - Undefined - 
//             * ProgramExists    - Boolean
//                                   - Undefined - 
//             * Signing          - Boolean
//                                   - Undefined - 
//             * CheckSignature     - Boolean
//                                   - Undefined - 
//             * Encryption          - Boolean
//                                   - Undefined - 
//             * Details         - Boolean
//                                   - Undefined - 
//             
//                                     
//                                     
//             
//                                    
//
//    * AdditionalChecksParameters - Arbitrary -  parameters that are passed to the procedure
//        The attachment of the form of verification of the certificate of the general module of the electronic signature is undetectable.
//
Procedure CheckCatalogCertificate(Certificate, AdditionalParameters = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCatalogCertificate(Certificate, AdditionalParameters);
	
EndProcedure

// Displays the dialog for installing an extension for working with electronic signature and encryption.
// Only for working through the platform's tools (Manager Cryptography).
//
// Parameters:
//   WithoutQuestion - Boolean -  if True, then the question will not be shown.
//                Required if the user clicked the button to Install the extension.
//
//   ResultHandler - NotifyDescription - 
//      :
//       
//          
//          
//       
//
//   QueryText     - String -  question text.
//   QuestionTitle - String -  the question title.
//
//
Procedure InstallExtension(WithoutQuestion, ResultHandler = Undefined, QueryText = "", QuestionTitle = "") Export
	
	DigitalSignatureInternalClient.InstallExtension(WithoutQuestion, ResultHandler, QueryText, QuestionTitle);
	
EndProcedure

// Opens or activates the electronic signature and encryption settings form.
// 
// Parameters:
//  Page - String -  valid strings are "Certificates", "Settings", "Programs".
//
Procedure OpenDigitalSignatureAndEncryptionSettings(Page = "Certificates") Export
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowPage", Page);
	
	Form = OpenForm("CommonForm.DigitalSignatureAndEncryptionSettings", FormParameters);
	
	// 
	If Page = "Certificates" Then
		Form.Items.Pages.CurrentPage = Form.Items.CertificatesPage;
		
	ElsIf Page = "Settings" Then
		Form.Items.Pages.CurrentPage = Form.Items.SettingsPage;
		
	ElsIf Page = "Programs" Then
		Form.Items.Pages.CurrentPage = Form.Items.ApplicationPage;
	EndIf;
	
	Form.Open();
	
EndProcedure

// Opens a link to the its section "Instructions for working with electronic signature and encryption programs".
//
Procedure OpenInstructionOfWorkWithApplications() Export
	
	DigitalSignatureInternalClient.OpenInstructionOfWorkWithApplications();
	
EndProcedure

// 
// 
//
// Parameters:
//   SectionName - String -  link to the error in the instructions.
//
Procedure OpenInstructionOnTypicalProblemsOnWorkWithApplications(SectionName = "") Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefiningRefToAppsTroubleshootingGuide(
		URL, SectionName);
	
	If Not IsBlankString(URL) Then
		FileSystemClient.OpenURL(URL);
	EndIf;
	
EndProcedure

// Returns the date extracted from the binary signature data, or Undefined.
//
// Parameters:
//  Notification - NotifyDescription - :
//                 
//                 
//  Signature - BinaryData - 
//  CastToSessionTimeZone - Boolean -  bring the universal time to the session time.
//
Procedure SigningDate(Notification, Signature, CastToSessionTimeZone = True) Export
	
	SigningDate = DigitalSignatureInternalClientServer.SigningDateUniversal(Signature);
	
	If SigningDate = Undefined Then
		ExecuteNotifyProcessing(Notification, Undefined);
		Return;
	EndIf;
	
	If CastToSessionTimeZone Then
		SigningDate = SigningDate + (CommonClient.SessionDate()
			- CommonClient.UniversalDate());
	EndIf;
	
	ExecuteNotifyProcessing(Notification, SigningDate);
	
EndProcedure
	
// Returns a view of the certificate in the directory, formed
// from the view of the subject (Comuvydan) and the certificate validity period.
//
// Parameters:
//   Certificate   - CryptoCertificate -  the certificate cryptography.
//                - Structure:
//                   * ValidBefore - 
//                   * Certificate   - CryptoCertificate -  the certificate cryptography.
//
// Returns:
//  String - 
//
Function CertificatePresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificatePresentation(Certificate,
		DigitalSignatureInternalClient.UTCOffset());
	
EndFunction

// Returns a representation of the certificate's subject (Comunidad).
//
// Parameters:
//   Certificate - CryptoCertificate -  the certificate cryptography.
//
// Returns:
//   String   - 
//              
//              
//              
//
Function SubjectPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.SubjectPresentation(Certificate);
	
EndFunction

// Returns a view of the certificate publisher (issued by whom).
//
// Parameters:
//   Certificate - CryptoCertificate -  the certificate cryptography.
//
// Returns:
//   String - 
//            
//
Function IssuerPresentation(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.IssuerPresentation(Certificate);
	
EndFunction

// Returns the main properties of the certificate as a structure.
//
// Parameters:
//   Certificate - CryptoCertificate -  the certificate cryptography.
//
// Returns:
//   Structure:
//    * Thumbprint      - String -  the thumbprint of the certificate in Base64 string format.
//    * SerialNumber  - BinaryData -  certificate property SerialNumber.
//    * Presentation  - See DigitalSignatureClient.CertificatePresentation.
//    * IssuedTo      - See DigitalSignatureClient.SubjectPresentation.
//    * IssuedBy       - See DigitalSignatureClient.IssuerPresentation.
//    * StartDate     - Date   -  the property of the DataPoint certificate in the session time zone.
//    * EndDate  - Date   -  property of the end Date certificate in the session time zone.
//    * Purpose     - String -  description of the extended property of the EKU certificate.
//    * Signing     - Boolean -  the certificate property is used for Signing.
//    * Encryption     - Boolean -  certificate property use for Decryption.
//
Function CertificateProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateProperties(Certificate,
		DigitalSignatureInternalClient.UTCOffset(), Undefined);
	
EndFunction

// Returns the subject properties of the cryptography certificate.
//
// Parameters:
//   Certificate - CryptoCertificate -  for which you need to return the subject properties.
//
// Returns:
//  Structure - :
//     * CommonName         - String -  (64) - extracted from the CN field.
//                          Legal entity - depending on the type of the final owner of the SKPEP
//                              a) name of the company;
//                              b) the name of the automated system;
//                              c) another display name according to the requirements of the information system.
//                          FULL NAME.
//                        - Undefined - 
//
//     * Country           - String -  (2) - extracted from the field C-two-character country code
//                          according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - 
//
//     * State           - String -  (128) - extracted from the field S - name of the subject of the Russian Federation.
//                          YUL - at the location address.
//                          FL - at the registration address.
//                        - Undefined - 
//
//     * Locality  - String -  (128) - extracted from the field L - name of the locality.
//                          YUL - at the location address.
//                          FL - at the registration address.
//                        - Undefined - 
//
//     * Street            - String -  (128) - extracted from the Street field - the name of the street, house, office.
//                          YUL - at the location address.
//                          FL - at the registration address.
//                        - Undefined - 
//
//     * Organization      - String -  (64) - extracted from the O field.
//                          Legal entity is the full or abbreviated name of the company.
//                        - Undefined - 
//
//     * Department    - String -  (64) - extracted from the OU field.
//                          Legal entity - in the case of the release of the UPCEP to an official - a division of the company.
//                              A subdivision is a territorial structural unit of a large company,
//                              which is usually not filled in in the certificate.
//                        - Undefined - 
//
//     * Email - String -  (128) - extracted from the E-mail address field.
//                          Legal entity - the e-mail address of the official.
//                          FL - the e-mail address of an individual.
//                        - Undefined - 
//
//     * JobTitle        - String -  (64) - extracted from the T field.
//                          YUL - in the case of the release of the SKPEP to an official - his position.
//                        - Undefined - 
//
//     * OGRN             - String -  (13) - extracted from the OGRN field.
//                          YUL - OGRN of the company.
//                        - Undefined - 
//
//     * OGRNIE           - String -  (15) - extracted from the OGRNIP field.
//                          IP - OGRN of an individual entrepreneur.
//                        - Undefined - 
//
//     * SNILS            - String -  (11) - extracted from the SNILS field.
//                          FL - SNILS
//                          YUL - not necessarily, in the case of the release of a SKPEP on an official - his SNILS.
//                        - Undefined - 
//
//     * TIN              - String -  (12) - extracted from the INN field.
//                          FL - INN.
//                          IP - INN.
//                          YUL - not required, but can be filled in in old certificates.
//                        - Undefined - 
//
//     * TINEntity            - String -  (10) - extracted from the INNLE field.
//                          YUL - required, but may be missing in old certificates.
//                        - Undefined - 
//
//     * LastName          - String -  (64) - is extracted from the SN field, if filled in.
//                        - Undefined - 
//
//     * Name              - String -  (64) - is extracted from the GN field if filled in.
//                        - Undefined - 
//
//     * MiddleName         - String -  (64) - is extracted from the GN field if filled in.
//                        - Undefined - 
//
Function CertificateSubjectProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateSubjectProperties(Certificate);
	
EndFunction

// Returns properties of the cryptography certificate publisher. 
//
// Parameters:
//   Certificate - CryptoCertificate -  for which you need to return the publisher properties.
//
// Returns:
//  Structure - 
//              :
//     * CommonName         - String -  (64) - extracted from the CN alias field of the certification authority.
//                        - Undefined - 
//
//     * Country           - String -  (2) - extracted from the field C-two-character country code
//                          according to ISO 3166-1:1997 (GOST 7.67-2003).
//                        - Undefined - 
//
//     * State           - String -  (128) - extracted from the field S-name of the subject of the Russian Federation
//                          at the address of the location of the PAC UC.
//                        - Undefined - 
//
//     * Locality  - String -  (128) - extracted from the field L - name of the locality
//                          at the address of the location of the UC PACK.
//                        - Undefined - 
//
//     * Street            - String -  (128) - extracted from the field Street-name of the street, house, office
//                          at the address of the location of the PAC UC.
//                        - Undefined - 
//
//     * Organization      - String -  (64) - extracted from the field O-full or abbreviated name of the company.
//                        - Undefined - 
//
//     * Department    - String -  (64) - extracted from the OU - business unit field.
//                            A division is a territorial structural unit of a large company
//                            that is usually not filled in in the certificate.
//                        - Undefined - 
//
//     * Email - String -  (128) - extracted from the e-mail address field of the certification authority.
//                        - Undefined - 
//
//     * OGRN             - String -  (13) - extracted from THE OGRN-OGRN field of the certification center company.
//                        - Undefined - 
//
//     * TIN              - String -  (12) - is extracted from the INN - INN field of the certification center company.
//                          YUL - optional, but may be present in old certificates.
//                        - Undefined - 
//
//     * TINEntity            - String -  (10) - extracted from the INNLE field - INN of the certification center company.
//                          YUL - required, but may be missing in old certificates.
//                        - Undefined - 
//
Function CertificateIssuerProperties(Certificate) Export
	
	Return DigitalSignatureInternalClientServer.CertificateIssuerProperties(Certificate);
	
EndFunction

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
// Parameters:
//  Parameters - See DigitalSignatureClient.XMLEnvelopeParameters
//            - Indefinite - use default parameters.
//
// Returns:
//  String
//
// Example:
//	The parameters of the envelope = the electronic signature of the client.Parameters of the XML() converter;
//	The parameters of the envelope.Option = "furs.mark.crpt.ru_v1";
//	The parameters of the envelope.Message XML =
//	"    <getProductDetailsResponse xmlns=""http://warehouse.example.com/ws"">
//	|      <getProductDetailsResult>
//	|       <productID>12345</productID>
//	|       <productName>Faceted glass</ProductName>
//	|       <description>The glass is faceted. 250 ml.</description>
//	|       <price>9.95</price>
//	|       <currency>
//	|         <code>840</code>
//	|         <alpha3>USD</alpha3>
//	|         <sign>$</sign>
//	|         <name>US dollar</name>
//	|         <accuracy>2</accuracy>
//	|       </currency>
//	|       <inStock>true</inStock>
//	|     </getProductDetailsResult>
//	|   </getProductDetailsResponse>";
//	
//	ConvertXML = Electronic Signature Client.envelopexml(Parameters);
//
Function XMLEnvelope(Parameters = Undefined) Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelope(Parameters);
	
EndFunction

// Returns parameters that can be set for an XML envelope.
//
// Returns:
//  Structure:
//   * Variant - String - :
//                 
//                 
//                 
//
//   * XMLMessage - String -  an XML message that is inserted into the template.
//                             If not filled in, the %messagexml% parameter remains.
//
Function XMLEnvelopeParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLEnvelopeParameters();
	
EndFunction

// Forms a property structure for customizing non
// -standard XML envelope processing and signing and hashing algorithms.
//
// It is recommended not to fill in the parameters XPathSignedInfo and XPath-signed tag
// The XPathSignedInfo parameter is calculated by canonicalization algorithms,
// and the XPath parameter of the signable tag is calculated by reference
// in the URI attribute of the SignedInfo.Reference element of the XML envelope.
// The parameters are left for backward compatibility. If specified, it works the same way:
// parameters are not extracted from the XML envelope and their control is not performed, while
// the envelope must contain canonization algorithms and have
// certificate placement elements, as in the "furs.mark.crpt.ru_v1" envelope variant.
//
// There is no need to fill in algorithms for using certificates
// with the public key algorithms GOST 94, GOST 2001, GOST 2012/256 and GOST 2012/512.
// Signing and hashing algorithms are calculated using the algorithm of the public key
// extracted from the certificate that is being signed. First
// by the transmitted table, then if the table is not filled in or a match
// is not found, by the internal matching table (recommended).
//
// Returns:
//  Structure:
//   * XPathSignedInfo         - String -  by default: "(//. | //@* | //namespace::*) [ancestor-or-self::*[local-name ()= 'SignedInfo']]".
//   * XPathTagToSign   - String -  by default: "(//. | //@* | //namespace::*) [ancestor-or-self:: soap:Body]".
//
//   * OIDOfPublicKeyAlgorithm - String -  for example, "1.2.643.2.2.19" + Characters.PS + "1.2.643.7.1.1.1.1"+ ...
//   * SIgnatureAlgorithmName        - String -  for example, "GOST R 34.10-2001" + Characters.PS + "GOST R 34.11-2012"+ ...
//   * SignatureAlgorithmOID        - String -  for example, "1.2.643.2.2.3" + Characters.PS + "1.2.643.7.1.1.3.2"+ ...
//   * HashingAlgorithmName    - String -  for example, "GOST R 34.11-94" + Characters.PS + "GOST R 34.11-12"+ ...
//   * HashingAlgorithmOID    - String -  for example, "1.2.643.2.2.9" + Characters.PS + "1.2.643.7.1.1.2.2"+ ...
//   * SignAlgorithm            - String -  for example, "http://www.w3.org/2001/04/xmldsig-more#gostr34102001-gostr3411"
//                                      + Symbols.PS +
//                                      "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102012-gostr34112012-256"+ ...
//   * HashAlgorithm        - String -  for example, "http://www.w3.org/2001/04/xmldsig-more#gostr3411"
//                                      + Symbols.PS + "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34112012-256"+ ...
//
Function XMLDSigParameters() Export
	
	Return DigitalSignatureInternalClientServer.XMLDSigParameters();
	
EndFunction

// Forms the structure of the properties to sign the data in CMS format.
// 
// Returns:
//  Structure:
//   * SignatureType                    - String -  "CAdES-BES" - other options are not used yet.
//   * DetachedAddIn                  - Boolean -    False ( default) - include data in the signature container.
//                                   True - do not include data in the signature container.
//   * IncludeCertificatesInSignature - CryptoCertificateIncludeMode -  specifies the length
//                                   of the certificate chain to include in the signature. The value of
//                                   include chained root Is not supported and is considered equal to the value of include full Chained.
//
Function CMSParameters() Export
	
	Return DigitalSignatureInternalClientServer.CMSParameters();
	
EndFunction

#Region WriteCertificateToCatalog1

// Initializes the parameter structure for adding the certificate
// to the Certificate directory of the Key Electronic Signature decryption.
// To be used in the procedure, write down the certificate of the reference.
//
// Returns:
//   Structure:
//      * Description   - String -  presentation of the certificate in the list.
//                       The default value is "".
//      * User   - CatalogRef.Users -  the user who owns the certificate.
//                       This value is used when getting a list of the user
//                       's personal certificates in the data signing and encryption forms.
//                       The default value is Undefined.
//      * Organization    - DefinedType.Organization -  the company that the certificate belongs to.
//                       The default value is Undefined.
//      * Individual - DefinedType.Individual - 
//                       
//      * Application      - CatalogRef.DigitalSignatureAndEncryptionApplications -  the program that
//                       is required for signing and decryption.
//                       The default value is Undefined.
//      * EnterPasswordInDigitalSignatureApplication - Boolean - 
//                       
//                       
//                       
//                       
//                       
//
Function CertificateRecordParameters() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Description", "");
	AdditionalParameters.Insert("User", Undefined);
	AdditionalParameters.Insert("Organization", Undefined);
	AdditionalParameters.Insert("Individual", Undefined);
	AdditionalParameters.Insert("Application", Undefined);
	AdditionalParameters.Insert("EnterPasswordInDigitalSignatureApplication", False);
	
	Return AdditionalParameters;
	
EndFunction

// Verifies the certificate and, if successful, adds a new certificate or updates an existing one in the Certificate
// directory of the Key Electronic Signature Decryption. If the check is not passed, it shows
// information about the errors that occurred.
// To add a certificate on the server, see the electronic signature.Write down the certificate in the Reference book.
//
// Parameters:
//   CompletionHandler - NotifyDescription - 
//                           :
//       
//       
//   Certificate              - BinaryData -  binary data of the certificate.
//                           - String - 
//                           
//   CertificatePassword       - String -  password of the certificate for verifying operations with the private key.
//   ToEncrypt           - Boolean -  defines the list of checks
//                           performed before adding the certificate. If the parameter is set to True,
//                           encryption and decryption are checked, otherwise signing and signature verification are performed.
//   AdditionalParameters - Undefined -  without any additional parameters.
//                           - See CertificateRecordParameters
//
Procedure WriteCertificateToCatalog(CompletionHandler,
	Certificate,
	CertificatePassword,
	ToEncrypt = False,
	AdditionalParameters = Undefined) Export
	
	Context = New Structure;
	Context.Insert("CertificatePassword", CertificatePassword);
	Context.Insert("ToEncrypt", ToEncrypt);
	Context.Insert("AdditionalParameters", ?(AdditionalParameters = Undefined,
		CertificateRecordParameters(), AdditionalParameters));
	Context.Insert("FormCaption", ?(Context.ToEncrypt = True,
		NStr("en = 'Cannot check encryption and decryption.';"),
		NStr("en = 'Cannot check if it is digitally signed.';")));
	Context.Insert("ApplicationErrorTitle",
		DigitalSignatureInternalClientServer.CertificateAddingErrorTitle(
			?(Context.ToEncrypt = True, "Encryption", "Signing")));
		
	Context.Insert("CertificateData", Certificate);
	Context.Insert("SignAlgorithm",
		DigitalSignatureInternalClientServer.CertificateSignAlgorithm(Certificate));
		
	If TypeOf(Context.CertificateData) = Type("String")
		And IsTempStorageURL(Context.CertificateData) Then
		
		Context.CertificateData = GetFromTempStorage(Context.CertificateData);
	EndIf;
	
	If CommonSettings().VerifyDigitalSignaturesOnTheServer Then
		
		CertificateRef = DigitalSignatureInternalServerCall.WriteCertificateAfterCheck(Context);
		If CertificateRef <> Undefined Then
			ExecuteNotifyProcessing(CompletionHandler, CertificateRef);
			Return;
		EndIf;
		
	EndIf;
	
	Context.Insert("CompletionHandler", CompletionHandler);
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.ShowError = Undefined;
	CreationParameters.SignAlgorithm = Context.SignAlgorithm;
	
	DigitalSignatureInternalClient.CreateCryptoManager(
		New NotifyDescription("AddCertificateAfterCreateCryptoManager",
		DigitalSignatureInternalClient, Context), "", CreationParameters);
	
EndProcedure

#EndRegion

#Region InteractiveCertificateAddition

// Initializes the parameter structure for interactively adding a certificate.
// If the create Statement parameter Is True and the store Name parameter is False, it opens a new
// certificate issuance application.
// If the create Statement parameter Is False and from the personal Store is True, it adds a certificate from
// the personal store.
// If the parameter create Statement-True and from other storage-True, opens the window for choosing
// how to add the certificate.
// For use in the electronic signature of the Client.Add a certificate
//
// Returns:
//   Structure:
//      * ToPersonalList      - Boolean -  if the parameter is set to True, the User account
//                           will be filled in by the current user, otherwise the account will not be filled in.
//                           The default value is False.
//      * Organization        - DefinedType.Organization -  the company that the certificate belongs to.
//                           The default value is Undefined.
//                           In the case when the parameter is used to create a statement, then the value
//                           is passed to the procedure for
//                           filling in the company's requestionsapplicationsertificate of the general module of the application, the certificate is undefined without modification, and after the call
//                           is reduced to the composition of the types of the Company's type property.
//      * CreateRequest   - Boolean -  if the parameter is set to True, it adds the ability
//                           to create a new certificate issuance request.
//                           The default value is True.
//      * FromPersonalStorage - Boolean -  if the parameter is set to True, it adds the ability
//                           to select a certificate from the ones installed in the personal storage.
//                           The default value is True.
//      * Individual     - CatalogRef -  the individual for whom you need to create
//                           a certificate application (when completed, takes precedence over the company).
//                           The default value is Undefined.
//                           The value is passed to the procedure when
//                           filling in the Owner's requestionsapplicationsertificate of the general module of the declarationsertificationdetermined without modification, and after the call
//                           is reduced to the composition of the types of the property of the Owner's type.
//      * OnToken           - Boolean - 
//
Function CertificateAddingOptions() Export
	
	AddingOptions = New Structure;
	AddingOptions.Insert("ToPersonalList", False);
	AddingOptions.Insert("Organization", Undefined);
	AddingOptions.Insert("CreateRequest", True);
	AddingOptions.Insert("FromPersonalStorage", True);
	AddingOptions.Insert("Individual", Undefined);
	AddingOptions.Insert("OnToken", False);
	
	Return AddingOptions;
	
EndFunction

// Interactively adds a certificate from the ones installed on the computer or creates a certificate release request.
//
// Parameters:
//   CompletionHandler - NotifyDescription - :
//      
//      
//          
//          
//                      
//                       
//                      
//   AddingOptions - Undefined -  without any additional parameters.
//                       - See DigitalSignatureClient.CertificateAddingOptions
//
// Example:
//  1) Adding a certificate from the installed in your personal storage:
//  Addmentparameters = email client.Parameteridentification();
//  Add parameters.Create An Ad = False;
//  Electronic signature of the client.Donaufestival (Parametrizability);
//  
//  2) Creating an application for issuing a certificate:
//  Addmentparameters = email client.Parameteridentification();
//  Add parameters.Isochlorogenic = False;
//  Electronic signature of the client.Donaufestival (Parametrizability);
//  
//  3) Interactive choice of how to add a certificate:
//  e-Signclient.Add a certificate();
//
Procedure ToAddCertificate(CompletionHandler = Undefined, AddingOptions = Undefined) Export
	
	If AddingOptions = Undefined Then
		AddingOptions = CertificateAddingOptions();
	EndIf;
	
	InteractiveSelectionParameters = New Structure("ToPersonalList, Organization, Individual");
	FillPropertyValues(InteractiveSelectionParameters, AddingOptions);
	
	If Not AddingOptions.CreateRequest
		And Not AddingOptions.FromPersonalStorage Then
		
		Return;
	EndIf;
	
	InteractiveSelectionParameters.Insert("HideApplication",
		AddingOptions.FromPersonalStorage And Not AddingOptions.CreateRequest);
	InteractiveSelectionParameters.Insert("CreateRequest",
		AddingOptions.CreateRequest And Not AddingOptions.FromPersonalStorage);
	If InteractiveSelectionParameters.CreateRequest Then
		InteractiveSelectionParameters.Insert("OnToken", AddingOptions.OnToken);
	EndIf;
	
	DigitalSignatureInternalClient.ToAddCertificate(InteractiveSelectionParameters, CompletionHandler);
	
EndProcedure

#EndRegion

#Region ForCallsFromOtherSubsystems

// 
// 
// Parameters:
//  FormParameters - Structure
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
//  OwnerForm - ClientApplicationForm - 
//  CallbackOnCompletion - NotifyDescription - 
//
Procedure OpenExtendedErrorPresentationForm(FormParameters, OwnerForm = Undefined, CallbackOnCompletion = Undefined) Export
	
	DigitalSignatureInternalClient.OpenExtendedErrorPresentationForm(FormParameters, OwnerForm, CallbackOnCompletion);
	
EndProcedure

// 

// 
//
// Parameters:
//  Notification     - NotifyDescription - :
//                   
//                   
//
//  Operation       - String -  if not empty, it must contain one of the lines that define
//                   the operation to insert in the error description: Signing, Verifying Signatures, Encrypting,
//                   Decrypting, Verifying Certificates, Receiving Certificates.
//
//  ShowError - Boolean -  if it is True, then the program error Form will open
//                   , from which you can go to the list of installed programs
//                   in the personal settings form on the "Installed programs" page,
//                   where you can see why the program could not be used,
//                   and also open the installation instructions.
//
//  Application      - Undefined - 
//                   
//                 - CatalogRef.DigitalSignatureAndEncryptionApplications - 
//                   
//                 - Structure - See DigitalSignature.NewApplicationDetails.
//                 - BinaryData - 
//                 - String - 
//
Procedure CreateCryptoManager(Notification, Operation, ShowError = True, Application = Undefined) Export
	
	If TypeOf(Operation) <> Type("String") Then
		Operation = "";
	EndIf;
	
	If ShowError <> True Then
		ShowError = False;
	EndIf;
	
	CreationParameters = DigitalSignatureInternalClient.CryptoManagerCreationParameters();
	CreationParameters.Application = Application;
	CreationParameters.ShowError = ShowError;
	
	DigitalSignatureInternalClient.CreateCryptoManager(Notification, Operation, CreationParameters);
	
EndProcedure

// Finds the certificate on the computer based on the fingerprint string.
// Only for working through the platform's tools (Manager Cryptography).
//
// Parameters:
//   Notification           - NotifyDescription - :
//     
//     
//     
//
//   Thumbprint              - String -  The Base64 encoded thumbprint of the certificate.
//   InPersonalStorageOnly - Boolean -  if True, then search in your personal storage, otherwise everywhere.
//   ShowError         - Boolean -  if False, then the error text that will be returned will not be shown.
//
Procedure GetCertificateByThumbprint(Notification, Thumbprint, InPersonalStorageOnly, ShowError = True) Export
	
	If TypeOf(ShowError) <> Type("Boolean") Then
		ShowError = True;
	EndIf;
	
	DigitalSignatureInternalClient.GetCertificateByThumbprint(Notification,
		Thumbprint, InPersonalStorageOnly, ShowError);
	
EndProcedure

// 
// 
// Parameters:
//  Notification     - NotifyDescription - :
//                     
//                     
//                      
//                      
//                     
//                     
//                     
//
//  OnlyPersonal   - Boolean -  if False, recipient certificates are added to the personal certificates.
//
//  ReceivingParameters - See CertificateThumbprintsReceiptParameters
//                     
//
Procedure GetCertificatesThumbprints(Notification, OnlyPersonal, ReceivingParameters = True) Export
	
	DigitalSignatureInternalClient.GetCertificatesThumbprints(Notification, OnlyPersonal, ReceivingParameters);
	
EndProcedure

// 
// See GetCertificatesThumbprints.
// 
// Parameters:
//   ClientSide - Boolean, Undefined - 
//     
//   ServerSide  - Boolean, Undefined - 
//     
//   Service     - Boolean, Undefined -  
//     
//
// Returns:
//  Structure:
//   * ClientSide - 
//   * ServerSide  - 
//   * Service     - 
//   * ShouldReturnSource - Boolean - 
//
Function CertificateThumbprintsReceiptParameters(ClientSide = True, ServerSide = True, Service = True) Export
	
	Structure = New Structure;
	Structure.Insert("ClientSide", ClientSide);
	Structure.Insert("ServerSide", ServerSide);
	Structure.Insert("Service", Service);
	Structure.Insert("ShouldReturnSource", True);
	Return Structure;
	
EndFunction

//  The procedure checks whether the certificate is in the personal storage, whether the current user
//  is specified in the certificate or not, and whether the program for working with the certificate is filled in.
//
//  Parameters:
//   Notification - NotifyDescription - :
//     
//            
//            
//            
//            
//            
//   Filter - Undefined -  to use the default values for the properties of the structure described below.
//         - Structure:
//                 * CheckExpirationDate - Boolean -  if the property is not present, it means True.
//                 * CertificatesWithFilledProgramOnly - Boolean -  if the property is not present, it means True
//                         . the request to the directory selects only those certificates
//                         that have the Program field filled in.
//                 * IncludeCertificatesWithBlankUser - Boolean -  if the property is not present, it means True
//                         . the request to the directory selects not only certificates that
//                         have the same User field as the current user, but also those that do not have it filled in.
//                 * Organization - DefinedType.Organization -  if the property is present and filled in, then
//                         only certificates that have the same Company field as the specified one are selected in the request to the directory
//                         .
//
Procedure FindValidPersonalCertificates(Notification, Filter = Undefined) Export
	
	FilterTypesArray = New Array;
	FilterTypesArray.Add(Type("Structure"));
	FilterTypesArray.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Filter", Filter, FilterTypesArray);
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindValidPersonalCertificates",
		"Notification", Notification, Type("NotifyDescription"));
	
	DigitalSignatureInternalClient.FindValidPersonalCertificates(Notification, Filter);
	
EndProcedure

// Searches for installed programs on the client and server.
// Only for working through the platform's tools (Manager Cryptography).
//
// Parameters:
//   Notification - NotifyDescription - :
//     
//                
//       
//       
//       
//                                     
//
//   ApplicationsDetails   - Undefined -  check only known programs that are filled in by the procedure
//                                 Electronic signature.Fill in the program list if you pass an empty array.
//                      - Array - 
//                                 
//                                 
//
//   CheckAtServer1 - Undefined -  check on the server if signing or encryption is enabled on the server.
//                      - Boolean - 
//                                 
//
Procedure FindInstalledPrograms(Notification, ApplicationsDetails = Undefined, CheckAtServer1 = Undefined) Export
	
	If ApplicationsDetails = Undefined Then
		ApplicationsDetails = New Array;
	EndIf;
	
	TypesArrayCheckAtServer = New Array;
	TypesArrayCheckAtServer.Add(Type("Boolean"));
	TypesArrayCheckAtServer.Add(Type("Undefined"));
	
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "CheckAtServer1", 
		CheckAtServer1, TypesArrayCheckAtServer);
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "Notification", 
		Notification, Type("NotifyDescription"));
		
	CommonClientServer.CheckParameter("DigitalSignatureClient.FindInstalledPrograms", "ApplicationsDetails", 
		ApplicationsDetails, Type("Array"));
	
	DigitalSignatureInternalClient.FindInstalledPrograms(Notification, ApplicationsDetails, CheckAtServer1);
	
EndProcedure

// 
// 
// Parameters:
//  Form - ClientApplicationForm
//  CheckParameters - 
//    
//      
//       
//      
//   
//       See DigitalSignatureInternalClientServer.AppsRelevantAlgorithms
//      
//      
//      
//   
//        
//   
//        
//   
//                                                 
//  CallbackOnCompletion - NotifyDescription - :
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
Procedure CheckCryptographyAppsInstallation(Form, CheckParameters = Undefined, CallbackOnCompletion = Undefined) Export
	
	DigitalSignatureInternalClient.CheckCryptographyAppsInstallation(Form, CheckParameters, CallbackOnCompletion);
	
EndProcedure

// Sets a password in the password store on the client for the duration of the session.
// Only for working through the platform's tools (Manager Cryptography).
//
// Setting a password allows you not to enter the user's password during the next
// operation, which is useful when performing a batch of operations.
// If a password is set for the certificate, then the remember Password check box
// in the data Signing and Decryption forms becomes invisible.
// To cancel the set password, just set the password value Undefined.
//
// Parameters:
//  CertificateReference - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the certificate
//                        that the password is set for.
//
//  Password           - String -  to set the password. It may be empty.
//                   - Undefined - 
//
//  PasswordNote   - Structure - :
//     * ExplanationText       - String -  only text;
//     * HyperlinkNote - Boolean -  if true, then when you click on the explanation, call action Processing.
//     * ToolTipText       - String
//                            - FormattedString - 
//     * ProcessAction    - NotifyDescription - 
//        :
//        
//          
//                         
//          
// 
Procedure SetCertificatePassword(CertificateReference, Password, PasswordNote = Undefined) Export
	
	DigitalSignatureInternalClient.SetCertificatePassword(CertificateReference, Password, PasswordNote);
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  CertificateReference - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates - 
//                        
//
// Returns:
//  Boolean - 
//
Function CertificatePasswordIsSet(CertificateReference) Export
	
	Return DigitalSignatureInternalClient.CertificatePasswordIsSet(CertificateReference);
	
EndFunction

// Overrides the normal certificate selection from the directory to select a certificate
// from the personal storage with password confirmation and automatic addition to the directory,
// if the certificate is not already in the directory.
//
// Parameters:
//  Item    - FormField -  the form element that the selected value will be passed to.
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the current value
//               selected in the Item field to select the corresponding row in the list.
//
//  StandardProcessing - Boolean -  standard parameter of the initial Selection event to reset to False.
//  
//  ToEncryptAndDecrypt - Boolean -  controls the header of the selection form. The initial value is False.
//                              False-for signing, True-for encryption and decryption,
//                            - Undefined - 
//
Procedure CertificateStartChoiceWithConfirmation(Item, Certificate, StandardProcessing, ToEncryptAndDecrypt = False) Export
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedCertificate", Certificate);
	FormParameters.Insert("ToEncryptAndDecrypt", ToEncryptAndDecrypt);
	
	DigitalSignatureInternalClient.SelectSigningOrDecryptionCertificate(FormParameters, Item);
	
EndProcedure

// Shows the result of a certificate check that was performed in the background.
//
// Parameters:
//   Certificate           - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the certificate
//                        that was validated.
//   Result            - 
//   FormOwner        - ClientApplicationForm -  owner of the certificate verification form that is being opened.
//   Title            - String -  title of the certificate verification form to open.
//   MergeResults - String -  defines how the verification results are displayed in the client-server
//                        version when using an electronic signature on the server. It can take
//                        the values Unjoin, Unify, and unify. If takes the value 
//                        Combine or Merge, the results of the check will be combined with 
//                        the corresponding condition. Otherwise, the results will be displayed
//                        separately for client and server checks.
//   CompletionProcessing  - NotifyDescription -  contains a description of the procedure that will be called after
//                        closing the certificate verification form.
//
Procedure ShowCertificateCheckResult(Certificate, Result, FormOwner,
	Title = "", MergeResults = "DontMerge", CompletionProcessing = Undefined) Export
	
	DigitalSignatureInternalClient.ShowCertificateCheckResult(
		Certificate, Result, FormOwner, Title, MergeResults, CompletionProcessing);
	
EndProcedure

// 
// 
// Parameters:
//  Certificate - BinaryData
//             - String - 
//             - String - 
//             - CryptoCertificate
//
Procedure InstallRootCertificate(Certificate) Export
	
	Parameters = DigitalSignatureInternalClient.CertificateInstallationParameters(Certificate);
	DigitalSignatureInternalClient.InstallRootCertificate(Parameters);
	
EndProcedure

// 
// 
// Parameters:
//  Notification - NotifyDescription - 
//                                    
//                                   
//   : 
//     
//     
//                                  
//     
//                                                   
//     
//             - Undefined - 
//     
//     
//     
//      
//     
//  Signature - BinaryData - 
//          - String - 
//          - Array of String
//          - Array of BinaryData
//  ShouldReadCertificates - Boolean - 
//
Procedure ReadSignatureProperties(Notification, Signature, ShouldReadCertificates = True) Export

	DigitalSignatureInternalClient.ReadSignatureProperties(Notification, Signature, ShouldReadCertificates);

EndProcedure

// 
// 
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates
//
Procedure NotifyAboutCertificateExpiring(Certificate) Export
	
	Result = DigitalSignatureInternalServerCall.CertificateCustomSettings(Certificate);

	If ValueIsFilled(Result.CertificateRef) And Not Result.IsNotified Then
		
		FormOpenParameters = New Structure("Certificate", Certificate);
		ActionOnClick = New NotifyDescription("OpenNotificationFormNeedReplaceCertificate",
			DigitalSignatureInternalClient, FormOpenParameters);
		ShowUserNotification(NStr("en = 'You need to reissue the certificate';"), ActionOnClick, Certificate,
			PictureLib.DialogExclamation, UserNotificationStatus.Important, Certificate);

	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  FormOwner - ClientApplicationForm - 
//  Notification - NotifyDescription - 
//   
//   :
//    
//    
//    
//    
//    
//    
//
Procedure EnterSignatureAuthenticityJustification(FormOwner, Notification) Export
	
	ClosingNotification1 = New NotifyDescription("AfterSignatureAuthenticityJustificationEntered", DigitalSignatureInternalClient, Notification);
	OpenForm("InformationRegister.DigitalSignatures.Form.SignatureAuthenticityJustification",,FormOwner,True,,,
		ClosingNotification1, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// 
// 
//
// Parameters:
//   SearchString - String - 
//
Procedure OpenSearchByErrorsWhenManagingDigitalSignature(SearchString = "") Export
	
	URL = "";
	DigitalSignatureClientServerLocalization.OnDefineRefToSearchByErrorsWhenManagingDigitalSignature(
		URL, SearchString);
	
	If Not IsBlankString(URL) Then
		FileSystemClient.OpenURL(URL);
	EndIf;
	
EndProcedure

// Opens the form for viewing the item's signature.
Procedure OpenSignature(CurrentData) Export
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	SignatureProperties = DigitalSignatureClientServer.ResultOfSignatureValidationOnForm();
	FillPropertyValues(SignatureProperties, CurrentData);
	
	FormParameters = New Structure("SignatureProperties", SignatureProperties);
	OpenForm("CommonForm.DigitalSignature", FormParameters);
	
EndProcedure

Procedure OpenRenewalFormActionsSignatures(Form, RenewalOptions, FollowUpHandler = Undefined) Export
	
	OpenForm("CommonForm.RenewDigitalSignatures", RenewalOptions,
		Form,,,,FollowUpHandler, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

// 
// 
// Parameters:
//  ExtensionMode - String -  
//    
//   
//
Procedure OpenReportExtendValidityofElectronicSignatures(ExtensionMode) Export
	
	OpenForm("Report.RenewDigitalSignatures.Form", 
		New Structure("ExtensionMode", ExtensionMode));
	
EndProcedure


// 
Procedure SaveSignature(SignatureAddress, SignatureFileName = "") Export
	
	DigitalSignatureInternalClient.SaveSignature(SignatureAddress, SignatureFileName);
	
EndProcedure

// Opens the display form of the certificate data.
//
// Parameters:
//  CertificateData - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  link to the certificate.
//                    - CryptoCertificate - 
//                    - BinaryData -  binary data of the certificate.
//                    - String - 
//                    - String - 
//
//  OpenData     - Boolean -  to open the certificate information, not the form of a dictionary element.
//                      If the reference to the reference list item was not passed and the reference list item
//                      could not be found by fingerprint, then the certificate data will be opened.
//
Procedure OpenCertificate(CertificateData, OpenData = False) Export
	
	DigitalSignatureInternalClient.OpenCertificate(CertificateData, OpenData);
	
EndProcedure

// At the end of the signing to announce the signing.
//
// Parameters:
//  DataPresentation - Arbitrary -  link to the object to which
//                          the electronic signature was added.
//  IsPluralForm     - Boolean -  specifies whether the message type is plural
//                          or singular.
//  FromFile             - Boolean -  defines the type of message for adding
//                          an electronic signature or file.
//
Procedure ObjectSigningInfo(DataPresentation, IsPluralForm = False, FromFile = False) Export
	
	If FromFile Then
		If IsPluralForm Then
			MessageText = NStr("en = 'Signatures from files added:';");
		Else
			MessageText = NStr("en = 'Signature from file is added:';");
		EndIf;
	Else
		If IsPluralForm Then
			MessageText = NStr("en = 'Digitally signed:';");
		Else
			MessageText = NStr("en = 'Digitally signed:';");
		EndIf;
	EndIf;
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// When encryption is complete, it notifies you that it is complete.
//
// Parameters:
//  DataPresentation - Arbitrary -  a reference to an object whose
//                          data is encrypted.
//  IsPluralForm     - Boolean -  specifies whether the message type is plural
//                          or singular.
//
Procedure InformOfObjectEncryption(DataPresentation, IsPluralForm = False) Export
	
	MessageText = NStr("en = 'Encrypted:';");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// When decryption is complete, it notifies you of completion.
//
// Parameters:
//  DataPresentation - Arbitrary -  a reference to the object whose
//                          data is decrypted.
//  IsPluralForm     - Boolean -  specifies whether the message type is plural
//                          or singular.
//
Procedure InformOfObjectDecryption(DataPresentation, IsPluralForm = False) Export
	
	MessageText = NStr("en = 'Decrypted:';");
	
	ShowUserNotification(MessageText, , DataPresentation);
	
EndProcedure

// See DigitalSignature.PersonalSettings.
Function PersonalSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.PersonalSettings;
	
EndFunction

#EndRegion

#Region Private

// See DigitalSignature.CommonSettings.
Function CommonSettings() Export
	
	Return StandardSubsystemsClient.ClientRunParameters().DigitalSignature.CommonSettings;
	
EndFunction

#EndRegion
