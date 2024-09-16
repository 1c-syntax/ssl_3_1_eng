///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Sends a message to users from another user. 
// If there was no discussion between users, a
// displayed discussion will be created.
//
// Throws an exception if the message could not be sent.
//
// Parameters: 
//   Author - CatalogRef.Users
//         - CollaborationSystemUser
//   Recipients - Array of CatalogRef.Users
//              - Array of CollaborationSystemUser
//   Message - See MessageDetails
//   ConversationContext - AnyRef -  the message will be sent to the context discussion.
//                      - CollaborationSystemConversationID - 
//                      - Undefined - 
//
// Example:
// Message = Discussions.Opisaniyami("Hello world!");
// Receiver = ObservableCollection.Nacinajuscego(Administrator);
// Discussions.Send A Message(Users.Current User (), Recipient, Message);
//
Procedure SendMessage(Val Author, Val Recipients, Message, ConversationContext = Undefined) Export
	
	If TypeOf(Author) <> Type("CollaborationSystemUser") Then
		Author = CollaborationSystemUser(Author);
	EndIf;
	
	If Author = Undefined Then
		Raise NStr("en = 'Message author is not specified';");
	EndIf;
	
	If Recipients.Count() = 0 Then
		Raise NStr("en = 'Message recipients are not specified';");
	EndIf;
	
	If TypeOf(Recipients[0]) = Type("CatalogRef.Users") Then
		AddresseesByRef = CollaborationSystemUsers(Recipients);
		Recipients = New Array; // 
		For Each KeyAndValue In AddresseesByRef Do
			Recipient = KeyAndValue.Value;
			If TypeOf(Recipient) = Type("CollaborationSystemUser") Then
				Recipients.Add(Recipient);
			EndIf;
		EndDo;
	EndIf;
	
	If ConversationContext <> Undefined 
			And TypeOf(ConversationContext) <> Type("CollaborationSystemConversationID") Then
			
		If Not ValueIsFilled(ConversationContext) Then
			Raise NStr("en = 'Empty conversation context is passed.';");
		EndIf;
		
		Context = New CollaborationSystemConversationContext(GetURL(ConversationContext));
		Filter = New CollaborationSystemConversationsFilter;
		Filter.ConversationContext = Context;
		Filter.CurrentUserIsMember = False;
		Filter.Displayed = True;
		Filter.ContextConversation = True;
		Conversation = CollaborationSystem.GetConversations(Filter);
		If Conversation.Count() = 0 Then
			Conversation = CollaborationSystem.CreateConversation();
			Conversation.ConversationContext = Context;
			Conversation.Displayed = True;
			Conversation.Title = String(ConversationContext);
			Conversation.Write();
		Else 
			Conversation = Conversation[0];
		EndIf;

		ConversationID = Conversation.ID;
		
	ElsIf ConversationContext = Undefined Then
		
		If Recipients.Count() = 1 Then
			Member = Recipients[0];
			Conversation = NotAGroupDiscussionBetweenUsers(Author.ID, Member.ID);
		Else	
			Conversation = CollaborationSystem.CreateConversation();
			Conversation.Title = Message.Text;
			Conversation.Displayed = True;
			Conversation.Group = True;
			Conversation.Members.Add(Author.ID);
 			AddRecipients(Conversation.Members, Recipients);
			Conversation.Write();
		EndIf;
		
		ConversationID = Conversation.ID;
		
	Else
		ConversationID = ConversationContext;
	EndIf;
	
	SetPrivilegedMode(True);
	CollaborationSystemMessage = MessageFromTheDescription(Author, ConversationID, Recipients, Message);
	CollaborationSystemMessage.Write();
	
EndProcedure

