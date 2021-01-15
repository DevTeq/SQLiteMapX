B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
End Sub

'This function returns a Map of B4XFile
'Map structure is (B4XFile.Name, B4XFile)
Public Sub GenerateB4XCode(ORMP As ORMProject) As Map
	Dim FileMap As Map
	FileMap.Initialize
	FileMap.Put("DBCore", GenerateDBCore(ORMP.Tables))
	For Each t As Table In ORMP.Tables
		Dim TableModel As B4XFile = GenerateB4XModelFromTable(t)
		TableModel.Group = "ORM\Models"
		FileMap.Put(TableModel.Name, TableModel)	
		
		Dim TableManager As B4XFile = GenerateB4XManagerFromTable(t)
		TableManager.Group = "ORM\Managers"
		FileMap.Put(TableManager.Name, TableManager)
	Next
	Return FileMap
End Sub

Public Sub GenerateB4XProjectFile(ORMP As ORMProject) As String
	Dim ProjectFileCode As String
	
	ProjectFileCode = ProjectFileCode & "AppType=StandardJava" & CRLF
	ProjectFileCode = ProjectFileCode & "Build1=Default,b4j.example" & CRLF
	ProjectFileCode = ProjectFileCode & "Group=Default Group" & CRLF
	
	Dim LibraryList As List = Array As String("jcore", "jsql")
	Dim Index As Int = 1
	For Each lib As String In LibraryList
		ProjectFileCode = ProjectFileCode & "Library" & Index & "=" & lib & CRLF
		Index = Index + 1
	Next
	
	Index = 1
	For Each T As Table In ORMP.Tables
		ProjectFileCode = ProjectFileCode & "Module" & Index & "=" & T.Modelname & CRLF
		Index = Index + 1
		ProjectFileCode = ProjectFileCode & "Module" & Index & "=" & T.Managername & CRLF
		Index = Index + 1
	Next
	
	ProjectFileCode = ProjectFileCode & "Module" & Index & "=dbCore" & CRLF
	
	ProjectFileCode = ProjectFileCode & "NumberOfFiles=0" & CRLF
	ProjectFileCode = ProjectFileCode & "NumberOfLibraries=" & LibraryList.Size & CRLF
	ProjectFileCode = ProjectFileCode & "NumberOfModules=" & ((ORMP.Tables.Size * 2)+1) & CRLF '+1 is for dbCore
	ProjectFileCode = ProjectFileCode & "Version=8.8" & CRLF
	ProjectFileCode = ProjectFileCode & "@EndOfDesignText@" & CRLF
	
	Dim ProcessGlobals As B4XSub
	ProcessGlobals.Initialize("Public", "Process_Globals")
	ProjectFileCode = ProjectFileCode & ProcessGlobals.ToString & CRLF & CRLF
	
	Dim Appstart As B4XSub
	Appstart.Initialize("Public", "Appstart")
	Appstart.AddParameter("Args() As String")
	
	ProjectFileCode = ProjectFileCode & Appstart.ToString & CRLF & CRLF
	
	Dim Application_Error As B4XSub
	Application_Error.Initialize("Public", "Application_Error")
	Application_Error.AddParameter("Error As Exception")
	Application_Error.AddParameter("StackTrace As String")
	Application_Error.ReturnType = "Boolean"
	Application_Error.AddCodeLine("Return True")
	
	
	ProjectFileCode = ProjectFileCode & Application_Error.ToString
	
	Return ProjectFileCode	
End Sub

