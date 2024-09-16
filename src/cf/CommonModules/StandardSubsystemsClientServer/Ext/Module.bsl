///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

//  
// 
// 
// Returns:
//  Structure:
//    * MetadataObjectsToSelectCollection - ValueList -  
//				:
//					
//					
//					
//
//    * FilterByMetadataObjects - ValueList -  
//				:
//					
//					
//					
//    * SelectedMetadataObjects - ValueList -  
//    			
//    * ChoiceInitialValue - String - 
//              
//    * SelectSingle - Boolean - 
//              
//    * ChooseRefs - Boolean - 
//    			
//    			See Common.MetadataObjectIDs.
//    * SelectCollectionsWhenAllObjectsSelected - Boolean - 
//    			 
//    			
//    * ShouldSelectExternalDataSourceTables - Boolean -  
//    * Title - String - 
//    * ObjectsGroupMethod - String - 
//    			
//    			
//    			 
//    			
//    * ParentSubsystems - ValueList -  
//				 
//    * SubsystemsWithCIOnly - Boolean -  
//				
//    * UUIDSource - UUID - 
//				
//				 
// 
Function MetadataObjectsSelectionParameters() Export
	
	FormParameters = New Structure;
	FormParameters.Insert("MetadataObjectsToSelectCollection", New ValueList);
	FormParameters.Insert("FilterByMetadataObjects", New ValueList);
	FormParameters.Insert("SelectedMetadataObjects", New ValueList);
	FormParameters.Insert("ChoiceInitialValue", "");
	FormParameters.Insert("SelectSingle", False);
	FormParameters.Insert("ChooseRefs", False);
	FormParameters.Insert("SelectCollectionsWhenAllObjectsSelected", False);
	FormParameters.Insert("ShouldSelectExternalDataSourceTables", False);
	FormParameters.Insert("Title", "");
	FormParameters.Insert("ObjectsGroupMethod", "ByKinds");
	FormParameters.Insert("ParentSubsystems", New ValueList);
	FormParameters.Insert("SubsystemsWithCIOnly", False);
	FormParameters.Insert("UUIDSource", Undefined);
	Return FormParameters;	
	
EndFunction

#EndRegion
