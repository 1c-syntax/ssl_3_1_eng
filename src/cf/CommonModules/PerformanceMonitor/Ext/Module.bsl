///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Starts measuring the time of the key operation. You must explicitly end the measurement by calling
// the end Timestamp or end Timestamptechnological procedure.
//
// Returns:
//  Number - 
//
Function StartTimeMeasurement() Export

	BeginTime = 0;

	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		BeginTime = CurrentUniversalDateInMilliseconds();
	EndIf;

	Return BeginTime;

EndFunction

// Completes the key operation time measurement
// and writes the result to the time Measurement information register.
//
// Parameters:
//   KeyOperation	- CatalogRef.KeyOperations
//                   	- String -  key operation.
//  BeginTime			- Number										-  universal date, in milliseconds,
//								  				  					  returned at the start of measurement by the performance Estimation function.Start timestamp.
//  MeasurementWeight			- Number										-  a quantitative measurement indicator, such as the number of lines in a document.
//  Comment			- String
//             			- Map - 
//  CompletedWithError	- Boolean									-  an indication that the measurement was not completed before the end of,
//
Procedure EndTimeMeasurement(KeyOperation, BeginTime, MeasurementWeight = 1, Comment = Undefined,
	CompletedWithError = False) Export
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		EndTime = CurrentUniversalDateInMilliseconds();
		Duration = (EndTime - BeginTime) / 1000;

		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", Duration);
		MeasurementParameters.Insert("KeyOperationStartDate", BeginTime);
		MeasurementParameters.Insert("KeyOperationEndDate", EndTime);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementWeight);
		MeasurementParameters.Insert("Comment", Comment);
		MeasurementParameters.Insert("Technological", False);
		MeasurementParameters.Insert("TimeConsuming", False);
		MeasurementParameters.Insert("CompletedWithError", CompletedWithError);

		RecordKeyOperationDuration(MeasurementParameters);
	EndIf;
EndProcedure

// Completes the measurement time key operation
// and writes the result to the register information Sametimeintegration.
//
// Parameters:
//   KeyOperation	- CatalogRef.KeyOperations
//                   	- String -  key operation.
//  BeginTime			- Number										-  universal date, in milliseconds,
//								  				  					  returned at the start of measurement by the performance Estimation function.Start timestamp.
//  MeasurementWeight			- Number										-  a quantitative measurement indicator, such as the number of lines in a document.
//  Comment			- String
//             			- Map - 
//
Procedure EndTechnologicalTimeMeasurement(KeyOperation, BeginTime, MeasurementWeight = 1,
	Comment = Undefined) Export
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		EndTime = CurrentUniversalDateInMilliseconds();
		Duration = (EndTime - BeginTime) / 1000;

		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", Duration);
		MeasurementParameters.Insert("KeyOperationStartDate", BeginTime);
		MeasurementParameters.Insert("KeyOperationEndDate", EndTime);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementWeight);
		MeasurementParameters.Insert("Comment", Comment);
		MeasurementParameters.Insert("Technological", True);
		MeasurementParameters.Insert("TimeConsuming", False);
		MeasurementParameters.Insert("CompletedWithError", False);

		RecordKeyOperationDuration(MeasurementParameters);
	EndIf;
EndProcedure

// Creates a key operation in the event of their absence.
//
// Parameters:
//  KeyOperations - Array -  key operations, array element-Structure ("key operation Name, target Time").
//
Procedure CreateKeyOperations(KeyOperations) Export
	Table = New ValueTable;
	Table.Columns.Add("KeyOperationName", New TypeDescription("String", , , ,
		New StringQualifiers(1000)));
	Table.Columns.Add("ResponseTimeThreshold", New TypeDescription("Number", , , New NumberQualifiers(15, 2)));

	For Each KeyOperation In KeyOperations Do
		FillPropertyValues(Table.Add(), KeyOperation);
	EndDo;

	Query = New Query;
	Query.Text = "SELECT
				   |	Table.KeyOperationName AS KeyOperationName,
				   |	Table.ResponseTimeThreshold AS ResponseTimeThreshold
				   |INTO Table
				   |FROM
				   |	&Table AS Table
				   |;
				   |
				   |////////////////////////////////////////////////////////////////////////////////
				   |SELECT
				   |	ISNULL(KeyOperations.Ref, VALUE(Catalog.KeyOperations.EmptyRef)) AS Ref,
				   |	Table.KeyOperationName AS KeyOperationName,
				   |	Table.ResponseTimeThreshold AS ResponseTimeThreshold
				   |FROM
				   |	Table AS Table
				   |		LEFT JOIN Catalog.KeyOperations AS KeyOperations
				   |		ON Table.KeyOperationName = KeyOperations.Name";
	Query.SetParameter("Table", Table);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	Selection = QueryResult.Select();

	While Selection.Next() Do
		If Selection.Ref.IsEmpty() Then
			CreateKeyOperation(Selection.KeyOperationName, Selection.ResponseTimeThreshold); // 
		EndIf;
	EndDo;
EndProcedure

// Sets a new target time for the operation.
//
// Parameters:
//  KeyOperations - Array -  key operations, array element-Structure ("key operation Name, target Time").
//
Procedure SetTimeThreshold(KeyOperations) Export

	Table = New ValueTable;
	Table.Columns.Add("KeyOperationName", New TypeDescription("String", , , ,
		New StringQualifiers(1000)));
	Table.Columns.Add("ResponseTimeThreshold", New TypeDescription("Number", , , New NumberQualifiers(15, 2)));

	For Each KeyOperation In KeyOperations Do
		FillPropertyValues(Table.Add(), KeyOperation);
	EndDo;

	Query = New Query;
	Query.Text = "SELECT
				   |	Table.KeyOperationName AS KeyOperationName,
				   |	Table.ResponseTimeThreshold AS ResponseTimeThreshold
				   |INTO Table
				   |FROM
				   |	&Table AS Table
				   |;
				   |
				   |////////////////////////////////////////////////////////////////////////////////
				   |SELECT
				   |	KeyOperations.Ref AS Ref,
				   |	Table.ResponseTimeThreshold AS ResponseTimeThreshold
				   |FROM
				   |	Catalog.KeyOperations AS KeyOperations
				   |		INNER JOIN Table AS Table
				   |		ON KeyOperations.Name = Table.KeyOperationName
				   |
				   |ORDER BY
				   |	Ref";
	Query.SetParameter("Table", Table);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	Selection = QueryResult.Select();

	BeginTransaction();
	Try
		Block = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Block.Add("Catalog.KeyOperations");
			LockItem.SetValue("Name", KeyOperation.KeyOperationName);
		EndDo;
		Block.Lock();
		While Selection.Next() Do
			KeyOperationObject = Selection.Ref.GetObject(); // CatalogObject.KeyOperations
			KeyOperationObject.ResponseTimeThreshold = Selection.ResponseTimeThreshold;
			KeyOperationObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// Changes key operations.
