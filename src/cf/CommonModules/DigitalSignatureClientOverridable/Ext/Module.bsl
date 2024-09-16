///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called after it is created on the server, but before opening the data Signing and Decryption forms.
// Used for additional actions that require a server call to avoid
// calling the server again.
//
// Parameters:
//  Operation          - String -  string Signing or Decryption.
//
//  InputParameters  - Arbitrary -  the value of the parameteradditional Actions property of
//                      the parameter description of the Given methods Sign, Decrypt the General
//                      module of the electronic signature Client.
//                      
//  OutputParametersSet - Arbitrary -  arbitrary data that was returned
//                      from the server from the procedure of the same name in the shared module.
//                      Electronic signature is undetectable.
//
Procedure BeforeOperationStart(Operation, InputParameters, OutputParametersSet) Export
	
	
	
EndProcedure

// Called from the certificate Check form if additional checks were added when creating the form.
//
// Parameters:
//  Parameters - Structure:
//   * WaitForContinue   - Boolean -  the return value. If True, then an additional check
//                            will be executed asynchronously, the continuation will resume after the notification is executed.
//                            The initial value is False.
//   * Notification           - NotifyDescription -  processing to be called to continue
//                              after performing an asynchronous additional check.
//   * Certificate           - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the certificate to verify.
//   * Validation             - String -  the name of the check added in the procedure for creating a form of verification Of the certificate of the
//                              General module of the electronic signature Undetectable.
//   * CryptoManager - CryptoManager -  prepared cryptography Manager for
//                              performing verification.
//                         - Undefined - 
//                              
//   * ErrorDescription       - String -  the return value. Description of the error received during the verification.
//                              This description can be seen by the user when clicking on the result image.
//   * IsWarning    - Boolean -  the return value. Image Type Error/Warning,
//                            the initial value is False.
//   * Password   - String -  password entered by the user.
//                   - Undefined - 
//                            
//   * ChecksResults   - Structure:
//      * Key     - String -  the name of the standard or additional check, or the name of the error. The key of the property containing
//                 the error contains the name of the check with the end Error.
//      * Value - Undefined -  the check was not performed (the error Description remains Undefined).
//                 - Boolean - 
//                 - String - 
//                 
//
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	
	
EndProcedure

// Called when opening instructions for working with electronic signature and encryption programs.
//
// Parameters:
//  Section - String -  the initial value is "accounting and tax Accounting",
//                    you can specify "accounting in state Institutions".
//
Procedure OnDetermineArticleSectionAtITS(Section) Export
	
	
	
EndProcedure

#EndRegion