// Sends a message to all participants in a non-contextual discussion.
// If the discussion is contextual, the message will be sent without recipients.
//
// Throws an exception if the message could not be sent.
//
// Parameters: 
//   Author - CatalogRef.Users
//         - CollaborationSystemUser
//   Message - See MessageDetails.
//   ConversationContext - AnyRef -  the message will be sent to the context discussion.
//                      - CollaborationSystemConversationID - 
//
// Example:
// Message = Discussions.Description of the message ("Hello, world!");
// Discussions.Send A Notification(Users.Current User (), Message, Customer Order);
//
Procedure SendNotification(Val Author, Message, ConversationContext) Export

	If TypeOf(Author) <> Type("CollaborationSystemUser") Then
		Author = CollaborationSystemUser(Author);
	EndIf;
	
	If Author = Undefined Then
		Raise NStr("en = 'Message author is not specified';");
	EndIf;
	
	Recipients = New Array;
	
	If ConversationContext <> Undefined 
			And TypeOf(ConversationContext) <> Type("CollaborationSystemConversationID") Then
			
		If Not ValueIsFilled(ConversationContext) Then
			Raise NStr("en = 'Empty conversation context is passed.';");
		EndIf;	
		
		Context = New CollaborationSystemConversationContext(GetURL(ConversationContext));
		Filter = New CollaborationSystemConversationsFilter;
		Filter.ContextConversation = True;
		Filter.ConversationContext = Context;
		Conversation = CollaborationSystem.GetConversations(Filter);
		If Conversation.Count() = 0 Then
			Conversation = CollaborationSystem.CreateConversation();
			Conversation.ConversationContext = Context;
			Conversation.Group = True;
			Conversation.Displayed = True;
			Conversation.Title = String(ConversationContext);
			Conversation.Write();
		Else 
			Conversation = Conversation[0];
		EndIf;
		
		ConversationID = Conversation.ID;
		Recipients = Conversation.Members;
		
	ElsIf ConversationContext = Undefined Then
		
		Raise NStr("en = 'Conversation ID or context is not specified.';");
		
	Else
		
		ConversationID = ConversationContext;
		Conversation = CollaborationSystem.GetConversation(ConversationID);
		Recipients = Conversation.Members;
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	CollaborationSystemMessage = MessageFromTheDescription(
					Author,
					ConversationID,
					Recipients,
					Message);
	CollaborationSystemMessage.Write();

EndProcedure

// 
// 
// 
//
// Returns:
//   Boolean
//
Function CollaborationSystemConnected() Export
	
	// 
	Registered1 = CollaborationSystem.InfoBaseRegistered();
	
	Return Registered1 And Not ConversationsInternal.Locked2();
	
EndFunction

// 
// 
// 
// 
// Returns:
//   Boolean
//
Function ConversationsAvailable() Export
	Return ConversationsInternal.Connected2();
EndFunction

