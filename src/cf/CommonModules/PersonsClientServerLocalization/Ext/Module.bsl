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
//  FullName - String - 
//            - Structure:
//                        * LastName  - String
//                        * Name      - String
//                        * MiddleName - String
//  FullNameFormat - String - 
//  IsInitialsComeFirst    - Boolean - 
//                                
//  Result - String -  
//
Procedure OnDefineSurnameAndInitials(Val FullName, Val FullNameFormat, Val IsInitialsComeFirst, Result) Export
EndProcedure

// 
// 
// 
//
// Parameters:
//  FullName - String - 
//  NameFormat - String - 
//                         
//                         
//  Result - Structure:
//   * LastName  - String - 
//   * Name      - String - 
//   * MiddleName - String - 
//
// Example:
//    
//   
//    
//   
//    
//   
//
Procedure OnDefineFullNameComponents(Val FullName, Val NameFormat, Result) Export
EndProcedure

// 
//
// Parameters:
//  LastFirstName - String - 
//  IsOnlyNationalScriptLetters - Boolean - 
//  CheckResult - Boolean - 
//
Procedure FullNameWrittenCorrectly(Val LastFirstName, Val IsOnlyNationalScriptLetters, CheckResult) Export
	
	
EndProcedure

#EndRegion

