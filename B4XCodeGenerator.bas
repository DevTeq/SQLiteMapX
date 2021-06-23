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
	For Each t As Table In ORMP.Tables
		Dim TableModel As B4XFile = GenerateB4XModelFromTable(t)
		TableModel.Group = "ORM\Models"
		FileMap.Put(TableModel.Name, TableModel)	
		
		Dim TableManager As B4XFile = GenerateB4XManagerFromTable(t)
		TableManager.Group = "ORM\Managers"
		FileMap.Put(TableManager.Name, TableManager)
	Next
	
	For Each Relation As ManyToManyRelation In ORMP.ManyToManyRelations
		Dim LeftModel As B4XFile = FileMap.Get(Relation.LeftColumn.ParentTable.Name)
		LeftModel.AddB4XSub(GenerateRelationList(Relation.LeftColumn.ParentTable, Relation.RightColumn.ParentTable))
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
		ProjectFileCode = ProjectFileCode & "Module" & Index & "=" & T.Name & CRLF
		Index = Index + 1
		ProjectFileCode = ProjectFileCode & "Module" & Index & "=" & T.Name & "Manager" & CRLF
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
	TableModel.Initialize(T.Name, True)
	
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
		If c.IsMandatory = False Then
			Dim isVariableNullTrue As B4XCodeBlock
			isVariableNullTrue.Initialize("ColumnMap.Put(" & Chr(34) & c.Name & Chr(34) & ", Null)")
			Dim isVariableNullFalse As B4XCodeBlock
			isVariableNullFalse.Initialize("ColumnMap.Put(" & Chr(34) & c.Name & Chr(34) & ", m" & c.Name & ")")
			PGlobals.AddCodeLine(GenerateVariable("mIs" & c.Name & "Null", "Private", "Boolean = True"))
			Dim ifVariableIsNull As B4XIfStatement
			ifVariableIsNull.Initialize(Array As String("mIs" & c.Name & "Null", "mIs" & c.Name & "Null"), Array As String("=", "="), Array As String("True", "False"), Array As B4XCodeBlock(isVariableNullTrue, isVariableNullFalse))
			DBColumnMap.AddCodeBlock(ifVariableIsNull.ToCodeBlock)
		Else
			DBColumnMap.AddCodeLine("ColumnMap.Put(" & Chr(34) & c.Name & Chr(34) & ", m" & c.Name & ")")
		End If
		
		Dim getColumn As B4XSub
		getColumn.Initialize("Public","get" & c.Name)
		getColumn.ReturnType = c.B4XType
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
			If c.IsMandatory = False Then setColumn.AddCodeLine("mIs" & c.Name & "Null = False")
			
			TableModel.AddB4XSub(setColumn)
		End If
		
		If c.Unique And c.IsImmutable Then
			UniqueImmutableColumnName = c.Name
		End If
		
		If c.IsMandatory Then
			init.AddCodeLine("m" & c.Name & " = " & c.Name)
			init.AddParameter(c.Name & " As " & c.B4XType)
		End If
			
	Next
	
	AllColumns = AllColumns.SubString2(0, AllColumns.Length - 2)
	AllColumnValues = AllColumnValues.SubString2(0, AllColumnValues.Length - 2)
	
	Dim Save As B4XSub
	Save.Initialize("Public", "Save")
	Save.AddCodeLine(GenerateVariable("ValueList", "Dim", "List"))
	Save.AddCodeLine("ValueList.Initialize")
	For Each c As Column In T.Columns
		If c.IsMandatory Then
			Save.AddCodeLine("ValueList.Add(m" & c.Name & ")")
		Else
			Dim ifIsNullTrueCode As B4XCodeBlock
			ifIsNullTrueCode.Initialize("ValueList.Add(Null)")
			Dim ifIsNullFalseCode As B4XCodeBlock
			ifIsNullFalseCode.Initialize("ValueList.Add(m" & c.Name &")")
			Dim ifIsNull As B4XIfStatement
			ifIsNull.Initialize(Array As String("mIs" & c.Name & "Null", "mIs" & c.Name & "Null"), Array As String("=", "="), Array As String("True", "False"), Array As B4XCodeBlock(ifIsNullTrueCode, ifIsNullFalseCode))
			Save.AddCodeBlock(ifIsNull.ToCodeBlock)
		End If
	Next

	Save.AddCodeLine($"dbCore.UpdateObject("${T.Name}", "${UniqueImmutableColumnName}", m${UniqueImmutableColumnName}, Array As String(${AllColumns}), ValueList)"$)
	TableModel.AddB4XSub(Save)
	
	Dim UpdateByMap As B4XSub
	UpdateByMap.Initialize("Public", "UpdateByMap")
	UpdateByMap.AddParameter("m As Map")
	Dim UpdateByMapLoopCode As B4XCodeBlock
	UpdateByMapLoopCode.Initialize($"CallSub2(Me, "set" & value, m.Get(value))"$)
	Dim UpdateByMapLoop As B4XForEach
	UpdateByMapLoop.Initialize("String", "m.Keys", UpdateByMapLoopCode)
	UpdateByMap.AddCodeBlock(UpdateByMapLoop.ToCodeBlock)
	TableModel.AddB4XSub(UpdateByMap)
	
	DBColumnMap.AddCodeLine("Return ColumnMap")
	TableModel.AddB4XSub(DBColumnMap)
	
	Return TableModel
