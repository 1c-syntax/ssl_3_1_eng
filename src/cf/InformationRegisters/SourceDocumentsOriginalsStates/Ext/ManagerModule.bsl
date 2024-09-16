///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Records the States of the original printed forms in the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList -  list of documents.
//  PrintForms - ValueList -  the name of the layout and presentation of printed forms.
//  Written1 - Boolean -  indicates that the status of the document is recorded in the register.
//
Procedure WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintForms, Written1 = False) Export
	
	State = PredefinedValue("Catalog.SourceDocumentsOriginalsStates.FormPrinted");
	If Not ValueIsFilled(PrintObjects) Then 
		Return;
	EndIf;
	
	Block = New DataLock();

	BeginTransaction();
	Try
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				LockItem = Block.Add("InformationRegister.SourceDocumentsOriginalsStates");
				LockItem.SetValue("Owner", Document.Value); 
			EndIf;
		EndDo;
		Block.Lock();
		
		For Each Document In PrintObjects Do
			If SourceDocumentsOriginalsRecording.IsAccountingObject(Document.Value) Then 
				TS = SourceDocumentsOriginalsRecording.TableOfEmployees(Document.Value);
				If TS <> "" Then
					For Each Employee In Document.Value[TS] Do
						For Each Form In PrintForms Do 
							WriteDocumentOriginalStateByPrintForms(Document.Value, 
								Form.Value, Form.Presentation, State, False, Employee.Employee);
						EndDo;
					EndDo;
				Else
					For Each Form In PrintForms Do
						WriteDocumentOriginalStateByPrintForms(Document.Value, Form.Value,
							Form.Presentation, State, False);
					EndDo;
				EndIf;
				WriteCommonDocumentOriginalState(Document.Value, State);
				Written1 = True;
			EndIf;
		EndDo;
		
		CommitTransaction();
		
	Except	
		
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Records the status of the original printed form in the register after printing the form.
//
//	Parameters:
//  Document - DocumentRef -  link to the document.
//  PrintForm - String -  name of the print form layout.
//  Presentation - String -  name of the printed form.
//  State - String -  name of the state of the original printed form
//            - CatalogRef - 
//  FromOutside - Boolean -  indicates whether the form belongs to the 1C system.
//  Employee - CatalogRef - 
//
Procedure WriteDocumentOriginalStateByPrintForms(Document, PrintForm, Presentation, State, 
	FromOutside, Employee = Undefined) Export
	
	SetPrivilegedMode(True);
	
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = PrintForm;
	If ValueIsFilled(Employee) Then
		LastFirstName = Employee.Description;
		Values = New Structure("Presentation, LASTFIRSTNAME", Presentation, LastFirstName);
		EmployeeView = StrFind(Presentation, LastFirstName);
		If EmployeeView = 0 Then
			OriginalStateRecord.SourceDocumentPresentation = StringFunctionsClientServer.InsertParametersIntoString(
				NStr("en = '[Presentation] [LastFirstName]';"), Values);
		Else
			OriginalStateRecord.SourceDocumentPresentation = Presentation;
		EndIf;
	Else
		OriginalStateRecord.SourceDocumentPresentation = Presentation;
	EndIf;
	OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
	OriginalStateRecord.OverallState = False;
	OriginalStateRecord.ExternalForm = FromOutside;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Employee = Employee;
	OriginalStateRecord.Write();

EndProcedure

// Records the General state of the original document in the register.
//
//	Parameters:
//  Document - DocumentRef -  link to the document.
//  State - String -  name of the original state.
//
Procedure WriteCommonDocumentOriginalState(Document, State) Export

	SetPrivilegedMode(True);
		
	OriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordManager();
	OriginalStateRecord.Owner = Document;
	OriginalStateRecord.SourceDocument = "";
		
	CheckOriginalStateRecord = InformationRegisters.SourceDocumentsOriginalsStates.CreateRecordSet();
	CheckOriginalStateRecord.Filter.Owner.Set(Document.Ref);
	CheckOriginalStateRecord.Filter.OverallState.Set(False);
	CheckOriginalStateRecord.Read();
	If CheckOriginalStateRecord.Count() Then
		For Each Record In CheckOriginalStateRecord Do
			If Record.ChangeAuthor <> Users.CurrentUser() Then
				OriginalStateRecord.ChangeAuthor = Undefined;
			Else
				OriginalStateRecord.ChangeAuthor = Users.CurrentUser();
			EndIf;
		EndDo;
		If SourceDocumentsOriginalsRecording.PrintFormsStateSame(Document, State) Then
			OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
		Else
				OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.OriginalsNotAll;
		EndIf;
	Else
		OriginalStateRecord.State = Catalogs.SourceDocumentsOriginalsStates.FindByDescription(State);
	EndIf;
		
	OriginalStateRecord.OverallState = True;
	OriginalStateRecord.LastChangeDate = CurrentSessionDate();
	OriginalStateRecord.Write();

EndProcedure

#EndRegion

#EndIf