//
// Parameters:
//  KeyOperations - Array -  key operations,
//								array element-Structure ("Keyoperation_name, Keyoperation_name, target Time")
//								or
//								array element - Structure ("Keyoperation_name, Keyoperation_name"),
//								the target time does not change.
//
Procedure ChangeKeyOperations(KeyOperations) Export

	Table = New ValueTable;
	Table.Columns.Add("NameOfKeyOperationIsOld", New TypeDescription("String", , , ,
		New StringQualifiers(1000)));
	Table.Columns.Add("KeyOperationNameNew", New TypeDescription("String", , , ,
		New StringQualifiers(1000)));
	Table.Columns.Add("ResponseTimeThreshold", New TypeDescription("Number", , , New NumberQualifiers(15, 2)));

	For Each KeyOperation In KeyOperations Do
		FillPropertyValues(Table.Add(), KeyOperation);
	EndDo;

	Query = New Query;
	Query.Text = "SELECT
				   |	Table.NameOfKeyOperationIsOld AS NameOfKeyOperationIsOld,
				   |	Table.KeyOperationNameNew AS KeyOperationNameNew,
				   |	Table.ResponseTimeThreshold AS ResponseTimeThreshold
				   |INTO Table
				   |FROM
				   |	&Table AS Table
				   |;
				   |
				   |////////////////////////////////////////////////////////////////////////////////
				   |SELECT
				   |	KeyOperations.Ref AS Ref,
				   |	Table.KeyOperationNameNew AS KeyOperationNameNew,
				   |	CASE
				   |		WHEN Table.ResponseTimeThreshold = 0
				   |			THEN KeyOperations.ResponseTimeThreshold
				   |		ELSE Table.ResponseTimeThreshold
				   |	END AS ResponseTimeThreshold
				   |FROM
				   |	Catalog.KeyOperations AS KeyOperations
				   |		INNER JOIN Table AS Table
				   |		ON KeyOperations.Name = Table.NameOfKeyOperationIsOld
				   |
				   |ORDER BY
				   |	Ref";
	Query.SetParameter("Table", Table);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	Selection = QueryResult.Select();

	BeginTransaction();
	Try

		Block = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Block.Add("Catalog.KeyOperations");
			LockItem.SetValue("Name", KeyOperation.NameOfKeyOperationIsOld);

			LockItem = Block.Add("Catalog.KeyOperations");
			LockItem.SetValue("Name", KeyOperation.KeyOperationNameNew);
		EndDo;
		Block.Lock();

		While Selection.Next() Do
			KeyOperationObject = Selection.Ref.GetObject(); // CatalogObject.KeyOperations
			KeyOperationObject.Name = Selection.KeyOperationNameNew;
			KeyOperationObject.Description = SplitStringByWords(Selection.KeyOperationNameNew);
			KeyOperationObject.ResponseTimeThreshold = Selection.ResponseTimeThreshold;
			KeyOperationObject.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// Starts measuring the time of a long key operation. You must explicitly end the measurement by calling
// the end-of-the-freeze Operation procedure.
//
// Parameters:
//   KeyOperation	- String -  key operation.
//
// Returns:
//   Map of KeyAndValue:
//     * Key - String
//     * Value - Arbitrary
//   :
//    
//    
//    
//    
//    
//
Function StartTimeConsumingOperationMeasurement(KeyOperation) Export

	MeasurementDetails = New Map;
	If PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		BeginTime = CurrentUniversalDateInMilliseconds();
		MeasurementDetails.Insert("KeyOperation", KeyOperation);
		MeasurementDetails.Insert("BeginTime", BeginTime);
		MeasurementDetails.Insert("LastMeasurementTime", BeginTime);
		MeasurementDetails.Insert("MeasurementWeight", 0);
		MeasurementDetails.Insert("NestedMeasurements", New Map);
	EndIf;

	Return MeasurementDetails;

EndFunction

// Captures the measurement of the nested step of a long operation.
// Parameters:
//  MeasurementDetails 		- Map	 -  must be obtained by calling the start method of a slow Operation.
//  DataVolume 	- Number			 -  the amount of data, for example, of rows processed during execution of a nested step.
//  StepName 			- String		 -  custom name of the nested step.
//  Comment 		- String		 -  any additional description of the measurement.
//
Procedure FixTimeConsumingOperationMeasure(MeasurementDetails, DataVolume, StepName, Comment = "") Export

	If Not ValueIsFilled(MeasurementDetails) Then
		Return;
	EndIf;

	CurrentTime = CurrentUniversalDateInMilliseconds();

	Duration = CurrentTime - MeasurementDetails["LastMeasurementTime"];
	DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
	// 
	NestedMeasurements = MeasurementDetails["NestedMeasurements"];
	If NestedMeasurements[StepName] = Undefined Then
		NestedMeasurements.Insert(StepName, New Map);
		NestedMeasurementStep = NestedMeasurements[StepName];
		NestedMeasurementStep.Insert("Comment", Comment);
		NestedMeasurementStep.Insert("BeginTime", MeasurementDetails["LastMeasurementTime"]);
		NestedMeasurementStep.Insert("Duration", 0.0);
		NestedMeasurementStep.Insert("MeasurementWeight", 0);
	EndIf;                                                            
	// 
	NestedMeasurementStep = NestedMeasurements[StepName];
	NestedMeasurementStep.Insert("EndTime", CurrentTime);
	NestedMeasurementStep.Insert("Duration", Duration + NestedMeasurementStep["Duration"]);
	NestedMeasurementStep.Insert("MeasurementWeight", DataVolumeInStep + NestedMeasurementStep["MeasurementWeight"]);
	
	// 
	MeasurementDetails.Insert("LastMeasurementTime", CurrentTime);
	MeasurementDetails.Insert("MeasurementWeight", DataVolumeInStep + MeasurementDetails["MeasurementWeight"]);

EndProcedure