Private Sub GenerateB4XModelFromTable(T As Table) As B4XFile
	Dim TableModel As B4XFile
	TableModel.Initialize(T.Modelname, True)
	
	Dim init As B4XSub
	init.Initialize("Public", "Initialize")
	
	'Add all Globals
	Dim PGlobals As B4XSub
	PGlobals.Initialize("Public", "Class_Globals")
	TableModel.AddB4XSub(PGlobals)
	TableModel.AddB4XSub(init)
	
	Dim DBColumnMap As B4XSub
	DBColumnMap.Initialize("Public", "DBColumnMap")
	DBColumnMap.ReturnType = "Map"
	DBColumnMap.AddCodeLine(GenerateVariable("ColumnMap", "Dim", "Map"))
	DBColumnMap.AddCodeLine("ColumnMap.Initialize")
	
	Dim UniqueImmutableColumnName As String
	Dim AllColumns As String
	Dim AllColumnValues As String
	For Each c As Column In T.Columns
		AllColumns = AllColumns & Chr(34) & c.Name & Chr(34) & ", "
		AllColumnValues = AllColumnValues & "m" & c.Name & ", "
		PGlobals.AddCodeLine(GenerateVariable("m" & c.Name, "Private", c.B4XType))
		DBColumnMap.AddCodeLine("ColumnMap.Put(" & Chr(34) & c.Name & Chr(34) & ", m" & c.Name & ")")
		
		Dim getColumn As B4XSub
		getColumn.Initialize("Public","get" & c.Name)
		getColumn.ReturnType = "String"
		getColumn.AddCodeLine("Return m" & c.Name)
		TableModel.AddB4XSub(getColumn)
		
		If c.IsGenerated And c.IsImmutable = False Then
			Dim TriggerColumn As B4XSub
			TriggerColumn.Initialize("Public", "Trigger" & c.Name)
			TriggerColumn.AddCodeLine("m" & c.Name & " = " & c.DefaultValue)
			TableModel.AddB4XSub(TriggerColumn)
		End If
		
		If c.IsGenerated = False Or c.IsImmutable Then
			Dim setColumn As B4XSub
			setColumn.Initialize("Public", "set" & c.Name)
			setColumn.AddParameter(c.Name & " As " & c.B4XType)
			setColumn.AddCodeLine("m" & c.Name & " = " & c.Name)
			TableModel.AddB4XSub(setColumn)
		End If
		
		If c.Unique And c.IsImmutable Then
			UniqueImmutableColumnName = c.Name
		End If
	
		init.AddCodeLine("m" & c.Name & " = " & c.Name)
		init.AddParameter(c.Name & " As " & c.B4XType)		
	Next
	
	AllColumns = AllColumns.SubString2(0, AllColumns.Length - 2)
	AllColumnValues = AllColumnValues.SubString2(0, AllColumnValues.Length - 2)
	
	Dim Save As B4XSub
	Save.Initialize("Public", "Save")
	Save.AddCodeLine($"dbCore.UpdateObject("${T.Name}", "${UniqueImmutableColumnName}", m${UniqueImmutableColumnName}, Array As String(${AllColumns}), Array As Object(${AllColumnValues}))"$)
	TableModel.AddB4XSub(Save)
	
	DBColumnMap.AddCodeLine("Return ColumnMap")
	TableModel.AddB4XSub(DBColumnMap)
	
	Return TableModel
End Sub

#Region GenerateDBCoreCode
Private Sub GenerateDBCore(Tables As List) As B4XFile
	Dim DBCore As B4XFile
	DBCore.Initialize("DBCore", False)
	
	Dim PGlobals As B4XSub
	PGlobals.Initialize("Public", "Process_Globals")
	PGlobals.AddCodeLine(GenerateVariable("db", "Private", "SQL"))
	DBCore.AddB4XSub(PGlobals)
	
	DBCore.AddB4XSub(GenerateDBCoreInit)
	DBCore.AddB4XSub(GenerateDBCoreParseResultToObjects(Tables))
	DBCore.AddB4XSub(GenerateDBCoreDoesItemExists)
	DBCore.AddB4XSub(GenerateDBCoreGetObjectByUniqueColumnValue)
	DBCore.AddB4XSub(GenerateDBCoreInsertObjectInDatabase(Tables))
	DBCore.AddB4XSub(GenerateDBCoreIsObjectValueAvailable)
	DBCore.AddB4XSub(GenerateDBCoreListAllObjects)
	DBCore.AddB4XSub(GenerateDBCoreConvertMapValuesToList)
	DBCore.AddB4XSub(GenerateDBCoreDeleteObject)
	DBCore.AddB4XSub(GenerateDBCoreUpdateObject)
	
	Return DBCore
End Sub

Private Sub GenerateDBCoreInit() As B4XSub
	Dim Init As B4XSub
	Init.Initialize("Public", "Initialize")
	Init.AddParameter("DatabasePath As String")
	
	Dim InitIfCode As B4XCodeBlock
	InitIfCode.Initialize("db.InitializeSQLite(File.GetFileParent(DatabasePath), File.GetName(DatabasePath), False)")
	Dim InitIf As B4XIfStatement
	InitIf.Initialize(Array As String("db.IsInitialized"), Array As String("="), Array As String("False"), Array As B4XCodeBlock(InitIfCode))
	Init.AddCodeBlock(InitIf.ToCodeBlock)
	Return Init
End Sub

