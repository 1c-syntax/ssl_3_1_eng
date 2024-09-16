///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

////////////////////////////////////////////////////////////////////////////////
// 
//
//  
//  
//  
//  
//  
//  

////////////////////////////////////////////////////////////////////////////////
// 

Var EventLogMessageKey Export; // 

Var ExternalConnection Export; // 

Var Queries Export; // 

////////////////////////////////////////////////////////////////////////////////
// 

Var Conversion; // 

Var Algorithms; // 

Var AdditionalDataProcessors; // 

Var Rules; // 

Var Managers; // 

Var ManagersForExchangePlans;

Var AdditionalDataProcessorParameters; // 

Var ParametersInitialized; // 

Var DataProtocolFile; // 

Var CommentObjectProcessingFlag;

////////////////////////////////////////////////////////////////////////////////
// 

Var ExportProcessing;
Var LoadProcessing;

////////////////////////////////////////////////////////////////////////////////
// 

Var HasBeforeExportObjectGlobalHandler;
Var HasAfterExportObjectGlobalHandler;

Var HasBeforeConvertObjectGlobalHandler;

Var HasBeforeImportObjectGlobalHandler;
Var HasAfterObjectImportGlobalHandler;

////////////////////////////////////////////////////////////////////////////////
// 

Var StringType;                  // 

Var BooleanType;                  // 

Var NumberType;                   // 

Var DateType;                    // 

Var UUIDType; // 

Var ValueStorageType;       // 

Var BinaryDataType;          // 

Var AccumulationRecordTypeType;   // 

Var ObjectDeletionType;         // 

Var AccountTypeKind;                // 

Var TypeType;                     // 

Var MapType;            // 

Var TypeDescriptionOfTypes;           // 

Var StringType36;
Var StringType255;

Var MapRegisterType;

Var XMLNodeTypeEndElement;
Var XMLNodeTypeStartElement;
Var XMLNodeTypeText;

Var BlankDateValue;

Var ErrorsMessages; // 

////////////////////////////////////////////////////////////////////////////////
// 
 
Var SnCounter;                            // Number

Var WrittenToFileSn;

// 
Var PropertyConversionRuleTable;       // ValueTable

Var XMLRules;                            // 

Var TypesForDestinationString;

Var DocumentsForDeferredPostingField; // 


// 
Var DocumentsForDeferredPostingMap; // Map

Var ObjectsForDeferredPostingField; // 

Var ExchangeFile; // 

Var ObjectsToExportCount;

////////////////////////////////////////////////////////////////////////////////
// 
 
Var DeferredDocumentRegisterRecordCount;
Var LastSearchByRefNumber;
Var StoredExportedObjectCountByTypes;
Var AdditionalSearchParameterMap;
Var TypeAndObjectNameMap;
Var EmptyTypeValueMap;
Var TypeDescriptionMap;
Var ConversionRulesMap; // 

Var MessageNumberField;
Var ReceivedMessageNumberField;
Var AllowDocumentPosting;
Var DataExportCallStack;
Var GlobalNotWrittenObjectStack;
Var DataMapForExportedItemUpdate;
Var EventsAfterParametersImport;
Var ObjectMapsRegisterManager;
Var CurrentNestingLevelExportByRule;
Var VisualExchangeSetupMode;
Var ExchangeRuleInfoImportMode;
Var SearchFieldInfoImportResultTable;
Var CustomSearchFieldsInformationOnDataExport;
Var CustomSearchFieldsInformationOnDataImport;
Var InfobaseObjectsMapQuery;
Var HasObjectRegistrationDataAdjustment;
Var HasObjectChangeRecordData;
Var ExchangeNodeDataImportObject;

Var DataImportDataProcessorField;
Var ObjectsToImportCount;
Var ExchangeMessageFileSize;

////////////////////////////////////////////////////////////////////////////////
// 

Var ErrorFlagField;
Var ExchangeResultField;
Var DataExchangeStateField;

//  
// 
Var DataTableExchangeMessagesField; // Map

Var PackageHeaderDataTableField; // 

Var ErrorMessageStringField; // String - 

Var DataForImportTypeMapField;

Var ImportedObjectsCounterField; // 

Var ExportedObjectsCounterField; // 

Var ExchangeResultsPrioritiesField; // Array - 

// 
// 
Var ObjectsPropertiesDetailsTableField; // Map

Var ExportedByRefObjectsField; // 

Var CreatedOnExportObjectsField; // 

// 
// 
Var ExportedByRefMetadataObjectsField; // Map

// 
// 
Var ObjectsRegistrationRulesField; // ValueTable

Var ExchangePlanNameField;

Var ExchangePlanNodePropertyField;

Var IncomingExchangeMessageFormatVersionField;

Var PutMessageToArchiveWithExternalConnection;
Var TempDirForArchiveAssembly;
Var PackageNumber;

#EndRegion

#Region Public

#Region ExportProperties1

// Function-property: number of the received data exchange message.
//
// Returns:
//  Number - 
//
Function ReceivedMessageNumber() Export
	
	If TypeOf(ReceivedMessageNumberField) <> Type("Number") Then
		
		ReceivedMessageNumberField = 0;
		
	EndIf;
	
	Return ReceivedMessageNumberField;
	
EndFunction

#EndRegion

#Region DataOperations

// Returns the string name of the passed enumeration value.
// This function can be used in event handlers whose program code 
// is stored in data exchange rules. Called by the Run () method.
// The "no function references found" message when checking the configuration 
// is not a configuration check error.
//
// Parameters:
//  Value - EnumRef -  enumeration value.
//
// Returns:
//   String - 
//
Function deEnumValueName(Value) Export

	MetadataObjectsList = Value.Metadata();
	
	EnumManager = Enums[MetadataObjectsList.Name]; // EnumManager
	ValueIndex = EnumManager.IndexOf(Value);

	Return MetadataObjectsList.EnumValues.Get(ValueIndex).Name;

EndFunction

#EndRegion

#Region ExchangeRulesOperationProcedures

// Sets parameter values in the structure Options 
// the table Tablecontentparser.
//
Procedure SetParametersFromDialog() Export

	For Each TableRow In ParametersSetupTable Do
		Parameters.Insert(TableRow.Name, TableRow.Value);
	EndDo;

EndProcedure

#EndRegion

#Region DataSending

// Unloads the object in accordance with the specified conversion rule.
//
// Parameters:
//  Source				 - Arbitrary - custom data source.
//  Receiver				 - XMLWriter -  xml node of the receiver object.
//  IncomingData			 - Arbitrary -  auxiliary data passed to the rule
//                             for performing the conversion.
//  OutgoingData			 - Arbitrary -  custom auxiliary data passed
//                             to the property conversion rules.
//  OCRName					 - String -  name of the conversion rule that is used for uploading.
//  RefNode				 - XMLWriter -  xml node of the receiver object reference.
//  GetRefNodeOnly - Boolean -  if True, the object is not uploaded, only generated
//                             xml link node.
//  OCR                      - ValueTableRow -  a row in the conversion rules table.
//  ExportSubordinateObjectRefs - Boolean -  if True, then links are unloaded from subordinate objects.
//  ExportRegisterRecordSetRow - Boolean -  if True, the recordset row is unloaded.
//  ParentNode				 - XMLWriter -  xml node of the ancestor of the receiver object.
//  ConstantNameForExport  - String -  the value to write to attribute Imagestate.
//  IsObjectExport     - Boolean -  indicates that the object is being unloaded.
//  IsRuleWithGlobalObjectExport - Boolean -  indicates whether objects are being uploaded globally.
//  DontUseRuleWithGlobalExportAndDontRememberExported - Boolean -  not use.
//  ObjectExportStack      - Array of AnyRef -  contains information about higher-level upload objects.
//
// Returns:
//   XMLWriter - 
//
Function ExportByRule(
		Source = Undefined,
		Receiver = Undefined,
		IncomingData = Undefined,
		OutgoingData = Undefined,
		OCRName = "",
		RefNode = Undefined,
		GetRefNodeOnly = False,
		OCR = Undefined,
		ExportSubordinateObjectRefs = True,
		ExportRegisterRecordSetRow = False,
		ParentNode = Undefined,
		ConstantNameForExport = "",
		IsObjectExport = Undefined,
		IsRuleWithGlobalObjectExport = False,
		DontUseRuleWithGlobalExportAndDontRememberExported = False,
		ObjectExportStack = Undefined) Export
	
	DetermineOCRByParameters(OCR, Source, OCRName);
	
	If OCR = Undefined Then
		
		WP = ExchangeProtocolRecord(45);
		
		WP.Object = Source;
		WP.ObjectType = TypeOf(Source);
		
		WriteToExecutionProtocol(45, WP, True); // 
		Return Undefined;
		
	EndIf;
	
	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule + 1;
	
	If CommentObjectProcessingFlag Then
		
		Try
			SourceToString = String(Source);
		Except
			SourceToString = " ";
		EndTry;
		
		ActionName = ?(GetRefNodeOnly, NStr("en = 'Converting object reference';"), NStr("en = 'Converting object';"));
		
		MessageText = NStr("en = '[ActionName]: [Object]([ObjectType]), ПКО: [OCR](OCRDescription)';");
		MessageText = StrReplace(MessageText, "[ActionName]", ActionName);
		MessageText = StrReplace(MessageText, "[Object]", SourceToString);
		MessageText = StrReplace(MessageText, "[ObjectType]", TypeOf(Source));
		MessageText = StrReplace(MessageText, "[OCR]", TrimAll(OCRName));
		MessageText = StrReplace(MessageText, "[OCRDescription]", TrimAll(OCR.Description));
		
		WriteToExecutionProtocol(MessageText, , False, CurrentNestingLevelExportByRule + 1, 7);
		
	EndIf;
	
	IsRuleWithGlobalObjectExport = False;
	
	If ObjectExportStack = Undefined Then
		ObjectExportStack = New Array;
	EndIf;
	
	PropertiesToTransfer = New Structure("Ref");
	If Source <> Undefined And TypeOf(Source) <> Type("String") Then
		FillPropertyValues(PropertiesToTransfer, Source);
	EndIf;
	SourceRef = PropertiesToTransfer.Ref;
	
	ObjectExportedByRefFromItself = False;
	If ValueIsFilled(SourceRef) Then
		SequenceNumberInStack = ObjectExportStack.Find(SourceRef);
		ObjectExportedByRefFromItself = SequenceNumberInStack <> Undefined;
	EndIf;
	
	ObjectExportStack.Add(SourceRef);
	
	// 
	// 
	RememberExportedData = ObjectExportedByRefFromItself And (OCR.RememberExportedData);
	
	ExportedObjects          = OCR.Exported_;
	AllObjectsExported         = OCR.AllObjectsExported;
	DontReplaceObjectOnImport = OCR.NotReplace;
	DontCreateIfNotFound     = OCR.DontCreateIfNotFound;
	OnExchangeObjectByRefSetGIUDOnly     = OCR.OnExchangeObjectByRefSetGIUDOnly;
	DontReplaceObjectCreatedInDestinationInfobase = OCR.DontReplaceObjectCreatedInDestinationInfobase;
	ExchangeObjectsPriority = OCR.ExchangeObjectsPriority;
	
	RecordObjectChangeAtSenderNode = False;
	
	AutonumberingPrefix		= "";
	WriteMode     			= "";
	PostingMode 			= "";
	TempFileList = Undefined;

   	TypeName          = "";
	ExportObjectProperties = True;
	
	PropertyStructure = FindPropertyStructureByParameters(OCR, Source);
			
	If PropertyStructure <> Undefined Then
		TypeName = PropertyStructure.TypeName;
	EndIf;

	DataToExportKey = OCRName;
	
	If ValueIsFilled(TypeName) Then
		
		IsNotReferenceType = TypeName = "Constants"
			Or TypeName = "InformationRegister"
			Or TypeName = "AccumulationRegister"
			Or TypeName = "AccountingRegister"
			Or TypeName = "CalculationRegister";
		
	Else
		
		If TypeOf(Source) = Type("Structure") Then
			IsNotReferenceType = Not Source.Property("Ref");
		Else
			IsNotReferenceType = True;
		EndIf;
		
	EndIf;
	
	If IsNotReferenceType 
		Or IsBlankString(TypeName) Then
		
		RememberExportedData = False;
		
	ElsIf OCR.Owner().Columns.Find("AnObjectWithRegisteredRecords") <> Undefined
		And OCR.AnObjectWithRegisteredRecords = True Then
		
		// 
		WriteMode = "Record";
		
	EndIf;
	
	RefToSource = Undefined;
	ExportingObject = IsObjectExport;
	
	If (Source <> Undefined) 
		And Not IsNotReferenceType Then
		
		If ExportingObject = Undefined Then
			// 
			ExportingObject = True;	
		EndIf;
		
		RefToSource = GetRefByObjectOrRef(Source, ExportingObject);
		If RememberExportedData Then
			DataToExportKey = DetermineInternalPresentationForSearch(RefToSource, PropertyStructure);
		EndIf;
		
	Else
		
		ExportingObject = False;
			
	EndIf;
	
	// 
	PredefinedItemName1 = Undefined;
	
	// 
	Cancel = False;
	If HasBeforeConvertObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				HandlerParameters = New Array();
				HandlerParameters.Add(ExchangeFile);
				HandlerParameters.Add(Source);
				HandlerParameters.Add(IncomingData);
				HandlerParameters.Add(OutgoingData);
				HandlerParameters.Add(OCRName);
				HandlerParameters.Add(OCR);
				HandlerParameters.Add(ExportedObjects);
				HandlerParameters.Add(Cancel);
				HandlerParameters.Add(DataToExportKey);
				HandlerParameters.Add(RememberExportedData);
				HandlerParameters.Add(DontReplaceObjectOnImport);
				HandlerParameters.Add(AllObjectsExported);
				HandlerParameters.Add(GetRefNodeOnly);
				HandlerParameters.Add(Receiver);
				HandlerParameters.Add(WriteMode);
				HandlerParameters.Add(PostingMode);
				HandlerParameters.Add(DontCreateIfNotFound);
				
				ExecuteHandlerConversionBeforeObjectConversion(HandlerParameters);
				
				ExchangeFile = HandlerParameters[0];
				Source = HandlerParameters[1];
				IncomingData = HandlerParameters[2];
				OutgoingData = HandlerParameters[3];
				OCRName = HandlerParameters[4];
				OCR = HandlerParameters[5];
				ExportedObjects = HandlerParameters[6];
				Cancel = HandlerParameters[7];
				DataToExportKey = HandlerParameters[8];
				RememberExportedData = HandlerParameters[9];
				DontReplaceObjectOnImport = HandlerParameters[10];
				AllObjectsExported = HandlerParameters[11];
				GetRefNodeOnly = HandlerParameters[12];
				Receiver = HandlerParameters[13];
				WriteMode = HandlerParameters[14];
				PostingMode = HandlerParameters[15];
				DontCreateIfNotFound = HandlerParameters[16];
				
			Else
				
				Execute(Conversion.BeforeConvertObject);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(64, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				OCR, Source, NStr("en = 'BeforeConvertObject (global)';"));
		EndTry;
		
		If Cancel Then	//	
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Receiver;
		EndIf;
		
	EndIf;
	
	// 
	If OCR.HasBeforeExportHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteOCRHandlerBeforeObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
															  ExportedObjects, Cancel, DataToExportKey, RememberExportedData,
															  DontReplaceObjectOnImport, AllObjectsExported, GetRefNodeOnly,
															  Receiver, WriteMode, PostingMode, DontCreateIfNotFound);
				
			Else
				
				Execute(OCR.BeforeExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(41, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				OCR, Source, "BeforeExportObject");
		EndTry;
		
		If Cancel Then	//	
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Receiver;
		EndIf;
		
	EndIf;
	
	ExportStackRow = Undefined;
	
	MustUpdateLocalExportedObjectCache = False;
	RefValueInAnotherIB = "";

	// 
	If Not AllObjectsExported Then
		
		NBSp = 0;
		
		If RememberExportedData Then
			
			ExportedObjectRow = ExportedObjects.Find(DataToExportKey, "Key");
			
			If ExportedObjectRow <> Undefined Then
				
				ExportedObjectRow.CallCount = ExportedObjectRow.CallCount + 1;
				ExportedObjectRow.LastCallNumber = SnCounter;
				
				If GetRefNodeOnly Then
					
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					If StrFind(ExportedObjectRow.RefNode, "<Ref") > 0
						And WrittenToFileSn >= ExportedObjectRow.RefSN Then
						Return ExportedObjectRow.RefSN;
					Else
						Return ExportedObjectRow.RefNode;
					EndIf;
					
				EndIf;
				
				ExportedRefNumber = ExportedObjectRow.RefSN;
				
				If Not ExportedObjectRow.OnlyRefExported Then
					
					CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
					Return ExportedObjectRow.RefNode;
					
				Else
					
					ExportStackRow = DataExportCallStackCollection().Find(DataToExportKey, "Ref");
				
					If ExportStackRow <> Undefined Then
						CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
						Return Undefined;
					EndIf;
					
					ExportStackRow = DataExportCallStackCollection().Add();
					ExportStackRow.Ref = DataToExportKey;
					
					NBSp = ExportedRefNumber;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If NBSp = 0 Then
			
			SnCounter = SnCounter + 1;
			NBSp        = SnCounter;
			
			
			// 
			If RememberExportedData Then
				
				If ExportedObjectRow = Undefined Then
					
					If Not IsRuleWithGlobalObjectExport
						And Not MustUpdateLocalExportedObjectCache
						And ExportedObjects.Count() > StoredExportedObjectCountByTypes Then
						
						MustUpdateLocalExportedObjectCache = True;
						DataMapForExportedItemUpdate.Insert(OCR.Receiver, OCR);
						
					EndIf;
					
					ExportedObjectRow = ExportedObjects.Add();
					
				EndIf;
				
				ExportedObjectRow.Key = DataToExportKey;
				ExportedObjectRow.RefNode = NBSp;
				ExportedObjectRow.RefSN = NBSp;
				ExportedObjectRow.LastCallNumber = NBSp;
				
				If GetRefNodeOnly Then
					
					ExportedObjectRow.OnlyRefExported = True;
					
				Else
					
					ExportStackRow = DataExportCallStackCollection().Add();
					ExportStackRow.Ref = DataToExportKey;
					
				EndIf;
				
			EndIf;
				
		EndIf;
		
	EndIf;
	
	ValueMap = OCR.PredefinedDataValues;
	ValueMapItemCount = ValueMap.Count();
	
	// 
	If PredefinedItemName1 = Undefined Then
		
		If PropertyStructure <> Undefined
			And ValueMapItemCount > 0
			And PropertyStructure.SearchByPredefinedItemsPossible Then
			
			Try
				PredefinedNameSource = Common.ObjectAttributeValue(RefToSource, "PredefinedDataName");
			Except
				PredefinedNameSource = "";
			EndTry;
			
		Else
			
			PredefinedNameSource = "";
			
		EndIf;
		
		If Not IsBlankString(PredefinedNameSource)
			And ValueMapItemCount > 0 Then
			
			PredefinedItemName1 = ValueMap[RefToSource];
			
		Else
			PredefinedItemName1 = Undefined;
		EndIf;
		
	EndIf;
	
	If PredefinedItemName1 <> Undefined Then
		ValueMapItemCount = 0;
	EndIf;
	
	DontExportByValueMap = (ValueMapItemCount = 0);
	
	If Not DontExportByValueMap Then
		
		// 
		RefNode = ValueMap[RefToSource];
		If RefNode = Undefined Then
			
			// 
			// 
			If PropertyStructure.TypeName = "Enum"
				And StrFind(OCR.Receiver, "EnumRef.") > 0 Then
				
				// 
				If Common.IsReference(TypeOf(RefToSource))
					And Common.RefExists(RefToSource) Then
					// 
					WP = ExchangeProtocolRecord();
					WP.OCRName              = OCRName;
					WP.Value            = Source;
					WP.ValueType         = PropertyStructure.RefTypeString1;
					WP.ErrorMessageCode = 71;
					WP.Text               = NStr("en = 'Map the Source value to the Destination value in the value conversion rule.
														|If there is no appropriate destination value, specify an empty value.';");
					//
					WriteToExecutionProtocol(71, WP);
				EndIf;
				
				If ExportStackRow <> Undefined Then
					DataExportCallStack.Delete(ExportStackRow);				
				EndIf;
				
				CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
				
				Return Undefined;
				
			Else
				
				DontExportByValueMap = True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DontExportSubordinateObjects = GetRefNodeOnly Or Not ExportSubordinateObjectRefs;
	
	MustRememberObject = RememberExportedData And (Not AllObjectsExported);
	
	If DontExportByValueMap Then
		
		If OCR.SearchProperties.Count() > 0 
			Or PredefinedItemName1 <> Undefined Then
			
			//	
			RefNode = CreateNode("Ref");
						
			If MustRememberObject Then
				
				If IsRuleWithGlobalObjectExport Then
					SetAttribute(RefNode, "Gsn", NBSp);
				Else
					SetAttribute(RefNode, "NBSp", NBSp);
				EndIf;
				
			EndIf;
			
			If DontCreateIfNotFound Then
				SetAttribute(RefNode, "DontCreateIfNotFound", DontCreateIfNotFound);
			EndIf;
			
			If OCR.SearchBySearchFieldsIfNotFoundByID Then
				SetAttribute(RefNode, "ContinueSearch", True);
			EndIf;
			
			If RecordObjectChangeAtSenderNode Then
				SetAttribute(RefNode, "RecordObjectChangeAtSenderNode", RecordObjectChangeAtSenderNode);
			EndIf;
			
			WriteExchangeObjectPriority(ExchangeObjectsPriority, RefNode);
			
			If DontReplaceObjectCreatedInDestinationInfobase Then
				SetAttribute(RefNode, "DontReplaceObjectCreatedInDestinationInfobase", DontReplaceObjectCreatedInDestinationInfobase);				
			EndIf;
			
			If ExportObjectProperties = True Then
			
				ExportProperties(Source, Receiver, IncomingData, OutgoingData, OCR, OCR.SearchProperties, 
					RefNode, , PredefinedItemName1, True, 
					True, ExportingObject, DataToExportKey, , RefValueInAnotherIB,,, ObjectExportStack);
					
			EndIf;
			
			RefNode.WriteEndElement();
			RefNode = RefNode.Close();
			
			If MustRememberObject Then
				
				ExportedObjectRow.RefNode = RefNode;
				
			EndIf;
			
		Else
			RefNode = NBSp;
		EndIf;
		
	Else
		
		// 
		If RefNode = Undefined Then
			
			// 
			WP = ExchangeProtocolRecord();
			WP.OCRName              = OCRName;
			WP.Value            = Source;
			WP.ValueType         = TypeOf(Source);
			WP.ErrorMessageCode = 71;
			
			WriteToExecutionProtocol(71, WP);
			
			If ExportStackRow <> Undefined Then
				DataExportCallStack.Delete(ExportStackRow);				
			EndIf;
			
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return Undefined;
		EndIf;
		
		If RememberExportedData Then
			ExportedObjectRow.RefNode = RefNode;			
		EndIf;
		
		If ExportStackRow <> Undefined Then
			DataExportCallStack.Delete(ExportStackRow);				
		EndIf;
		
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf;

		
	If GetRefNodeOnly
		Or AllObjectsExported Then
		
		If ExportStackRow <> Undefined Then
			DataExportCallStack.Delete(ExportStackRow);				
		EndIf;
		
		CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
		Return RefNode;
		
	EndIf; 

	If Receiver = Undefined Then
		
		Receiver = CreateNode("Object");
		
		If Not ExportRegisterRecordSetRow Then
			
			If IsRuleWithGlobalObjectExport Then
				SetAttribute(Receiver, "Gsn", NBSp);
			Else
				SetAttribute(Receiver, "NBSp", NBSp);
			EndIf;
			
			SetAttribute(Receiver, "Type", 			OCR.Receiver);
			SetAttribute(Receiver, "RuleName",	OCR.Name);
			
			If Not IsBlankString(ConstantNameForExport) Then
				
				SetAttribute(Receiver, "ConstantName", ConstantNameForExport);
				
			EndIf;
			
			WriteExchangeObjectPriority(ExchangeObjectsPriority, Receiver);
			
			If DontReplaceObjectOnImport Then
				SetAttribute(Receiver, "NotReplace",	"true");
			EndIf;
			
			If Not IsBlankString(AutonumberingPrefix) Then
				SetAttribute(Receiver, "AutonumberingPrefix",	AutonumberingPrefix);
			EndIf;
			
			If Not IsBlankString(WriteMode) Then
				
				SetAttribute(Receiver, "WriteMode",	WriteMode);
				If Not IsBlankString(PostingMode) Then
					SetAttribute(Receiver, "PostingMode",	PostingMode);
				EndIf;
				
			EndIf;
			
			If TypeOf(RefNode) <> NumberType Then
				AddSubordinateNode(Receiver, RefNode);
			EndIf;
		
		EndIf;
		
	EndIf;

	// 
	StandardProcessing = True;
	Cancel = False;
	
	If OCR.HasOnExportHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteOCRHandlerOnObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName,
														   OCR, ExportedObjects, DataToExportKey, Cancel,
														   StandardProcessing, Receiver, RefNode);
				
			Else
				
				Execute(OCR.OnExport);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(42, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				OCR, Source, "OnExportObject");
		EndTry;
				
		If Cancel Then	//	
			
			If ExportStackRow <> Undefined Then
				DataExportCallStack.Delete(ExportStackRow);				
			EndIf;
			
			CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
			Return RefNode;
		EndIf;
		
	EndIf;

	// 
	If StandardProcessing Then
		
		If Not IsBlankString(ConstantNameForExport) Then
			
			PropertyForExportArray = New Array();
			
			TableRow = OCR.Properties.Find(ConstantNameForExport, "Source");
			
			If TableRow <> Undefined Then
				PropertyForExportArray.Add(TableRow);
			EndIf;
			
		Else
			
			PropertyForExportArray = OCR.Properties;
			
		EndIf;
		
		If ExportObjectProperties Then
		
			ExportProperties(
				Source,                 // Source
				Receiver,                 // Receiver
				IncomingData,           // IncomingData
				OutgoingData,          // OutgoingData
				OCR,                      // OCR
				PropertyForExportArray, // PCRCollection
				,                         // 
				,                         // 
				,                         // 
				True,                   // 
				False,                     // 
				ExportingObject,        // 
				DataToExportKey,    // 
				,                         // 
				RefValueInAnotherIB,  // RefValueInAnotherIB
				TempFileList,    // 
				ExportRegisterRecordSetRow, // 
				ObjectExportStack);
				
			EndIf;
			
		EndIf;    
		
		// 
		
		If OCR.HasAfterExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecuteOCRHandlerAfterObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
																 ExportedObjects, DataToExportKey, Cancel, Receiver, RefNode);
					
				Else
					
					Execute(OCR.AfterExport);
					
				EndIf;
				
			Except
				WriteInfoOnOCRHandlerExportError(43, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
					OCR, Source, "AfterExportObject");
			EndTry;
			
			If Cancel Then	//	
				
				If ExportStackRow <> Undefined Then
					DataExportCallStack.Delete(ExportStackRow);				
				EndIf;
				
				CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
				Return RefNode;
			EndIf;
		EndIf;
		
		
	//	
	
	CurrentNestingLevelExportByRule = CurrentNestingLevelExportByRule - 1;
	
	If ParentNode <> Undefined Then
		
		Receiver.WriteEndElement();
		
		ParentNode.WriteRaw(Receiver.Close());
		
	Else
	
		If TempFileList = Undefined Then
			
			Receiver.WriteEndElement();
			WriteToFile(Receiver);
			
		Else
			
			WriteToFile(Receiver);
		
			TempFile = New TextReader;
			For Each TempFileName In TempFileList Do
				
				Try
					TempFile.Open(TempFileName, TextEncoding.UTF8);
				Except
					Continue;
				EndTry;
				
				TempFileLine = TempFile.ReadLine();
				While TempFileLine <> Undefined Do
					WriteToFile(TempFileLine);	
				    TempFileLine = TempFile.ReadLine();
				EndDo;
				
				TempFile.Close();
				
				// 
				DeleteFiles(TempFileName); 
			EndDo;
			
			WriteToFile("</Object>");
			
		EndIf;
		
		If MustRememberObject
			And IsRuleWithGlobalObjectExport Then
				
			ExportedObjectRow.RefNode = NBSp;
			
		EndIf;
		
		If CurrentNestingLevelExportByRule = 0 Then
			
			SetExportedToFileObjectFlags();
			
		EndIf;
		
		UpdateDataInDataToExport();		
		
	EndIf;
	
	If ExportStackRow <> Undefined Then
		DataExportCallStack.Delete(ExportStackRow);				
	EndIf;
	
	// 
	If OCR.HasAfterExportToFileHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteOCRHandlerAfterObjectExportToExchangeFile(ExchangeFile, Source, IncomingData, OutgoingData,
																		OCRName, OCR, ExportedObjects, Receiver, RefNode);
				
			Else
				
				Execute(OCR.AfterExportToFile);
				
			EndIf;
			
		Except
			WriteInfoOnOCRHandlerExportError(79, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				OCR, Source, "HasAfterExportToFileHandler");
		EndTry;
		
	EndIf;
	
	Return RefNode;
	
EndFunction

// Unloads the register by calling the pre-Load and post-Load rules.
//
// Parameters:
//         RecordSetForExport - НаборЗаписейРегистра -  there may also be a Structure containing the selection.
//         Rule - ValueTableRow -  tables of object conversion rules.
//         IncomingData - Arbitrary -  incoming data for the conversion rule.
//         DontExportPropertyObjectsByRefs - Boolean -  a sign to unload the properties on the links.
//         OCRName - String -  name of the conversion rule.
//
// Returns:
//         Boolean - 
//
Function ExportRegister(RecordSetForExport,
							Rule = Undefined,
							IncomingData = Undefined,
							DontExportPropertyObjectsByRefs = False,
							OCRName = "") Export
							
	OCRName			= "";
	Cancel			= False;
	OutgoingData	= Undefined;
		
	FireEventsBeforeExportObject(RecordSetForExport, Rule, Undefined, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);
		
	If Cancel Then
		Return False;
	EndIf;	
	
	
	UnloadRegister(RecordSetForExport, 
					 Undefined, 
					 OutgoingData, 
					 DontExportPropertyObjectsByRefs, 
					 OCRName,
					 Rule);
		
	FireEventsAfterExportObject(RecordSetForExport, Rule, Undefined, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);	
		
	Return Not Cancel;							
							
EndFunction

// Generates the result of a request for uploading data cleaning.
//
//  Parameters:
//       Properties                      - Structure -  contains the properties of the object.
//       TypeName                       - String -  name of the object type.
//       SelectionForDataClearing       - Boolean -  indicates whether the selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean -  indicates whether direct deletion is required.
//       SelectAllFields               - Boolean -  indicates whether all fields must be selected.
//
//  Returns:
//       QueryResult, Undefined - 
//
Function QueryResultForExpotingDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export 
	
	PermissionRow = ?(ExportAllowedObjectsOnly, " ALLOWED ", ""); // @Query-part-1
	
	FieldSelectionString = ?(SelectAllFields, " * ", "	ObjectForExport.Ref AS Ref ");
	
	If TypeName = "Catalog" 
		Or TypeName = "ChartOfCharacteristicTypes" 
		Or TypeName = "ChartOfAccounts" 
		Or TypeName = "ChartOfCalculationTypes" 
		Or TypeName = "AccountingRegister"
		Or TypeName = "ExchangePlan"
		Or TypeName = "Task"
		Or TypeName = "BusinessProcess" Then
		
		Query = New Query;
		
		Query.Text =
		"SELECT ALLOWED
		|	ObjectForExport.Ref AS Ref
		|FROM
		|	&MetadataTableName AS ObjectForExport
		|WHERE ObjectForExport.Parent = &Parent";
		
		Query.Text = StrReplace(Query.Text, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("%1.%2", TypeName, Properties.Name));
		
		If Not ExportAllowedObjectsOnly Then
			
			Query.Text = StrReplace(Query.Text, "ALLOWED", ""); // @Query-part-1
			
		EndIf;
		
		If SelectAllFields 
			Or TypeName = "AccountingRegister" Then
			
			Query.Text = StrReplace(Query.Text, "ObjectForExport.Ref AS Ref", "*");
			
		EndIf;
		
		If (SelectionForDataClearing And DeleteObjectsDirectly)
			And ((TypeName = "Catalog" And Metadata.Catalogs[Properties.Name].Hierarchical)
				Or (TypeName = "ChartOfCharacteristicTypes" And Metadata.ChartsOfCharacteristicTypes[Properties.Name].Hierarchical)) Then
			
			Query.SetParameter("Parent", Properties.Manager.EmptyRef());
			
		Else
			
			Query.Text = StrReplace(Query.Text, "WHERE ObjectForExport.Parent = &Parent", "");
			
		EndIf;
		
	ElsIf TypeName = "Document" Then
		
		Query = New Query;
		
		Query.Text =
		"SELECT ALLOWED
		|	ObjectForExport.Ref AS Ref
		|FROM
		|	&MetadataTableName AS ObjectForExport";
		
		Query.Text = StrReplace(Query.Text, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("%1.%2", TypeName, Properties.Name));
		
		If Not ExportAllowedObjectsOnly Then
			
			Query.Text = StrReplace(Query.Text, "ALLOWED", ""); // @Query-part-1
			
		EndIf;
		
	ElsIf TypeName = "InformationRegister" Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		| *
		| ,NULL AS Active
		| ,NULL AS Recorder
		| ,NULL AS LineNumber
		| ,NULL AS Period
		|FROM
		| &MetadataTableName AS ObjectForExport";
		
		Query.Text = StrReplace(Query.Text, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("%1.%2", TypeName, Properties.Name));
		
		If Properties.SubordinateToRecorder Then
			
			Query.Text = StrReplace(Query.Text, ",NULL AS Active", "");
			Query.Text = StrReplace(Query.Text, ",NULL AS Recorder", "");
			Query.Text = StrReplace(Query.Text, ",NULL AS LineNumber", "");
			
		EndIf;
		
		If Properties.Periodic3 Then
			
			Query.Text = StrReplace(Query.Text, ",NULL AS Period", "");
			
		EndIf;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	
	Return Query.Execute();
	
EndFunction

// Generates a selection for uploading and clearing data.
//
//  Parameters:
//       Properties                      - Structure -  contains the properties of the object.
//       TypeName                       - String -  name of the object type.
//       SelectionForDataClearing       - Boolean -  indicates whether the selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean -  indicates whether direct deletion is required.
//       SelectAllFields               - Boolean -  indicates whether all fields must be selected.
//
//  Returns:
//       QueryResultSelection, Undefined - 
//
Function SelectionForExpotingDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export
	
	QueryResult = QueryResultForExpotingDataClearing(Properties, TypeName, 
			SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
			
	If QueryResult = Undefined Then
		Return Undefined;
	EndIf;
			
	Selection = QueryResult.Select();
	
	
	Return Selection;		
	
EndFunction

// Uploads data according to the specified rule.
//
// Parameters:
//  Rule - ValueTableRow - :
//     * Enable - Boolean
//     * Name - Arbitrary
//     * Description - Arbitrary
//     * Order - Arbitrary
//     * DataFilterMethod - Arbitrary
//     * SelectionObject1 - Arbitrary
//     * SelectionObjectMetadata - Arbitrary
//     * ConversionRule - Arbitrary
//     * BeforeProcess - Arbitrary
//     * BeforeProcessHandlerName - Arbitrary
//     * AfterProcess - Arbitrary
//     * AfterProcessHandlerName - Arbitrary
//     * BeforeExport - Arbitrary
//     * BeforeExportHandlerName - Arbitrary
//     * AfterExport - Arbitrary
//     * AfterExportHandlerName - Arbitrary
//     * UseFilter1 - Boolean
//     * BuilderSettings - Arbitrary
//     * ObjectForQueryName - Arbitrary
//     * ObjectNameForRegisterQuery - Arbitrary
//     * DestinationTypeName - Arbitrary
//     * DoNotExportObjectsCreatedInDestinationInfobase - Boolean
//     * ExchangeNodeRef - Arbitrary
//     * SynchronizeByID - Boolean
// 
Procedure ExportDataByRule(Rule) Export
	
	OCRName = Rule.ConversionRule;
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;


	If CommentObjectProcessingFlag Then
		
		MessageString = NStr("en = 'DATA EXPORT RULE: %1 (%2)';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, TrimAll(Rule.Name), TrimAll(Rule.Description));
		WriteToExecutionProtocol(MessageString, , False, , 4);
		
	EndIf;
		
	
	// 
	Cancel           = False;
	OutgoingData = Undefined;
	DataSelection   = Undefined;
	
	If Not IsBlankString(Rule.BeforeProcess) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerDERBeforeProcessRule(Cancel, OCRName, Rule, OutgoingData, DataSelection);
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(31, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "BeforeProcessDataExport");
			
		EndTry;
		
		If Cancel Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// 
	If Rule.DataFilterMethod = "StandardSelection" And Rule.UseFilter1 Then

		Selection = SelectionForExportWithRestrictions(Rule);
		
		While Selection.Next() Do
			ExportSelectionObject(Selection.Ref, Rule, , OutgoingData);
		EndDo;

	// 
	ElsIf (Rule.DataFilterMethod = "StandardSelection") Then
		
		Properties = Managers(Rule.SelectionObject1);
		TypeName  = Properties.TypeName;
		
		If TypeName = "Constants" Then
			
			ExportConstantsSet(Rule, Properties, OutgoingData);
			
		Else
			
			IsNotReferenceType = TypeName =  "InformationRegister" 
				Or TypeName = "AccountingRegister";
			
			
			If IsNotReferenceType Then
					
				SelectAllFields = MustSelectAllFields(Rule);
				
			Else
				
				// 
				SelectAllFields = False;	
				
			EndIf;	
				
			
			Selection = SelectionForExpotingDataClearing(Properties, TypeName, , , SelectAllFields);
			
			If Selection = Undefined Then
				Return;
			EndIf;
			
			While Selection.Next() Do
				
				If IsNotReferenceType Then
					
					ExportSelectionObject(Selection, Rule, Properties, OutgoingData);
					
				Else
					
					ExportSelectionObject(Selection.Ref, Rule, Properties, OutgoingData);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then

		If DataSelection <> Undefined Then
			
			Selection = SelectionToExportByArbitraryAlgorithm(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
					
					ExportSelectionObject(Selection, Rule, , OutgoingData);
					
				EndDo;
				
			Else
				
				For Each Object In DataSelection Do
					
					ExportSelectionObject(Object, Rule, , OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf;
			
	EndIf;

	
	// 
	
	If Not IsBlankString(Rule.AfterProcess) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerDERAfterProcessRule(OCRName, Rule, OutgoingData);
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteErrorInfoDERHandlers(32, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "AfterProcessDataExport");
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Adds information about value types to the xml file.
//
// Parameters:
//   Receiver - XMLWriter -  xml node of the receiver object.
//   Type - String
//       - Array of String - 
//   AttributesList - Structure -  the key contains the attribute name.
//
Procedure ExportInformationAboutTypes(Receiver, Type, AttributesList = Undefined) Export
	
	TypesNode = CreateNode("Types");
	
	If AttributesList <> Undefined Then
		For Each CollectionItem In AttributesList Do
			SetAttribute(TypesNode, CollectionItem.Key, CollectionItem.Value);
		EndDo;
	EndIf;
	
	If TypeOf(Type) = Type("String") Then
		deWriteElement(TypesNode, "Type", Type);
	Else
		For Each TypeAsString In Type Do
			deWriteElement(TypesNode, "Type", TypeAsString);
		EndDo;
	EndIf;
	
	AddSubordinateNode(Receiver, TypesNode);
	
EndProcedure

// Creates an entry in the exchange file about deleting an object.
//
// Parameters:
//  Ref - CatalogRef
//         - DocumentRef - 
//  DestinationType - String -  contains a string representation of the receiver type.
//  SourceType - String -  contains a string representation of the source type.
// 
Procedure WriteToFileObjectDeletion(Ref, Val DestinationType, Val SourceType) Export
	
	Receiver = CreateNode("ObjectDeletion");
	
	SetAttribute(Receiver, "DestinationType", DestinationType);
	SetAttribute(Receiver, "SourceType", SourceType);
	
	SetAttribute(Receiver, "UUID", Ref.UUID());
	
	Receiver.WriteEndElement(); // ObjectDeletion
	
	WriteToFile(Receiver);
	
EndProcedure

// Registers the object created during upload.
//
// Parameters:
//  Ref - CatalogRef
//         - DocumentRef - 
// 
Procedure RegisterObjectCreatedDuringExport(Ref) Export
	
	If CreatedOnExportObjects().Find(Ref) = Undefined Then
		
		CreatedOnExportObjects().Add(Ref);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region GetData

// Returns a table of values that contains links to documents for deferred processing,
// as well as the dates of these documents for pre-sorting.
//
// Returns:
//  ValueTable - :
//    * DocumentRef - DocumentRef -  link to the uploaded document that requires deferred processing;
//    * DocumentDate  - Date -  date of the uploaded document for pre-sorting the table.
//
Function DocumentsForDeferredPosting() Export
	
	If TypeOf(DocumentsForDeferredPostingField) <> Type("ValueTable") Then
		
		// 
		DocumentsForDeferredPostingField = New ValueTable;
		DocumentsForDeferredPostingField.Columns.Add("DocumentRef");
		DocumentsForDeferredPostingField.Columns.Add("DocumentDate", deTypeDetails("Date"));
		
	EndIf;
	
	Return DocumentsForDeferredPostingField;
	
EndFunction

// Indicates that this is an upload to the database.
// 
// Returns:
//  Boolean - 
// 
Function DataImportToInfobaseMode() Export
	
	Return IsBlankString(DataImportMode) Or Upper(DataImportMode) = Upper("ImportToInfobase");
	
EndFunction

// Adds a line to the deferred holding table that contains a reference to the document
// to be held and the date of the document to be pre-sorted.
//
// Parameters:
//  ObjectReference         - DocumentRef -  the item to hold on hold.
//  ObjectDate            - Date -  document date;
//  AdditionalProperties - Structure -  additional properties of the object being recorded.
//
Procedure AddObjectForDeferredPosting(ObjectReference, ObjectDate, AdditionalProperties) Export
	
	DeferredPostingTable = DocumentsForDeferredPosting();
	NewRow = DeferredPostingTable.Add();
	NewRow.DocumentRef = ObjectReference;
	NewRow.DocumentDate  = ObjectDate;
	
	AdditionalPropertiesForDeferredPosting().Insert(ObjectReference, AdditionalProperties);
	
EndProcedure

// Writes an object to the information database.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject -  the object being recorded.
//  Type - String -  type of object as a string.
//  WriteObject - Boolean -  indicates that the object was recorded.
//  SendBack - Boolean -  indicates that the state of the data element in this information
//                           database should be passed to the correspondent information database.
// 
Procedure WriteObjectToIB(Object, Type, WriteObject = False, Val SendBack = False) Export
	
	// 
	If DataImportToValueTableMode() Then
		Return;
	EndIf;
		
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(Object.Metadata().FullName());
		Else
			IsSeparatedMetadataObject = False;
		EndIf;
		
		If Not IsSeparatedMetadataObject Then 
		
			ErrorMessageString = NStr("en = 'Attempting to modify shared data (%1) in a separated session.';");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, Object.Metadata().FullName());
			
			WriteToExecutionProtocol(ErrorMessageString,, False,,,, Enums.ExchangeExecutionResults.CompletedWithWarnings);
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// 
	SetDataExchangeLoad(Object,, SendBack);
	
	// 
	RemoveDeletionMarkFromPredefinedItem(Object, Type);
	
	BeginTransaction();
	Try
		
		// 
		Object.Write();
		
		InfobaseObjectsMaps = Undefined;
		If Object.AdditionalProperties.Property("InfobaseObjectsMaps", InfobaseObjectsMaps)
			And InfobaseObjectsMaps <> Undefined Then
			
			InfobaseObjectsMaps.SourceUUID = Object.Ref;
			
			InformationRegisters.InfobaseObjectsMaps.AddRecord(InfobaseObjectsMaps);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteObject = False;
		
		ErrorMessageString = WriteErrorInfoToProtocol(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			Object, Type);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

// Cancels the placement of the object in the information database.
//
// Parameters:
//  Object - DocumentObject -  document to cancel the event.
//  Type - String -  type of object as a string.
//  WriteObject - Boolean -  indicates that the object was recorded.
//
Procedure UndoObjectPostingInIB(Object, Type, WriteObject = False) Export
	
	If DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
		Enums.DataExchangeIssuesTypes.UnpostedDocument);
	
	// 
	SetDataExchangeLoad(Object);
	
	BeginTransaction();
	Try
		
		// 
		Object.Posted = False;
		Object.Write();
		
		InfobaseObjectsMaps = Undefined;
		If Object.AdditionalProperties.Property("InfobaseObjectsMaps", InfobaseObjectsMaps)
			And InfobaseObjectsMaps <> Undefined Then
			
			InfobaseObjectsMaps.SourceUUID = Object.Ref;
			
			InformationRegisters.InfobaseObjectsMaps.AddRecord(InfobaseObjectsMaps);
		EndIf;
		
		DataExchangeServer.DeleteDocumentRegisterRecords(Object);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		WriteObject = False;
		
		ErrorMessageString = WriteErrorInfoToProtocol(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			Object, Type);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

// Sets the delete mark.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject - 
//  DeletionMark - Boolean -  flag for marking deletion.
//  ObjectTypeName - String -  type of object as a string.
//
Procedure SetObjectDeletionMark(Object, DeletionMark, ObjectTypeName) Export
	
	If (DeletionMark = Undefined And Object.DeletionMark <> True)
		Or DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	If ObjectTypeName = "Document" Then
		SetDataExchangeLoad(Object, False);
		InformationRegisters.DataExchangeResults.RecordIssueResolved(Object,
			Enums.DataExchangeIssuesTypes.UnpostedDocument);
	EndIf;
	
	MarkToSet = ?(DeletionMark <> Undefined, DeletionMark, False);
	
	SetDataExchangeLoad(Object);
		
	// 
	If ObjectTypeName = "Catalog"
		Or ObjectTypeName = "ChartOfCharacteristicTypes"
		Or ObjectTypeName = "ChartOfAccounts" Then
		
		If Not Object.Predefined Then
			
			Object.SetDeletionMark(MarkToSet, False);
			
		EndIf;
		
	Else
		
		Object.SetDeletionMark(MarkToSet);
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region Other

// Logs the warning in the log.
// If this procedure was accessed during data exchange, data exchange will not be stopped.
// After the exchange is completed, the status of the exchange in the monitor for the user will be set to "Warning",
// if there were no errors.
//
// Parameters:
//  Warning - String -  the text of the warning that you need to register.
//            Information, warnings, and errors that occur during data exchange are recorded in the log.
// 
Procedure RecordWarning(Warning) Export
	
	WriteToExecutionProtocol(Warning,,False,,,, Enums.ExchangeExecutionResults.CompletedWithWarnings);
	
EndProcedure

// Sets the marking state for subordinate rows of the value tree row.
// Depending on the mark of the current line.
//
// Parameters:
//  CurRow - ValueTreeRow -  the elements of which should be marked.
//  Attribute - String -  name of the prop that is responsible for tagging.
// 
Procedure SetSubordinateMarks(CurRow, Attribute) Export

	SubordinateItems = CurRow.Rows;

	If SubordinateItems.Count() = 0 Then
		Return;
	EndIf;
	
	For Each String In SubordinateItems Do
		
		If String.BuilderSettings = Undefined 
			And Attribute = "UseFilter1" Then
			
			String[Attribute] = 0;
			
		Else
			
			String[Attribute] = CurRow[Attribute];
			
		EndIf;
		
		SetSubordinateMarks(String, Attribute);
		
	EndDo;
		
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated: You should use the function resultsquery
// for uploading and clearing Data Generates the result of the query for uploading and clearing data.
//
//  Parameters:
//       Properties                      - Structure -  contains the properties of the object.
//       TypeName                       - String -  name of the object type.
//       SelectionForDataClearing       - Boolean -  indicates whether the selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean -  indicates whether direct deletion is required.
//       SelectAllFields               - Boolean -  indicates whether all fields must be selected.
//
//  Returns:
//       QueryResult, Undefined - 
//
Function GetQueryResultForExportDataClearing(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export 
	
	Return QueryResultForExpotingDataClearing(Properties, TypeName,
		SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
	
EndFunction

// Deprecated: You should use the fetch function for uploading and clearing Data
// Creates a selection for uploading and clearing data.
//
//  Parameters:
//       Properties                      - Structure -  contains the properties of the object.
//       TypeName                       - String -  name of the object type.
//       SelectionForDataClearing       - Boolean -  indicates whether the selection is passed for clearing.
//       DeleteObjectsDirectly - Boolean -  indicates whether direct deletion is required.
//       SelectAllFields               - Boolean -  indicates whether all fields must be selected.
//
//  Returns:
//       QueryResultSelection, Undefined - 
//
Function GetSelectionForDataClearingExport(Properties, TypeName, 
	SelectionForDataClearing = False, DeleteObjectsDirectly = False, SelectAllFields = True) Export
	
	Return SelectionForExpotingDataClearing(Properties, TypeName,
		SelectionForDataClearing, DeleteObjectsDirectly, SelectAllFields);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region ExportProperties1

// Function-property: flag for data exchange error.
//
// Returns:
//  Boolean - 
//
Function FlagErrors() Export
	
	If TypeOf(ErrorFlagField) <> Type("Boolean") Then
		
		ErrorFlagField = False;
		
	EndIf;
	
	Return ErrorFlagField;
	
EndFunction

// Function property: the result of the data exchange.
//
// Returns:
//  EnumRef.ExchangeExecutionResults -  the result of the data exchange.
//
Function ExchangeExecutionResult() Export
	
	If TypeOf(ExchangeResultField) <> Type("EnumRef.ExchangeExecutionResults") Then
		
		ExchangeResultField = Enums.ExchangeExecutionResults.Completed2;
		
	EndIf;
	
	Return ExchangeResultField;
	
EndFunction

// Function property: the result of the data exchange.
//
// Returns:
//  String - 
//
Function ExchangeExecutionResultString() Export
	
	Return Common.EnumerationValueName(ExchangeExecutionResult());
	
EndFunction

// Property function: matches the data tables of the incoming exchange message.
//
// Returns:
//  Map - 
//
Function DataTablesExchangeMessages() Export
	
	If TypeOf(DataTableExchangeMessagesField) <> Type("Map") Then
		
		DataTableExchangeMessagesField = New Map;
		
	EndIf;
	
	Return DataTableExchangeMessagesField;
	
EndFunction

// Property function: a table of values with statistical and additional information about the incoming exchange message.
//
// Returns:
//  ValueTable - 
//
Function PackageHeaderDataTable() Export
	
	If TypeOf(PackageHeaderDataTableField) <> Type("ValueTable") Then
		
		PackageHeaderDataTableField = New ValueTable;
		
		Columns = PackageHeaderDataTableField.Columns;
		
		Columns.Add("ObjectTypeString",            deTypeDetails("String"));
		Columns.Add("ObjectCountInSource", deTypeDetails("Number"));
		Columns.Add("SearchFields",                   deTypeDetails("String"));
		Columns.Add("TableFields",                  deTypeDetails("String"));
		
		Columns.Add("SourceTypeString", deTypeDetails("String"));
		Columns.Add("DestinationTypeString", deTypeDetails("String"));
		
		Columns.Add("SynchronizeByID", deTypeDetails("Boolean"));
		Columns.Add("IsObjectDeletion", deTypeDetails("Boolean"));
		Columns.Add("IsClassifier", deTypeDetails("Boolean"));
		Columns.Add("UsePreview", deTypeDetails("Boolean"));
		
	EndIf;
	
	Return PackageHeaderDataTableField;
	
EndFunction

// Property function: a string that contains an error message during data exchange.
//
// Returns:
//  String - 
//
Function ErrorMessageString() Export
	
	If TypeOf(ErrorMessageStringField) <> Type("String") Then
		
		ErrorMessageStringField = "";
		
	EndIf;
	
	Return ErrorMessageStringField;
	
EndFunction

// Property function: the number of objects that were loaded.
//
// Returns:
//  Number - 
//
Function ImportedObjectCounter() Export
	
	If TypeOf(ImportedObjectsCounterField) <> Type("Number") Then
		
		ImportedObjectsCounterField = 0;
		
	EndIf;
	
	Return ImportedObjectsCounterField;
	
EndFunction

// Property function: the number of objects that were unloaded.
//
// Returns:
//  Number - 
//
Function ExportedObjectCounter() Export
	
	If TypeOf(ExportedObjectsCounterField) <> Type("Number") Then
		
		ExportedObjectsCounterField = 0;
		
	EndIf;
	
	Return ExportedObjectsCounterField;
	
EndFunction

#EndRegion

#Region DataExport

// Performs the downloading of data.
// -- All objects are uploaded to a single file.
// -- The file header is loaded with:
//	 - the rules of the exchange.
//	 - information about data types.
//	 - data exchange (name of exchange, codes of nodes, number of messages (handshake)).
//
// Parameters:
//      DataProcessorForDataImport - ОбработкаОбъект.КонвертацияОбъектовИнформационныхБаз в COM-connection.
//
Procedure RunDataExport(DataProcessorForDataImport = Undefined) Export
	
	DataExchangeServer.ClearErrorsListOnExportData(NodeForExchange);
	
	SetErrorFlag2(False);
	
	ErrorMessageStringField = "";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	ExportedByRefObjectsField = Undefined;
	CreatedOnExportObjectsField = Undefined;
	ExportedByRefMetadataObjectsField = Undefined;
	ObjectsRegistrationRulesField = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	DataImportDataProcessorField = DataProcessorForDataImport;
	
	InitializeKeepExchangeProtocol();
	
	// 
	If IsExchangeOverExternalConnection() Then
		ExchangeFile = New TextWriter;
	Else
		
		If IsMessageImportToMap() Then
			ExchangeFileName = GetTempFileName("xml");
		EndIf;
		
		OpenExportFile();
	EndIf;
	
	If FlagErrors() Then
		ExchangeFile = Undefined;
		FinishKeepExchangeProtocol();
		Return;
	EndIf;
	
	SecurityProfileName = InitializeDataProcessors();
	
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	If IsExchangeOverExternalConnection() Then
		
		DataProcessorForDataImport().ExternalConnectionBeforeDataImport();
		
		DataProcessorForDataImport().ImportExchangeRules(XMLRules, "String");
		
		If DataProcessorForDataImport().FlagErrors() Then
			
			MessageString = NStr("en = 'Peer infobase error: %1';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DataProcessorForDataImport().ErrorMessageString());
			WriteToExecutionProtocol(MessageString);
			FinishKeepExchangeProtocol();
			Return;
			
		EndIf;
		
		Cancel = False;
		
		DataProcessorForDataImport().ExternalConnectionConversionHandlerBeforeDataImport(Cancel);
		
		If Cancel Then
			FinishKeepExchangeProtocol();
			DisableDataProcessorForDebug();
			Return;
		EndIf;
		
	Else
		
		// 
		ExchangeFile.WriteLine(XMLRules);
		
	EndIf;
	
	// 
	Try
		ExecuteExport();
	Except
		WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		FinishKeepExchangeProtocol();
		ExchangeFile = Undefined;
		ExportedByRefObjectsField = Undefined;
		CreatedOnExportObjectsField = Undefined;
		ExportedByRefMetadataObjectsField = Undefined;
		Return;
	EndTry;
	
	If IsExchangeOverExternalConnection() Then
		
		If Not FlagErrors() Then
			
			DataProcessorForDataImport().ExternalConnectionAfterDataImport();
			
		EndIf;
		
	Else
		
		// 
		CloseFile();
		
	EndIf;
	
	FinishKeepExchangeProtocol();
	
	If IsMessageImportToMap() Then
		
		TextDocument = New TextDocument;
		TextDocument.Read(ExchangeFileName);
		
		DataProcessorForDataImport().PutMessageForDataMapping(TextDocument.GetText());
		
		TextDocument = Undefined;
		
		DeleteFiles(ExchangeFileName);
		
	EndIf;
	
	// 
	ExportedByRefObjectsField = Undefined;
	CreatedOnExportObjectsField = Undefined;
	ExportedByRefMetadataObjectsField = Undefined;
	DisableDataProcessorForDebug();
	ExchangeFile = Undefined;
	
EndProcedure

// Unloads the selection register.
// 
// Parameters:
//         RecordSetForExport - Structure -  containing a selection, or a set of register Entries.
//         Rule - ValueTableRow - :
//           * Properties - See PropertiesConversionRulesCollection
//         IncomingData - Arbitrary -  incoming data for the conversion rule.
//         DontExportObjectsByRefs - Boolean -  a sign to unload the properties on the links..
//         OCRName - String -  name of the conversion rule.
//         DataExportRule - ValueTableRow -  from the data upload rules table.
//
Procedure UnloadRegister(RecordSetForExport, 
							Rule = Undefined, 
							IncomingData = Undefined, 
							DontExportObjectsByRefs = False, 
							OCRName = "",
							DataExportRule = Undefined) Export
							
	OutgoingData = Undefined;						
							
	
	DetermineOCRByParameters(Rule, RecordSetForExport, OCRName);
	
	ExchangeObjectsPriority = Rule.ExchangeObjectsPriority;
	
	If TypeOf(RecordSetForExport) = Type("Structure") Then
		
		RecordSetFilter  = RecordSetForExport.Filter;
		RecordSetRows = RecordSetForExport.Rows;
		
	Else // RecordSet
		
		RecordSetFilter  = RecordSetForExport.Filter;
		RecordSetRows = RecordSetForExport;
		
	EndIf;
	
	// 
	// 
	
	Receiver = CreateNode("RegisterRecordSet");
	
	RegisterRecordCount = RecordSetRows.Count();
		
	SnCounter = SnCounter + 1;
	NBSp        = SnCounter;
	
	SetAttribute(Receiver, "NBSp",			NBSp);
	SetAttribute(Receiver, "Type", 			StrReplace(Rule.Receiver, "InformationRegisterRecord.", "InformationRegisterRecordSet."));
	SetAttribute(Receiver, "RuleName",	Rule.Name);
	
	WriteExchangeObjectPriority(ExchangeObjectsPriority, Receiver);
	
	ExportingEmptySet = RegisterRecordCount = 0;
	If ExportingEmptySet Then
		SetAttribute(Receiver, "IsEmptySet",	True);
	EndIf;
	
	Receiver.WriteStartElement("Filter");
	
	SourceStructure = New Structure;
	PCRArrayForExport = New Array();
	
	For Each FIlterRow In RecordSetFilter Do
		
		If FIlterRow.Use = False Then
			Continue;
		EndIf;
		
		PCRRow = Rule.Properties.Find(FIlterRow.Name, "Source");
		
		If PCRRow = Undefined Then
			
			PCRRow = Rule.Properties.Find(FIlterRow.Name, "Receiver");
			
		EndIf;
		
		If PCRRow <> Undefined
			And  (PCRRow.DestinationKind = "Property"
			Or PCRRow.DestinationKind = "Dimension") Then
			
			PCRArrayForExport.Add(PCRRow);
			
			Var_Key = ?(IsBlankString(PCRRow.Source), PCRRow.Receiver, PCRRow.Source);
			
			SourceStructure.Insert(Var_Key, FIlterRow.Value);
			
		EndIf;
		
	EndDo;
	
	// 
	For Each SearchPropertyRow In Rule.SearchProperties Do
		
		If IsBlankString(SearchPropertyRow.Receiver)
			And Not IsBlankString(SearchPropertyRow.ParameterForTransferName) Then
			
			PCRArrayForExport.Add(SearchPropertyRow);	
			
		EndIf;
		
	EndDo;
	
	ExportProperties(SourceStructure, Undefined, IncomingData, OutgoingData, Rule, PCRArrayForExport, Receiver, 
		, , True, , , , ExportingEmptySet);
	
	Receiver.WriteEndElement();
	
	Receiver.WriteStartElement("RecordSetRows");
	
	// 
	For Each RegisterLine In RecordSetRows Do
		
		ExportSelectionObject(RegisterLine, DataExportRule, , IncomingData, DontExportObjectsByRefs, True, 
			Receiver, , OCRName, False);
				
	EndDo;
	
	Receiver.WriteEndElement();
	
	Receiver.WriteEndElement();
	
	WriteToFile(Receiver);
	
	UpdateDataInDataToExport();
	
	SetExportedToFileObjectFlags();
	
EndProcedure
#EndRegion

#Region DataImport

// Loads data from the exchange message file.
// Data is uploaded to the information database.
//
// Parameters:
// 
Procedure RunDataImport() Export
	
	DataExchangeServer.ClearErrorsListOnDataImport(NodeForExchange);
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	MessageReader = Undefined; // See MessageReaderDetails
	Try
		DataImportMode = "ImportToInfobase";
		
		ErrorMessageStringField = "";
		DataExchangeStateField = Undefined;
		ExchangeResultField = Undefined;
		DataForImportTypeMapField = Undefined;
		ImportedObjectsCounterField = Undefined;
		DocumentsForDeferredPostingField = Undefined;
		ObjectsForDeferredPostingField = Undefined;
		DocumentsForDeferredPostingMap = Undefined;
		ExchangePlanNodePropertyField = Undefined;
		IncomingExchangeMessageFormatVersionField = Undefined;
		HasObjectRegistrationDataAdjustment = False;
		HasObjectChangeRecordData = False;
		
		GlobalNotWrittenObjectStack = New Map;
		LastSearchByRefNumber = 0;
		
		InitManagersAndMessages();
		
		SetErrorFlag2(False);
		
		InitializeCommentsOnDataExportAndImport();
		
		InitializeKeepExchangeProtocol();
		
		CustomSearchFieldsInformationOnDataImport = New Map;
		
		AdditionalSearchParameterMap = New Map;
		ConversionRulesMap = New Map;
		
		DeferredDocumentRegisterRecordCount = 0;
		
		If ContinueOnError Then
			UseTransactions = False;
		EndIf;
		
		If ProcessedObjectsCountToUpdateStatus = 0 Then
			ProcessedObjectsCountToUpdateStatus = 100;
		EndIf;
		
		DataAnalysisResultToExport = DataExchangeServer.DataAnalysisResultToExport(ExchangeFileName, False);
		ExchangeMessageFileSize = DataAnalysisResultToExport.ExchangeMessageFileSize;
		ObjectsToImportCount = DataAnalysisResultToExport.ObjectsToImportCount;
		
		SecurityProfileName = InitializeDataProcessors();
		
		If SecurityProfileName <> Undefined Then
			SetSafeMode(SecurityProfileName);
		EndIf;
		
		StartReadMessage(MessageReader);
		
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		If UseTransactions Then
			BeginTransaction();
		EndIf;
		Try
			
			RunReadingData(MessageReader);
			
			If FlagErrors() Then
				Raise NStr("en = 'Data import errors.';");
			EndIf;
			
			// 
			ExecuteWriteNotWrittenObjects();
			
			ExecuteHandlerAfterImportData();
			
			If FlagErrors() Then
				Raise NStr("en = 'Data import errors.';");
			EndIf;
			
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			If UseTransactions Then
				CommitTransaction();
			EndIf;
		Except
			If UseTransactions Then
				RollbackTransaction();
				DataExchangeInternal.DisableAccessKeysUpdate(False, False);
			Else
				DataExchangeInternal.DisableAccessKeysUpdate(False);
			EndIf;
			
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
		// 
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		Try
			ExecuteDeferredDocumentsPosting();
			ExecuteDeferredObjectsWrite();
			
			DataExchangeInternal.DisableAccessKeysUpdate(False);
		Except
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			Raise;
		EndTry;
		
		FinishMessageReader(MessageReader);
	Except
		If MessageReader <> Undefined
			And MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
	EndTry;
	
	FinishKeepExchangeProtocol();
	
	// 
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	DisableDataProcessorForDebug();
	ExchangeFile = Undefined;
	
EndProcedure

#EndRegion

#Region PackagedDataImport

// Loads data from the exchange message file to the Information Database of only the specified object types.
//
// Parameters:
//  TablesToImport - Array - 
//                                
//  :
//   
//   
// 
//  
//  
// 
Procedure ExecuteDataImportForInfobase(TablesToImport) Export
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	DataImportMode = "ImportToInfobase";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	HasObjectRegistrationDataAdjustment = False;
	HasObjectChangeRecordData = False;
	GlobalNotWrittenObjectStack = New Map;
	ConversionRulesMap = New Map;
	
	// 
	DataExchangeState().StartDate = CurrentSessionDate();
	
	// 
	MessageString = NStr("en = 'Data exchange started. Node: %1.';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(ExchangeNodeDataImport));
	WriteEventLogDataExchange1(MessageString, EventLogLevel.Information);
	
	DataExchangeInternal.DisableAccessKeysUpdate(True);
	Try
		ExecuteSelectiveMessageReader(TablesToImport);
		DataExchangeInternal.DisableAccessKeysUpdate(False);
	Except
		DataExchangeInternal.DisableAccessKeysUpdate(False);
		Raise;
	EndTry;
	
	// 
	DataExchangeState().EndDate = CurrentSessionDate();
	
	// 
	WriteDataImportEnd();
	
	// 
	MessageString = NStr("en = 'Action to execute: %1;
		|Completion status: %2;
		|Objects processed: %3.';",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
					ExchangeExecutionResult(),
					Enums.ActionsOnExchange.DataImport,
					Format(ImportedObjectCounter(), "NG=0"));
	//
	WriteEventLogDataExchange1(MessageString, EventLogLevel.Information);
	
	// 
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// Loads data from the exchange message file to a table of values for only the specified object types.
//
// Parameters:
//  TablesToImport - Array - 
//                                
//  :
//   
//   
// 
//  
//  
// 
Procedure ExecuteDataImportIntoValueTable(TablesToImport) Export
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	DataImportMode = "ImportToValueTable";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	HasObjectRegistrationDataAdjustment = False;
	HasObjectChangeRecordData = False;
	GlobalNotWrittenObjectStack = New Map;
	ConversionRulesMap = New Map;
	
	UseTransactions = False;
	
	// 
	For Each DataTableKey In TablesToImport Do
		
		SubstringsArray = StrSplit(DataTableKey, "#");
		
		ObjectType = SubstringsArray[1];
		
		DataTablesExchangeMessages().Insert(DataTableKey, InitExchangeMessageDataTable(Type(ObjectType)));
		
	EndDo;
	
	ExecuteSelectiveMessageReader(TablesToImport);
	
	// 
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// Performs sequential reading of the exchange message file while:
//     - deleting the registration of changes by the incoming receipt number
//     - exchange rules are loaded
//     - information about data types is loaded
//     - data matching information is read and recorded and is
//     -information about the types of objects and their number is collected.
//
// Parameters:
//   AnalysisParameters - Structure - :
//     * CollectClassifiersStatistics - Boolean -  flag that classifier data will be included in
//                                                    statistics.
//                                                    Classifiers are defined as reference books, PVC, charts
//                                                    of accounts, and PVR that have the following parameters set in the PKO:
//                                                    Sync to the ID. and
//                                                    continue searching for the field of Searchinglipoidentificatorunenashli.
// 
Procedure ExecuteExchangeMessageAnalysis(AnalysisParameters = Undefined) Export
	
	MessageReader = Undefined; // See MessageReaderDetails
	
	If ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	Try
		
		SetErrorFlag2(False);
		
		UseTransactions = False;
		
		ErrorMessageStringField = "";
		DataExchangeStateField = Undefined;
		ExchangeResultField = Undefined;
		IncomingExchangeMessageFormatVersionField = Undefined;
		HasObjectRegistrationDataAdjustment = False;
		HasObjectChangeRecordData = False;
		GlobalNotWrittenObjectStack = New Map;
		ConversionRulesMap = New Map;
		
		InitializeKeepExchangeProtocol();
		
		InitManagersAndMessages();
		
		// 
		DataExchangeState().StartDate = CurrentSessionDate();
		
		// 
		PackageHeaderDataTableField = Undefined;
		
		StartReadMessage(MessageReader, True);
		Try
			
			// 
			ReadDataInAnalysisMode(MessageReader, AnalysisParameters);
			
			If FlagErrors() Then
				Raise NStr("en = 'Data analysis errors.';");
			EndIf;
			
			// 
			TemporaryPackageHeaderDataTable = PackageHeaderDataTable().Copy(, "SourceTypeString, DestinationTypeString, SearchFields, TableFields");
			TemporaryPackageHeaderDataTable.GroupBy("SourceTypeString, DestinationTypeString, SearchFields, TableFields");
			
			// 
			PackageHeaderDataTable().GroupBy(
				"ObjectTypeString, SourceTypeString, DestinationTypeString, SynchronizeByID, IsClassifier, IsObjectDeletion, UsePreview",
				"ObjectCountInSource");
			//
			PackageHeaderDataTable().Columns.Add("SearchFields",  deTypeDetails("String"));
			PackageHeaderDataTable().Columns.Add("TableFields", deTypeDetails("String"));
			
			For Each TableRow In PackageHeaderDataTable() Do
				
				Filter = New Structure;
				Filter.Insert("SourceTypeString", TableRow.SourceTypeString);
				Filter.Insert("DestinationTypeString", TableRow.DestinationTypeString);
				
				TemporaryTableRows = TemporaryPackageHeaderDataTable.FindRows(Filter);
				
				TableRow.SearchFields  = TemporaryTableRows[0].SearchFields;
				TableRow.TableFields = TemporaryTableRows[0].TableFields;
				
			EndDo;
			
			ExecuteHandlerAfterImportData();
			
			FinishMessageReader(MessageReader);
			
		Except
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
	Except
		If MessageReader <> Undefined
			And MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		
	EndTry;
	
	FinishKeepExchangeProtocol();
	
	// 
	DataExchangeState().EndDate = CurrentSessionDate();
	
	// 
	WriteDataImportEnd();
	
	// 
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ConversionRulesMap = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

#EndRegion

#Region ProcessingProceduresOfExternalConnection

// Loads data from an XML string.
//
Procedure ExternalConnectionImportDataFromXMLString(XMLLine) Export
	
	If ExchangeNodeDataImportObject = Undefined
		And ValueIsFilled(ExchangeNodeDataImport) Then
		ExchangeNodeDataImportObject = ExchangeNodeDataImport.GetObject();
	EndIf;
	
	ExchangeFile.SetString(XMLLine);
	
	WritePackageToFileForArchiveAssembly(XMLLine);
	
	MessageReader = Undefined;
	Try
		
		ReadDataInExternalConnectionMode(MessageReader);
		
	Except
		
		If MessageReader <> Undefined
			And MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
		
	EndTry;
	
EndProcedure

// The handler performs the conversion Before the data is loaded for the external connections.
//
Procedure ExternalConnectionConversionHandlerBeforeDataImport(Cancel) Export
	
	// 
	If Not IsBlankString(Conversion.BeforeImportData) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeDataImport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeImportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(22, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'BeforeImportData (conversion)';"));
			Cancel = True;
		EndTry;
		
	EndIf;
	
	If Cancel Then // 
		Return;
	EndIf;
	// 
	
EndProcedure

// The initialization routine before the data is loaded via an external connection.
//
Procedure ExternalConnectionBeforeDataImport() Export
	
	DataImportMode = "ImportToInfobase";
	
	ErrorMessageStringField = "";
	DataExchangeStateField = Undefined;
	ExchangeResultField = Undefined;
	DataForImportTypeMapField = Undefined;
	ImportedObjectsCounterField = Undefined;
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	ExchangePlanNodePropertyField = Undefined;
	IncomingExchangeMessageFormatVersionField = Undefined;
	
	ArchiveParameters = InformationRegisters.ExchangeMessageArchiveSettings.GetSettings(ExchangeNodeDataImport);
	
	If ArchiveParameters <> Undefined And ArchiveParameters.FilesCount > 0 Then
		
		PutMessageToArchiveWithExternalConnection = True;
		
		PackageNumber = 0;
		TempDirectory = GetTempFileName();
		CreateDirectory(TempDirectory);
		TempDirForArchiveAssembly = CommonClientServer.AddLastPathSeparator(TempDirectory);
		
		WriteMessageHeaderToArchive();
		
	Else
		
		PutMessageToArchiveWithExternalConnection = False;
		
	EndIf;
	
	GlobalNotWrittenObjectStack = New Map;
	LastSearchByRefNumber = 0;
	
	InitManagersAndMessages();
	
	SetErrorFlag2(False);
	
	InitializeCommentsOnDataExportAndImport();
	
	InitializeKeepExchangeProtocol();
	
	CustomSearchFieldsInformationOnDataImport = New Map;
	
	AdditionalSearchParameterMap = New Map;
	ConversionRulesMap = New Map;
	
	DeferredDocumentRegisterRecordCount = 0;
	
	If ProcessedObjectsCountToUpdateStatus = 0 Then
		ProcessedObjectsCountToUpdateStatus = 100;
	EndIf;
	
	// 
	Rules.Clear();
	ConversionRulesTable.Clear();
	
	ExchangeFile = New XMLReader;
	
	HasObjectChangeRecordData = False;
	HasObjectRegistrationDataAdjustment = False;
	
EndProcedure

// Executes the handler After loading the data.
// Resets variables and holds pending the holding of documents and writing of objects.
//
Procedure ExternalConnectionAfterDataImport() Export
	
	CollectAndArchiveExchangeMessage();
	
	// 
	ExecuteWriteNotWrittenObjects();
	
	// 
	If Not FlagErrors() Then
		
		If Not IsBlankString(Conversion.AfterImportData) Then
			
			Try
				
				If ImportHandlersDebug Then
					
					ExecuteHandlerConversionAfterImportData();
					
				Else
					
					Execute(Conversion.AfterImportData);
					
				EndIf;
				
			Except
				WriteErrorInfoConversionHandlers(23, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
					NStr("en = 'AfterImportData (conversion)';"));
			EndTry;
			
		EndIf;
		
	EndIf;
	
	If Not FlagErrors() Then
		
		// 
		ExecuteDeferredDocumentsPosting();
		ExecuteDeferredObjectsWrite();
		
	EndIf;
	
	If Not FlagErrors() Then
		
		BeginTransaction();
		Try
			Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(ExchangeNodeDataImport));
		    LockItem.SetValue("Ref", ExchangeNodeDataImport);
		    Block.Lock();
			
			// 
			LockDataForEdit(ExchangeNodeDataImport);
			NodeObject = ExchangeNodeDataImport.GetObject();
			
			NodeObject.ReceivedNo = MessageNo();
			NodeObject.DataExchange.Load = True;
			
			NodeObject.Write();
	
			CommitTransaction();
		Except
			RollbackTransaction();
			WriteErrorInfoToProtocol(173, ErrorProcessing.BriefErrorDescription(ErrorInfo()), NodeObject);
		EndTry;
		
	EndIf;
	
	If Not FlagErrors() Then
		
		If HasObjectRegistrationDataAdjustment = True Then
			
			InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustmentUnconditionally(ExchangeNodeDataImport);
			
		EndIf;
		
		If HasObjectChangeRecordData = True Then
			
			InformationRegisters.InfobaseObjectsMaps.DeleteObsoleteExportByRefModeRecords(ExchangeNodeDataImport);
			
		EndIf;
		
	EndIf;
	
	FinishKeepExchangeProtocol();
	
	// 
	DocumentsForDeferredPostingField = Undefined;
	ObjectsForDeferredPostingField = Undefined;
	DocumentsForDeferredPostingMap = Undefined;
	DataForImportTypeMapField = Undefined;
	GlobalNotWrittenObjectStack = Undefined;
	ExchangeFile = Undefined;
	
EndProcedure

// Opens a new transaction.
//
Procedure ExternalConnectionCheckTransactionStartAndCommitOnDataImport() Export
	
	If UseTransactions
		And ObjectCountPerTransaction > 0
		And ImportedObjectCounter() % ObjectCountPerTransaction = 0 Then
		
		CommitTransaction();
		BeginTransaction();
		
	EndIf;
	
EndProcedure

// Opens a transaction for exchange over an external connection, if required.
//
Procedure ExternalConnectionBeginTransactionOnDataImport() Export
	
	If UseTransactions Then
		BeginTransaction();
	EndIf;
	
EndProcedure

// Completes the transaction when exchanging via an external connection (if the download was performed in a transaction).
//
Procedure ExternalConnectionCommitTransactionOnDataImport() Export
	
	If UseTransactions Then
		
		If FlagErrors() Then
			RollbackTransaction();
		Else
			CommitTransaction();
		EndIf;
		
	EndIf;
	
EndProcedure

// Cancels the transaction when exchanging via an external connection.
//
Procedure ExternalConnectionRollbackTransactionOnDataImport() Export
	
	While TransactionActive() Do
		RollbackTransaction();
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

// Places the exchange file in the file storage service for later matching.
// Data is not being loaded.
//
Procedure PutMessageForDataMapping(XMLExportData) Export
	
	DumpDirectory = DataExchangeServer.TempFilesStorageDirectory();
	TempFileName = DataExchangeServer.UniqueExchangeMessageFileName();
	
	TempFileFullName = CommonClientServer.GetFullFileName(
		DumpDirectory, TempFileName);
		
	TextDocument = New TextDocument;
	TextDocument.AddLine(XMLExportData);
	TextDocument.Write(TempFileFullName, , Chars.LF);
	
	FileID = DataExchangeServer.PutFileInStorage(TempFileFullName);
	
	DataExchangeInternal.PutMessageForDataMapping(ExchangeNodeDataImport, FileID);
	
EndProcedure

// Sets the value of the "Load" parameter for the object's "Tricked" property.
//
// Parameters:
//   Object - Arbitrary -  the data object for which the property is set.
//   Value - Boolean -  the value of the "Upload" property to set.
//   SendBack - Boolean
//
Procedure SetDataExchangeLoad(Object, Value = True, Val SendBack = False) Export
	
	DataExchangeServer.SetDataExchangeLoad(Object, Value, SendBack, ExchangeNodeDataImport);
	
EndProcedure

// Prepares a string with information about rules based on the read data from the XML file.
//
// Parameters:
//   IsCorrespondentRules - Boolean
// 
// Returns:
//   String - 
//
Function RulesInformation(IsCorrespondentRules = False) Export
	
	// 
	InfoString = "";
	
	If FlagErrors() Then
		Return InfoString;
	EndIf;
	
	If IsCorrespondentRules Then
		InfoString = NStr("en = 'Peer (%1) conversion rules created on %2';");
	Else
		InfoString = NStr("en = 'This infobase (%1) conversion rules created on %2';");
	EndIf;
	
	SourceConfigurationPresentation = ConfigurationPresentationFromExchangeRules("Source1");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(InfoString,
							SourceConfigurationPresentation,
							Format(Conversion.CreationDateTime, "DLF =DD"));
EndFunction

// Sets the event name for writing messages to the log.
// 
// Parameters:
//   EventName - String
//
Procedure SetEventLogMessageKey(EventName) Export
	
	EventLogMessageKey = EventName;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region InternalProperties

Function DataProcessorForDataImport()
	
	Return DataImportDataProcessorField;
	
EndFunction

Function IsExchangeOverExternalConnection()
	
	Return DataProcessorForDataImport() <> Undefined
		And Not (DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping");
	
EndFunction
	
Function IsMessageImportToMap()	
	
	Return DataProcessorForDataImport() <> Undefined
		And DataProcessorForDataImport().DataImportMode = "ImportMessageForDataMapping";
		
EndFunction

Function DataExchangeState()
	
	If TypeOf(DataExchangeStateField) <> Type("Structure") Then
		
		DataExchangeStateField = New Structure;
		DataExchangeStateField.Insert("InfobaseNode");
		DataExchangeStateField.Insert("ActionOnExchange");
		DataExchangeStateField.Insert("ExchangeExecutionResult");
		DataExchangeStateField.Insert("StartDate");
		DataExchangeStateField.Insert("EndDate");
		
	EndIf;
	
	Return DataExchangeStateField;
	
EndFunction

Function DataForImportTypeMap()
	
	If TypeOf(DataForImportTypeMapField) <> Type("Map") Then
		
		DataForImportTypeMapField = New Map;
		
	EndIf;
	
	Return DataForImportTypeMapField;
	
EndFunction

Function DataImportToValueTableMode()
	
	Return Not DataImportToInfobaseMode();
	
EndFunction

Function UUIDColumnName()
	
	Return "UUID";
	
EndFunction

Function ColumnNameTypeAsString()
	
	Return "TypeAsString";
	
EndFunction

Function EventLogMessageKey()
	
	If TypeOf(EventLogMessageKey) <> Type("String")
		Or IsBlankString(EventLogMessageKey) Then
		
		EventLogMessageKey = DataExchangeServer.DataExchangeEventLogEvent();
		
	EndIf;
	
	Return EventLogMessageKey;
EndFunction

Function ExchangeResultPriorities()
	
	If TypeOf(ExchangeResultsPrioritiesField) <> Type("Array") Then
		
		ExchangeResultsPrioritiesField = New Array;
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.Error);
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.ErrorMessageTransport);
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.Canceled);
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.CompletedWithWarnings);
		ExchangeResultsPrioritiesField.Add(Enums.ExchangeExecutionResults.Completed2);
		ExchangeResultsPrioritiesField.Add(Undefined);
		
	EndIf;
	
	Return ExchangeResultsPrioritiesField;
EndFunction

Function ObjectPropertyDescriptionTables()
	
	If TypeOf(ObjectsPropertiesDetailsTableField) <> Type("Map") Then
		
		ObjectsPropertiesDetailsTableField = New Map;
		
	EndIf;
	
	Return ObjectsPropertiesDetailsTableField;
EndFunction

Function AdditionalPropertiesForDeferredPosting()
	
	If TypeOf(DocumentsForDeferredPostingMap) <> Type("Map") Then
		
		// 
		DocumentsForDeferredPostingMap = New Map;
		
	EndIf;
	
	Return DocumentsForDeferredPostingMap;
	
EndFunction

Function ObjectsForDeferredPosting()
	
	If TypeOf(ObjectsForDeferredPostingField) <> Type("Map") Then
		
		// 
		ObjectsForDeferredPostingField = New Map;
		
	EndIf;
	
	Return ObjectsForDeferredPostingField;
	
EndFunction

Function ExportedByRefObjects()
	
	If TypeOf(ExportedByRefObjectsField) <> Type("Array") Then
		
		ExportedByRefObjectsField = New Array;
		
	EndIf;
	
	Return ExportedByRefObjectsField;
EndFunction

Function CreatedOnExportObjects()
	
	If TypeOf(CreatedOnExportObjectsField) <> Type("Array") Then
		
		CreatedOnExportObjectsField = New Array;
		
	EndIf;
	
	Return CreatedOnExportObjectsField;
EndFunction

Function ExportedByRefMetadataObjects()
	
	If TypeOf(ExportedByRefMetadataObjectsField) <> Type("Map") Then
		
		ExportedByRefMetadataObjectsField = New Map;
		
	EndIf;
	
	Return ExportedByRefMetadataObjectsField;
EndFunction

Function ExportObjectByRef(Object, ExchangePlanNode)
	
	MetadataObject = Metadata.FindByType(TypeOf(Object));
	
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	
	// 
	Result = ExportedByRefMetadataObjects().Get(MetadataObject);
	
	If Result = Undefined Then
		
		Result = False;
		
		// 
		Filter = New Structure("MetadataObjectName3", MetadataObject.FullName());
		
		RulesArray = ObjectsRegistrationRules(ExchangePlanNode).FindRows(Filter);
		
		For Each Rule In RulesArray Do
			
			If Not IsBlankString(Rule.FlagAttributeName) Then
				
				FlagAttributeValue = Undefined;
				ExchangePlanNodeProperties(ExchangePlanNode).Property(Rule.FlagAttributeName, FlagAttributeValue);
				
				Result = Result Or ( FlagAttributeValue = Enums.ExchangeObjectExportModes.ExportIfNecessary
										Or FlagAttributeValue = Enums.ExchangeObjectExportModes.EmptyRef());
				//
				If Result Then
					Break;
				EndIf;
				
			EndIf;
			
		EndDo;
		
		// 
		ExportedByRefMetadataObjects().Insert(MetadataObject, Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function ExchangePlanName()
	
	If TypeOf(ExchangePlanNameField) <> Type("String")
		Or IsBlankString(ExchangePlanNameField) Then
		
		If ValueIsFilled(NodeForExchange) Then
			
			ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(NodeForExchange);
			
		ElsIf ValueIsFilled(ExchangeNodeDataImport) Then
			
			ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(ExchangeNodeDataImport);
			
		ElsIf ValueIsFilled(ExchangePlanNameSOR) Then
			
			ExchangePlanNameField = ExchangePlanNameSOR;
			
		Else
			
			ExchangePlanNameField = "";
			
		EndIf;
		
	EndIf;
	
	Return ExchangePlanNameField;
EndFunction

Function ExchangePlanNodeProperties(Node)
	
	If TypeOf(ExchangePlanNodePropertyField) <> Type("Structure") Then
		
		ExchangePlanNodePropertyField = New Structure;
		
		// 
		AttributesNames = Common.AttributeNamesByType(Node, Type("EnumRef.ExchangeObjectExportModes"));
		
		// 
		If Not IsBlankString(AttributesNames) Then
			
			ExchangePlanNodePropertyField = Common.ObjectAttributesValues(Node, AttributesNames);
			
		EndIf;
		
	EndIf;
	
	Return ExchangePlanNodePropertyField;
EndFunction

Function IncomingExchangeMessageFormatVersion()
	
	If TypeOf(IncomingExchangeMessageFormatVersionField) <> Type("String") Then
		
		IncomingExchangeMessageFormatVersionField = "0.0.0.0";
		
	EndIf;
	
	// 
	VersionDigits1 = StrSplit(IncomingExchangeMessageFormatVersionField, ".");
	
	If VersionDigits1.Count() < 4 Then
		
		DigitsCountAdd = 4 - VersionDigits1.Count();
		
		For A = 1 To DigitsCountAdd Do
			
			VersionDigits1.Add("0");
			
		EndDo;
		
		IncomingExchangeMessageFormatVersionField = StrConcat(VersionDigits1, ".");
		
	EndIf;
	
	Return IncomingExchangeMessageFormatVersionField;
EndFunction

Function MessageNo()
	
	If TypeOf(MessageNumberField) <> Type("Number") Then
		
		MessageNumberField = 0;
		
	EndIf;
	
	Return MessageNumberField;
	
EndFunction

#EndRegion

#Region CachingFunctions

Function ObjectPropertiesDescriptionTable(MetadataObject)
	
	Result = ObjectPropertyDescriptionTables().Get(MetadataObject);
	
	If Result = Undefined Then
		
		Result = Common.ObjectPropertiesDetails(MetadataObject, "Name");
		
		ObjectPropertyDescriptionTables().Insert(Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function ObjectsRegistrationRules(ExchangePlanNode)
	
	If TypeOf(ObjectsRegistrationRulesField) <> Type("ValueTable") Then
		
		ObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(
			DataExchangeCached.GetExchangePlanName(ExchangePlanNode));
		ObjectsRegistrationRulesField = ObjectsRegistrationRules.Copy(, "MetadataObjectName3, FlagAttributeName"); // ValueTable
		ObjectsRegistrationRulesField.Indexes.Add("MetadataObjectName3");
		
	EndIf;
	
	Return ObjectsRegistrationRulesField;
	
EndFunction

#EndRegion

#Region AuxiliaryProceduresToWriteAlgorithms

#Region StringOperations

// Parses a string into two parts: before the delimiter substring and after.
//
// Parameters:
//  Page1          - the string to parse;
//  Separator  - подстрока-Separator:
//  Mode        - 0 -  the separator is not included in the returned substrings;
//                 1-the separator is included in the left substring;
//                 2-the separator is included in the right substring.
//
// Returns:
//  Правая часть строки - 
// 
Function SplitWithSeparator(Page1, Val Separator, Mode=0)

	RightPart         = "";
	SeparatorPos      = StrFind(Page1, Separator);
	SeparatorLength    = StrLen(Separator);
	If SeparatorPos > 0 Then
		RightPart	 = Mid(Page1, SeparatorPos + ?(Mode=2, 0, SeparatorLength));
		Page1          = TrimAll(Left(Page1, SeparatorPos - ?(Mode=1, -SeparatorLength + 1, 1)));
	EndIf;

	Return(RightPart);

EndFunction

// Converts values from a string to an array using the specified separator.
//
// Parameters:
//  Page1            - the string to parse.
//  Separator    - substring separator.
//
// Returns:
//  Array of values
// 
Function ArrayFromString(Val Page1, Separator=",")

	Array      = New Array;
	RightPart = SplitWithSeparator(Page1, Separator);
	
	While Not IsBlankString(Page1) Do
		Array.Add(TrimAll(Page1));
		Page1         = RightPart;
		RightPart = SplitWithSeparator(Page1, Separator);
	EndDo; 

	Return(Array);
	
EndFunction

Function StringNumberWithoutPrefixes(Number)
	
	NumberWithoutPrefixes = "";
	Cnt = StrLen(Number);
	
	While Cnt > 0 Do
		
		Char = Mid(Number, Cnt, 1);
		
		If (Char >= "0" And Char <= "9") Then
			
			NumberWithoutPrefixes = Char + NumberWithoutPrefixes;
			
		Else
			
			Return NumberWithoutPrefixes;
			
		EndIf;
		
		Cnt = Cnt - 1;
		
	EndDo;
	
	Return NumberWithoutPrefixes;
	
EndFunction

// Parses a string, selecting the prefix and numeric part from it.
//
// Parameters:
//  Page1            - String -  the string to parse;
//  NumericalPart  - Number -  variable to return the numeric part of the string to;
//  Mode          - String -   if "Number", it returns the numeric part, otherwise it returns the prefix.
//
// Returns:
//  The prefix of the string
//
Function PrefixNumberCount(Val Page1, NumericalPart = "", Mode = "")

	NumericalPart = 0;
	Prefix = "";
	Page1 = TrimAll(Page1);
	Length   = StrLen(Page1);
	
	StringNumberWithoutPrefix = StringNumberWithoutPrefixes(Page1);
	StringPartLength = StrLen(StringNumberWithoutPrefix);
	If StringPartLength > 0 Then
		NumericalPart = Number(StringNumberWithoutPrefix);
		Prefix = Mid(Page1, 1, Length - StringPartLength);
	Else
		Prefix = Page1;	
	EndIf;

	If Mode = "Number" Then
		Return(NumericalPart);
	Else
		Return(Prefix);
	EndIf;

EndFunction

// Sets the number (code) to the required length. In this case, the prefix
// and the numeric part of the number are allocated, and the rest of the space between the prefix and
// the number is filled with zeros.
// This function can be used in event handlers whose program code 
// is stored in data exchange rules. Called by the Run () method.
// The "no function references found" message when checking the configuration 
// is not a configuration check error.
//
// Parameters:
//  Page1          - String-  the converted string;
//  Length        - Number -  the required length of the string.
//
// Returns:
//  String       - 
// 
Function CastNumberToLength(Val Page1, Length, AddZerosIfLengthNotLessCurrentNumberLength = True, Prefix = "")

	Page1             = TrimAll(Page1);
	IncomingNumberLength = StrLen(Page1);

	NumericalPart   = "";
	Result       = PrefixNumberCount(Page1, NumericalPart);
	
	Result = ?(IsBlankString(Prefix), Result, Prefix);
	
	NumericPartString = Format(NumericalPart, "NG=0");
	NumericPartLength = StrLen(NumericPartString);

	If (Length >= IncomingNumberLength And AddZerosIfLengthNotLessCurrentNumberLength)
		Or (Length < IncomingNumberLength) Then
		
		For TemporaryVariable = 1 To Length - StrLen(Result) - NumericPartLength Do
			
			Result = Result + "0";
			
		EndDo;
	
	EndIf;
		
	Result = Result + NumericPartString;

	Return(Result);

EndFunction

// Extends the string with the specified character to the specified length.
//
// Parameters:
//  Page1          - String -  the string to pad;
//  Length        - Number -  required length of the resulting string;
//  Than          - String -  the character that completes the string.
//
// Returns:
//  String - 
//
Function odSupplementString(Page1, Length, Than = " ")

	Result = TrimAll(Page1);
	While Length - StrLen(Result) > 0 Do
		Result = Result + Than;
	EndDo;

	Return(Result);

EndFunction

#EndRegion

#Region DataOperations

// Determines whether the passed value is filled in.
//
// Parameters:
//  Value       - 
//
// Returns:
//   Boolean - 
//
Function deEmpty(Value, ThisNULL=False)

	// 
	If Value = Undefined Then
		Return True;
	ElsIf Value = NULL Then
		ThisNULL   = True;
		Return True;
	EndIf;
	
	ValueType = TypeOf(Value);
	
	If ValueType = ValueStorageType Then
		
		Result = deEmpty(Value.Get());
		Return Result;		
		
	ElsIf ValueType = BinaryDataType Then
		
		Return False;
		
	Else
		
		// 
		// 
		Try
			Result = Not ValueIsFilled(Value);
			Return Result;
		Except
			Return False;
		EndTry;
			
	EndIf;
	
EndFunction

// Returns a type Descriptor object containing the specified type.
//
// Parameters:
//  TypeValue - строка с именем типа или значение Тип -  type of Type.
//
// Returns:
//  TypeDescription
//
Function deTypeDetails(TypeValue)

	TypeDescription = TypeDescriptionMap[TypeValue];
	
	If TypeDescription = Undefined Then
		
		TypesArray = New Array;
		If TypeOf(TypeValue) = StringType Then
			TypesArray.Add(Type(TypeValue));
		Else
			TypesArray.Add(TypeValue);
		EndIf; 
		TypeDescription	= New TypeDescription(TypesArray);
		
		TypeDescriptionMap.Insert(TypeValue, TypeDescription);
		
	EndIf;	
	
	Return TypeDescription;

EndFunction

// Returns an empty (default) value of the specified type.
//
// Parameters:
//  Type          - строка с именем типа или значение Тип -  type of Type.
//
// Returns:
//  An empty value of the specified type.
//
Function deGetEmptyValue(Type)

	EmptyTypeValue = EmptyTypeValueMap[Type];
	
	If EmptyTypeValue = Undefined Then
		
		EmptyTypeValue = deTypeDetails(Type).AdjustValue(Undefined);	
		
		EmptyTypeValueMap.Insert(Type, EmptyTypeValue);
			
	EndIf;
	
	Return EmptyTypeValue;

EndFunction

Function CheckRefExists(Ref, Manager, FoundByUUIDObject, 
	MainObjectSearchMode, SearchByUUIDQueryString)
	
	Try
			
		If MainObjectSearchMode
			Or IsBlankString(SearchByUUIDQueryString) Then
			
			FoundByUUIDObject = Ref.GetObject();
			
			If FoundByUUIDObject = Undefined Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		Else
			// 
			// 
			
			Query = New Query();
			Query.Text = SearchByUUIDQueryString + "  Ref = &Ref ";
			Query.SetParameter("Ref", Ref);
			
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
			
				Return Manager.EmptyRef();
				
			EndIf;
			
		EndIf;
		
		Return Ref;	
		
	Except
			
		Return Manager.EmptyRef();
		
	EndTry;
	
EndFunction

// Performs a simple search for an information database object by the specified property.
//
// Parameters:
//  Manager       - 
//  Property       -  
//                   
//  Value       - 
//
// Returns:
//  The found object of the information database.
//
Function deFindObjectByProperty(Manager, Property, Value, 
	FoundByUUIDObject = Undefined, 
	CommonPropertyStructure = Undefined, CommonSearchProperties = Undefined,
	MainObjectSearchMode = True, SearchByUUIDQueryString = "")
	
	If Property = "Name" Then
		
		Return Manager[Value];
		
	ElsIf Property = "{UUID}" Then
		
		RefByUUID = Manager.GetRef(New UUID(Value));
		
		Ref =  CheckRefExists(RefByUUID, Manager, FoundByUUIDObject, 
			MainObjectSearchMode, SearchByUUIDQueryString);
			
		Return Ref;
		
	ElsIf Property = "{PredefinedItemName1}" Then
		
		Ref = PredefinedManagerItem(Manager, Value);
		If Ref = Undefined Then
			Ref = Manager.FindByCode(Value);
			If Ref = Undefined Then
				Ref = Manager.EmptyRef();
			EndIf;
		EndIf;
		
		Return Ref;
		
	Else
		
		ObjectReference = FindItemUsingRequest(CommonPropertyStructure, CommonSearchProperties, , Manager);
		
		Return ObjectReference;
		
	EndIf;
	
EndFunction

// Returns the value of a predefined element by its name.
// 
Function PredefinedManagerItem(Val Manager, Val PredefinedItemName)
	
	QueryTextTemplate2 = 
	"SELECT
	|	AliasOfTheMetadataTable.PredefinedDataName AS PredefinedDataName,
	|	AliasOfTheMetadataTable.Ref AS Ref
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable
	|WHERE
	|	AliasOfTheMetadataTable.Predefined";
	
	ReplacementString = Metadata.FindByType(TypeOf(Manager)).FullName();
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", ReplacementString);
	Query = New Query(QueryText);
	
	Selection = Query.Execute().Select();
	If Selection.FindNext(New Structure("PredefinedDataName", PredefinedItemName)) Then
		
		Return Selection.Ref;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Performs a simple search for an information database object by the specified property.
//
// Parameters:
//  Page1            - String -  value of the property that 
//                   the object is searched for;
//  Type            - type of object you are looking for;
//  Property       - String -  name of the property that we are looking for the object by.
//
// Returns:
//  The found object of the information database.
//
Function deGetValueByString(Page1, Type, Property = "")

	If IsBlankString(Page1) Then
		Return New(Type);
	EndIf; 

	Properties = Managers[Type];

	If Properties = Undefined Then
		
		TypeDescription = deTypeDetails(Type);
		Return TypeDescription.AdjustValue(Page1);
		
	EndIf;

	If IsBlankString(Property) Then
		
		If Properties.TypeName = "Enum"
			Or Properties.TypeName = "BusinessProcessRoutePoint" Then
			Property = "Name";
		Else
			Property = "{PredefinedItemName1}";
		EndIf;
		
	EndIf; 

	Return deFindObjectByProperty(Properties.Manager, Property, Page1);

EndFunction

// Returns a string representation of the value type.
//
// Parameters: 
//  ValueOrType - 
//
// Returns:
//  String - 
//
Function deValueTypeAsString(ValueOrType)

	ValueType	= TypeOf(ValueOrType);
	
	If ValueType = TypeType Then
		ValueType	= ValueOrType;
	EndIf; 
	
	If (ValueType = Undefined) Or (ValueOrType = Undefined) Then
		Result = "";
	ElsIf ValueType = StringType Then
		Result = "String";
	ElsIf ValueType = NumberType Then
		Result = "Number";
	ElsIf ValueType = DateType Then
		Result = "Date";
	ElsIf ValueType = BooleanType Then
		Result = "Boolean";
	ElsIf ValueType = ValueStorageType Then
		Result = "ValueStorage";
	ElsIf ValueType = UUIDType Then
		Result = "UUID";
	ElsIf ValueType = AccumulationRecordTypeType Then
		Result = "AccumulationRecordType";
	ElsIf ValueType = TypeDescriptionOfTypes Then
		Result = "TypeDescription";
	Else
		Manager = Managers[ValueType];
		If Manager = Undefined Then
		Else
			Result = Manager.RefTypeString1;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#Region WorkingWithTypeDescriptions

Function DescriptionOfTypesInJSON(ValueDescriptionOfTypes)
	
	ArrayOfTypesOfTypeDescriptions = ValueDescriptionOfTypes.Types();
	ThisIsCompositeType = (ArrayOfTypesOfTypeDescriptions.Count() > 1);
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	JSONWriter.WriteStartObject();
	JSONWriter.WritePropertyName("TypeDescription");
	
	JSONWriter.WriteStartArray();
	
	JSONWriter.WriteStartObject();
	AddJSONPropertyAndValue(JSONWriter, "multiple", String(ThisIsCompositeType));
	JSONWriter.WriteEndObject();
	
	For Each TypeOfTypeDescriptionValue In ArrayOfTypesOfTypeDescriptions Do
		
		DescriptionType = TypeOf(TypeOfTypeDescriptionValue);
		If DescriptionType <> Type("Type") Then
			
			Continue;
			
		EndIf;
		
		JSONWriter.WriteStartObject();
		
		MetadataObject = Metadata.FindByType(TypeOfTypeDescriptionValue);
		If MetadataObject = Undefined Then
			
			SerializePrimitiveTypeDescription(JSONWriter, TypeOfTypeDescriptionValue, ValueDescriptionOfTypes);
			
		Else
			
			SerializeReferenceTypeDescription(JSONWriter, MetadataObject);
			
		EndIf;
		
		JSONWriter.WriteEndObject();
		
	EndDo;
	
	JSONWriter.WriteEndArray();
	JSONWriter.WriteEndObject(); // "TypeDescription"
	
	Return JSONWriter.Close();
	
EndFunction

Function DescriptionOfTypesFromJSON(JSONText)
	
	DescriptionOfValueTypeTypes = New TypeDescription;
	If IsBlankString(JSONText) Then
		
		Return DescriptionOfValueTypeTypes;
		
	EndIf;
	
	ArrayOfNamesOfTypeDescriptions = New Array;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(JSONText);
	
	StringQualifierLength = 0;
	StringQualifierAllowedLength = AllowedLength.Variable;
	
	NumberQualifierBitDepth = 0;
	NumberQualifierIsBitDepthOfFractionalPart = 0;
	NumberQualifierIsValidSign = AllowedSign.Any;
	
	DateQualifierOfDatePart = DateFractions.DateTime;
	
	While JSONReader.Read() Do
		
		If JSONReader.CurrentValueType = JSONValueType.PropertyName Then
			
			If Upper(JSONReader.CurrentValue) = Upper("TypeDescription") Then
				
				Continue;
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("multiple") Then
				
				JSONReader.Read();
				// 
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("typeFeatures") Then
				
				TypeNameByString = "";
				
				JSONReader.Read();
				
				TypeNameByString = TrimAll(JSONReader.CurrentValue);
				If Upper(TypeNameByString) = Upper("String") Then
					
					ArrayOfNamesOfTypeDescriptions.Add(Type("String"));
					
				ElsIf Upper(TypeNameByString) = Upper("number") Then
					
					ArrayOfNamesOfTypeDescriptions.Add(Type("Number"));
					
				ElsIf Upper(TypeNameByString) = Upper("Date") Then
					
					ArrayOfNamesOfTypeDescriptions.Add(Type("Date"));
					
				ElsIf Upper(TypeNameByString) = Upper("Boolean") Then
					
					ArrayOfNamesOfTypeDescriptions.Add(Type("Boolean"));
					
				Else 
					
					Try
						
						// 
						// 
						ArrayOfNamesOfTypeDescriptions.Add(Type(TypeNameByString));
						
					Except
						
						// 
						CommentText1 = NStr("en = 'Metadata not found: %1.';", Common.DefaultLanguageCode());
						CommentText1 = StrTemplate(CommentText1, TypeNameByString);
						
						WriteEventLogDataExchange1(CommentText1, EventLogLevel.Warning);						
						
					EndTry;
					
				EndIf;
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("lengthStr") Then
				
				JSONReader.Read();
				StringQualifierLength = Number(JSONReader.CurrentValue);
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("typeStr") Then
				
				JSONReader.Read();
				If Not IsBlankString(JSONReader.CurrentValue) Then
					
					StringQualifierAllowedLength = AllowedLength[JSONReader.CurrentValue];
					
				EndIf;
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("lengthInt") Then
				
				JSONReader.Read();
				NumberQualifierBitDepth = Number(JSONReader.CurrentValue);
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("decimal") Then
				
				JSONReader.Read();
				NumberQualifierIsBitDepthOfFractionalPart = Number(JSONReader.CurrentValue);
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("sign") Then
				
				JSONReader.Read();
				If Upper(JSONReader.CurrentValue) <> Upper("any") Then
					
					NumberQualifierIsValidSign = AllowedSign.Nonnegative;
					
				EndIf;
				
			ElsIf Upper(JSONReader.CurrentValue) = Upper("typeDate") Then
				
				JSONReader.Read();
				If Upper(JSONReader.CurrentValue) = Upper("Data") Then
					
					DateQualifierOfDatePart = DateFractions.Date;
					
				ElsIf Upper(JSONReader.CurrentValue) = Upper("Time") Then
					
					DateQualifierOfDatePart = DateFractions.Time;
					
				EndIf;
				
			EndIf;
			
		ElsIf JSONReader.CurrentValueType = JSONValueType.ObjectStart
			Or JSONReader.CurrentValueType = JSONValueType.ArrayStart
			Or JSONReader.CurrentValueType = JSONValueType.ОbjectEnd
			Or JSONReader.CurrentValueType = JSONValueType.ArrayEnd Then
			
			Continue;
			
		EndIf;
		
	EndDo;
	
	StringTypeQualifier = New StringQualifiers(StringQualifierLength, StringQualifierAllowedLength);
	NumberTypeQualifier = New NumberQualifiers(NumberQualifierBitDepth,NumberQualifierIsBitDepthOfFractionalPart,NumberQualifierIsValidSign);
	DateTypeQualifier = New DateQualifiers(DateQualifierOfDatePart);
	
	Return New TypeDescription(ArrayOfNamesOfTypeDescriptions, , , NumberTypeQualifier, StringTypeQualifier, DateTypeQualifier);
	
EndFunction

Procedure AddJSONPropertyAndValue(JSONWriter, PropertyName, PropertyValue)
	
	JSONWriter.WritePropertyName(PropertyName);
	JSONWriter.WriteValue(PropertyValue);
	
EndProcedure

Procedure SerializePrimitiveTypeDescription(JSONWriter, TypeOfTypeDescriptionValue, ValueDescriptionOfTypes)
	
	If TypeOfTypeDescriptionValue = Type("String") Then
		
		AddJSONPropertyAndValue(JSONWriter, "typeFeatures", "string");
		AddJSONPropertyAndValue(JSONWriter, "lengthStr", String(ValueDescriptionOfTypes.StringQualifiers.Length));
		AddJSONPropertyAndValue(JSONWriter, "typeStr", String(ValueDescriptionOfTypes.StringQualifiers.AllowedLength));
		
	ElsIf TypeOfTypeDescriptionValue = Type("Number") Then
		
		AllowedNumberChar = ValueDescriptionOfTypes.NumberQualifiers.AllowedSign;
		
		AddJSONPropertyAndValue(JSONWriter, "typeFeatures", "number");
		AddJSONPropertyAndValue(JSONWriter, "lengthInt", ValueDescriptionOfTypes.NumberQualifiers.Digits);
		AddJSONPropertyAndValue(JSONWriter, "decimal", ValueDescriptionOfTypes.NumberQualifiers.FractionDigits);
		AddJSONPropertyAndValue(JSONWriter, "sign", ?(AllowedNumberChar = AllowedSign.Any, "any", "non-negative"));
		
	ElsIf TypeOfTypeDescriptionValue = Type("Date") Then
		
		DescriptionOfDateParts = "dateTime";
		If ValueDescriptionOfTypes.DateQualifiers.DateFractions = DateFractions.Date Then
			
			DescriptionOfDateParts = "data";
			
		ElsIf ValueDescriptionOfTypes.DateQualifiers.DateFractions = DateFractions.Time Then
			
			DescriptionOfDateParts = "time";
			
		EndIf;
		
		AddJSONPropertyAndValue(JSONWriter, "typeFeatures", "date");
		AddJSONPropertyAndValue(JSONWriter, "typeDate", DescriptionOfDateParts);
		
	ElsIf TypeOfTypeDescriptionValue = Type("Boolean") Then
		
		AddJSONPropertyAndValue(JSONWriter, "typeFeatures", "boolean");
		
	EndIf;
	
EndProcedure

Procedure SerializeReferenceTypeDescription(JSONWriter, MetadataObject)
	
	FullName = MetadataObject.FullName();
	FullName = StrReplace(FullName, ".", "Ref.");
	
	AddJSONPropertyAndValue(JSONWriter, "typeFeatures", FullName);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region ProceduresAndFunctionsOfObjectOperationsXMLWriter

// Creates a new xml node.
// This function can be used in event handlers whose program code 
// is stored in data exchange rules. Called by the Run () method.
//
// Parameters: 
//   Name - String -  host name.
//
// Returns:
//   XMLWriter - 
//
Function CreateNode(Name)

	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement(Name);

	Return XMLWriter;

EndFunction

// Writes the element and its value to the specified object.
//
// Parameters:
//  Object         - 
//  Name            - String -  element name.
//  Value       - element value.
//
Procedure deWriteElement(Object, Name, Value="")

	Object.WriteStartElement(Name);
	Page1 = XMLString(Value);
	
	Object.WriteText(Page1);
	Object.WriteEndElement();
	
EndProcedure

// Subordinates the xml node to the specified parent node.
//
// Parameters: 
//  ParentNode1   - xml-parent node.
//  Node           - 
//
Procedure AddSubordinateNode(ParentNode1, Node)

	If TypeOf(Node) <> StringType Then
		Node.WriteEndElement();
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	ParentNode1.WriteRaw(InformationToWriteToFile);
		
EndProcedure

// Sets the attribute of the specified xml node.
//
// Parameters: 
//  Node           - xml-Node
//  Name            - attribute name.
//  Value       - set value.
//
Procedure SetAttribute(Node, Name, Value)

	RecordRow = XMLString(Value);
	
	Node.WriteAttribute(Name, RecordRow);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfObjectOperationsXMLReader

// Reads the attribute value by name from the specified object, and converts the value
// to the specified primitive type.
//
// Parameters:
//  Object      - 
//                
//  Type         - значение Тип -  type of Type. Attribute type.
//  Name         - String -  attribute name.
//
// Returns:
//  The attribute value obtained by name and cast to the specified type.
//
Function deAttribute(Object, Type, Name)

	ValueStr = TrimR(Object.GetAttribute(Name));
	If Not IsBlankString(ValueStr) Then
		Return XMLValue(Type, ValueStr);		
	ElsIf      Type = StringType Then
		Return ""; 
	ElsIf Type = BooleanType Then
		Return False;
	ElsIf Type = NumberType Then
		Return 0;
	ElsIf Type = DateType Then
		Return BlankDateValue;
	EndIf; 
	
EndFunction

// Skips xml nodes to the end of the specified element (by default, the current one).
//
// Parameters:
//  Object   - an object of the ReadXml type.
//  Name      - name of the node to skip elements to the end of.
//
Procedure deSkip(Object, Name="")

	AttachmentsCount = 0; // 

	If Name = "" Then
		
		Name = Object.LocalName;
		
	EndIf; 
	
	While Object.Read() Do
		
		If Object.LocalName <> Name Then
			Continue;
		EndIf;
		
		NodeType = Object.NodeType;
			
		If NodeType = XMLNodeTypeEndElement Then
				
			If AttachmentsCount = 0 Then
					
				Break;
					
			Else
					
				AttachmentsCount = AttachmentsCount - 1;
					
			EndIf;
				
		ElsIf NodeType = XMLNodeTypeStartElement Then
				
			AttachmentsCount = AttachmentsCount + 1;
				
		EndIf;
					
	EndDo;
	
EndProcedure

// Reads the text of the element and converts the value to the specified type.
//
// Parameters:
//  Object           - 
//  Type              - the type of value to get.
//  SearchByProperty - for reference types, you can specify a property
//                     to search for the object by: "Code", "Name", <Requestname>, "Name" (predefined value).
//
// Returns:
//  Значение xml-
//
Function deElementValue(Object, Type, SearchByProperty = "", CutStringRight = True)

	Value = "";
	Name      = Object.LocalName;

	While Object.Read() Do
		
		NodeType = Object.NodeType;
		
		If NodeType = XMLNodeTypeText Then
			
			Value = Object.Value;
			
			If CutStringRight Then
				
				Value = TrimR(Value);
				
			EndIf;
						
		ElsIf (Object.LocalName = Name) And (NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			Return Undefined;
			
		EndIf;
		
	EndDo;

	
	If (Type = StringType)
		Or (Type = BooleanType)
		Or (Type = NumberType)
		Or (Type = DateType)
		Or (Type = ValueStorageType)
		Or (Type = UUIDType)
		Or (Type = AccumulationRecordTypeType)
		Or (Type = AccountTypeKind) Then
		
		Return XMLValue(Type, Value);
		
	ElsIf (Type = TypeDescriptionOfTypes) Then
		
		Return DescriptionOfTypesFromJSON(Value);
		
	Else
		
		Return deGetValueByString(Value, Type, SearchByProperty);
		
	EndIf;
	
EndFunction

#EndRegion

#Region ExchangeFileOperationsProceduresAndFunctions

// Saves the specified xml node to a file.
//
// Parameters:
//  Node           - xml-the node to save to a file.
//
Procedure WriteToFile(Node)

	If TypeOf(Node) <> StringType Then
		InformationToWriteToFile = Node.Close();
	Else
		InformationToWriteToFile = Node;
	EndIf;
	
	If IsExchangeOverExternalConnection() Then
		
		// 
		DataProcessorForDataImport().ExternalConnectionImportDataFromXMLString(InformationToWriteToFile);
		
		If DataProcessorForDataImport().FlagErrors() Then
			
			MessageString = NStr("en = 'Peer infobase error: %1';");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, DataProcessorForDataImport().ErrorMessageString());
			ExchangeExecutionResultExternalConnection = Enums.ExchangeExecutionResults[DataProcessorForDataImport().ExchangeExecutionResultString()];
			WriteToExecutionProtocol(MessageString,,,,,, ExchangeExecutionResultExternalConnection);
			Raise MessageString;
			
		EndIf;
		// 
		
	Else
		
		ExchangeFile.WriteLine(InformationToWriteToFile);
		
	EndIf;
	
EndProcedure

// Opens the exchange file, writes the file header in accordance with the exchange format.
//
// Parameters:
//  No.
//
Function OpenExportFile()

	ExchangeFile = New TextWriter;
		
	Try
		ExchangeFile.Open(ExchangeFileName, TextEncoding.UTF8);
	Except
		ErrorPresentation = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Cannot open the file for writing the exchange message.
				|File name: %1.
				|Error details:
				|%2';"),
			String(ExchangeFileName),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteToExecutionProtocol(ErrorPresentation);
		Return "";
	EndTry;
	
	XMLInfoString = "<?xml version=""1.0"" encoding=""UTF-8""?>";
	
	ExchangeFile.WriteLine(XMLInfoString);

	TempXMLWriter = New XMLWriter();
	
	TempXMLWriter.SetString();
	
	TempXMLWriter.WriteStartElement("ExchangeFile");
	
	SetAttribute(TempXMLWriter, "FormatVersion", 				 ExchangeMessageFormatVersion());
	SetAttribute(TempXMLWriter, "ExportDate",				 CurrentSessionDate());
	SetAttribute(TempXMLWriter, "SourceConfigurationName",	 Conversion().Source);
	SetAttribute(TempXMLWriter, "SourceConfigurationVersion", Conversion().SourceConfigurationVersion);
	SetAttribute(TempXMLWriter, "DestinationConfigurationName",	 Conversion().Receiver);
	SetAttribute(TempXMLWriter, "ConversionRulesID",		 Conversion().ID);
	
	TempXMLWriter.WriteEndElement();
	
	Page1 = TempXMLWriter.Close();
	
	Page1 = StrReplace(Page1, "/>", ">");
	
	ExchangeFile.WriteLine(Page1);
	
	Return XMLInfoString + Chars.LF + Page1;
	
EndFunction

// Closes the exchange file
//
// Parameters:
//  No.
//
Procedure CloseFile()
	
	ExchangeFile.WriteLine("</ExchangeFile>");
	ExchangeFile.Close();
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfExchangeProtocolOperations

// Returns an object of the structure type containing all possible fields
// of the execution Protocol record (error messages, etc.).
//
// Parameters:
//  No.
//
// Returns:
//  Structure - 
//
Function ExchangeProtocolRecord(ErrorMessageCode = "", Val ErrorString = "")

	ErrorStructure = New Structure(
		"OCRName,
		|DPRName,
		|NBSp,
		|Gsn,
		|Source,
		|ObjectType,
		|Property,
		|Value,
		|ValueType,
		|OCR,
		|PCR,
		|PGCR,
		|DER,
		|DPR,
		|Object,
		|DestinationProperty,
		|ConvertedValue,
		|Handler,
		|ErrorDescription,
		|ModulePosition,
		|Text,
		|ErrorMessageCode,
		|ExchangePlanNode");
	
	ModuleString = SplitWithSeparator(ErrorString, "{");
	If IsBlankString(ErrorString) Then
		ErrorDescription = TrimAll(SplitWithSeparator(ModuleString, "}:"));
	Else
		ErrorDescription = ErrorString;
		ModuleString   = "{" + ModuleString;
	EndIf;
	
	If ErrorDescription <> "" Then
		ErrorStructure.ErrorDescription = ErrorDescription;
		ErrorStructure.ModulePosition  = ModuleString;
	EndIf;
	
	If ErrorStructure.ErrorMessageCode <> "" Then
		
		ErrorStructure.ErrorMessageCode = ErrorMessageCode;
		
	EndIf;
	
	Return ErrorStructure;
	
EndFunction 

Procedure InitializeKeepExchangeProtocol()
	
	If IsBlankString(ExchangeProtocolFileName) Then
		
		DataProtocolFile = Undefined;
		CommentObjectProcessingFlag = OutputInfoMessagesToMessageWindow;		
		Return;
		
	Else	
		
		CommentObjectProcessingFlag = OutputInfoMessagesToProtocol Or OutputInfoMessagesToMessageWindow;		
		
	EndIf;
	
	// 
	Try
		DataProtocolFile = New TextWriter(ExchangeProtocolFileName, TextEncoding.ANSI, , AppendDataToExchangeLog);
	Except
		DataProtocolFile = Undefined;
		MessageString = NStr("en = 'Failed to log to: %1. Error details: %2';",
			Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeProtocolFileName,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteEventLogDataExchange1(MessageString, EventLogLevel.Warning);
	EndTry;
	
EndProcedure

Procedure FinishKeepExchangeProtocol()
	
	If DataProtocolFile <> Undefined Then
		
		DataProtocolFile.Close();
				
	EndIf;	
	
	DataProtocolFile = Undefined;
	
EndProcedure

Procedure SetExchangeResult(ExchangeExecutionResult)
	
	CurrentResultIndex = ExchangeResultPriorities().Find(ExchangeExecutionResult());
	NewResultIndex   = ExchangeResultPriorities().Find(ExchangeExecutionResult);
	
	If CurrentResultIndex = Undefined Then
		CurrentResultIndex = 100
	EndIf;
	
	If NewResultIndex = Undefined Then
		NewResultIndex = 100
	EndIf;
	
	If NewResultIndex < CurrentResultIndex Then
		
		ExchangeResultField = ExchangeExecutionResult;
		
	EndIf;
	
EndProcedure

Function ExchangeExecutionResultError(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
	
EndFunction

Function ExchangeExecutionResultWarning(ExchangeExecutionResult)
	
	Return ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
	
EndFunction

// Saves messages of the specified structure to the execution Protocol (or displays them on the screen).
//
// Parameters:
//  Code               - Number -  message code.
//  RecordStructure   - Structure -  structure of the Protocol record.
//  SetErrorFlag1 - если истина, то -  this is an error message. The Error Flag Is Cocked.
// 
Function WriteToExecutionProtocol(Code = "",
									RecordStructure=Undefined,
									SetErrorFlag1=True,
									Level=0,
									Align=22,
									UnconditionalWriteToExchangeProtocol = False,
									Val ExchangeExecutionResult = Undefined) Export
	//
	Indent = "";
	For Cnt = 0 To Level-1 Do
		Indent = Indent + Chars.Tab;
	EndDo; 
	
	If TypeOf(Code) = NumberType Then
		
		If ErrorsMessages = Undefined Then
			InitMessages();
		EndIf;
		
		Page1 = ErrorsMessages[Code];
		
	Else
		
		Page1 = String(Code);
		
	EndIf;

	Page1 = Indent + Page1;
	
	If RecordStructure <> Undefined Then
		
		For Each Field In RecordStructure Do
			
			Value = Field.Value;
			If Value = Undefined Then
				Continue;
			EndIf; 
			Var_Key = Field.Key;
			Page1  = Page1 + Chars.LF + Indent + Chars.Tab + odSupplementString(Var_Key, Align) + " =  " + String(Value);
			
		EndDo;
		
	EndIf;
	
	ErrorMessageStringField = Page1;
	
	If SetErrorFlag1 Then
		
		SetErrorFlag2();
		
		ExchangeExecutionResult = ?(ExchangeExecutionResult = Undefined,
										Enums.ExchangeExecutionResults.Error,
										ExchangeExecutionResult);
		//
	EndIf;
	
	SetExchangeResult(ExchangeExecutionResult);
	
	If DataProtocolFile <> Undefined Then
		
		If SetErrorFlag1 Then
			
			DataProtocolFile.WriteLine(Chars.LF + "Error.");
			
		EndIf;
		
		If SetErrorFlag1 Or UnconditionalWriteToExchangeProtocol Or OutputInfoMessagesToProtocol Then
			
			DataProtocolFile.WriteLine(Chars.LF + ErrorMessageString());
		
		EndIf;
		
	EndIf;
	
	If ExchangeExecutionResultError(ExchangeExecutionResult) Then
		
		ELLevel = EventLogLevel.Error;
		
	ElsIf ExchangeExecutionResultWarning(ExchangeExecutionResult) Then
		
		ELLevel = EventLogLevel.Warning;
		
	Else
		
		ELLevel = EventLogLevel.Information;
		
	EndIf;
	
	// 
	ErrorMessageString = ErrorMessageString();
	WriteEventLogDataExchange1(ErrorMessageString, ELLevel);
	
	WriteToDataExchangeResults = True;  
	If Common.DataSeparationEnabled() 
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations") Then
			
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");     
		WriteToDataExchangeResults = ModuleSaaSOperations.SessionSeparatorUsage();
		
	EndIf;
	
	If WriteToDataExchangeResults Then

		WriteParameters = New Structure("ObjectWithIssue, IssueType");
		WriteParameters.Insert("InfobaseNode", NodeForExchange);
		WriteParameters.Insert("Cause", ErrorMessageString);
		
		If ValueIsFilled(LinkToGoToOnError) Then
			
			WriteParameters.ObjectWithIssue = LinkToGoToOnError;
			
		EndIf;
		
		If ExchangeMode = "Upload0" Then
			
			WriteParameters.IssueType = Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData;
			
		ElsIf ExchangeMode = "Load" Then
			
			WriteParameters.IssueType = Enums.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData;
			
		EndIf;
		
		InformationRegisters.DataExchangeResults.AddAnEntryAboutTheResultsOfTheExchange(WriteParameters);
	
	EndIf;
	
	Return ErrorMessageString();
	
EndFunction

Function WriteErrorInfoToProtocol(ErrorMessageCode, ErrorString, Object, ObjectType = Undefined)
	
	WP         = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.Object  = Object;
	
	If ObjectType <> Undefined Then
		WP.ObjectType     = ObjectType;
	EndIf;	
		
	ErrorString = WriteToExecutionProtocol(ErrorMessageCode, WP);	
	
	Return ErrorString;
	
EndFunction

Procedure WriteDataClearingHandlerErrorInfo(ErrorMessageCode, ErrorString, DataClearingRuleName, Object = "", HandlerName = "")
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.DPR                    = DataClearingRuleName;
	
	If Object <> "" Then
		WP.Object                 = String(Object) + "  (" + TypeOf(Object) + ")";
	EndIf;
	
	If HandlerName <> "" Then
		WP.Handler             = HandlerName;
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

Procedure WriteInfoOnOCRHandlerImportError(ErrorMessageCode, ErrorString, RuleName, Source = "", 
	ObjectType, Object = Undefined, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.OCRName                 = RuleName;
	WP.ObjectType             = ObjectType;
	WP.Handler             = HandlerName;
						
	If Not IsBlankString(Source) Then
							
		WP.Source           = Source;
							
	EndIf;
						
	If Object <> Undefined Then
	
		WP.Object                 = String(Object);
		
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

Procedure WriteInfoOnOCRHandlerExportError(ErrorMessageCode, ErrorString, OCR, Source, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
	
	Try
		WP.Object                 = String(Source) + "  (" + TypeOf(Source) + ")";
	Except
		WP.Object                 = "(" + TypeOf(Source) + ")";
	EndTry;
	
	WP.Handler             = HandlerName;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure

Procedure WriteErrorInfoPCRHandlers(ErrorMessageCode, ErrorString, OCR, PCR, Source = "", 
	HandlerName = "", Value = Undefined)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
	WP.PCR                    = PCR.Name + "  (" + PCR.Description + ")";
	
	Try
		WP.Object                 = String(Source) + "  (" + TypeOf(Source) + ")";
	Except
		WP.Object                 = "(" + TypeOf(Source) + ")";
	EndTry;
	
	WP.DestinationProperty      = PCR.Receiver + "  (" + PCR.DestinationType + ")";
	
	If HandlerName <> "" Then
		WP.Handler         = HandlerName;
	EndIf;
	
	If Value <> Undefined Then
		WP.ConvertedValue = String(Value) + "  (" + TypeOf(Value) + ")";
	EndIf;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
		
EndProcedure	

Procedure WriteErrorInfoDERHandlers(ErrorMessageCode, ErrorString, RuleName, HandlerName, Object = Undefined)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.DER                    = RuleName;
	
	If Object <> Undefined Then
		WP.Object                 = String(Object) + "  (" + TypeOf(Object) + ")";
	EndIf;
	
	WP.Handler             = HandlerName;
	
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	
	If Not ContinueOnError Then
		Raise ErrorMessageString;
	EndIf;
	
EndProcedure

Function WriteErrorInfoConversionHandlers(ErrorMessageCode, ErrorString, HandlerName)
	
	WP                        = ExchangeProtocolRecord(ErrorMessageCode, ErrorString);
	WP.Handler             = HandlerName;
	ErrorMessageString = WriteToExecutionProtocol(ErrorMessageCode, WP);
	Return ErrorMessageString;
	
EndFunction

#EndRegion

#Region CollectionsTypesDetails

// Returns:
//   ValueTable - :
//     * Name - String
//     * Description - String
//     * Order - Number
//     * SynchronizeByID - Boolean
//     * DontCreateIfNotFound - Boolean
//     * DontExportPropertyObjectsByRefs - Boolean
//     * SearchBySearchFieldsIfNotFoundByID - Boolean
//     * OnExchangeObjectByRefSetGIUDOnly - Boolean
//     * DontReplaceObjectCreatedInDestinationInfobase - Boolean
//     * UseQuickSearchOnImport - Boolean
//     * GenerateNewNumberOrCodeIfNotSet - Boolean
//     * TinyObjectCount - Boolean
//     * RefExportReferenceCount - Number
//     * IBItemsCount - Number
//     * ExportMethod - Arbitrary
//     * Source - Arbitrary
//     * Receiver - Arbitrary
//     * SourceType - String
//     * DestinationType - String
//     * BeforeExport - Arbitrary
//     * BeforeExportHandlerName - String
//     * OnExport - Arbitrary
//     * OnExportHandlerName - String
//     * AfterExport - Arbitrary
//     * AfterExportHandlerName - String
//     * AfterExportToFile - Arbitrary
//     * AfterExportToFileHandlerName - String
//     * HasBeforeExportHandler - Boolean
//     * HasOnExportHandler - Boolean
//     * HasAfterExportHandler - Boolean
//     * HasAfterExportToFileHandler - Boolean
//     * BeforeImport - Arbitrary
//     * BeforeImportHandlerName - String
//     * OnImport - Arbitrary
//     * OnImportHandlerName - String
//     * AfterImport - Arbitrary
//     * AfterImportHandlerName - String
//     * SearchFieldSequence - Arbitrary
//     * SearchFieldSequenceHandlerName - String
//     * SearchInTabularSections - See SearchTabularSectionsCollection
//     * ExchangeObjectsPriority - Arbitrary
//     * HasBeforeImportHandler - Boolean
//     * HasOnImportHandler - Boolean
//     * HasAfterImportHandler - Boolean
//     * HasSearchFieldSequenceHandler - Boolean
//     * Properties - See PropertiesConversionRulesCollection
//     * SearchProperties - See PropertiesConversionRulesCollection
//     * DisabledProperties - See PropertiesConversionRulesCollection
//     * PredefinedDataValues - Map
//     * PredefinedDataReadValues - Structure
//     * Exported_ - ValueTable
//     * ExportSourcePresentation - Boolean
//     * NotReplace - Boolean
//     * RememberExportedData - Boolean
//     * AllObjectsExported - Boolean
//     * SearchFields - String
//     * TableFields - String
// 
Function ConversionRulesCollection()
	
	Return ConversionRulesTable;
	
EndFunction

// Returns:
//   ValueTable - :
//     * TagName - Arbitrary
//     * KeySearchFieldArray - Array of Arbitrary
//     * KeySearchFields - Arbitrary
//     * Valid - Boolean
// 
Function SearchTabularSectionsCollection()
	
	SearchInTabularSections = New ValueTable;
	SearchInTabularSections.Columns.Add("TagName");
	SearchInTabularSections.Columns.Add("KeySearchFieldArray");
	SearchInTabularSections.Columns.Add("KeySearchFields");
	SearchInTabularSections.Columns.Add("Valid", deTypeDetails("Boolean"));
	
	Return SearchInTabularSections;
	
EndFunction

// Returns:
//   ValueTable - :
//     * Name - String
//     * Description - String
//     * Order - Number
//     * IsFolder - Boolean
//     * IsSearchField - Boolean
//     * GroupRules - See PropertiesConversionRulesCollection
//     * DisabledGroupRules - Arbitrary
//     * SourceKind - Arbitrary
//     * DestinationKind - Arbitrary
//     * SimplifiedPropertyExport - Boolean
//     * XMLNodeRequiredOnExport - Boolean
//     * XMLNodeRequiredOnExportGroup - Boolean
//     * SourceType - String
//     * DestinationType - String
//     * Source - Arbitrary
//     * Receiver - Arbitrary
//     * ConversionRule - Arbitrary
//     * GetFromIncomingData - Boolean
//     * NotReplace - Boolean
//     * IsRequiredProperty - Boolean
//     * BeforeExport - Arbitrary
//     * BeforeExportHandlerName - Arbitrary
//     * OnExport - Arbitrary
//     * OnExportHandlerName - Arbitrary
//     * AfterExport - Arbitrary
//     * AfterExportHandlerName - Arbitrary
//     * BeforeProcessExport - Arbitrary
//     * BeforeExportProcessHandlerName - Arbitrary
//     * AfterProcessExport - Arbitrary
//     * AfterExportProcessHandlerName - Arbitrary
//     * HasBeforeExportHandler - Boolean
//     * HasOnExportHandler - Boolean
//     * HasAfterExportHandler - Boolean
//     * HasBeforeProcessExportHandler - Boolean
//     * HasAfterProcessExportHandler - Boolean
//     * CastToLength - Number
//     * ParameterForTransferName - String
//     * SearchByEqualDate - Boolean
//     * ExportGroupToFile - Boolean
//     * SearchFieldsString - Arbitrary
// 
Function PropertiesConversionRulesCollection()
	
	Return PropertyConversionRuleTable;
	
EndFunction

// Returns:
//   ValueTable - :
//     * Enable - Boolean
//     * Name - Arbitrary
//     * Description - Arbitrary
//     * Order - Arbitrary
//     * DataFilterMethod - Arbitrary
//     * SelectionObject1 - Arbitrary
//     * SelectionObjectMetadata - Arbitrary
//     * ConversionRule - Arbitrary
//     * BeforeProcess - Arbitrary
//     * BeforeProcessHandlerName - Arbitrary
//     * AfterProcess - Arbitrary
//     * AfterProcessHandlerName - Arbitrary
//     * BeforeExport - Arbitrary
//     * BeforeExportHandlerName - Arbitrary
//     * AfterExport - Arbitrary
//     * AfterExportHandlerName - Arbitrary
//     * UseFilter1 - Boolean
//     * BuilderSettings - Arbitrary
//     * ObjectForQueryName - Arbitrary
//     * ObjectNameForRegisterQuery - Arbitrary
//     * DestinationTypeName - Arbitrary
//     * DoNotExportObjectsCreatedInDestinationInfobase - Boolean
//     * ExchangeNodeRef - Arbitrary
//     * SynchronizeByID - Boolean
// 
Function DataExportRulesCollection()
	
	Return ExportRulesTable;

EndFunction

// Returns:
//   ValueTree - :
//     * Enable -  Boolean
//     * IsFolder - Boolean
//     * Name - String
//     * Description - String
//     * Order - Number
//     * DataFilterMethod - Arbitrary
//     * SelectionObject1 - Arbitrary
//     * DeleteForPeriod - Arbitrary
//     * Directly - Boolean
//     * BeforeProcess - Arbitrary
//     * BeforeProcessHandlerName - Arbitrary
//     * AfterProcess - Arbitrary
//     * AfterProcessHandlerName - Arbitrary
//     * BeforeDeleteRow - Arbitrary
//     * BeforeDeleteHandlerName - Arbitrary
// 
Function DataClearingRulesCollection()

	Return CleanupRulesTable;

EndFunction

// Returns:
//   ValueTable:
//     * Ref - AnyRef -  reference to the object being uploaded.
//
Function DataExportCallStackCollection()
	
	Return DataExportCallStack;
	
EndFunction

#EndRegion

#Region ExchangeRulesImportProcedures

// Performs the download of the conversion rule group properties.
//
// Parameters:
//   ExchangeRules  - XMLReader -  an object of the ReadXml type.
//   PropertiesTable - See PropertiesConversionRulesCollection
//   DisabledProperties - See PropertiesConversionRulesCollection
//   SynchronizeByID - Boolean -  True if syncing is performed by ID.
//   OCRName - String -  name of the conversion rule.
//
Procedure ImportPGCR(ExchangeRules, PropertiesTable, DisabledProperties, SynchronizeByID, OCRName = "")
	
	IsDisabledField = deAttribute(ExchangeRules, BooleanType, "Disconnect");
	
	If IsDisabledField Then
		
		NewRow = DisabledProperties.Add();
		
	Else
		
		NewRow = PropertiesTable.Add();
		
	EndIf;
	
	NewRow.IsFolder     = True;
	
	NewRow.GroupRules            = PropertyConversionRuleTable.Copy();
	NewRow.DisabledGroupRules = PropertyConversionRuleTable.Copy();
	
	// 
	NewRow.NotReplace               = False;
	NewRow.GetFromIncomingData = False;
	NewRow.SimplifiedPropertyExport = False;
	
	SearchFieldsString = "";
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Receiver" Then
			NewRow.Receiver		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Property" Then
			
			PCRParent = ?(ValueIsFilled(NewRow.Source), "_" + NewRow.Source, "_" + NewRow.Receiver);
			
			OCRProperties = New Structure;
			OCRProperties.Insert("OCRName", OCRName);
			OCRProperties.Insert("ParentName", PCRParent);
			OCRProperties.Insert("SynchronizeByID", SynchronizeByID);
			
			ImportPCR(ExchangeRules, NewRow.GroupRules, NewRow.DisabledGroupRules, OCRProperties, SearchFieldsString);

		ElsIf NodeName = "BeforeProcessExport" Then
			NewRow.BeforeProcessExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeProcessExportHandler = Not IsBlankString(NewRow.BeforeProcessExport);
			
		ElsIf NodeName = "AfterProcessExport" Then
			NewRow.AfterProcessExport	= deElementValue(ExchangeRules, StringType);
			NewRow.HasAfterProcessExportHandler = Not IsBlankString(NewRow.AfterProcessExport);
			
		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "NotReplace" Then
			NewRow.NotReplace = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "ExportGroupToFile" Then
			NewRow.ExportGroupToFile = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf (NodeName = "Group") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If NewRow.HasBeforeProcessExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_BeforeProcessExport_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.BeforeExportProcessHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasAfterProcessExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_AfterProcessExport_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.AfterExportProcessHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasBeforeExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_BeforeExportProperty_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.BeforeExportHandlerName = HandlerName;

	EndIf;
	
	If NewRow.HasOnExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_OnExportProperty_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.OnExportHandlerName = HandlerName;

	EndIf;
	
	If NewRow.HasAfterExportHandler Then
		
		HandlerName = "PGCR_[OCRName][PCRPropertyName]_AfterExportProperty_[PGCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PGCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		NewRow.AfterExportHandlerName = HandlerName;
		
	EndIf;
	
	NewRow.SearchFieldsString = SearchFieldsString;
	
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler Or NewRow.HasAfterExportHandler;
	
	NewRow.XMLNodeRequiredOnExportGroup = NewRow.HasAfterProcessExportHandler; 

EndProcedure

Procedure AddFieldToSearchString(SearchFieldsString, FieldName)
	
	If IsBlankString(FieldName) Then
		Return;
	EndIf;
	
	If Not IsBlankString(SearchFieldsString) Then
		SearchFieldsString = SearchFieldsString + ",";
	EndIf;
	
	SearchFieldsString = SearchFieldsString + FieldName;
	
EndProcedure

// Performs the download of the conversion rules properties.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object containing the text of the exchange rules.
//  PropertiesTable - See PropertiesConversionRulesCollection
//  DisabledProperties - See PropertiesConversionRulesCollection
//  OCRProperties - Structure - :
//    * OCRName - String -  name of the PKO.
//    * SynchronizeByID - Boolean -  the criterion of using the search algorithm according to a unique identifier.
//    * ParentName - String -  name of the parent PCO or PCGS.
//  SearchFieldsString - String -  PKO search properties.
//  SearchTable - See PropertiesConversionRulesCollection
//
Procedure ImportPCR(ExchangeRules,
	PropertiesTable,
	DisabledProperties,
	OCRProperties,
	SearchFieldsString = "",
	SearchTable = Undefined)
	
	OCRName = ?(ValueIsFilled(OCRProperties.OCRName), OCRProperties.OCRName, "");
	ParentName = ?(ValueIsFilled(OCRProperties.ParentName), OCRProperties.ParentName, "");
	SynchronizeByID = ?(ValueIsFilled(OCRProperties.SynchronizeByID),
		OCRProperties.SynchronizeByID, False);
	
	IsDisabledField        = deAttribute(ExchangeRules, BooleanType, "Disconnect");
	IsSearchField           = deAttribute(ExchangeRules, BooleanType, "Search");
	IsRequiredProperty = deAttribute(ExchangeRules, BooleanType, "Required");
	
	If IsDisabledField Then
		
		NewRow = DisabledProperties.Add();
		
	ElsIf IsRequiredProperty And SearchTable <> Undefined Then
		
		NewRow = SearchTable.Add();
		
	ElsIf IsSearchField And SearchTable <> Undefined Then
		
		NewRow = SearchTable.Add();
		
	Else
		
		NewRow = PropertiesTable.Add();
		
	EndIf;
	
	// 
	NewRow.NotReplace               = False;
	NewRow.GetFromIncomingData = False;
	NewRow.IsRequiredProperty  = IsRequiredProperty;
	NewRow.IsSearchField            = IsSearchField;
		
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Source" Then
			NewRow.Source		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.SourceKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.SourceType	= deAttribute(ExchangeRules, StringType, "Type");
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Receiver" Then
			NewRow.Receiver		= deAttribute(ExchangeRules, StringType, "Name");
			NewRow.DestinationKind	= deAttribute(ExchangeRules, StringType, "Kind");
			NewRow.DestinationType	= deAttribute(ExchangeRules, StringType, "Type");
			
			If Not IsDisabledField Then
				
				// 
				AddFieldToSearchString(SearchFieldsString, NewRow.Receiver);
				
			EndIf;
			
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "NotReplace" Then
			NewRow.NotReplace = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "ConversionRuleCode" Then
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "BeforeExport" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
	        NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "GetFromIncomingData" Then
			NewRow.GetFromIncomingData = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "CastToLength" Then
			NewRow.CastToLength = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "ParameterForTransferName" Then
			NewRow.ParameterForTransferName = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SearchByEqualDate" Then
			NewRow.SearchByEqualDate = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf (NodeName = "Property") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If NewRow.HasBeforeExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_BeforeExportProperty_[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		
		NewRow.BeforeExportHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasOnExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_OnExportProperty_[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));
		
		NewRow.OnExportHandlerName = HandlerName;
		
	EndIf;
	
	If NewRow.HasAfterExportHandler Then
		
		HandlerName = "PCR_[OCRName][ParentName][PCRPropertyName]_AfterExportProperty_[PCRName]_[OCRNameLength]";
		HandlerName = StrReplace(HandlerName, "[OCRName]", OCRName);
		HandlerName = StrReplace(HandlerName, "[ParentName]", ParentName);
		HandlerName = StrReplace(HandlerName, "[PCRPropertyName]", PCRPropertyName(NewRow));
		HandlerName = StrReplace(HandlerName, "[PCRName]", NewRow.Name);
		HandlerName = StrReplace(HandlerName, "[OCRNameLength]", StrLen(OCRName));

		NewRow.AfterExportHandlerName = HandlerName;
		
	EndIf;
	
	NewRow.SimplifiedPropertyExport = Not NewRow.GetFromIncomingData
		And Not NewRow.HasBeforeExportHandler
		And Not NewRow.HasOnExportHandler
		And Not NewRow.HasAfterExportHandler
		And IsBlankString(NewRow.ConversionRule)
		And NewRow.SourceType = NewRow.DestinationType
		And (NewRow.SourceType = "String" Or NewRow.SourceType = "Number" Or NewRow.SourceType = "Boolean" Or NewRow.SourceType = "Date");
		
	NewRow.XMLNodeRequiredOnExport = NewRow.HasOnExportHandler Or NewRow.HasAfterExportHandler;
	
EndProcedure

// 
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  PropertiesTable - ValueTable -  a table of values containing PKS.
//  SearchTable  - ValueTable -  table of values containing PKS (synchronizing).
//
Procedure ImportProperties(ExchangeRules,
							PropertiesTable,
							SearchTable,
							DisabledProperties,
							Val SynchronizeByID = False,
							OCRName = "")
	//
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Property" Then
			
			OCRProperties = New Structure;
			OCRProperties.Insert("OCRName", OCRName);
			OCRProperties.Insert("ParentName", "");
			OCRProperties.Insert("SynchronizeByID", SynchronizeByID);
			ImportPCR(ExchangeRules, PropertiesTable, DisabledProperties, OCRProperties,, SearchTable);
			
		ElsIf NodeName = "Group" Then
			
			ImportPGCR(ExchangeRules, PropertiesTable, DisabledProperties, SynchronizeByID, OCRName);
			
		ElsIf (NodeName = "Properties") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	PropertiesTable.Sort("Order");
	SearchTable.Sort("Order");
	DisabledProperties.Sort("Order");
	
EndProcedure

// Performs the download of the conversion rule values.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  Values       - соответствие значений объекта источника -  string
//                   representations of the receiver object.
//  SourceType   - значение Тип -  type - type of the source object.
//
Procedure ImportVCR(ExchangeRules, Values, SourceType)
	
	Source = "";
	Receiver = "";
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Source" Then
			Source = deElementValue(ExchangeRules, StringType);
		ElsIf NodeName = "Receiver" Then
			Receiver = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Value") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
	If Not IsBlankString(Source) Then
		Values.Insert(Source, Receiver);
	EndIf;
	
EndProcedure

// Re-download rules of conversion values.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  Values       - соответствие значений объекта источника -  string
//                   representations of the receiver object.
//  SourceType   - значение Тип -  type - type of the source object.
//
Procedure LoadValues(ExchangeRules, Values, SourceType)

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Value" Then
			ImportVCR(ExchangeRules, Values, SourceType);
		ElsIf (NodeName = "Values") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Performs the download of the conversion rule objects.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportConversionRule(ExchangeRules, XMLWriter)

	XMLWriter.WriteStartElement("Rule");

	NewRow = ConversionRulesCollection().Add();
	
	// 
	
	NewRow.RememberExportedData = True;
	NewRow.NotReplace            = False;
	NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	
	NewRow.SearchInTabularSections = SearchTabularSectionsCollection();
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
				
		If      NodeName = "Code" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.Name = Value;
			
		ElsIf NodeName = "Description" Then
			
			NewRow.Description = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SynchronizeByID" Then
			
			NewRow.SynchronizeByID = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.SynchronizeByID);
			
		ElsIf NodeName = "DontCreateIfNotFound" Then
			
			NewRow.DontCreateIfNotFound = deElementValue(ExchangeRules, BooleanType);			
			
		ElsIf NodeName = "RecordObjectChangeAtSenderNode" Then // 
			
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "DontExportPropertyObjectsByRefs" Then
			
			NewRow.DontExportPropertyObjectsByRefs = deElementValue(ExchangeRules, BooleanType);
						
		ElsIf NodeName = "SearchBySearchFieldsIfNotFoundByID" Then
			
			NewRow.SearchBySearchFieldsIfNotFoundByID = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.SearchBySearchFieldsIfNotFoundByID);
			
		ElsIf NodeName = "OnExchangeObjectByRefSetGIUDOnly" Then
			
			NewRow.OnExchangeObjectByRefSetGIUDOnly = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.OnExchangeObjectByRefSetGIUDOnly);
			
		ElsIf NodeName = "DontReplaceObjectCreatedInDestinationInfobase" Then
			
			NewRow.DontReplaceObjectCreatedInDestinationInfobase = deElementValue(ExchangeRules, BooleanType);	
			deWriteElement(XMLWriter, NodeName, NewRow.DontReplaceObjectCreatedInDestinationInfobase);		
			
		ElsIf NodeName = "UseQuickSearchOnImport" Then
			
			NewRow.UseQuickSearchOnImport = deElementValue(ExchangeRules, BooleanType);	
			
		ElsIf NodeName = "GenerateNewNumberOrCodeIfNotSet" Then
			
			NewRow.GenerateNewNumberOrCodeIfNotSet = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, NewRow.GenerateNewNumberOrCodeIfNotSet);
						
		ElsIf NodeName = "NotRememberExportedData" Then
			
			NewRow.RememberExportedData = Not deElementValue(ExchangeRules, BooleanType);
			
		ElsIf NodeName = "NotReplace" Then
			
			Value = deElementValue(ExchangeRules, BooleanType);
			deWriteElement(XMLWriter, NodeName, Value);
			NewRow.NotReplace = Value;
			
		ElsIf NodeName = "Receiver" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			
			NewRow.Receiver     = Value;
			NewRow.DestinationType = Value;
			
		ElsIf NodeName = "Source" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			deWriteElement(XMLWriter, NodeName, Value);
			
			NewRow.SourceType = Value;
			
			If ExchangeMode = "Load" Then
				
				NewRow.Source = Value;
				
			Else
				
				If Not IsBlankString(Value) Then
					
					If Not ExchangeRuleInfoImportMode Then
						
						Try
							
							NewRow.Source = Type(Value);
							
							Managers[NewRow.Source].OCR = NewRow;
							
						Except
							
							WriteErrorInfoToProtocol(11, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
								String(NewRow.Source));
							
						EndTry;
					
					EndIf;
					
				EndIf;
				
			EndIf;
			
		// Properties
		
		ElsIf NodeName = "Properties" Then
		
			NewRow.Properties            = PropertiesConversionRulesCollection().Copy();
			NewRow.SearchProperties      = PropertiesConversionRulesCollection().Copy();
			NewRow.DisabledProperties = PropertiesConversionRulesCollection().Copy();
			
			If NewRow.SynchronizeByID = True Then
				
				SearchPropertyUUID = NewRow.SearchProperties.Add();
				SearchPropertyUUID.Name      = "{UUID}";
				SearchPropertyUUID.Source = "{UUID}";
				SearchPropertyUUID.Receiver = "{UUID}";
				SearchPropertyUUID.IsRequiredProperty = True;
				
			EndIf;
			
			ImportProperties(ExchangeRules, NewRow.Properties, NewRow.SearchProperties, NewRow.DisabledProperties, NewRow.SynchronizeByID, NewRow.Name);
			
		// Values
		ElsIf NodeName = "Values" Then
			
			LoadValues(ExchangeRules, NewRow.PredefinedDataReadValues, NewRow.Source);
			
		// 
		ElsIf NodeName = "BeforeExport" Then
		
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_BeforeExportObject";
			NewRow.BeforeExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasBeforeExportHandler = Not IsBlankString(NewRow.BeforeExport);
			
		ElsIf NodeName = "OnExport" Then
			
			NewRow.OnExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_OnExportObject";
			NewRow.OnExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasOnExportHandler    = Not IsBlankString(NewRow.OnExport);
			
		ElsIf NodeName = "AfterExport" Then
			
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_AfterExportObject";
			NewRow.AfterExportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasAfterExportHandler  = Not IsBlankString(NewRow.AfterExport);
			
		ElsIf NodeName = "AfterExportToFile" Then
			
			NewRow.AfterExportToFile = deElementValue(ExchangeRules, StringType);
			HandlerName = "OCR_[OCRName]_ПослеВыгрузкиОбъектаВФайлОбмена";
			NewRow.AfterExportToFileHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
			NewRow.HasAfterExportToFileHandler  = Not IsBlankString(NewRow.AfterExportToFile);
			
		// 
		
		ElsIf NodeName = "BeforeImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.BeforeImport               = Value;
				HandlerName = "OCR_[OCRName]_BeforeImportObject";
				NewRow.BeforeImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasBeforeImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "OnImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.OnImport               = Value;
				HandlerName = "OCR_[OCRName]_OnImportObject";
				NewRow.OnImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasOnImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf; 
			
		ElsIf NodeName = "AfterImport" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If ExchangeMode = "Load" Then
				
				NewRow.AfterImport               = Value;
				HandlerName = "OCR_[OCRName]_AfterImportObject";
				NewRow.AfterImportHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				NewRow.HasAfterImportHandler = Not IsBlankString(Value);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "SearchFieldSequence" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			NewRow.HasSearchFieldSequenceHandler = Not IsBlankString(Value);
			
			If ExchangeMode = "Load" Then
				
				NewRow.SearchFieldSequence = Value;
				HandlerName = "OCR_[OCRName]_SearchFieldSequence";
				NewRow.SearchFieldSequenceHandlerName = StrReplace(HandlerName, "[OCRName]", NewRow.Name);
				
			Else
				
				deWriteElement(XMLWriter, NodeName, Value);
				
			EndIf;
			
		ElsIf NodeName = "ExchangeObjectsPriority" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			
			If Value = "Below" Then
				NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority;
			ElsIf Value = "Matches" Then
				NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch;
			EndIf;
			
		// 
		ElsIf NodeName = "ObjectSearchOptionsSettings" Then
		
			ImportSearchVariantSettings(ExchangeRules, NewRow);
			
		ElsIf NodeName = "SearchInTabularSections" Then
			
			// 
			Value = deElementValue(ExchangeRules, StringType);
			
			For Number = 1 To StrLineCount(Value) Do
				
				CurrentRow = StrGetLine(Value, Number);
				
				SearchString = SplitWithSeparator(CurrentRow, ":");
				
				TableRow = NewRow.SearchInTabularSections.Add();
				
				TableRow.TagName               = CurrentRow;
				TableRow.KeySearchFields        = SearchString;
				TableRow.KeySearchFieldArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(SearchString);
				TableRow.Valid                  = TableRow.KeySearchFieldArray.Count() <> 0;
				
			EndDo;
			
		ElsIf NodeName = "SearchFields" Then
			
			NewRow.SearchFields = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "TableFields" Then
			
			NewRow.TableFields = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "AnObjectWithRegisteredRecords" Then
			
			NewRow.AnObjectWithRegisteredRecords = deElementValue(ExchangeRules, BooleanType);
			
		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
		
			Break;
			
		EndIf;
		
	EndDo;
	
	If ExchangeMode <> "Load" Then
		
		// 
		
		ResultingTSSearchString = "";
		
		// 
		For Each PropertyString In NewRow.Properties Do
			
			If Not PropertyString.IsFolder
				Or IsBlankString(PropertyString.DestinationKind)
				Or IsBlankString(PropertyString.Receiver) Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(PropertyString.SearchFieldsString) Then
				Continue;
			EndIf;
			
			ResultingTSSearchString = ResultingTSSearchString + Chars.LF + PropertyString.DestinationKind + "." + PropertyString.Receiver + ":" + PropertyString.SearchFieldsString;
			
		EndDo;
		
		ResultingTSSearchString = TrimAll(ResultingTSSearchString);
		
		If Not IsBlankString(ResultingTSSearchString) Then
			
			deWriteElement(XMLWriter, "SearchInTabularSections", ResultingTSSearchString);
			
		EndIf;
		
	EndIf;
	
	TableFields = "";
	SearchFields = "";
	If NewRow.Properties.Count() > 0
		Or NewRow.SearchProperties.Count() > 0 Then
		
		ArrayProperties = NewRow.Properties.Copy(New Structure("IsFolder, ParameterForTransferName", False, ""), "Receiver").UnloadColumn("Receiver");
		
		ArraySearchProperties               = NewRow.SearchProperties.Copy(New Structure("IsFolder, ParameterForTransferName", False, ""), "Receiver").UnloadColumn("Receiver");
		SearchPropertyAdditionalArray = NewRow.Properties.Copy(New Structure("IsSearchField, ParameterForTransferName", True, ""), "Receiver").UnloadColumn("Receiver");
		
		For Each Value In SearchPropertyAdditionalArray Do
			
			ArraySearchProperties.Add(Value);
			
		EndDo;
		
		// 
		CommonClientServer.DeleteValueFromArray(ArraySearchProperties, "{UUID}");
		
		// 
		TableFieldsTable = New ValueTable;
		TableFieldsTable.Columns.Add("Receiver");
		
		CommonClientServer.SupplementTableFromArray(TableFieldsTable, ArrayProperties, "Receiver");
		CommonClientServer.SupplementTableFromArray(TableFieldsTable, ArraySearchProperties, "Receiver");
		
		TableFieldsTable.GroupBy("Receiver");
		ArrayProperties = TableFieldsTable.UnloadColumn("Receiver");
		
		TableFields = StrConcat(ArrayProperties, ",");
		SearchFields  = StrConcat(ArraySearchProperties, ",");
		
	EndIf;
	
	If ExchangeMode = "Load" Then
		
		// 
		If Not ValueIsFilled(NewRow.TableFields) Then
			NewRow.TableFields = TableFields;
		EndIf;
		
		If Not ValueIsFilled(NewRow.SearchFields) Then
			NewRow.SearchFields = SearchFields;
		EndIf;
		
	Else
		
		If Not IsBlankString(TableFields) Then
			deWriteElement(XMLWriter, "TableFields", TableFields);
		EndIf;
		
		If Not IsBlankString(SearchFields) Then
			deWriteElement(XMLWriter, "SearchFields", SearchFields);
		EndIf;
		
	EndIf;
	
	// 
	XMLWriter.WriteEndElement(); // Rule
	
	// 
	Rules.Insert(NewRow.Name, NewRow);
	
EndProcedure

Procedure ImportSearchVariantSetting(ExchangeRules, NewRow)
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If NodeName = "AlgorithmSettingName" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.AlgorithmSettingName = Value;
			EndIf;
			
		ElsIf NodeName = "UserSettingsName" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.UserSettingsName = Value;
			EndIf;
			
		ElsIf NodeName = "SettingDetailsForUser" Then
			
			Value = deElementValue(ExchangeRules, StringType);
			If ExchangeRuleInfoImportMode Then
				NewRow.SettingDetailsForUser = Value;
			EndIf;
			
		ElsIf (NodeName = "SearchMode") And (NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
		EndIf;
		
	EndDo;	
	
EndProcedure

// Returns:
//   ValueTable:
//     * ExchangeRuleCode - String
//     * ExchangeRuleDescription - String
//
Function SearchFieldsInfoImportResults()
	Return SearchFieldInfoImportResultTable;
EndFunction

Procedure ImportSearchVariantSettings(ExchangeRules, BaseOCRRow)

	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If NodeName = "SearchMode" Then
			
			If ExchangeRuleInfoImportMode Then
				SettingString = SearchFieldsInfoImportResults().Add();
				SettingString.ExchangeRuleCode = BaseOCRRow.Name;
				SettingString.ExchangeRuleDescription = BaseOCRRow.Description;
			Else
				SettingString = Undefined;
			EndIf;
			
			ImportSearchVariantSetting(ExchangeRules, SettingString);
			
		ElsIf (NodeName = "ObjectSearchOptionsSettings") And (NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Re-download rules of conversion facilities.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportConversionRules(ExchangeRules, XMLWriter)
	
	ConversionRulesTable.Clear();
	
	XMLWriter.WriteStartElement("ObjectsConversionRules");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Rule" Then
			
			ImportConversionRule(ExchangeRules, XMLWriter);
			
		ElsIf (NodeName = "ObjectsConversionRules") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	ImportConversionRuleExchangeObjectsExportModes(XMLWriter);
	
	XMLWriter.WriteEndElement();
	
	ConversionRulesTable.Indexes.Add("Receiver");
	
EndProcedure

// Loads a group of data clearing rules according to the format of the exchange rules.
//
// Parameters:
//  NewRow    - 
// 
Procedure ImportDPRGroup(ExchangeRules, NewRow)

	NewRow.IsFolder = True;
	NewRow.Enable  = Number(Not deAttribute(ExchangeRules, BooleanType, "Disconnect"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;
		
		If      NodeName = "Code" Then
			NewRow.Name = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "Rule" Then
			VTRow = NewRow.Rows.Add();
			ImportDPR(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeTypeStartElement) Then
			VTRow = NewRow.Rows.Add();
			ImportDPRGroup(ExchangeRules, VTRow);
			
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Loads the data clearing rule according to the format of the exchange rules.
//
// Parameters:
//  NewRow    - 
// 
Procedure ImportDPR(ExchangeRules, NewRow)
	
	NewRow.Enable = Number(Not deAttribute(ExchangeRules, BooleanType, "Disconnect"));
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Code" Then
			Value = deElementValue(ExchangeRules, StringType);
			NewRow.Name = Value;

		ElsIf NodeName = "Description" Then
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "SelectionObject1" Then
			
			If Not ExchangeRuleInfoImportMode Then
			
				SelectionObject1 = deElementValue(ExchangeRules, StringType);
				If Not IsBlankString(SelectionObject1) Then
					NewRow.SelectionObject1 = Type(SelectionObject1);
				EndIf;
				
			EndIf;

		ElsIf NodeName = "DeleteForPeriod" Then
			NewRow.DeleteForPeriod = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Directly" Then
			NewRow.Directly = deElementValue(ExchangeRules, BooleanType);

		
		// 

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_BeforeProcessRule";
			NewRow.BeforeProcessHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_AfterProcessRule";
			NewRow.AfterProcessHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		ElsIf NodeName = "BeforeDeleteObject" Then
			NewRow.BeforeDeleteRow = deElementValue(ExchangeRules, StringType);
			HandlerName = "DPR_[DPRName]_BeforeDeleteObject";
			NewRow.BeforeDeleteHandlerName = StrReplace(HandlerName, "[DPRName]", NewRow.Name);
			
		// 
		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
			
		EndIf;
		
	EndDo;

	
	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf; 
	
EndProcedure

// Re-download the purge rules data.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportClearingRules(ExchangeRules, XMLWriter)

	DataClearingRulesCollection().Rows.Clear();
	VTRows = DataClearingRulesCollection().Rows;
	
	XMLWriter.WriteStartElement("DataClearingRules");

	While ExchangeRules.Read() Do
		
		NodeType = ExchangeRules.NodeType;
		
		If NodeType = XMLNodeTypeStartElement Then
			NodeName = ExchangeRules.LocalName;
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteStartElement(ExchangeRules.Name);
				While ExchangeRules.ReadAttribute() Do
					XMLWriter.WriteAttribute(ExchangeRules.Name, ExchangeRules.Value);
				EndDo;
			Else
				If NodeName = "Rule" Then
					VTRow = VTRows.Add();
					ImportDPR(ExchangeRules, VTRow);
				ElsIf NodeName = "Group" Then
					VTRow = VTRows.Add();
					ImportDPRGroup(ExchangeRules, VTRow);
				EndIf;
			EndIf;
		ElsIf NodeType = XMLNodeTypeEndElement Then
			NodeName = ExchangeRules.LocalName;
			If NodeName = "DataClearingRules" Then
				Break;
			Else
				If ExchangeMode <> "Load" Then
					XMLWriter.WriteEndElement();
				EndIf;
			EndIf;
		ElsIf NodeType = XMLNodeTypeText Then
			If ExchangeMode <> "Load" Then
				XMLWriter.WriteText(ExchangeRules.Value);
			EndIf;
		EndIf; 
	EndDo;

	VTRows.Sort("Order", True);
	
	XMLWriter.WriteEndElement();
	
EndProcedure

// Loads the algorithm in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportAlgorithm(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Text" Then
			Text = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Algorithm") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;

	
	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Algorithms.Insert(Name, Text);
		Else
			XMLWriter.WriteStartElement("Algorithm");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Algorithms.Insert(Name, Text);
		EndIf;
	EndIf;
	
	
EndProcedure

// Loads algorithms according to the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportAlgorithms(ExchangeRules, XMLWriter)

	Algorithms.Clear();

	XMLWriter.WriteStartElement("Algorithms");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		If      NodeName = "Algorithm" Then
			ImportAlgorithm(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Algorithms") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Loads the request in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportQuery(ExchangeRules, XMLWriter)

	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Text" Then
			Text = deElementValue(ExchangeRules, StringType);
		ElsIf (NodeName = "Query") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			deSkip(ExchangeRules);
		EndIf;
		
	EndDo;

	If UsedOnImport Then
		If ExchangeMode = "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		Else
			XMLWriter.WriteStartElement("Query");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",   Name);
			deWriteElement(XMLWriter, "Text", Text);
			XMLWriter.WriteEndElement();
		EndIf;
	Else
		If ExchangeMode <> "Load" Then
			Query	= New Query(Text);
			Queries.Insert(Name, Query);
		EndIf;
	EndIf;
	
EndProcedure

// Loads requests in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportQueries(ExchangeRules, XMLWriter)

	Queries.Clear();

	XMLWriter.WriteStartElement("Queries");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "Query" Then
			ImportQuery(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "Queries") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Loads parameters according to the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//
Procedure DoImportParameters(ExchangeRules, XMLWriter)

	Parameters.Clear();
	EventsAfterParametersImport.Clear();
	ParametersSetupTable.Clear();
	
	XMLWriter.WriteStartElement("Parameters");
	
	While ExchangeRules.Read() Do
		NodeName = ExchangeRules.LocalName;
		NodeType = ExchangeRules.NodeType;

		If NodeName = "Parameter" And NodeType = XMLNodeTypeStartElement Then
			
			// 
			Name                     = deAttribute(ExchangeRules, StringType, "Name");
			Description            = deAttribute(ExchangeRules, StringType, "Description");
			SetInDialog   = deAttribute(ExchangeRules, BooleanType, "SetInDialog");
			ValueTypeString      = deAttribute(ExchangeRules, StringType, "ValueType");
			UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");
			PassParameterOnExport = deAttribute(ExchangeRules, BooleanType, "PassParameterOnExport");
			ConversionRule = deAttribute(ExchangeRules, StringType, "ConversionRule");
			AfterParameterImportAlgorithm = deAttribute(ExchangeRules, StringType, "AfterImportParameter");
			
			If Not IsBlankString(AfterParameterImportAlgorithm) Then
				
				EventsAfterParametersImport.Insert(Name, AfterParameterImportAlgorithm);
				
			EndIf;
			
			// 
			If Not IsBlankString(ValueTypeString) Then
				
				Try
					DataValueType = Type(ValueTypeString);
					TypeDefined = True;
				Except
					TypeDefined = False;
				EndTry;
				
			Else
				
				TypeDefined = False;
				
			EndIf;
			
			If TypeDefined Then
				ParameterValue = deGetEmptyValue(DataValueType);
				Parameters.Insert(Name, ParameterValue);
			Else
				ParameterValue = "";
				Parameters.Insert(Name);
			EndIf;
						
			If SetInDialog = True Then
				
				TableRow              = ParametersSetupTable.Add();
				TableRow.Description = Description;
				TableRow.Name          = Name;
				TableRow.Value = ParameterValue;				
				TableRow.PassParameterOnExport = PassParameterOnExport;
				TableRow.ConversionRule = ConversionRule;
				
			EndIf;
			
			If UsedOnImport
				And ExchangeMode = "Upload0" Then
				
				XMLWriter.WriteStartElement("Parameter");
				SetAttribute(XMLWriter, "Name",   Name);
				SetAttribute(XMLWriter, "Description", Description);
					
				If Not IsBlankString(AfterParameterImportAlgorithm) Then
					SetAttribute(XMLWriter, "AfterImportParameter", XMLString(AfterParameterImportAlgorithm));
				EndIf;
				
				XMLWriter.WriteEndElement();
				
			EndIf;

		ElsIf (NodeType = XMLNodeTypeText) Then
			
			// 
			ParametersString1 = ExchangeRules.Value;
			For Each Par In ArrayFromString(ParametersString1) Do
				Parameters.Insert(Par);
			EndDo;
			
		ElsIf (NodeName = "Parameters") And (NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();

EndProcedure

// Loads processing in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportDataProcessor(ExchangeRules, XMLWriter)

	Name                     = deAttribute(ExchangeRules, StringType, "Name");
	Description            = deAttribute(ExchangeRules, StringType, "Description");
	IsSetupDataProcessor   = deAttribute(ExchangeRules, BooleanType, "IsSetupDataProcessor");
	
	UsedOnExport = deAttribute(ExchangeRules, BooleanType, "UsedOnExport");
	UsedOnImport = deAttribute(ExchangeRules, BooleanType, "UsedOnImport");

	ParametersString1        = deAttribute(ExchangeRules, StringType, "Parameters");
	
	DataProcessorStorage      = deElementValue(ExchangeRules, ValueStorageType);

	AdditionalDataProcessorParameters.Insert(Name, ArrayFromString(ParametersString1));
	
	
	If UsedOnImport Then
		If ExchangeMode <> "Load" Then
			XMLWriter.WriteStartElement("DataProcessor");
			SetAttribute(XMLWriter, "UsedOnImport", True);
			SetAttribute(XMLWriter, "Name",                     Name);
			SetAttribute(XMLWriter, "Description",            Description);
			SetAttribute(XMLWriter, "IsSetupDataProcessor",   IsSetupDataProcessor);
			XMLWriter.WriteText(XMLString(DataProcessorStorage));
			XMLWriter.WriteEndElement();
		EndIf;
	EndIf;

	If IsSetupDataProcessor Then
		If (ExchangeMode = "Load") And UsedOnImport Then
			ImportSettingsDataProcessors.Add(Name, Description, , );
			
		ElsIf (ExchangeMode = "Upload0") And UsedOnExport Then
			ExportSettingsDataProcessors.Add(Name, Description, , );
			
		EndIf; 
	EndIf; 
	
EndProcedure

// Loads external processing in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//  XMLWriter      - XMLWriter -  an object of the Recordxml type - rules that are saved to the exchange file and
//                   used when loading data.
//
Procedure ImportDataProcessors(ExchangeRules, XMLWriter)

	AdditionalDataProcessors.Clear();
	AdditionalDataProcessorParameters.Clear();
	
	ExportSettingsDataProcessors.Clear();
	ImportSettingsDataProcessors.Clear();

	XMLWriter.WriteStartElement("DataProcessors");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If      NodeName = "DataProcessor" Then
			ImportDataProcessor(ExchangeRules, XMLWriter);
		ElsIf (NodeName = "DataProcessors") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	XMLWriter.WriteEndElement();
	
EndProcedure

// Loads the data upload rule in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules - XMLReader -  an object of the ReadXml type.
//
Procedure ImportDER(ExchangeRules)
	
	NewRow = DataExportRulesCollection().Add();
	
	NewRow.Enable = Not deAttribute(ExchangeRules, BooleanType, "Disconnect");
		
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		If NodeName = "Code" Then
			
			NewRow.Name = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "Description" Then
			
			NewRow.Description = deElementValue(ExchangeRules, StringType);
		
		ElsIf NodeName = "Order" Then
			
			NewRow.Order = deElementValue(ExchangeRules, NumberType);
			
		ElsIf NodeName = "DataFilterMethod" Then
			
			NewRow.DataFilterMethod = deElementValue(ExchangeRules, StringType);
			
		ElsIf NodeName = "SelectExportDataInSingleQuery" Then
			
			// 
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "DoNotExportObjectsCreatedInDestinationInfobase" Then
			
			NewRow.DoNotExportObjectsCreatedInDestinationInfobase = deElementValue(ExchangeRules, BooleanType);

		ElsIf NodeName = "DestinationTypeName" Then
			
			NewRow.DestinationTypeName = deElementValue(ExchangeRules, StringType);

		ElsIf NodeName = "SelectionObject1" Then
			
			SelectionObject1 = deElementValue(ExchangeRules, StringType);
			
			If Not ExchangeRuleInfoImportMode Then
				
				NewRow.SynchronizeByID = SynchronizeByDERID(NewRow.ConversionRule);
				
				If Not IsBlankString(SelectionObject1) Then
					
					NewRow.SelectionObject1        = Type(SelectionObject1);
					
				EndIf;
				
				// 
				If StrFind(SelectionObject1, "Ref.") Then
					NewRow.ObjectForQueryName = StrReplace(SelectionObject1, "Ref.", ".");
				Else
					NewRow.ObjectNameForRegisterQuery = StrReplace(SelectionObject1, "Record.", ".");
				EndIf;
				
			EndIf;

		ElsIf NodeName = "ConversionRuleCode" Then
			
			NewRow.ConversionRule = deElementValue(ExchangeRules, StringType);

		// 

		ElsIf NodeName = "BeforeProcessRule" Then
			NewRow.BeforeProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_BeforeProcessRule";
			NewRow.BeforeProcessHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf NodeName = "AfterProcessRule" Then
			NewRow.AfterProcess = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_AfterProcessRule";
			NewRow.AfterProcessHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
		
		ElsIf NodeName = "BeforeExportObject" Then
			NewRow.BeforeExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_BeforeExportObject";
			NewRow.BeforeExportHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf NodeName = "AfterExportObject" Then
			NewRow.AfterExport = deElementValue(ExchangeRules, StringType);
			HandlerName = "DER_[DERName]_AfterExportObject";
			NewRow.AfterExportHandlerName = StrReplace(HandlerName, "[DERName]", NewRow.Name);
			
		ElsIf (NodeName = "Rule") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			Break;
		EndIf;
		
	EndDo;

	If IsBlankString(NewRow.Description) Then
		NewRow.Description = NewRow.Name;
	EndIf;
	
EndProcedure

// Loads data upload rules in accordance with the format of the exchange rules.
//
// Parameters:
//  ExchangeRules  - XMLReader -  an object of the ReadXml type.
//
Procedure ImportExportRules(ExchangeRules)
	
	ExportRulesTable.Clear();
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If NodeName = "Rule" Then
			
			ImportDER(ExchangeRules);
			
		ElsIf (NodeName = "DataExportRules") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;

EndProcedure

Function SynchronizeByDERID(Val OCRName)
	
	OCR = FindRule(Undefined, OCRName);
	
	If OCR <> Undefined Then
		
		Return (OCR.SynchronizeByID = True);
		
	EndIf;
	
	Return False;
EndFunction

Procedure ImportConversionRuleExchangeObjectsExportModes(XMLWriter)
	
	SourceType = "EnumRef.ExchangeObjectExportModes";
	DestinationType = "EnumRef.ExchangeObjectExportModes";
	
	Filter = New Structure;
	Filter.Insert("SourceType", SourceType);
	Filter.Insert("DestinationType", DestinationType);
	
	If ConversionRulesCollection().FindRows(Filter).Count() <> 0 Then
		Return;
	EndIf;
	
	NewRow = ConversionRulesCollection().Add();
	
	NewRow.RememberExportedData = True;
	NewRow.NotReplace            = False;
	NewRow.ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	
	NewRow.Properties            = PropertyConversionRuleTable.Copy();
	NewRow.SearchProperties      = PropertyConversionRuleTable.Copy();
	NewRow.DisabledProperties = PropertyConversionRuleTable.Copy();
	
	NewRow.Name = "ExchangeObjectExportModes";
	NewRow.Source = Type(SourceType);
	NewRow.Receiver = DestinationType;
	NewRow.SourceType = SourceType;
	NewRow.DestinationType = DestinationType;
	
	Values = New Structure;
	Values.Insert("ExportAlways",           "ExportAlways");
	Values.Insert("ExportByCondition",        "ExportByCondition");
	Values.Insert("ExportIfNecessary", "ExportIfNecessary");
	Values.Insert("ManualExport",          "ManualExport");
	Values.Insert("NotExport",               "NotExport");
	NewRow.PredefinedDataReadValues = Values;
	
	SearchInTabularSections = New ValueTable;
	SearchInTabularSections.Columns.Add("TagName");
	SearchInTabularSections.Columns.Add("KeySearchFieldArray");
	SearchInTabularSections.Columns.Add("KeySearchFields");
	SearchInTabularSections.Columns.Add("Valid", deTypeDetails("Boolean"));
	NewRow.SearchInTabularSections = SearchInTabularSections;
	
	Managers[NewRow.Source].OCR = NewRow;
	
	Rules.Insert(NewRow.Name, NewRow);
	
	XMLWriter.WriteStartElement("Rule");
	deWriteElement(XMLWriter, "Code", NewRow.Name);
	deWriteElement(XMLWriter, "Source", NewRow.SourceType);
	deWriteElement(XMLWriter, "Receiver", NewRow.DestinationType);
	XMLWriter.WriteEndElement(); // Rule
	
EndProcedure

#EndRegion

#Region ExchangeRulesOperationProcedures

// Searches for a conversion rule by name or according to the type
// of object passed.
//
// Parameters:
//   Object     - Arbitrary -  source object for which we are looking for a conversion rule.
//   RuleName - String -  name of the conversion rule.
//
// Returns:
//   ValueTableRow - :
//     * Name - String
//     * Description - String
//     * Source - String
//     * Properties - See PropertiesConversionRulesCollection
// 
Function FindRule(Object = Undefined, RuleName = "")

	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName]; // See FindRule
		
	Else
		
		Rule = Managers[TypeOf(Object)];
		If Rule <> Undefined Then
			Rule = Rule.OCR; // See FindRule
			
			If Rule <> Undefined Then
				RuleName = Rule.Name;
			EndIf;
			
		EndIf; 
		
	EndIf;
	
	Return Rule;
	
EndFunction

// Returns:
//   Structure:
//     * RulesStorageFormatVersion - Number
//     * Conversion
//     * ExportRulesTable -  See DataExportRulesCollection
//     * ConversionRulesTable - See ConversionRulesCollection
//     * ParametersSetupTable
//     * Algorithms
//     * Queries
//     * Parameters
//     * XMLRules
//     * TypesForDestinationString
//
Function ConversionRulesStructure()
	
	If SavedSettings = Undefined Then
		Return Undefined;
	EndIf;
	
	Return SavedSettings.Get();
	
EndFunction

Procedure RestoreRulesFromInternalFormat() Export
	
	RulesStructure = ConversionRulesStructure();

	If RulesStructure = Undefined Then
		Return;
	EndIf;	
	
	// 
	RulesStorageFormatVersion = Undefined;
	RulesStructure.Property("RulesStorageFormatVersion", RulesStorageFormatVersion);
	If RulesStorageFormatVersion <> ExchangeRuleStorageFormatVersion() Then
		Raise NStr("en = 'Unexpected exchange rule storage format version.
			|Please reload the exchange rules.';");
	EndIf;
	
	Conversion                = RulesStructure.Conversion;
	ExportRulesTable      = RulesStructure.ExportRulesTable;
	ConversionRulesTable   = RulesStructure.ConversionRulesTable;
	ParametersSetupTable = RulesStructure.ParametersSetupTable;
	
	Algorithms                  = RulesStructure.Algorithms;
	QueriesToRestore   = RulesStructure.Queries;
	Parameters                  = RulesStructure.Parameters;
	
	XMLRules                = RulesStructure.XMLRules;
	TypesForDestinationString   = RulesStructure.TypesForDestinationString;
	
	HasBeforeExportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeExportObject);
	HasAfterExportObjectGlobalHandler     = Not IsBlankString(Conversion.AfterExportObject);
	HasBeforeImportObjectGlobalHandler    = Not IsBlankString(Conversion.BeforeImportObject);
	HasAfterObjectImportGlobalHandler     = Not IsBlankString(Conversion.AfterImportObject);
	HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);

	// 
	Queries.Clear();
	For Each StructureItem In QueriesToRestore Do
		Query = New Query(StructureItem.Value);
		Queries.Insert(StructureItem.Key, Query);
	EndDo;
	
	InitManagersAndMessages();
	
	Rules.Clear();
	
	For Each TableRow In ConversionRulesCollection() Do
		
		If ExchangeMode = "Upload0" Then
			
			GetPredefinedDataValues(TableRow);
			
		EndIf;
		
		Rules.Insert(TableRow.Name, TableRow);
		
		If ExchangeMode = "Upload0" And TableRow.Source <> Undefined Then
			
			Try
				If TypeOf(TableRow.Source) = StringType Then
					Managers[Type(TableRow.Source)].OCR = TableRow;
				Else
					Managers[TableRow.Source].OCR = TableRow;
				EndIf;
			Except
				WriteErrorInfoToProtocol(11, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
					String(TableRow.Source));
			EndTry;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetParameterValueInTable(ParameterName, ParameterValue)
	
	TableRow = ParametersSetupTable.Find(ParameterName, "Name");
	
	If TableRow <> Undefined Then
		
		TableRow.Value = ParameterValue;	
		
	EndIf;
	
EndProcedure

Procedure InitializeInitialParameterValues()
	
	For Each CurParameter In Parameters Do
		
		SetParameterValueInTable(CurParameter.Key, CurParameter.Value);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ClearingRuleProcessing

Procedure DeleteObject(Object, DeleteDirectly, TypeName = "")
	
	ObjectMetadata = Object.Metadata();
	
	If Common.IsCatalog(ObjectMetadata)
		Or Common.IsChartOfCharacteristicTypes(ObjectMetadata)
		Or Common.IsChartOfAccounts(ObjectMetadata)
		Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
		
		Predefined = Object.Predefined;
	Else
		Predefined = False;
	EndIf;
	
	If Predefined Then
		
		Return;
		
	EndIf;
	
	If DeleteDirectly Then
		
		Object.Delete();
		
	Else
		
		SetObjectDeletionMark(Object, True, TypeName);
		
	EndIf;
	
EndProcedure

Procedure ExecuteObjectDeletion(Object, Properties, DeleteDirectly)
	
	If Properties.TypeName = "InformationRegister" Then
		
		Object.Delete();
		
	Else
		
		DeleteObject(Object, DeleteDirectly, Properties.TypeName);
		
	EndIf;
	
EndProcedure

// Deletes (or marks for deletion) the selection object in accordance with the specified rule.
//
// Parameters:
//  Object         - Arbitrary -  the selection object that is being deleted (marked for deletion).
//  Rule        - ValueTableRow - :
//    * Name - String -  rule name.
//  Properties       - Structure -  properties of the metadata object of the object being deleted.
//  IncomingData - Arbitrary -  arbitrary auxiliary data.
// 
Procedure SelectionObjectDeletion(Object, Rule, Properties, IncomingData)
	
	Cancel = False;
	DeleteDirectly = Rule.Directly;
	
	// 
	
	If Not IsBlankString(Rule.BeforeDeleteRow) Then
	
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerDPRBeforeDeleteObject(Rule, Object, Cancel, DeleteDirectly, IncomingData);
				
			Else
				
				Execute(Rule.BeforeDeleteRow);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(29, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, Object, "BeforeDeleteSelectionObject");
			
		EndTry;
		
		If Cancel Then
		
			Return;
			
		EndIf;
		
	EndIf;

	Try
		
		ExecuteObjectDeletion(Object, Properties, DeleteDirectly);
		
	Except
		
		WriteDataClearingHandlerErrorInfo(24, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			Rule.Name, Object, "");
		
	EndTry;
	
EndProcedure

// Clears data for the specified rule.
//
// Parameters:
//  Rule - ValueTableRow - :
//    * Name - String -  rule name.
// 
Procedure ClearDataByRule(Rule)
	
	// 
	
	Cancel			= False;
	DataSelection	= Undefined;
	OutgoingData = Undefined;
	
	// 
	If Not IsBlankString(Rule.BeforeProcess) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerDPRBeforeProcessRule(Rule, Cancel, OutgoingData, DataSelection);
				
			Else
				
				Execute(Rule.BeforeProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(27, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "", "BeforeProcessClearingRule");
						
		EndTry;
			
		If Cancel Then
			
			Return;
			
		EndIf;
		
	EndIf;
	
	// 
	
	Properties = Managers[Rule.SelectionObject1];
	
	If Rule.DataFilterMethod = "StandardSelection" Then
		
		TypeName		= Properties.TypeName;
		
		If TypeName = "AccountingRegister" 
			Or TypeName = "Constants" Then
			
			Return;
			
		EndIf;
		
		AllFieldsRequired  = Not IsBlankString(Rule.BeforeDeleteRow);
		
		Selection = SelectionForExpotingDataClearing(Properties, TypeName, True, Rule.Directly, AllFieldsRequired);
		
		While Selection.Next() Do
			
			If TypeName =  "InformationRegister" Then
				
				RecordManager = Properties.Manager.CreateRecordManager(); 
				FillPropertyValues(RecordManager, Selection);
									
				SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);
									
			Else
					
				SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
					
			EndIf;
				
		EndDo;		

	ElsIf Rule.DataFilterMethod = "ArbitraryAlgorithm" Then

		If DataSelection <> Undefined Then
			
			Selection = SelectionToExportByArbitraryAlgorithm(DataSelection);
			
			If Selection <> Undefined Then
				
				While Selection.Next() Do
					
					If TypeName =  "InformationRegister" Then
				
						RecordManager = Properties.Manager.CreateRecordManager(); 
						FillPropertyValues(RecordManager, Selection);
											
						SelectionObjectDeletion(RecordManager, Rule, Properties, OutgoingData);
											
					Else
							
						SelectionObjectDeletion(Selection.Ref.GetObject(), Rule, Properties, OutgoingData);
							
					EndIf;					
					
				EndDo;	
				
			Else
				
				For Each Object In DataSelection Do
					
					SelectionObjectDeletion(Object.GetObject(), Rule, Properties, OutgoingData);
					
				EndDo;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// 
	
	If Not IsBlankString(Rule.AfterProcess) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerDPRAfterProcessRule(Rule);
				
			Else
				
				Execute(Rule.AfterProcess);
				
			EndIf;
			
		Except
			
			WriteDataClearingHandlerErrorInfo(28, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "", "AfterProcessClearingRule");
			
		EndTry;
		
	EndIf;
	
EndProcedure

// Traverses the data cleanup rule tree and performs cleanup.
//
// Parameters:
//  Rows - ValueTreeRow -  a collection of rows in the data clearing rule tree.
// 
Procedure ProcessClearingRules(Rows)
	
	For Each ClearingRule In Rows Do
		
		If ClearingRule.Enable = 0 Then
			
			Continue;
			
		EndIf; 

		If ClearingRule.IsFolder Then
			
			ProcessClearingRules(ClearingRule.Rows);
			Continue;
			
		EndIf;
		
		ClearDataByRule(ClearingRule);
		
	EndDo; 
	
EndProcedure

#EndRegion

#Region DataImportProcedures

Procedure StartReadMessage(MessageReader, DataAnalysis = False)
	
	If IsBlankString(ExchangeFileName) Then
		Raise WriteToExecutionProtocol(15);
	EndIf;
	
	ExchangeFile = New XMLReader;
	
	ExchangeFile.OpenFile(ExchangeFileName);
	
	ExchangeFile.Read(); // ExchangeFile
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeFile" Then
		// 
		If DataExchangeXDTOServer.CheckExchangeMessageFormat(ExchangeFile) Then
			SwitchToNewExchange();
		Else
			Raise NStr("en = 'Exchange message format error.';");
		EndIf;
	EndIf;
	
	IncomingExchangeMessageFormatVersionField = deAttribute(ExchangeFile, StringType, "FormatVersion");
	
	SourceConfigurationVersion = "";
	Conversion.Property("SourceConfigurationVersion", SourceConfigurationVersion);
	SourceVersionFromRules = deAttribute(ExchangeFile, StringType, "SourceConfigurationVersion");
	MessageText = "";
	
	If DataExchangeServer.DifferentCorrespondentVersions(ExchangePlanName(), EventLogMessageKey(),
		SourceConfigurationVersion, SourceVersionFromRules, MessageText) Then
		
		Raise MessageText;
		
	EndIf;
	
	ExchangeFile.Read(); // ExchangeRules
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeRules" Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	If ConversionRulesTable.Count() = 0 Then
		ImportExchangeRules(ExchangeFile, "XMLReader");
		If FlagErrors() Then
			Raise NStr("en = 'Cannot load data exchange rules.';");
		EndIf;
	Else
		deSkip(ExchangeFile);
	EndIf;
	
	// 
	If Not IsBlankString(Conversion.BeforeImportData) Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeDataImport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeImportData);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(22, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'BeforeImportData (conversion)';"));
		EndTry;
		
		If Cancel Then
			Raise NStr("en = 'Exchange message import canceled in the BeforeImportData handler (conversion).';");
		EndIf;
		
	EndIf;
	// 
	
	ExchangeFile.Read();
	
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	// 
	If ExchangeFile.LocalName = "CustomSearchSettings" Then
		ImportCustomSearchFieldInfo();
		ExchangeFile.Read();
	EndIf;
	
	// 
	If ExchangeFile.LocalName = "DataTypeInformation" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("en = 'Exchange message format error.';");
		EndIf;
		
		If DataForImportTypeMap().Count() > 0 Then
			deSkip(ExchangeFile);
		Else
			ImportDataTypeInformation();
			If FlagErrors() Then
				Raise NStr("en = 'Errors occurred while importing information about the data types.';");
			EndIf;
		EndIf;
		ExchangeFile.Read();
	EndIf;
	
	// 
	If ExchangeFile.LocalName = "ParameterValue" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("en = 'Exchange message format error.';");
		EndIf;
		
		ImportDataExchangeParameterValues();
		
		While ExchangeFile.Read() Do
			
			If ExchangeFile.LocalName = "ParameterValue" Then
				
				If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
					Raise NStr("en = 'Exchange message format error.';");
				EndIf;
				
				ImportDataExchangeParameterValues();
			Else
				Break;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// 
	If ExchangeFile.LocalName = "AfterParameterExportAlgorithm" Then
		
		If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
			Raise NStr("en = 'Exchange message format error.';");
		EndIf;
		
		ExecuteAfterParametersImportAlgorithm(deElementValue(ExchangeFile, StringType));
		ExchangeFile.Read();
	EndIf;
	
	// 
	If ExchangeFile.NodeType <> XMLNodeType.StartElement Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	If ExchangeFile.LocalName <> "DataFromExchange" Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	ReadDataViaExchange(MessageReader, DataAnalysis);
	ExchangeFile.Read();
	
	If TransactionActive() Then
		Raise NStr("en = 'Cannot set a data receipt lock in an active transaction.';");
	EndIf;
	
	// 
	Try
		LockDataForEdit(MessageReader.Sender);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot lock the data exchange.
			|The data exchange might be running in another session.
			|
			|Details:
			|%1';"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ExecuteHandlerAfterImportData()
	
	// 
	If Not IsBlankString(Conversion.AfterImportData) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionAfterImportData();
				
			Else
				
				Execute(Conversion.AfterImportData);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(23, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'AfterImportData (conversion)';"));
		EndTry;
		
	EndIf;
	// 
	
EndProcedure

Procedure FinishMessageReader(Val MessageReader)
	
	If ExchangeFile.NodeType <> XMLNodeType.EndElement Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	If ExchangeFile.LocalName <> "ExchangeFile" Then
		Raise NStr("en = 'Exchange message format error.';");
	EndIf;
	
	ExchangeFile.Read(); // ExchangeFile
	ExchangeFile.Close();
	
	BeginTransaction();
	Try
		If Not MessageReader.DataAnalysis Then
			MessageReader.SenderObject.ReceivedNo = MessageReader.MessageNo;
			MessageReader.SenderObject.DataExchange.Load = True;
			MessageReader.SenderObject.Write();
		EndIf;
		
		If HasObjectRegistrationDataAdjustment = True Then
			InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustmentUnconditionally(ExchangeNodeDataImport);
		EndIf;
		
		If HasObjectChangeRecordData = True Then
			InformationRegisters.InfobaseObjectsMaps.DeleteObsoleteExportByRefModeRecords(ExchangeNodeDataImport);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
	EndTry;
	
	UnlockDataForEdit(MessageReader.Sender);
	
EndProcedure

Procedure BreakMessageReader(Val MessageReader)
	
	ExchangeFile.Close();
	
	UnlockDataForEdit(MessageReader.Sender);
	
EndProcedure

Procedure ExecuteAfterParametersImportAlgorithm(Val AlgorithmText)
	
	If IsBlankString(AlgorithmText) Then
		Return;
	EndIf;
	
	Cancel = False;
	CancelReason = "";
	
	Try
		
		If ImportHandlersDebug Then
			
			ExecuteHandlerConversionAfterParametersImport(ExchangeFile, Cancel, CancelReason);
			
		Else
			
			Execute(AlgorithmText);
			
		EndIf;
		
		If Cancel = True Then
			
			If Not IsBlankString(CancelReason) Then
				
				MessageString = NStr("en = 'The exchange message import is canceled in the AfterImportParameters (conversion) handler. Reason: %1';");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CancelReason);
				Raise MessageString;
			Else
				Raise NStr("en = 'The exchange message import is canceled in the AfterImportParameters (conversion) handler.';");
			EndIf;
			
		EndIf;
		
	Except
		
		WP = ExchangeProtocolRecord(78, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WP.Handler     = "AfterImportParameters";
		ErrorMessageString = WriteToExecutionProtocol(78, WP);
		
		If Not ContinueOnError Then
			Raise ErrorMessageString;
		EndIf;
		
	EndTry;
	
EndProcedure

Function SetNewObjectRef(Object, Manager, SearchProperties)
	
	UUID1 = SearchProperties["{UUID}"];
	
	If UUID1 <> Undefined Then
		
		NewRef = Manager.GetRef(New UUID(UUID1));
		
		Object.SetNewObjectRef(NewRef);
		
		SearchProperties.Delete("{UUID}");
		
	Else
		
		Object.SetNewObjectRef(Manager.GetRef(New UUID));
		NewRef = Undefined;
		
	EndIf;
	
	Return NewRef;
	
EndFunction

// Searches for an object by its number in the list of already loaded objects.
//
// Parameters:
//  NBSp          - the number of the object you are looking for in the exchange file.
//
// Returns:
//  Link to the found object. If the object is not found, it returns Undefined.
// 
Function FindObjectByNumber(NBSp, ObjectType, MainObjectSearchMode = False)
	
	Return Undefined;
	
EndFunction

Function FindObjectByGlobalNumber(NBSp, MainObjectSearchMode = False)
	
	Return Undefined;
	
EndFunction

Procedure RemoveDeletionMarkFromPredefinedItem(Object, Val ObjectType)
	
	If TypeOf(ObjectType) = StringType Then
		ObjectType = Type(ObjectType);
	EndIf;
	
	If (Catalogs.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfAccounts.AllRefsType().ContainsType(ObjectType)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType))
		And Object.DeletionMark
		And Object.Predefined Then
		
		Object.DeletionMark = False;
		
		// 
		WP            = ExchangeProtocolRecord(80);
		WP.ObjectType = ObjectType;
		WP.Object     = String(Object);
		
		WriteToExecutionProtocol(80, WP, False,,,,Enums.ExchangeExecutionResults.CompletedWithWarnings);
		
	EndIf;
	
EndProcedure

Procedure SetCurrentDateToAttribute(ObjectAttribute)
	
	ObjectAttribute = CurrentSessionDate();
	
EndProcedure

// Creates a new object of the specified type, sets the details specified
// in the search Property structure.
//
// Parameters:
//  Type            - type of object to create.
//  SearchProperties - Structure -  contains the details of the new object to be set.
//  Object - 
//  WriteObjectImmediatelyAfterCreation - Boolean
//  NewRef - 
//  SetAllObjectSearchProperties - Boolean
//  RegisterRecordSet - InformationRegisterRecordSet -  which is created.
//
// Returns:
//  Created object, or Undefined (if not set to write objectsreferences).
// 
Function CreateNewObject(Type, SearchProperties, Object, 
	WriteObjectImmediatelyAfterCreation, NewRef = Undefined, 
	SetAllObjectSearchProperties = True,
	RegisterRecordSet = Undefined)
	
	MDProperties      = Managers[Type];
	TypeName         = MDProperties.TypeName;
	Manager        = MDProperties.Manager;

	If TypeName = "Catalog"
		Or TypeName = "ChartOfCharacteristicTypes" Then
		
		IsFolder = SearchProperties["IsFolder"];
		
		If IsFolder = True Then
			
			Object = Manager.CreateFolder();
						
		Else
			
			Object = Manager.CreateElement();
			
		EndIf;		
				
	ElsIf TypeName = "Document" Then
		
		Object = Manager.CreateDocument();
				
	ElsIf TypeName = "ChartOfAccounts" Then
		
		Object = Manager.CreateAccount();
				
	ElsIf TypeName = "ChartOfCalculationTypes" Then
		
		Object = Manager.CreateCalculationType();
				
	ElsIf TypeName = "InformationRegister" Then
		
		RegisterRecordSet = Manager.CreateRecordSet(); // InformationRegisterRecordSet
		Object = RegisterRecordSet.Add();
		Return Object;
		
	ElsIf TypeName = "ExchangePlan" Then
		
		Object = Manager.CreateNode();
				
	ElsIf TypeName = "Task" Then
		
		Object = Manager.CreateTask();
		
	ElsIf TypeName = "BusinessProcess" Then
		
		Object = Manager.CreateBusinessProcess();	
		
	ElsIf TypeName = "Enum" Then
		
		Object = MDProperties.EmptyRef;	
		Return Object;
		
	ElsIf TypeName = "BusinessProcessRoutePoint" Then
		
		Return Undefined;
				
	EndIf;
	
	NewRef = SetNewObjectRef(Object, Manager, SearchProperties);
	
	If SetAllObjectSearchProperties Then
		SetObjectSearchAttributes(Object, SearchProperties, , False, False);
	EndIf;
	
	// Checks
	If TypeName = "Document"
		Or TypeName = "Task"
		Or TypeName = "BusinessProcess" Then
		
		If Not ValueIsFilled(Object.Date) Then
			
			SetCurrentDateToAttribute(Object.Date);			
						
		EndIf;
		
	EndIf;
		
	If WriteObjectImmediatelyAfterCreation Then
		
		WriteObjectToIB(Object, Type);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	Return Object.Ref;
	
EndFunction

// Reads the object properties node from the file and sets the property value.
//
// Parameters:
//  Type            - 
//  
//                   
//
// Returns:
//  Property value
// 
Function ReadProperty(Type, DontCreateObjectIfNotFound = False, PropertyNotFoundByRef = False, OCRName = "")

	Value = Undefined;
	PropertyExistence = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Value" Then
			
			SearchByProperty = deAttribute(ExchangeFile, StringType, "Property");
			Value         = deElementValue(ExchangeFile, Type, SearchByProperty, False);
			PropertyExistence = True;
			
		ElsIf NodeName = "Ref" Then
			
			InfobaseObjectsMaps = Undefined;
			CreatedObject = Undefined;
			ObjectFound = True;
			SearchBySearchFieldsIfNotFoundByID = False;
			
			Value = FindObjectByRef(Type,
											,
											, 
											ObjectFound, 
											CreatedObject, 
											DontCreateObjectIfNotFound, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											, 
											OCRName, 
											InfobaseObjectsMaps, 
											SearchBySearchFieldsIfNotFoundByID);
			
			If DontCreateObjectIfNotFound
				And Not ObjectFound Then
				
				PropertyNotFoundByRef = False;
				
			EndIf;
			
			PropertyExistence = True;
			
		ElsIf NodeName = "NBSp" Then
			
			ExchangeFile.Read();
			NBSp = Number(ExchangeFile.Value);
			If NBSp <> 0 Then
				Value  = FindObjectByNumber(NBSp, Type);
				PropertyExistence = True;
			EndIf;			
			ExchangeFile.Read();
			
		ElsIf NodeName = "Gsn" Then
			
			ExchangeFile.Read();
			Gsn = Number(ExchangeFile.Value);
			If Gsn <> 0 Then
				Value  = FindObjectByGlobalNumber(Gsn);
				PropertyExistence = True;
			EndIf;
			
			ExchangeFile.Read();
			
		ElsIf (NodeName = "Property" Or NodeName = "ParameterValue") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			If Not PropertyExistence
				And ValueIsFilled(Type) Then
				
				// 
				Value = deGetEmptyValue(Type);
				
			EndIf;
			
			Break;
			
		ElsIf NodeName = "Expression" Then
			
			Expression = deElementValue(ExchangeFile, StringType, , False);
			Value  = Common.CalculateInSafeMode(Expression);
			
			PropertyExistence = True;
			
		ElsIf NodeName = "Empty" Then
			
			Value = deGetEmptyValue(Type);
			PropertyExistence = True;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Value;
	
EndFunction

Procedure SetObjectSearchAttributes(FoundObject, SearchProperties,
		SearchPropertiesDontReplace = Undefined, ShouldCompareWithCurrentAttributes = True, DontReplacePropertiesNotToChange = True)
	
	For Each Property In SearchProperties Do
					
		Name      = Property.Key;
		Value = Property.Value;
		
		If DontReplacePropertiesNotToChange
			And SearchPropertiesDontReplace[Name] <> Undefined Then
			
			Continue;
			
		EndIf;
					
		If Name = "IsFolder" 
			Or Name = "{UUID}" 
			Or Name = "{PredefinedItemName1}"
			Or Name = "{SourceIBSearchKey}"
			Or Name = "{DestinationIBSearchKey}"
			Or Name = "{TypeNameInSourceIB}"
			Or Name = "{TypeNameInDestinationIB}" Then
						
			Continue;
						
		ElsIf Name = "DeletionMark" Then
						
			If Not ShouldCompareWithCurrentAttributes
				Or FoundObject.DeletionMark <> Value Then
							
				FoundObject.DeletionMark = Value;
							
			EndIf;
						
		Else
				
			// 
			
			If FoundObject[Name] <> NULL Then
			
				If Not ShouldCompareWithCurrentAttributes
					Or FoundObject[Name] <> Value Then
						
					FoundObject[Name] = Value;
					
						
				EndIf;
				
			EndIf;
				
		EndIf;
					
	EndDo;
	
EndProcedure

Function FindOrCreateObjectByProperty(PropertyStructure,
									ObjectType,
									SearchProperties,
									SearchPropertiesDontReplace,
									ObjectTypeName,
									SearchProperty,
									SearchPropertyValue,
									ObjectFound,
									CreateNewItemIfNotFound = True,
									FoundOrCreatedObject = Undefined,
									MainObjectSearchMode = False,
									NewUUIDRef = Undefined,
									NBSp = 0,
									Gsn = 0,
									ObjectParameters = Undefined,
									DontReplaceObjectCreatedInDestinationInfobase = False,
									ObjectCreatedInCurrentInfobase = Undefined)
	
	Object = deFindObjectByProperty(PropertyStructure.Manager, SearchProperty, SearchPropertyValue, 
		FoundOrCreatedObject, , , MainObjectSearchMode, PropertyStructure.SearchString);
	
	ObjectFound = Not (Object = Undefined
				Or Object.IsEmpty());
				
	If Not ObjectFound
		And CreateNewItemIfNotFound Then
		
		Object = CreateNewObject(ObjectType, SearchProperties, FoundOrCreatedObject, 
			Not MainObjectSearchMode, NewUUIDRef);
			
		Return Object;
		
	EndIf;
			
	
	If MainObjectSearchMode Then
		
		//
		Try
			
			If Not ValueIsFilled(Object) Then
				Return Object;
			EndIf;
			
			If FoundOrCreatedObject = Undefined Then
				FoundOrCreatedObject = Object.GetObject();
			EndIf;
			
		Except
			Return Object;
		EndTry;
			
		SetObjectSearchAttributes(FoundOrCreatedObject, SearchProperties, SearchPropertiesDontReplace);
		
	EndIf;
		
	Return Object;
	
EndFunction

Function PropertyType1()
	
	PropertyTypeString = deAttribute(ExchangeFile, StringType, "Type");
	If IsBlankString(PropertyTypeString) Then
		
		// 
		Return Undefined;
		
	ElsIf PropertyTypeString = "TypeDefinition" Then
		
		Return Type("TypeDescription");
		
	EndIf;
	
	Return Type(PropertyTypeString);
	
EndFunction

Function PropertyTypeByAdditionalData(TypesInformation, PropertyName)
	
	PropertyType1 = PropertyType1();
				
	If PropertyType1 = Undefined
		And TypesInformation <> Undefined Then
		
		PropertyType1 = TypesInformation[PropertyName];
		
	EndIf;
	
	Return PropertyType1;
	
EndFunction

Procedure ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation,
	SearchByEqualDate, ObjectParameters, Val MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps)
	
	SearchByEqualDate = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If    NodeName = "Property"
			Or NodeName = "ParameterValue" Then
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name = deAttribute(ExchangeFile, StringType, "Name");
			
			SourceTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			DestinationTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			UUIDProperty = (Name = "{UUID}");
			
			If UUIDProperty Then
				
				PropertyType1 = StringType;
				
			ElsIf Name = "{PredefinedItemName1}"
				  Or Name = "{SourceIBSearchKey}"
				  Or Name = "{DestinationIBSearchKey}"
				  Or Name = "{TypeNameInSourceIB}"
				  Or Name = "{TypeNameInDestinationIB}" Then
				
				PropertyType1 = StringType;
				
			Else
				
				PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
				
			EndIf;
			
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "NotReplace");
			
			SearchByEqualDate = SearchByEqualDate 
						Or deAttribute(ExchangeFile, BooleanType, "SearchByEqualDate");
			//
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			PropertyValue = ReadProperty(PropertyType1,,, OCRName);
			
			If UUIDProperty Then
				
				ReplaceUUIDIfNecessary(PropertyValue, SourceTypeString, DestinationTypeString, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
				
			EndIf;
			
			If (Name = "IsFolder") And (PropertyValue <> True) Then
				
				PropertyValue = False;
												
			EndIf; 
			
			If IsParameter Then
				
				
				AddParameterIfNecessary(ObjectParameters, Name, PropertyValue);
				
			Else
			
				SearchProperties[Name] = PropertyValue;
				
				If DontReplaceProperty Then
					
					SearchPropertiesDontReplace[Name] = True;
					
				EndIf;
				
			EndIf;
			
		ElsIf (NodeName = "Ref") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ReplaceUUIDIfNecessary(
										UUID,
										Val SourceTypeString,
										Val DestinationTypeString,
										Val MainObjectSearchMode,
										ObjectMapFound = False,
										InfobaseObjectsMaps = Undefined)
	
	// 
	If MainObjectSearchMode And DataImportToValueTableMode() Then
		Return;
	EndIf;
	
	InfobaseObjectsMapQuery.SetParameter("InfobaseNode", ExchangeNodeDataImport);
	InfobaseObjectsMapQuery.SetParameter("DestinationUUID", UUID);
	InfobaseObjectsMapQuery.SetParameter("DestinationType", DestinationTypeString);
	InfobaseObjectsMapQuery.SetParameter("SourceType", SourceTypeString);
	
	QueryResult = InfobaseObjectsMapQuery.Execute();
	
	If QueryResult.IsEmpty() Then
		
		InfobaseObjectsMaps = New Structure;
		InfobaseObjectsMaps.Insert("InfobaseNode", ExchangeNodeDataImport);
		InfobaseObjectsMaps.Insert("DestinationType", DestinationTypeString);
		InfobaseObjectsMaps.Insert("SourceType", SourceTypeString);
		InfobaseObjectsMaps.Insert("DestinationUUID", UUID);
		
		// 
		// 
		InfobaseObjectsMaps.Insert("SourceUUID", Undefined);
		
	Else
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		UUID = Selection.SourceUUIDString;
		
		ObjectMapFound = True;
		
	EndIf;
	
EndProcedure

Function UnlimitedLengthField(TypeManager, ParameterName)
	
	LongStrings = Undefined;
	If Not TypeManager.Property("LongStrings", LongStrings) Then
		
		LongStrings = New Map;
		For Each Attribute In TypeManager.MetadataObjectsList.Attributes Do
			
			If Attribute.Type.ContainsType(StringType) 
				And (Attribute.Type.StringQualifiers.Length = 0) Then
				
				LongStrings.Insert(Attribute.Name, Attribute.Name);	
				
			EndIf;
			
		EndDo;
		
		TypeManager.Insert("LongStrings", LongStrings);
		
	EndIf;
	
	Return (LongStrings[ParameterName] <> Undefined);
		
EndFunction

Function IsUnlimitedLengthParameter(TypeManager, ParameterValue, ParameterName)
	
	If TypeOf(ParameterValue) = StringType Then
		UnlimitedLengthString = UnlimitedLengthField(TypeManager, ParameterName);
	Else
		UnlimitedLengthString = False;
	EndIf;
	
	Return UnlimitedLengthString;
	
EndFunction

Function FindItemUsingRequest(PropertyStructure, SearchProperties, ObjectType = Undefined, 
	TypeManager = Undefined, RealPropertyForSearchCount = Undefined)
	
	PropertyCountForSearch = ?(RealPropertyForSearchCount = Undefined, SearchProperties.Count(), RealPropertyForSearchCount);
	
	If PropertyCountForSearch = 0
		And PropertyStructure.TypeName = "Enum" Then
		
		Return PropertyStructure.EmptyRef;
		
	EndIf;
	
	QueryText       = PropertyStructure.SearchString;
	
	If IsBlankString(QueryText) Then
		Return PropertyStructure.EmptyRef;
	EndIf;
	
	SearchQuery       = New Query();
	
	PropertyUsedInSearchCount = 0;
	
	For Each Property In SearchProperties Do
		
		ParameterName = Property.Key;
		
		// 
		If ParameterName = "{UUID}" Or ParameterName = "{PredefinedItemName1}" Then
			Continue;
		EndIf;
		
		ParameterValue = Property.Value;
		SearchQuery.SetParameter(ParameterName, ParameterValue);
		
		UnlimitedLengthString = IsUnlimitedLengthParameter(PropertyStructure, ParameterValue, ParameterName);
		
		PropertyUsedInSearchCount = PropertyUsedInSearchCount + 1;
		
		If UnlimitedLengthString Then
			
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " And ", "") + ParameterName + " LIKE &" + ParameterName;
			
		Else
			
			QueryText = QueryText + ?(PropertyUsedInSearchCount > 1, " And ", "") + ParameterName + " = &" + ParameterName;
			
		EndIf;
		
	EndDo;
	
	If PropertyUsedInSearchCount = 0 Then
		Return Undefined;
	EndIf;
	
	SearchQuery.Text = QueryText;
	Result = SearchQuery.Execute();
			
	If Result.IsEmpty() Then
		
		Return Undefined;
								
	Else
		
		// 
		Selection = Result.Select();
		Selection.Next();
		ObjectReference = Selection.Ref;
				
	EndIf;
	
	Return ObjectReference;
	
EndFunction

// Defines an object conversion rule (PCO) based on the receiver object type.
//
// Parameters:
//  RefTypeString1 - String -  the object type in the string representation, e.g. "Spravochniki.Nomenclature".
// 
// Returns:
//  Match valuesreferences = Object conversion rule.
// 
Function GetConversionRuleWithSearchAlgorithmByDestinationObjectType(RefTypeString1)
	
	MapValue = ConversionRulesMap.Get(RefTypeString1);
	
	If MapValue <> Undefined Then
		Return MapValue;
	EndIf;
	
	Try
	
		For Each Item In Rules Do
			
			If Item.Value.Receiver = RefTypeString1 Then
				
				If Item.Value.HasSearchFieldSequenceHandler = True Then
					
					Rule = Item.Value;
					
					ConversionRulesMap.Insert(RefTypeString1, Rule);
					
					Return Rule;
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		ConversionRulesMap.Insert(RefTypeString1, Undefined);
		Return Undefined;
	
	Except
		
		ConversionRulesMap.Insert(RefTypeString1, Undefined);
		Return Undefined;
	
	EndTry;
	
EndFunction

Function FindDocumentRef(SearchProperties, PropertyStructure, RealPropertyForSearchCount, SearchWithQuery, SearchByEqualDate)
	
	// 
	SearchWithQuery = SearchByEqualDate Or (RealPropertyForSearchCount <> 2);
				
	If SearchWithQuery Then
		Return Undefined;
	EndIf;
	
	DocumentNumber = SearchProperties["Number"];
	DocumentDate  = SearchProperties["Date"];
					
	If (DocumentNumber <> Undefined) And (DocumentDate <> Undefined) Then
						
		ObjectReference = PropertyStructure.Manager.FindByNumber(DocumentNumber, DocumentDate);
																		
	Else
						
		// 
		SearchWithQuery = True;
		ObjectReference = Undefined;
						
	EndIf;
	
	Return ObjectReference;
	
EndFunction

Function FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, 
	PropertyStructure, SearchPropertyNameString, SearchByEqualDate)
	
	// 
	// 
	// 
	
	If IsBlankString(SearchPropertyNameString) Then
		
		TemporarySearchProperties = SearchProperties;
		
	Else
		
		SelectedProperties = StrSplit(SearchPropertyNameString, ", ", False);
		
		TemporarySearchProperties = New Map;
		For Each PropertyItem In SearchProperties Do
			
			If SelectedProperties.Find(PropertyItem.Key) <> Undefined Then
				TemporarySearchProperties.Insert(PropertyItem.Key, PropertyItem.Value);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	UUIDProperty = TemporarySearchProperties["{UUID}"];
	PredefinedNameProperty    = TemporarySearchProperties["{PredefinedItemName1}"];
	
	RealPropertyForSearchCount = TemporarySearchProperties.Count();
	RealPropertyForSearchCount = RealPropertyForSearchCount - ?(UUIDProperty <> Undefined, 1, 0);
	RealPropertyForSearchCount = RealPropertyForSearchCount - ?(PredefinedNameProperty    <> Undefined, 1, 0);
	
	SearchWithQuery = False;
	
	If ObjectTypeName = "Document" Then
		
		ObjectReference = FindDocumentRef(TemporarySearchProperties, PropertyStructure, RealPropertyForSearchCount, SearchWithQuery, SearchByEqualDate);
		
	Else
		
		SearchWithQuery = True;
		
	EndIf;
	
	If SearchWithQuery Then
		
		ObjectReference = FindItemUsingRequest(PropertyStructure, TemporarySearchProperties, ObjectType, , RealPropertyForSearchCount);
		
	EndIf;
	
	Return ObjectReference;
EndFunction

Procedure ProcessObjectSearchPropertySetting(SetAllObjectSearchProperties, 
												ObjectType, 
												SearchProperties, 
												SearchPropertiesDontReplace, 
												ObjectReference, 
												CreatedObject, 
												WriteNewObjectToInfobase = True, 
												DontReplaceObjectCreatedInDestinationInfobase = False, 
												ObjectCreatedInCurrentInfobase = Undefined)
	
	If SetAllObjectSearchProperties <> True Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(ObjectReference) Then
		Return;
	EndIf;
	
	If CreatedObject = Undefined Then
		CreatedObject = ObjectReference.GetObject();
	EndIf;
	
	SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
	
EndProcedure

Procedure ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace,
	SearchByEqualDate = False, ObjectParameters = Undefined, Val MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps)
	
	If SearchProperties = "" Then
		SearchProperties = New Map;
	EndIf;
	
	If SearchPropertiesDontReplace = "" Then
		SearchPropertiesDontReplace = New Map;
	EndIf;
	
	TypesInformation = DataForImportTypeMap()[ObjectType];
	ReadSearchPropertiesFromFile(SearchProperties, SearchPropertiesDontReplace, TypesInformation, SearchByEqualDate, ObjectParameters, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
	
EndProcedure

Procedure GetAdditionalObjectSearchParameters(SearchProperties, ObjectType, PropertyStructure, ObjectTypeName, IsDocumentObject)
	
	If ObjectType = Undefined Then
		
		// 
		DestinationTypeName = SearchProperties["{TypeNameInDestinationIB}"];
		If DestinationTypeName = Undefined Then
			DestinationTypeName = SearchProperties["{TypeNameInSourceIB}"];
		EndIf;
		
		If DestinationTypeName <> Undefined Then
			
			ObjectType = Type(DestinationTypeName);	
			
		EndIf;		
		
	EndIf;
	
	PropertyStructure   = Managers[ObjectType];
	ObjectTypeName     = PropertyStructure.TypeName;	
	
EndProcedure

// Searches for an object in the information database, and creates a new one if it is not found.
//
// Parameters:
//  ObjectType     - 
//  SearchProperties - Structure -  contains properties that are used to search for the object.
//  ObjectFound   - 
//
// Returns:
//  A new or found object in the database.
//  
Function FindObjectByRef(ObjectType, 
							SearchProperties = "", 
							SearchPropertiesDontReplace = "", 
							ObjectFound = True, 
							CreatedObject = Undefined, 
							DontCreateObjectIfNotFound = False,
							MainObjectSearchMode = False,
							GlobalRefSn = 0,
							RefSN = 0,
							ObjectFoundBySearchFields = False,
							KnownUUIDRef = Undefined,
							SearchingImportObject = False,
							ObjectParameters = Undefined,
							DontReplaceObjectCreatedInDestinationInfobase = False,
							ObjectCreatedInCurrentInfobase = Undefined,
							RecordObjectChangeAtSenderNode = False,
							UUIDAsString1 = "",
							OCRName = "",
							InfobaseObjectsMaps = Undefined,
							SearchBySearchFieldsIfNotFoundByID = Undefined)
	
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
	
	SearchByEqualDate = False;
	ObjectReference = Undefined;
	PropertyStructure = Undefined;
	ObjectTypeName = Undefined;
	IsDocumentObject = False;
	RefPropertyReadingCompleted = False;
	ObjectMapFound = False;
	
	GlobalRefSn = deAttribute(ExchangeFile, NumberType, "Gsn");
	RefSN           = deAttribute(ExchangeFile, NumberType, "NBSp");
	
	// 
	RecordObjectChangeAtSenderNode = deAttribute(ExchangeFile, BooleanType, "RecordObjectChangeAtSenderNode");
	
	FlagDontCreateObjectIfNotFound = deAttribute(ExchangeFile, BooleanType, "DontCreateIfNotFound");
	If Not ValueIsFilled(FlagDontCreateObjectIfNotFound) Then
		FlagDontCreateObjectIfNotFound = False;
	EndIf;
	
	If DontCreateObjectIfNotFound = Undefined Then
		DontCreateObjectIfNotFound = False;
	EndIf;
	
	OnExchangeObjectByRefSetGIUDOnly = Not MainObjectSearchMode;
		
	DontCreateObjectIfNotFound = DontCreateObjectIfNotFound Or FlagDontCreateObjectIfNotFound;
	
	FlagDontReplaceObjectCreatedInDestinationInfobase = deAttribute(ExchangeFile, BooleanType, "DontReplaceObjectCreatedInDestinationInfobase");
	If Not ValueIsFilled(FlagDontReplaceObjectCreatedInDestinationInfobase) Then
		DontReplaceObjectCreatedInDestinationInfobase = False;
	Else
		DontReplaceObjectCreatedInDestinationInfobase = FlagDontReplaceObjectCreatedInDestinationInfobase;	
	EndIf;
	
	SearchBySearchFieldsIfNotFoundByID = deAttribute(ExchangeFile, BooleanType, "ContinueSearch");
	
	// 
	ReadSearchPropertyInfo(ObjectType, SearchProperties, SearchPropertiesDontReplace, SearchByEqualDate, ObjectParameters, MainObjectSearchMode, ObjectMapFound, InfobaseObjectsMaps);
	GetAdditionalObjectSearchParameters(SearchProperties, ObjectType, PropertyStructure, ObjectTypeName, IsDocumentObject);
	
	UUIDProperty = SearchProperties["{UUID}"];
	PredefinedNameProperty    = SearchProperties["{PredefinedItemName1}"];
	
	UUIDAsString1 = UUIDProperty;
	
	OnExchangeObjectByRefSetGIUDOnly = OnExchangeObjectByRefSetGIUDOnly
									And UUIDProperty <> Undefined;
	
	If ObjectMapFound Then
		
		// 
		
		ObjectReference = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
		
		If MainObjectSearchMode Then
			
			CreatedObject = ObjectReference.GetObject();
			
			If CreatedObject <> Undefined Then
				
				SetObjectSearchAttributes(CreatedObject, SearchProperties, SearchPropertiesDontReplace);
				
				ObjectFound = True;
				
				Return ObjectReference;
				
			EndIf;
			
		Else
			
			// 
			Return ObjectReference;
			
		EndIf;
		
	EndIf;
	
	// 
	If PredefinedNameProperty <> Undefined Then
		
		CreateNewObjectAutomatically = False;
		
		ObjectReference = FindOrCreateObjectByProperty(PropertyStructure,
													ObjectType,
													SearchProperties,
													SearchPropertiesDontReplace,
													ObjectTypeName,
													"{PredefinedItemName1}",
													PredefinedNameProperty,
													ObjectFound,
													CreateNewObjectAutomatically,
													CreatedObject,
													MainObjectSearchMode,
													,
													RefSN, GlobalRefSn,
													ObjectParameters,
													DontReplaceObjectCreatedInDestinationInfobase,
													ObjectCreatedInCurrentInfobase);
		
		If ObjectReference <> Undefined
			And ObjectReference.IsEmpty() Then
			
			ObjectFound = False;
			ObjectReference = Undefined;
					
		EndIf;
			
		If    ObjectReference <> Undefined
			Or CreatedObject <> Undefined Then
			
			ObjectFound = True;
			
			// 
			Return ObjectReference;
			
		EndIf;
		
	EndIf;
	
	// 
	If UUIDProperty <> Undefined Then
		
		If MainObjectSearchMode Then
			
			CreateNewObjectAutomatically = Not DontCreateObjectIfNotFound And Not SearchBySearchFieldsIfNotFoundByID;
			
			ObjectReference = FindOrCreateObjectByProperty(PropertyStructure,
														ObjectType,
														SearchProperties,
														SearchPropertiesDontReplace,
														ObjectTypeName,
														"{UUID}",
														UUIDProperty,
														ObjectFound,
														CreateNewObjectAutomatically,
														CreatedObject,
														MainObjectSearchMode,
														KnownUUIDRef,
														RefSN,
														GlobalRefSn,
														ObjectParameters,
														DontReplaceObjectCreatedInDestinationInfobase,
														ObjectCreatedInCurrentInfobase);
			If Not SearchBySearchFieldsIfNotFoundByID Then
				
				Return ObjectReference;
				
			EndIf;
			
		ElsIf SearchBySearchFieldsIfNotFoundByID Then
			
			CreateNewObjectAutomatically = False;
			
			ObjectReference = FindOrCreateObjectByProperty(PropertyStructure,
														ObjectType,
														SearchProperties,
														SearchPropertiesDontReplace,
														ObjectTypeName,
														"{UUID}",
														UUIDProperty,
														ObjectFound,
														CreateNewObjectAutomatically,
														CreatedObject,
														MainObjectSearchMode,
														KnownUUIDRef,
														RefSN,
														GlobalRefSn,
														ObjectParameters,
														DontReplaceObjectCreatedInDestinationInfobase,
														ObjectCreatedInCurrentInfobase);
			
		Else
			
			// 
			Return PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
			
		EndIf;
		
		If ObjectReference <> Undefined 
			And ObjectReference.IsEmpty() Then
			
			ObjectFound = False;
			ObjectReference = Undefined;
					
		EndIf;
			
		If    ObjectReference <> Undefined
			Or CreatedObject <> Undefined Then
			
			ObjectFound = True;
			
			// 
			Return ObjectReference;
			
		EndIf;
		
	EndIf;
	
	// 
	SearchVariantNumber = 1;
	SearchPropertyNameString = "";
	PreviousSearchString = Undefined;
	StopSearch = False;
	SetAllObjectSearchProperties = True;
	OCR = Undefined;
	SearchAlgorithm = "";
	
	If Not IsBlankString(OCRName) Then
		
		OCR = Rules[OCRName];
		
	EndIf;
	
	If OCR = Undefined Then
		
		OCR = GetConversionRuleWithSearchAlgorithmByDestinationObjectType(PropertyStructure.RefTypeString1);
		
	EndIf;
	
	If OCR <> Undefined Then
		
		SearchAlgorithm = OCR.SearchFieldSequence;
		
	EndIf;
	
	HasSearchAlgorithm = Not IsBlankString(SearchAlgorithm);
	
	While SearchVariantNumber <= 10
		And HasSearchAlgorithm Do
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteOCRHandlerSearchFieldsSequence(SearchVariantNumber, SearchProperties, ObjectParameters, StopSearch,
																	  ObjectReference, SetAllObjectSearchProperties, SearchPropertyNameString,
																	  OCR.SearchFieldSequenceHandlerName);
				
			Else
				
				Execute(SearchAlgorithm);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(73, ErrorProcessing.DetailErrorDescription(ErrorInfo()), "", "", 
				ObjectType, Undefined, NStr("en = 'Search field sequence';"));
			
		EndTry;
		
		DontSearch = StopSearch = True 
			Or SearchPropertyNameString = PreviousSearchString
			Or ValueIsFilled(ObjectReference);				
			
		If Not DontSearch Then
	
			// 
			ObjectReference = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
				SearchPropertyNameString, SearchByEqualDate);
				
			DontSearch = ValueIsFilled(ObjectReference);
			
			If ObjectReference <> Undefined
				And ObjectReference.IsEmpty() Then
				ObjectReference = Undefined;
			EndIf;
			
		EndIf;
		
		If DontSearch Then
		
			If MainObjectSearchMode Then
			
				ProcessObjectSearchPropertySetting(SetAllObjectSearchProperties, 
													ObjectType, 
													SearchProperties, 
													SearchPropertiesDontReplace, 
													ObjectReference, 
													CreatedObject, 
													Not MainObjectSearchMode, 
													DontReplaceObjectCreatedInDestinationInfobase, 
													ObjectCreatedInCurrentInfobase);
					
			EndIf;
						
			Break;
			
		EndIf;	
	
		SearchVariantNumber = SearchVariantNumber + 1;
		PreviousSearchString = SearchPropertyNameString;
		
	EndDo;
		
	If Not HasSearchAlgorithm Then
		
		// 
		ObjectReference = FindItemBySearchProperties(ObjectType, ObjectTypeName, SearchProperties, PropertyStructure, 
					SearchPropertyNameString, SearchByEqualDate);
		
	EndIf;
	
	If MainObjectSearchMode
		And ValueIsFilled(ObjectReference)
		And (ObjectTypeName = "Document" 
		Or ObjectTypeName = "Task"
		Or ObjectTypeName = "BusinessProcess") Then
		
		// 
		EmptyDate = Not ValueIsFilled(SearchProperties["Date"]);
		CanReplace = (Not EmptyDate) 
			And (SearchPropertiesDontReplace["Date"] = Undefined);
			
		If CanReplace Then
			
			If CreatedObject = Undefined Then
				CreatedObject = ObjectReference.GetObject();
			EndIf;
			
			CreatedObject.Date = SearchProperties["Date"];
				
		EndIf;
		
	EndIf;		
	
	// 
	If (ObjectReference = Undefined
			Or ObjectReference.IsEmpty())
		And CreatedObject = Undefined Then // 
		
		If OnExchangeObjectByRefSetGIUDOnly Then
			
			ObjectReference = PropertyStructure.Manager.GetRef(New UUID(UUIDProperty));
			
		ElsIf Not DontCreateObjectIfNotFound Then
		
			ObjectReference = CreateNewObject(ObjectType, SearchProperties, CreatedObject, 
				Not MainObjectSearchMode, KnownUUIDRef, SetAllObjectSearchProperties);
				
		EndIf;
			
		ObjectFound = False;
		
	Else
		
		// 
		ObjectFound = True;
			
	EndIf;
	
	If ObjectReference <> Undefined
		And ObjectReference.IsEmpty() Then
		
		ObjectReference = Undefined;
		
	EndIf;
	
	ObjectFoundBySearchFields = ObjectFound;
	
	Return ObjectReference;
	
EndFunction 

Procedure SetExchangeFileCollectionProperties(Object, ExchangeFileCollection, TypesInformation,
	ObjectParameters, RecNo, Val TabularSectionName, Val OrderFieldName)
	
	BranchName = TabularSectionName + "TabularSection";
	
	CollectionRow = ExchangeFileCollection.Add();
	CollectionRow[OrderFieldName] = RecNo;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Property" 
			Or NodeName = "ParameterValue" Then
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name    = deAttribute(ExchangeFile, StringType, "Name");
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
			
			PropertyValue = ReadProperty(PropertyType1,,, OCRName);
			
			If IsParameter Then
				
				AddComplexParameterIfNecessary(ObjectParameters, BranchName, RecNo, Name, PropertyValue);
				
			Else
				
				Try
					
					CollectionRow[Name] = PropertyValue;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WP.OCRName           = OCRName;
					WP.Object           = Object;
					WP.ObjectType       = TypeOf(Object);
					WP.Property         = "Object." + TabularSectionName + "." + Name;
					WP.Value         = PropertyValue;
					WP.ValueType      = TypeOf(PropertyValue);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "ExtDimensionDr" Or NodeName = "ExtDimensionCr" Then
			
			deSkip(ExchangeFile);
				
		ElsIf (NodeName = "Record") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Loads the table part of the object.
//
Procedure ImportTabularSection(Object, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, OCR)
	
	Var KeySearchFields;
	Var KeySearchFieldArray;
	
	Result = KeySearchFieldsByTabularSection(OCR, TabularSectionName, KeySearchFieldArray, KeySearchFields);
	
	If Not Result Then
		
		KeySearchFieldArray = New Array;
		
		MetadataObjectTabularSection = Object.Metadata().TabularSections[TabularSectionName]; // MetadataObjectTabularSection
		
		For Each Attribute In MetadataObjectTabularSection.Attributes Do
			
			KeySearchFieldArray.Add(Attribute.Name);
			
		EndDo;
		
		KeySearchFields = StrConcat(KeySearchFieldArray, ",");
		
	EndIf;
	
	UUID = StrReplace(String(New UUID), "-", "_");
	
	OrderFieldName = "SortField_[UUID]";
	OrderFieldName = StrReplace(OrderFieldName, "[UUID]", UUID);
	
	IteratorColumnName = "ПолеИтератора_[UUID]";
	IteratorColumnName = StrReplace(IteratorColumnName, "[UUID]", UUID);
	
	ObjectTabularSection = Object[TabularSectionName];
	
	ObjectCollection = ObjectTabularSection.Unload(); // ValueTable
	
	ExchangeFileCollection = ObjectCollection.CopyColumns();
	ExchangeFileCollection.Columns.Add(OrderFieldName);
	
	FillExchangeFileCollection(Object, ExchangeFileCollection, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, KeySearchFieldArray, OrderFieldName);
	
	AddColumnWithValueToTable(ExchangeFileCollection, +1, IteratorColumnName);
	AddColumnWithValueToTable(ObjectCollection,     -1, IteratorColumnName);
	
	GroupCollection = InitTableByKeyFields(KeySearchFieldArray);
	GroupCollection.Columns.Add(IteratorColumnName);
	
	FillTablePropertiesValues(ExchangeFileCollection, GroupCollection);
	FillTablePropertiesValues(ObjectCollection,     GroupCollection);
	
	GroupCollection.GroupBy(KeySearchFields, IteratorColumnName);
	
	OrderCollection = ObjectTabularSection.UnloadColumns(); // ValueTable
	OrderCollection.Columns.Add(OrderFieldName);
	
	For Each CollectionRow In GroupCollection Do
		
		// 
		Filter = New Structure();
		
		For Each FieldName In KeySearchFieldArray Do
			
			Filter.Insert(FieldName, CollectionRow[FieldName]);
			
		EndDo;
		
		OrderFieldsValues = Undefined;
		
		If CollectionRow[IteratorColumnName] = 0 Then
			
			// 
			ObjectCollectionRows = ObjectCollection.FindRows(Filter);
			
			OrderFieldsValues = ExchangeFileCollection.FindRows(Filter);
			
		Else
			
			// 
			ObjectCollectionRows = ExchangeFileCollection.FindRows(Filter);
			
		EndIf;
		
		// 
		For Each CollectionRow In ObjectCollectionRows Do
			
			OrderCollectionRow = OrderCollection.Add();
			
			FillPropertyValues(OrderCollectionRow, CollectionRow);
			
			If OrderFieldsValues <> Undefined Then
				
				OrderCollectionRow[OrderFieldName] = OrderFieldsValues[ObjectCollectionRows.Find(CollectionRow)][OrderFieldName];
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	OrderCollection.Sort(OrderFieldName);
	
	// 
	Try
		ObjectTabularSection.Load(OrderCollection);
	Except
		
		Text = NStr("en = 'Table name: %1';");
		
		WP = ExchangeProtocolRecord(83, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WP.Object     = Object;
		WP.ObjectType = TypeOf(Object);
		WP.Text = StringFunctionsClientServer.SubstituteParametersToString(Text, TabularSectionName);
		WriteToExecutionProtocol(83, WP);
		
		deSkip(ExchangeFile);
		Return;
	EndTry;
	
EndProcedure

Procedure FillTablePropertiesValues(SourceCollection, DestinationCollection)
	
	For Each CollectionItem In SourceCollection Do
		
		FillPropertyValues(DestinationCollection.Add(), CollectionItem);
		
	EndDo;
	
EndProcedure

Function InitTableByKeyFields(KeySearchFieldArray)
	
	Collection = New ValueTable;
	
	For Each FieldName In KeySearchFieldArray Do
		
		Collection.Columns.Add(FieldName);
		
	EndDo;
	
	Return Collection;
	
EndFunction

Procedure AddColumnWithValueToTable(Collection, Value, IteratorColumnName)
	
	Collection.Columns.Add(IteratorColumnName);
	Collection.FillValues(Value, IteratorColumnName);
	
EndProcedure

Procedure FillExchangeFileCollection(Object, ExchangeFileCollection, TabularSectionName, GeneralDocumentTypeInformation, ObjectParameters, KeySearchFieldArray, OrderFieldName)
	
	BranchName = TabularSectionName + "TabularSection";
	
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[BranchName];
	Else
		TypesInformation = Undefined;
	EndIf;
	
	RecNo = 0;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Record" Then
			
			SetExchangeFileCollectionProperties(Object, ExchangeFileCollection, TypesInformation, ObjectParameters, RecNo, TabularSectionName, OrderFieldName);
			
			RecNo = RecNo + 1;
			
		ElsIf (NodeName = "TabularSection") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function KeySearchFieldsByTabularSection(OCR, TabularSectionName, KeySearchFieldArray, KeySearchFields)
	
	If OCR = Undefined Then
		Return False;
	EndIf;
	
	SearchDataInTS = OCR.SearchInTabularSections.Find("TabularSection." + TabularSectionName, "TagName");
	
	If SearchDataInTS = Undefined Then
		Return False;
	EndIf;
	
	If Not SearchDataInTS.Valid Then
		Return False;
	EndIf;
	
	KeySearchFieldArray = SearchDataInTS.KeySearchFieldArray;
	KeySearchFields        = SearchDataInTS.KeySearchFields;
	
	Return True;

EndFunction

// Loads the movement of an object
//
// Parameters:
//  Object         - 
//  Name            - register name.
//  Clear       - 
// 
Procedure ImportRegisterRecords(Object, Name, Clear, GeneralDocumentTypeInformation, 
	ObjectParameters, Rule)
	
	RegisterRecordName = Name + "RecordSet";
	If GeneralDocumentTypeInformation <> Undefined Then
		TypesInformation = GeneralDocumentTypeInformation[RegisterRecordName];
	Else
	    TypesInformation = Undefined;
	EndIf;
	
	SearchDataInTS = Undefined;
	
	TSCopyForSearch = Undefined;
	
	RegisterRecords = Object.RegisterRecords[Name];
	
	RegisterRecords.Read();
	RegisterRecords.Write = True;

	If Clear
		And RegisterRecords.Count() <> 0 Then
		
		If SearchDataInTS <> Undefined Then 
			TSCopyForSearch = RegisterRecords.Unload();
		EndIf;
		
        RegisterRecords.Clear();
		
	ElsIf SearchDataInTS <> Undefined Then
		
		TSCopyForSearch = RegisterRecords.Unload();	
		
	EndIf;
	
	RecNo = 0;
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
			
		If      NodeName = "Record" Then
			
			Record = RegisterRecords.Add();
			SetRecordProperties(Record, TypesInformation, ObjectParameters, RegisterRecordName, RecNo, SearchDataInTS, TSCopyForSearch);
			
			RecNo = RecNo + 1;
			
		ElsIf (NodeName = "RecordSet") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Sets the properties of the object (record).
//
// Parameters:
//  Record         - 
//                   
//
Procedure SetRecordProperties(Record, TypesInformation, 
	ObjectParameters, BranchName, RecNo,
	SearchDataInTS = Undefined, TSCopyForSearch = Undefined)
	
	MustSearchInTS = (SearchDataInTS <> Undefined)
								And (TSCopyForSearch <> Undefined)
								And TSCopyForSearch.Count() <> 0;
								
	If MustSearchInTS Then
									
		PropertyReadingStructure = New Structure();
		ExtDimensionReadingStructure = New Structure();
		
	EndIf;
		
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property"
			Or NodeName = "ParameterValue" Then
			
			
			IsParameter = (NodeName = "ParameterValue");
			
			Name    = deAttribute(ExchangeFile, StringType, "Name");
			OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
			
			If Name = "RecordType" And StrFind(Metadata.FindByType(TypeOf(Record)).FullName(), "AccumulationRegister") Then
				
				PropertyType1 = AccumulationRecordTypeType;
				
			Else
				
				PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
				
			EndIf;
			
			PropertyValue = ReadProperty(PropertyType1,,, OCRName);
			
			If IsParameter Then
				AddComplexParameterIfNecessary(ObjectParameters, BranchName, RecNo, Name, PropertyValue);			
			ElsIf MustSearchInTS Then 
				PropertyReadingStructure.Insert(Name, PropertyValue);	
			Else
				
				Try
					
					Record[Name] = PropertyValue;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WP.OCRName           = OCRName;
					WP.Object           = Record;
					WP.ObjectType       = TypeOf(Record);
					WP.Property         = Name;
					WP.Value         = PropertyValue;
					WP.ValueType      = TypeOf(PropertyValue);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "ExtDimensionDr" Or NodeName = "ExtDimensionCr" Then
			
			// 
			
			Var_Key = Undefined;
			Value = Undefined;
			
			While ExchangeFile.Read() Do
				
				NodeName = ExchangeFile.LocalName;
								
				If NodeName = "Property" Then
					
					Name    = deAttribute(ExchangeFile, StringType, "Name");
					OCRName = deAttribute(ExchangeFile, StringType, "OCRName");
					
					PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
										
					If Name = "Key" Then
						
						Var_Key = ReadProperty(PropertyType1);
						
					ElsIf Name = "Value" Then
						
						Value = ReadProperty(PropertyType1,,, OCRName);
						
					EndIf;
					
				ElsIf (NodeName = "ExtDimensionDr" Or NodeName = "ExtDimensionCr") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
					
					Break;
					
				Else
					
					WriteToExecutionProtocol(9);
					Break;
					
				EndIf;
				
			EndDo;
			
			If Var_Key <> Undefined 
				And Value <> Undefined Then
				
				If Not MustSearchInTS Then
				
					Record[NodeName][Var_Key] = Value;
					
				Else
					
					RecordMap = Undefined;
					If Not ExtDimensionReadingStructure.Property(NodeName, RecordMap) Then
						RecordMap = New Map;
						ExtDimensionReadingStructure.Insert(NodeName, RecordMap);
					EndIf;
					
					RecordMap.Insert(Var_Key, Value);
					
				EndIf;
				
			EndIf;
				
		ElsIf (NodeName = "Record") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	If MustSearchInTS Then
		
		TheStructureOfTheSearch = New Structure();
		
		For Each SearchItem In  SearchDataInTS.TSSearchFields Do
			
			ElementValue = Undefined;
			PropertyReadingStructure.Property(SearchItem, ElementValue);
			
			TheStructureOfTheSearch.Insert(SearchItem, ElementValue);		
			
		EndDo;		
		
		SearchResultArray = TSCopyForSearch.FindRows(TheStructureOfTheSearch);
		
		FoundRecord = SearchResultArray.Count() > 0;
		If FoundRecord Then
			FillPropertyValues(Record, SearchResultArray[0]);
		EndIf;
		
		// 
		For Each KeyAndValue In PropertyReadingStructure Do
			
			Record[KeyAndValue.Key] = KeyAndValue.Value;
			
		EndDo;
		
		For Each ItemName In ExtDimensionReadingStructure Do
			
			For Each ItemKey1 In ItemName.Value Do
			
				Record[ItemName.Key][ItemKey1.Key] = ItemKey1.Value;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Loads an object of the type Descriptiontype type from the specified xml source.
//
// Parameters:
//  Source         - xml-source.
// 
Function ImportObjectTypes(Source)
	
	// DateQualifiers
	
	DateComposition =  deAttribute(Source, StringType,  "DateComposition");
	
	// StringQualifiers
	
	Length           =  deAttribute(Source, NumberType,  "Length");
	Var_AllowedLength =  deAttribute(Source, StringType, "AllowedLength");
	
	// NumberQualifiers
	
	Digits             = deAttribute(Source, NumberType,  "Digits");
	FractionDigits = deAttribute(Source, NumberType,  "FractionDigits");
	AllowedFlag          = deAttribute(Source, StringType, "AllowedSign");
	
	// 
	
	TypesArray = New Array;
	
	While Source.Read() Do
		NodeName = Source.LocalName;
		
		If      NodeName = "Type" Then
			TypesArray.Add(Type(deElementValue(Source, StringType)));
		ElsIf (NodeName = "Types") And ( Source.NodeType = XMLNodeTypeEndElement) Then
			Break;
		Else
			WriteToExecutionProtocol(9);
			Break;
		EndIf;
		
	EndDo;
	
	If TypesArray.Count() > 0 Then
		
		// DateQualifiers
		
		If DateComposition = "Date" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Date);
		ElsIf DateComposition = "DateTime" Then
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		ElsIf DateComposition = "Time" Then
			DateQualifiers   = New DateQualifiers(DateFractions.Time);
		Else
			DateQualifiers   = New DateQualifiers(DateFractions.DateTime);
		EndIf;
		
		// NumberQualifiers
		
		If Digits > 0 Then
			If AllowedFlag = "Nonnegative" Then
				Character = AllowedSign.Nonnegative;
			Else
				Character = AllowedSign.Any;
			EndIf; 
			NumberQualifiers  = New NumberQualifiers(Digits, FractionDigits, Character);
		Else
			NumberQualifiers  = New NumberQualifiers();
		EndIf;
		
		// StringQualifiers
		
		If Length > 0 Then
			If Var_AllowedLength = "Fixed" Then
				Var_AllowedLength = AllowedLength.Fixed;
			Else
				Var_AllowedLength = AllowedLength.Variable;
			EndIf;
			StringQualifiers = New StringQualifiers(Length, Var_AllowedLength);
		Else
			StringQualifiers = New StringQualifiers();
		EndIf; 
		
		Return New TypeDescription(TypesArray, NumberQualifiers, StringQualifiers, DateQualifiers);
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure WriteDocumentInSafeMode(Document, ObjectType)
	
	If Document.Posted Then
						
		Document.Posted = False;
			
	EndIf;		
								
	WriteObjectToIB(Document, ObjectType);	
	
EndProcedure

Function ObjectByRefAndAddInformation(CreatedObject, Ref)
	
	// 
	If CreatedObject <> Undefined Then
		
		Object = CreatedObject;
		
	ElsIf Ref = Undefined Then
		
		Object = Undefined;
		
	ElsIf Ref.IsEmpty() Then
		
		Object = Undefined;
		
	Else
		
		Object = Ref.GetObject();
		
	EndIf;
	
	Return Object;
EndFunction

Procedure ObjectImportComments(NBSp, RuleName, Source, ObjectType, Gsn = 0)
	
	If CommentObjectProcessingFlag Then
		
		MessageString = NStr("en = 'Importing object #%1';");
		Number = ?(NBSp <> 0, NBSp, Gsn);
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Number);
		
		WP = ExchangeProtocolRecord();
		
		If Not IsBlankString(RuleName) Then
			
			WP.OCRName = RuleName;
			
		EndIf;
		
		If Not IsBlankString(Source) Then
			
			WP.Source = Source;
			
		EndIf;
		
		WP.ObjectType = ObjectType;
		WriteToExecutionProtocol(MessageString, WP, False);
		
	EndIf;	
	
EndProcedure

Procedure AddParameterIfNecessary(DataParameters, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	DataParameters.Insert(ParameterName, ParameterValue);
	
EndProcedure

Procedure AddComplexParameterIfNecessary(DataParameters, ParameterBranchName, LineNumber, ParameterName, ParameterValue)
	
	If DataParameters = Undefined Then
		DataParameters = New Map;
	EndIf;
	
	CurrentParameterData = DataParameters[ParameterBranchName];
	
	If CurrentParameterData = Undefined Then
		
		CurrentParameterData = New ValueTable;
		CurrentParameterData.Columns.Add("LineNumber");
		CurrentParameterData.Columns.Add("ParameterName");
		CurrentParameterData.Indexes.Add("LineNumber");
		
		DataParameters.Insert(ParameterBranchName, CurrentParameterData);	
		
	EndIf;
	
	If CurrentParameterData.Columns.Find(ParameterName) = Undefined Then
		CurrentParameterData.Columns.Add(ParameterName);
	EndIf;		
	
	RowData = CurrentParameterData.Find(LineNumber, "LineNumber");
	If RowData = Undefined Then
		RowData = CurrentParameterData.Add();
		RowData.LineNumber = LineNumber;
	EndIf;		
	
	RowData[ParameterName] = ParameterValue;
	
EndProcedure

Function ReadObjectChangeRecordInfo()
	
	// 
	DestinationUUID = deAttribute(ExchangeFile, StringType, "SourceUUID");
	SourceUUID = deAttribute(ExchangeFile, StringType, "DestinationUUID");
	DestinationType                     = deAttribute(ExchangeFile, StringType, "SourceType");
	SourceType                     = deAttribute(ExchangeFile, StringType, "DestinationType");
	IsEmptySet                      = deAttribute(ExchangeFile, BooleanType, "IsEmptySet");
	
	Try
		SourceUUID = New UUID(SourceUUID);
	Except
		
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
		
	EndTry;
	
	// 
	Try
		PropertyStructure = Managers[Type(SourceType)];
	Except
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
	EndTry;
	
	// 
	SourceUUID = PropertyStructure.Manager.GetRef(SourceUUID);
	
	// 
	If Not ValueIsFilled(SourceUUID) Then
		deSkip(ExchangeFile, "ObjectRegistrationInformation");
		Return Undefined;
	EndIf;
	
	RecordSet = ObjectMapsRegisterManager.CreateRecordSet(); // InformationRegisterRecordSet.InfobaseObjectsMaps
	
	// 
	RecordSet.Filter.InfobaseNode.Set(ExchangeNodeDataImport);
	RecordSet.Filter.SourceUUID.Set(SourceUUID);
	RecordSet.Filter.DestinationUUID.Set(DestinationUUID);
	RecordSet.Filter.SourceType.Set(SourceType);
	RecordSet.Filter.DestinationType.Set(DestinationType);
	
	If Not IsEmptySet Then
		
		// 
		SetRow = RecordSet.Add();
		
		SetRow.InfobaseNode           = ExchangeNodeDataImport;
		SetRow.SourceUUID = SourceUUID;
		SetRow.DestinationUUID = DestinationUUID;
		SetRow.SourceType                     = SourceType;
		SetRow.DestinationType                     = DestinationType;
		
	EndIf;
	
	// 
	WriteObjectToIB(RecordSet, "InformationRegisterRecordSet.InfobaseObjectsMaps");
	
	deSkip(ExchangeFile, "ObjectRegistrationInformation");
	
	Return RecordSet;
	
EndFunction

Procedure ExportMappingInfoAdjustment()
	
	ConversionRules = ConversionRulesTable.Copy(New Structure("SynchronizeByID", True), "SourceType, DestinationType");
	ConversionRules.GroupBy("SourceType, DestinationType");
	
	For Each Rule In ConversionRules Do
		
		Manager = Managers.Get(Type(Rule.SourceType)).Manager; // 
		
		If TypeOf(Manager) = Type("BusinessProcessRoutePoints") Then
			Continue;
		EndIf;
		
		If Manager <> Undefined Then
			
			Selection = Manager.Select();
			
			While Selection.Next() Do
				
				UUID = String(Selection.Ref.UUID());
				
				Receiver = CreateNode("ObjectRegistrationDataAdjustment");
				
				SetAttribute(Receiver, "UUID", UUID);
				SetAttribute(Receiver, "SourceType",            Rule.SourceType);
				SetAttribute(Receiver, "DestinationType",            Rule.DestinationType);
				
				Receiver.WriteEndElement(); // ObjectRegistrationDataAdjustment
				
				WriteToFile(Receiver);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadMappingInfoAdjustment()
	
	// 
	UUID = deAttribute(ExchangeFile, StringType, "UUID");
	DestinationType            = deAttribute(ExchangeFile, StringType, "SourceType");
	SourceType            = deAttribute(ExchangeFile, StringType, "DestinationType");
	
	DestinationUUID = UUID;
	SourceUUID = UUID;
	
	InfobaseObjectsMapQuery.SetParameter("InfobaseNode", ExchangeNodeDataImport);
	InfobaseObjectsMapQuery.SetParameter("DestinationUUID", DestinationUUID);
	InfobaseObjectsMapQuery.SetParameter("DestinationType", DestinationType);
	InfobaseObjectsMapQuery.SetParameter("SourceType", SourceType);
	
	QueryResult = InfobaseObjectsMapQuery.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Return; // 
	EndIf;
	
	Try
		UUID = SourceUUID;
		SourceUUID = New UUID(SourceUUID);
	Except
		Return;
	EndTry;
	
	// 
	PropertyStructure = Managers[Type(SourceType)];
	
	// 
	SourceUUID = PropertyStructure.Manager.GetRef(SourceUUID);
	
	Object = SourceUUID.GetObject();
	
	If Object = Undefined Then
		Return; // 
	EndIf;
	
	// 
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", ExchangeNodeDataImport);
	RecordStructure.Insert("SourceUUID", SourceUUID);
	RecordStructure.Insert("DestinationUUID", DestinationUUID);
	RecordStructure.Insert("DestinationType",                     DestinationType);
	RecordStructure.Insert("SourceType",                     SourceType);
	
	InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure);
	
	IncreaseImportedObjectCounter();
	
EndProcedure

Function ReadRegisterRecordSet()
	
	// 
	Var Ref,ObjectFound, DontReplaceObject, WriteMode, PostingMode, GenerateNewNumberOrCodeIfNotSet, ObjectIsModified;
	
	NBSp						= deAttribute(ExchangeFile, NumberType,  "NBSp");
	RuleName				= deAttribute(ExchangeFile, StringType, "RuleName");
	ObjectTypeString       = deAttribute(ExchangeFile, StringType, "Type");
	ExchangeObjectPriority  = ExchangeObjectPriority(ExchangeFile);
	
	IsEmptySet			= deAttribute(ExchangeFile, BooleanType, "IsEmptySet");
	If Not ValueIsFilled(IsEmptySet) Then
		IsEmptySet = False;
	EndIf;
	
	ObjectType 				= Type(ObjectTypeString);
	Source 				= Undefined;
	SearchProperties 			= Undefined;
	
	ObjectImportComments(NBSp, RuleName, Undefined, ObjectType);
	
	RegisterRowTypeName = StrReplace(ObjectTypeString, "InformationRegisterRecordSet.", "InformationRegisterRecord.");
	RegisterName = StrReplace(ObjectTypeString, "InformationRegisterRecordSet.", "");
	
	RegisterSetRowType = Type(RegisterRowTypeName);
	
	PropertyStructure = Managers[RegisterSetRowType];
	ObjectTypeName   = PropertyStructure.TypeName;
	
	TypesInformation = DataForImportTypeMap()[RegisterSetRowType];
	
	Object          = Undefined;
		
	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		HasBeforeImportHandler = Rule.HasBeforeImportHandler;
		HasOnImportHandler    = Rule.HasOnImportHandler;
		HasAfterImportHandler  = Rule.HasAfterImportHandler;
		
	Else
		
		HasBeforeImportHandler = False;
		HasOnImportHandler    = False;
		HasAfterImportHandler  = False;
		
	EndIf;

    // 
	
	If HasBeforeImportObjectGlobalHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeImportObject(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
																	  GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																	  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Conversion.BeforeImportObject);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(53, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				RuleName, Source, 
			ObjectType, Undefined, NStr("en = 'BeforeImportObject (global)';"));
			
		EndTry;
		
		If Cancel Then	//	
			
			deSkip(ExchangeFile, "RegisterRecordSet");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	
	// 
	If HasBeforeImportHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteOCRHandlerBeforeObjectImport(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
															  GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
															  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Rule.BeforeImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(19, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				RuleName, Source, ObjectType, Undefined, "BeforeImportObject");
			
		EndTry;
		
		If Cancel Then // 
			
			deSkip(ExchangeFile, "RegisterRecordSet");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	FilterReadMode = False;
	RecordReadingMode = False;
	
	RegisterFilter = Undefined;
	CurrentRecordSetRow = Undefined;
	ObjectParameters = Undefined;
	RecordSetParameters = Undefined;
	RecNo = -1;
	
	// 
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Filter" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
					
				Object = InformationRegisters[RegisterName].CreateRecordSet();
				RegisterFilter = Object.Filter;
			
				FilterReadMode = True;
					
			EndIf;			
		
		ElsIf NodeName = "Property"
			Or NodeName = "ParameterValue" Then
			
			IsParameterForObject = (NodeName = "ParameterValue");
			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "NotReplace");
			OCRName             = deAttribute(ExchangeFile, StringType, "OCRName");
			
			// 
			PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
			PropertyNotFoundByRef = False;
			
			// 
			Value = ReadProperty(PropertyType1, IsEmptySet, PropertyNotFoundByRef, OCRName);
			
			If IsParameterForObject Then
				
				If FilterReadMode Then
					AddParameterIfNecessary(RecordSetParameters, Name, Value);
				Else
					// 
					AddParameterIfNecessary(ObjectParameters, Name, Value);
					AddComplexParameterIfNecessary(RecordSetParameters, "Rows", RecNo, Name, Value);
				EndIf;
				
			Else
 				
				Try
					
					If FilterReadMode Then
						DataExchangeInternal.SetFilterItemValue(RegisterFilter, Name, Value);
					ElsIf RecordReadingMode Then
						CurrentRecordSetRow[Name] = Value;
					EndIf;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WP.OCRName           = RuleName;
					WP.Source         = Source;
					WP.Object           = Object;
					WP.ObjectType       = ObjectType;
					WP.Property         = Name;
					WP.Value         = Value;
					WP.ValueType      = TypeOf(Value);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "RecordSetRows" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
				
				// 
				// 
				If FilterReadMode = True
					And HasOnImportHandler Then
					
					Try
						
						If ImportHandlersDebug Then
							
							ExecuteOCRHandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
							RuleName, Source, ObjectType, Object, "OnImportObject");
						
					EndTry;
					
				EndIf;
				
				FilterReadMode = False;
				RecordReadingMode = True;
				
			EndIf;
			
		ElsIf NodeName = "Object" Then
			
			If ExchangeFile.NodeType <> XMLNodeTypeEndElement Then
			
				CurrentRecordSetRow = Object.Add();	
			    RecNo = RecNo + 1;
				
			EndIf;
			
		ElsIf NodeName = "RegisterRecordSet" And ExchangeFile.NodeType = XMLNodeTypeEndElement Then
			
			Break;
						
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	// 
	Cancel = False;
	If HasAfterImportHandler Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteOCRHandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
															 ObjectIsModified, ObjectTypeName, ObjectFound, Rule);
				
			Else
				
				Execute(Rule.AfterImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(21, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				RuleName, Source, ObjectType, Object, "AfterImportObject");
			
		EndTry;
		
	EndIf;
	
	If Cancel Then
		Return Undefined;
	EndIf;
	
	If Object <> Undefined Then
		
		ItemReceive = DataItemReceive.Auto;
		SendBack = False;
		
		Object.AdditionalProperties.Insert("DataExchange", New Structure("DataAnalysis", Not DataImportToInfobaseMode()));
		
		If ExchangeObjectPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
			StandardSubsystemsServer.OnReceiveDataFromSlave(Object, ItemReceive, SendBack, ExchangeNodeDataImportObject);
		Else
			StandardSubsystemsServer.OnReceiveDataFromMaster(Object, ItemReceive, SendBack, ExchangeNodeDataImportObject);
		EndIf;
		
		If ItemReceive = DataItemReceive.Ignore Then
			Return Undefined;
		EndIf;
		
		WriteObjectToIB(Object, ObjectType);
		
	EndIf;
	
	Return Object;
	
EndFunction

Procedure SupplementNotWrittenObjectStack(NumberForStack, Object, KnownRef, ObjectType, TypeName, GenerateCodeAutomatically = False, ObjectParameters = Undefined)
	
	StackString = GlobalNotWrittenObjectStack[NumberForStack];
	If StackString <> Undefined Then
		Return;
	EndIf;
	ParametersStructure = New Structure();
	ParametersStructure.Insert("Object",Object);
	ParametersStructure.Insert("KnownRef",KnownRef);
	ParametersStructure.Insert("ObjectType", ObjectType);
	ParametersStructure.Insert("TypeName", TypeName);
	ParametersStructure.Insert("GenerateCodeAutomatically", GenerateCodeAutomatically);
	ParametersStructure.Insert("ObjectParameters", ObjectParameters);

	GlobalNotWrittenObjectStack.Insert(NumberForStack, ParametersStructure);
	
EndProcedure

Procedure DeleteFromNotWrittenObjectStack(NBSp, Gsn)
	
	NumberForStack = ?(NBSp = 0, Gsn, NBSp);
	GlobalNotWrittenObjectStack.Delete(NumberForStack);
	
EndProcedure

Procedure ExecuteWriteNotWrittenObjects()
	
	For Each DataString1 In GlobalNotWrittenObjectStack Do
		
		// 
		Object = DataString1.Value.Object;
		
		If DataString1.Value.GenerateCodeAutomatically = True Then
			
			ExecuteNumberCodeGenerationIfNecessary(True, Object,
				DataString1.Value.TypeName, True);
			
		EndIf;
		
		WriteObjectToIB(Object, DataString1.Value.ObjectType);
		
	EndDo;
	
	GlobalNotWrittenObjectStack.Clear();
	
EndProcedure

Procedure ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, ObjectTypeName, 
	DataExchangeMode1)
	
	If Not GenerateNewNumberOrCodeIfNotSet
		Or Not DataExchangeMode1 Then
		
		// 
		// 
		Return;
	EndIf;
	
	// 
	If ObjectTypeName = "Document"
		Or ObjectTypeName =  "BusinessProcess"
		Or ObjectTypeName = "Task" Then
		
		If Not ValueIsFilled(Object.Number) Then
			
			Object.SetNewNumber();
			
		EndIf;
		
	ElsIf ObjectTypeName = "Catalog"
		Or ObjectTypeName = "ChartOfCharacteristicTypes"
		Or ObjectTypeName = "ExchangePlan" Then
		
		If Not ValueIsFilled(Object.Code) Then
			
			Object.SetNewCode();
			
		EndIf;	
		
	EndIf;
	
EndProcedure

Function ExchangeObjectPriority(ExchangeFile)
		
	PriorityString = deAttribute(ExchangeFile, StringType, "ExchangeObjectPriority");
	If IsBlankString(PriorityString) Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	ElsIf PriorityString = "Above" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority;
	ElsIf PriorityString = "Below" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority;
	ElsIf PriorityString = "Matches" Then
		PriorityValue = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch;
	EndIf;
	
	Return PriorityValue;
	
EndFunction

// Reads the next object from the exchange file and loads it.
//
// Parameters:
//  No.
// 
Function ReadObject(UUIDAsString1 = "")

	NBSp						= deAttribute(ExchangeFile, NumberType,  "NBSp");
	Gsn					= deAttribute(ExchangeFile, NumberType,  "Gsn");
	Source				= deAttribute(ExchangeFile, StringType, "Source");
	RuleName				= deAttribute(ExchangeFile, StringType, "RuleName");
	DontReplaceObject 		= deAttribute(ExchangeFile, BooleanType, "NotReplace");
	AutonumberingPrefix	= deAttribute(ExchangeFile, StringType, "AutonumberingPrefix");
	ExchangeObjectPriority  = ExchangeObjectPriority(ExchangeFile);
	
	ObjectTypeString       = deAttribute(ExchangeFile, StringType, "Type");
	ObjectType 				= Type(ObjectTypeString);
	TypesInformation = DataForImportTypeMap()[ObjectType];
	
	ObjectImportComments(NBSp, RuleName, Source, ObjectType, Gsn);
	
	PropertyStructure = Managers[ObjectType];
	ObjectTypeName   = PropertyStructure.TypeName;
	
	// 
	// 
	//
	DeferredMotionRecordingTables = New Map;
	
	If ObjectTypeName = "Document" Then
		
		WriteMode     = deAttribute(ExchangeFile, StringType, "WriteMode");
		PostingMode = deAttribute(ExchangeFile, StringType, "PostingMode");
		
	EndIf;
	
	Object          = Undefined; // 
	ObjectFound    = True;
	ObjectCreatedInCurrentInfobase = Undefined;
	
	SearchProperties  = New Map;
	SearchPropertiesDontReplace  = New Map;
	
	If Not IsBlankString(RuleName) Then
		
		Rule = Rules[RuleName];
		HasBeforeImportHandler = Rule.HasBeforeImportHandler;
		HasOnImportHandler    = Rule.HasOnImportHandler;
		HasAfterImportHandler  = Rule.HasAfterImportHandler;
		GenerateNewNumberOrCodeIfNotSet = Rule.GenerateNewNumberOrCodeIfNotSet;
		DontReplaceObjectCreatedInDestinationInfobase =  Rule.DontReplaceObjectCreatedInDestinationInfobase;
		
	Else
		
		HasBeforeImportHandler = False;
		HasOnImportHandler    = False;
		HasAfterImportHandler  = False;
		GenerateNewNumberOrCodeIfNotSet = False;
		DontReplaceObjectCreatedInDestinationInfobase = False;
		
	EndIf;


	// 
	
	If HasBeforeImportObjectGlobalHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeImportObject(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
																	  GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																	  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Conversion.BeforeImportObject);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(53, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				RuleName, Source, ObjectType, Undefined, NStr("en = 'BeforeImportObject (global)';"));
				
		EndTry;
				
		If Cancel Then	//	
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;
	
	
	// 
	If HasBeforeImportHandler Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteOCRHandlerBeforeObjectImport(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
															  GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
															  ObjectType, DontReplaceObject, WriteMode, PostingMode);
				
			Else
				
				Execute(Rule.BeforeImport);
				
			EndIf;
			
		Except
			
			WriteInfoOnOCRHandlerImportError(19, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				RuleName, Source, ObjectType, Undefined, "BeforeImportObject");
			
		EndTry;
		
		If Cancel Then // 
			
			deSkip(ExchangeFile, "Object");
			Return Undefined;
			
		EndIf;
		
	EndIf;

	ConstantOperatingMode = False;
	ConstantName = "";
	
	GlobalRefSn = 0;
	RefSN = 0;
	ObjectParameters = Undefined;
	RecordSet = Undefined;
	WriteObject = True;
	
	// 
	// 
	// 
	ObjectFoundBySearchFields = False;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
				
		If NodeName = "Property"
			Or NodeName = "ParameterValue" Then
			
			IsParameterForObject = (NodeName = "ParameterValue");
			
			If Object = Undefined Then
				
				// 
				ObjectFound = False;
				
				// 
				If HasOnImportHandler Then
					ObjectIsModified = True;
					// 
					Try
						
						If ImportHandlersDebug Then
							
							ExecuteOCRHandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
							RuleName, Source, ObjectType, Object, "OnImportObject");
						
					EndTry;
					
				EndIf;
				
				// 
				If Object = Undefined Then
					
					If ObjectTypeName = "Constants" Then
						
						Object = Undefined;
						ConstantOperatingMode = True;
												
					Else
						
						CreateNewObject(ObjectType, SearchProperties, Object, False, , ,RecordSet);
																	
					EndIf;
					
				EndIf;
				
			EndIf; 

			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "NotReplace");
			OCRName             = deAttribute(ExchangeFile, StringType, "OCRName");
			
			If ConstantOperatingMode Then
				
				Object = Constants[Name].CreateValueManager();	
				ConstantName = Name;
				Name = "Value";
				
			ElsIf Not IsParameterForObject
				And ((ObjectFound And DontReplaceProperty) 
				Or (Name = "IsFolder") 
				Or (Object[Name] = NULL)) Then
				
				// 
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf; 

			
			// 
			PropertyType1 = PropertyTypeByAdditionalData(TypesInformation, Name);
			Value    = ReadProperty(PropertyType1,,, OCRName);
			
			If IsParameterForObject Then
				
				// 
				AddParameterIfNecessary(ObjectParameters, Name, Value);
				
			Else
				
				Try
					
					Object[Name] = Value;
					
				Except
					
					WP = ExchangeProtocolRecord(26, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WP.OCRName           = RuleName;
					WP.NBSp              = NBSp;
					WP.Gsn             = Gsn;
					WP.Source         = Source;
					WP.Object           = Object;
					WP.ObjectType       = ObjectType;
					WP.Property         = Name;
					WP.Value         = Value;
					WP.ValueType      = TypeOf(Value);
					ErrorMessageString = WriteToExecutionProtocol(26, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "Ref" Then
			
			// 
			InfobaseObjectsMaps = Undefined;
			CreatedObject = Undefined;
			DontCreateObjectIfNotFound = Undefined;
			KnownUUIDRef = Undefined;
			DontReplaceObjectCreatedInDestinationInfobase = False;
			RecordObjectChangeAtSenderNode = False;
												
			Ref = FindObjectByRef(ObjectType,
										SearchProperties,
										SearchPropertiesDontReplace,
										ObjectFound,
										CreatedObject,
										DontCreateObjectIfNotFound,
										True,
										GlobalRefSn,
										RefSN,
										ObjectFoundBySearchFields,
										KnownUUIDRef,
										True,
										ObjectParameters,
										DontReplaceObjectCreatedInDestinationInfobase,
										ObjectCreatedInCurrentInfobase,
										RecordObjectChangeAtSenderNode,
										UUIDAsString1,
										RuleName,
										InfobaseObjectsMaps);
				
			If ObjectTypeName = "Enum" Then
				
				Object = Ref;
				
			Else
				
				Object = ObjectByRefAndAddInformation(CreatedObject, Ref);
				
				If Object = Undefined Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
				If ObjectFound And DontReplaceObject And (Not HasOnImportHandler) Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
				If Ref = Undefined Then
					
					NumberForStack = ?(NBSp = 0, Gsn, NBSp);
					SupplementNotWrittenObjectStack(NumberForStack, CreatedObject, KnownUUIDRef, ObjectType, 
						ObjectTypeName, Rule.GenerateNewNumberOrCodeIfNotSet, ObjectParameters);
					
				EndIf;
				
			EndIf;
			
			// 
			If HasOnImportHandler Then
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteOCRHandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
						
					Else
						
						Execute(Rule.OnImport);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(20, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
						RuleName, Source, ObjectType, Object, "OnImportObject");
					
				EndTry;
				
				If ObjectFound And DontReplaceObject Then
					
					deSkip(ExchangeFile, "Object");
					Break;
					
				EndIf;
				
			EndIf;
			
			If RecordObjectChangeAtSenderNode = True Then
				Object.AdditionalProperties.Insert("RecordObjectChangeAtSenderNode");
			EndIf;
			
			Object.AdditionalProperties.Insert("InfobaseObjectsMaps", InfobaseObjectsMaps);
			
		ElsIf NodeName = "TabularSection"
			  Or NodeName = "RecordSet" Then
			//
			
			If DataImportToValueTableMode()
				And ObjectTypeName <> "ExchangePlan" Then
				deSkip(ExchangeFile, NodeName);
				Continue;
			EndIf;
			
			If Object = Undefined Then
				
				ObjectFound = False;
				
				// 
				
				If HasOnImportHandler Then
					
					Try
						
						If ImportHandlersDebug Then
							
							ExecuteOCRHandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule);
							
						Else
							
							Execute(Rule.OnImport);
							
						EndIf;
						
					Except
						
						WriteInfoOnOCRHandlerImportError(20, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
							RuleName, Source, ObjectType, Object, "OnImportObject");
						
					EndTry;
						
				EndIf;
				 
			EndIf;
			
			Name                = deAttribute(ExchangeFile, StringType, "Name");
			DontReplaceProperty = deAttribute(ExchangeFile, BooleanType, "NotReplace");
			NotClear          = deAttribute(ExchangeFile, BooleanType, "NotClear");

			If ObjectFound And DontReplaceProperty Then
				
				deSkip(ExchangeFile, NodeName);
				Continue;
				
			EndIf;
			
			If Object = Undefined Then
					
				CreateNewObject(ObjectType, SearchProperties, Object, False);
									
			EndIf;
						
			If NodeName = "TabularSection" Then
				
				If LoadingTabularPartIsSupported(Object, Name) = True Then
					
					// 
					ImportTabularSection(Object, Name, TypesInformation, ObjectParameters, Rule);
					
				EndIf;
				
			ElsIf NodeName = "RecordSet" Then
				
				// 
				ImportRegisterRecords(Object, Name, Not NotClear, TypesInformation, ObjectParameters, Rule);
				
				// 
				If Metadata.AccountingRegisters.Find(Name) <> Undefined Then
				
					LoadedRegisteredRecords = Object.RegisterRecords[Name].Unload();
					If LoadedRegisteredRecords.Count() > 0 Then
						
						// 
						// 
						// 
						EliminateErrorOfAssigningTypeOfSubconto(LoadedRegisteredRecords);
						
						DeferredMotionRecordingTables.Insert(Name, LoadedRegisteredRecords);
						Object.RegisterRecords[Name].Clear();
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		ElsIf (NodeName = "Object") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Cancel = False;
			
			// 
			If HasAfterObjectImportGlobalHandler Then
				
				ObjectIsModified = True;
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteHandlerConversionAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
																			 ObjectIsModified, ObjectTypeName, ObjectFound);
						
					Else
						
						Execute(Conversion.AfterImportObject);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(54, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
						RuleName, Source, ObjectType, Object, NStr("en = 'AfterImportObject (global)';"));
					
				EndTry;
				
			EndIf;
			
			// 
			If HasAfterImportHandler Then
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteOCRHandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
																	 ObjectIsModified, ObjectTypeName, ObjectFound, Rule);
						
					Else
						
						Execute(Rule.AfterImport);
						
					EndIf;
					
				Except
					
					WriteInfoOnOCRHandlerImportError(21, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
						RuleName, Source, ObjectType, Object, "AfterImportObject");
					
				EndTry;
				
			EndIf;
			
			ItemReceive = DataItemReceive.Auto;
			SendBack = False;
			
			CurObject = Object;
			If ObjectTypeName = "InformationRegister" Then
				CurObject = RecordSet;
			EndIf;
			If CurObject <> Undefined Then
				If ObjectTypeName <> "Enum"
					And ObjectTypeName <> "Constants" Then
					CurObject.AdditionalProperties.Insert("DataExchange", New Structure("DataAnalysis", Not DataImportToInfobaseMode()));
				EndIf;
				
				If ExchangeObjectPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
					StandardSubsystemsServer.OnReceiveDataFromSlave(CurObject, ItemReceive, SendBack, ExchangeNodeDataImportObject);
				Else
					StandardSubsystemsServer.OnReceiveDataFromMaster(CurObject, ItemReceive, SendBack, ExchangeNodeDataImportObject);
				EndIf;
			EndIf;
			
			If ItemReceive = DataItemReceive.Ignore Then
				Cancel = True;
			EndIf;
			
			If Cancel Then
				DeleteFromNotWrittenObjectStack(NBSp, Gsn);
				Return Undefined;
			EndIf;
			
			If ObjectTypeName = "Document" Then
				
				If WriteMode = "Posting" Then
					
					WriteMode = DocumentWriteMode.Posting;
					
				ElsIf WriteMode = "UndoPosting" Then
					
					WriteMode = DocumentWriteMode.UndoPosting; 
					
				ElsIf WriteMode = "Record" Then
					
					WriteMode = DocumentWriteMode.Write;	
					
				Else
					
					// 
					If Object.Posted Then
						
						WriteMode = DocumentWriteMode.Posting;
						
					Else
						
						// 
						DocumentCanBePosted = (Object.Metadata().Posting = AllowDocumentPosting);
						
						If DocumentCanBePosted Then
							WriteMode = DocumentWriteMode.UndoPosting;
						Else
							WriteMode = DocumentWriteMode.Write;
						EndIf;
						
					EndIf;
					
				EndIf;
				
				PostingMode = ?(PostingMode = "RealTime", DocumentPostingMode.RealTime, DocumentPostingMode.Regular);
				
				// 
				If Object.DeletionMark
					And (WriteMode = DocumentWriteMode.Posting) Then
					
					Object.DeletionMark = False;
					
				EndIf;
				
				ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object, 
				ObjectTypeName, True);
				
				If DataImportToInfobaseMode() Then
					
					Try
						
						// 
						
						// 
						If WriteMode = DocumentWriteMode.Write Then
							
							// 
							// 
							// 
							Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							
							// 
							For Each CurRecord In Object.RegisterRecords Do
								SetDataExchangeLoad(CurRecord,, SendBack);
							EndDo;
							
							WriteObjectToIB(Object, ObjectType, WriteObject, SendBack);
							
							RecordAccountingRegisters(Object.Ref, DeferredMotionRecordingTables);
							
							If WriteObject
								And Object <> Undefined
								And Object.Ref <> Undefined Then
								
								ObjectsForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
								
							EndIf;
							
						ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
							
							UndoObjectPostingInIB(Object, ObjectType, WriteObject);
							
						ElsIf WriteMode = DocumentWriteMode.Posting Then
							
							// 
							// 
							// 
							Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
							
							UndoObjectPostingInIB(Object, ObjectType, WriteObject);
							
							// 
							// 
							If WriteObject
								And Object <> Undefined
								And Object.Ref <> Undefined Then
								
								TableRow = DocumentsForDeferredPosting().Add();
								TableRow.DocumentRef = Object.Ref;
								TableRow.DocumentDate  = Object.Date;
								
								AdditionalPropertiesForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
								
							EndIf;
							
						EndIf;
						
					Except
						
						ErrorDescriptionString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
						
						If WriteObject Then
							// 
							WriteDocumentInSafeMode(Object, ObjectType);
						EndIf;
						
						WP                        = ExchangeProtocolRecord(25, ErrorDescriptionString);
						WP.OCRName                 = RuleName;
						
						If Not IsBlankString(Source) Then
							
							WP.Source           = Source;
							
						EndIf;
						
						WP.ObjectType             = ObjectType;
						WP.Object                 = String(Object);
						WriteToExecutionProtocol(25, WP);
						
						MessageString = NStr("en = 'Failed to save document: %1. Error details: %2';");
						MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(Object), ErrorDescriptionString);
						
						// 
						Raise MessageString;
						
					EndTry;
					
					DeleteFromNotWrittenObjectStack(NBSp, Gsn);
					
				EndIf;
				
			ElsIf ObjectTypeName <> "Enum" Then
				
				If ObjectTypeName = "InformationRegister" Then
					
					Periodic3 = PropertyStructure.Periodic3;
					
					If Periodic3 Then
						
						If Not ValueIsFilled(Object.Period) Then
							SetCurrentDateToAttribute(Object.Period);
						EndIf;
						
					EndIf;
					If RecordSet <> Undefined Then
						// 
						For Each FilterElement In RecordSet.Filter Do
							FilterElement.Set(Object[FilterElement.Name]);
						EndDo;
						Object = RecordSet;
					EndIf;
				EndIf;
				
				ExecuteNumberCodeGenerationIfNecessary(GenerateNewNumberOrCodeIfNotSet, Object,
				ObjectTypeName, True);
				
				If DataImportToInfobaseMode() Then
					
					// 
					// 
					// 
					If ObjectTypeName <> "Constants" Then
						Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
					EndIf;
					
					WriteObjectToIB(Object, ObjectType, WriteObject, SendBack);
					
					If Not (ObjectTypeName = "InformationRegister"
						 Or ObjectTypeName = "Constants") Then
						// 
						// 
						If WriteObject
							And Object <> Undefined
							And Object.Ref <> Undefined Then
							
							ObjectsForDeferredPosting().Insert(Object.Ref, Object.AdditionalProperties);
							
						EndIf;
						
						DeleteFromNotWrittenObjectStack(NBSp, Gsn);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			IsReferenceObjectType = Not(ObjectTypeName = "InformationRegister"
										Or ObjectTypeName = "Constants");
			
			Break;
			
		ElsIf NodeName = "SequenceRecordSet" Then
			
			deSkip(ExchangeFile);
			
		ElsIf NodeName = "Types" Then

			If Object = Undefined Then
				
				ObjectFound = False;
				Ref  = CreateNewObject(ObjectType, SearchProperties, Object, True);
								
			EndIf; 

			ObjectTypesDetails = ImportObjectTypes(ExchangeFile);

			If ObjectTypesDetails <> Undefined Then
				
				Object.ValueType = ObjectTypesDetails;
				
			EndIf; 
			
		Else
			
			WriteToExecutionProtocol(9);
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Object;

EndFunction

Procedure SwitchToNewExchange()
	
	ExchangePlanName = ExchangePlanName();
		
	PreviousExchangePlanSettings = 
		DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangePlanNameToMigrateToNewExchange");
	NameOfExchangePlanToGo = PreviousExchangePlanSettings.ExchangePlanNameToMigrateToNewExchange;
	
	DataSynchronizationSetup = Undefined;
	If ValueIsFilled(NodeForExchange) Then
		DataSynchronizationSetup = NodeForExchange;
	ElsIf ValueIsFilled(ExchangeNodeDataImport) Then
		DataSynchronizationSetup = ExchangeNodeDataImport;
	EndIf;

	ExchangePlans[NameOfExchangePlanToGo].SwitchToNewExchange(DataSynchronizationSetup);
	MessageString = NStr("en = 'Automatic switching to EnterpriseData data synchronization format.';");
	WriteEventLogDataExchange1(MessageString, EventLogLevel.Information);
	ExchangeResultField = Enums.ExchangeExecutionResults.Canceled;
	Raise NStr("en = 'Data synchronization with outdated settings is canceled.';");
EndProcedure

Function LoadingTabularPartIsSupported(Object, TabularSectionName)
	
	ObjectMetadata = Object.Metadata();
	If Not Metadata.Catalogs.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata) Then
		
		Return True;
		
	EndIf;
	
	ForItem = Metadata.ObjectProperties.AttributeUse.ForItem;
	If Object.IsFolder
		And ObjectMetadata.TabularSections[TabularSectionName].Use = ForItem Then
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

Procedure RecordAccountingRegisters(Recorder, DeferredMotionRecordingTables)
	
	If Not ValueIsFilled(Recorder.IsEmpty()) Then
		
		Return;
		
	EndIf;
	
	For Each DescriptionOfMovementTable In DeferredMotionRecordingTables Do
		
		RegisterName = DescriptionOfMovementTable.Key;
		RegisterRecordTable = DescriptionOfMovementTable.Value;
		
		If TypeOf(RegisterRecordTable) <> Type("ValueTable")
			Or RegisterRecordTable.Count() < 1 Then
			
			Continue;
			
		EndIf;
		
		RegisterRecordSet = AccountingRegisters[RegisterName].CreateRecordSet();
		RegisterRecordSet.Filter.Recorder.Set(Recorder, True);
		For Each TableRow In RegisterRecordTable Do
			
			SetRecord = RegisterRecordSet.Add();
			FillPropertyValues(SetRecord, TableRow);
			
			ExtDimensionNumberDr = 0;
			For Each DrDescriptionOfExtDimensionType In SetRecord.AccountDr.ExtDimensionTypes Do
				
				ExtDimensionNumberDr = ExtDimensionNumberDr + 1;
				SetRecord.ExtDimensionsDr[DrDescriptionOfExtDimensionType.ExtDimensionType] = TableRow["ExtDimensionDr" + String(ExtDimensionNumberDr)];
				
			EndDo;
			
			ExtDimensionNumberCr = 0;
			For Each DescriptionOfTypeOfExtDimensionOfCr In SetRecord.AccountCr.ExtDimensionTypes Do
				
				ExtDimensionNumberCr = ExtDimensionNumberCr + 1;
				SetRecord.ExtDimensionsCr[DescriptionOfTypeOfExtDimensionOfCr.ExtDimensionType] = TableRow["ExtDimensionCr" + String(ExtDimensionNumberCr)];
				
			EndDo;
			
		EndDo;
		
		InfobaseUpdate.WriteRecordSet(RegisterRecordSet, True, False, False);
		
	EndDo;
	
EndProcedure

Procedure CheckExtDimensionCollection(TableRow, ValuesBeforeCorrection, Direction, HasError)
	
	ExtDimensionTypesCollection = TableRow["Account" + Direction].ExtDimensionTypes;
	
	For Each ExtDimensionTypeFromCollection In ExtDimensionTypesCollection Do
		
		ExtDimensionType = Direction + String(ExtDimensionTypeFromCollection.LineNumber);
		
		NameExtdimension = "ExtDimension" + ExtDimensionType;
		NameTypesOfSubconto = "ExtDimensionType" + ExtDimensionType;
		
		DescriptionOfExtdimension = New Structure;
		DescriptionOfExtdimension.Insert("HasError", False);
		DescriptionOfExtdimension.Insert("ExtDimension", TableRow[NameExtdimension]);
		DescriptionOfExtdimension.Insert("ExtDimensionType", TableRow[NameTypesOfSubconto]);
		
		If TableRow[NameTypesOfSubconto] <> ExtDimensionTypeFromCollection.ExtDimensionType Then
			
			DescriptionOfExtdimension.HasError = True;
			
			TableRow[NameExtdimension] = Undefined;
			TableRow[NameTypesOfSubconto] = ExtDimensionTypeFromCollection.ExtDimensionType;
			
			HasError = True;
			
		EndIf;
		
		ValuesBeforeCorrection.Insert(ExtDimensionType, DescriptionOfExtdimension);
		
	EndDo;
	
EndProcedure

Procedure EliminateErrorOfAssigningTypeOfSubconto(LoadedRegisteredRecords)
	
	For Each TableRow In LoadedRegisteredRecords Do
		
		HasError = False;
		
		ValuesBeforeCorrection = New Map;
		
		CheckExtDimensionCollection(TableRow, ValuesBeforeCorrection, "Dr", HasError);
		CheckExtDimensionCollection(TableRow, ValuesBeforeCorrection, "Cr", HasError);
		
		If HasError Then
			
			For Each MapItem In ValuesBeforeCorrection Do
				
				DescriptionOfExtdimension = MapItem.Value;
				If Not DescriptionOfExtdimension.HasError Then
					
					Continue;
					
				EndIf;
				
				NameOfTypeOfSubcontoBeingCorrected = "ExtDimensionType" + MapItem.Key;
				
				For Each AlternativeElement In ValuesBeforeCorrection Do
					
					AlternativeDescription = AlternativeElement.Value;
					If Not AlternativeDescription.HasError 
						Or MapItem.Key = AlternativeElement.Key Then
						
						Continue;
						
					EndIf;
					
					ExtdimensionValueType = TableRow[NameOfTypeOfSubcontoBeingCorrected].ValueType;
					If TableRow[NameOfTypeOfSubcontoBeingCorrected] = AlternativeDescription.ExtDimensionType
						And ExtdimensionValueType.ContainsType(TypeOf(AlternativeDescription["ExtDimension"])) Then
						
						TableRow["ExtDimension" + MapItem.Key] = AlternativeDescription["ExtDimension"];
						Break;
						
					EndIf;
					
				EndDo;
			
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DataExportProcedures

Function DocumentRegisterRecordSet(DocumentReference, SourceKind, RegisterName)
	
	If SourceKind = "AccumulationRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccumulationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "InformationRegisterRecordsSet" Then
		
		DocumentRegisterRecordSet = InformationRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "AccountingRegisterRecordSet" Then
		
		DocumentRegisterRecordSet = AccountingRegisters[RegisterName].CreateRecordSet();
		
	ElsIf SourceKind = "CalculationRegisterRecordSet" Then	
		
		DocumentRegisterRecordSet = CalculationRegisters[RegisterName].CreateRecordSet();
		
	Else
		
		Return Undefined;
		
	EndIf;
	
	DataExchangeInternal.SetFilterItemValue(DocumentRegisterRecordSet.Filter, "Recorder", DocumentReference.Ref);
	DocumentRegisterRecordSet.Read();
	
	Return DocumentRegisterRecordSet;
	
EndFunction

// Generates the property nodes of the receiver object in accordance with the specified collection of property conversion rules.
//
// Parameters:
//  Source		     - custom data source.
//  Receiver		     - xml-node of the receiver object.
//  IncomingData	     - custom auxiliary data passed to the rule
//                         for performing the conversion.
//  OutgoingData      - custom auxiliary data passed
//                         to the property object conversion rules.
//  OCR				     - 
//  PGCR                 - 
//  PropertyCollectionNode - xml-node of the property collection.
// 
Procedure ExportPropertyGroup(Source, Receiver, IncomingData, OutgoingData, OCR, PGCR, PropertyCollectionNode, 
	ExportRefOnly, TempFileList = Undefined, ExportRegisterRecordSetRow = False)

	
	ObjectCollection1 = Undefined;
	NotReplace        = PGCR.NotReplace;
	NotClear         = False;
	ExportGroupToFile = PGCR.ExportGroupToFile;
	
	// 

	If PGCR.HasBeforeProcessExportHandler Then
		
		Cancel = False;
		Try
			
			If ExportHandlersDebug Then
				
				ExecutePGCRHandlerBeforeExportProcessing(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
																 PGCR, Cancel, ObjectCollection1, NotReplace, PropertyCollectionNode, NotClear);
				
			Else
				
				Execute(PGCR.BeforeProcessExport);
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(48, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
			
			TypeDescription = New TypeDescription("String");
			StringSource= TypeDescription.AdjustValue(Source);
			If Not IsBlankString(StringSource) Then
				WP.Object = TypeDescription.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
			Else
				WP.Object = "(" + TypeOf(Source) + ")";
			EndIf;
			
			WP.Handler             = "BeforeProcessPropertyGroupExport";
			ErrorMessageString = WriteToExecutionProtocol(48, WP);
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
							
		If Cancel Then // 
			
			Return;
			
		EndIf;
		
	EndIf;

	
    DestinationKind = PGCR.DestinationKind;
	SourceKind = PGCR.SourceKind;
	
	
    // 
	PropertyNodeStructure = Undefined;
	ObjectCollectionNode = Undefined;
	MasterNodeName = "";
	
	If DestinationKind = "TabularSection" Then
		
		MasterNodeName = "TabularSection";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Receiver, MasterNodeName);
		
		If NotReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "NotReplace", "true");
						
		EndIf;
		
		If NotClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "NotClear", "true");
						
		EndIf;
		
	ElsIf DestinationKind = "SubordinateCatalog" Then
				
		
	ElsIf DestinationKind = "SequenceRecordSet" Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Receiver, MasterNodeName);
		
	ElsIf StrFind(DestinationKind, "RecordsSet") > 0 Then
		
		MasterNodeName = "RecordSet";
		
		CreateObjectsForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, True, PGCR.Receiver, MasterNodeName);
		
		If NotReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "NotReplace", "true");
						
		EndIf;
		
		If NotClear Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, ObjectCollectionNode, "NotClear", "true");
						
		EndIf;
		
	Else  // 
		
		ExportProperties(Source, Receiver, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
			PropertyCollectionNode, , , True, False);
		
		If PGCR.HasAfterProcessExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePGCRHandlerAfterExportProcessing(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																	OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode);
					
				Else
					
					Execute(PGCR.AfterProcessExport);
					
				EndIf;
				
			Except
				
				WP = ExchangeProtocolRecord(49, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
				WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
				
				TypeDescription = New TypeDescription("String");
				StringSource= TypeDescription.AdjustValue(Source);
				If Not IsBlankString(StringSource) Then
					WP.Object = TypeDescription.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
				Else
					WP.Object = "(" + TypeOf(Source) + ")";
				EndIf;
				
				WP.Handler             = "AfterProcessPropertyGroupExport";
				ErrorMessageString = WriteToExecutionProtocol(49, WP);
			
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
			EndTry;
			
		EndIf;
		
		Return;
		
	EndIf;
	
	// 
	
	If ObjectCollection1 <> Undefined Then
		
		// 
		
	ElsIf PGCR.GetFromIncomingData Then
		
		Try
			
			ObjectCollection1 = IncomingData[PGCR.Receiver];
			
			If TypeOf(ObjectCollection1) = Type("QueryResult") Then
				
				ObjectCollection1 = ObjectCollection1.Unload();
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(66, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WP.OCR  = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR = PGCR.Name + "  (" + PGCR.Description + ")";
			
			Try
				WP.Object = String(Source) + "  (" + TypeOf(Source) + ")";
			Except
				WP.Object = "(" + TypeOf(Source) + ")";
			EndTry;
			
			ErrorMessageString = WriteToExecutionProtocol(66, WP);
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
			Return;
		EndTry;
		
	ElsIf SourceKind = "TabularSection" Then
		
		ObjectCollection1 = Source[PGCR.Source];
		
		If TypeOf(ObjectCollection1) = Type("QueryResult") Then
			
			ObjectCollection1 = ObjectCollection1.Unload();
			
		EndIf;
		
	ElsIf SourceKind = "SubordinateCatalog" Then
		
	ElsIf StrFind(SourceKind, "RecordsSet") > 0 Then
		
		ObjectCollection1 = DocumentRegisterRecordSet(Source, SourceKind, PGCR.Source);
				
	ElsIf IsBlankString(PGCR.Source) Then
		
		ObjectCollection1 = Source[PGCR.Receiver];
		
		If TypeOf(ObjectCollection1) = Type("QueryResult") Then
			
			ObjectCollection1 = ObjectCollection1.Unload();
			
		EndIf;
		
	EndIf;

	ExportGroupToFile = ExportGroupToFile Or (ObjectCollection1.Count() > 1000);
	ExportGroupToFile = ExportGroupToFile And Not ExportRegisterRecordSetRow;
	ExportGroupToFile = ExportGroupToFile And Not IsExchangeOverExternalConnection();
	
	If ExportGroupToFile Then
		
		PGCR.XMLNodeRequiredOnExport = False;
		
		If TempFileList = Undefined Then
			TempFileList = New ValueList();
		EndIf;
		
		RecordFileName = GetTempFileName();
		// 
		TempFileList.Add(RecordFileName);
		
		TempRecordFile = New TextWriter;
		Try
			
			TempRecordFile.Open(RecordFileName, TextEncoding.UTF8);
			
		Except
			
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Cannot create a temporary file for data export.
					|File name: %1.
					|Error details:
					|%2';"),
				String(RecordFileName),
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
			WriteToExecutionProtocol(ErrorMessageString);
			
		EndTry;
		
		InformationToWriteToFile = ObjectCollectionNode.Close();
		TempRecordFile.WriteLine(InformationToWriteToFile);
		
	EndIf;
	
	For Each CollectionObject In ObjectCollection1 Do
		
		// 
		If PGCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePGCRHandlerBeforePropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
																	PGCR, Cancel, CollectionObject, PropertyCollectionNode, ObjectCollectionNode);
					
				Else
					
					Execute(PGCR.BeforeExport);
					
				EndIf;
				
			Except
				
				ErrorMessageString = WriteToExecutionProtocol(50);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
			If Cancel Then // 
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		// 
		
		If PGCR.XMLNodeRequiredOnExport Or ExportGroupToFile Then
			CollectionObjectNode = CreateNode("Record");
		Else
			ObjectCollectionNode.WriteStartElement("Record");
			CollectionObjectNode = ObjectCollectionNode;
		EndIf;
		
		StandardProcessing	= True;
		
		If PGCR.HasOnExportHandler Then
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePGCRHandlerOnPropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
																 PGCR, CollectionObject, ObjectCollectionNode, CollectionObjectNode,
																 PropertyCollectionNode, StandardProcessing);
					
				Else
					
					Execute(PGCR.OnExport);
					
				EndIf;
			
		Except
				
				ErrorMessageString = WriteToExecutionProtocol(51);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
		EndIf;
		
		// 
		If StandardProcessing Then
			
			If PGCR.GroupRules.Count() > 0 Then
				
				ExportProperties(Source, Receiver, IncomingData, OutgoingData, OCR, PGCR.GroupRules, 
					CollectionObjectNode, CollectionObject, , True, False);
				
			EndIf;
			
		EndIf;
		
		// 
		If PGCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePGCRHandlerAfterPropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																   OCR, PGCR, Cancel, CollectionObject, ObjectCollectionNode,
																   PropertyCollectionNode, CollectionObjectNode);
					
				Else
					
					Execute(PGCR.AfterExport);
					
				EndIf;
				
			Except
				
				ErrorMessageString = WriteToExecutionProtocol(52);
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Break;
				
			EndTry;
			
		If Cancel Then // 
			
			Continue;
			
		EndIf;
			
		EndIf;
		
		If PGCR.XMLNodeRequiredOnExport Then
			AddSubordinateNode(ObjectCollectionNode, CollectionObjectNode);
		EndIf;
		
		// 
		If ExportGroupToFile Then
			
			CollectionObjectNode.WriteEndElement();
			InformationToWriteToFile = CollectionObjectNode.Close();
			TempRecordFile.WriteLine(InformationToWriteToFile);
			
		Else
			
			If Not PGCR.XMLNodeRequiredOnExport Then
				
				ObjectCollectionNode.WriteEndElement();
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// 
	If PGCR.HasAfterProcessExportHandler Then
		
		Cancel = False;
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecutePGCRHandlerAfterExportProcessing(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode);
				
			Else
				
				Execute(PGCR.AfterProcessExport);
				
			EndIf;
			
		Except
			
			WP = ExchangeProtocolRecord(49, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WP.OCR                    = OCR.Name + "  (" + OCR.Description + ")";
			WP.PGCR                   = PGCR.Name + "  (" + PGCR.Description + ")";
			
			TypeDescription = New TypeDescription("String");
			StringSource= TypeDescription.AdjustValue(Source);
			If Not IsBlankString(StringSource) Then
				WP.Object = TypeDescription.AdjustValue(Source) + "  (" + TypeOf(Source) + ")";
			Else
				WP.Object = "(" + TypeOf(Source) + ")";
			EndIf;
			
			WP.Handler             = "AfterProcessPropertyGroupExport";
			ErrorMessageString = WriteToExecutionProtocol(49, WP);
		
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
		If Cancel Then // 
			
			Return;
			
		EndIf;
		
	EndIf;
	
	If ExportGroupToFile Then
		TempRecordFile.WriteLine("</" + MasterNodeName + ">"); // 
		TempRecordFile.Close(); // 
	Else
		WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, ObjectCollectionNode);
	EndIf;
	
EndProcedure

Procedure GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, DataSelection = Undefined)
	
	If Value <> Undefined Then
		Return;
	EndIf;
	
	If PCR.GetFromIncomingData Then
			
		ObjectForReceivingData = IncomingData;
		
		If Not IsBlankString(PCR.Receiver) Then
		
			PropertyName = PCR.Receiver;
			
		Else
			
			PropertyName = PCR.ParameterForTransferName;
			
		EndIf;
		
		ErrorCode = ?(CollectionObject <> Undefined, 67, 68);
	
	ElsIf CollectionObject <> Undefined Then
		
		ObjectForReceivingData = CollectionObject;
		
		If Not IsBlankString(PCR.Source) Then
			
			PropertyName = PCR.Source;
			ErrorCode = 16;
						
		Else
			
			PropertyName = PCR.Receiver;
			ErrorCode = 17;
            							
		EndIf;
		
	ElsIf DataSelection <> Undefined Then
		
		ObjectForReceivingData = DataSelection;	
		
		If Not IsBlankString(PCR.Source) Then
		
			PropertyName = PCR.Source;
			ErrorCode = 13;
			
		Else
			
			Return;
			
		EndIf;
						
	Else
		
		ObjectForReceivingData = Source;
		
		If Not IsBlankString(PCR.Source) Then
		
			PropertyName = PCR.Source;
			ErrorCode = 13;
		
		Else
			
			PropertyName = PCR.Receiver;
			ErrorCode = 14;
		
		EndIf;
			
	EndIf;
	
	
	Try
		
		Value = ObjectForReceivingData[PropertyName];
		
		// 
		If PCR.SourceType = "TypeDefinition" Then
			
			Value = DescriptionOfTypesInJSON(Value);
			
		EndIf
		
	Except
		
		If ErrorCode <> 14 Then
			WriteErrorInfoPCRHandlers(ErrorCode, ErrorProcessing.DetailErrorDescription(ErrorInfo()), OCR, PCR, Source, "");
		EndIf;
		
	EndTry;
			
EndProcedure

Procedure ExportItemPropertyType(PropertyNode1, PropertyType1)
	
	SetAttribute(PropertyNode1, "Type", PropertyType1);	
	
EndProcedure

Procedure _ExportExtDimension1(Source, Receiver, IncomingData, OutgoingData, OCR, PCR, 
	PropertyCollectionNode = Undefined, CollectionObject = Undefined, Val ExportRefOnly = False)
	
	// 
    Var DestinationType, Empty, Expression, NotReplace, PropertiesOCR, PropertyNode1;
	
	// 
	Value = Undefined;
	OCRName = "";
	OCRNameExtDimensionType = "";
	
	// 
	If PCR.HasBeforeExportHandler Then
		
		Cancel = False;
		
		Try
			
			ExportObject1 = Not ExportRefOnly;
			
			If ExportHandlersDebug Then
				
				ExecutePCRHandlerBeforeExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
															   PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
															   OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, NotReplace,
															   ExportObject1);
				
			Else
				
				Execute(PCR.BeforeExport);
				
			EndIf;
			
			ExportRefOnly = Not ExportObject1;
			
		Except
			
			WriteErrorInfoPCRHandlers(55, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
				OCR, PCR, Source, "BeforeExportProperty", Value);
			
		EndTry;
		
		If Cancel Then // 
			
			Return;
			
		EndIf;
		
	EndIf;
	
	GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source);
	
	If PCR.CastToLength <> 0 Then
				
		CastValueToLength(Value, PCR);
						
	EndIf;
		
	For Each KeyAndValue In Value Do
		
		ExtDimensionType = KeyAndValue.Key;
		ExtDimension = KeyAndValue.Value;
		OCRName = "";
		
		// 
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject1 = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					ExecutePCRHandlerOnExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																ExtDimension, Empty, OCRName, PropertiesOCR,PropertyNode1, PropertyCollectionNode,
																OCRNameExtDimensionType, ExportObject1);
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject1;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					OCR, PCR, Source, "OnExportProperty", Value);
				
			EndTry;
			
			If Cancel Then // 
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		If ExtDimension = Undefined
			Or FindRule(ExtDimension, OCRName) = Undefined Then
			
			Continue;
			
		EndIf;
			
		ExtDimensionNode = CreateNode(PCR.Receiver);
			
		// Key
		PropertyNode1 = CreateNode("Property");
			
		If OCRNameExtDimensionType = "" Then
				
			OCRKey = FindRule(ExtDimensionType);
				
		Else
				
			OCRKey = FindRule(, OCRNameExtDimensionType);
				
		EndIf;
			
		SetAttribute(PropertyNode1, "Name", "Key");
		ExportItemPropertyType(PropertyNode1, OCRKey.Receiver);
		
		RefNode = ExportByRule(ExtDimensionType,, OutgoingData,, OCRNameExtDimensionType,, True, OCRKey, , , , , False);
			
		If RefNode <> Undefined Then
				
			AddSubordinateNode(PropertyNode1, RefNode);
				
		EndIf;
			
		AddSubordinateNode(ExtDimensionNode, PropertyNode1);
		
		// Value
		PropertyNode1 = CreateNode("Property");
			
		OCRValue = FindRule(ExtDimension, OCRName);
		
		DestinationType = OCRValue.Receiver;
		
		ThisNULL = False;
		Empty = deEmpty(ExtDimension, ThisNULL);
		
		If Empty Then
			
			If ThisNULL 
				Or Value = Undefined Then
				
				Continue;
				
			EndIf;
			
			If IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(ExtDimension);
								
			EndIf;			
			
			SetAttribute(PropertyNode1, "Name", "Value");
			
			If Not IsBlankString(DestinationType) Then
				SetAttribute(PropertyNode1, "Type", DestinationType);
			EndIf;
							
			// 
			deWriteElement(PropertyNode1, "Empty");
			AddSubordinateNode(ExtDimensionNode, PropertyNode1);
			
		Else
			
			IsRuleWithGlobalExport = False;
			
			ExportRefOnly = True;
			If ExportObjectByRef(ExtDimension, NodeForExchange) Then
						
				If Not ObjectPassesAllowedObjectFilter(ExtDimension) Then
					
					// 
					ExportRefOnly = False;
					
					// 
					RecordStructure = New Structure;
					RecordStructure.Insert("InfobaseNode", NodeForExchange);
					RecordStructure.Insert("SourceUUID", ExtDimension);
					RecordStructure.Insert("ObjectExportedByRef", True);
					
					InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure, True);
					
					// 
					// 
					// 
					ExportedByRefObjectsAddValue(ExtDimension);
					
				EndIf;
				
			EndIf;
			
			RefNode = ExportByRule(ExtDimension,, OutgoingData, , OCRName, , ExportRefOnly, OCRValue, , , , , False, IsRuleWithGlobalExport);
			
			SetAttribute(PropertyNode1, "Name", "Value");
			ExportItemPropertyType(PropertyNode1, DestinationType);
						
				
			RefNodeType = TypeOf(RefNode);
				
			If RefNode = Undefined Then
					
				Continue;
					
			EndIf;
							
			AddPropertiesForExport(RefNode, RefNodeType, PropertyNode1, IsRuleWithGlobalExport);
			
			AddSubordinateNode(ExtDimensionNode, PropertyNode1);
			
		EndIf;
		
		// 
		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePCRHandlerAfterExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																  ExtDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode1,
																  RefNode, PropertyCollectionNode, ExtDimensionNode);
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(57, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					OCR, PCR, Source, "AfterExportProperty", Value);
				
			EndTry;
			
			If Cancel Then // 
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		AddSubordinateNode(PropertyCollectionNode, ExtDimensionNode);
		
	EndDo;
	
EndProcedure

Procedure AddPropertiesForExport(RefNode, RefNodeType, PropertyNode1, IsRuleWithGlobalExport)
	
	If RefNodeType = StringType Then
				
		If StrFind(RefNode, "<Ref") > 0 Then
					
			PropertyNode1.WriteRaw(RefNode);
					
		Else
			
			deWriteElement(PropertyNode1, "Value", RefNode);
					
		EndIf;
				
	ElsIf RefNodeType = NumberType Then
		
		If IsRuleWithGlobalExport Then
		
			deWriteElement(PropertyNode1, "Gsn", RefNode);
			
		Else     		
			
			deWriteElement(PropertyNode1, "NBSp", RefNode);
			
		EndIf;
				
	Else
				
		AddSubordinateNode(PropertyNode1, RefNode);
				
	EndIf;
	
EndProcedure

Procedure GetValueSettingPossibility(Value, ValueType, DestinationType, PropertySet, TypeRequired)
	
	PropertySet = True;
		
	If ValueType = StringType Then
				
		If DestinationType = "String"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf DestinationType = "Date"  Then
					
			Value = Date(Value);
					
		ElsIf DestinationType = "ValueStorage"  Then
					
			Value = New ValueStorage(Value);
					
		ElsIf DestinationType = "UUID" Then
					
			Value = New UUID(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "String";
			TypeRequired = True;
			
		EndIf;
								
	ElsIf ValueType = NumberType Then
				
		If DestinationType = "Number"
			Or DestinationType = "String" Then
		ElsIf DestinationType = "Boolean"  Then
					
			Value = Boolean(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Number";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;
								
	ElsIf ValueType = DateType Then
				
		If DestinationType = "Date"  Then
		ElsIf DestinationType = "String"  Then
					
			Value = Left(String(Value), 10);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Date";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = BooleanType Then
				
		If DestinationType = "Boolean"  Then
		ElsIf DestinationType = "Number"  Then
					
			Value = Number(Value);
					
		ElsIf IsBlankString(DestinationType) Then
					
			DestinationType = "Boolean";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = ValueStorageType Then
				
		If IsBlankString(DestinationType) Then
					
			DestinationType = "ValueStorage";
			TypeRequired = True;
					
		ElsIf DestinationType <> "ValueStorage"  Then
					
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = UUIDType Then
				
		If DestinationType = "UUID" Then
		ElsIf DestinationType = "String" Then
			
			Value = String(Value);
			
		ElsIf IsBlankString(DestinationType) Then
			
			DestinationType = "UUID";
			TypeRequired = True;
			
		Else
			
			PropertySet = False;
					
		EndIf;				
						
	ElsIf ValueType = AccumulationRecordTypeType Then
				
		Value = String(Value);		
		
	ElsIf ValueType = TypeDescriptionOfTypes Then
		
		Value = String(Value);
		
	Else
		
		PropertySet = False;
		
	EndIf;	
	
EndProcedure

Function GetDataTypeForDestination(Value)
	
	DestinationType = deValueTypeAsString(Value);
	
	// 
	// 
	TableRow = ConversionRulesTable.Find(DestinationType, "Receiver");
	
	If TableRow = Undefined Then
		
		If Not (DestinationType = "String"
			Or DestinationType = "Number"
			Or DestinationType = "Date"
			Or DestinationType = "Boolean"
			Or DestinationType = "ValueStorage") Then
			
			DestinationType = "";
		EndIf;
		
	EndIf;
	
	Return DestinationType;
	
EndFunction

Procedure CastValueToLength(Value, PCR)
	
	Value = CastNumberToLength(String(Value), PCR.CastToLength);
		
EndProcedure

Procedure WriteStructureToXML(StructureOfData, PropertyCollectionNode, IsOrdinaryProperty = True)
	
	PropertyCollectionNode.WriteStartElement(?(IsOrdinaryProperty, "Property", "ParameterValue"));
	
	For Each CollectionItem In StructureOfData Do
		
		If CollectionItem.Key = "Expression"
			Or CollectionItem.Key = "Value"
			Or CollectionItem.Key = "NBSp"
			Or CollectionItem.Key = "Gsn" Then
			
			deWriteElement(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		ElsIf CollectionItem.Key = "Ref" Then
			
			PropertyCollectionNode.WriteRaw(CollectionItem.Value);
			
		Else
			
			SetAttribute(PropertyCollectionNode, CollectionItem.Key, CollectionItem.Value);
			
		EndIf;
		
	EndDo;
	
	PropertyCollectionNode.WriteEndElement();		
	
EndProcedure

Procedure CreateComplexInformationForXMLWriter(StructureOfData, PropertyNode1, XMLNodeRequired, DestinationName, ParameterName)
	
	If IsBlankString(ParameterName) Then
		
		CreateObjectsForXMLWriter(StructureOfData, PropertyNode1, XMLNodeRequired, DestinationName, "Property");
		
	Else
		
		CreateObjectsForXMLWriter(StructureOfData, PropertyNode1, XMLNodeRequired, ParameterName, "ParameterValue");
		
	EndIf;
	
EndProcedure

Procedure CreateObjectsForXMLWriter(StructureOfData, PropertyNode1, XMLNodeRequired, NodeName, XMLNodeDescription = "Property")
	
	If XMLNodeRequired Then
		
		PropertyNode1 = CreateNode(XMLNodeDescription);
		SetAttribute(PropertyNode1, "Name", NodeName);
		
	Else
		
		StructureOfData = New Structure("Name", NodeName);
		
	EndIf;		
	
EndProcedure

Procedure AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		SetAttribute(PropertyNode1, AttributeName, AttributeValue);
	EndIf;
	
EndProcedure

Procedure AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		deWriteElement(PropertyNode1, AttributeName, AttributeValue);
	EndIf;
	
EndProcedure

Procedure AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode1, AttributeName, AttributeValue)
	
	If PropertyNodeStructure <> Undefined Then
		PropertyNodeStructure.Insert(AttributeName, AttributeValue);
	Else
		PropertyNode1.WriteRaw(AttributeValue);
	EndIf;
	
EndProcedure

Procedure WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode1, IsOrdinaryProperty = True)
	
	If PropertyNodeStructure <> Undefined Then
		WriteStructureToXML(PropertyNodeStructure, PropertyCollectionNode, IsOrdinaryProperty);
	Else
		AddSubordinateNode(PropertyCollectionNode, PropertyNode1);
	EndIf;
	
EndProcedure

// Generates the property nodes of the receiver object in accordance with the specified collection of property conversion rules.
//
// Parameters:
//  Source             - Arbitrary -  custom data source.
//  Receiver             - XMLWriter -  xml node of the receiver object.
//  IncomingData       - Arbitrary -  custom auxiliary data passed to the rule
//                         for performing the conversion.
//  OutgoingData      - Arbitrary -  custom auxiliary data passed
//                         to the property object conversion rules.
//  OCR                  - ValueTableRow -  link to the object conversion rule.
//  PCRCollection         - See PropertiesConversionRulesCollection
//  PropertyCollectionNode - XMLWriter -  xml node of the property collection.
//  CollectionObject      - Arbitrary -  if specified, the properties of the collection object are unloaded, otherwise the Source.
//  PredefinedItemName1 - String -  if specified, the name of the predefined element is written in the properties.
// 
Procedure ExportProperties(Source, 
							Receiver, 
							IncomingData, 
							OutgoingData, 
							OCR, 
							PCRCollection, 
							PropertyCollectionNode = Undefined, 
							CollectionObject = Undefined, 
							PredefinedItemName1 = Undefined, 
							Val OCRExportRefOnly = True, 
							Val IsRefExport = False, 
							Val ExportingObject = False, 
							RefSearchKey = "", 
							DontUseRulesWithGlobalExportAndDontRememberExported = False,
							RefValueInAnotherIB = "",
							TempFileList = Undefined, 
							ExportRegisterRecordSetRow = False,
							ObjectExportStack = Undefined)
							
	// 
	Var KeyAndValue, ExtDimensionType, ExtDimension, OCRNameExtDimensionType, ExtDimensionNode;

							
	If PropertyCollectionNode = Undefined Then
		
		PropertyCollectionNode = Receiver;
		
	EndIf;
	
	PropertiesSelection = Undefined;
	
	If IsRefExport Then
				
		// 
		If PredefinedItemName1 <> Undefined Then
			
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", "{PredefinedItemName1}");
			deWriteElement(PropertyCollectionNode, "Value", PredefinedItemName1);
			PropertyCollectionNode.WriteEndElement();
			
		EndIf;
		
	EndIf;
	
	For Each PCR In PCRCollection Do
		
		ExportRefOnly = OCRExportRefOnly;
		
		If PCR.SimplifiedPropertyExport Then
			
			
			 //	
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", PCR.Receiver);
			
			If Not IsBlankString(PCR.DestinationType) Then
				
				SetAttribute(PropertyCollectionNode, "Type", PCR.DestinationType);
				
			EndIf;
			
			If PCR.NotReplace Then
				
				SetAttribute(PropertyCollectionNode, "NotReplace",	"true");
				
			EndIf;
			
			If PCR.SearchByEqualDate  Then
				
				SetAttribute(PropertyCollectionNode, "SearchByEqualDate", "true");
				
			EndIf;
			
			Value = Undefined;
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, PropertiesSelection);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
			
			ThisNULL = False;
			Empty = deEmpty(Value, ThisNULL);
						
			If Empty Then
				
				PropertyCollectionNode.WriteEndElement();
				Continue;
				
			EndIf;
			
			deWriteElement(PropertyCollectionNode, 	"Value", Value);
			
			PropertyCollectionNode.WriteEndElement();
			Continue;					
					
		ElsIf PCR.DestinationKind = "AccountExtDimensionTypes" Then
			
			_ExportExtDimension1(Source, Receiver, IncomingData, OutgoingData, OCR, 
				PCR, PropertyCollectionNode, CollectionObject, ExportRefOnly);
			
			Continue;
			
		ElsIf PCR.Name = "{UUID}" Then
			
			RefToSource = GetRefByObjectOrRef(Source, ExportingObject);
			
			UUID = RefToSource.UUID();
			
			PropertyCollectionNode.WriteStartElement("Property");
			SetAttribute(PropertyCollectionNode, "Name", "{UUID}");
			SetAttribute(PropertyCollectionNode, "Type", "String");
			SetAttribute(PropertyCollectionNode, "SourceType", OCR.SourceType);
			SetAttribute(PropertyCollectionNode, "DestinationType", OCR.DestinationType);
			deWriteElement(PropertyCollectionNode, "Value", UUID);
			PropertyCollectionNode.WriteEndElement();
			
			Continue;
			
		ElsIf PCR.IsFolder Then
			
			ExportPropertyGroup(
				Source, Receiver, IncomingData, OutgoingData, OCR, PCR, PropertyCollectionNode, 
				ExportRefOnly, TempFileList, ExportRegisterRecordSetRow);
			
			Continue;
			
		EndIf;
		
		//	
		Value 	 = Undefined;
		OCRName		 = PCR.ConversionRule;
		NotReplace   = PCR.NotReplace;
		
		Empty		 = False;
		Expression	 = Undefined;
		DestinationType = PCR.DestinationType;

		ThisNULL      = False;
		
		// 
		If PCR.HasBeforeExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject1 = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					ExecutePCRHandlerBeforeExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																   PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
																   OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, NotReplace,
																   ExportObject1);
					
				Else
					
					Execute(PCR.BeforeExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject1;
				
			Except
				
				WriteErrorInfoPCRHandlers(55, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					OCR, PCR, Source, "BeforeExportProperty", Value);
				
			EndTry;
			
			If Cancel Then	//	
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		// 
		PropertyNodeStructure = Undefined;
		PropertyNode1 = Undefined;
		
		CreateComplexInformationForXMLWriter(PropertyNodeStructure, PropertyNode1, PCR.XMLNodeRequiredOnExport, PCR.Receiver, PCR.ParameterForTransferName);
							
		If NotReplace Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "NotReplace", "true");			
						
		EndIf;
		
		If PCR.SearchByEqualDate  Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "SearchByEqualDate", "true");
			
		EndIf;
		
		//	
		If Not IsBlankString(OCRName) Then
			
			PropertiesOCR = Rules[OCRName];
			
		Else
			
			PropertiesOCR = Undefined;
			
		EndIf;
		
		If Not IsBlankString(DestinationType) Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "Type", DestinationType);
			
		ElsIf PropertiesOCR <> Undefined Then
			
			// 
			DestinationType = PropertiesOCR.Receiver;
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "Type", DestinationType);
			
		EndIf;
		
		If Not IsBlankString(OCRName)
			And PropertiesOCR <> Undefined
			And PropertiesOCR.HasSearchFieldSequenceHandler = True Then
			
			AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "OCRName", OCRName);
			
		EndIf;
		
		IsOrdinaryProperty = IsBlankString(PCR.ParameterForTransferName);
		
		//	
		If Expression <> Undefined Then
			
			AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, "Expression", Expression);
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode1, IsOrdinaryProperty);
			Continue;
			
		ElsIf Empty Then
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode1, IsOrdinaryProperty);
			Continue;
			
		Else
			
			GetPropertyValue(Value, CollectionObject, OCR, PCR, IncomingData, Source, PropertiesSelection);
			
			If PCR.CastToLength <> 0 Then
				
				CastValueToLength(Value, PCR);
								
			EndIf;
						
		EndIf;

		OldValueBeforeOnExportHandler = Value;
		Empty = deEmpty(Value, ThisNULL);
		
		// 
		If PCR.HasOnExportHandler Then
			
			Cancel = False;
			
			Try
				
				ExportObject1 = Not ExportRefOnly;
				
				If ExportHandlersDebug Then
					
					ExecutePCRHandlerOnExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																ExtDimension, Empty, OCRName, PropertiesOCR,PropertyNode1, PropertyCollectionNode,
																OCRNameExtDimensionType, ExportObject1);
					
				Else
					
					Execute(PCR.OnExport);
					
				EndIf;
				
				ExportRefOnly = Not ExportObject1;
				
			Except
				
				WriteErrorInfoPCRHandlers(56, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					OCR, PCR, Source, "OnExportProperty", Value);
				
			EndTry;
			
			If Cancel Then	//	
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		//  
		// 
		If OldValueBeforeOnExportHandler <> Value Then
			
			Empty = deEmpty(Value, ThisNULL);
			
		EndIf;

		If Empty Then
			
			If ThisNULL Then
				
				Value = Undefined;
				
			EndIf;
			
			If Value <> Undefined 
				And IsBlankString(DestinationType) Then
				
				DestinationType = GetDataTypeForDestination(Value);
				
				If Not IsBlankString(DestinationType) Then
					
					AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "Type", DestinationType);
					
				EndIf;
								
			EndIf;			
			
			WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode1, IsOrdinaryProperty);
			Continue;
			
		EndIf;
      		
		RefNode = Undefined;
		
		If PropertiesOCR = Undefined
			And IsBlankString(OCRName) Then
			
			PropertySet = False;
			ValueType = TypeOf(Value);
			TypeRequired = False;
			GetValueSettingPossibility(Value, ValueType, DestinationType, PropertySet, TypeRequired);
						
			If PropertySet Then
				
				// 
				If TypeRequired Then
					
					AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "Type", DestinationType);
					
				EndIf;
				
				AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, "Value", Value);
								              				
			Else
				
				ValueManager = Managers[ValueType];
				
				If ValueManager = Undefined Then
					Continue;
				EndIf;
				
				PropertiesOCR = ValueManager.OCR; // See FindRule
				
				If PropertiesOCR = Undefined Then
					Continue;
				EndIf;
					
				OCRName = PropertiesOCR.Name;
				
			EndIf;
			
		EndIf;
		
		If (PropertiesOCR <> Undefined) 
			Or (Not IsBlankString(OCRName)) Then
			
			If ExportRefOnly Then
				
				If ExportObjectByRef(Value, NodeForExchange) Then
					
					If Not ObjectPassesAllowedObjectFilter(Value) Then
						
						// 
						ExportRefOnly = False;
						
						// 
						RecordStructure = New Structure;
						RecordStructure.Insert("InfobaseNode", NodeForExchange);
						RecordStructure.Insert("SourceUUID", Value);
						RecordStructure.Insert("ObjectExportedByRef", True);
						
						InformationRegisters.InfobaseObjectsMaps.AddRecord(RecordStructure, True);
						
						// 
						// 
						// 
						ExportedByRefObjectsAddValue(Value);
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(ObjectExportStack) Then
				ExportStackBranch = Common.CopyRecursive(ObjectExportStack);
			Else
				ExportStackBranch = New Array;
			EndIf;
			
			RuleWithGlobalExport = False;
			RefNode = ExportByRule(Value, , OutgoingData, , OCRName, , ExportRefOnly, PropertiesOCR, , , , , False, 
				RuleWithGlobalExport, DontUseRulesWithGlobalExportAndDontRememberExported, ExportStackBranch);
	
			If RefNode = Undefined Then
						
				Continue;
						
			EndIf;
			
			If IsBlankString(DestinationType) Then
						
				DestinationType  = PropertiesOCR.Receiver;
				AddAttributeForXMLWriter(PropertyNodeStructure, PropertyNode1, "Type", DestinationType);
														
			EndIf;			
				
			RefNodeType = TypeOf(RefNode);
						
			If RefNodeType = StringType Then
				
				If StrFind(RefNode, "<Ref") > 0 Then
								
					AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode1, "Ref", RefNode);
											
				Else
					
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, "Value", RefNode);
																	
				EndIf;
						
			ElsIf RefNodeType = NumberType Then
				
				If RuleWithGlobalExport Then
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, "Gsn", RefNode);
				Else
					AddValueForXMLWriter(PropertyNodeStructure, PropertyNode1, "NBSp", RefNode);
				EndIf;
														
			Else
				
				RefNode.WriteEndElement();
				InformationToWriteToFile = RefNode.Close();
				
				AddArbitraryDataForXMLWriter(PropertyNodeStructure, PropertyNode1, "Ref", InformationToWriteToFile);
										
			EndIf;
													
		EndIf;
		
		
		
		// 
		
		If PCR.HasAfterExportHandler Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecutePCRHandlerAfterExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
																  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
																  ExtDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode1,
																  RefNode, PropertyCollectionNode, ExtDimensionNode);
					
				Else
					
					Execute(PCR.AfterExport);
					
				EndIf;
				
			Except
				
				WriteErrorInfoPCRHandlers(57, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					OCR, PCR, Source, "AfterExportProperty", Value);
				
			EndTry;
			
			If Cancel Then	//	
				
				Continue;
				
			EndIf;
			
		EndIf;
		
		WriteDataToMasterNode(PropertyCollectionNode, PropertyNodeStructure, PropertyNode1, IsOrdinaryProperty);
		
	EndDo; // 
	
EndProcedure

Procedure DetermineOCRByParameters(OCR, Source, OCRName)
	
	// 
	If OCR = Undefined Then
		
        OCR = FindRule(Source, OCRName);
		
	ElsIf (Not IsBlankString(OCRName))
		And OCR.Name <> OCRName Then
		
		OCR = FindRule(Source, OCRName);
				
	EndIf;	
	
EndProcedure

Function FindPropertyStructureByParameters(OCR, Source)
	
	PropertyStructure = Managers[OCR.Source];
	If PropertyStructure = Undefined Then
		PropertyStructure = Managers[TypeOf(Source)];
	EndIf;	
	
	Return PropertyStructure;
	
EndFunction

Function GetRefByObjectOrRef(Source, ExportingObject)
	
	If ExportingObject Then
		Return Source.Ref;
	Else
		Return Source;
	EndIf;
	
EndFunction

Function DetermineInternalPresentationForSearch(Source, PropertyStructure)
	
	If PropertyStructure.TypeName = "Enum" Then
		Return Source;
	Else
		Return ValueToStringInternal(Source);
	EndIf
	
EndFunction

Procedure UpdateDataInDataToExport()
	
	If DataMapForExportedItemUpdate.Count() > 0 Then
		
		DataMapForExportedItemUpdate.Clear();
		
	EndIf;
	
EndProcedure

Procedure SetExportedToFileObjectFlags()
	
	WrittenToFileSn = SnCounter;
	
EndProcedure

Procedure WriteExchangeObjectPriority(ExchangeObjectsPriority, Node)
	
	If ValueIsFilled(ExchangeObjectsPriority)
		And ExchangeObjectsPriority <> Enums.ExchangeObjectsPriorities.ExchangeObjectHigherPriority Then
		
		If ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectLowerPriority Then
			SetAttribute(Node, "ExchangeObjectPriority", "Below");
		ElsIf ExchangeObjectsPriority = Enums.ExchangeObjectsPriorities.ExchangeObjectPriorityMatch Then
			SetAttribute(Node, "ExchangeObjectPriority", "Matches");
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExportChangeRecordedObjectData(RecordSetForExport)
	
	If RecordSetForExport.Count() = 0 Then // 
		
		Filter = New Structure;
		Filter.Insert("SourceUUID", RecordSetForExport.Filter.SourceUUID.Value);
		Filter.Insert("DestinationUUID", RecordSetForExport.Filter.DestinationUUID.Value);
		Filter.Insert("SourceType",                     RecordSetForExport.Filter.SourceType.Value);
		Filter.Insert("DestinationType",                     RecordSetForExport.Filter.DestinationType.Value);
		
		ExportInfobaseObjectsMapRecord(Filter, True);
		
	Else
		
		For Each SetRow In RecordSetForExport Do
			
			ExportInfobaseObjectsMapRecord(SetRow, False);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ExportInfobaseObjectsMapRecord(SetRow, IsEmptySet)
	
	Receiver = CreateNode("ObjectRegistrationInformation");
	
	SetAttribute(Receiver, "SourceUUID", String(SetRow.SourceUUID.UUID()));
	SetAttribute(Receiver, "DestinationUUID",        SetRow.DestinationUUID);
	SetAttribute(Receiver, "SourceType",                            SetRow.SourceType);
	SetAttribute(Receiver, "DestinationType",                            SetRow.DestinationType);
	
	SetAttribute(Receiver, "IsEmptySet", IsEmptySet);
	
	Receiver.WriteEndElement(); // ObjectRegistrationInformation
	
	WriteToFile(Receiver);
	
EndProcedure

Procedure FireEventsBeforeExportObject(Object, Rule, Properties=Undefined, IncomingData=Undefined, 
	DontExportPropertyObjectsByRefs = False, OCRName, Cancel, OutgoingData)
	
	If CommentObjectProcessingFlag Then
		
		TypeDescription = New TypeDescription("String");
		RowObject  = TypeDescription.AdjustValue(Object);
		If RowObject = "" Then
			ObjectRul = RowObject + "  (" + TypeOf(Object) + ")";
		Else
			ObjectRul = TypeOf(Object);
		EndIf;
		
		EventName = NStr("en = 'Export object: %1';");
		EventName = StringFunctionsClientServer.SubstituteParametersToString(EventName, ObjectRul);
		
		WriteToExecutionProtocol(EventName, , False, 1, 7);
		
	EndIf;
	
	
	OCRName			= Rule.ConversionRule;
	Cancel			= False;
	OutgoingData	= Undefined;
	
	
	// 
	If HasBeforeExportObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object);
				
			Else
				
				Execute(Conversion.BeforeExportObject);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(65, ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
				Rule.Name, NStr("en = 'BeforeExportSelectionObject (global)';"), Object);
		EndTry;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// 
	If Not IsBlankString(Rule.BeforeExport) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerDERBeforeExportObject(ExchangeFile, Cancel, OCRName, Rule, IncomingData, OutgoingData, Object);
				
			Else
				
				Execute(Rule.BeforeExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(33, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "BeforeExportSelectionObject", Object);
		EndTry;
		
	EndIf;		
	
EndProcedure

Procedure FireEventsAfterExportObject(Object, Rule, Properties=Undefined, IncomingData=Undefined, 
	DontExportPropertyObjectsByRefs = False, OCRName, Cancel, OutgoingData)
	
	Var RefNode; // 
	
	// 
	If HasAfterExportObjectGlobalHandler Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionAfterObjectExport(ExchangeFile, Object, OCRName, IncomingData, OutgoingData, RefNode);
				
			Else
				
				Execute(Conversion.AfterExportObject);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(69, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, NStr("en = 'AfterExportSelectionObject (global)';"), Object);
		EndTry;
	EndIf;
	
	// 
	If Not IsBlankString(Rule.AfterExport) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerDERAfterExportObject(ExchangeFile, Object, OCRName, IncomingData, OutgoingData, RefNode, Rule);
				
			Else
				
				Execute(Rule.AfterExport);
				
			EndIf;
			
		Except
			WriteErrorInfoDERHandlers(34, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				Rule.Name, "AfterExportSelectionObject", Object);
		EndTry;
		
	EndIf;
	
EndProcedure

// Unloads the selection object in accordance with the specified rule.
//
// Parameters:
//  Object          - 
//  ExportRule - 
//  Properties        - 
//  IncomingData  - arbitrary auxiliary data.
// 
Function ExportSelectionObject(Object, 
								ExportRule, 
								Properties=Undefined, 
								IncomingData = Undefined,
								DontExportPropertyObjectsByRefs = False, 
								ExportRecordSetRow = False, 
								ParentNode = Undefined, 
								ConstantNameForExport = "",
								OCRName = "",
								FireEvents = True)
								
	Cancel			= False;
	OutgoingData	= Undefined;
		
	If FireEvents
		And ExportRule <> Undefined Then

		OCRName = "";
		
		FireEventsBeforeExportObject(Object, ExportRule, Properties, IncomingData, 
			DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);
		
		If Cancel Then
			Return False;
		EndIf;
		
	EndIf;
	
	RefNode = Undefined;
	ExportByRule(Object, , IncomingData, OutgoingData, OCRName, RefNode, , , Not DontExportPropertyObjectsByRefs, 
		ExportRecordSetRow, ParentNode, ConstantNameForExport, True);
		
		
	If FireEvents
		And ExportRule <> Undefined Then
		
		FireEventsAfterExportObject(Object, ExportRule, Properties, IncomingData, 
		DontExportPropertyObjectsByRefs, OCRName, Cancel, OutgoingData);	
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Returns:
//   ReportBuilder - 
// 
Function ObjectReportBuilder()
	If ReportBuilder = Undefined Then
		ReportBuilder = New ReportBuilder;
	EndIf;
	
	Return ReportBuilder;
EndFunction

Function SelectionForExportWithRestrictions(Rule)
	
	NameOfMetadataObjects = Rule.ObjectForQueryName;
	
	QueryText = 
	"SELECT ALLOWED
	|	Object.Ref AS Ref
	|FROM
	|	&MetadataTableName AS Object
	|{WHERE
	|	Object.Ref.* AS AliasOfADynamicCondition}";
	
	If Not ExportAllowedObjectsOnly Then
		
		QueryText = StrReplace(QueryText, "ALLOWED", ""); // @Query-part-1
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&MetadataTableName", NameOfMetadataObjects);
	QueryText = StrReplace(QueryText, "AliasOfADynamicCondition", StrReplace(NameOfMetadataObjects, ".", "_"));
	
	ObjectReportBuilder().Text = QueryText;
	ObjectReportBuilder().Filter.Reset();
	If Not Rule.BuilderSettings = Undefined Then
		ObjectReportBuilder().SetSettings(Rule.BuilderSettings);
	EndIf;

	ObjectReportBuilder().Execute();
	Selection = ObjectReportBuilder().Result.Select();
		
	Return Selection;
		
EndFunction

Function SelectionToExportByArbitraryAlgorithm(DataSelection)
	
	Selection = Undefined;
	
	If TypeOf(DataSelection) = Type("QueryResultSelection") Then
		
		Selection = DataSelection;
		
	ElsIf TypeOf(DataSelection) = Type("QueryResult") Then
		
		Selection = DataSelection.Select();
		
	ElsIf TypeOf(DataSelection) = Type("Query") Then
		
		QueryResult = DataSelection.Execute();
		Selection          = QueryResult.Select();
		
	EndIf;
	
	Return Selection;
	
EndFunction

Function ConstantsSetStringForExport(ConstantDataTableForExport)
	
	ConstantSetString = "";
	
	For Each TableRow In ConstantDataTableForExport Do
		
		If Not IsBlankString(TableRow.Source) Then
		
			ConstantSetString = ConstantSetString + ", " + TableRow.Source;
			
		EndIf;	
		
	EndDo;	
	
	If Not IsBlankString(ConstantSetString) Then
		
		ConstantSetString = Mid(ConstantSetString, 3);
		
	EndIf;
	
	Return ConstantSetString;
	
EndFunction

Function ExportConstantsSet(Rule, Properties, OutgoingData, ConstantSetNameString = "")
	
	If ConstantSetNameString = "" Then
		ConstantSetNameString = ConstantsSetStringForExport(Properties.OCR.Properties);
	EndIf;
			
	ConstantsSet = Constants.CreateSet(ConstantSetNameString);
	ConstantsSet.Read();
	ExportResult = ExportSelectionObject(ConstantsSet, Rule, Properties, OutgoingData, , , , ConstantSetNameString);	
	Return ExportResult;
	
EndFunction

Function MustSelectAllFields(Rule)
	
	AllFieldsRequiredForSelection = Not IsBlankString(Conversion.BeforeExportObject)
		Or Not IsBlankString(Rule.BeforeExport)
		Or Not IsBlankString(Conversion.AfterExportObject)
		Or Not IsBlankString(Rule.AfterExport);		
		
	Return AllFieldsRequiredForSelection;	
	
EndFunction

Procedure ProcessObjectDeletion(ObjectDeletionData, ErrorMessageString = "")
	
	Ref = ObjectDeletionData.Ref;
	
	EventText = "";
	If Conversion.Property("BeforeSendDeletionInfo", EventText) Then
		
		If Not IsBlankString(EventText) Then
			
			Cancel = False;
			
			Try
				
				If ExportHandlersDebug Then
					
					ExecuteHandlerConversionBeforeSendDeletionInfo(Ref, Cancel);
					
				Else
					
					Execute(EventText);
					
				EndIf;
				
			Except
				ErrorMessageString = WriteErrorInfoConversionHandlers(76, 
					ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
					NStr("en = 'BeforeSendDeletionInfo (conversion)';"));
				
				If Not ContinueOnError Then
					Raise ErrorMessageString;
				EndIf;
				
				Cancel = True;
			EndTry;
			
			If Cancel Then
				Return;
			EndIf;
			
		EndIf;
	EndIf;
	
	Filter = New Structure("Source", TypeOf(Ref));
	RulesForDeletion = ConversionRulesCollection().Copy(Filter, "DestinationType,SourceType");
	RulesForDeletion.GroupBy("DestinationType, SourceType");
	
	If RulesForDeletion.Count() = 0 Then

		WP = ExchangeProtocolRecord(45);
		
		WP.Object = Ref;
		WP.ObjectType = TypeOf(Ref);
		
		WriteToExecutionProtocol(45, WP, True);
		Return;
		
	EndIf;
	
	For Each OCR In RulesForDeletion Do
		WriteToFileObjectDeletion(Ref, OCR.DestinationType, OCR.SourceType);
	EndDo;
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfCompilingExchangeRulesInStructure

// returns the structure of exchange rules.
Function ExchangeRules(Source) Export
	
	ImportExchangeRules(Source, "XMLFile");
	
	If FlagErrors() Then
		Return Undefined;
	EndIf;
	
	// 
	QueriesToSave = New Structure;
	
	For Each StructureItem In Queries Do
		
		QueriesToSave.Insert(StructureItem.Key, StructureItem.Value.Text);
		
	EndDo;
	
	// 
	ParametersToSave = New Structure;
	
	For Each StructureItem In Parameters Do
		
		ParametersToSave.Insert(StructureItem.Key, Undefined);
		
	EndDo;
	
	ExchangeRuleStructure = New Structure;
	
	ExchangeRuleStructure.Insert("RulesStorageFormatVersion", ExchangeRuleStorageFormatVersion());
	
	ExchangeRuleStructure.Insert("Conversion", Conversion);
	
	ExchangeRuleStructure.Insert("ParametersSetupTable", ParametersSetupTable);
	ExchangeRuleStructure.Insert("ExportRulesTable",      ExportRulesTable);
	ExchangeRuleStructure.Insert("ConversionRulesTable",   ConversionRulesTable);
	
	ExchangeRuleStructure.Insert("Algorithms", Algorithms);
	ExchangeRuleStructure.Insert("Parameters", ParametersToSave);
	ExchangeRuleStructure.Insert("Queries",   QueriesToSave);
	
	ExchangeRuleStructure.Insert("XMLRules",              XMLRules);
	ExchangeRuleStructure.Insert("TypesForDestinationString", TypesForDestinationString);
	
	// 
	
	Return ExchangeRuleStructure;
	
EndFunction

#EndRegion

#Region InitializingExchangeRulesTables

// Initializes columns in the table of rules for converting object properties.
//
// Parameters:
//  Tab - ValueTable -  initialized table of property conversion rules.
// 
Procedure InitPropertyConversionRuleTable(Tab)

	Columns = Tab.Columns;

	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("IsFolder",     deTypeDetails("Boolean"));
	Columns.Add("IsSearchField", deTypeDetails("Boolean"));
	Columns.Add("GroupRules");
	Columns.Add("DisabledGroupRules");

	Columns.Add("SourceKind");
	Columns.Add("DestinationKind");
	
	Columns.Add("SimplifiedPropertyExport", deTypeDetails("Boolean"));
	Columns.Add("XMLNodeRequiredOnExport", deTypeDetails("Boolean"));
	Columns.Add("XMLNodeRequiredOnExportGroup", deTypeDetails("Boolean"));

	Columns.Add("SourceType", deTypeDetails("String"));
	Columns.Add("DestinationType", deTypeDetails("String"));
		
	Columns.Add("Source");
	Columns.Add("Receiver");

	Columns.Add("ConversionRule");

	Columns.Add("GetFromIncomingData", deTypeDetails("Boolean"));
	
	Columns.Add("NotReplace",              deTypeDetails("Boolean"));
	Columns.Add("IsRequiredProperty", deTypeDetails("Boolean"));
	
	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	Columns.Add("OnExport");
	Columns.Add("OnExportHandlerName");
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");

	Columns.Add("BeforeProcessExport");
	Columns.Add("BeforeExportProcessHandlerName");
	Columns.Add("AfterProcessExport");
	Columns.Add("AfterExportProcessHandlerName");

	Columns.Add("HasBeforeExportHandler",			deTypeDetails("Boolean"));
	Columns.Add("HasOnExportHandler",				deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportHandler",				deTypeDetails("Boolean"));
	
	Columns.Add("HasBeforeProcessExportHandler",	deTypeDetails("Boolean"));
	Columns.Add("HasAfterProcessExportHandler",	deTypeDetails("Boolean"));
	
	Columns.Add("CastToLength",							deTypeDetails("Number"));
	Columns.Add("ParameterForTransferName", 				deTypeDetails("String"));
	Columns.Add("SearchByEqualDate",					deTypeDetails("Boolean"));
	Columns.Add("ExportGroupToFile",				deTypeDetails("Boolean"));
	
	Columns.Add("SearchFieldsString");
	
EndProcedure

Function CreateExportedObjectTable()
	
	Table = New ValueTable;
	Table.Columns.Add("Key");
	Table.Columns.Add("RefNode");
	Table.Columns.Add("OnlyRefExported",    New TypeDescription("Boolean"));
	Table.Columns.Add("RefSN",                New TypeDescription("Number"));
	Table.Columns.Add("CallCount",      New TypeDescription("Number"));
	Table.Columns.Add("LastCallNumber", New TypeDescription("Number"));
	
	Table.Indexes.Add("Key");
	
	Return Table;
	
EndFunction

// Initializes columns in the object conversion rules table.
// 
Procedure InitConversionRuleTable()

	Columns = ConversionRulesTable.Columns;
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("SynchronizeByID",                        deTypeDetails("Boolean"));
	Columns.Add("DontCreateIfNotFound",                                 deTypeDetails("Boolean"));
	Columns.Add("DontExportPropertyObjectsByRefs",                      deTypeDetails("Boolean"));
	Columns.Add("SearchBySearchFieldsIfNotFoundByID", deTypeDetails("Boolean"));
	Columns.Add("OnExchangeObjectByRefSetGIUDOnly",       deTypeDetails("Boolean"));
	Columns.Add("DontReplaceObjectCreatedInDestinationInfobase",   deTypeDetails("Boolean"));
	Columns.Add("UseQuickSearchOnImport",                     deTypeDetails("Boolean"));
	Columns.Add("GenerateNewNumberOrCodeIfNotSet",                deTypeDetails("Boolean"));
	Columns.Add("TinyObjectCount",                             deTypeDetails("Boolean"));
	Columns.Add("RefExportReferenceCount",                    deTypeDetails("Number"));
	Columns.Add("IBItemsCount",                                  deTypeDetails("Number"));
	
	Columns.Add("ExportMethod");

	Columns.Add("Source");
	Columns.Add("Receiver");
	
	Columns.Add("SourceType", deTypeDetails("String"));
	Columns.Add("DestinationType", deTypeDetails("String"));
	
	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	
	Columns.Add("OnExport");
	Columns.Add("OnExportHandlerName");
	
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");
	
	Columns.Add("AfterExportToFile");
	Columns.Add("AfterExportToFileHandlerName");

	Columns.Add("HasBeforeExportHandler",	deTypeDetails("Boolean"));
	Columns.Add("HasOnExportHandler",		deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportHandler",		deTypeDetails("Boolean"));
	Columns.Add("HasAfterExportToFileHandler",deTypeDetails("Boolean"));

	Columns.Add("BeforeImport");
	Columns.Add("BeforeImportHandlerName");
	
	Columns.Add("OnImport");
	Columns.Add("OnImportHandlerName");
	
	Columns.Add("AfterImport");
	Columns.Add("AfterImportHandlerName");
	
	Columns.Add("SearchFieldSequence");
	Columns.Add("SearchFieldSequenceHandlerName");

	Columns.Add("SearchInTabularSections");
	
	Columns.Add("ExchangeObjectsPriority");
	
	Columns.Add("HasBeforeImportHandler", deTypeDetails("Boolean"));
	Columns.Add("HasOnImportHandler",    deTypeDetails("Boolean"));
	Columns.Add("HasAfterImportHandler",  deTypeDetails("Boolean"));
	
	Columns.Add("HasSearchFieldSequenceHandler",  deTypeDetails("Boolean"));

	Columns.Add("Properties",            deTypeDetails("ValueTable"));
	Columns.Add("SearchProperties",      deTypeDetails("ValueTable"));
	Columns.Add("DisabledProperties", deTypeDetails("ValueTable"));
	
	// 
	// 
	
	// 
	// 
	// 
	Columns.Add("PredefinedDataValues", deTypeDetails("Map"));
	
	// 
	// 
	// 
	Columns.Add("PredefinedDataReadValues", deTypeDetails("Structure"));
	
	Columns.Add("Exported_",                     deTypeDetails("ValueTable"));
	Columns.Add("ExportSourcePresentation", deTypeDetails("Boolean"));
	
	Columns.Add("NotReplace",                  deTypeDetails("Boolean"));
	
	Columns.Add("RememberExportedData",       deTypeDetails("Boolean"));
	Columns.Add("AllObjectsExported",         deTypeDetails("Boolean"));
	
	Columns.Add("SearchFields",  deTypeDetails("String"));
	Columns.Add("TableFields", deTypeDetails("String"));
	
	Columns.Add("AnObjectWithRegisteredRecords", deTypeDetails("Boolean"));
	
EndProcedure

// Initializes columns in the data upload rule table.
//
Procedure InitExportRuleTable()

	Columns = ExportRulesTable.Columns;

	Columns.Add("Enable", deTypeDetails("Boolean"));
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order");

	Columns.Add("DataFilterMethod");
	Columns.Add("SelectionObject1");
	Columns.Add("SelectionObjectMetadata");
	
	Columns.Add("ConversionRule");

	Columns.Add("BeforeProcess");
	Columns.Add("BeforeProcessHandlerName");
	Columns.Add("AfterProcess");
	Columns.Add("AfterProcessHandlerName");

	Columns.Add("BeforeExport");
	Columns.Add("BeforeExportHandlerName");
	Columns.Add("AfterExport");
	Columns.Add("AfterExportHandlerName");
	
	// 
	Columns.Add("UseFilter1", deTypeDetails("Boolean"));
	Columns.Add("BuilderSettings");
	Columns.Add("ObjectForQueryName");
	Columns.Add("ObjectNameForRegisterQuery");
	Columns.Add("DestinationTypeName");
	
	Columns.Add("DoNotExportObjectsCreatedInDestinationInfobase", deTypeDetails("Boolean"));
	
	Columns.Add("ExchangeNodeRef");
	
	Columns.Add("SynchronizeByID", deTypeDetails("Boolean"));
	
EndProcedure

// Initializes columns in the data clearing rules table.
//
Procedure CleaningRuleTableInitialization()

	Columns = CleanupRulesTable.Columns;

	Columns.Add("Enable",  deTypeDetails("Boolean"));
	Columns.Add("IsFolder", deTypeDetails("Boolean"));
	
	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Order", deTypeDetails("Number"));

	Columns.Add("DataFilterMethod");
	Columns.Add("SelectionObject1");
	
	Columns.Add("DeleteForPeriod");
	Columns.Add("Directly", deTypeDetails("Boolean"));

	Columns.Add("BeforeProcess");
	Columns.Add("BeforeProcessHandlerName");
	Columns.Add("AfterProcess");
	Columns.Add("AfterProcessHandlerName");
	Columns.Add("BeforeDeleteRow");
	Columns.Add("BeforeDeleteHandlerName");

EndProcedure

// Initializes columns in the parameter settings table.
//
Procedure ParametersSetupTableInitialization()

	Columns = ParametersSetupTable.Columns;

	Columns.Add("Name");
	Columns.Add("Description");
	Columns.Add("Value");
	Columns.Add("PassParameterOnExport");
	Columns.Add("ConversionRule");

EndProcedure

#EndRegion

#Region InitAttributesAndModuleVariables

Function InitExchangeMessageDataTable(ObjectType)
	
	ExchangeMessageDataTable = New ValueTable;
	
	Columns = ExchangeMessageDataTable.Columns;
	
	// 
	Columns.Add(UUIDColumnName(), StringType36);
	Columns.Add(ColumnNameTypeAsString(),              StringType255);
	
	MetadataObject = Metadata.FindByType(ObjectType);
	
	// 
	ObjectPropertiesDescriptionTable = Common.ObjectPropertiesDetails(MetadataObject, "Name, Type");
	
	For Each PropertyDetails In ObjectPropertiesDescriptionTable Do
		ColumnTypes = New TypeDescription(PropertyDetails.Type, "Null");
		Columns.Add(PropertyDetails.Name, ColumnTypes);
	EndDo;
	
	ExchangeMessageDataTable.Indexes.Add(UUIDColumnName());
	
	Return ExchangeMessageDataTable;
	
EndFunction

Function InitializeDataProcessors()
	
	If ExportHandlersDebug Or ImportHandlersDebug Then 
		Raise
			NStr("en = 'The external data processor (debugger) is not supported.';");
	EndIf;
	
	ExchangePlanName = ExchangePlanName();
	SecurityProfileName = DataExchangeCached.SecurityProfileName(ExchangePlanName);
	Return SecurityProfileName;
	
EndFunction

// Disables processing with handler code that was previously enabled for debugging.
//
Procedure DisableDataProcessorForDebug()
	
	If ExportProcessing <> Undefined Then
		
		Try
			ExportProcessing.DisableDataProcessorForDebug();
		Except
			WriteLogEvent(NStr("en = 'Data exchange';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		ExportProcessing = Undefined;
		
	ElsIf LoadProcessing <> Undefined Then
		
		Try
			LoadProcessing.DisableDataProcessorForDebug();
		Except
			WriteLogEvent(NStr("en = 'Data exchange';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
		LoadProcessing = Undefined;
		
	EndIf;
	
EndProcedure

// Initializes the error Message variable, which contains matches of message codes to their descriptions.
//
// Parameters:
//  No.
// 
Procedure InitMessages()

	ErrorsMessages			= New Map;
		
	ErrorsMessages.Insert(2,  NStr("en = 'Error extracting exchange file. File is locked.';"));
	ErrorsMessages.Insert(3,  NStr("en = 'The exchange rules file does not exist.';"));
	ErrorsMessages.Insert(4,  NStr("en = 'Cannot create COM object: Msxml2.DOMDocument.';"));
	ErrorsMessages.Insert(5,  NStr("en = 'An error occurred when opening an exchange file';"));
	ErrorsMessages.Insert(6,  NStr("en = 'Error importing exchange rules';"));
	ErrorsMessages.Insert(7,  NStr("en = 'Exchange rule format error';"));
	ErrorsMessages.Insert(8,  NStr("en = 'Invalid data export file name';")); // 
	ErrorsMessages.Insert(9,  NStr("en = 'Exchange file format error';"));
	ErrorsMessages.Insert(10, NStr("en = 'Data export file name is not specified';"));
	ErrorsMessages.Insert(11, NStr("en = 'Exchange rules reference a metadata object that does not exist';"));
	ErrorsMessages.Insert(12, NStr("en = 'Exchange rules file name is not specified';"));
			
	ErrorsMessages.Insert(13, NStr("en = 'Error getting value of object property by property name in source infobase';"));
	ErrorsMessages.Insert(14, NStr("en = 'Error getting value of object property by property name in destination infobase';"));
	
	ErrorsMessages.Insert(15, NStr("en = 'Data import file name is not specified';"));
			
	ErrorsMessages.Insert(16, NStr("en = 'Error getting value of subordinate object property by property name in source infobase';"));
	ErrorsMessages.Insert(17, NStr("en = 'Error getting value of subordinate object property by property name in destination infobase';"));
	ErrorsMessages.Insert(18, NStr("en = 'Error creating data processor with handlers code';"));
	ErrorsMessages.Insert(19, NStr("en = 'Event handler error: BeforeImportObject';"));
	ErrorsMessages.Insert(20, NStr("en = 'Event handler error: OnImportObject';"));
	ErrorsMessages.Insert(21, NStr("en = 'Event handler error: AfterImportObject';"));
	ErrorsMessages.Insert(22, NStr("en = 'Event handler error (data conversion): BeforeDataImport';"));
	ErrorsMessages.Insert(23, NStr("en = 'Event handler error (data conversion): AfterImportData';"));
	ErrorsMessages.Insert(24, NStr("en = 'An error occurred when deleting the object';"));
	ErrorsMessages.Insert(25, NStr("en = 'An error occurred when saving the document';"));
	ErrorsMessages.Insert(26, NStr("en = 'An error occurred when saving the object';"));
	ErrorsMessages.Insert(27, NStr("en = 'Event handler error: BeforeProcessClearingRule';"));
	ErrorsMessages.Insert(28, NStr("en = 'Event handler error: AfterProcessClearingRule';"));
	ErrorsMessages.Insert(29, NStr("en = 'Event handler error: BeforeDeleteObject';"));
	
	ErrorsMessages.Insert(31, NStr("en = 'Event handler error: BeforeProcessExportRule';"));
	ErrorsMessages.Insert(32, NStr("en = 'Event handler error: AfterProcessExportRule';"));
	ErrorsMessages.Insert(33, NStr("en = 'Event handler error: BeforeExportObject';"));
	ErrorsMessages.Insert(34, NStr("en = 'Event handler error: AfterExportObject';"));
			
	ErrorsMessages.Insert(41, NStr("en = 'Event handler error: BeforeExportObject';"));
	ErrorsMessages.Insert(42, NStr("en = 'Event handler error: OnExportObject';"));
	ErrorsMessages.Insert(43, NStr("en = 'Event handler error: AfterExportObject';"));
			
	ErrorsMessages.Insert(45, NStr("en = 'Object conversion rule not found';"));
		
	ErrorsMessages.Insert(48, NStr("en = 'Event handler error: BeforeProcessExport (of property group)';"));
	ErrorsMessages.Insert(49, NStr("en = 'Event handler error: AfterProcessExport (of property group)';"));
	ErrorsMessages.Insert(50, NStr("en = 'Event handler error: BeforeExport (of collection object)';"));
	ErrorsMessages.Insert(51, NStr("en = 'Event handler error: OnExport (of collection object)';"));
	ErrorsMessages.Insert(52, NStr("en = 'Event handler error: AfterExport (of collection object)';"));
	ErrorsMessages.Insert(53, NStr("en = 'Global event handler error (data conversion): BeforeImportObject';"));
	ErrorsMessages.Insert(54, NStr("en = 'Global event handler error (data conversion): AfterImportObject';"));
	ErrorsMessages.Insert(55, NStr("en = 'Event handler error: BeforeExport (of property)';"));
	ErrorsMessages.Insert(56, NStr("en = 'Event handler error: OnExport (of property)';"));
	ErrorsMessages.Insert(57, NStr("en = 'Event handler error: AfterExport (of property)';"));
	
	ErrorsMessages.Insert(62, NStr("en = 'Event handler error (data conversion): BeforeExportData';"));
	ErrorsMessages.Insert(63, NStr("en = 'Event handler error (data conversion): AfterExportData';"));
	ErrorsMessages.Insert(64, NStr("en = 'Global event handler error (data conversion): BeforeConvertObject';"));
	ErrorsMessages.Insert(65, NStr("en = 'Global event handler error (data conversion): BeforeExportObject';"));
	ErrorsMessages.Insert(66, NStr("en = 'Error getting collection of subordinate objects from incoming data';"));
	ErrorsMessages.Insert(67, NStr("en = 'Error getting property of subordinate object from incoming data';"));
	ErrorsMessages.Insert(68, NStr("en = 'Error getting object property from incoming data';"));
	
	ErrorsMessages.Insert(69, NStr("en = 'Global event handler error (data conversion): AfterExportObject';"));
	
	ErrorsMessages.Insert(71, NStr("en = 'Cannot find a match for the source value';"));
	
	ErrorsMessages.Insert(72, NStr("en = 'Error exporting data for exchange plan node';"));
	
	ErrorsMessages.Insert(73, NStr("en = 'Event handler error: SearchFieldSequence';"));
	ErrorsMessages.Insert(74, NStr("en = 'To export data, reload data exchange rules.';"));
	
	ErrorsMessages.Insert(75, NStr("en = 'Event handler error (data conversion): AfterImportExchangeRules';"));
	ErrorsMessages.Insert(76, NStr("en = 'Event handler error (data conversion): BeforeSendDeletionInfo';"));
	ErrorsMessages.Insert(77, NStr("en = 'Event handler error (data conversion): OnGetDeletionInfo';"));
	
	ErrorsMessages.Insert(78, NStr("en = 'Algorithm fails after parameter values are imported';"));
	
	ErrorsMessages.Insert(79, NStr("en = 'Event handler error: AfterExportObjectToFile';"));
	
	ErrorsMessages.Insert(80, NStr("en = 'Error marking item for deletion.
		|Predefined items cannot be marked for deletion.';"));
	//
	ErrorsMessages.Insert(83, NStr("en = 'Object table access error. Cannot change the table.';"));
	ErrorsMessages.Insert(84, NStr("en = 'Period-end closing dates conflict.';"));
	
	ErrorsMessages.Insert(173, NStr("en = 'Cannot lock the exchange node. Probably the synchronization is already running.';"));
	ErrorsMessages.Insert(174, NStr("en = 'The exchange message was received earlier.';"));
	ErrorsMessages.Insert(175, NStr("en = 'Event handler error (data conversion): BeforeGetChangedObjects';"));
	ErrorsMessages.Insert(176, NStr("en = 'Event handler error (data conversion): AfterGetExchangeNodesInformation';"));
		
	ErrorsMessages.Insert(1000, NStr("en = 'Cannot create a temporary data export file.';"));
		
EndProcedure

Procedure SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, TypeName, Manager, TypeNamePrefix, SearchByPredefinedItemsPossible = False)
	
	Name              = MetadataObjectsList.Name;
	RefTypeString1 = TypeNamePrefix + "." + Name;
	
	TheTextOfTheSearchQuery = "SELECT Ref FROM &MetadataTableName";
	TheTextOfTheSearchQuery = StrReplace(TheTextOfTheSearchQuery, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("%1.%2", TypeName, Name));
	SearchString = TheTextOfTheSearchQuery + " WHERE ";
	
	QueryTextExports = "SELECT &SearchFieldsParameter FROM &MetadataTableName";
	QueryTextExports = StrReplace(QueryTextExports, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("%1.%2", TypeName, Name));
	RefExportSearchString     = StrReplace(QueryTextExports, "&SearchFieldsParameter", "#SearchFields#");
	
	RefType        = Type(RefTypeString1);
	
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);
	Structure.Insert("SearchString",SearchString);
	Structure.Insert("RefExportSearchString",RefExportSearchString);
	Structure.Insert("SearchByPredefinedItemsPossible",SearchByPredefinedItemsPossible);

	Managers.Insert(RefType, Structure);
	
	
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, True, False);

	ManagersForExchangePlans.Insert(MetadataObjectsList, StructureForExchangePlan);
	
EndProcedure

Procedure SupplementManagerArrayWithRegisterType(Managers, MetadataObjectsList, TypeName, Manager, TypeNamePrefixRecord, SelectionTypeNamePrefix)
	
	Periodic3 = Undefined;
	
	Name					= MetadataObjectsList.Name;
	RefTypeString1	= TypeNamePrefixRecord + "." + Name;
	RefType			= Type(RefTypeString1);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);

	If TypeName = "InformationRegister" Then
		
		Periodic3 = (MetadataObjectsList.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical);
		SubordinateToRecorder = (MetadataObjectsList.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.RecorderSubordinate);
		
		Structure.Insert("Periodic3", Periodic3);
		Structure.Insert("SubordinateToRecorder", SubordinateToRecorder);
		
	EndIf;	
	
	Managers.Insert(RefType, Structure);
		
	StructureForExchangePlan = ExchangePlanParametersStructure(Name, RefType, False, True);

	ManagersForExchangePlans.Insert(MetadataObjectsList, StructureForExchangePlan);
	
	
	RefTypeString1	= SelectionTypeNamePrefix + "." + Name;
	RefType			= Type(RefTypeString1);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);

	If Periodic3 <> Undefined Then
		
		Structure.Insert("Periodic3", Periodic3);
		Structure.Insert("SubordinateToRecorder", SubordinateToRecorder);
		
	EndIf;
	
	Managers.Insert(RefType, Structure);
		
EndProcedure

// Initializes the managers variable, which contains matches of object types to their properties.
//
// Parameters:
//  No.
// 
Procedure ManagersInitialization()

	Managers = New Map;
	
	ManagersForExchangePlans = New Map;
    	
	// References
	
	For Each MetadataObjectsList In Metadata.Catalogs Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "Catalog", Catalogs[MetadataObjectsList.Name], "CatalogRef", True);
					
	EndDo;

	For Each MetadataObjectsList In Metadata.Documents Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "Document", Documents[MetadataObjectsList.Name], "DocumentRef");
				
	EndDo;

	For Each MetadataObjectsList In Metadata.ChartsOfCharacteristicTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "ChartOfCharacteristicTypes", ChartsOfCharacteristicTypes[MetadataObjectsList.Name], "ChartOfCharacteristicTypesRef", True);
				
	EndDo;
	
	For Each MetadataObjectsList In Metadata.ChartsOfAccounts Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "ChartOfAccounts", ChartsOfAccounts[MetadataObjectsList.Name], "ChartOfAccountsRef", True);
						
	EndDo;
	
	For Each MetadataObjectsList In Metadata.ChartsOfCalculationTypes Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "ChartOfCalculationTypes", ChartsOfCalculationTypes[MetadataObjectsList.Name], "ChartOfCalculationTypesRef", True);
				
	EndDo;
	
	For Each MetadataObjectsList In Metadata.ExchangePlans Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "ExchangePlan", ExchangePlans[MetadataObjectsList.Name], "ExchangePlanRef");
				
	EndDo;
	
	For Each MetadataObjectsList In Metadata.Tasks Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "Task", Tasks[MetadataObjectsList.Name], "TaskRef");
				
	EndDo;
	
	For Each MetadataObjectsList In Metadata.BusinessProcesses Do
		
		SupplementManagerArrayWithReferenceType(Managers, ManagersForExchangePlans, MetadataObjectsList, "BusinessProcess", BusinessProcesses[MetadataObjectsList.Name], "BusinessProcessRef");
		
		TypeName = "BusinessProcessRoutePoint";
		// 
		Name              = MetadataObjectsList.Name;
		Manager         = BusinessProcesses[Name].RoutePoints;
		SearchString     = "";
		RefTypeString1 = "BusinessProcessRoutePointRef." + Name;
		RefType        = Type(RefTypeString1);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);
		Structure.Insert("EmptyRef", Undefined);
		Structure.Insert("SearchString", SearchString);

		Managers.Insert(RefType, Structure);
				
	EndDo;
	
	// Registers

	For Each MetadataObjectsList In Metadata.InformationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObjectsList, "InformationRegister", InformationRegisters[MetadataObjectsList.Name], "InformationRegisterRecord", "InformationRegisterSelection");
						
	EndDo;

	For Each MetadataObjectsList In Metadata.AccountingRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObjectsList, "AccountingRegister", AccountingRegisters[MetadataObjectsList.Name], "AccountingRegisterRecord", "AccountingRegisterSelection");
				
	EndDo;
	
	For Each MetadataObjectsList In Metadata.AccumulationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObjectsList, "AccumulationRegister", AccumulationRegisters[MetadataObjectsList.Name], "AccumulationRegisterRecord", "AccumulationRegisterSelection");
						
	EndDo;
	
	For Each MetadataObjectsList In Metadata.CalculationRegisters Do
		
		SupplementManagerArrayWithRegisterType(Managers, MetadataObjectsList, "CalculationRegister", CalculationRegisters[MetadataObjectsList.Name], "CalculationRegisterRecord", "CalculationRegisterSelection");
						
	EndDo;
	
	TypeName = "Enum";
	
	For Each MetadataObjectsList In Metadata.Enums Do
		
		Name              = MetadataObjectsList.Name;
		Manager         = Enums[Name];
		RefTypeString1 = "EnumRef." + Name;
		RefType        = Type(RefTypeString1);
		Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);
		Structure.Insert("EmptyRef", Enums[Name].EmptyRef());

		Managers.Insert(RefType, Structure);
		
	EndDo;
	
	// Constants
	TypeName             = "Constants";
	MetadataObjectsList            = Metadata.Constants;
	Name					= "Constants";
	Manager			= Constants;
	RefTypeString1	= "ConstantsSet";
	RefType			= Type(RefTypeString1);
	Structure = ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList);

	Managers.Insert(RefType, Structure);
	
EndProcedure

Procedure InitManagersAndMessages()
	
	If Managers = Undefined Then
		ManagersInitialization();
	EndIf; 

	If ErrorsMessages = Undefined Then
		InitMessages();
	EndIf;
	
EndProcedure

// Returns:
//   Structure:
//     * FormatVersion - String
//     * ID - String
//     * Description - String
//     * CreationDateTime - Date
//     * SourcePlatformVersion - String
//     * SourceConfigurationSynonym - String
//     * SourceConfigurationVersion - String
//     * Source - String
//     * DestinationPlatformVersion - String
//     * DestinationConfigurationSynonym - String
//     * DestinationConfigurationVersion - String
//     * Receiver - String
//     * AfterImportExchangeRules - String
//     * AfterExchangeRulesImportHandlerName - String
//     * BeforeExportData - String
//     * BeforeDataExportHandlerName - String
//     * BeforeGetChangedObjects - String
//     * BeforeGetChangedObjectsHandlerName - String
//     * AfterGetExchangeNodesInformation - String
//     * AfterGetExchangeNodeDetailsHandlerName - String
//     * AfterExportData - String
//     * AfterDataExportHandlerName - String
//     * BeforeSendDeletionInfo - String
//     * BeforeSendDeletionInformationHandlerName - String
//     * BeforeExportObject - String
//     * BeforeObjectExportHandlerName - String
//     * AfterExportObject - String
//     * AfterObjectExportHandlerName - String
//     * BeforeImportObject - String
//     * BeforeObjectImportHandlerName - String
//     * AfterImportObject - String
//     * AfterObjectImportHandlerName - String
//     * BeforeConvertObject - String
//     * BeforeObjectConversionHandlerName - String
//     * BeforeImportData - String
//     * BeforeDataImportHandlerName - String
//     * AfterImportData - String
//     * AfterImportDataHandlerName - String
//     * AfterImportParameters - String
//     * AfterParametersImportHandlerName - String
//     * OnGetDeletionInfo - String
//     * OnGetDeletionInformationHandlerName - String
//     * DeleteMappedObjectsFromDestinationOnDeleteFromSource - Boolean
//
Function Conversion()
	Return Conversion;
EndFunction

// Returns:
//   Structure:
//     * Name - String
//     * TypeName - String
//     * RefTypeString1 - String
//     * Manager - CatalogManager
//                - DocumentManager
//                - InformationRegisterManager
//                - 
//     * MetadataObjectsList - MetadataObjectCatalog
//                - MetadataObjectDocument
//                - MetadataObjectInformationRegister
//                - 
//     * OCR - ValueTableRow - :
//       ** Properties - See PropertiesConversionRulesCollection
//
Function Managers(Type)
	Return Managers[Type];
EndFunction

Procedure CreateConversionStructure()
	
	Conversion = New Structure("BeforeExportData, AfterExportData, BeforeGetChangedObjects, AfterGetExchangeNodesInformation, BeforeExportObject, AfterExportObject, BeforeConvertObject, BeforeImportObject, AfterImportObject, BeforeImportData, AfterImportData, OnGetDeletionInfo, BeforeSendDeletionInfo");
	Conversion.Insert("DeleteMappedObjectsFromDestinationOnDeleteFromSource", False);
	Conversion.Insert("FormatVersion");
	Conversion.Insert("CreationDateTime");
		
EndProcedure

// Initializes processing details and module variables.
//
Procedure InitAttributesAndModuleVariables()

	VisualExchangeSetupMode = False;
	ProcessedObjectsCountToUpdateStatus = 100;
	
	StoredExportedObjectCountByTypes = 2000;
		
	ParametersInitialized        = False;
	
	Managers    = Undefined;
	ErrorsMessages  = Undefined;
	
	SetErrorFlag2(False);
	
	CreateConversionStructure();
	
	Rules      = New Structure;
	Algorithms    = New Structure;
	AdditionalDataProcessors = New Structure;
	Queries      = New Structure;

	Parameters    = New Structure;
	EventsAfterParametersImport = New Structure;
	
	AdditionalDataProcessorParameters = New Structure;
    	
	XMLRules  = Undefined;
	
	// Types

	StringType                  = Type("String");
	BooleanType                  = Type("Boolean");
	NumberType                   = Type("Number");
	DateType                    = Type("Date");
	ValueStorageType       = Type("ValueStorage");
	UUIDType = Type("UUID");
	BinaryDataType          = Type("BinaryData");
	AccumulationRecordTypeType   = Type("AccumulationRecordType");
	ObjectDeletionType         = Type("ObjectDeletion");
	AccountTypeKind			       = Type("AccountType");
	TypeType                     = Type("Type");
	MapType            = Type("Map");
	TypeDescriptionOfTypes           = Type("TypeDescription");
	
	StringType36  = New TypeDescription("String",, New StringQualifiers(36));
	StringType255 = New TypeDescription("String",, New StringQualifiers(255));
	
	MapRegisterType    = Type("InformationRegisterRecordSet.InfobaseObjectsMaps");

	BlankDateValue		   = Date('00010101');
	
	ObjectsToImportCount     = 0;
	ObjectsToExportCount     = 0;
	ExchangeMessageFileSize      = 0;

	// 
	
	XMLNodeTypeEndElement  = XMLNodeType.EndElement;
	XMLNodeTypeStartElement = XMLNodeType.StartElement;
	XMLNodeTypeText          = XMLNodeType.Text;
	
	DataProtocolFile = Undefined;
	
	TypeAndObjectNameMap = New Map();
	
	EmptyTypeValueMap = New Map;
	TypeDescriptionMap = New Map;
	
	AllowDocumentPosting = Metadata.ObjectProperties.Posting.Allow;
	
	ExchangeRuleInfoImportMode = False;
	
	ExchangeResultField = Undefined;
	
	CustomSearchFieldsInformationOnDataExport = New Map();
	CustomSearchFieldsInformationOnDataImport = New Map();
		
	ObjectMapsRegisterManager = InformationRegisters.InfobaseObjectsMaps;
	
	// 
	InfobaseObjectsMapQuery = New Query;
	InfobaseObjectsMapQuery.Text = "
	|SELECT TOP 1
	|	InfobaseObjectsMaps.SourceUUIDString AS SourceUUIDString
	|FROM
	|	InformationRegister.InfobaseObjectsMaps AS InfobaseObjectsMaps
	|WHERE
	|	  InfobaseObjectsMaps.InfobaseNode           = &InfobaseNode
	|	AND InfobaseObjectsMaps.DestinationUUID = &DestinationUUID
	|	AND InfobaseObjectsMaps.DestinationType                     = &DestinationType
	|	AND InfobaseObjectsMaps.SourceType                     = &SourceType
	|";
	//
	
EndProcedure

Procedure SetErrorFlag2(Value = True)
	
	ErrorFlagField = Value;
	
EndProcedure

Procedure Increment(Value, Val Iterator_SSLy = 1)
	
	If TypeOf(Value) <> Type("Number") Then
		
		Value = 0;
		
	EndIf;
	
	Value = Value + Iterator_SSLy;
	
EndProcedure

Procedure WriteDataImportEnd()
	
	DataExchangeState().ExchangeExecutionResult = ExchangeExecutionResult();
	DataExchangeState().ActionOnExchange         = Enums.ActionsOnExchange.DataImport;
	DataExchangeState().InfobaseNode    = ExchangeNodeDataImport;
	
	InformationRegisters.DataExchangesStates.AddRecord(DataExchangeState());
	
	// 
	If ExchangeExecutionResult() = Enums.ExchangeExecutionResults.Completed2 Then
		
		// 
		RecordStructure = New Structure("InfobaseNode, ActionOnExchange, EndDate");
		FillPropertyValues(RecordStructure, DataExchangeState());
		
		InformationRegisters.SuccessfulDataExchangesStates.AddRecord(RecordStructure);
		
	EndIf;
	
EndProcedure

Procedure IncreaseImportedObjectCounter()
	
	If DataImportedOverExternalConnection Then
		If ImportedObjectCounterExternalConnection > 0 Then
			ImportedObjectsCounterField = ImportedObjectCounterExternalConnection;
		ElsIf ObjectsToImportCountExternalConnection > ImportedObjectCounter() Then
			Increment(ImportedObjectsCounterField);
		EndIf;
	Else
		Increment(ImportedObjectsCounterField);
	EndIf;
	
EndProcedure

Function ManagerParametersStructure(Name, TypeName, RefTypeString1, Manager, MetadataObjectsList)
	Structure = New Structure();
	Structure.Insert("Name", Name);
	Structure.Insert("TypeName", TypeName);
	Structure.Insert("RefTypeString1", RefTypeString1);
	Structure.Insert("Manager", Manager);
	Structure.Insert("MetadataObjectsList", MetadataObjectsList);
	Structure.Insert("SearchByPredefinedItemsPossible", False);
	Structure.Insert("OCR");
	Return Structure;
EndFunction

Function ExchangePlanParametersStructure(Name, RefType, IsReferenceType, IsRegister)
	Structure = New Structure();
	Structure.Insert("Name",Name);
	Structure.Insert("RefType",RefType);
	Structure.Insert("IsReferenceType",IsReferenceType);
	Structure.Insert("IsRegister",IsRegister);
	Return Structure;
EndFunction

#EndRegion

#Region HandlerProcedures

Function PCRPropertyName(LineOfATabularSection)
	
	If ValueIsFilled(LineOfATabularSection.Source) Then
		Property = "_" + TrimAll(LineOfATabularSection.Source);
	ElsIf ValueIsFilled(LineOfATabularSection.Receiver) Then 
		Property = "_" + TrimAll(LineOfATabularSection.Receiver);
	ElsIf ValueIsFilled(LineOfATabularSection.ParameterForTransferName) Then
		Property = "_" + TrimAll(LineOfATabularSection.ParameterForTransferName);
	Else
		Property = "";
	EndIf;
	
	Return Property;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecuteHandlerConversionAfterExchangeRulesImport()
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterExchangeRulesImportHandlerName);
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeDataExport(ExchangeFile, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeDataExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeGetChangedObjects(Recipient, BackgroundExchangeNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Recipient);
	HandlerParameters.Add(BackgroundExchangeNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeGetChangedObjectsHandlerName, HandlerParameters);
	
	Recipient = HandlerParameters[0];
	BackgroundExchangeNode = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterDataExport(ExchangeFile)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterDataExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeObjectExport(ExchangeFile, Cancel, OCRName, Rule,
																IncomingData, OutgoingData, Object)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(Object);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeObjectExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	Rule = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	OutgoingData = HandlerParameters[5];
	Object = HandlerParameters[6];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterObjectExport(ExchangeFile, Object, OCRName, IncomingData,
															   OutgoingData, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.AfterObjectExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Object = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	RefNode = HandlerParameters[5];
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeObjectConversion(HandlerParameters)
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeObjectConversionHandlerName, HandlerParameters);
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeSendDeletionInfo(Ref, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Conversion.BeforeSendDeletionInformationHandlerName, HandlerParameters);
	
	Ref = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeDataImport(ExchangeFile, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.BeforeDataImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterImportData()
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.AfterImportDataHandlerName);
	
EndProcedure

Procedure ExecuteHandlerConversionBeforeImportObject(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
																GenerateNewNumberOrCodeIfNotSet,ObjectTypeString,
																ObjectType, DontReplaceObject, WriteMode, PostingMode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(NBSp);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(RuleName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(GenerateNewNumberOrCodeIfNotSet);
	HandlerParameters.Add(ObjectTypeString);
	HandlerParameters.Add(ObjectType);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.BeforeObjectImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	NBSp = HandlerParameters[2];
	Source = HandlerParameters[3];
	RuleName = HandlerParameters[4];
	Rule = HandlerParameters[5];
	GenerateNewNumberOrCodeIfNotSet = HandlerParameters[6];
	ObjectTypeString = HandlerParameters[7];
	ObjectType = HandlerParameters[8];
	DontReplaceObject = HandlerParameters[9];
	WriteMode = HandlerParameters[10];
	PostingMode = HandlerParameters[11];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
															   ObjectIsModified, ObjectTypeName, ObjectFound)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(ObjectIsModified);
	HandlerParameters.Add(ObjectTypeName);
	HandlerParameters.Add(ObjectFound);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.AfterObjectImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	Ref = HandlerParameters[2];
	Object = HandlerParameters[3];
	ObjectParameters = HandlerParameters[4];
	ObjectIsModified = HandlerParameters[5];
	ObjectTypeName = HandlerParameters[6];
	ObjectFound = HandlerParameters[7];
	
EndProcedure

Procedure ExecuteHandlerConversionOnGetDeletionInfo(Object, Cancel)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Object);
	HandlerParameters.Add(Cancel);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.OnGetDeletionInformationHandlerName, HandlerParameters);
	
	Object = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterParametersImport(ExchangeFile, Cancel, CancelReason)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CancelReason);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, "ConversionAfterParametersImport", HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	CancelReason = HandlerParameters[2];
	
EndProcedure

Procedure ExecuteHandlerConversionAfterGetExchangeNodesInformation(Val ExchangeNodeDataImport)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeNodeDataImport);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Conversion.AfterGetExchangeNodeDetailsHandlerName, HandlerParameters);
	
	ExchangeNodeDataImport = HandlerParameters[0];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecuteOCRHandlerBeforeObjectExport(ExchangeFile, Source, IncomingData, OutgoingData,
														OCRName, OCR, ExportedObjects, Cancel, DataToExportKey,
														RememberExportedData, DontReplaceObjectOnImport,
														AllObjectsExported, GetRefNodeOnly, Receiver,
														WriteMode, PostingMode, DontCreateIfNotFound)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(DataToExportKey);
	HandlerParameters.Add(RememberExportedData);
	HandlerParameters.Add(DontReplaceObjectOnImport);
	HandlerParameters.Add(AllObjectsExported);
	HandlerParameters.Add(GetRefNodeOnly);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	HandlerParameters.Add(DontCreateIfNotFound);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	DataToExportKey = HandlerParameters[8];
	RememberExportedData = HandlerParameters[9];
	DontReplaceObjectOnImport = HandlerParameters[10];
	AllObjectsExported = HandlerParameters[11];
	GetRefNodeOnly = HandlerParameters[12];
	Receiver = HandlerParameters[13];
	WriteMode = HandlerParameters[14];
	PostingMode = HandlerParameters[15];
	DontCreateIfNotFound = HandlerParameters[16];
	
EndProcedure

Procedure ExecuteOCRHandlerOnObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
													 ExportedObjects, DataToExportKey, Cancel, StandardProcessing,
													 Receiver, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(DataToExportKey);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(StandardProcessing);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	DataToExportKey = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	StandardProcessing = HandlerParameters[9];
	Receiver = HandlerParameters[10];
	RefNode = HandlerParameters[11];
	
EndProcedure

Procedure ExecuteOCRHandlerAfterObjectExport(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
													   ExportedObjects, DataToExportKey, Cancel, Receiver, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(DataToExportKey);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.AfterExportHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	DataToExportKey = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Receiver = HandlerParameters[9];
	RefNode = HandlerParameters[10];
	
EndProcedure

Procedure ExecuteOCRHandlerAfterObjectExportToExchangeFile(ExchangeFile, Source, IncomingData, OutgoingData, OCRName, OCR,
																  ExportedObjects, Receiver, RefNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(ExportedObjects);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, OCR.AfterExportToFileHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	IncomingData = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	OCRName = HandlerParameters[4];
	OCR = HandlerParameters[5];
	ExportedObjects = HandlerParameters[6];
	Receiver = HandlerParameters[7];
	RefNode = HandlerParameters[8];
	
EndProcedure

Procedure ExecuteOCRHandlerBeforeObjectImport(ExchangeFile, Cancel, NBSp, Source, RuleName, Rule,
														GenerateNewNumberOrCodeIfNotSet, ObjectTypeString,
														ObjectType,DontReplaceObject, WriteMode, PostingMode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(NBSp);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(RuleName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(GenerateNewNumberOrCodeIfNotSet);
	HandlerParameters.Add(ObjectTypeString);
	HandlerParameters.Add(ObjectType);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(WriteMode);
	HandlerParameters.Add(PostingMode);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.BeforeImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	NBSp = HandlerParameters[2];
	Source = HandlerParameters[3];
	RuleName = HandlerParameters[4];
	Rule = HandlerParameters[5];
	GenerateNewNumberOrCodeIfNotSet = HandlerParameters[6];
	ObjectTypeString = HandlerParameters[7];
	ObjectType = HandlerParameters[8];
	DontReplaceObject = HandlerParameters[9];
	WriteMode = HandlerParameters[10];
	PostingMode = HandlerParameters[11];
	
EndProcedure

Procedure ExecuteOCRHandlerOnObjectImport(ExchangeFile, ObjectFound, Object, DontReplaceObject, ObjectIsModified, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(ObjectFound);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(DontReplaceObject);
	HandlerParameters.Add(ObjectIsModified);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.OnImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	ObjectFound = HandlerParameters[1];
	Object = HandlerParameters[2];
	DontReplaceObject = HandlerParameters[3];
	ObjectIsModified = HandlerParameters[4];
	
EndProcedure

Procedure ExecuteOCRHandlerAfterObjectImport(ExchangeFile, Cancel, Ref, Object, ObjectParameters,
													   ObjectIsModified, ObjectTypeName, ObjectFound, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Ref);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(ObjectIsModified);
	HandlerParameters.Add(ObjectTypeName);
	HandlerParameters.Add(ObjectFound);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.AfterImportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	Ref = HandlerParameters[2];
	Object = HandlerParameters[3];
	ObjectParameters = HandlerParameters[4];
	ObjectIsModified = HandlerParameters[5];
	ObjectTypeName = HandlerParameters[6];
	ObjectFound = HandlerParameters[7];
	
EndProcedure

Procedure ExecuteOCRHandlerSearchFieldsSequence(SearchVariantNumber, SearchProperties, ObjectParameters, StopSearch,
																ObjectReference, SetAllObjectSearchProperties,
																SearchPropertyNameString, HandlerName)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(SearchVariantNumber);
	HandlerParameters.Add(SearchProperties);
	HandlerParameters.Add(ObjectParameters);
	HandlerParameters.Add(StopSearch);
	HandlerParameters.Add(ObjectReference);
	HandlerParameters.Add(SetAllObjectSearchProperties);
	HandlerParameters.Add(SearchPropertyNameString);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, HandlerName, HandlerParameters);
		
	SearchVariantNumber = HandlerParameters[0];
	SearchProperties = HandlerParameters[1];
	ObjectParameters = HandlerParameters[2];
	StopSearch = HandlerParameters[3];
	ObjectReference = HandlerParameters[4];
	SetAllObjectSearchProperties = HandlerParameters[5];
	SearchPropertyNameString = HandlerParameters[6];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecutePCRHandlerBeforeExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
														 PCR, OCR, CollectionObject, Cancel, Value, DestinationType, OCRName,
														 OCRNameExtDimensionType, Empty, Expression, PropertyCollectionNode, NotReplace,
														 ExportObject1)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(DestinationType);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(Empty);
	HandlerParameters.Add(Expression);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(NotReplace);
	HandlerParameters.Add(ExportObject1);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	DestinationType = HandlerParameters[10];
	OCRName = HandlerParameters[11];
	OCRNameExtDimensionType = HandlerParameters[12];
	Empty = HandlerParameters[13];
	Expression = HandlerParameters[14];
	PropertyCollectionNode = HandlerParameters[15];
	NotReplace = HandlerParameters[16];
	ExportObject1 = HandlerParameters[17];
	
EndProcedure

Procedure ExecutePCRHandlerOnExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
													  PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
													  ExtDimension, Empty, OCRName, PropertiesOCR,PropertyNode1, PropertyCollectionNode,
													  OCRNameExtDimensionType, ExportObject1)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(KeyAndValue);
	HandlerParameters.Add(ExtDimensionType);
	HandlerParameters.Add(ExtDimension);
	HandlerParameters.Add(Empty);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(PropertiesOCR);
	HandlerParameters.Add(PropertyNode1);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(ExportObject1);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	KeyAndValue = HandlerParameters[10];
	ExtDimensionType = HandlerParameters[11];
	ExtDimension = HandlerParameters[12];
	Empty = HandlerParameters[13];
	OCRName = HandlerParameters[14];
	PropertiesOCR = HandlerParameters[15];
	PropertyNode1 = HandlerParameters[16];
	PropertyCollectionNode = HandlerParameters[17];
	OCRNameExtDimensionType = HandlerParameters[18];
	ExportObject1 = HandlerParameters[19];
	
EndProcedure

Procedure ExecutePCRHandlerAfterExportProperty(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
														PCR, OCR, CollectionObject, Cancel, Value, KeyAndValue, ExtDimensionType,
														ExtDimension, OCRName, OCRNameExtDimensionType, PropertiesOCR, PropertyNode1,
														RefNode, PropertyCollectionNode, ExtDimensionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(PCR);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(Value);
	HandlerParameters.Add(KeyAndValue);
	HandlerParameters.Add(ExtDimensionType);
	HandlerParameters.Add(ExtDimension);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(OCRNameExtDimensionType);
	HandlerParameters.Add(PropertiesOCR);
	HandlerParameters.Add(PropertyNode1);
	HandlerParameters.Add(RefNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ExtDimensionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PCR.AfterExportHandlerName, HandlerParameters);
		
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	PCR = HandlerParameters[5];
	OCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	Cancel = HandlerParameters[8];
	Value = HandlerParameters[9];
	KeyAndValue = HandlerParameters[10];
	ExtDimensionType = HandlerParameters[11];
	ExtDimension = HandlerParameters[12];
	OCRName = HandlerParameters[13];
	OCRNameExtDimensionType = HandlerParameters[14];
	PropertiesOCR = HandlerParameters[15];
	PropertyNode1 = HandlerParameters[16];
	RefNode = HandlerParameters[17];
	PropertyCollectionNode = HandlerParameters[18];
	ExtDimensionNode = HandlerParameters[19];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecutePGCRHandlerBeforeExportProcessing(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
														   PGCR, Cancel, ObjectCollection1, NotReplace, PropertyCollectionNode, NotClear)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(ObjectCollection1);
	HandlerParameters.Add(NotReplace);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(NotClear);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.BeforeExportProcessHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	ObjectCollection1 = HandlerParameters[8];
	NotReplace = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	NotClear = HandlerParameters[11];
	
EndProcedure

Procedure ExecutePGCRHandlerBeforePropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
														  PGCR, Cancel, CollectionObject, PropertyCollectionNode, ObjectCollectionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ObjectCollectionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	CollectionObject = HandlerParameters[8];
	PropertyCollectionNode = HandlerParameters[9];
	ObjectCollectionNode = HandlerParameters[10];
	
EndProcedure

Procedure ExecutePGCRHandlerOnPropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData, OCR,
													   PGCR, CollectionObject, ObjectCollectionNode, CollectionObjectNode,
													   PropertyCollectionNode, StandardProcessing)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(ObjectCollectionNode);
	HandlerParameters.Add(CollectionObjectNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(StandardProcessing);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.OnExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	CollectionObject = HandlerParameters[7];
	ObjectCollectionNode = HandlerParameters[8];
	CollectionObjectNode = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	StandardProcessing = HandlerParameters[11];
	
EndProcedure

Procedure ExecutePGCRHandlerAfterPropertyExport(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
														 OCR, PGCR, Cancel, CollectionObject, ObjectCollectionNode,
														 PropertyCollectionNode, CollectionObjectNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(CollectionObject);
	HandlerParameters.Add(ObjectCollectionNode);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(CollectionObjectNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.AfterExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	CollectionObject = HandlerParameters[8];
	ObjectCollectionNode = HandlerParameters[9];
	PropertyCollectionNode = HandlerParameters[10];
	CollectionObjectNode = HandlerParameters[11];
	
EndProcedure

Procedure ExecutePGCRHandlerAfterExportProcessing(ExchangeFile, Source, Receiver, IncomingData, OutgoingData,
														  OCR, PGCR, Cancel, PropertyCollectionNode, ObjectCollectionNode)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Source);
	HandlerParameters.Add(Receiver);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(OCR);
	HandlerParameters.Add(PGCR);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(PropertyCollectionNode);
	HandlerParameters.Add(ObjectCollectionNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, PGCR.AfterExportProcessHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Source = HandlerParameters[1];
	Receiver = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	OCR = HandlerParameters[5];
	PGCR = HandlerParameters[6];
	Cancel = HandlerParameters[7];
	PropertyCollectionNode = HandlerParameters[8];
	ObjectCollectionNode = HandlerParameters[9];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecuteHandlerDERBeforeProcessRule(Cancel, OCRName, Rule, OutgoingData, DataSelection)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(DataSelection);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.BeforeProcessHandlerName, HandlerParameters);
	
	Cancel = HandlerParameters[0];
	OCRName = HandlerParameters[1];
	Rule = HandlerParameters[2];
	OutgoingData = HandlerParameters[3];
	DataSelection = HandlerParameters[4];
	
EndProcedure

Procedure ExecuteHandlerDERAfterProcessRule(OCRName, Rule, OutgoingData)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(OutgoingData);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.AfterProcessHandlerName, HandlerParameters);
	
	OCRName = HandlerParameters[0];
	Rule = HandlerParameters[1];
	OutgoingData = HandlerParameters[2];
	
EndProcedure

Procedure ExecuteHandlerDERBeforeExportObject(ExchangeFile, Cancel, OCRName, Rule,
														IncomingData, OutgoingData, Object)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(Object);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.BeforeExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	Rule = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	OutgoingData = HandlerParameters[5];
	Object = HandlerParameters[6];
	
EndProcedure

Procedure ExecuteHandlerDERAfterExportObject(ExchangeFile, Object, OCRName, IncomingData,
													   OutgoingData, RefNode, Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(ExchangeFile);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(OCRName);
	HandlerParameters.Add(IncomingData);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(RefNode);
	
	Common.ExecuteObjectMethod(
		ExportProcessing, Rule.AfterExportHandlerName, HandlerParameters);
	
	ExchangeFile = HandlerParameters[0];
	Object = HandlerParameters[1];
	OCRName = HandlerParameters[2];
	IncomingData = HandlerParameters[3];
	OutgoingData = HandlerParameters[4];
	RefNode = HandlerParameters[5];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecuteHandlerDPRBeforeProcessRule(Rule, Cancel, OutgoingData, DataSelection)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(OutgoingData);
	HandlerParameters.Add(DataSelection);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.BeforeProcessHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	Cancel = HandlerParameters[1];
	OutgoingData = HandlerParameters[2];
	DataSelection = HandlerParameters[3];
	
EndProcedure

Procedure ExecuteHandlerDPRBeforeDeleteObject(Rule, Object, Cancel, DeleteDirectly, IncomingData)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	HandlerParameters.Add(Object);
	HandlerParameters.Add(Cancel);
	HandlerParameters.Add(DeleteDirectly);
	HandlerParameters.Add(IncomingData);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.BeforeDeleteHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	Object = HandlerParameters[1];
	Cancel = HandlerParameters[2];
	DeleteDirectly = HandlerParameters[3];
	IncomingData = HandlerParameters[4];
	
EndProcedure

Procedure ExecuteHandlerDPRAfterProcessRule(Rule)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Rule);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, Rule.AfterProcessHandlerName, HandlerParameters);
	
	Rule = HandlerParameters[0];
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ExecuteHandlerParametersAfterParameterImport(Name, Value)
	
	HandlerParameters = New Array();
	HandlerParameters.Add(Name);
	HandlerParameters.Add(Value);
	
	HandlerName = "Parameters_[ParameterName]_AfterImportParameter";
	HandlerName = StrReplace(HandlerName, "[ParameterName]", Name);
	
	Common.ExecuteObjectMethod(
		LoadProcessing, HandlerName, HandlerParameters);
	
	Name = HandlerParameters[0];
	Value = HandlerParameters[1];
	
EndProcedure

#EndRegion

#Region Constants

Function ExchangeMessageFormatVersion()
	
	Return "3.1";
	
EndFunction

// The version of the storage format of the rules of the exchange format (read rules)
// work which supports this treatment.
//
// The exchange rules are read from the file and stored in the information database in the storage format.
// The format for storing rules may be outdated. In this case, you will need to re-read the exchange rules again.
//
Function ExchangeRuleStorageFormatVersion()
	
	Return 2;
	
EndFunction

#EndRegion

#Region Other

Procedure GetPredefinedDataValues(Val OCR)
	
	OCR.PredefinedDataValues = New Map;
	
	For Each Item In OCR.PredefinedDataReadValues Do
		
		OCR.PredefinedDataValues.Insert(deGetValueByString(Item.Key, OCR.Source), Item.Value);
		
	EndDo;
	
EndProcedure

Function ConfigurationPresentationFromExchangeRules(DefinitionName)
	
	ConfigurationName = "";
	Conversion.Property("ConfigurationSynonym" + DefinitionName, ConfigurationName);
	
	If Not ValueIsFilled(ConfigurationName) Then
		Return "";
	EndIf;
	
	AccurateVersion = "";
	Conversion.Property("ConfigurationVersion" + DefinitionName, AccurateVersion);
	
	If ValueIsFilled(AccurateVersion) Then
		
		AccurateVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(AccurateVersion);
		
		ConfigurationName = ConfigurationName + " version " + AccurateVersion;
		
	EndIf;
	
	Return ConfigurationName;
	
EndFunction

Procedure FillPropertiesForSearch(StructureOfData, PCR)
	
	For Each FieldsString In PCR Do
		
		If FieldsString.IsFolder Then
						
			If FieldsString.DestinationKind = "TabularSection" 
				Or StrFind(FieldsString.DestinationKind, "RecordsSet") > 0 Then
				
				DestinationStructureName = FieldsString.Receiver + ?(FieldsString.DestinationKind = "TabularSection", "TabularSection", "RecordSet");
				
				InternalStructure = StructureOfData[DestinationStructureName];
				
				If InternalStructure = Undefined Then
					InternalStructure = New Map();
				EndIf;
				
				StructureOfData[DestinationStructureName] = InternalStructure;
				
			Else
				
				InternalStructure = StructureOfData;	
				
			EndIf;
			
			FillPropertiesForSearch(InternalStructure, FieldsString.GroupRules);
									
		Else
			
			If IsBlankString(FieldsString.DestinationType)	Then
				
				Continue;
				
			EndIf;
			
			StructureOfData[FieldsString.Receiver] = FieldsString.DestinationType;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteExcessiveItemsFromMap(StructureOfData)
	
	ArrayOfKeysToDelete = New Array;
	
	For Each Item In StructureOfData Do
		
		If TypeOf(Item.Value) = MapType Then
			
			DeleteExcessiveItemsFromMap(Item.Value);
			
			If Item.Value.Count() = 0 Then
				ArrayOfKeysToDelete.Add(Item.Key);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	For Each Var_Key In ArrayOfKeysToDelete Do
		StructureOfData.Delete(Var_Key);
	EndDo;	
	
EndProcedure

Procedure FillInformationByDestinationDataTypes(StructureOfData, Rules)
	
	For Each String In Rules Do
		
		If IsBlankString(String.Receiver) Then
			Continue;
		EndIf;
		
		DataFromStructure = StructureOfData[String.Receiver];
		If DataFromStructure = Undefined Then
			
			DataFromStructure = New Map();
			StructureOfData[String.Receiver] = DataFromStructure;
			
		EndIf;
		
		// 
		FillPropertiesForSearch(DataFromStructure, String.SearchProperties);
				
		// Properties
		FillPropertiesForSearch(DataFromStructure, String.Properties);
		
	EndDo;
	
	DeleteExcessiveItemsFromMap(StructureOfData);	
	
EndProcedure

Procedure CreateStringWithPropertyTypes(XMLWriter, PropertyTypes)
	
	If TypeOf(PropertyTypes.Value) = MapType Then
		
		If PropertyTypes.Value.Count() = 0 Then
			Return;
		EndIf;
		
		XMLWriter.WriteStartElement(PropertyTypes.Key);
		
		For Each Item In PropertyTypes.Value Do
			CreateStringWithPropertyTypes(XMLWriter, Item);
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	Else		
		
		deWriteElement(XMLWriter, PropertyTypes.Key, PropertyTypes.Value);
		
	EndIf;
	
EndProcedure

Function CreateTypesStringForDestination(StructureOfData)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement("DataTypeInformation");	
	
	For Each String In StructureOfData Do
		
		XMLWriter.WriteStartElement("DataType");
		SetAttribute(XMLWriter, "Name", String.Key);
		
		For Each SubordinationRow In String.Value Do
			
			CreateStringWithPropertyTypes(XMLWriter, SubordinationRow);	
			
		EndDo;
		
		XMLWriter.WriteEndElement();
		
	EndDo;	
	
	XMLWriter.WriteEndElement();
	
	ResultString1 = XMLWriter.Close();
	Return ResultString1;
	
EndFunction

Procedure ImportSingleTypeData(ExchangeRules, TypeMap, LocalItemName)
	
	NodeName = LocalItemName;
	
	ExchangeRules.Read();
	
	If (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
		
		ExchangeRules.Read();
		Return;
		
	ElsIf ExchangeRules.NodeType = XMLNodeTypeStartElement Then
			
		// 
		NewMap = New Map;
		TypeMap.Insert(NodeName, NewMap);
		
		ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);
		ExchangeRules.Read();
		
	Else
		
		If ExchangeRules.Value = "TypeDefinition" Then
			
			TypeMap.Insert(NodeName, Type("TypeDescription")); // 
			
		Else
			
			TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
			
		EndIf;
		
		ExchangeRules.Read();
		
	EndIf;
	
	ImportTypeMapForSingleType(ExchangeRules, TypeMap);
	
EndProcedure

Procedure ImportTypeMapForSingleType(ExchangeRules, TypeMap)
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		If (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			
		    Break;
			
		EndIf;
		
		// 
		ExchangeRules.Read();
		
		If ExchangeRules.NodeType = XMLNodeTypeStartElement Then
			
			// 
			NewMap = New Map;
			TypeMap.Insert(NodeName, NewMap);
			
			ImportSingleTypeData(ExchangeRules, NewMap, ExchangeRules.LocalName);			
			
		Else
			
			If ExchangeRules.Value = "TypeDefinition" Then
				
				TypeMap.Insert(NodeName, Type("TypeDescription")); // 
				
			Else
				
				TypeMap.Insert(NodeName, Type(ExchangeRules.Value));
				
			EndIf;
			
			ExchangeRules.Read();
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ImportDataTypeInformation()
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "DataType" Then
			
			TypeName = deAttribute(ExchangeFile, StringType, "Name");
			
			TypeMap = New Map;
			DataForImportTypeMap().Insert(Type(TypeName), TypeMap);

			ImportTypeMapForSingleType(ExchangeFile, TypeMap);	
			
		ElsIf (NodeName = "DataTypeInformation") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

Procedure ImportDataExchangeParameterValues()
	
	Name = deAttribute(ExchangeFile, StringType, "Name");
	
	PropertyType1 = PropertyTypeByAdditionalData(Undefined, Name);
	
	Value = ReadProperty(PropertyType1);
	
	Parameters.Insert(Name, Value);	
	
	AfterParameterImportAlgorithm = "";
	If EventsAfterParametersImport.Property(Name, AfterParameterImportAlgorithm)
		And Not IsBlankString(AfterParameterImportAlgorithm) Then
		
		If ImportHandlersDebug Then
			
			ExecuteHandlerParametersAfterParameterImport(Name, Value);
			
		Else
			
			Execute(AfterParameterImportAlgorithm);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ImportCustomSearchFieldInfo()
	
	RuleName = "";
	SearchSetup = "";
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "RuleName" Then
			
			RuleName = deElementValue(ExchangeFile, StringType);
			
		ElsIf NodeName = "SearchSetup" Then
			
			SearchSetup = deElementValue(ExchangeFile, StringType);
			CustomSearchFieldsInformationOnDataImport.Insert(RuleName, SearchSetup);	
			
		ElsIf (NodeName = "CustomSearchSettings") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break;
			
		EndIf;
		
	EndDo;	
	
EndProcedure

// Re-download rules of the exchange in accordance with the format.
//
// Parameters:
//   Source     - XMLReader
//                - String -  the object from which the exchange rules are loaded;
//   SourceType - String -  a string indicating the source type: "Xmlfile", "ReadXml", "String".
//   ErrorMessageString - String -  error message.
//   ImportRuleHeaderOnly - Boolean -  True if you only need to load the rule header.
// 
Procedure ImportExchangeRules(Source="",
									SourceType="XMLFile",
									ErrorMessageString = "",
									ImportRuleHeaderOnly = False) Export
	
	InitManagersAndMessages();
	
	HasBeforeExportObjectGlobalHandler    = False;
	HasAfterExportObjectGlobalHandler     = False;
	
	HasBeforeConvertObjectGlobalHandler = False;
	
	HasBeforeImportObjectGlobalHandler    = False;
	HasAfterObjectImportGlobalHandler     = False;
	
	CreateConversionStructure();
	
	PropertyConversionRuleTable = New ValueTable;
	InitPropertyConversionRuleTable(PropertyConversionRuleTable);
	
	// 
	
	ExchangeRulesTempFileName = "";
	If IsBlankString(Source) Then
		
		Source = ExchangeRulesFileName;
		
	EndIf;
	
	If SourceType="XMLFile" Then
		
		If IsBlankString(Source) Then
			ErrorMessageString = WriteToExecutionProtocol(12);
			Return; 
		EndIf;
		
		File = New File(Source);
		If Not File.Exists() Then
			ErrorMessageString = WriteToExecutionProtocol(3);
			Return; 
		EndIf;
		
		ExchangeRules = New XMLReader();
		ExchangeRules.OpenFile(Source);
		ExchangeRules.Read();
		
	ElsIf SourceType="String" Then
		
		ExchangeRules = New XMLReader();
		ExchangeRules.SetString(Source);
		ExchangeRules.Read();
		
		WritePackageToFileForArchiveAssembly(Source);
		
	ElsIf SourceType="XMLReader" Then
		
		ExchangeRules = Source;
		
	EndIf;
		
	If Not ((ExchangeRules.LocalName = "ExchangeRules") And (ExchangeRules.NodeType = XMLNodeTypeStartElement)) Then
		ErrorMessageString = WriteToExecutionProtocol(7);
		Return;
	EndIf;
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XMLWriter.WriteStartElement("ExchangeRules");
	
	While ExchangeRules.Read() Do
		
		NodeName = ExchangeRules.LocalName;
		
		// 
		If NodeName = "FormatVersion" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("FormatVersion", Value);
			
			XMLWriter.WriteStartElement("FormatVersion");
			Page1 = XMLString(Value);
			
			XMLWriter.WriteText(Page1);
			XMLWriter.WriteEndElement();
			
		ElsIf NodeName = "ID" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("ID",                   Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Description" Then
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Description",         Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "CreationDateTime" Then
			Value = deElementValue(ExchangeRules, DateType);
			Conversion.Insert("CreationDateTime",    Value);
			deWriteElement(XMLWriter, NodeName, Value);
		ElsIf NodeName = "Source" Then
			
			SourcePlatformVersion = ExchangeRules.GetAttribute ("PlatformVersion");
			SourceConfigurationSynonym = ExchangeRules.GetAttribute ("ConfigurationSynonym");
			SourceConfigurationVersion = ExchangeRules.GetAttribute ("ConfigurationVersion");
			
			Conversion.Insert("SourcePlatformVersion", SourcePlatformVersion);
			Conversion.Insert("SourceConfigurationSynonym", SourceConfigurationSynonym);
			Conversion.Insert("SourceConfigurationVersion", SourceConfigurationVersion);
			
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Source",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
			
		ElsIf NodeName = "Receiver" Then
			
			DestinationPlatformVersion = ExchangeRules.GetAttribute ("PlatformVersion");
			DestinationConfigurationSynonym = ExchangeRules.GetAttribute ("ConfigurationSynonym");
			DestinationConfigurationVersion = ExchangeRules.GetAttribute ("ConfigurationVersion");
			
			Conversion.Insert("DestinationPlatformVersion", DestinationPlatformVersion);
			Conversion.Insert("DestinationConfigurationSynonym", DestinationConfigurationSynonym);
			Conversion.Insert("DestinationConfigurationVersion", DestinationConfigurationVersion);
			
			Value = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("Receiver",             Value);
			deWriteElement(XMLWriter, NodeName, Value);
			
			If ImportRuleHeaderOnly Then
				Return;
			EndIf;
			
		ElsIf NodeName = "CompatibilityMode" Then
			// 
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Comment" Then
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "MainExchangePlan" Then
			deSkip(ExchangeRules);
			
		ElsIf NodeName = "Parameters" Then
			DoImportParameters(ExchangeRules, XMLWriter)

		// 
		
		ElsIf NodeName = "" Then
		
		ElsIf NodeName = "AfterImportExchangeRules" Then
			Conversion.Insert("AfterImportExchangeRules", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterExchangeRulesImportHandlerName","ConversionAfterExchangeRulesImport");
				
		ElsIf NodeName = "BeforeExportData" Then
			Conversion.Insert("BeforeExportData", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeDataExportHandlerName","ConversionBeforeDataExport");
			
		ElsIf NodeName = "BeforeGetChangedObjects" Then
			Conversion.Insert("BeforeGetChangedObjects", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeGetChangedObjectsHandlerName","ConversionBeforeGetChangedObjects");
			
		ElsIf NodeName = "AfterGetExchangeNodesInformation" Then
			
			Conversion.Insert("AfterGetExchangeNodesInformation", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterGetExchangeNodeDetailsHandlerName","ConversionAfterGetExchangeNodeDetails");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterGetExchangeNodesInformation);
						
		ElsIf NodeName = "AfterExportData" Then
			Conversion.Insert("AfterExportData",  deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterDataExportHandlerName","ConversionAfterDataExport");
			
		ElsIf NodeName = "BeforeSendDeletionInfo" Then
			Conversion.Insert("BeforeSendDeletionInfo",  deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeSendDeletionInformationHandlerName","ConversionBeforeSendDeletionInfo");

		ElsIf NodeName = "BeforeExportObject" Then
			Conversion.Insert("BeforeExportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectExportHandlerName","ConversionBeforeExportObject");
			HasBeforeExportObjectGlobalHandler = Not IsBlankString(Conversion.BeforeExportObject);

		ElsIf NodeName = "AfterExportObject" Then
			Conversion.Insert("AfterExportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterObjectExportHandlerName","ConversionAfterExportObject");
			HasAfterExportObjectGlobalHandler = Not IsBlankString(Conversion.AfterExportObject);

		ElsIf NodeName = "BeforeImportObject" Then
			Conversion.Insert("BeforeImportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectImportHandlerName","ConversionBeforeImportObject");
			HasBeforeImportObjectGlobalHandler = Not IsBlankString(Conversion.BeforeImportObject);
			deWriteElement(XMLWriter, NodeName, Conversion.BeforeImportObject);

		ElsIf NodeName = "AfterImportObject" Then
			Conversion.Insert("AfterImportObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterObjectImportHandlerName","ConversionAfterImportObject");
			HasAfterObjectImportGlobalHandler = Not IsBlankString(Conversion.AfterImportObject);
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportObject);

		ElsIf NodeName = "BeforeConvertObject" Then
			Conversion.Insert("BeforeConvertObject", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("BeforeObjectConversionHandlerName","ConversionBeforeObjectConversion");
			HasBeforeConvertObjectGlobalHandler = Not IsBlankString(Conversion.BeforeConvertObject);
			
		ElsIf NodeName = "BeforeImportData" Then
			Conversion.BeforeImportData = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("BeforeDataImportHandlerName","ConversionBeforeDataImport");
			deWriteElement(XMLWriter, NodeName, Conversion.BeforeImportData);
			
		ElsIf NodeName = "AfterImportData" Then
            Conversion.AfterImportData = deElementValue(ExchangeRules, StringType);
			Conversion.Insert("AfterImportDataHandlerName","ConversionAfterImportData");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportData);
			
		ElsIf NodeName = "AfterImportParameters" Then
            Conversion.Insert("AfterImportParameters", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("AfterParametersImportHandlerName","ConversionAfterParametersImport");
			deWriteElement(XMLWriter, NodeName, Conversion.AfterImportParameters);
			
		ElsIf NodeName = "OnGetDeletionInfo" Then
            Conversion.Insert("OnGetDeletionInfo", deElementValue(ExchangeRules, StringType));
			Conversion.Insert("OnGetDeletionInformationHandlerName","ConversionOnGetDeletionInfo");
			deWriteElement(XMLWriter, NodeName, Conversion.OnGetDeletionInfo);
			
		ElsIf NodeName = "DeleteMappedObjectsFromDestinationOnDeleteFromSource" Then
            Conversion.DeleteMappedObjectsFromDestinationOnDeleteFromSource = deElementValue(ExchangeRules, BooleanType);
						
		// Rules
		
		ElsIf NodeName = "DataExportRules" Then
			If ExchangeMode = "Load" Then
				deSkip(ExchangeRules);
			Else
				ImportExportRules(ExchangeRules);
			EndIf; 
			
		ElsIf NodeName = "ObjectsConversionRules" Then
			ImportConversionRules(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "DataClearingRules" Then
			ImportClearingRules(ExchangeRules, XMLWriter)
		
		ElsIf NodeName = "ObjectsRegistrationRules" Then
			deSkip(ExchangeRules);
			
		// 
		
		ElsIf NodeName = "Algorithms" Then
			ImportAlgorithms(ExchangeRules, XMLWriter);
			
		ElsIf NodeName = "Queries" Then
			ImportQueries(ExchangeRules, XMLWriter);

		ElsIf NodeName = "DataProcessors" Then
			ImportDataProcessors(ExchangeRules, XMLWriter);
			
		// 
		ElsIf (NodeName = "ExchangeRules") And (ExchangeRules.NodeType = XMLNodeTypeEndElement) Then
			If ExchangeMode <> "Load" Then
				ExchangeRules.Close();
			EndIf;
			Break;

			
		// 
		Else
			ErrorMessageString = WriteToExecutionProtocol(7);
			Return;
		EndIf;
	EndDo;
	
	XMLWriter.WriteEndElement();
	XMLRules = XMLWriter.Close();
	
	// 
	If Not IsBlankString(ExchangeRulesTempFileName) Then
		Try
			DeleteFiles(ExchangeRulesTempFileName);
		Except
			WriteLogEvent(NStr("en = 'Data exchange';", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	If ImportRuleHeaderOnly Then
		Return;
	EndIf;
	
	// 
	StructureOfData = New Map();
	FillInformationByDestinationDataTypes(StructureOfData, ConversionRulesTable);
	
	TypesForDestinationString = CreateTypesStringForDestination(StructureOfData);
	
	SecurityProfileName = InitializeDataProcessors();
	
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	// 
	AfterExchangeRulesImportEventText = "";
	If ExchangeMode <> "Load" And Conversion.Property("AfterImportExchangeRules", AfterExchangeRulesImportEventText)
		And Not IsBlankString(AfterExchangeRulesImportEventText) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionAfterExchangeRulesImport();
				
			Else
				
				Execute(AfterExchangeRulesImportEventText);
				
			EndIf;
			
		Except
			ErrorMessageString = WriteErrorInfoConversionHandlers(75, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()), 
				NStr("en = 'AfterImportExchangeRules (conversion)';"));
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
	EndIf;
	
	InitializeInitialParameterValues();
	
EndProcedure

Procedure ProcessNewItemReadEnd(LastImportObject = Undefined)
	
	IncreaseImportedObjectCounter();
	
	If ImportedObjectCounter() % 100 = 0
		And GlobalNotWrittenObjectStack.Count() > 100 Then
		
		ExecuteWriteNotWrittenObjects();
		
	EndIf;
	
	// 
	If Not DataImportedOverExternalConnection Then
		
		If UseTransactions
			And ObjectCountPerTransaction > 0 
			And ImportedObjectCounter() % ObjectCountPerTransaction = 0 Then
			
			CommitTransaction();
			BeginTransaction();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure DeleteObjectByLink(Ref, ErrorMessageString)
	
	Object = Ref.GetObject();
	
	If Object = Undefined Then
		Return;
	EndIf;
	
	If DataExchangeEvents.ImportRestricted(Object, ExchangeNodeDataImportObject) Then
		Return;
	EndIf;
	
	SetDataExchangeLoad(Object);
	
	If Not IsBlankString(Conversion.OnGetDeletionInfo) Then
		
		Cancel = False;
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionOnGetDeletionInfo(Object, Cancel);
				
			Else
				
				Execute(Conversion.OnGetDeletionInfo);
				
			EndIf;
			
		Except
			ErrorMessageString = WriteErrorInfoConversionHandlers(77,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'OnGetDeletionInfo (conversion)';"));
				
			Cancel = True;
			
			If Not ContinueOnError Then
				Raise ErrorMessageString;
			EndIf;
			
		EndTry;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	DeleteObject(Object, True);
	
EndProcedure

Procedure ReadObjectDeletion(ErrorMessageString)
	
	SourceTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
	DestinationTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
	
	UUIDAsString1 = deAttribute(ExchangeFile, StringType, "UUID");
	
	ReplaceUUIDIfNecessary(UUIDAsString1, SourceTypeString, DestinationTypeString, True);
	
	PropertyStructure = Managers[Type(SourceTypeString)];
	
	Ref = PropertyStructure.Manager.GetRef(New UUID(UUIDAsString1));
	
	DeleteObjectByLink(Ref, ErrorMessageString);
	
EndProcedure

Procedure ExecuteSelectiveMessageReader(TablesToImport)
	
	If TablesToImport.Count() = 0 Then
		Return;
	EndIf;
	
	MessageReader = Undefined; // See MessageReaderDetails
	Try
		
		SetErrorFlag2(False);
		
		InitializeCommentsOnDataExportAndImport();
		
		CustomSearchFieldsInformationOnDataImport = New Map;
		AdditionalSearchParameterMap = New Map;
		ConversionRulesMap = New Map;
		
		// 
		InitializeKeepExchangeProtocol();
		
		If ProcessedObjectsCountToUpdateStatus = 0 Then
			ProcessedObjectsCountToUpdateStatus = 100;
		EndIf;
		
		GlobalNotWrittenObjectStack = New Map;
		
		ImportedObjectsCounterField = Undefined;
		LastSearchByRefNumber  = 0;
		
		InitManagersAndMessages();
		
		StartReadMessage(MessageReader, True);
		
		If UseTransactions Then
			BeginTransaction();
		EndIf;
		Try
			
			ReadDataForTables(TablesToImport);
			
			If FlagErrors() Then
				Raise NStr("en = 'Data import errors.';");
			EndIf;
			
			// 
			ExecuteWriteNotWrittenObjects();
			
			ExecuteHandlerAfterImportData();
			
			If FlagErrors() Then
				Raise NStr("en = 'Data import errors.';");
			EndIf;
			
			If UseTransactions Then
				CommitTransaction();
			EndIf;
		Except
			If UseTransactions Then
				RollbackTransaction();
			EndIf;
			BreakMessageReader(MessageReader);
			Raise;
		EndTry;
		
		// 
		ExecuteDeferredDocumentsPosting();
		ExecuteDeferredObjectsWrite();
		
		FinishMessageReader(MessageReader);
		
	Except
		If MessageReader <> Undefined
			And MessageReader.MessageReceivedEarlier Then
			WriteToExecutionProtocol(174,,,,,,
				Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted);
		Else
			WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndIf;
	EndTry;
	
	FinishKeepExchangeProtocol();
	
EndProcedure

Procedure RunReadingData(MessageReader)
	
	ErrorMessageString = "";
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
			LastImportObject = ReadObject();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			// 
			LastImportObject = ReadRegisterRecordSet();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			// 
			ReadObjectDeletion(ErrorMessageString);
			
			deSkip(ExchangeFile, "ObjectDeletion");
			
			ProcessNewItemReadEnd();
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			HasObjectRegistrationDataAdjustment = True;
			
			ReadMappingInfoAdjustment();
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(MessageReader);
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // 
			
		Else
			
			Raise NStr("en = 'Exchange message format error';");
			
		EndIf;
		
		// 
		If FlagErrors() Then
			Raise NStr("en = 'Data import errors.';");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadDataForTables(TablesToImport)
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			ObjectTypeString = deAttribute(ExchangeFile, StringType, "Type");
			
			If ObjectTypeString = "ConstantsSet" Then
				
				ConstantName = deAttribute(ExchangeFile, StringType, "ConstantName");
				
				SourceTypeString = ConstantName;
				DestinationTypeString = ConstantName;
				
			Else
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				
				OCR = Rules[RuleName];
				
				SourceTypeString = OCR.SourceType;
				DestinationTypeString = OCR.DestinationType;
				
			EndIf;
			
			DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, False);
			
			If TablesToImport.Find(DataTableKey) <> Undefined Then
				
				If DataImportToInfobaseMode() Then // 
					
					ProcessNewItemReadEnd(ReadObject());
					
				Else // 
					
					UUIDAsString1 = "";
					
					LastImportObject = ReadObject(UUIDAsString1);
					
					If LastImportObject <> Undefined Then
						
						ExchangeMessageDataTable = DataTablesExchangeMessages().Get(DataTableKey);
						
						TableRow = ExchangeMessageDataTable.Find(UUIDAsString1, UUIDColumnName());
						
						If TableRow = Undefined Then
							
							IncreaseImportedObjectCounter();
							
							TableRow = ExchangeMessageDataTable.Add();
							
							TableRow[ColumnNameTypeAsString()]              = DestinationTypeString;
							TableRow["Ref"]                            = LastImportObject.Ref;
							TableRow[UUIDColumnName()] = UUIDAsString1;
							
						EndIf;
						
						// 
						FillPropertyValues(TableRow, LastImportObject);
						
					EndIf;
					
				EndIf;
				
			Else
				
				deSkip(ExchangeFile, NodeName);
				
			EndIf;
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			If DataImportToInfobaseMode() Then
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				
				OCR = Rules[RuleName];
				
				SourceTypeString = OCR.SourceType;
				DestinationTypeString = OCR.DestinationType;
				
				DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, False);
				
				If TablesToImport.Find(DataTableKey) <> Undefined Then
					
					ProcessNewItemReadEnd(ReadRegisterRecordSet());
					
				Else
					
					deSkip(ExchangeFile, NodeName);
					
				EndIf;
				
			Else
				
				deSkip(ExchangeFile, NodeName);
				
			EndIf;
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			DestinationTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			SourceTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			DataTableKey = DataExchangeServer.DataTableKey(SourceTypeString, DestinationTypeString, True);
			
			If TablesToImport.Find(DataTableKey) <> Undefined Then
				
				If DataImportToInfobaseMode() Then // 
					
					// 
					ReadObjectDeletion("");
					
					ProcessNewItemReadEnd();
					
				Else // 
					
					UUIDAsString1 = deAttribute(ExchangeFile, StringType, "UUID");
					
					// 
					ExchangeMessageDataTable = DataTablesExchangeMessages().Get(DataTableKey);
					
					TableRow = ExchangeMessageDataTable.Find(UUIDAsString1, UUIDColumnName());
					
					If TableRow = Undefined Then
						
						IncreaseImportedObjectCounter();
						
						TableRow = ExchangeMessageDataTable.Add();
						
						// 
						For Each Column In ExchangeMessageDataTable.Columns Do
							
							// Filter
							If    Column.Name = ColumnNameTypeAsString()
								Or Column.Name = UUIDColumnName()
								Or Column.Name = "Ref" Then
								Continue;
							EndIf;
							
							If Column.ValueType.ContainsType(StringType) Then
								
								TableRow[Column.Name] = NStr("en = 'Object deletion';");
								
							EndIf;
							
						EndDo;
						
						PropertyStructure = Managers[Type(DestinationTypeString)];
						
						ObjectToDeleteRef = PropertyStructure.Manager.GetRef(New UUID(UUIDAsString1));
						
						TableRow[ColumnNameTypeAsString()]              = DestinationTypeString;
						TableRow["Ref"]                            = ObjectToDeleteRef;
						TableRow[UUIDColumnName()] = UUIDAsString1;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			deSkip(ExchangeFile, NodeName); // 
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			deSkip(ExchangeFile, NodeName); // 
			
		ElsIf NodeName = "CommonNodeData" Then
			
			deSkip(ExchangeFile, NodeName); // 
			
		ElsIf (NodeName = "ExchangeFile") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // 
			
		Else
			
			Raise NStr("en = 'Exchange message format error';");
			
		EndIf;
		
		// 
		If FlagErrors() Then
			Raise NStr("en = 'Data import errors.';");
		EndIf;
		
	EndDo;
	
EndProcedure

// Under the classifier, we understand the reference book, PVC, chart of accounts, and PVR, which
// have the flags set in the PKO to synchronize with the Identifier And continue with the search field of the Searchlipoidentificatorunnashli.
//
Function IsClassifierObject(ObjectTypeString, OCR)
	
	ObjectKind = ObjectTypeString;
	Position = StrFind(ObjectKind, ".");
	If Position > 0 Then
		ObjectKind = Left(ObjectKind, Position - 1);
	EndIf;
	
	If    ObjectKind = "CatalogRef"
		Or ObjectKind = "ChartOfCharacteristicTypesRef"
		Or ObjectKind = "ChartOfAccountsRef"
		Or ObjectKind = "ChartOfCalculationTypesRef" Then
		Return OCR.SynchronizeByID And OCR.SearchBySearchFieldsIfNotFoundByID
	EndIf; 
	
	Return False;
EndFunction

Procedure ReadDataInAnalysisMode(MessageReader, AnalysisParameters = Undefined)
	
	// 
	StatisticsCollectionParameters = New Structure("CollectClassifiersStatistics", False);
	If AnalysisParameters <> Undefined Then
		FillPropertyValues(StatisticsCollectionParameters, AnalysisParameters);
	EndIf;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			ObjectTypeString = deAttribute(ExchangeFile, StringType, "Type");
			
			If ObjectTypeString <> "ConstantsSet" Then
				
				RuleName = deAttribute(ExchangeFile, StringType, "RuleName");
				OCR        = Rules[RuleName];
				
				If StatisticsCollectionParameters.CollectClassifiersStatistics And IsClassifierObject(ObjectTypeString, OCR) Then
					// 
					CollectStatistics = True;
					IsClassifier   = True;
					
				ElsIf Not (OCR.SynchronizeByID And OCR.SearchBySearchFieldsIfNotFoundByID) And OCR.SynchronizeByID Then
					// 
					//  
					// 
					// 

					// 
					// 
					CollectStatistics = True;
					IsClassifier   = False;
					
				Else 
					CollectStatistics = False;
					
				EndIf;
				
				If CollectStatistics Then
					TableRow = PackageHeaderDataTable().Add();
					
					TableRow.ObjectTypeString = ObjectTypeString;
					TableRow.ObjectCountInSource = 1;
					
					TableRow.DestinationTypeString = OCR.DestinationType;
					TableRow.SourceTypeString = OCR.SourceType;
					
					TableRow.SearchFields  = ObjectMappingMechanismSearchFields(OCR.SearchFields);
					TableRow.TableFields = OCR.TableFields;
					
					TableRow.SynchronizeByID    = OCR.SynchronizeByID;
					TableRow.UsePreview = OCR.SynchronizeByID;
					TableRow.IsClassifier   = IsClassifier;
					TableRow.IsObjectDeletion = False;

				EndIf;
				
			EndIf;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectDeletion" Then
			
			TableRow = PackageHeaderDataTable().Add();
			
			TableRow.DestinationTypeString = deAttribute(ExchangeFile, StringType, "DestinationType");
			TableRow.SourceTypeString = deAttribute(ExchangeFile, StringType, "SourceType");
			
			TableRow.ObjectTypeString = TableRow.DestinationTypeString;
			
			TableRow.ObjectCountInSource = 1;
			
			TableRow.SynchronizeByID = False;
			TableRow.UsePreview = True;
			TableRow.IsClassifier = False;
			TableRow.IsObjectDeletion = True;
			
			TableRow.SearchFields = ""; // 
			
			// 
			// 
			ObjectType = Type(TableRow.ObjectTypeString);
			MetadataObject = Metadata.FindByType(ObjectType);
			
			SubstringsArray = ObjectPropertiesDescriptionTable(MetadataObject).UnloadColumn("Name");
			
			// 
			CommonClientServer.DeleteValueFromArray(SubstringsArray, "Ref");
			
			TableRow.TableFields = StrConcat(SubstringsArray, ",");
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			HasObjectRegistrationDataAdjustment = True;
			
			ReadMappingInfoAdjustment();
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(MessageReader);
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") And (ExchangeFile.NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			Raise NStr("en = 'Exchange message format error';");
			
		EndIf;
		
		// 
		If FlagErrors() Then
			Raise NStr("en = 'Data analysis errors.';");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ReadDataInExternalConnectionMode(MessageReader)
	
	ErrorMessageString = "";
	ObjectsToImportCount = ObjectsToImportCountExternalConnection;
	
	While ExchangeFile.Read() Do
		
		NodeName = ExchangeFile.LocalName;
		
		If NodeName = "Object" Then
			
			LastImportObject = ReadObject();
			
			ProcessNewItemReadEnd(LastImportObject);
			
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
			
		ElsIf NodeName = "RegisterRecordSet" Then
			
			// 
			LastImportObject = ReadRegisterRecordSet();
			
			ProcessNewItemReadEnd(LastImportObject);
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
		ElsIf NodeName = "ObjectDeletion" Then
			
			// 
			ReadObjectDeletion(ErrorMessageString);
			
			deSkip(ExchangeFile, "ObjectDeletion");
			
			ProcessNewItemReadEnd();
			DataExchangeServer.CalculateImportPercent(ImportedObjectCounter(), ObjectsToImportCount, ExchangeMessageFileSize);
		ElsIf NodeName = "ObjectRegistrationInformation" Then
			
			HasObjectChangeRecordData = True;
			
			LastImportObject = ReadObjectChangeRecordInfo();
			
			ProcessNewItemReadEnd(LastImportObject);
			
		ElsIf NodeName = "CustomSearchSettings" Then
			
			ImportCustomSearchFieldInfo();
			
		ElsIf NodeName = "DataTypeInformation" Then
			
			If DataForImportTypeMap().Count() > 0 Then
				
				deSkip(ExchangeFile, NodeName);
				
			Else
				ImportDataTypeInformation();
			EndIf;
			
		ElsIf NodeName = "ParameterValue" Then	
			
			ImportDataExchangeParameterValues();
			
		ElsIf NodeName = "AfterParameterExportAlgorithm" Then
			
			Cancel = False;
			CancelReason = "";
			
			AlgorithmText = deElementValue(ExchangeFile, StringType);
			
			If Not IsBlankString(AlgorithmText) Then
				
				Try
					
					If ImportHandlersDebug Then
						
						ExecuteHandlerConversionAfterParametersImport(ExchangeFile, Cancel, CancelReason);
						
					Else
						
						Execute(AlgorithmText);
						
					EndIf;
					
					If Cancel = True Then
						
						If Not IsBlankString(CancelReason) Then
							
							MessageString = NStr("en = 'Data import canceled. Reason: %1';");
							MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CancelReason);
							Raise MessageString;
						Else
							Raise NStr("en = 'Data import canceled';");
						EndIf;
						
					EndIf;
					
				Except
					
					WP = ExchangeProtocolRecord(78, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					WP.Handler     = "AfterImportParameters";
					ErrorMessageString = WriteToExecutionProtocol(78, WP, True);
					
					If Not ContinueOnError Then
						Raise ErrorMessageString;
					EndIf;
					
				EndTry;
				
			EndIf;
			
		ElsIf NodeName = "DataFromExchange" Then
			
			ReadDataViaExchange(MessageReader, False);
			
			deSkip(ExchangeFile, NodeName);
			
			If FlagErrors() Then
				Break;
			EndIf;
			
		ElsIf NodeName = "CommonNodeData" Then
			
			ReadCommonNodeData(Undefined);
			
			deSkip(ExchangeFile, NodeName);
			
			If FlagErrors() Then
				Break;
			EndIf;
			
		ElsIf NodeName = "ObjectRegistrationDataAdjustment" Then
			
			ReadMappingInfoAdjustment();
			
			HasObjectRegistrationDataAdjustment = True;
			
			deSkip(ExchangeFile, NodeName);
			
		ElsIf (NodeName = "ExchangeFile") And (ExchangeFile.NodeType = XMLNodeTypeEndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(ExchangeFile, NodeName);
			
		EndIf;
		
		// 
		If FlagErrors() Then
			Break;
		EndIf;
		
	EndDo;
		
EndProcedure

// Returns:
//   Structure - :
//     * MessageNo - Number
//     * ReceivedNo - Number
//     * Sender - ExchangePlanRef
//     * SenderObject - ExchangePlanObject
//     * MessageReceivedEarlier - Boolean
//     * DataAnalysis - Boolean
//     * BackupRestored - Boolean
//
Function MessageReaderDetails()
	
	MessageReader = New Structure;
	MessageReader.Insert("MessageNo");
	MessageReader.Insert("ReceivedNo");
	MessageReader.Insert("Sender");
	MessageReader.Insert("SenderObject");
	MessageReader.Insert("MessageReceivedEarlier");
	MessageReader.Insert("DataAnalysis");
	MessageReader.Insert("BackupRestored");
	
	Return MessageReader;
	
EndFunction

// Parameters:
//   MessageReader - See MessageReaderDetails
//   DataAnalysis - Boolean
//
Procedure ReadDataViaExchange(MessageReader, DataAnalysis)
	
	ExchangePlanNameField           = deAttribute(ExchangeFile, StringType, "ExchangePlan");
	FromWhomCode                    = deAttribute(ExchangeFile, StringType, "FromWhom");
	MessageNumberField           = deAttribute(ExchangeFile, NumberType,  "OutgoingMessageNumber");
	ReceivedMessageNumberField  = deAttribute(ExchangeFile, NumberType,  "IncomingMessageNumber");
	DeleteChangeRecords  = deAttribute(ExchangeFile, BooleanType, "DeleteChangeRecords");
	SenderVersion            = deAttribute(ExchangeFile, StringType, "SenderVersion");
	
	ExchangeNodeRecipient = ExchangePlans[ExchangePlanName()].FindByCode(FromWhomCode);
	
	// 
	// 
	If Not ValueIsFilled(ExchangeNodeRecipient)
		Or ExchangeNodeRecipient <> ExchangeNodeDataImport Then
		
		MessageString = NStr("en = 'Exchange node for data import is not found. Exchange plan: %1, code: %2.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangePlanName(), FromWhomCode);
		Raise MessageString;
	EndIf;
	
	MessageReader = MessageReaderDetails();
	MessageReader.Sender       = ExchangeNodeRecipient;
	MessageReader.SenderObject = ExchangeNodeRecipient.GetObject();
	MessageReader.MessageNo    = MessageNumberField;
	MessageReader.ReceivedNo    = ReceivedMessageNumberField;
	MessageReader.MessageReceivedEarlier = False;
	MessageReader.DataAnalysis = DataAnalysis;
	MessageReader.Insert("BackupRestored",
		MessageReader.ReceivedNo > Common.ObjectAttributeValue(MessageReader.Sender, "SentNo"));
	
	MessageReader = New FixedStructure(MessageReader);
	
	If DataImportToInfobaseMode() Then
		
		BeginTransaction();
		Try
			ReceivedNo = Common.ObjectAttributeValue(MessageReader.Sender, "ReceivedNo");
			CommitTransaction();
		Except
			RollbackTransaction();
		EndTry;
		
		If ReceivedNo >= MessageReader.MessageNo Then // 
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False); //Structure
			MessageReaderTemporary.MessageReceivedEarlier = True;
			MessageReader = New FixedStructure(MessageReaderTemporary);
			
			Raise NStr("en = 'The exchange message was received earlier.';");
		EndIf;
		
		DeleteChangeRecords = DeleteChangeRecords And Not MessageReader.BackupRestored;
		
		If DeleteChangeRecords Then // 
			
			If TransactionActive() Then
				Raise NStr("en = 'Cannot unregister items in an active transaction.';");
			EndIf;
			
			ExchangePlans.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
			
			InformationRegisters.CommonNodeDataChanges.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
			
			If CommonClientServer.CompareVersions(IncomingExchangeMessageFormatVersion(), "3.1.0.0") >= 0 Then
				
				InformationRegisters.CommonInfobasesNodesSettings.CommitMappingInfoAdjustment(MessageReader.Sender, MessageReader.ReceivedNo);
				
			EndIf;
			
			InformationRegisters.CommonInfobasesNodesSettings.ClearInitialDataExportFlag(MessageReader.Sender, MessageReader.ReceivedNo);
			
		EndIf;
		
		If MessageReader.BackupRestored Then
			DataExchangeServer.OnRestoreFromBackup(MessageReader);
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False); //Structure
			MessageReaderTemporary.SenderObject = MessageReader.Sender.GetObject();
			MessageReader = New FixedStructure(MessageReaderTemporary);
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetCorrespondentVersion(MessageReader.Sender, SenderVersion);
		
	EndIf;
	
	// 
	If Not IsBlankString(Conversion.AfterGetExchangeNodesInformation) Then
		
		Try
			
			If ImportHandlersDebug Then
				
				ExecuteHandlerConversionAfterGetExchangeNodesInformation(MessageReader.Sender);
				
			Else
				
				Execute(Conversion.AfterGetExchangeNodesInformation);
				
			EndIf;
			
		Except
			Raise WriteErrorInfoConversionHandlers(176,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'AfterGetExchangeNodesInformation (conversion)';"));
		EndTry;
		
	EndIf;
	// 
	
EndProcedure

Procedure ReadCommonNodeData(MessageReader)
	
	ExchangeFile.Read();
	
	DataImportModePrevious = DataImportMode;
	
	DataImportMode = "ImportToValueTable";
	
	CommonNode = ReadObject();
	
	IncreaseImportedObjectCounter();
	
	DataImportMode = DataImportModePrevious;
	
	// 
	Ignore = False;
	ExchangePlanName = CommonNode.Metadata().Name;
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnGetSenderData",ExchangePlanName) Then
		ExchangePlans[ExchangePlanName].OnGetSenderData(CommonNode, Ignore);
	
		If Ignore = True Then
			Return;
		EndIf;
	EndIf;
	// 
	
	If DataExchangeEvents.DataDiffers1(CommonNode, CommonNode.Ref.GetObject()) Then
		
		BeginTransaction();
		Try
			
			CommonNode.DataExchange.Load = True;
			CommonNode.Write();
			
			// 
			DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		// 
		// 
		// 
		// 
		//  
		// 
		// 
		// 
		OpenTransaction = False;
		If TransactionActive() Then
			CommitTransaction();
			OpenTransaction = True;
		EndIf;
		
		// 
		InformationRegisters.CommonNodeDataChanges.DeleteChangeRecords(CommonNode.Ref);
		
		// 
		// 
		If OpenTransaction Then
			BeginTransaction();
		EndIf;
		
		If MessageReader <> Undefined
			And CommonNode.Ref = MessageReader.Sender Then
			
			MessageReaderTemporary = Common.CopyRecursive(MessageReader, False);
			MessageReaderTemporary.SenderObject = MessageReader.Sender.GetObject();
			MessageReader = New FixedStructure(MessageReaderTemporary);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteDeferredDocumentsPosting()
	
	DataExchangeServer.ExecuteDeferredDocumentsPosting(
		DocumentsForDeferredPosting(), ExchangeNodeDataImport, AdditionalPropertiesForDeferredPosting());
		
EndProcedure

Procedure ExecuteDeferredObjectsWrite()
	
	DataExchangeServer.ExecuteDeferredObjectsWrite(
		ObjectsForDeferredPosting(), ExchangeNodeDataImport);
	
EndProcedure

Procedure WriteInformationOnDataExchangeOverExchangePlans(Val SentNo)
	
	Receiver = CreateNode("DataFromExchange");
	
	SetAttribute(Receiver, "ExchangePlan", ExchangePlanName());
	SetAttribute(Receiver, "Whom", DataExchangeServer.CorrespondentNodeIDForExchange(NodeForExchange));
	SetAttribute(Receiver, "FromWhom", DataExchangeServer.NodeIDForExchange(NodeForExchange));
	
	ReceivedNo = Common.ObjectAttributeValue(NodeForExchange, "ReceivedNo");
	
	// 
	SetAttribute(Receiver, "OutgoingMessageNumber", SentNo);
	SetAttribute(Receiver, "IncomingMessageNumber",  ReceivedNo);
	SetAttribute(Receiver, "DeleteChangeRecords", True);
	
	SetAttribute(Receiver, "SenderVersion", TrimAll(Metadata.Version));
	
	// 
	Receiver.WriteEndElement();
	
	WriteToFile(Receiver);
	
EndProcedure

Procedure ExportCommonNodeData(Val SentNo)
	
	NodesChangesSelection = InformationRegisters.CommonNodeDataChanges.SelectChanges(NodeForExchange, SentNo);
	
	If NodesChangesSelection.Count() = 0 Then
		Return;
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(NodeForExchange);
	
	CommonNodeData = DataExchangeCached.CommonNodeData(NodeForExchange);
	
	If IsBlankString(CommonNodeData) Then
		Return;
	EndIf;
	
	PropertiesConversionRules = New ValueTable; // See PropertiesConversionRulesCollection
	InitPropertyConversionRuleTable(PropertiesConversionRules);
	
	Properties       = PropertiesConversionRules.Copy(); // See PropertiesConversionRulesCollection
	SearchProperties = PropertiesConversionRules.Copy(); // See PropertiesConversionRulesCollection
	
	CommonNodeMetadata = Metadata.ExchangePlans[ExchangePlanName];
	
	CommonNodeTabularSections = DataExchangeEvents.ObjectTabularSections(CommonNodeMetadata);
	
	CommonNodeProperties = StrSplit(CommonNodeData, ",");
	
	For Each Property In CommonNodeProperties Do
		
		If CommonNodeTabularSections.Find(Property) <> Undefined Then
			
			PCR = Properties.Add();
			PCR.IsFolder = True;
			PCR.SourceKind = "TabularSection";
			PCR.DestinationKind = "TabularSection";
			PCR.Source = Property;
			PCR.Receiver = Property;
			
			PGCRTable = PropertiesConversionRules.Copy(); // See PropertiesConversionRulesCollection
			
			TSMetadata = CommonNodeMetadata.TabularSections[Property]; // MetadataObjectTabularSection
			
			For Each Attribute In TSMetadata.Attributes Do
				
				AttributeName = Attribute.Name;
				
				PGCR = PGCRTable.Add();
				PGCR.IsFolder = False;
				PGCR.SourceKind = "Attribute";
				PGCR.DestinationKind = "Attribute";
				PGCR.Source = AttributeName;
				PGCR.Receiver = AttributeName;
				
			EndDo;
			
			PCR.GroupRules = PGCRTable;
			
		Else
			
			PCR = Properties.Add();
			PCR.IsFolder = False;
			PCR.SourceKind = "Attribute";
			PCR.DestinationKind = "Attribute";
			PCR.Source = Property;
			PCR.Receiver = Property;
			
		EndIf;
		
	EndDo;
	
	PCR = SearchProperties.Add();
	PCR.SourceKind = "Property";
	PCR.DestinationKind = "Property";
	PCR.Source = "Code";
	PCR.Receiver = "Code";
	PCR.SourceType = "String";
	PCR.DestinationType = "String";
	
	OCR = ConversionRulesCollection().Add();
	OCR.SynchronizeByID = False;
	OCR.SearchBySearchFieldsIfNotFoundByID = False;
	OCR.DontExportPropertyObjectsByRefs = True;
	OCR.SourceType = "ExchangePlanRef." + ExchangePlanName;
	OCR.Source = Type(OCR.SourceType);
	OCR.DestinationType = OCR.SourceType;
	OCR.Receiver     = OCR.SourceType;
	
	OCR.Properties = Properties;
	OCR.SearchProperties = SearchProperties;
	
	CommonNode = ExchangePlans[ExchangePlanName].CreateNode();
	DataExchangeEvents.FillObjectPropertiesValues(CommonNode, NodeForExchange.GetObject(), CommonNodeData);
	
	// 
	Ignore = False;
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnSendSenderData", ExchangePlanName) Then
		ExchangePlans[ExchangePlanName].OnSendSenderData(CommonNode, Ignore);
		If Ignore = True Then
			Return;
		EndIf;
	EndIf;
	// 
	
	CommonNode.Code = DataExchangeServer.NodeIDForExchange(NodeForExchange);
	
	XMLNode = CreateNode("CommonNodeData");
	
	ExportByRule(CommonNode,,,,,,, OCR,,, XMLNode);
	
	XMLNode.WriteEndElement();
	
	WriteToFile(XMLNode);
	
EndProcedure

Function ExportRefObjectData(Value, OutgoingData, OCRName, PropertiesOCR, DestinationType, PropertyNode1, Val ExportRefOnly)
	
	IsRuleWithGlobalExport = False;
	RefNode    = ExportByRule(Value, , OutgoingData, , OCRName, , ExportRefOnly, PropertiesOCR, IsRuleWithGlobalExport, , , , False);
	RefNodeType = TypeOf(RefNode);

	If IsBlankString(DestinationType) Then
				
		DestinationType  = PropertiesOCR.Receiver;
		SetAttribute(PropertyNode1, "Type", DestinationType);
				
	EndIf;
			
	If RefNode = Undefined Then
				
		Return Undefined;
				
	EndIf;
				
	AddPropertiesForExport(RefNode, RefNodeType, PropertyNode1, IsRuleWithGlobalExport);	
	
	Return RefNode;
	
EndFunction

Procedure SendOneParameterToDestination(Name, InitialParameterValue, ConversionRule = "")
	
	If IsBlankString(ConversionRule) Then
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		SetAttribute(ParameterNode, "Type", deValueTypeAsString(InitialParameterValue));
		
		ThisNULL = False;
		Empty = deEmpty(InitialParameterValue, ThisNULL);
		
		If Empty Then
			
			// 
			deWriteElement(ParameterNode, "Empty");
			
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
			
		EndIf;
		
		deWriteElement(ParameterNode, "Value", InitialParameterValue);
		
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);
		
	Else
		
		ParameterNode = CreateNode("ParameterValue");
		
		SetAttribute(ParameterNode, "Name", Name);
		
		ThisNULL = False;
		Empty = deEmpty(InitialParameterValue, ThisNULL);
		
		If Empty Then
			
			PropertiesOCR = FindRule(InitialParameterValue, ConversionRule);
			DestinationType  = PropertiesOCR.Receiver;
			SetAttribute(ParameterNode, "Type", DestinationType);
			
			// 
			deWriteElement(ParameterNode, "Empty");
			
			ParameterNode.WriteEndElement();
			
			WriteToFile(ParameterNode);
			
			Return;
			
		EndIf;
		
		ExportRefObjectData(InitialParameterValue, Undefined, ConversionRule, Undefined, Undefined, ParameterNode, True);
		
		ParameterNode.WriteEndElement();
		
		WriteToFile(ParameterNode);
		
	EndIf;
	
EndProcedure

Procedure SendAdditionalParametersToDestination()
	
	For Each Parameter In ParametersSetupTable Do
		
		If Parameter.PassParameterOnExport = True Then
			
			SendOneParameterToDestination(Parameter.Name, Parameter.Value, Parameter.ConversionRule);
					
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SendTypesInformationToDestination()
	
	If Not IsBlankString(TypesForDestinationString) Then
		WriteToFile(TypesForDestinationString);
	EndIf;
		
EndProcedure

Procedure SendCustomSearchFieldsInformationToDestination()
	
	For Each MapKeyAndValue In CustomSearchFieldsInformationOnDataExport Do
		
		ParameterNode = CreateNode("CustomSearchSettings");
		
		deWriteElement(ParameterNode, "RuleName", MapKeyAndValue.Key);
		deWriteElement(ParameterNode, "SearchSetup", MapKeyAndValue.Value);
		
		ParameterNode.WriteEndElement();
		WriteToFile(ParameterNode);
		
	EndDo;
	
EndProcedure

Procedure InitializeCommentsOnDataExportAndImport()
	
	CommentOnDataExport = "";
	CommentOnDataImport = "";
	
EndProcedure

Procedure ExportedByRefObjectsAddValue(Value)
	
	If ExportedByRefObjects().Find(Value) = Undefined Then
		
		ExportedByRefObjects().Add(Value);
		
	EndIf;
	
EndProcedure

Function ObjectPassesAllowedObjectFilter(Value)
	
	Return InformationRegisters.InfobaseObjectsMaps.ObjectIsInRegister(Value, NodeForExchange);
	
EndFunction

Function ObjectMappingMechanismSearchFields(Val SearchFields)
	
	SearchFieldsCollection = StrSplit(SearchFields, ",");
	
	CommonClientServer.DeleteValueFromArray(SearchFieldsCollection, "IsFolder");
	
	Return StrConcat(SearchFieldsCollection, ",");
EndFunction

Procedure ExecuteExport(ErrorMessageString = "")
	
	ExchangePlanNameField = DataExchangeCached.GetExchangePlanName(NodeForExchange);
	
	ExportMappingInformation = ExportObjectMappingInfo(NodeForExchange);
	
	InitializeCommentsOnDataExportAndImport();
	
	CurrentNestingLevelExportByRule = 0;
	
	DataExportCallStack = New ValueTable;
	DataExportCallStack.Columns.Add("Ref");
	DataExportCallStack.Indexes.Add("Ref");
	
	InitManagersAndMessages();
	
	ExportedObjectsCounterField = Undefined;
	SnCounter 				= 0;
	WrittenToFileSn		= 0;
	
	For Each Rule In ConversionRulesTable Do
		
		Rule.Exported_ = CreateExportedObjectTable();
		
	EndDo;
	
	// 
	UsedExportRulesTable = DataExportRulesCollection().Copy(New Structure("Enable", True));
	UsedExportRulesTable.Indexes.Add("SelectionObjectMetadata");
	
	For Each TableRow In UsedExportRulesTable Do
		
		If Not TableRow.SelectionObject1 = Type("ConstantsSet") Then
			
			TableRow.SelectionObjectMetadata = Metadata.FindByType(TableRow.SelectionObject1);
			
		EndIf;
		
	EndDo;
	
	DataMapForExportedItemUpdate = New Map;
	
	// 
	Cancel = False;
	
	If Not IsBlankString(Conversion.BeforeExportData) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeDataExport(ExchangeFile, Cancel);
				
			Else
				
				Execute(Conversion.BeforeExportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(62, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'BeforeExportData (conversion)';"));
				
			Cancel = True;
		EndTry; 
		
		If Cancel Then // 
			FinishKeepExchangeProtocol();
			Return;
		EndIf;
		
	EndIf;
	// 
	
	SendCustomSearchFieldsInformationToDestination();
	
	SendTypesInformationToDestination();
	
	// 
	SendAdditionalParametersToDestination();
	
	EventTextAfterParametersImport = "";
	If Conversion.Property("AfterImportParameters", EventTextAfterParametersImport)
		And Not IsBlankString(EventTextAfterParametersImport) Then
		
		WritingEvent = New XMLWriter;
		WritingEvent.SetString();
		deWriteElement(WritingEvent, "AfterParameterExportAlgorithm", EventTextAfterParametersImport);
		
		WriteToFile(WritingEvent);
		
	EndIf;
	
	SentNo = Common.ObjectAttributeValue(NodeForExchange, "SentNo") + ?(ExportMappingInformation, 2, 1);
	
	WriteInformationOnDataExchangeOverExchangePlans(SentNo);
	
	ExportCommonNodeData(SentNo);
	
	Cancel = False;
	
	// 
	If ExportMappingInformation Then
		
		XMLWriter = New XMLWriter;
		XMLWriter.SetString();
		WriteMessage1 = ExchangePlans.CreateMessageWriter();
		WriteMessage1.BeginWrite(XMLWriter, NodeForExchange);
		
		Try
			ExportObjectMappingRegister(WriteMessage1, ErrorMessageString);
		Except
			Cancel = True;
		EndTry;
		
		If Cancel Then
			WriteMessage1.CancelWrite();
		Else
			WriteMessage1.EndWrite();
		EndIf;
		
		XMLWriter.Close();
		XMLWriter = Undefined;
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
	// 
	If MustAdjustMappingInfo() Then
		
		ExportMappingInfoAdjustment();
		
	EndIf;
	
	// 
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	WriteMessage1.BeginWrite(XMLWriter, NodeForExchange);
	
	Try
		ExecuteRegisteredDataExport(WriteMessage1, ErrorMessageString, UsedExportRulesTable);
	Except
		Cancel = True;
		WriteToExecutionProtocol(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	// 
	For Each Item In ExportedByRefObjects() Do
		
		ExchangePlans.RecordChanges(WriteMessage1.Recipient, Item);
		
	EndDo;
	
	// 
	If ExportedByRefObjects().Count() > 0 Then
		
		DataExchangeServer.SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo, ExportedByRefObjects());
		
	EndIf;
	
	// 
	If CreatedOnExportObjects().Count() > 0 Then
		
		DataExchangeServer.SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo, CreatedOnExportObjects());
		
	EndIf;
	
	If Cancel Then
		WriteMessage1.CancelWrite();
	Else
		WriteMessage1.EndWrite();
	EndIf;
	
	XMLWriter.Close();
	XMLWriter = Undefined;
	
	// 
	If Not Cancel And Not IsBlankString(Conversion.AfterExportData) Then
		
		Try
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionAfterDataExport(ExchangeFile);
				
			Else
				
				Execute(Conversion.AfterExportData);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(63,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()), NStr("en = 'AfterExportData (conversion)';"));
		EndTry;
	
	EndIf;
	// 
	
EndProcedure

Procedure ExportObjectMappingRegister(WriteMessage1, ErrorMessageString)
	
	// 
	ChangesSelection = DataExchangeServer.SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo, Metadata.InformationRegisters.InfobaseObjectsMaps);
	
	While ChangesSelection.Next() Do
		
		Data = ChangesSelection.Get();
		
		// 
		If Data.Filter.InfobaseNode.Value <> NodeForExchange Then
			Continue;
		ElsIf IsBlankString(Data.Filter.DestinationUUID.Value) Then
			Continue;
		EndIf;
		
		ExportObject = True;
		
		For Each Record In Data Do
			
			If ExportObject And Record.ObjectExportedByRef = True Then
				
				ExportObject = False;
				
			EndIf;
			
		EndDo;
		
		// 
		// 
		If ExportObject Then
			
			ExportChangeRecordedObjectData(Data);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExecuteRegisteredDataExport(WriteMessage1, ErrorMessageString, UsedExportRulesTable)
	
	// 
	Var Cancel, OCRName, DataSelection, OutgoingData;
	// 
	If Not IsBlankString(Conversion.BeforeGetChangedObjects) Then
		
		Try
			
			Recipient = NodeForExchange;
			
			If ExportHandlersDebug Then
				
				ExecuteHandlerConversionBeforeGetChangedObjects(Recipient, BackgroundExchangeNode);
				
			Else
				
				Execute(Conversion.BeforeGetChangedObjects);
				
			EndIf;
			
		Except
			WriteErrorInfoConversionHandlers(175, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
				NStr("en = 'BeforeGetChangedObjects (conversion)';"));
			Return;
		EndTry;
		
	EndIf;
	// 
	
	MetadataToExportArray = UsedExportRulesTable.UnloadColumn("SelectionObjectMetadata");
	
	// 
	If MetadataToExportArray.Find(Undefined) <> Undefined Then
		
		SupplementMetadataToExportArrayWithConstants(MetadataToExportArray);
		
	EndIf;
	
	// 
	DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray);
	
	// 
	// 
	If MetadataToExportArray.Find(Metadata.InformationRegisters.InfobaseObjectsMaps) <> Undefined Then
		
		CommonClientServer.DeleteValueFromArray(MetadataToExportArray, Metadata.InformationRegisters.InfobaseObjectsMaps);
		
	EndIf;
	
	// 
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	InitialDataExport = DataExchangeServer.InitialDataExportFlagIsSet(WriteMessage1.Recipient);
	
	// 
	ChangesSelection = DataExchangeServer.SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo, MetadataToExportArray);
	
	MetadataObjectPrevious      = Undefined;
	PreviousDataExportRule = Undefined;
	DataExportRule           = Undefined;
	ExportingRegister              = False;
	ExportingConstants            = False;
	
	IsExchangeOverExternalConnection = IsExchangeOverExternalConnection();
	
	StartATransactionWhenLoadingData();
	Try
		NodeForExchangeObject = NodeForExchange.GetObject();
		
		While ChangesSelection.Next() Do
			Increment(ObjectsToExportCount);
		EndDo;
		
		ChangesSelection.Reset();
		
		HasImportedObjectsCounterFieldExternalConnection = False;
		If IsExchangeOverExternalConnection() Then
			ImportProcessingAttributes = DataProcessorForDataImport().Metadata().Attributes;
			// 
			If ImportProcessingAttributes.Find("ObjectsToImportCountExternalConnection") <> Undefined Then
				DataProcessorForDataImport().ObjectsToImportCountExternalConnection = ObjectsToExportCount;
			EndIf;
			HasImportedObjectsCounterFieldExternalConnection = ImportProcessingAttributes.Find("ImportedObjectCounterExternalConnection") <> Undefined;
		EndIf;
		
		While ChangesSelection.Next() Do
			
			If IsExchangeOverExternalConnection() Then
				// 
				If HasImportedObjectsCounterFieldExternalConnection Then
					Increment(DataProcessorForDataImport().ImportedObjectCounterExternalConnection);
				EndIf;
			EndIf;
			Increment(ExportedObjectsCounterField);
			
			DataExchangeServer.CalculateExportPercent(ExportedObjectCounter(), ObjectsToExportCount);
			
			Data = ChangesSelection.Get();
			
			ExportDataType = TypeOf(Data);
			
			// 
			If ExportDataType = ObjectDeletionType Then
				
				ProcessObjectDeletion(Data);
				Continue;
				
			ElsIf ExportDataType = MapRegisterType Then
				Continue;
			EndIf;
			
			CurrentMetadataObject = Data.Metadata(); // MetadataObject
			
			// 
			If MetadataObjectPrevious <> CurrentMetadataObject Then
				
				If MetadataObjectPrevious <> Undefined Then
					
					// 
					If PreviousDataExportRule <> Undefined
						And Not IsBlankString(PreviousDataExportRule.AfterProcess) Then
						
						Try
							
							If ExportHandlersDebug Then
								
								ExecuteHandlerDERAfterProcessRule(OCRName, PreviousDataExportRule, OutgoingData);
								
							Else
								
								Execute(PreviousDataExportRule.AfterProcess);
								
							EndIf;
							
						Except
							WriteErrorInfoDERHandlers(32, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
								PreviousDataExportRule["Name"], "AfterProcessDataExport");
						EndTry;
						
					EndIf;
					// 
					
				EndIf;
				
				MetadataObjectPrevious = CurrentMetadataObject;
				
				ExportingRegister = False;
				ExportingConstants = False;
				
				StructureOfData = ManagersForExchangePlans[CurrentMetadataObject];
				
				If StructureOfData = Undefined Then
					
					ExportingConstants = Metadata.Constants.Contains(CurrentMetadataObject);
					
				ElsIf StructureOfData.IsRegister = True Then
					
					ExportingRegister = True;
					
				EndIf;
				
				If ExportingConstants Then
					
					DataExportRule = UsedExportRulesTable.Find(Type("ConstantsSet"), "SelectionObjectMetadata");
					If DataExportRule = Undefined Then
						 
						 DataExportRule = UsedExportRulesTable.Find(Type("ConstantsSet"), "SelectionObject1");
						 
					EndIf;
					
				Else
					
					DataExportRule = UsedExportRulesTable.Find(CurrentMetadataObject, "SelectionObjectMetadata");
					
				EndIf;
				
				PreviousDataExportRule = DataExportRule;
				
				// 
				OutgoingData = Undefined;
				
				If DataExportRule <> Undefined
					And Not IsBlankString(DataExportRule.BeforeProcess) Then
					
					Try
						
						If ExportHandlersDebug Then
							
							ExecuteHandlerDERBeforeProcessRule(Cancel, OCRName, DataExportRule, OutgoingData, DataSelection);
							
						Else
							
							Execute(DataExportRule.BeforeProcess);
							
						EndIf;
						
					Except
						WriteErrorInfoDERHandlers(31, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
							DataExportRule.Name, "BeforeProcessDataExport");
					EndTry;
					
					
				EndIf;
				// 
				
			EndIf;
			
			If ExportDataType <> MapRegisterType Then
				
				// 
				ItemSend = DataItemSend.Auto;
				
				StandardSubsystemsServer.OnSendDataToSlave(Data, ItemSend, InitialDataExport, NodeForExchangeObject);
				
				If ItemSend = DataItemSend.Delete Then
					
					If ExportingRegister Then
						
						// 
						
					Else
						
						// 
						ProcessObjectDeletion(Data);
						Continue;
						
					EndIf;
					
				ElsIf ItemSend = DataItemSend.Ignore Then
					
					Continue;
					
				EndIf;
				
			EndIf;
			
			// 
			If ExportingRegister Then
				
				// 
				ExportRegister(Data, DataExportRule, OutgoingData, DontExportObjectsByRefs);
				
			ElsIf ExportingConstants Then
				
				// 
				Properties = Managers[Type("ConstantsSet")];
				
				ExportConstantsSet(DataExportRule, Properties, OutgoingData, CurrentMetadataObject.Name);
				
			Else
				
				Try
					
					LinkToGoToOnError = Data.Ref;
					
				Except
					
					If False Then // 
						
						Raise;
						
					EndIf;
					
				EndTry;
				
				// 
				ExportSelectionObject(Data, DataExportRule, , OutgoingData, DontExportObjectsByRefs);
				
			EndIf;
			
			CheckTheStartAndCommitOfATransactionWhenLoadingData();
			
		EndDo;
		
		If MetadataObjectPrevious <> Undefined Then
			
			// 
			If DataExportRule <> Undefined
				And Not IsBlankString(DataExportRule.AfterProcess) Then
				
				Try
					
					If ExportHandlersDebug Then
						
						ExecuteHandlerDERAfterProcessRule(OCRName, DataExportRule, OutgoingData);
						
					Else
						
						Execute(DataExportRule.AfterProcess);
						
					EndIf;
					
				Except
					WriteErrorInfoDERHandlers(32, ErrorProcessing.DetailErrorDescription(ErrorInfo()),
						DataExportRule.Name, "AfterProcessDataExport");
				EndTry;
				
			EndIf;
			// 
			
		EndIf;
	
		ToCommitTheTransactionWhenTheDataIsLoaded();
		
	Except
		
		ToCancelATransactionForLoadingData();
		
		Raise(NStr("en = 'Cannot send the data';") + ": " + ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry
	
EndProcedure

Procedure StartATransactionWhenLoadingData()
	
	If IsExchangeOverExternalConnection() Then
		If DataImportExecutedInExternalConnection Then
			If DataProcessorForDataImport().UseTransactions Then
				ExternalConnection.BeginTransaction();
			EndIf;
		Else
			DataProcessorForDataImport().ExternalConnectionBeginTransactionOnDataImport();
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckTheStartAndCommitOfATransactionWhenLoadingData()
	
	If IsExchangeOverExternalConnection() Then
		If DataImportExecutedInExternalConnection Then
			If DataProcessorForDataImport().UseTransactions
				And DataProcessorForDataImport().ObjectCountPerTransaction > 0
				And DataProcessorForDataImport().ImportedObjectCounter() % DataProcessorForDataImport().ObjectCountPerTransaction = 0 Then
				
				// 
				// 
				//  
				// 
				// 
				ExternalConnection.CommitTransaction();
				ExternalConnection.BeginTransaction();
			EndIf;
		Else
			DataProcessorForDataImport().ExternalConnectionCheckTransactionStartAndCommitOnDataImport();
		EndIf;
	EndIf;
	
EndProcedure

Procedure ToCommitTheTransactionWhenTheDataIsLoaded()
	
	If IsExchangeOverExternalConnection() Then
		If DataImportExecutedInExternalConnection Then
			If DataProcessorForDataImport().UseTransactions Then
				If DataProcessorForDataImport().FlagErrors() Then
					Raise(NStr("en = 'Cannot send the data.';"));
				Else
					ExternalConnection.CommitTransaction();
				EndIf;
			EndIf;
		Else
			DataProcessorForDataImport().ExternalConnectionCommitTransactionOnDataImport();
		EndIf;
	EndIf;
	
EndProcedure

Procedure ToCancelATransactionForLoadingData()
	
	If IsExchangeOverExternalConnection() Then
		If DataImportExecutedInExternalConnection Then
			While ExternalConnection.TransactionActive() Do
				ExternalConnection.RollbackTransaction();
			EndDo;
		Else
			DataProcessorForDataImport().ExternalConnectionRollbackTransactionOnDataImport();
		EndIf;
	EndIf;
	
EndProcedure


Procedure WriteEventLogDataExchange1(Comment, Level = Undefined)
	
	If Level = Undefined Then
		Level = EventLogLevel.Error;
	EndIf;
	
	MetadataObject = Undefined;
	
	If     ExchangeNodeDataImport <> Undefined
		And Not ExchangeNodeDataImport.IsEmpty() Then
		
		MetadataObject = ExchangeNodeDataImport.Metadata();
		
	EndIf;
	
	WriteLogEvent(EventLogMessageKey(), Level, MetadataObject,, Comment);
	
EndProcedure

Function ExportObjectMappingInfo(InfobaseNode)
	
	QueryText = "
	|SELECT TOP 1 1
	|FROM
	|	InformationRegister.InfobaseObjectsMaps.Changes AS ComplianceOfObjectsOfInformationDatabasesChanges
	|WHERE
	|	ComplianceOfObjectsOfInformationDatabasesChanges.Node = &InfobaseNode
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function MustAdjustMappingInfo()
	
	SentNo = Common.ObjectAttributeValue(NodeForExchange, "SentNo");
	Return InformationRegisters.CommonInfobasesNodesSettings.MustAdjustMappingInfo(
		NodeForExchange, SentNo + 1);
	
EndFunction

Procedure DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray)
	
	If MetadataToExportArray.Find(Undefined) <> Undefined Then
		
		CommonClientServer.DeleteValueFromArray(MetadataToExportArray, Undefined);
		
		DeleteInvalidValuesFromMetadataToExportArray(MetadataToExportArray);
		
	EndIf;
	
EndProcedure

Procedure SupplementMetadataToExportArrayWithConstants(MetadataToExportArray)
	
	Content = Metadata.ExchangePlans[ExchangePlanName()].Content;
	
	For Each MetadataObjectConstant In Metadata.Constants Do
		
		If Content.Contains(MetadataObjectConstant) Then
			
			MetadataToExportArray.Add(MetadataObjectConstant);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure WritePackageToFileForArchiveAssembly(Source)
	
	If Not PutMessageToArchiveWithExternalConnection Then
		Return;
	EndIf;
	
	FileName = TempDirForArchiveAssembly + PackageNumber + ".xml";
	PackageNumber = PackageNumber + 1;
	
	TextDocument = New TextDocument;
	TextDocument.AddLine(Source);
	TextDocument.Write(FileName, , Chars.LF);
	
EndProcedure

Procedure CollectAndArchiveExchangeMessage()

	If Not PutMessageToArchiveWithExternalConnection Then
		Return;
	EndIf;
	
	NameOfCommonFile = TempDirForArchiveAssembly + String(New UUID) + ".xml";

	TextDocument = New TextDocument;
	
	For Cnt = 0 To (PackageNumber - 1) Do
		
		FileName = TempDirForArchiveAssembly + Cnt + ".xml";
		Read = New TextReader(FileName);
		String = Read.Read();
		Read = Undefined;
		
		TextDocument.AddLine(String);
		
	EndDo;
	
	TextDocument.AddLine("</ExchangeFile>");
	TextDocument.Write(NameOfCommonFile, , Chars.LF);
	TextDocument = Undefined;
	
	InformationRegisters.ArchiveOfExchangeMessages.PackMessageToArchive(ExchangeNodeDataImport, NameOfCommonFile);
	
	DeleteFiles(TempDirForArchiveAssembly);
	
EndProcedure

Procedure WriteMessageHeaderToArchive()
	
	FileName = TempDirForArchiveAssembly +  PackageNumber + ".xml";
	
	PackageNumber = PackageNumber + 1;
	
	ExchangeFile = New TextWriter;
	ExchangeFile.Open(FileName, TextEncoding.UTF8);
	
	XMLInfoString = "<?xml version=""1.0"" encoding=""UTF-8""?>";
	
	ExchangeFile.WriteLine(XMLInfoString);

	TempXMLWriter = New XMLWriter();
	
	TempXMLWriter.SetString();
	
	TempXMLWriter.WriteStartElement("ExchangeFile");
	
	SetAttribute(TempXMLWriter, "FormatVersion", 				 ExchangeMessageFormatVersion());
	SetAttribute(TempXMLWriter, "ExportDate",				 CurrentSessionDate());
	SetAttribute(TempXMLWriter, "SourceConfigurationName",	 Conversion().Source);
	SetAttribute(TempXMLWriter, "SourceConfigurationVersion", Conversion().SourceConfigurationVersion);
	SetAttribute(TempXMLWriter, "DestinationConfigurationName",	 Conversion().Receiver);
	SetAttribute(TempXMLWriter, "ConversionRulesID",		 Conversion().ID);
	
	TempXMLWriter.WriteEndElement();
	
	Page1 = TempXMLWriter.Close();
	
	Page1 = StrReplace(Page1, "/>", ">");
	
	ExchangeFile.WriteLine(Page1);
	
	ExchangeFile.Close();
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

InitAttributesAndModuleVariables();

InitConversionRuleTable();
InitExportRuleTable();
CleaningRuleTableInitialization();
ParametersSetupTableInitialization();

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf
