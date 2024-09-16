///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	
	If AttachableCommandsKinds.Find("Administration", "Name") = Undefined Then
	
		Kind = AttachableCommandsKinds.Add();
		Kind.Name         = "Administration";
		Kind.SubmenuName  = "Service";
		Kind.Title   = NStr("en = 'Service';");
		Kind.Order     = 80;
		Kind.Picture    = PictureLib.ServiceSubmenu;
		Kind.Representation = ButtonRepresentation.PictureAndText;	
	
	EndIf;
	
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export

	AttachedObjects = New Array;
	BatchEditObjectsOverridable.OnDefineObjectsWithBatchObjectsModificationCommand(AttachedObjects);
	For Each AttachedObject In AttachedObjects Do
					
		If AccessRight("Update", AttachedObject) 
			And Sources.Rows.Find(AttachedObject, "Metadata") <> Undefined Then
				
			Command = Commands.Add();
			Command.Kind = "Administration";
			Command.Importance = "SeeAlso";
			Command.Presentation = NStr("en = 'Edit selected…';");
			Command.WriteMode = "NotWrite";
			Command.Purpose = "ForList";
			Command.MultipleChoice = True;
			Command.Handler = "BatchEditObjectsClient.HandlerCommands";
			Command.OnlyInAllActions = True;
			Command.Order = 20;
			
			StringParts1 = StrSplit(AttachedObject.FullName(), ".", True);
			StringParts1[0] = StringParts1[0] + "Ref";
			Command.ParameterType = New TypeDescription(StrConcat(StringParts1, "."));
		EndIf;	
	
	EndDo;	

EndProcedure

#EndRegion

#EndRegion