Private Sub GenerateDBCoreParseResultToObjects(Tables As List) As B4XSub
	Dim ParseResultToObjects As B4XSub
	ParseResultToObjects.Initialize("Private", "ParseResultToObjects")
	ParseResultToObjects.AddParameter("Result As ResultSet")
	ParseResultToObjects.AddParameter("TableName As String")
	ParseResultToObjects.ReturnType = "List"
	
	Dim InitParsedObjectListBlock As B4XCodeBlock
	InitParsedObjectListBlock.Initialize("Dim ParsedObjects As List")
	InitParsedObjectListBlock.AddCodeLine("ParsedObjects.Initialize")
	ParseResultToObjects.AddCodeBlock(InitParsedObjectListBlock)
	
	'Generate conversion code for every object in the database
	Dim SelectCodeBlocks As List
	SelectCodeBlocks.Initialize
	For Each t As Table In Tables
		Dim ConversionBlock As B4XCodeBlock
		ConversionBlock.Initialize(GenerateVariable("new" & t.Modelname, "Dim", t.Modelname))
		Dim InitString As String
		For Each c As Column In t.Columns
			InitString = InitString & "Result.Get" & c.B4XType & "(" & Chr(34) & c.Name & Chr(34) & "), "
		Next
		InitString = InitString.SubString2(0, InitString.Length -2)
		ConversionBlock.AddCodeLine("new" & t.Modelname & ".Initialize(" & InitString & ")")
		ConversionBlock.AddCodeLine("ParsedObjects.Add(new" & t.Modelname & ")")
		SelectCodeBlocks.Add(ConversionBlock)
	Next
	
	Dim TableNames As List
	TableNames.Initialize
	For Each T As Table In Tables
		TableNames.Add(Chr(34) & t.Name & Chr(34))
	Next
	
	Dim SelectCase As B4XSelect
	SelectCase.Initialize("Tablename", TableNames, SelectCodeBlocks)
	
	Dim LoopResultset As B4XWhileLoop
	LoopResultset.Initialize("Result.NextRow", SelectCase.ToCodeBlock)
	
	ParseResultToObjects.AddCodeBlock(LoopResultset.ToCodeBlock)
	
	ParseResultToObjects.AddCodeLine("Return ParsedObjects")
	
	Return ParseResultToObjects
End Sub

Private Sub GenerateDBCoreDoesItemExists As B4XSub
	Dim ItemExistsSub As B4XSub
	ItemExistsSub.Initialize("Public", "DoesItemExist")
	ItemExistsSub.AddParameters(Array As String("TableName As String", "ColumnName As String", "Value As Object"))
	ItemExistsSub.ReturnType = "Boolean"
	
	ItemExistsSub.AddCodeLine($"Return db.ExecQuery2("SELECT * FROM " & tableName & " WHERE " & columnName & " = ?", Array As Object(value)).NextRow"$)
	
	Return ItemExistsSub
End Sub

Private Sub GenerateDBCoreGetObjectByUniqueColumnValue As B4XSub
	Dim GetObjectByUniqueColumnValueSub As B4XSub
	GetObjectByUniqueColumnValueSub.Initialize("Public", "GetObjectByUniqueColumnValue")
	GetObjectByUniqueColumnValueSub.AddParameters(Array As String("TableName As String", "ColumnName As String", "Value As Object"))
	GetObjectByUniqueColumnValueSub.ReturnType = "Object"
	
	Dim SetupVariablesBlock As B4XCodeBlock
	SetupVariablesBlock.Initialize(GenerateVariable("Result", "Dim", "ResultSet"))
	SetupVariablesBlock.AddCodeLine($"Result = db.ExecQuery2("SELECT * FROM " & TableName & " WHERE " & ColumnName & " = ?", Array As Object(Value))"$)
	SetupVariablesBlock.AddCodeLine(GenerateVariable("ObjectList", "Dim", "List"))
	SetupVariablesBlock.AddCodeLine("ObjectList = ParseResultToObjects(Result, TableName)")
	GetObjectByUniqueColumnValueSub.AddCodeBlock(SetupVariablesBlock)
	
	Dim ObjectFoundCode As B4XCodeBlock
	ObjectFoundCode.Initialize("Return ObjectList.Get(0)")
	
	Dim IfCodeblock As B4XIfStatement
	IfCodeblock.Initialize(Array As String("ObjectList.Size"), Array As String(">"), Array As String("0"), Array As B4XCodeBlock(ObjectFoundCode))
	GetObjectByUniqueColumnValueSub.AddCodeBlock(IfCodeblock.ToCodeBlock)
	
	Return GetObjectByUniqueColumnValueSub
