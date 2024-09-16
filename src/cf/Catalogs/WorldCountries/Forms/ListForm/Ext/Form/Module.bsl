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
	
	// 
	CanAddToCatalog = ContactsManagerInternal.HasRightToAdd();
	
	If Metadata.CommonModules.Find("AddressManager") = Undefined Then
		ClassifierDataAvailable = False;
	ElsIf Parameters.AllowClassifierData = Undefined Then
		ClassifierDataAvailable = True;
	Else
		BooleanType = New TypeDescription("Boolean");
		ClassifierDataAvailable = BooleanType.AdjustValue(Parameters.AllowClassifierData);
	EndIf;
	
	OnlyClassifierData = Parameters.OnlyClassifierData;
	ChoiceMode = Parameters.ChoiceMode;
	
	// 
	Items.List.ChoiceMode = ChoiceMode;
	CommonClientServer.SetFormItemProperty(Items, "ListChoose", "DefaultButton", ChoiceMode);
	Items.Create.Visible  = CanAddToCatalog;
	
	If Not ClassifierDataAvailable Then
		// 
		Items.ListClassifier.Visible = False;
		// 
		Items.ListSelectFromClassifier.Visible = False;
		Items.ListClassifier.Visible           = False;
		
		If CanAddToCatalog Then
			Items.ListCreate.LocationInCommandBar = ButtonLocationInCommandBar.InCommandBar;
			Items.ListCreate.DefaultButton         = Not ChoiceMode;
			Items.ListCreate.Title =               "";
		EndIf;
		
		Return;
	EndIf;
	
	If ChoiceMode Then
		If OnlyClassifierData Then
			If CanAddToCatalog Then
				// 
				OpenClassifierForm = True
				
			Else
				// 
				SetCatalogAndClassifierIntersectionFilter();
				// 
				Items.ListSelectFromClassifier.Visible = False;
				Items.ListClassifier.Visible           = False;
			EndIf;
			
		Else
			If CanAddToCatalog Then 
				// 
			Else
				// 
				Items.ListSelectFromClassifier.Visible = False;
				Items.ListClassifier.Visible           = False;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If OpenClassifierForm Then
		// 
		OpeningParameters = New Structure;
		OpeningParameters.Insert("ChoiceMode",        True);
		OpeningParameters.Insert("CloseOnChoice", CloseOnChoice);
		OpeningParameters.Insert("CurrentRow",      Items.List.CurrentRow);
		OpeningParameters.Insert("WindowOpeningMode",  WindowOpeningMode);
		OpeningParameters.Insert("CurrentRow",      Items.List.CurrentRow);
		
		ShowClassifier(OpeningParameters, FormOwner);
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "Catalog.WorldCountries.Update" Then
		RefreshCountriesListDisplay();
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If ChoiceMode Then
		NotifyChoice(ValueSelected); // 
	EndIf;
	
EndProcedure

&AtClient
Procedure ListNewWriteProcessing(NewObject, Source, StandardProcessing)
	RefreshCountriesListDisplay();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenClassifier(Command)
	
	// 
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	
	ShowClassifier(OpeningParameters, Items.List);
	
EndProcedure

&AtClient
Procedure SelectFromClassifier(Command)
	
	// 
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ChoiceMode", True);
	OpeningParameters.Insert("CloseOnChoice", CloseOnChoice);
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	OpeningParameters.Insert("WindowOpeningMode", WindowOpeningMode);
	OpeningParameters.Insert("CurrentRow", Items.List.CurrentRow);
	OpeningParameters.Insert("InsertMode", True);
	
	ShowClassifier(OpeningParameters, Items.List, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ShowClassifier(OpeningParameters, Var_FormOwner, Var_WindowOpeningMode = Undefined);
	
	If Not ClassifierDataAvailable Then
		Return;
	EndIf;

	ModuleAddressManagerClient = CommonClient.CommonModule("AddressManagerClient");
	ModuleAddressManagerClient.ShowClassifier( OpeningParameters, Var_FormOwner, Var_WindowOpeningMode);
	
EndProcedure

&AtClient
Procedure RefreshCountriesListDisplay()
	
	If RefFilterItemID <> Undefined Then
		// 
		SetCatalogAndClassifierIntersectionFilter();
	EndIf;
	
	Items.List.Refresh();
EndProcedure

&AtServer
Procedure SetCatalogAndClassifierIntersectionFilter()
	Filterlist0 = List.SettingsComposer.FixedSettings.Filter;
	
	If RefFilterItemID=Undefined Then
		FilterElement = Filterlist0.Items.Add(Type("DataCompositionFilterItem"));
		
		FilterElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		FilterElement.LeftValue    = New DataCompositionField("Ref");
		FilterElement.ComparisonType     = DataCompositionComparisonType.InList;
		FilterElement.Use    = True;
		
		RefFilterItemID = Filterlist0.GetIDByObject(FilterElement);
	Else
		FilterElement = Filterlist0.GetObjectByID(RefFilterItemID);
	EndIf;
	
	Query = New Query("
		|SELECT
		|	Code, Description
		|INTO
		|	Classifier
		|FROM
		|	&Classifier AS Classifier
		|INDEX BY
		|	Code, Description
		|;////////////////////////////////////////////////////////////
		|SELECT 
		|	Ref
		|FROM
		|	Catalog.WorldCountries AS WorldCountries
		|INNER JOIN
		|	Classifier AS Classifier
		|ON
		|	WorldCountries.Code = Classifier.Code
		|	AND WorldCountries.Description = Classifier.Description
		|");
	
	ModuleAddressManager = Common.CommonModule("AddressManager");
	Query.SetParameter("Classifier", ModuleAddressManager.TableOfClassifier());
	FilterElement.RightValue = Query.Execute().Unload().UnloadColumn("Ref");
	
EndProcedure

#EndRegion
