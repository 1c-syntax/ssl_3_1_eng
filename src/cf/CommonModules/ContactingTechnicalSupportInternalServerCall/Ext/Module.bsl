///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

Function WorkWithExternalResourcesIsAvailable() Export
	
	Return Not ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	
EndFunction

Function TechnicalInformationArchiveAddress(Val RequestParameters_) Export
	
	TempDirectory = FileSystem.CreateTemporaryDirectory();
	FileAddresses = TechnicalInfoFilesAddresses(RequestParameters_);
	
	AddTechnicalInformationFileToTemporaryDirectory(
		FileAddresses.TechnologicalInfo,
		NStr("en = 'Технологическая информация.txt'"),
		TempDirectory);
	
	AddTechnicalInformationFileToTemporaryDirectory(
		FileAddresses.EventLog,
		NStr("en = 'Журнал регистрации.xml'"),
		TempDirectory);
	
	For Each AdditionalFile In RequestParameters_.AdditionalFiles Do
		AddTechnicalInformationFileToTemporaryDirectory(
			AdditionalFile.FileAddress,
			AdditionalFile.FullFileName,
			TempDirectory);
	EndDo;
	
	ArchiveOfTechnicalInformation = New ZipFileWriter();
	ArchiveOfTechnicalInformation.Add(TempDirectory);
	
	ArchiveData = ArchiveOfTechnicalInformation.GetBinaryData();
	Result = PutToTempStorage(ArchiveData, New UUID);
	
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	
	Return Result;
	
EndFunction

Function TechnicalInfoFilesAddresses(Val RequestParameters_) Export
	
	Result = New Structure("TechnologicalInfo, EventLog");
	Result.TechnologicalInfo = AddressTechnologicalInformation(RequestParameters_.TechnologicalInfo);
	Result.EventLog = AddressOfRegistrationLog(RequestParameters_.EventLogFilter);
	
	Return Result;
	
EndFunction

Function AddressTechnologicalInformation(TechnologicalInfo)
	
	TempFileName = GetTempFileName("txt");
	
	TextOfInformationForSupport = New TextDocument;
	TextOfInformationForSupport.SetText(TechnologicalInfo);
	TextOfInformationForSupport.Write(TempFileName);
	
	Result = PutToTempStorage(New BinaryData(TempFileName), New UUID);
	
	DeleteFiles(TempFileName);
	
	Return Result;
	
EndFunction

Function AddressOfRegistrationLog(EventLogFilter)
	
	SecondsBeforeEventsStart = 600;
	
	If EventLogFilter.Property("StartDate") Then // 
		StartDate = EventLogFilter.StartDate - SecondsBeforeEventsStart;
	Else
		StartDate = CurrentSessionDate() - SecondsBeforeEventsStart;
	EndIf;
	
	EventLogFilter.Insert("StartDate", StartDate);
	EventLogFilter.Insert("User", InfoBaseUsers.CurrentUser());
	
	EventCount1 = 100;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Result = EventLog.TechnicalSupportLog(EventLogFilter, EventCount1);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

Function AddressOfScreenshot(Val ScreenShot) Export
	
	Return PutToTempStorage(ScreenShot.GetBinaryData(), New UUID);
	
EndFunction

Procedure AddTechnicalInformationFileToTemporaryDirectory(FileAddress, FileName, TempDirectory)
	
	BinaryData = GetFromTempStorage(FileAddress);
	BinaryData.Write(TempDirectory + FileName);
	
	DeleteFromTempStorage(FileAddress);
	
EndProcedure

#EndRegion
