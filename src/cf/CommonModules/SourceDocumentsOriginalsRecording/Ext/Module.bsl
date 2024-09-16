///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region FormsEventsHandlers

// Handler for the "append to Server" event in the document form.
//
// Parameters:
//  Form - ClientApplicationForm:
//   * Object - FormDataStructure, DocumentObject - 
//  Placement - FormGroup -  the group where the label about the current state of the original will be located.
//		           If Undefined, then the label will be located in the lower-right corner of the form. Optional. 
//
Procedure OnCreateAtServerDocumentForm(Form, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		DecorationToDisable = Form.Items.Find("OriginalStateDecoration");
		If Not DecorationToDisable = Undefined Then
			DecorationToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));
	
	Form.ChangeAttributes(Attributes);

	OriginalsStates = UsedStates();
	
	FillOriginalStatesChoiceList(Form, OriginalsStates);
	
	If Placement = Undefined Then
		Parent = Form;
	Else
		Parent = Placement;
	EndIf;
	
	OriginalStateDecoration = Form.Items.Add("OriginalStateDecoration", Type("FormDecoration"), Parent);
	OriginalStateDecoration.Type = FormDecorationType.Label;
	OriginalStateDecoration.Hyperlink = True;
	If Placement = Undefined Then
		OriginalStateDecoration.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	EndIf;
	OriginalStateDecoration.SetAction("Click", "Attachable_OriginalStateDecorationClick");

	If ValueIsFilled(Form.Object.Ref) Then
		CurrentOriginalState = OriginalStateInfoByRef(Form.Object.Ref);
		If CurrentOriginalState.Count() = 0 Then
			CurrentOriginalState=NStr("en = '<Original state is unknown>';");
			OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
		Else
			CurrentOriginalState = CurrentOriginalState.SourceDocumentOriginalState;
		EndIf;
	Else
		CurrentOriginalState=NStr("en = '<Original state is unknown>';");
		OriginalStateDecoration.TextColor = StyleColors.InaccessibleCellTextColor;
	EndIf;

	OriginalStateDecoration.Title = CurrentOriginalState;

EndProcedure

// Handler for the "join Server" event in the list form.
//
// Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//  List - FormTable -  the main list of the form.
//  Placement - FormField -  the list column that will be preceded by the new state columns.
//		                       If Undefined, then the columns will be located at the end of the list. Optional.
//
Procedure OnCreateAtServerListForm(Form, List, Placement = Undefined) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False 
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		ColumnToDisable = Form.Items.Find("StateOriginalReceived");
		If Not ColumnToDisable = Undefined Then
			ColumnToDisable.Visible = False;
		EndIf;
		Return;
	EndIf;
	
	// 
	AttributeListState = Form.Items.Insert("StateOriginalReceived",Type("FormField"),List,Placement);
	AttributeListState.Type = FormFieldType.PictureField;
	AttributeListState.TitleLocation = FormItemTitleLocation.None; 
	AttributeListState.ValuesPicture = PictureLib.IconsCollectionSourceDocumentOriginalAvailable;
	AttributeListState.HeaderPicture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	AttributeListState.Title = NStr("en = 'Status ""Hard copy received""';");
	AttributeListState.DataPath = List.Name + ".StateOriginalReceived";
	
	AttributeListState = Form.Items.Insert("SourceDocumentOriginalState",Type("FormField"),List,Placement);
	AttributeListState.Type = FormFieldType.LabelField;
	AttributeListState.CellHyperlink = True; 
	AttributeListState.Title = NStr("en = 'Original state';");
	AttributeListState.DataPath = List.Name + ".SourceDocumentOriginalState";
	
	If Not RightsToChangeState() Then
		Return;
	EndIf;
	
	// 
	Attributes = New Array;
	Attributes.Add(New FormAttribute("OriginalStatesChoiceList", New TypeDescription("ValueList")));	
	Form.ChangeAttributes(Attributes);
	
	OriginalsStates = UsedStates();
	
	If Not Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);
	EndIf;

	FillOriginalStatesChoiceList(Form, OriginalsStates);

EndProcedure

// The event handler for the "Prepolycondensation" list form.
//
// Parameters:
//  ListRows - DynamicListRows - 
//
Procedure OnGetDataAtServer(ListRows) Export
	
	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") = False 
	Or Not AccessRight("Read",Metadata.InformationRegisters.SourceDocumentsOriginalsStates) Then
		Return;
	EndIf;
	
	References = New Array;
	KeyFieldName = "Ref";
	 
	For Each ListLine In ListRows Do
		ListLine = ListRows[ListLine.Key]; 
		If Not ListLine.Data.Property("Ref")
			Or (ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined 
			And ListLine.Appearance.Get("StateOriginalReceived") = Undefined) Then
			Return;
		EndIf;
		References.Add(ListLine.Data[KeyFieldName]);
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	               |	SourceDocumentsOriginalsStates.State AS SourceDocumentOriginalState,
	               |	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	               |	CASE
	               |		WHEN SourceDocumentsOriginalsStates.State = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalReceived)
	               |			THEN 1
	               |		ELSE 0
	               |	END AS StateOriginalReceived,
	               |	SourceDocumentsOriginalsStates.Owner AS Ref
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.OverallState
	               |	AND SourceDocumentsOriginalsStates.Owner IN(&Ref)"; 

	Query.SetParameter("Ref", References);
	
	Selection = Query.Execute().Select();
	If Not ListLine.Appearance.Get("SourceDocumentOriginalState") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				
				String.Data["SourceDocumentOriginalState"] = Selection.SourceDocumentOriginalState;
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", StyleColors.HyperlinkColor); 
			Else
				String.Data["SourceDocumentOriginalState"] = NStr("en = '<Unknown>';");
				String.Appearance["SourceDocumentOriginalState"].SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor); 
			EndIf;
		EndDo;
	EndIf;
	
	If Not ListLine.Appearance.Get("StateOriginalReceived") = Undefined Then
		For Each String In ListRows Do
			String = ListRows[String.Key];
			Selection.Reset();
			If Selection.FindNext(String.Data["Ref"], "Ref") Then 
				String.Data["StateOriginalReceived"] = Selection.StateOriginalReceived;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