// Completes the measurement of a long operation.
// If a step name is specified, captures it as a separate nested step
// Parameters:
//  MeasurementDetails 		- Map	 -  must be obtained by calling the start method of a slow Operation.
//  DataVolume 	- Number			 -  the amount of data, for example, of rows processed during execution of a nested step.
//  StepName 			- String		 -  custom name of the nested step.
//  Comment 		- String		 -  any additional description of the measurement.
//
Procedure EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume, StepName = "", Comment = "") Export

	If Not ValueIsFilled(MeasurementDetails) Then
		Return;
	EndIf;

	If MeasurementDetails["Client"] = True Then
		Return;
	EndIf;
	
	// 
	MeasurementStartTime	 = MeasurementDetails["BeginTime"];
	KeyOperationName	 = MeasurementDetails["KeyOperation"];
	NestedMeasurements		 = MeasurementDetails["NestedMeasurements"];
	
	// 
	NestedMeasurementsAvailable = NestedMeasurements.Count();
	CurrentTime = CurrentUniversalDateInMilliseconds();
	Duration = CurrentTime - MeasurementStartTime;
	WeightedTimeTotal = 0;
	
	// 
	DataVolumeInStep = ?(DataVolume = 0, 1, DataVolume);
	If NestedMeasurementsAvailable Then
		FixTimeConsumingOperationMeasure(MeasurementDetails, DataVolumeInStep, ?(IsBlankString(StepName),
			"LastStep", StepName), Comment);
	EndIf;

	MeasurementsArrayToWrite = New Array;

	For Each Measurement In NestedMeasurements Do
		MeasurementData = Measurement.Value;
		NestedMeasurementWeight = MeasurementData["MeasurementWeight"];
		NestedMeasurementDuration = MeasurementData["Duration"];
		KeyOperation = KeyOperationName + "." + Measurement.Key;
		WeightedTime = ?(NestedMeasurementWeight = 0, NestedMeasurementDuration, NestedMeasurementDuration
			/ NestedMeasurementWeight);
		WeightedTimeTotal = WeightedTimeTotal + WeightedTime;

		MeasurementParameters = New Structure;
		MeasurementParameters.Insert("KeyOperation", KeyOperation);
		MeasurementParameters.Insert("Duration", WeightedTime / 1000);
		MeasurementParameters.Insert("KeyOperationStartDate", MeasurementData["BeginTime"]);
		MeasurementParameters.Insert("KeyOperationEndDate", MeasurementData["EndTime"]);
		MeasurementParameters.Insert("MeasurementWeight", NestedMeasurementWeight);
		MeasurementParameters.Insert("Comment", MeasurementData["Comment"]);
		MeasurementParameters.Insert("Technological", False);
		MeasurementParameters.Insert("TimeConsuming", True);

		MeasurementsArrayToWrite.Add(MeasurementParameters);
	EndDo;
	
	// 
	MeasurementParameters = New Structure;
	MeasurementParameters.Insert("KeyOperation", KeyOperationName + ".Specific");
	MeasurementParameters.Insert("KeyOperationStartDate", MeasurementStartTime);
	MeasurementParameters.Insert("KeyOperationEndDate", CurrentTime);
	MeasurementParameters.Insert("Comment", Comment);
	MeasurementParameters.Insert("Technological", False);
	MeasurementParameters.Insert("TimeConsuming", True);

	If NestedMeasurementsAvailable Then
		MeasurementParameters.Insert("Duration", WeightedTimeTotal / 1000);
		MeasurementParameters.Insert("MeasurementWeight", MeasurementDetails["MeasurementWeight"]);
	Else
		// 
		MeasurementParameters.Insert("Duration", Duration / 1000 / DataVolumeInStep);
		MeasurementParameters.Insert("MeasurementWeight", DataVolumeInStep);
	EndIf;
	MeasurementsArrayToWrite.Add(MeasurementParameters);
	
	// 
	MeasurementParameters = New Structure;
	MeasurementParameters.Insert("KeyOperation", KeyOperationName);
	MeasurementParameters.Insert("Duration", (Duration) / 1000);
	MeasurementParameters.Insert("KeyOperationStartDate", MeasurementStartTime);
	MeasurementParameters.Insert("KeyOperationEndDate", CurrentTime);
	If NestedMeasurementsAvailable Then
		MeasurementParameters.Insert("MeasurementWeight", MeasurementDetails["MeasurementWeight"]);
	Else
		MeasurementParameters.Insert("MeasurementWeight", DataVolumeInStep);
	EndIf;
	MeasurementParameters.Insert("Comment", Comment);
	MeasurementParameters.Insert("Technological", False);
	MeasurementParameters.Insert("TimeConsuming", False);

	MeasurementsArrayToWrite.Add(MeasurementParameters);

	WriteTimeMeasurements(MeasurementsArrayToWrite);

EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Parameters:
//  KeyOperations - Array -  key operations, array element-Structure ("key operation Name, Attribute").
//
Procedure SetCompletedWithErrorFlag(KeyOperations) Export

	Query = New Query;
	Query.Text = "SELECT TOP 1
				   |	KeyOperations.Ref AS Ref
				   |FROM
				   |	Catalog.KeyOperations AS KeyOperations
				   |WHERE
				   |	KeyOperations.Name = &Name
				   |ORDER BY
				   |	Ref";

	BeginTransaction();
	Try

		Block = New DataLock;
		For Each KeyOperation In KeyOperations Do
			LockItem = Block.Add("Catalog.KeyOperations");
			LockItem.SetValue("Name", KeyOperation.KeyOperationName);
		EndDo;
		Block.Lock();

		For Each KeyOperation In KeyOperations Do
			Query.SetParameter("Name", KeyOperation.KeyOperationName);
			QueryResult = Query.Execute(); // 
			If Not QueryResult.IsEmpty() Then
				Selection = QueryResult.Select();
				Selection.Next();
				KeyOperationRef = Selection.Ref;
				KeyOperationObject = KeyOperationRef.GetObject(); // CatalogObject.KeyOperations
				KeyOperationObject.IsFailed = KeyOperation.Flag;

				KeyOperationObject.Write();
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Enables / disables performance measurements
//
Procedure EnablePerformanceMeasurements(Parameter) Export

	Constants.RunPerformanceMeasurements.Set(Parameter);

EndProcedure

#EndRegion

#Region Private

// Creates a new element of the "Key operations"reference list.
//
// Parameters:
//  KeyOperationName - String -  name of the key operation.
//  ResponseTimeThreshold - Number -  target time of the key operation.
//  TimeConsuming - Boolean -  indicates whether the specific time for measuring a key operation is fixed.
//
// Returns:
//  CatalogRef.KeyOperations
//
Function CreateKeyOperation(KeyOperationName, ResponseTimeThreshold = 1, TimeConsuming = False) Export

	SetPrivilegedMode(True);

	BeginTransaction();

	Try
		Block = New DataLock;
		LockItem = Block.Add("Catalog.KeyOperations");
		LockItem.SetValue("Name", KeyOperationName);
		Block.Lock();

		Query = New Query;
		Query.Text = "SELECT TOP 1
					   |	KeyOperations.Ref AS Ref
					   |FROM
					   |	Catalog.KeyOperations AS KeyOperations
					   |WHERE
					   |	KeyOperations.NameHash = &NameHash
					   |
					   |ORDER BY
					   |	Ref";

		MD5Hash = New DataHashing(HashFunction.MD5);
		MD5Hash.Append(KeyOperationName);
		NameHash = MD5Hash.HashSum;
		NameHash = StrReplace(String(NameHash), " ", "");

		Query.SetParameter("NameHash", NameHash);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			Description = SplitStringByWords(KeyOperationName);

			NewItem = PerformanceMonitorInternal.ServiceItem(
				Catalogs.KeyOperations);
			NewItem.Name = KeyOperationName;
			NewItem.Description = Description;
			NewItem.NameHash = NameHash;
			NewItem.ResponseTimeThreshold = ResponseTimeThreshold;
			NewItem.TimeConsuming = TimeConsuming;
			NewItem.Write();
			KeyOperationRef = NewItem.Ref;
		Else
			Selection = QueryResult.Select();
			Selection.Next();
			KeyOperationRef = Selection.Ref;
		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	Return KeyOperationRef;

