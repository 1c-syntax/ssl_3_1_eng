///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.TextWarning.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.TextWarning.Title,
		Metadata.Synonym, Metadata.Version, Metadata.Name, Metadata.Vendor);
	
	SourceConfigurations = GetFromTempStorage(Parameters.SourceConfigurations);
	ValueToFormAttribute(SourceConfigurations, "UpdateForVersions");
	
EndProcedure

#EndRegion