// Forms a correspondence between the user IDs of the interaction system
// and the elements of the users directory.
//
// Parameters:
//   CollaborationSystemUsers - Array of CollaborationSystemUserID
//                                     - CollaborationSystemUserIDCollection 
// 
// Returns:
//   Map of KeyAndValue:
//   * Key - CollaborationSystemUserID
//   * Value - See InfoBaseUser
//
Function InfoBaseUsers(CollaborationSystemUsers)Export
	InputParametersTypes = New Array;
	InputParametersTypes.Add(Type("CollaborationSystemUserIDCollection"));
	InputParametersTypes.Add(Type("Array"));
 	CommonClientServer.CheckParameter("InfoBaseUsers",
 		"CollaborationSystemUsers",
 		CollaborationSystemUsers,
 		InputParametersTypes);

	Result = New Map;
	Errors = New Array;
	For Each Id In CollaborationSystemUsers Do
		Try
			Result.Insert(Id, InfoBaseUser(Id));
		Except
			Errors.Add(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Result.Insert(Id, Undefined);
		EndTry;
	EndDo;
	
	If Errors.Count() > 0 Then
	
		WriteLogEvent(ConversationsInternal.EventLogEvent(
			NStr("en = 'Infobase users';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			StrConcat(Errors, Chars.LF + Chars.LF));
	
	EndIf;
	
	Return Result;
EndFunction

// Searches for an item in the users directory by the user ID of the Interaction System.
//
// Throws an exception if the user was not found.
//
// Parameters:
//   CollaborationSystemUser - CollaborationSystemUserID
//
// Returns:
//   CatalogRef.Users
//
Function InfoBaseUser(CollaborationSystemUser) Export
	Result = Undefined;
	
	Var_22_CollaborationSystemUser = CollaborationSystem.GetUser(CollaborationSystemUser);
	Result = Catalogs.Users.FindByAttribute("IBUserID", Var_22_CollaborationSystemUser.InfoBaseUserID);
	If Not ValueIsFilled(Result) Then
		
		ErrorTemplate = NStr("en = 'Cannot get an infobase user by collaboration system user ID (%1)';");
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String(CollaborationSystemUser));
		Raise ErrorDescription;
		
	EndIf;	
	
	Return Result;
EndFunction

// Forms a correspondence between the elements of the users directory
// and the user IDs of the interaction system.
//  
// If the user is not found, an attempt will be made to create an interaction system user.
// If the user is not found and an exception was thrown when creating a new user,
// it returns Undefined.
//
// Parameters:
//   Var_InfoBaseUsers - Array of CatalogRef.Users
// 
// Returns:
//   Map of KeyAndValue:
//   * Key - CatalogRef.Users
//   * Value - CollaborationSystemUser
//
Function CollaborationSystemUsers(Var_InfoBaseUsers) Export
	CommonClientServer.CheckParameter(
		"CollaborationSystemUsers",
 		"InfoBaseUsers",
 		Var_InfoBaseUsers,
 		Type("Array"));
	
	Result = New Map;
	Errors = New Array;

	For Each User In Var_InfoBaseUsers Do
		
		Try
			Result.Insert(User, CollaborationSystemUser(User));
		Except
			Errors.Add(ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Result.Insert(User, Undefined);
		EndTry;
		
	EndDo;
	
	If Errors.Count() > 0 Then
		
		WriteLogEvent(ConversationsInternal.EventLogEvent(
			NStr("en = 'Collaboration system users';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,,,
			StrConcat(Errors, Chars.LF));
		
	EndIf;
	
	Return Result;
EndFunction

// Gets the user ID of the interaction system.
// If the user is not found, an attempt is made to create a new user.
// 
// Throws an exception if:
// - the database user ID could not be obtained;
// - failed to create an Interaction system user.
//
// Parameters:
//  User - CatalogRef.Users
//               - CatalogObject.Users
//
//  IDOnly - Boolean - 
//                                 
//
// Returns:
//   CollaborationSystemUser - 
//   
//
Function CollaborationSystemUser(User, IDOnly = False) Export
	
	IsCurrentUser = User = Users.AuthorizedUser();
	If IsCurrentUser Then
		InfoBaseUserID = InfoBaseUsers.CurrentUser().UUID;
	Else
		SetPrivilegedMode(True);
		InfoBaseUserID = ?(TypeOf(User) = Type("CatalogObject.Users"),
			User.IBUserID,
			Common.ObjectAttributeValue(
				User, "IBUserID"));
		SetPrivilegedMode(False);
		
		If Not ValueIsFilled(InfoBaseUserID) Then
			If User = Users.UnspecifiedUserRef() Then
				InfoBaseUserID = InfoBaseUsers.FindByName("").UUID;
			Else
				ErrorTemplate = NStr("en = 'Cannot get user ID (%1)';");
				ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
					ErrorTemplate,
					String(User));
					
				Raise ErrorDescription;
			EndIf;
		EndIf;
	EndIf;
	
	Result = Undefined;
	CollaborationSystemIDGettingError = "";
	Try
		If IsCurrentUser Then
			UserIDCollaborationSystem = CollaborationSystem.CurrentUserID();
		Else
			UserIDCollaborationSystem = CollaborationSystem.GetUserID(
				InfoBaseUserID);
		EndIf;
		If IDOnly Then
			Return UserIDCollaborationSystem;
		EndIf;
		Result = CollaborationSystem.GetUser(UserIDCollaborationSystem);
	Except
		ErrorInfo = ErrorInfo();
		If IsInteractionSystemConnectError(ErrorInfo) Then
			Raise;
		EndIf;
		HasConnectionWithInteractionServer = True;
		Try
			CollaborationSystem.GetExternalSystemTypes();
		Except
			HasConnectionWithInteractionServer = False;
		EndTry;
		If Not HasConnectionWithInteractionServer Then
			Raise;
		EndIf;
		CollaborationSystemIDGettingError = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	EndTry;
	
	If Result = Undefined Then
		
		Try
			SetPrivilegedMode(True);
			Result = NewCollaborationSystemUser(User);
			SetPrivilegedMode(False);
		Except
			Error = ErrorInfo();
			ErrorDescription = ?(Not ValueIsFilled(CollaborationSystemIDGettingError), "",
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot receive a collaboration system user ID for the %1 (%2) user
					           |due to:
					           |%3';"),
					String(User),
					String(InfoBaseUserID),
					CollaborationSystemIDGettingError)
				+ Chars.LF + Chars.LF);
			ErrorDescription = ErrorDescription + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Cannot create a collaboration system user for the %1 (%2) user
					           |due to:
					           |%3';"),
					String(User),
					String(InfoBaseUserID),
					ErrorProcessing.DetailErrorDescription(Error));
			WriteLogEvent(ConversationsInternal.EventLogEvent(),
				EventLogLevel.Error,,,
				ErrorDescription);
			Raise;
		EndTry;
		
	EndIf;
	
	If IDOnly Then
		Return Result.ID;
	EndIf;
	
	Return Result;
	
EndFunction

// Updates additional user information of the interaction system.
// For example, phone number and email address.
// If the interaction system user has not yet been created, a new
// interaction system user will be created.
//
// Throws an exception if the interaction system user update failed.
//
// Parameters:
//   User - CatalogRef.Users
//                - CatalogObject.Users
//
Procedure UpdateUserInCollaborationSystem(User) Export
	
	If Not CollaborationSystemConnected() Then
		Return;
	EndIf;
	
	Try
		CollaborationSystemUser = CollaborationSystemUser(User);
		UserDetails = UserDetails(User);
		UpdateUserDetailsInCollaborationSystem(
			CollaborationSystemUser,
			UserDetails);
	Except
		ErrorDescription = NStr("en = 'Cannot update the collaboration system user.';");
		Error = ErrorInfo();
		WriteLogEvent(ConversationsInternal.EventLogEvent(
			NStr("en = 'Update details in the collaboration system';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			User.Metadata(),
			User.Ref,
			ErrorDescription + Chars.LF + ErrorProcessing.DetailErrorDescription(Error));
	EndTry;
	
EndProcedure

// Generates a message description for sending a message through the procedures
// and functions of the Discussion subsystem.
//
// Parameters:
//   Text - String -  message text of the Interaction system
//         - FormattedString
//
// Returns:
//   Structure:
//   * Text - FormattedString
//   * Attachments - Array of See AttachmentDetails
//   * Data - Undefined - 
//   * Actions - ValueList - 
//
Function MessageDetails(Val Text) Export
	LongDesc = New Structure;
	
	If TypeOf(Text) = Type("String") Then
		Text = New FormattedString(Text);
	EndIf;
	
	LongDesc.Insert("Text", Text);
	LongDesc.Insert("Attachments", New Array);
	LongDesc.Insert("Data", Undefined);
	LongDesc.Insert("Actions", New ValueList);
	Return LongDesc;
EndFunction

// Generates a description of the attachment for sending messages through the procedures
// and functions of the Discussion subsystem.
//
// Parameters:
//   Stream - Stream -  the thread from which the Interaction system attachment will be created.
//         - MemoryStream
//         - FileStream
//   Description - String - 
// 
// Returns:
//   Structure:
//   * Stream - Stream - 
// 			- MemoryStream
// 			- FileStream
//   * Description - String
//   * MIMEType - String
//   * Displayed - Boolean -  the default value is True
//
Function AttachmentDetails(Stream, Description) Export

	LongDesc = New Structure;
	LongDesc.Insert("Stream", Stream);
	LongDesc.Insert("Description", Description);
	LongDesc.Insert("MIMEType", "");
	LongDesc.Insert("Displayed", True);
	Return LongDesc;

EndFunction

#EndRegion

#Region Internal

// 
// 
// 
// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  Boolean
//
Function IsInteractionSystemConnectError(ErrorInfo) Export
	
	MultiLangStrings = New Array;
	
	// 
	
	MultiLangStrings.Add(
	"az = 'Qarşılıqlı fəaliyyət sistmei qeydə alınmayıb';
	|en = 'The collaboration system is not registered';
	|hy = 'Փոխազդեցության համակարգը գրանցված չէ';
	|bg = 'Системата за взаимодействия не е регистрирана';
	|hu = 'Az interaktív rendszer nincs regisztrálva';
	|vi = 'Chưa ghi nhận hệ thống tương tác';
	|el = 'Το σύστημα αλληλεπίδρασης δεν έχει καταχωρηθεί';
	|ka = 'კომუნიკაციის სისტემა არ არის დარეგისტრირებული';
	|el = 'Το σύστημα αλληλεπίδρασης δεν έχει καταχωρηθεί';
	|it = 'Il sistema di interoperabilità non è registrato';
	|kk = 'Өзара әрекет ету жүйесі тіркелмеген';
	|zh = '交互系统没有启动';
	|lv = 'Mijiedarbības sistēma nav reģistrēta';
	|lt = 'Sąveikos sistema neužregistruota';
	|de = 'Interaktionssystem nicht registriert';
	|pl = 'System współpracy nie został zarejestrowany';
	|ro = 'Sistemul de interacţiune nu este înregistrat';
	|ru = 'Система взаимодействия не зарегистрирована';
	|tr = 'Etkileşim sistemine kayıtlı değil';
	|uk = 'Система взаємодії не зареєстрована';
	|fr = 'Le système d’interaction n’est pas enregistré'"); // @Non-NLS
	
	MultiLangStrings.Add(
	"az = 'Невозможно установить соединение с сервером системы взаимодействия';
	|en = 'Cannot connect to the collaboration system server';
	|hy = 'Невозможно установить соединение с сервером системы взаимодействия';
	|bg = 'Невозможно установить соединение с сервером системы взаимодействия';
	|hu = 'Невозможно установить соединение с сервером системы взаимодействия';
	|vi = 'Невозможно установить соединение с сервером системы взаимодействия';
	|el = 'Невозможно установить соединение с сервером системы взаимодействия';
	|ka = 'Невозможно установить соединение с сервером системы взаимодействия';
	|el = 'Невозможно установить соединение с сервером системы взаимодействия';
	|it = 'Невозможно установить соединение с сервером системы взаимодействия';
	|kk = 'Невозможно установить соединение с сервером системы взаимодействия';
	|zh = 'Невозможно установить соединение с сервером системы взаимодействия';
	|lv = 'Невозможно установить соединение с сервером системы взаимодействия';
	|lt = 'Невозможно установить соединение с сервером системы взаимодействия';
	|de = 'Невозможно установить соединение с сервером системы взаимодействия';
	|pl = 'Невозможно установить соединение с сервером системы взаимодействия';
	|ro = 'Невозможно установить соединение с сервером системы взаимодействия';
	|ru = 'Невозможно установить соединение с сервером системы взаимодействия';
	|tr = 'Невозможно установить соединение с сервером системы взаимодействия';
	|uk = 'Невозможно установить соединение с сервером системы взаимодействия';
	|fr = 'Невозможно установить соединение с сервером системы взаимодействия'"); // @Non-NLS
	
	// 
	
	BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	
	For Each MultiLangString In MultiLangStrings Do
		//@skip-check bsl-nstr-string-literal-format
		SearchString = NStr(MultiLangString);
		If ValueIsFilled(SearchString)
		   And StrStartsWith(BriefErrorDescription, SearchString) Then
			Return True;
		EndIf;
		//@skip-check bsl-nstr-string-literal-format
		SearchString = NStr(MultiLangString, "ru");
		If ValueIsFilled(SearchString)
		   And StrStartsWith(BriefErrorDescription, SearchString) Then
			Return True;
		EndIf;
		//@skip-check bsl-nstr-string-literal-format
		SearchString = NStr(MultiLangString, "en");
		If ValueIsFilled(SearchString)
		   And StrStartsWith(BriefErrorDescription, SearchString) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Procedure UpdateUserDetailsInCollaborationSystem(CollaborationSystemUser, UserDetails)
	
	Photo = UserDetails.Photo;
	If Photo <> Undefined Then
		CollaborationSystemUser.Picture = New Picture(Photo);
	EndIf;
	
	CollaborationSystemUser.Email = UserDetails.Email;
	CollaborationSystemUser.PhoneNumber = UserDetails.Phone;
	CollaborationSystemUser.IsLocked = UserDetails.Invalid Or UserDetails.DeletionMark;
	
	SetPrivilegedMode(True);
	CollaborationSystemUser.Write();
	
EndProcedure

// Creates a new user of the interaction system and fills it
// with the information database user data.
//
// Throws an exception if a new Interaction system user could not be created.
//
// Parameters:
//   User - CatalogRef.Users -  the user for which
//													the interaction system user will be created.
// Returns:
//   CollaborationSystemUser
//
Function NewCollaborationSystemUser(User)
	UserDetails = UserDetails(User);
	
	If Not ValueIsFilled(UserDetails.IBUserID) Then
		Raise NStr("en = 'Infobase user does not exist';");
	EndIf;
	
	IBUser = InfoBaseUsers.FindByUUID(
		UserDetails.IBUserID);
	CollaborationSystemUser = CollaborationSystem.CreateUser(IBUser);
	
	UpdateUserDetailsInCollaborationSystem(CollaborationSystemUser, UserDetails);
	
	Return CollaborationSystemUser;
EndFunction

Function UserDetails(User)
	Return UsersInternal.UserDetails(User);
EndFunction

// Parameters:
//  RecipientsDestination - CollaborationSystemUserIDCollection
//  RecipientsSource - CollaborationSystemUserIDCollection
//                     - Array of CollaborationSystemUser
//
Procedure AddRecipients(RecipientsDestination, RecipientsSource)
	
	If RecipientsSource.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Recipient In RecipientsSource Do 
		If TypeOf(Recipient) = Type("CollaborationSystemUserID") Then
			RecipientsDestination.Add(Recipient);
		ElsIf TypeOf(Recipient) = Type("CollaborationSystemUser") Then
			RecipientsDestination.Add(Recipient.ID);
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  Author	 - CollaborationSystemUserID
//  Member - CollaborationSystemUserID
// 
// Returns:
//    CollaborationSystemConversation
//
Function NotAGroupDiscussionBetweenUsers(Author, Member)
	Conversation = Undefined;
	
	Filter = New CollaborationSystemConversationsFilter;
	Filter.ContextConversation = False;
	Filter.Group = False;
	FoundDiscussions = CollaborationSystem.GetConversations(Filter);
	
	For Each SelectedDiscussion In FoundDiscussions Do
		If SelectedDiscussion.Members.Contains(Member) 
				And SelectedDiscussion.Members.Contains(Author) Then
			
			Conversation = SelectedDiscussion;
			Break;
		EndIf;
	EndDo;
	
	If Conversation = Undefined Then
		Conversation = CollaborationSystem.CreateConversation();
		Conversation.Displayed = True;
		Conversation.Group = False;
		Conversation.Members.Add(Author);
		Conversation.Members.Add(Member);
		Conversation.Write();
	EndIf;
	
	Return Conversation;
EndFunction

Function MessageFromTheDescription(Author, ConversationID, Recipients, Message)
	
	CollaborationSystemMessage = CollaborationSystem.CreateMessage(ConversationID);
	CollaborationSystemMessage.Author = Author.ID;
	CollaborationSystemMessage.Text = Message.Text;
	CollaborationSystemMessage.Data = Message.Data;
	For Each Action In Message.Actions Do
		CollaborationSystemMessage.Actions.Add(Action.Value, Action.Presentation);
	EndDo;
	
	AddRecipients(CollaborationSystemMessage.Recipients, Recipients);
	
	For Each Attachment In Message.Attachments Do
		CollaborationSystemMessage.Attachments.Add(Attachment.Stream, Attachment.Description, Attachment.MIMEType, 
			Attachment.Displayed);
	EndDo;
		
	Return CollaborationSystemMessage;

EndFunction

#EndRegion