End Sub

#Region GenerateManagerFile
Private Sub GenerateB4XManagerFromTable(T As Table) As B4XFile
	Dim ManagerFile As B4XFile
	ManagerFile.Initialize(T.Name & "Manager", False)
	
	Dim PGlobals As B4XSub
	PGlobals.Initialize("Public", "Process_Globals")
	ManagerFile.AddB4XSub(PGlobals)
	
	ManagerFile.AddB4XSub(GenerateB4XManagerAddSub(T))
	
	For Each C As Column In T.Columns
		Dim AlreadyCreatedDeleteSub As Boolean
		If C.Unique Then
			ManagerFile.AddB4XSub(GenerateB4XManagerIsUniqueColumnAvailable(T.Name, C.Name))
			ManagerFile.AddB4XSub(GenerateB4XManagerGetByUniqueColumn(T.Name, C))
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
	AddSub.Initialize("Public", "Add" & T.Name)
	AddSub.ReturnType = T.Name
	
	Dim InitStringParameters As String
	For Each C As Column In T.Columns
		If C.IsMandatory Then
			If C.IsGenerated Then
				InitStringParameters = InitStringParameters & C.DefaultValue & ", "
			Else
				If C.ReferenceTable <> "" Then
					AddSub.AddParameter(C.Name & " As " & C.ReferenceTable)
					InitStringParameters = InitStringParameters & C.Name & "." & C.ReferenceColumn & ", "
				Else
					AddSub.AddParameter(C.Name & " As " & C.B4XType)
					InitStringParameters = InitStringParameters & C.Name & ", "
				End If
				
			End If			
		Else
			If C.DefaultValue <> "" Then
				If C.B4XType = "string" Then
					InitStringParameters = InitStringParameters & Chr(34) & C.DefaultValue & Chr(34) & ", "
				Else
					InitStringParameters = InitStringParameters & C.DefaultValue & ", "
				End If
			End If
		End If
	Next
	
	AddSub.AddCodeLine(GenerateVariable("NewObject", "Dim", T.Name))
	AddSub.AddCodeLine("NewObject.Initialize(" & InitStringParameters.SubString2(0, InitStringParameters.Length  - 2) & ")")
	AddSub.AddCodeLine("dbCore.InsertObjectInDatabase(NewObject)")
	AddSub.AddCodeLine("Return NewObject")
	
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

Private Sub GenerateB4XManagerGetByUniqueColumn(TableName As String, UniqueColumn As Column) As B4XSub
	Dim GetByUniqueColumn As B4XSub
	GetByUniqueColumn.Initialize("Public", "GetBy" & UniqueColumn.Name)
	GetByUniqueColumn.AddParameter(UniqueColumn.Name & " As " & UniqueColumn.B4XType)
	GetByUniqueColumn.ReturnType = TableName
	
	GetByUniqueColumn.AddCodeLine(GenerateVariable("New" & TableName, "Dim", TableName))
	GetByUniqueColumn.AddCodeLine("New" & TableName & $"= dbCore.GetObjectByUniqueColumnValue("${TableName}", "${UniqueColumn.Name}", ${UniqueColumn.Name})"$)
	
	Dim ifCodeToExecute As B4XCodeBlock
	ifCodeToExecute.Initialize("Return New" & TableName)
	
	Dim ifBlock As B4XIfStatement
	ifBlock.Initialize(Array As String("New" & TableName & " <> Null AND New" & TableName & ".IsInitialized"), Array As String(""), Array As String(""), Array As B4XCodeBlock(ifCodeToExecute))
	GetByUniqueColumn.AddCodeBlock(ifBlock.ToCodeBlock)
	
	GetByUniqueColumn.AddCodeLine("Return Null")
	Return GetByUniqueColumn
End Sub

Private Sub GenerateB4XManagerDelete(T As Table, UniqueImmutableColumnName As String) As B4XSub
	Dim Delete As B4XSub
	Delete.Initialize("Public", "Delete")
	Delete.AddParameter(T.Name & "Object As " & T.Name)
	
	Delete.AddCodeLine($"dbCore.DeleteObject("${T.Name}", "${UniqueImmutableColumnName}", ${T.Name}Object.${UniqueImmutableColumnName})"$)
	
	Return Delete
End Sub
#End Region

#Region RelationsCode
Private Sub GenerateRelationList(LeftTable As Table, RightTable As Table) As B4XSub
	Dim ListAllReferenceObjectSub As B4XSub
	ListAllReferenceObjectSub.Initialize("Public", "get" & RightTable.Name & "List")
	ListAllReferenceObjectSub.ReturnType = "List"
	ListAllReferenceObjectSub.AddCodeLine($"Return DBcore.GetManyToManyList("${LeftTable.Name}", mID, "${LeftTable.Name}_${RightTable.Name}", "${RightTable.Name}")"$)
	
	Return ListAllReferenceObjectSub
End Sub

Private Sub GenerateVariable(Name As String, AccessModifier As String, VarType As String) As String
	Return AccessModifier & " " & Name & " As " & VarType
End Sub
#End Region