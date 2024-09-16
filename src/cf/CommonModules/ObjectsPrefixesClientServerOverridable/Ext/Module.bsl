///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Handler for the "when a number is received for printing" event.
// The event occurs before the standard processing of getting the number.
// In the handler, you can override the standard behavior of the system when generating a print number.
//
// Parameters:
//  ObjectNumber                     - String -  the number or code of the object that is being processed.
//  StandardProcessing             - Boolean -  standard processing flag; if the flag value is set to False,
//                                              the standard processing of printing number
//                                              generation will not be performed.
//  DeleteInfobasePrefix - Boolean -  a sign of the removal of the prefix information base;
//                                              the default value is False.
//  DeleteCustomPrefix   - Boolean -  flag for deleting a custom prefix;
//                                              the default value is False.
//
// Example:
//
//   Object Number = Prefixation Of Clientserver Objects.Delete The Userrefixing Of The Object's Numberobject (Object Number);
//   Standard Processing = False;
//
Procedure OnGetNumberForPrinting(ObjectNumber, StandardProcessing,
	DeleteInfobasePrefix, DeleteCustomPrefix) Export
	
EndProcedure

#EndRegion