End Sub

Private Sub GenerateDBCoreInsertObjectInDatabase(Tables As List) As B4XSub
	Dim InsertObjectInDatabaseSub As B4XSub
	InsertObjectInDatabaseSub.Initialize("Public", "InsertObjectInDatabase")
	InsertObjectInDatabaseSub.AddParameter("Obj As Object")
	
	Dim SetupCode As B4XCodeBlock
	SetupCode.Initialize(GenerateVariable("Query", "Dim", "String"))
	SetupCode.AddCodeLine($"Query = "INSERT INTO ""$)
	InsertObjectInDatabaseSub.AddCodeBlock(SetupCode)
	
	Dim VarAList(Tables.Size) As String
	Dim ConditionList(Tables.Size) As String
	Dim VarBList(Tables.Size) As String
	Dim CodeList(Tables.Size) As B4XCodeBlock
	For i = 0 To Tables.Size - 1
		Dim T As Table = Tables.Get(i)
		VarAList(i) = "obj"
		ConditionList(i) = "Is"
		VarBList(i) = T.Modelname
		Dim IfCodeBlock As B4XCodeBlock
		IfCodeBlock.Initialize("Query = Query & " & Chr(34) & T.Name & " " & Chr(34))
		CodeList(i) = IfCodeBlock
	Next
	
	Dim IfSub As B4XIfStatement
	IfSub.Initialize(VarAList, ConditionList, VarBList, CodeList)
	InsertObjectInDatabaseSub.AddCodeBlock(IfSub.ToCodeBlock)
	
	InsertObjectInDatabaseSub.AddCodeLine($"Query = Query & "(" "$)
	InsertObjectInDatabaseSub.AddCodeLine($"Dim ColumnMap As Map = CallSub(obj, "dbColumnMap")"$)
	
	Dim ForEachColumnKeysCode As B4XCodeBlock
	ForEachColumnKeysCode.Initialize($"Query = Query & Value &  ", ""$)
	Dim ForEachColumnKeys As B4XForEach
	ForEachColumnKeys.Initialize("String", "ColumnMap.Keys", ForEachColumnKeysCode)
	InsertObjectInDatabaseSub.AddCodeBlock(ForEachColumnKeys.ToCodeBlock)
	
	InsertObjectInDatabaseSub.AddCodeLine($"Query = Query.SubString2(0, Query.Length - 2) & ") VALUES (""$)
	
	Dim ForEachColumnValuesCode As B4XCodeBlock
	ForEachColumnValuesCode.Initialize($"Query = Query & "?, ""$)
	Dim ForEachColumnValues As B4XForEach
	ForEachColumnValues.Initialize("String", "ColumnMap.Values", ForEachColumnValuesCode)
	InsertObjectInDatabaseSub.AddCodeBlock(ForEachColumnValues.ToCodeBlock)
	
	InsertObjectInDatabaseSub.AddCodeLine($"Query = Query.Substring2(0, Query.Length - 2) & ")""$)
	InsertObjectInDatabaseSub.AddCodeLine("db.ExecNonQuery2(Query, ConvertMapValuesToList(ColumnMap))")
	
	Return InsertObjectInDatabaseSub
End Sub

Private Sub GenerateDBCoreIsObjectValueAvailable As B4XSub
	Dim IsObjectValueAvailableSub As B4XSub
	IsObjectValueAvailableSub.Initialize("Public", "IsObjectValueAvailable")
	IsObjectValueAvailableSub.AddParameters(Array As String("TableName As String", "ColumnName As String", "Value As Object"))
	IsObjectValueAvailableSub.ReturnType = "Boolean"
	
	IsObjectValueAvailableSub.AddCodeLine($"Return db.ExecQuery2("SELECT * FROM " & tableName & " WHERE " & columnName & " = ?", Array As Object(value)).NextRow"$)
	
	Return IsObjectValueAvailableSub
End Sub