EndFunction

// Splits a string of several combined words into a string with individual words.
// An uppercase character is considered a sign of the beginning of a new word.
//
// Parameters:
//  String                 - String -  delimited text;
//
// Returns:
//  String - 
//
// :
//  
//  
//
Function SplitStringByWords(Val String)

	WordArray = New Array;

	WordPositions = New Array;
	For CharPosition = 1 To StrLen(String) Do
		CurChar = Mid(String, CharPosition, 1);
		If CurChar = Upper(CurChar) And (PerformanceMonitorClientServer.OnlyLatinInString(CurChar)
			Or PerformanceMonitorClientServer.OnlyRomanInString(CurChar)) Then
			WordPositions.Add(CharPosition);
		EndIf;
	EndDo;

	If WordPositions.Count() > 0 Then
		PreviousPosition = 0;
		For Each Position In WordPositions Do
			If PreviousPosition > 0 Then
				Substring = Mid(String, PreviousPosition, Position - PreviousPosition);
				If Not IsBlankString(Substring) Then
					WordArray.Add(TrimAll(Substring));
				EndIf;
			EndIf;
			PreviousPosition = Position;
		EndDo;

		Substring = Mid(String, Position);
		If Not IsBlankString(Substring) Then
			WordArray.Add(TrimAll(Substring));
		EndIf;
	EndIf;

	For IndexOf = 1 To WordArray.UBound() Do
		WordArray[IndexOf] = Lower(WordArray[IndexOf]);
	EndDo;

	If WordArray.Count() <> 0 Then
		Result = StrConcat(WordArray, " ");
	Else
		Result = String;
	EndIf;

	Return Result;

EndFunction

// Current value of the measurement results recording period on the server
//
// Returns:
//   Number - 
//
Function RecordPeriod() Export
	CurrentPeriod = Constants.PerformanceMonitorRecordPeriod.Get();
	Return ?(CurrentPeriod > 60, CurrentPeriod, 60);
EndFunction

// Procedure for recording a single measurement
//
// Parameters:
//  Key Operation-Reference Link.Key operations - key operation
//						or String - name of the key operation
//  Duration - The Number
//  Distanceluminosity Of - Date.
//
Procedure RecordKeyOperationDuration(Parameters)

	KeyOperation				 = Parameters.KeyOperation;
	Duration					 = Parameters.Duration;
	KeyOperationStartDate		 = Parameters.KeyOperationStartDate;
	KeyOperationEndDate	 = Parameters.KeyOperationEndDate;
	MeasurementWeight						 = Parameters.MeasurementWeight;
	Comment						 = Parameters.Comment;
	Technological					 = Parameters.Technological;
	TimeConsuming						 = Parameters.TimeConsuming;
	CompletedWithError				 = Parameters.CompletedWithError;

	If Not ValueIsFilled(KeyOperationStartDate) Then
		WriteLogEvent(NStr("en = 'Sampling error. Start date required';",
			PerformanceMonitorInternal.DefaultLanguageCode()), EventLogLevel.Information,,, String(
			KeyOperation));

		Return;
	EndIf;

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	If TypeOf(KeyOperation) = Type("String") Then
		KeyOperationRef = PerformanceMonitorCached.GetKeyOperationByName(KeyOperation,
			TimeConsuming);
	Else
		KeyOperationRef = KeyOperation;
	EndIf;

	If Comment = Undefined Then
		Comment = SessionParameters.TimeMeasurementComment;
	Else
		DefaultComment = Common.JSONValue(SessionParameters.TimeMeasurementComment);
		DefaultComment.Insert("AddlInf", Comment);

		JSONWriter = New JSONWriter;
		JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
		WriteJSON(JSONWriter, DefaultComment);
		Comment = JSONWriter.Close();
	EndIf;

	If Not Technological Then
		Record = InformationRegisters.TimeMeasurements.CreateRecordManager();
	Else
		Record = InformationRegisters.TimeMeasurementsTechnological.CreateRecordManager();
	EndIf;

	Record.KeyOperation = KeyOperationRef;
	
	// 
	Record.MeasurementStartDate = KeyOperationStartDate;
	Record.SessionNumber = InfoBaseSessionNumber();

	Record.RunTime = ?(Duration = 0, 0.001, Duration); // 
	Record.MeasurementWeight = MeasurementWeight;

	Record.RecordDate = Date(1, 1, 1) + CurrentUniversalDateInMilliseconds() / 1000;
	Record.RecordDateBegOfHour = BegOfHour(Record.RecordDate);
	If KeyOperationEndDate <> Undefined Then
		// 
		Record.EndDate = KeyOperationEndDate;
	EndIf;
	Record.User = InfoBaseUsers.CurrentUser();
	Record.RecordDateLocal = CurrentSessionDate();
	Record.Comment = Comment;
	If Not Technological Then
		Record.CompletedWithError = CompletedWithError;
	EndIf;

	Record.Write();

EndProcedure

