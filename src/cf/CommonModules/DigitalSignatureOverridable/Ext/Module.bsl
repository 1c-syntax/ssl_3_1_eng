///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// Parameters:
//  Settings - Structure:
//   * IndividualUsed - Boolean - 
//          See DefinedType.Individual
//
Procedure OnDefineSettings(Settings) Export
	
EndProcedure

// Called in the form of the certificate reference element for the key electronic signature Decryption and in other places
// where certificates are created or updated, for example, in the select certificate for signing or Decryption form.
// You can throw an exception if you want to stop the action and tell the user something -
// for example, when you try to create a copy of a certificate element that has restricted access.
//
// Parameters:
//  Ref     - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  empty for the new element.
//
//  Certificate - CryptoCertificate -  the certificate for which the directory element is created or updated.
//
//  AttributesParameters - ValueTable:
//               * AttributeName       - String -  name of the item to specify parameters for.
//               * ReadOnly     - Boolean -  if set to True, editing will be prohibited.
//               * FillChecking - Boolean -  if set to True, the filling will be checked.
//               * Visible          - Boolean -  if set to True, the props will become invisible.
//               * FillValue - Arbitrary -  the initial value of the new object's props.
//                                    - Undefined - 
//
Procedure BeforeStartEditKeyCertificate(Ref, Certificate, AttributesParameters) Export
	
	// 
	// 
	
EndProcedure

// Called when creating data Signing and Decryption forms on the server.
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
//  OutputParametersSet - Arbitrary -  arbitrary returned data that
//                      will be placed in the same procedure in the General module.
//                      E-signclientdetermined after the form
//                      is created on the server, but before it is opened.
//
Procedure BeforeOperationStart(Operation, InputParameters, OutputParametersSet) Export
	
EndProcedure

// Called to expand the list of checks being performed.
//
// Parameters:
//  Certificate - CatalogRef.DigitalSignatureAndEncryptionKeysCertificates -  the certificate to verify.
// 
//  AdditionalChecks - ValueTable:
//    * Name           - String -  name of the additional check, for example, authorization in English.
//    * Presentation - String -  the user name of the check, for example, "authorization on the taxi server".
//    * ToolTip     - String -  a hint that will be shown to the user when the question mark is clicked.
//
//  AdditionalChecksParameters - Arbitrary -  the value of the parameter of the same name specified
//    in the procedure check the certificate of the Reference of the General module of the electronic signature Client.
//
//  StandardChecks - Boolean -  if set to False, then all standard checks will
//    be skipped and hidden. Hidden checks are not included in the Result property
//    of the check certificate procedure for the common e-signature Client module. in addition, the Cryptography Manager
//    parameter will not be defined in the additional check Certificate procedures for the
//    common e-signature Undetectable and e-signature client Undetectable.
//
//  EnterPassword - Boolean -  if set to False, then entering the password for the private part of the certificate key will be hidden.
//    It is ignored if the standard Check parameter is not set to False.
//
Procedure OnCreateFormCertificateCheck(Certificate, AdditionalChecks, AdditionalChecksParameters, StandardChecks, EnterPassword = True) Export
	
	
	
EndProcedure

// Called from the certificate Check form if additional checks were added when creating the form.
//
// Parameters:
//  Parameters - Structure:
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
//   * Password               - String -  password entered by the user.
//                         - Undefined - 
//                              
//   * ChecksResults   - Structure:
//      * Key     - String -  name of the additional check that has already been performed.
//      * Value - Undefined -  additional verification was not performed (the error Description remains Undefined).
//                 - Boolean - 
//
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
//
Procedure OnFillCompanyAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Deprecated.
//
Procedure OnFillOwnerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Deprecated.
//
Procedure OnFillOfficerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

// Deprecated.
//
Procedure OnFillPartnerAttributesInApplicationForCertificate(Parameters) Export
	
EndProcedure

#EndRegion

#EndRegion