Private Sub GenerateDBCoreListAllObjects As B4XSub
	Dim ListAllObjectsSub As B4XSub
	ListAllObjectsSub.Initialize("Public", "ListAllObjects")
	ListAllObjectsSub.AddParameter("TableName As String")
	ListAllObjectsSub.ReturnType = "List"
	
	ListAllObjectsSub.AddCodeLine(GenerateVariable("Result", "Dim", "ResultSet") & $" = db.ExecQuery("SELECT * FROM " & TableName)"$)
	ListAllObjectsSub.AddCodeLine(GenerateVariable("Objects", "Dim", "List") & $" = ParseResultToObjects(Result, Tablename)"$)
	ListAllObjectsSub.AddCodeLine("Return Objects")
	
	Return ListAllObjectsSub
End Sub

Private Sub GenerateDBCoreConvertMapValuesToList() As B4XSub
	Dim ConvertMapValuesToList As B4XSub
	ConvertMapValuesToList.Initialize("Private", "ConvertMapValuesToList")
	ConvertMapValuesToList.AddParameter("m As Map")
	ConvertMapValuesToList.ReturnType = "List"
	
	ConvertMapValuesToList.AddCodeLine(GenerateVariable("lst", "Dim", "List"))
	ConvertMapValuesToList.AddCodeLine("lst.Initialize")
	
	Dim LoopCode As B4XCodeBlock
	LoopCode.Initialize("lst.Add(Value)")
	Dim MapLooper As B4XForEach
	MapLooper.Initialize("Object", "m.Values", LoopCode)
	ConvertMapValuesToList.AddCodeBlock(MapLooper.ToCodeBlock)
	
	ConvertMapValuesToList.AddCodeLine("Return lst")
	
	Return ConvertMapValuesToList
End Sub

Private Sub GenerateDBCoreDeleteObject As B4XSub
	Dim DeleteSub As B4XSub
	DeleteSub.Initialize("Public", "DeleteObject")
	DeleteSub.AddParameters(Array As String("Tablename As String", "ColumnName As String", "Value As Object"))
	
	DeleteSub.AddCodeLine($"db.ExecNonQuery2("DELETE FROM " & Tablename & " WHERE " & ColumnName &  " = ?", Array As Object(Value))"$)
	
	Return DeleteSub
End Sub

Private Sub GenerateDBCoreUpdateObject As B4XSub
	Dim UpdateObject As B4XSub
	UpdateObject.Initialize("Public", "UpdateObject")
	UpdateObject.AddParameters(Array As String("Tablename As String", "UniqueColumn As String", "UniqueValue As String", "ColumnNames As List", "Values As List"))
	UpdateObject.AddCodeLine($"Dim Query As String = "UPDATE " & UniqueColumn & " SET ""$)
	
	Dim LoopCode As B4XCodeBlock
	LoopCode.Initialize($"Query = Query & Value & " = ?, ""$)
	Dim ColumnLooper As B4XForEach
	ColumnLooper.Initialize("String", "ColumnNames", LoopCode)
	UpdateObject.AddCodeBlock(ColumnLooper.ToCodeBlock)
	
	UpdateObject.AddCodeLine($"Query = Query.SubString2(0, Query.Length - 2)"$)
	UpdateObject.AddCodeLine("Dim newValues As List")
	UpdateObject.AddCodeLine("newValues.Initialize")
	UpdateObject.AddCodeLine("NewValues.AddAll(Values)")
	UpdateObject.AddCodeLine("NewValues.Add(UniqueValue)")
	UpdateObject.AddCodeLine("db.ExecNonQuery2(Query, NewValues)")
	
	Return UpdateObject
End Sub
#End Region

#Region GenerateManagerFile
Private Sub GenerateB4XManagerFromTable(T As Table) As B4XFile
	Dim ManagerFile As B4XFile
	ManagerFile.Initialize(T.Managername, False)
	
	Dim PGlobals As B4XSub
	PGlobals.Initialize("Public", "Process_Globals")
	ManagerFile.AddB4XSub(PGlobals)
	
	ManagerFile.AddB4XSub(GenerateB4XManagerAddSub(T))
	
	For Each C As Column In T.Columns
		Dim AlreadyCreatedDeleteSub As Boolean
		If C.Unique Then
			ManagerFile.AddB4XSub(GenerateB4XManagerIsUniqueColumnAvailable(T.Name, C.Name))
			ManagerFile.AddB4XSub(GenerateB4XManagerGetByUniqueColumn(T.Name, T.Modelname, C))
			If C.IsImmutable Then
				If AlreadyCreatedDeleteSub = False Then
					ManagerFile.AddB4XSub(GenerateB4XManagerDelete(T, C.Name))
					AlreadyCreatedDeleteSub = True
				End If
			End If
			
			
		End If
	Next
	
	ManagerFile.AddB4XSub(GenerateB4XManagerListAll(T.Name))
	
	Return ManagerFile