// Records the passed array of measurements.
// The elements of the array - type structure.
// Recording is performed by a set of records.
//   Key operation - name of the key operation.
//   Duration - duration in milliseconds.
//   Distanceluminosity - the start key of the operation in milliseconds.
//   Key operation end dateis the time when the key operation ends, in milliseconds.
//   Comment - any string, measurement comment.
//   Measure weight - the amount of data processed.
//   Long - indicates that the measurement duration is calculated per unit weight.
//
Procedure WriteTimeMeasurements(MeasurementsArray)

	If ExclusiveMode() Then
		Return;
	EndIf;

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	RecordSet = InformationRegisters.TimeMeasurements.CreateRecordSet();
	SessionNumber = InfoBaseSessionNumber();
	RecordDate = Date(1, 1, 1) + CurrentUniversalDateInMilliseconds() / 1000;
	RecordDateBegOfHour = BegOfHour(RecordDate);
	User = InfoBaseUsers.CurrentUser();
	RecordDateLocal = CurrentSessionDate();

	For Each Measurement In MeasurementsArray Do

		If Not ValueIsFilled(Measurement.KeyOperationStartDate) Then
			WriteLogEvent(NStr("en = 'Sampling error. Start date required';",
				PerformanceMonitorInternal.DefaultLanguageCode()), EventLogLevel.Information,,, String(
				Measurement.KeyOperation));
			Return;
		EndIf;

		If TypeOf(Measurement.KeyOperation) = Type("String") Then
			KeyOperationRef = PerformanceMonitorCached.GetKeyOperationByName(
				Measurement.KeyOperation, Measurement.TimeConsuming);
		Else
			KeyOperationRef = Measurement.KeyOperation;
		EndIf;

		If Not ValueIsFilled(Measurement.Comment) Then
			Comment = SessionParameters.TimeMeasurementComment;
		Else
			DefaultComment = Common.JSONValue(SessionParameters.TimeMeasurementComment);
			DefaultComment.Insert("AddlInf", Measurement.Comment);

			JSONWriter = New JSONWriter;
			JSONWriter.SetString(New JSONWriterSettings(JSONLineBreak.None));
			WriteJSON(JSONWriter, DefaultComment);
			Comment = JSONWriter.Close();
		EndIf;

		Record = RecordSet.Add();

		Record.KeyOperation = KeyOperationRef;
	
		// 
		Record.MeasurementStartDate = Measurement.KeyOperationStartDate;
		Record.SessionNumber = SessionNumber;

		Record.RunTime = ?(Measurement.Duration = 0, 0.001, Measurement.Duration); // 
		Record.MeasurementWeight = Measurement.MeasurementWeight;

		Record.RecordDate = RecordDate;
		Record.RecordDateBegOfHour = RecordDateBegOfHour;
		If ValueIsFilled(Measurement.KeyOperationEndDate) Then
			// 
			Record.EndDate = Measurement.KeyOperationEndDate;
		EndIf;
		Record.User = User;
		Record.RecordDateLocal = RecordDateLocal;
		Record.Comment = Comment;

	EndDo;

	If RecordSet.Count() > 0 Then
		Try
			RecordSet.Write(False);
		Except
			WriteLogEvent(NStr("en = 'Performance monitor.Error saving measurements';",
				PerformanceMonitorInternal.DefaultLanguageCode()), EventLogLevel.Error,,,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;

	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);

EndProcedure

// Procedure for processing a routine task for uploading data
//
// Parameters:
//  DirectoriesForExport - Structure -  a structure with an Array value.
//   AddlParameters - Structure -  advanced setting.
//
Procedure PerformanceMonitorDataExport(DirectoriesForExport, AddlParameters = Undefined) Export

	If PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = PerformanceMonitorInternal.CommonModule("Common");
		ModuleCommon.OnStartExecuteScheduledJob(
			Metadata.ScheduledJobs.PerformanceMonitorDataExport);
	EndIf;
		
	// 
	If AddlParameters = Undefined
		And Not PerformanceMonitorServerCallCached.RunPerformanceMeasurements() Then
		Return;
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Measurements.RecordDate) AS MeasurementDate
	|FROM 
	|	InformationRegister.TimeMeasurements AS Measurements
	|WHERE
	|	Measurements.RecordDate <= &CurDate";

	If AddlParameters = Undefined Then
		Query.SetParameter("CurDate", CurrentUniversalDate() - 1);
	Else
		Query.SetParameter("CurDate", AddlParameters.EndDate);
	EndIf;

	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.MeasurementDate <> Null Then
		MeasurementsDateUpperBoundary = Selection.MeasurementDate;
	Else
		Return;
	EndIf;

	MeasurementsArrays = MeasurementsDividedByKeyOperations(MeasurementsDateUpperBoundary, AddlParameters);

	FileSequenceNumber = 0;
	CurDate = CurrentUniversalDateInMilliseconds();
	If AddlParameters <> Undefined Then
		TempDirectory = GetTempFileName();
		CreateDirectory(TempDirectory);

		DirectoriesForExport = New Structure("LocalExportDirectory, FTPExportDirectory", New Array, New Array);
		DirectoriesForExport.LocalExportDirectory.Add(True);
		DirectoriesForExport.LocalExportDirectory.Add(TempDirectory);
		DirectoriesForExport.FTPExportDirectory.Add(False);
		DirectoriesForExport.FTPExportDirectory.Add("");
	EndIf;

	For Each MeasurementsArray In MeasurementsArrays Do
		FileSequenceNumber = FileSequenceNumber + 1;
		ExportResults(DirectoriesForExport, MeasurementsArray, CurDate, FileSequenceNumber);
	EndDo;

	If AddlParameters <> Undefined Then
		DataFiles1 = FindFiles(TempDirectory, "*.xml");
		ZipFileWriter = New ZipFileWriter;
		ArchiveName = GetTempFileName("zip");
		ZipFileWriter.Open(ArchiveName,,, ZIPCompressionMethod.Deflate);
		For Each DataFile In DataFiles1 Do
			ZipFileWriter.Add(DataFile.FullName);
		EndDo;
		ZipFileWriter.Write();

		BinaryDataArchive = New BinaryData(ArchiveName);
		PutToTempStorage(BinaryDataArchive, AddlParameters.StorageAddress);

		DeleteFiles(TempDirectory);
		DeleteFiles(ArchiveName);
	EndIf;

EndProcedure

// Procedure for processing a routine task for clearing measurement registers
Procedure ClearTimeMeasurementsRegisters() Export

	If PerformanceMonitorInternal.SubsystemExists("StandardSubsystems.Core") Then
		ModuleCommon = PerformanceMonitorInternal.CommonModule("Common");
		ModuleCommon.OnStartExecuteScheduledJob(
			Metadata.ScheduledJobs.ClearTimeMeasurements);
	EndIf;

	DeletionBoundary = BegOfDay(CurrentUniversalDate() - 86400 * Constants.KeepMeasurementsPeriod.Get());

	TimeMeasurementsQuery = New Query;
	TimeMeasurementsQuery.Text = "
								|SELECT
								|	MIN(RecordDateBegOfHour) AS RecordDateBegOfHour
								|FROM
								|	InformationRegister.TimeMeasurements
								|WHERE
								|	RecordDateBegOfHour < &DeletionBoundary
								|";
	TimeMeasurementsQuery.SetParameter("DeletionBoundary", DeletionBoundary);

	TechnologicalTimeMeasurementsQuery = New Query;
	TechnologicalTimeMeasurementsQuery.Text = "
											   |SELECT
											   |	MIN(RecordDateBegOfHour) AS RecordDateBegOfHour
											   |FROM
											   |	InformationRegister.TimeMeasurementsTechnological
											   |WHERE
											   |	RecordDateBegOfHour < &DeletionBoundary
											   |";
	TechnologicalTimeMeasurementsQuery.SetParameter("DeletionBoundary", DeletionBoundary);

	RecordSet = InformationRegisters.TimeMeasurements.CreateRecordSet();
	RecordSetTechnologicalRecords = InformationRegisters.TimeMeasurementsTechnological.CreateRecordSet();

	DeletionRequired = True;
	TechnologicalDeletionRequired = True;
	While DeletionRequired Or TechnologicalDeletionRequired Do

		If DeletionRequired Then
			DeletionRequired = False;

			Result = TimeMeasurementsQuery.Execute(); // 
			Selection = Result.Select();
			Selection.Next();
			RecordDateBegOfHour = Selection.RecordDateBegOfHour;

			If Not RecordDateBegOfHour = Null Then
				RecordSet.Filter.RecordDateBegOfHour.Set(RecordDateBegOfHour);
				RecordSet.Write(True);
				DeletionRequired = True;
			EndIf;
		EndIf;

		If TechnologicalDeletionRequired Then
			TechnologicalDeletionRequired = False;
			Result = TechnologicalTimeMeasurementsQuery.Execute(); // 
			Selection = Result.Select();
			Selection.Next();
			RecordDateBegOfHour = Selection.RecordDateBegOfHour;
			If Not RecordDateBegOfHour = Null Then
				RecordSetTechnologicalRecords.Filter.RecordDateBegOfHour.Set(RecordDateBegOfHour);
				RecordSetTechnologicalRecords.Write(True);
				TechnologicalDeletionRequired = True;
			EndIf;
		EndIf;

	EndDo;

