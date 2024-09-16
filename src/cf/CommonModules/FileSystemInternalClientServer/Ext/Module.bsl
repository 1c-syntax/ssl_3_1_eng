///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function UniqueFileName(Val FileName) Export
	
	File = New File(FileName);
	BaseName = File.BaseName;
	Extension = File.Extension;
	DirectoryName = File.Path;
	
	Counter = 1;
	While File.Exists() Do
		Counter = Counter + 1;
		File = New File(DirectoryName + BaseName + " (" + Counter + ")" + Extension);
	EndDo;
	
	Return File.FullName;

EndFunction

#EndRegion