End Sub

Private Sub GenerateB4XManagerAddSub(T As Table) As B4XSub
	Dim AddSub As B4XSub
	AddSub.Initialize("Public", "Add" & T.Modelname)
	Dim InitStringParameters As String
	For Each C As Column In T.Columns
		If C.IsMandatory Then
			If C.IsGenerated Then
				InitStringParameters = InitStringParameters & C.DefaultValue & ", "
			Else
				AddSub.AddParameter(C.Name & " As " & C.B4XType)
				InitStringParameters = InitStringParameters & C.Name & ", "
			End If			
		Else
			If C.B4XType = "string" Then
				InitStringParameters = InitStringParameters & Chr(34) & C.DefaultValue & Chr(34) & ", "
			Else
				InitStringParameters = InitStringParameters & C.DefaultValue & ", "
			End If
			
		End If
	Next
	
	AddSub.AddCodeLine(GenerateVariable("NewObject", "Dim", T.Modelname))
	AddSub.AddCodeLine("NewObject.Initialize(" & InitStringParameters.SubString2(0, InitStringParameters.Length  - 2) & ")")
	AddSub.AddCodeLine("dbCore.InsertObjectInDatabase(NewObject)")
	
	Return AddSub
End Sub

Private Sub GenerateB4XManagerIsUniqueColumnAvailable(TableName As String, UniqueColumn As String) As B4XSub
	Dim IsUniqueColumnAvailable As B4XSub
	IsUniqueColumnAvailable.Initialize("Public", "Is" & UniqueColumn & "Available")
	IsUniqueColumnAvailable.AddParameter(UniqueColumn & " As string")
	IsUniqueColumnAvailable.ReturnType = "Boolean"
	
	IsUniqueColumnAvailable.AddCodeLine($"Return dbCore.IsObjectValueAvailable("${TableName}", "${UniqueColumn}", ${UniqueColumn})"$)
	
	Return IsUniqueColumnAvailable
End Sub

Private Sub GenerateB4XManagerListAll(TableName As String) As B4XSub
	Dim ListAll As B4XSub
	ListAll.Initialize("Public", "ListAll")
	ListAll.ReturnType = "List"
	
	ListAll.AddCodeLine($"Return dbCore.ListAllObjects("${TableName}")"$)
	
	Return ListAll
End Sub

Private Sub GenerateB4XManagerGetByUniqueColumn(TableName As String, ModelName As String, UniqueColumn As Column) As B4XSub
	Dim GetByUniqueColumn As B4XSub
	GetByUniqueColumn.Initialize("Public", "GetBy" & UniqueColumn.Name)
	GetByUniqueColumn.AddParameter(UniqueColumn.Name & " As " & UniqueColumn.B4XType)
	GetByUniqueColumn.ReturnType = ModelName
	
	GetByUniqueColumn.AddCodeLine(GenerateVariable("New" & ModelName, "Dim", ModelName))
	GetByUniqueColumn.AddCodeLine("New" & ModelName & $"= dbCore.GetObjectByUniqueColumnValue("${TableName}", "${UniqueColumn.Name}", ${UniqueColumn.Name})"$)
	
	Dim ifCodeToExecute As B4XCodeBlock
	ifCodeToExecute.Initialize("Return New" & ModelName)
	
	Dim ifBlock As B4XIfStatement
	ifBlock.Initialize(Array As String("New" & ModelName & ".IsInitialized"), Array As String(""), Array As String(""), Array As B4XCodeBlock(ifCodeToExecute))
	GetByUniqueColumn.AddCodeBlock(ifBlock.ToCodeBlock)
	
	Return GetByUniqueColumn
End Sub

Private Sub GenerateB4XManagerDelete(T As Table, UniqueImmutableColumnName As String) As B4XSub
	Dim Delete As B4XSub
	Delete.Initialize("Public", "Delete")
	Delete.AddParameter(T.Modelname & "Object As " & T.Modelname)
	
	Delete.AddCodeLine($"dbCore.DeleteObject("${T.Name}", "${UniqueImmutableColumnName}", ${T.Modelname}Object.${UniqueImmutableColumnName})"$)
	
	Return Delete
End Sub
#End Region


Private Sub GenerateVariable(Name As String, AccessModifier As String, VarType As String) As String
	Return AccessModifier & " " & Name & " As " & VarType
End Sub