EndProcedure

// Routine export task
// Parameters:
//   AddlParameters - Structure:
//   * StartDate - Date -  measurement start date
//   * EndDate - Date -  end date of measurements.
//
Function MeasurementsDividedByKeyOperations(MeasurementsDateUpperBoundary, AddlParameters = Undefined)

	Query = New Query;

	PerformanceLevelsNumber = New Map;
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Excellent, 1);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Good, 0.94);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Bad, 0.85);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.VeryPoor, 0.70);
	PerformanceLevelsNumber.Insert(Enums.PerformanceLevels.Unacceptable, 0.50);

	If AddlParameters = Undefined Then
		QueryText = TimeMeasurementsWithoutProfileFiltering();
		Query.SetParameter("LastExportDate",
			Constants.LastPerformanceMeasurementsExportDateUTC.Get());
		Query.SetParameter("MeasurementsDateUpperBoundary", MeasurementsDateUpperBoundary);
		Constants.LastPerformanceMeasurementsExportDateUTC.Set(MeasurementsDateUpperBoundary);
	Else
		If ValueIsFilled(AddlParameters.Profile) Then
			QueryText = TimeMeasurementsWithProfileFiltering();
			Query.SetParameter("Profile", AddlParameters.Profile);
		Else
			QueryText = TimeMeasurementsWithoutProfileFiltering();
		EndIf;
		Query.SetParameter("LastExportDate", AddlParameters.StartDate);
		Query.SetParameter("MeasurementsDateUpperBoundary", AddlParameters.EndDate);
	EndIf;

	Query.Text = QueryText;

	Result = Query.Execute();

	MeasurementsCountInFile = Constants.MeasurementsCountInExportPackage.Get();
	MeasurementsCountInFile = ?(MeasurementsCountInFile <> 0, MeasurementsCountInFile, 1000);

	MeasurementsByFiles = New Array;

	DividedMeasurements = New Map;
	CurMeasurementsCount = 0;

	Selection = Result.Select();
	While Selection.Next() Do
		KeyOperation = DividedMeasurements.Get(Selection.KeyOperation);

		If KeyOperation = Undefined Then
			KeyOperation = New Map;
			KeyOperation.Insert("uid", String(Selection.KeyOperation.UUID()));
			KeyOperation.Insert("name", Selection.KeyOperationRow);
			KeyOperation.Insert("nameFull", Selection.KeyOperationName1);
			KeyOperation.Insert("comments", New Map);
			KeyOperation.Insert("priority", Selection.KeyOperationPriority);
			KeyOperation.Insert("targetValue", Selection.KeyOperationResponseTimeThreshold);
			KeyOperation.Insert("minimalApdexValue",
				PerformanceLevelsNumber[Selection.KeyOperation.MinValidLevel]);
			KeyOperation.Insert("long", Selection.TimeConsuming);

			DividedMeasurements.Insert(Selection.KeyOperation, KeyOperation);
		EndIf;

		Comment = DividedMeasurements[Selection.KeyOperation]["comments"][Selection.Comment];
		If Comment = Undefined Then
			Comment = New Map;
			Comment.Insert("Measurements", New Array);
			KeyOperation["comments"].Insert(Selection.Comment, Comment);
		EndIf;

		KeyOperationMeasurements = Comment.Get("Measurements"); // Array

		MeasurementStructure = New Structure;
		MeasurementStructure.Insert("value", Selection.RunTime);
		MeasurementStructure.Insert("weight", Selection.MeasurementWeight);
		MeasurementStructure.Insert("tUTC", Selection.MeasurementStartDate);
		MeasurementStructure.Insert("userName", Selection.User);
		MeasurementStructure.Insert("tSaveUTC", Selection.RecordDate);
		MeasurementStructure.Insert("sessionNumber", Selection.SessionNumber);
		MeasurementStructure.Insert("comment", Selection.Comment);
		MeasurementStructure.Insert("runningError", Selection.CompletedWithError);

		KeyOperationMeasurements.Add(MeasurementStructure);

		CurMeasurementsCount = CurMeasurementsCount + 1;

		If CurMeasurementsCount = MeasurementsCountInFile Then
			MeasurementsByFiles.Add(DividedMeasurements);
			DividedMeasurements = New Map;
			KeyOperation = Undefined;
			CurMeasurementsCount = 0;
		EndIf;
	EndDo;
	MeasurementsByFiles.Add(DividedMeasurements);

	Return MeasurementsByFiles;
EndFunction