// Update commands set status of the original in the form of a list.
//
// Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//  List - FormTable -  the main list of the form.
//
Procedure UpdateOriginalStateCommands(Form, List) Export

	OriginalsStates = UsedStates();

	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		SetConfigureOriginalStateSubmenu = Form.Items.Find("SetConfigureOriginalStateSubmenuNormal");		
		If Not SetConfigureOriginalStateSubmenu = Undefined Then
			Form.Items.Delete(SetConfigureOriginalStateSubmenu);
		EndIf;
		
		SetConfigureOriginalStateSubmenu = Form.Items.Find("SetConfigureOriginalStateSubmenuSeeAlso");		
		If Not SetConfigureOriginalStateSubmenu = Undefined Then
			Form.Items.Delete(SetConfigureOriginalStateSubmenu);
		EndIf;
	EndIf;
	
	OutputOriginalStateCommandsToForm(Form, List, OriginalsStates);

	FillOriginalStatesChoiceList(Form, OriginalsStates);

EndProcedure

// Sets conditional formatting for plug-in items in the list.
//
// Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//  List - FormTable -  the main list of the form.
//
Procedure SetConditionalAppearanceInListForm(Form, List) Export

	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled;
	FilterElement.Use = True;

	AppearanceItem.Appearance.SetParameterValue("Text", NStr("en = '<Unknown>';"));
	AppearanceItem.Appearance.SetParameterValue("TextColor",  StyleColors.InaccessibleCellTextColor);
	AppearanceItem.Use = True;
	
	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;
	
	AppearanceItem = Form.ConditionalAppearance.Items.Add();

	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField(List.Name+".SourceDocumentOriginalState"); 
	FilterElement.ComparisonType = DataCompositionComparisonType.Filled;
	FilterElement.Use = True;
	
	AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	AppearanceItem.Use = True;

	AppearanceField = AppearanceItem.Fields.Items.Add();
	AppearanceField.Field = New DataCompositionField("SourceDocumentOriginalState");
	AppearanceField.Use = True;

EndProcedure

// Adds a role to the profile description of the supplied access groups to change the state of the original. 
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails) Export

	ProfileDetails.Roles.Add("SourceDocumentsOriginalsStatesChange");

EndProcedure

// Adds a role to the profile description of the supplied access groups to configure the original status list.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//  
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesSetup(ProfileDetails) Export

	ProfileDetails.Roles.Add("AddEditSourceDocumentsOriginalsStates");

EndProcedure

// Adds a role to the profile description of the supplied access groups to read the state of the original.
//
// Parameters:
//  ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription.
//
Procedure SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails) Export

	ProfileDetails.Roles.Add("ReadSourceDocumentsOriginalsStates");

EndProcedure

// 
//
//	Returns:
//  Array of CatalogRef.SourceDocumentsOriginalsStates - 
//    
//
Function AllStates() Export
	
	Query = New Query;
	Query.Text ="SELECT ALLOWED
	              |	SourceDocumentsOriginalsStates.Ref AS State
	              |FROM
	              |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	              |WHERE
	              |	NOT SourceDocumentsOriginalsStates.DeletionMark
	              |
	              |ORDER BY
	              |	SourceDocumentsOriginalsStates.AddlOrderingAttribute" ;

	Selection = Query.Execute();

	Return Selection.Unload().UnloadColumn("State");

EndFunction

// Displays plug-in commands in the form. Called without connecting the "Pluggable commands" subsystem.
//
// Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//  List - FormTable -  the main list of the form.
//  OriginalsStates - ValueTable - 
//                                          :
//              * Description 	- String -  name of the original state.
//              * Ref		- CatalogRef.SourceDocumentsOriginalsStates
//
Procedure OutputOriginalStateCommandsToForm(Form, List, OriginalsStates) Export

	// 
	Items = Form.Items;

	If Items.Find("SetConfigureOriginalStateSubmenu") = Undefined Then
		SetConfigureOriginalStateSubmenu = Items.Add("SetConfigureOriginalStateSubmenu", 
			Type("FormGroup"), List.CommandBar);
		SetConfigureOriginalStateSubmenu.Type = FormGroupType.Popup;
		SetConfigureOriginalStateSubmenu.Representation = ButtonRepresentation.Picture; 
		SetConfigureOriginalStateSubmenu.Picture = PictureLib.SetSourceDocumentOriginalState;
		SetConfigureOriginalStateSubmenu.Title = NStr("en = 'Set original state';");
		SetConfigureOriginalStateSubmenu.ToolTip = NStr("en = 'Use these commands to set and change states of source document originals.';");
	EndIf;
	SetConfigureOriginalStateSubmenu = Items.Find("SetConfigureOriginalStateSubmenu");
	
	If Items.Find("SetOriginalStateGroup") = Undefined Then
		SetOriginalStateGroup = Items.Add("SetOriginalStateGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		SetOriginalStateGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	SetOriginalStateGroup = Items.Find("SetOriginalStateGroup");

	If Items.Find("ConfigureOriginalStatesGroup") = Undefined Then
		ConfigureOriginalStatesGroup = Items.Add("ConfigureOriginalStatesGroup", Type("FormGroup"),
			SetConfigureOriginalStateSubmenu);
		ConfigureOriginalStatesGroup.Type = FormGroupType.ButtonGroup;
	EndIf;
	ConfigureOriginalStatesGroup = Items.Find("ConfigureOriginalStatesGroup");

	If Items.Find("SetOriginalReceivedGroup") = Undefined Then
		SetOriginalReceivedGroup =  Items.Add("SetOriginalReceivedGroup", Type("FormGroup"), 
			List.CommandBar); 
		SetOriginalReceivedGroup.Type = FormGroupType.ButtonGroup;
		SetOriginalReceivedGroup.ToolTip = NStr("en = 'Set the final ""Original received"" state of the source document original.';");
	EndIf;
	SetOriginalReceivedGroup = Items.Find("SetOriginalReceivedGroup");
	
	For Each State In SetOriginalStateGroup.ChildItems Do
		FoundCommand = Form.Commands.Find(State.CommandName);
		FoundButton = Form.Items.Find(State.CommandName);

		If Not FoundCommand = Undefined Then
			Form.Commands.Delete(FoundCommand);
			Form.Items.Delete(FoundButton);
		EndIf;			
	EndDo;
	
	// 
	If SetOriginalStateGroup.ChildItems.Count() > 0 Then 
		State = SetOriginalStateGroup.ChildItems[0];
		FoundCommand = Form.Commands.Find(State.CommandName);
		FoundButton = Form.Items.Find(State.CommandName);
	EndIf;
	
	If Not FoundCommand = Undefined Then
		Form.Commands.Delete(FoundCommand);
		Form.Items.Delete(FoundButton);
	EndIf;
	
	For Each State In OriginalsStates Do
		CommandName = "Command" + StrReplace(State.Ref.UUID(),"-","_");
		ButtonName = State.Description;

		If Form.Commands.Find(CommandName) = Undefined Then
			Command = Form.Commands.Add(CommandName);
			Command.Action = "Attachable_SetOriginalState";

			// 
			SetStateButton = Form.Items.Add(CommandName, Type("FormButton"), SetOriginalStateGroup);
			SetStateButton.Title = ButtonName;
			SetStateButton.CommandName = CommandName;

			// 
			If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
			ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
				SetStateButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
			EndIf;
			
		EndIf;

	EndDo;

	// 
	If AccessRight("Insert",Metadata.Catalogs.SourceDocumentsOriginalsStates) 
		And AccessRight("Update",Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		CommandName = "StatesSetup";
		ButtonName = NStr("en = 'Configure…';");

		If Form.Commands.Find(CommandName) = Undefined Then
			FormCommand  = Form.Commands.Add(CommandName);
			FormCommand.Action = "Attachable_SetOriginalState";
			FormCommand.Title = ButtonName;
			
			ConfigureStatesButton = Form.Items.Add(CommandName, Type("FormButton"),ConfigureOriginalStatesGroup);
			ConfigureStatesButton.Title = ButtonName;
			ConfigureStatesButton.CommandName = CommandName;
			ConfigureStatesButton.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		EndIf; 
		
	EndIf;

	//  
	CommandName = "SetOriginalReceived";
	If Form.Commands.Find(CommandName) = Undefined Then
		FormCommand  = Form.Commands.Add(CommandName);
		FormCommand.Action = "Attachable_SetOriginalState";
		FormCommand.Title = NStr("en = 'Set ""Original received""';");
		FormCommand.ToolTip = NStr("en = 'Set ""Original received""';");
		
		NewButton = Form.Items.Add("Button" + CommandName , Type("FormButton"), SetOriginalReceivedGroup);
		NewButton.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		NewButton.CommandName = CommandName;
	EndIf;

EndProcedure

#EndRegion

#Region Internal

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.142";
	Handler.InitialFilling = True;
	Handler.Procedure = "SourceDocumentsOriginalsRecording.WriteSourceDocumentOriginalState";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.4.137"; 
	Handler.Id = New UUID("35320bc5-3ec6-4036-9253-ee5c507531e3");
	Handler.Procedure = "Catalogs.SourceDocumentsOriginalsStates.ProcessDataForMigrationToNewVersion";
	Handler.Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Repopulate internal attribute %1 to prevent misordering.';"),
		"AddlOrderingAttribute");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.SourceDocumentsOriginalsStates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToRead      = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToChange    = "Catalog.SourceDocumentsOriginalsStates";
	Handler.ObjectsToLock   = "Catalog.SourceDocumentsOriginalsStates";
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		Priority = Handler.ExecutionPriorities.Add();
		Priority.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
		Priority.Order = "Before";
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//  Objects - Array of MetadataObject
//
Procedure OnDefineObjectsWithInitialFilling(Objects) Export

	Objects.Add(Metadata.Catalogs.SourceDocumentsOriginalsStates);

EndProcedure

// See ImportDataFromFileOverridable.OnDefineCatalogsForDataImport.
Procedure OnDefineCatalogsForDataImport(CatalogsToImport) Export

	TableRow = CatalogsToImport.Find(Metadata.Catalogs.SourceDocumentsOriginalsStates.FullName(), 
		"FullName");
	If TableRow <> Undefined Then 
		CatalogsToImport.Delete(TableRow);
	EndIf;

EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds.
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording")Then
		Return;
	EndIf;

	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingOriginalState";
	Kind.SubmenuName  = "SetConfigureOriginalStateSubmenu";
	Kind.Title   = NStr("en = 'Set original state';");
	Kind.Picture    = PictureLib.SetSourceDocumentOriginalState;
	Kind.Representation = ButtonRepresentation.Picture;
	
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "SettingStateOriginalReceived";
	Kind.SubmenuName  = "SetStateOriginalReceived";
	Kind.Title   = NStr("en = 'Set ""Original received"" state';");
	Kind.Picture    = PictureLib.SourceDocumentOriginalStateOriginalReceived;	
	Kind.Representation = ButtonRepresentation.Picture;

EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	If Not RightsToChangeState() Then
		Return;
	EndIf;

	ObjectsWithSourceDocumentsOriginalsAccounting = New Array;
	SourceDocumentsOriginalsRecordingOverridable.OnDefineObjectsWithOriginalsAccountingCommands(ObjectsWithSourceDocumentsOriginalsAccounting);
	NeedOutputCommands = False;
	
	For Each Object In ObjectsWithSourceDocumentsOriginalsAccounting Do		
		If StrFind(FormSettings.FormName, Object) Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;
	
	ObjectsWithSourceDocumentsOriginalsAccounting.Clear();
	
	For Each Type In Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types() Do
		If Type = Type("CatalogRef.MetadataObjectIDs") Then
			Continue;
		EndIf;
		MetadataObject = Metadata.FindByType(Type);
		ObjectsWithSourceDocumentsOriginalsAccounting.Add(MetadataObject.FullName());
	EndDo;
	
	For Each Source In Sources.Rows Do
		If ObjectsWithSourceDocumentsOriginalsAccounting.Find(Source.FullName) <> Undefined Then
			NeedOutputCommands = True;
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;

	OriginalsStates = UsedStates();
	
	Order = 0;
	
	// 
	For Each State In OriginalsStates Do		
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Presentation = State.Description;
		Command.Order = Order + 1; 
		// 
		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalNotReceived;
		EndIf;		
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.Purpose = "ForList";
		Command.WriteMode = "Post";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";
		
		Order = Order + 1;
	EndDo;
	
	// 
	// 
	If AccessRight("Insert",Metadata.Catalogs.SourceDocumentsOriginalsStates) 
		And AccessRight("Update",Metadata.Catalogs.SourceDocumentsOriginalsStates) Then
		Command = Commands.Add();
		Command.Kind = "SettingOriginalState";
		Command.Id = "StatesSetup";
		Command.Presentation = NStr("en = 'Configure…';");
		Command.Importance = "SeeAlso";
		Command.Picture = PictureLib.ConfigureSourceDocumentOriginalStates;
		Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
		Command.Purpose = "ForList";
		Command.WriteMode = "NotWrite";
		Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
		Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	
	EndIf;
	
	Description = String(Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

	//  
	Command = Commands.Add();
	Command.Kind = "SettingStateOriginalReceived";
	Command.Presentation = StringFunctionsClientServer.InsertParametersIntoString(
		NStr("en = 'Set the ""[Description]"" state';"),
		New Structure("Description", Description));
	Command.ButtonRepresentation = ButtonRepresentation.Picture;
	Command.Picture = PictureLib.SourceDocumentOriginalStateOriginalReceived;
	Command.ParameterType = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type;
	Command.Purpose = "ForList";
	Command.WriteMode = "Post";
	Command.FunctionalOptions = "UseSourceDocumentsOriginalsRecording";
	Command.Handler = "SourceDocumentsOriginalsRecordingClient.Attachable_SetOriginalState";	

EndProcedure

Procedure BeforeItemMoved(ItemToMove, AdjacentElement, Direction, ErrorText, 
	StandardProcessing) Export
	
	If TypeOf(ItemToMove) <> Type("CatalogRef.SourceDocumentsOriginalsStates") Then
		Return;
	EndIf;
	
	ItemFormPrinted = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	ItemOriginalReceived = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.OriginalReceived");
	
	MovingDown = Direction = ItemOrderSetup.ItemMovementDirectionDown();
	MovingUp = Direction = ItemOrderSetup.ItemMovementDirectionUp();
	
	If AdjacentElement = ItemFormPrinted And MovingUp
		Or (ItemToMove = ItemFormPrinted And MovingDown) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The ""%1"" state is the initial state. No other states can be set before it.';"),
			ItemFormPrinted);
	EndIf;
	
	If AdjacentElement = ItemOriginalReceived And MovingDown 
		Or (ItemToMove = ItemOriginalReceived And MovingUp) Then
		StandardProcessing = False;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The ""%1"" state is the final state. No other states can be set after it.';"),
			ItemOriginalReceived);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function RightsToChangeState()
	
	Return AccessRight("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);

EndFunction

//	Parameters:
//  RecordData - Array of See SetTheNewStateOfTheOriginalArray.RecordData
//               - DocumentRef -   
//  StateName - String -  set state.
//
// Returns:
//  String - 
//            
//            
//
Function SetNewOriginalState(Val RecordData, Val StateName) Export

	If Not GetFunctionalOption("UseSourceDocumentsOriginalsRecording") Then
		Return "NotIsChanged";
	EndIf;
		
	VerifyAccessRights("Edit", Metadata.InformationRegisters.SourceDocumentsOriginalsStates);

	WritingObjects = New Array;
	DocsToCheck = New Array;
	If TypeOf(RecordData) = Type("Array") Then
		For Each ListLine In RecordData Do
			Ref = CommonClientServer.StructureProperty(ListLine, "Ref"); 
			If IsAccountingObject(Ref) Then
				DocsToCheck.Add(Ref);
				WritingObjects.Add(ListLine);
			EndIf;
		EndDo;
	Else
		DocsToCheck.Add(RecordData);
		WritingObjects.Add(RecordData);
	EndIf;

	UnpostedDocuments = CommonServerCall.CheckDocumentsPosting(DocsToCheck);
	If UnpostedDocuments.Count() > 0 Then
		Return "NotPosted";
	EndIf;
	
	SetPrivilegedMode(True);
	If TypeOf(RecordData) = Type("Array") Then
		 Result = SetTheNewStateOfTheOriginalArray(RecordData, StateName);
	Else
		 Result = SetNewStatusForOriginalDoc(RecordData, StateName);
	EndIf;
	Return ?(Result, "IsChanged", "NotIsChanged");
	
EndFunction

//	Parameters:
//  RecordData - Array of Structure - :
//                 * OverallState    - Boolean - 
//                 * Ref 		   - DocumentRef - 
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           
//                 * SourceDocument - String -  
//                                                
//                 * FromOutside 			   - Boolean -  
//                                                 
//  StateName - String -  set state.
//
// Returns:  
//  Boolean -  True if the state of the original document is not repeated and has been recorded.
//
Function SetTheNewStateOfTheOriginalArray(Val RecordData, Val StateName)

	IsChanged = False;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Record In RecordData Do
			LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
			LockItem.SetValue("Owner", Record.Ref); 
		EndDo;
		Block.Lock();

		For Each Record In RecordData Do
	
			If TrimAll(Record.SourceDocumentOriginalState) = TrimAll(StateName) Then
				Continue;
			EndIf;
			
			If Record.OverallState Then
				RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
				RecordSet.Filter.Owner.Set(Record.Ref);
				RecordSet.Filter.OverallState.Set(False);
				RecordSet.Read();
	
				If RecordSet.Count() = 0 Then
					IsChanged = True;
					InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
						StateName);
					Continue;
				EndIf;
					
				For Each PreviousRecord1 In RecordSet Do
					If TrimAll(PreviousRecord1.State) = StateName Then
						Continue;
					EndIf; 
					IsChanged = True;
					TabularSection = TableOfEmployees(Record.Ref);
					PreviousRecordEmployee = ?(TabularSection <> "", PreviousRecord1.Employee, Undefined);
					InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Record.Ref,
						PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, StateName,
						PreviousRecord1.ExternalForm, PreviousRecordEmployee);
				EndDo;
	
				IsChanged = True;
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
					StateName);
				Continue;
			EndIf;
			
			RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
			RecordSet.Filter.Owner.Set(Record.Ref);
			RecordSet.Read();
			If RecordSet.Count() = 0 Then
				IsChanged = True;
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref,
					StateName);
				Continue;
			EndIf;
			
			RecordSet.Filter.SourceDocument.Set(Record.SourceDocument);
			RecordSet.Read();
			TabularSection = TableOfEmployees(Record.Ref); 
			If TabularSection <> "" Then
				IsStatesChanged = WriteOriginalDocumentStateByEmployees(RecordSet, Record.Ref, 
					TabularSection, StateName);
			Else
				IsStatesChanged = WriteDocumentOriginalStateByPrintForms(RecordSet, Record.Ref, 
					StateName);
			EndIf;
			IsChanged = IsChanged Or IsStatesChanged; 
			If IsChanged Then
				InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Record.Ref, 
					StateName);
			EndIf;
	
		EndDo;
		
		CommitTransaction();
		
	Except	
		RollbackTransaction();
		Raise;
	EndTry;
		
	Return IsChanged;

EndFunction

// Parameters:
//   Document - DocumentRef - 
//   StateName - String -  set state.
//
// Returns:
//   Boolean -  True if the state of the original document is not repeated and has been recorded.
//
Function SetNewStatusForOriginalDoc(Val Document, Val StateName)
	
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
	LockItem.SetValue("Owner", Document); 

	BeginTransaction();
	Try
		 
		Block.Lock();
		RecordSet = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
		RecordSet.Filter.Owner.Set(Document);
		RecordSet.Filter.OverallState.Set(True);  
		RecordSet.Read();
	
		If RecordSet.Count() And TrimAll(RecordSet[0].State) = StateName Then
			CommitTransaction();
			Return False;
		EndIf;
				
		RecordSet.Filter.OverallState.Set(False);
		RecordSet.Read();
	
		If RecordSet.Count() > 0 Then
			TabularSection = TableOfEmployees(Document); 
			If TabularSection <> "" Then
				WriteOriginalDocumentStateByEmployees(RecordSet, Document, TabularSection, StateName);
			Else
				WriteDocumentOriginalStateByPrintForms(RecordSet, Document, StateName);
			EndIf;
		EndIf; 
		
		InformationRegisters.SourceDocumentsOriginalsStates.WriteCommonDocumentOriginalState(Document, 
			StateName);
		
		CommitTransaction();
		
	Except
		RollbackTransaction(); 
		Raise;
	EndTry;
	
	Return True;

EndFunction

Function WriteDocumentOriginalStateByPrintForms(RecordSet, Document, StateName)
	
	IsChanged = False;
	For Each PreviousRecord1 In RecordSet Do
		If TrimAll(PreviousRecord1.State) = StateName Then
			Continue;
		EndIf;
		IsChanged = True;
		InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Document,
			PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, 
			StateName, PreviousRecord1.ExternalForm);
	EndDo;
	Return IsChanged;
	
EndFunction

Function WriteOriginalDocumentStateByEmployees(RecordSet, Document, TabularSection, StateName)
	
	IsChanged = False;
	For Each Employee In Document[TabularSection] Do
		RecordSet.Filter.Employee.Set(Employee.Employee);
		RecordSet.Read(); 
		If RecordSet.Count() = 0 Then
			Continue;
		EndIf;

		For Each PreviousRecord1 In RecordSet Do
			If TrimAll(PreviousRecord1.State) = StateName Then
				Continue;
			EndIf;
			IsChanged = True;
			InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalStateByPrintForms(Document,
				PreviousRecord1.SourceDocument, PreviousRecord1.SourceDocumentPresentation, 
				StateName, PreviousRecord1.ExternalForm, Employee.Employee);
		EndDo; 
	EndDo;
	Return IsChanged;
	
EndFunction

// Fills in the drop-down list for selecting States on the form.
//
//	Parameters:
//  Form - ClientApplicationForm -  the list form of the document.
//
Procedure FillOriginalStatesChoiceList(Form, OriginalsStates)

	OriginalStatesChoiceList = Form.OriginalStatesChoiceList;
	OriginalStatesChoiceList.Clear(); 
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description, State.Description,,
				PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description, State.Description);
		EndIf;

	EndDo;

EndProcedure

// Returns an array of States available to the user.
//
//	Returns:
//  ValueTable:
//    * Description - String -  name of the original state;
//    * Ref		 - CatalogRef.SourceDocumentsOriginalsStates
//
Function UsedStates()Export 

	SetPrivilegedMode(True);

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	SourceDocumentsOriginalsStates.Description AS Description,
	               |	SourceDocumentsOriginalsStates.Ref AS Ref
	               |FROM
	               |	Catalog.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	NOT SourceDocumentsOriginalsStates.Ref = VALUE(Catalog.SourceDocumentsOriginalsStates.OriginalsNotAll)
	               |	AND NOT SourceDocumentsOriginalsStates.DeletionMark
	               |
	               |ORDER BY
	               |	SourceDocumentsOriginalsStates.AddlOrderingAttribute";

	Selection = Query.Execute();
	
	SetPrivilegedMode(False);

	Return Selection.Unload();

EndFunction

// Returns the key for recording the General state register of the original document by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - 
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates
//
Function OverallStateRecordKey(DocumentRef) Export

	Query = New Query;
	Query.Text ="SELECT ALLOWED
	|	SourceDocumentsOriginalsStates.Owner AS Owner,
	|	SourceDocumentsOriginalsStates.SourceDocument AS SourceDocument,
	|	SourceDocumentsOriginalsStates.OverallState AS OverallState,
	|	SourceDocumentsOriginalsStates.ExternalForm AS ExternalForm,
	|	SourceDocumentsOriginalsStates.Employee AS Employee
	|FROM
	|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	|WHERE
	|	SourceDocumentsOriginalsStates.Owner = &Ref
	|	AND SourceDocumentsOriginalsStates.OverallState" ;
	
	Query.SetParameter("Ref",DocumentRef);

	Selection = Query.Execute().Unload();

	For Each Var_Key In Selection Do
		TransmittedParameters = New Structure("Owner, SourceDocument, OverallState, ExternalForm, Employee");
		FillPropertyValues(TransmittedParameters,Var_Key);

		ParametersArray1 = New Array;
		ParametersArray1.Add(TransmittedParameters);

		RegisterRecordKey = New("InformationRegisterRecordKey.SourceDocumentsOriginalsStates", ParametersArray1);
	EndDo;

	Return RegisterRecordKey;

EndFunction

// Checks and returns whether the referenced document is an original document.
//
// Parameters:
//  DocumentRef - DocumentRef -  link to the document that you want to check.
//
// Returns:
//   Boolean
//
Function IsAccountingObject(DocumentRef) Export

	If DocumentRef = Undefined Then
		Return False;
	EndIf;
	
	Return Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.ContainsType(TypeOf(DocumentRef));

EndFunction

// 
//
//	Parameters:
//  DocumentRef - DocumentRef -  link to the document that you want to check.
//
//	Returns:
//  String - 
//           
//
Function TableOfEmployees(DocumentRef) Export
	
	ListOfObjects = New Map();
	Result = "";
	SourceDocumentsOriginalsRecordingOverridable.WhenDeterminingMultiEmployeeDocuments(ListOfObjects);
	DocumentType = Common.TableNameByRef(DocumentRef);
	If ListOfObjects[DocumentType] <> Undefined Then
		Result = ListOfObjects[DocumentType];
	EndIf;
	
	Return Result;
	
EndFunction

// Returns an array with a description of the types of objects connected to the subsystem.
//
//	Returns:
//  Array of Type
//
Function InformationAboutConnectedObjects() Export

	AvailableTypes = Metadata.DefinedTypes.ObjectWithSourceDocumentsOriginalsAccounting.Type.Types();
	Return AvailableTypes;

EndFunction

// Returns a link to the document based on the barcode of the table document.
//
// Parameters:
//  Barcode - String
//  Managers - Array of CatalogRef
//            - DocumentRef
//            - TaskRef
//
// Returns:
//  Array of DocumentRef
//
Function RefBySpreadsheetDocumentBarcode(Barcode, Managers = Undefined) 

	If Not StringFunctionsClientServer.OnlyNumbersInString(Barcode, False, False)
		Or TrimAll(Barcode) = "" Then
		Return New Array;
	EndIf;

	BarcodeInHexadecimal = ConvertDecimalToHexadecimalNotation(Number(Barcode));
	While StrLen(BarcodeInHexadecimal) < 32 Do
		BarcodeInHexadecimal = "0" + BarcodeInHexadecimal;
	EndDo;

	Id = Mid(BarcodeInHexadecimal, 1,  8)
		+ "-" + Mid(BarcodeInHexadecimal, 9,  4)
		+ "-" + Mid(BarcodeInHexadecimal, 13, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 17, 4)
		+ "-" + Mid(BarcodeInHexadecimal, 21, 12);

	If StrLen(Id) <> 36 Then
		Return New Array;
	EndIf;

	If Managers = Undefined Then
		ObjectsManagers = New Array();
		For Each MetadataItem In Metadata.Documents Do
			ObjectsManagers.Add(Documents[MetadataItem.Name]);
		EndDo;
	Else
		ObjectsManagers = New Array();
		For Each EmptyRef In Managers Do
			RefType = TypeOf(EmptyRef);
			
			If Documents.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Documents[EmptyRef.Metadata().Name]);
				
			ElsIf Catalogs.AllRefsType().ContainsType(RefType) Then
				ObjectsManagers.Add(Catalogs[EmptyRef.Metadata().Name]);
				
			ElsIf Tasks.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(Tasks[EmptyRef.Metadata().Name]);
				
			ElsIf BusinessProcesses.AllRefsType(RefType).ContainsType(RefType) Then	
				ObjectsManagers.Add(BusinessProcesses[EmptyRef.Metadata().Name]);
				
			ElsIf ChartsOfCharacteristicTypes.AllRefsType(RefType).ContainsType(RefType) Then
				ObjectsManagers.Add(ChartsOfCharacteristicTypes[EmptyRef.Metadata().Name]);
				
			Else
				ExceptionText = NStr("en = 'Barcode recognition error: type ""%Type%"" is not supported.';");
				ExceptionText = StrReplace(ExceptionText, "%Type%", RefType);				
				Raise ExceptionText;
			EndIf;

		EndDo;
	EndIf;

	Query = New Query;

	ReferencesArrray = New Array;
	FirstQuery = True;
	For Each Manager In ObjectsManagers Do

		Try
			Ref = Manager.GetRef(New UUID(Id));
		Except
			Continue;
		EndTry;
		
		RefMetadata = Ref.Metadata();
		If Not AccessRight("Read", RefMetadata) Then
			Continue;
		EndIf;
		
		ReferencesArrray.Add(Ref);
		
		If FirstQuery Then
			Query.Text = Query.Text +
			"SELECT ALLOWED Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		Else	
			Query.Text = Query.Text + 
			"UNION ALL
			|
			|SELECT Table.Ref AS Ref
			|FROM &TheMetadataLinksToTheFullName AS Table
			|WHERE Ref IN (&ReferencesArrray)
			|";
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&TheMetadataLinksToTheFullName", RefMetadata.FullName());
		FirstQuery = False;

	EndDo;

	If Not FirstQuery Then
		Query.Parameters.Insert("ReferencesArrray", ReferencesArrray);
		Return Query.Execute().Unload().UnloadColumn("Ref");
	Else
		Return New Array;
	EndIf;

EndFunction

// The procedure processes actions for recording originals after scanning the document's barcode.
//
// Parameters:
//   Barcode - String -  scanned barcode of the document.
//
Procedure ProcessBarcode(Barcode) Export

	RefByBarcode = RefBySpreadsheetDocumentBarcode(Barcode);
	SetNewOriginalState(RefByBarcode[0], 
		Catalogs.SourceDocumentsOriginalsStates.OriginalReceived);

EndProcedure

// Checks whether the States of the document's printed forms have the same States after writing them to the register.
//
// Parameters:
//  DocumentRef - DocumentRef -  link to the document that you want to check the status of printed forms.
//  StateName - String -  name of the state that was set.
//
// Returns:
//   Boolean - 
//
Function PrintFormsStateSame(DocumentRef,StateName) Export

	FormsStateSame = False;

	Query = New Query;
	Query.Text = "SELECT ALLOWED
	               |	SourceDocumentsOriginalsStates.State.Description AS OriginalState
	               |FROM
	               |	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
	               |WHERE
	               |	SourceDocumentsOriginalsStates.Owner = &Ref
	               |	AND NOT SourceDocumentsOriginalsStates.OverallState";
	Query.SetParameter("Ref", DocumentRef);

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		FormsStateSame = (Selection.OriginalState = TrimAll(StateName));
		If Not FormsStateSame Then
			Break;
		EndIf;

	EndDo;

	Return FormsStateSame;

EndFunction

// 
//
//	Parameters:
//  DocumentRef - DocumentRef -  a link to the document for which you want to get information about the general state. 
//
//  Returns:
//    Structure:
//    * Ref - DocumentRef -  link to the document.
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -  the current
//        state of the original document.
//
Function OriginalStateInfoByRef(DocumentRef) Export

	Query = New Query;
	Query.Text = "SELECT ALLOWED
		|	SourceDocumentsOriginalsStates.State AS State,
		|	SourceDocumentsOriginalsStates.OverallState AS OverallState
		|FROM
		|	InformationRegister.SourceDocumentsOriginalsStates AS SourceDocumentsOriginalsStates
		|WHERE
		|	SourceDocumentsOriginalsStates.Owner = &Ref
		|	AND SourceDocumentsOriginalsStates.OverallState = TRUE";
	
	Query.SetParameter("Ref",DocumentRef);
	
	StateInfo3 = New Structure;

	If Not Query.Execute().IsEmpty() Then
		Selection = Query.Execute().Select();
		Selection.Next();
		
		StateInfo3.Insert("Ref",DocumentRef);
		StateInfo3.Insert("SourceDocumentOriginalState",Selection.State);	
	EndIf;

	Return StateInfo3;

EndFunction

// Update handler procedure for filling in the initial elements of the reference list "States of originals of primary documents".
Procedure WriteSourceDocumentOriginalState() Export

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.FormPrinted.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("en = 'Form printed';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("en = 'State that means that the print form was printed only.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 1;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("en = 'Not all originals';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("en = 'The aggregated state of a document whose print forms have different states.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99998;
	InfobaseUpdate.WriteObject(OriginalState);

	OriginalState = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived.GetObject();
	LockDataForEdit(OriginalState.Ref);
	OriginalState.Description = NStr("en = 'Original received';", Common.DefaultLanguageCode());
	OriginalState.LongDesc = NStr("en = 'State that means that the signed print form original is available.';", 
		Common.DefaultLanguageCode());
	OriginalState.AddlOrderingAttribute = 99999;
	InfobaseUpdate.WriteObject(OriginalState);

EndProcedure

Function ConvertDecimalToHexadecimalNotation(Val Decimal)

	Result = "";

	While Decimal > 0 Do
		Remainder = Decimal % 16;
		Decimal = (Decimal - Remainder) / 16;
		Result = Mid("0123456789abcdef", Remainder + 1, 1) + Result;
	EndDo;

	Return Result;
	
EndFunction

// 
//
// Parameters:
//  PrintObjects - ValueList - 
//  PrintList - ValueList - 
//
Procedure WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList) Export
	
	AccountingTableForOriginals = AccountingTableForOriginals();
	If AccountingTableForOriginals.Count() = 0 Then
		Return;
	EndIf;
	
	TemplatesNames = New Array;
	For Each Template In PrintList Do
		TemplatesNames.Add(Template.Value);
	EndDo;
	
	MetadataCompliance = New Map();
	For Each PrintObject In PrintObjects Do
		MetadataCompliance.Insert(PrintObject.Value.Metadata());
	EndDo;
	MetadataObjects = Common.UnloadColumn(MetadataCompliance, "Key");
	
	DeleteLayouts = New Array;
	For Each MetadataObject In MetadataObjects Do
		FoundRows = AccountingTableForOriginals.FindRows(New Structure("MetadataObject", MetadataObject));
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		LeaveLayouts = Common.UnloadColumn(FoundRows, "Id");
		For Each Template In TemplatesNames Do
			If LeaveLayouts.Find(Template) = Undefined Then
				DeleteLayouts.Add(Template);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Template In DeleteLayouts Do
		FoundTemplate = PrintList.FindByValue(Template);
		If FoundTemplate <> Undefined Then
			PrintList.Delete(FoundTemplate);
		EndIf;
	EndDo;

EndProcedure

Function AccountingTableForOriginals()
	
	Table = New ValueTable;
	Table.Columns.Add("MetadataObject", New TypeDescription("MetadataObject"));
	Table.Columns.Add("Id", New TypeDescription("String"));
	
	SourceDocumentsOriginalsRecordingOverridable.FillInTheOriginalAccountingTable(Table);
	Return Table;
	
EndFunction

#EndRegion