// Saves the results of the APDEX calculation to a file
//
// Parameters:
//  DirectoriesForExport - 
//  
//  MeasurementsArrays - a structure with an Array value.
//
Procedure ExportResults(DirectoriesForExport, MeasurementsArrays, CurDate, FileSequenceNumber)

	Namespace = "www.v8.1c.ru/ssl/performace-assessment/apdexExport/1.0.0.4";
	TempFileName = GetTempFileName(".xml");

	XMLWriter = New XMLWriter;
	XMLWriter.OpenFile(TempFileName, "UTF-8");
	XMLWriter.WriteXMLDeclaration();
	XMLWriter.WriteStartElement("Performance", Namespace);
	XMLWriter.WriteNamespaceMapping("prf", Namespace);
	XMLWriter.WriteNamespaceMapping("xs", "http://www.w3.org/2001/XMLSchema");
	XMLWriter.WriteNamespaceMapping("xsi", "http://www.w3.org/2001/XMLSchema-instance");

	XMLWriter.WriteAttribute("version", Namespace, "1.0.0.4");
	XMLWriter.WriteAttribute("period", Namespace, String(Date(1, 1, 1) + CurDate / 1000));

	TypeKeyOperation = XDTOFactory.Type(Namespace, "KeyOperation");
	TypeMeasurement = XDTOFactory.Type(Namespace, "Measurement");

	For Each CurMeasurement In MeasurementsArrays Do
		KeyOperationMeasurements = CurMeasurement.Value;

		For Each Comment In KeyOperationMeasurements["comments"] Do
			KeyOperation = XDTOFactory.Create(TypeKeyOperation); // See XDTOPackage.ApdexExport.KeyOperation
			KeyOperation.name = KeyOperationMeasurements["name"];
			KeyOperation.nameFull = KeyOperationMeasurements["nameFull"];
			KeyOperation.long = KeyOperationMeasurements["long"];
			KeyOperation.comment = Comment.Key;
			KeyOperation.priority = KeyOperationMeasurements["priority"];
			KeyOperation.targetValue = KeyOperationMeasurements["targetValue"];
			KeyOperation.uid = KeyOperationMeasurements["uid"];

			Measurements = Comment.Value["Measurements"];
			For Each Measurement In Measurements Do
				XMLMeasurement = XDTOFactory.Create(TypeMeasurement);
				XMLMeasurement.value = Measurement.value;
				XMLMeasurement.weight = Measurement.weight;
				XMLMeasurement.tUTC = Measurement.tUTC;
				XMLMeasurement.userName = Measurement.userName;
				XMLMeasurement.tSaveUTC = Measurement.tSaveUTC;
				XMLMeasurement.sessionNumber = Measurement.sessionNumber;
				XMLMeasurement.runningError = Measurement.runningError;

				KeyOperation.measurement.Add(XMLMeasurement);
			EndDo;

			XDTOFactory.WriteXML(XMLWriter, KeyOperation);
		EndDo;
	EndDo;
	XMLWriter.WriteEndElement();
	XMLWriter.Close();

	For Each ExecuteDirectoryKey In DirectoriesForExport Do
		ExecuteDirectory = ExecuteDirectoryKey.Value;
		ExecuteJob = ExecuteDirectory[0];
		If Not ExecuteJob Then
			Continue;
		EndIf;

		ExportDirectory = ExecuteDirectory[1];
		Var_Key = ExecuteDirectoryKey.Key;
		If Var_Key = PerformanceMonitorClientServer.LocalExportDirectoryJobKey() Then
			CreateDirectory(ExportDirectory);
		EndIf;

		FileCopy(TempFileName, ExportFileFullName(ExportDirectory, CurDate, FileSequenceNumber,
			".xml"));
	EndDo;
	DeleteFiles(TempFileName);
EndProcedure

Function TimeMeasurementsWithoutProfileFiltering()
	Return "
			|SELECT
			|	Measurements.KeyOperation AS KeyOperation,
			|	Measurements.MeasurementStartDate AS MeasurementStartDate,
			|	Measurements.RunTime AS RunTime,
			|	Measurements.MeasurementWeight AS MeasurementWeight,
			|	Measurements.User AS User,
			|	Measurements.RecordDate AS RecordDate,
			|	Measurements.SessionNumber AS SessionNumber,
			|	Measurements.Comment AS Comment, 
			|	KeyOperations.Description AS KeyOperationRow,
			|	KeyOperations.Name AS KeyOperationName1,
			|	KeyOperations.Priority AS KeyOperationPriority,
			|	KeyOperations.ResponseTimeThreshold AS KeyOperationResponseTimeThreshold,
			|	KeyOperations.MinValidLevel AS MinValidLevel,
			|	Measurements.CompletedWithError AS CompletedWithError,
			|	KeyOperations.TimeConsuming AS TimeConsuming
			|FROM
			|	InformationRegister.TimeMeasurements AS Measurements
			|INNER JOIN
			|	Catalog.KeyOperations AS KeyOperations
			|ON
			|	KeyOperations.Ref = Measurements.KeyOperation
			|WHERE
			|	Measurements.RecordDate > &LastExportDate
			|	AND Measurements.RecordDate <= &MeasurementsDateUpperBoundary
			|ORDER BY
			|	Measurements.KeyOperation,
			|	Measurements.Comment
			|";
EndFunction

Function TimeMeasurementsWithProfileFiltering()
	Return "
			|SELECT
			|	Measurements.KeyOperation AS KeyOperation,
			|	Measurements.MeasurementStartDate AS MeasurementStartDate,
			|	Measurements.RunTime AS RunTime,
			|	Measurements.MeasurementWeight AS MeasurementWeight,
			|	Measurements.User AS User,
			|	Measurements.RecordDate AS RecordDate,
			|	Measurements.SessionNumber AS SessionNumber,
			|	Measurements.Comment AS Comment, 
			|	KeyOperations.KeyOperation.Description AS KeyOperationRow,
			|	KeyOperations.KeyOperation.Name AS KeyOperationName1,
			|	KeyOperations.Priority AS KeyOperationPriority,
			|	KeyOperations.ResponseTimeThreshold AS KeyOperationResponseTimeThreshold,
			|	KeyOperations.KeyOperation.MinValidLevel AS MinValidLevel,
			|	Measurements.CompletedWithError AS CompletedWithError,
			|	KeyOperations.KeyOperation.TimeConsuming AS TimeConsuming
			|FROM
			|	InformationRegister.TimeMeasurements AS Measurements
			|INNER JOIN
			|	Catalog.KeyOperationProfiles.ProfileKeyOperations AS KeyOperations
			|ON
			|	KeyOperations.KeyOperation = Measurements.KeyOperation
			|	AND KeyOperations.Ref = &Profile
			|WHERE
			|	Measurements.RecordDate > &LastExportDate
			|	AND Measurements.RecordDate <= &MeasurementsDateUpperBoundary
			|ORDER BY
			|	Measurements.KeyOperation,
			|	Measurements.Comment
			|";
EndFunction

// Generates a file name for export
//
// Parameters:
//  Directory - String, 
//  Dataterminalready of - date - the date and time reset
//  ExtentionWithDot - String -  specifies the file extension, in the form". xxx". 
// Returns:
//  String - 
//
Function ExportFileFullName(Directory, CurDate, FileSequenceNumber, ExtentionWithDot)

	FileFormationDate = Date(1, 1, 1) + CurDate / 1000;
	FileSequenceNumberFormat = Format(FileSequenceNumber, "ND=5; NLZ=; NG=0");

	Separator = ?(Upper(Left(Directory, 3)) = "FTP", "/", GetPathSeparator());
	// 
	Return RemoveSeparatorsAtFileNameEnd(Directory, Separator) + Separator + Format(FileFormationDate,
		"DF='yyyy-MM-dd HH-mm-ex-" + FileSequenceNumberFormat + "'") + ExtentionWithDot;
	// 

EndFunction

// Check the path for a trailing slash, and if there is one, delete it
//
// Parameters:
//  FileName - String
//  Separator - String
//
Function RemoveSeparatorsAtFileNameEnd(Val FileName, Separator)

	PathLength = StrLen(FileName);
	If PathLength = 0 Then
		Return FileName;
	EndIf;

	While PathLength > 0 And StrEndsWith(FileName, Separator) Do
		FileName = Left(FileName, PathLength - 1);
		PathLength = StrLen(FileName);
	EndDo;

	Return FileName;

EndFunction

Procedure LoadPerformanceMonitorFile(FileName, StorageAddress) Export

	FileForStorage = GetTempFileName("zip");
	BinaryDataOfArchive = GetFromTempStorage(StorageAddress); // BinaryData
	BinaryDataOfArchive.Write(FileForStorage);

	FilesDirectory = AddLastPathSeparator(GetTempFileName());

	Try
		ZIPReader = New ZipFileReader(FileForStorage);
		ZIPReader.ExtractAll(FilesDirectory, ZIPRestoreFilePathsMode.DontRestore);
		ZIPReader.Close();
	Except
		DeleteFiles(FileForStorage);
		DeleteFiles(FilesDirectory);
		ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		StringPattern = NStr("en = 'Cannot extract the archive %1 %2';");
		ExceptionDetails = PerformanceMonitorClientServer.SubstituteParametersToString(StringPattern, FileName,
			ErrorDescription);
		Raise ExceptionDetails;
	EndTry;

	Try
		AvailableKeyOperations = AvailableKeyOperations();
		KeyOperationsToWrite = New Array;
		RawMeasurementsToWrite = New Array;

		For Each File In FindFiles(FilesDirectory, "*.XML") Do
			XMLReader = New XMLReader;
			XMLReader.OpenFile(File.FullName);
			XMLReader.MoveToContent();

			// 
			LoadPerformanceMonitorFileApdexExport(XMLReader, AvailableKeyOperations,
				KeyOperationsToWrite, RawMeasurementsToWrite);  
			XMLReader.Close();
		EndDo;
		DeleteFiles(FileForStorage);
		DeleteFiles(FilesDirectory);
	Except
		XMLReader.Close();
		DeleteFiles(FileForStorage);
		DeleteFiles(FilesDirectory);
		Raise;
	EndTry;

	BeginTransaction();
	Try
		For Each RawMeasurementToWrite In RawMeasurementsToWrite Do
			Record = InformationRegisters.TimeMeasurements.CreateRecordManager();
			For Each KeyAndValue In RawMeasurementToWrite Do
				Record[KeyAndValue.Key] = KeyAndValue.Value;
			EndDo;
			Record.RecordDateBegOfHour = BegOfHour(Record.RecordDate);
			Record.EndDate = Record.MeasurementStartDate + Record.RunTime * 1000;
			Record.Write();
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

Procedure LoadPerformanceMonitorFileApdexExport(XMLReader, AvailableKeyOperations,
	KeyOperationsToWrite, RawMeasurementsToWrite)

	Namespace = XMLReader.NamespaceURI;
	
	// 
	ErrorInMeasurementFlag = Metadata.XDTOPackages.ApdexExport_1_0_0_4.Namespace = Namespace;

	Measurements = "measurement";
	TypeKeyOperation = XDTOFactory.Type(Namespace, "KeyOperation");

	XMLReader.Read();

	While XMLReader.NodeType <> XMLNodeType.EndElement Do

		KeyOperation = XDTOFactory.ReadXML(XMLReader, TypeKeyOperation);

		KeyOperationName1 = KeyOperation.nameFull;
		ResponseTimeThreshold = KeyOperation.targetValue;
		Comment = KeyOperation.comment;
		TimeConsuming = KeyOperation.long;

		KeyOperationRef = AvailableKeyOperations[KeyOperationName1];
		If KeyOperationRef = Undefined Then
			KeyOperationRef = CreateKeyOperation(KeyOperationName1, ResponseTimeThreshold, TimeConsuming);  // 
			AvailableKeyOperations.Insert(KeyOperationName1, KeyOperationRef);
		EndIf;

		MaxMeasurementDate = Undefined;
		NumberOfMeasurements1 = KeyOperation[Measurements].Count();
		MeasurementNumber = 0;
		While MeasurementNumber < NumberOfMeasurements1 Do
			Measurement = KeyOperation[Measurements].Get(MeasurementNumber);
			MeasurementDate = Measurement.tUTC;
			If MaxMeasurementDate = Undefined Or MaxMeasurementDate < MeasurementDate Then
				MaxMeasurementDate = MeasurementDate;
			EndIf;
			If ErrorInMeasurementFlag Then
				CompletedWithError = Measurement.runningError;
			Else
				CompletedWithError = KeyOperation.runningError;
			EndIf;

			RawMeasurementToWrite = New Map;
			RawMeasurementToWrite.Insert("KeyOperation", KeyOperationRef);
			RawMeasurementToWrite.Insert("MeasurementStartDate", Measurement.tUTC);
			RawMeasurementToWrite.Insert("RunTime", Measurement.value);
			RawMeasurementToWrite.Insert("MeasurementWeight", Measurement.weight);
			RawMeasurementToWrite.Insert("User", Measurement.userName);
			RawMeasurementToWrite.Insert("RecordDate", Measurement.tSaveUTC);
			RawMeasurementToWrite.Insert("SessionNumber", Measurement.sessionNumber);
			RawMeasurementToWrite.Insert("Comment", Comment);
			RawMeasurementToWrite.Insert("CompletedWithError", CompletedWithError);

			RawMeasurementsToWrite.Add(RawMeasurementToWrite);

			MeasurementNumber = MeasurementNumber + 1;
		EndDo;
	EndDo;

EndProcedure

Function AvailableKeyOperations()
	AvailableKeyOperations = New Map;
	Query = New Query("SELECT
						  |	KeyOperations.Ref AS Ref,
						  |	KeyOperations.Name AS Name
						  |FROM
						  |	Catalog.KeyOperations AS KeyOperations");
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AvailableKeyOperations.Insert(Selection.Name, Selection.Ref);
	EndDo;
	Return AvailableKeyOperations;
EndFunction

// Adds a trailing delimiter character to the passed directory path, if it is missing.
//
// Parameters:
//  DirectoryPath - String -  directory path.
//  Platform - PlatformType -  this parameter is deprecated and is no longer used.
//
// Returns:
//  String - 
//
// Example:
//  Result = Dobasefinalization("Svi directory"); // returns "Svi directory\".
//  Result = Dobasefinalization("Svi directory\"); // returns "Svi directory\".
//  Result = add an end path Separator ("%APPDATA%"); / / returns " %APPDATA%\".
//
Function AddLastPathSeparator(Val DirectoryPath, Val Platform = Undefined)
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;

	CharToAdd = GetPathSeparator();

	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else
		Return DirectoryPath + CharToAdd;
	EndIf;
EndFunction

#EndRegion