B4J=true
Group=Classes\Project
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mTableList As List
	Private mManyToManyRelationList As List
	Private mDatabasePath As String
	Private sql As SQL
	Private mName As String
End Sub

'Initialize the ORMProject from a project file (.b4orm file)
Public Sub Initialize()
	mTableList.Initialize
	mManyToManyRelationList.Initialize
End Sub

'Initializes the ORMProject starting from a SQLitePath.
'This class tries to figure out the correct types based on the database
Public Sub LoadProjectSQLite(DatabasePath As String)
	Try
		sql.InitializeSQLite(File.GetFileParent(DatabasePath), File.GetName(DatabasePath), False)
	Catch
		Dim e As ExceptionEx
		e.Initialize(LastException)
		e.Throw
	End Try
	mName = Regex.Split("\.", File.GetName(DatabasePath))(0)
	mDatabasePath = DatabasePath
	MapDatabaseTablesToTables
End Sub

Public Sub getName As String
	Return mName
End Sub

Public Sub AddTable(NewTable As Table)
	mTableList.Add(NewTable)
End Sub

Public Sub getDatabasePath() As String
	Return mDatabasePath
End Sub

Public Sub getTables() As List
	Return mTableList
End Sub

Public Sub GetTable(Name As String) As Table
	For Each t As Table In mTableList
		If t.Name = Name Then
			Return t
		End If
	Next
	Return Null
End Sub

Public Sub getManyToManyRelations() As List
	Return mManyToManyRelationList
End Sub

Public Sub GetManyToManyRelation(LeftTableName As String, RightTableName As String) As ManyToManyRelation
	For Each m2m As ManyToManyRelation In mManyToManyRelationList
		If (m2m.LeftColumn.ParentTable.Name = LeftTableName) And (m2m.RightColumn.ParentTable.Name = RightTableName) Then
			Return m2m
		End If
	Next
	Return Null
End Sub

#Region InterpretDatabase
Private Sub MapDatabaseTablesToTables
	Dim getTablesSQL As String = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
	'First do normal tables
	Dim rs As ResultSet = sql.ExecQuery(getTablesSQL)
	Do While rs.NextRow
		If rs.GetString("name").Contains("_") = False Then 
			Dim t As Table
			t.Initialize(rs.GetString("name"))
			t.AddColumns(MapDatabaseColumnsToColumns(T))
			mTableList.Add(t)
		End If
	Loop
	
	'Then ManyToManyRelations are handled
	rs = sql.ExecQuery(getTablesSQL)
	Do While rs.NextRow
		Dim databaseName As String = rs.GetString("name")
		If databaseName.Contains("_") Then
			Dim leftTable As Table = GetTable(Regex.Split("_", databaseName)(0))
			Dim rightTable As Table = GetTable(Regex.Split("_", databaseName)(1))
			
			Dim ColumnList As List = MapRelationColumnsToColumns(databaseName, leftTable, rightTable)
			
			Dim SubList As List
			SubList.Initialize
			
			For i = 2 To ColumnList.Size - 1
				SubList.Add(ColumnList.Get(i))
			Next
			
			Dim ManyToMany As ManyToManyRelation
			ManyToMany.Initialize(ColumnList.Get(0), ColumnList.Get(1), SubList)
			mManyToManyRelationList.Add(ManyToMany)
		End If
	Loop
End Sub

Private Sub MapDatabaseColumnsToColumns(T As Table) As List
	Dim ColumnList As List
	ColumnList.Initialize
	Dim rs As ResultSet = sql.ExecQuery("PRAGMA table_info('" & T.Name & "')")

	Dim isIDColumnPresent As Boolean
	Do While rs.NextRow
		Dim ColumnName As String = rs.GetString("name")
		If ColumnName = "ID" Then
			isIDColumnPresent = True
		End If
		Dim B4XType As String = MapDatabaseTypeToB4XType(rs.GetString("type"))
		Dim ReferenceTable As String
		Dim ReferenceColumn As String
		Dim SplittedReference As List = Regex.Split("\|", GetForeignKeyReference(T.Name, ColumnName))
		If SplittedReference.Size = 2 Then
			ReferenceTable = SplittedReference.Get(0)
			ReferenceColumn = SplittedReference.Get(1)
		End If
		Dim c As Column
		c.Initialize(ColumnName, rs.GetString("type"), B4XType, ReferenceTable, ReferenceColumn, Parser.IntToBoolean(rs.GetInt("notnull")), IsColumnUnique(T.Name, ColumnName), False, "", IsImmutable(T.Name, ColumnName), T)
		ColumnList.Add(c)
	Loop
	
	If isIDColumnPresent = False Then
		Dim ex As ExceptionEx
		ex.Initialize($"Table "${T.Name}" is missing a column named ID."$)
		ex.Throw
	End If
	
	Return ColumnList
End Sub

Private Sub MapRelationColumnsToColumns(RelationTableName As String, LeftTable As Table, RightTable As Table) As List
	Dim ColumnList As List
	ColumnList.Initialize
	Dim rs As ResultSet = sql.ExecQuery("PRAGMA table_info('" & RelationTableName & "')")

	Dim index As Int
	Do While rs.NextRow
		Dim ColumnName As String = rs.GetString("name")
		Dim B4XType As String = MapDatabaseTypeToB4XType(rs.GetString("type"))
		Dim c As Column
		Dim parentTable As Table
		Select index
			Case 0
				parentTable = LeftTable
			Case 1
				parentTable = RightTable
			Case Else
				parentTable = Null
		End Select
		c.Initialize(ColumnName, rs.GetString("type"), B4XType, "", "", Parser.IntToBoolean(rs.GetInt("notnull")), False, False, "", False, parentTable)
		ColumnList.Add(c)
		index = index + 1
	Loop
	Return ColumnList
End Sub

Private Sub IsColumnUnique(TableName As String, ColumnName As String) As Boolean
	Dim rs As ResultSet = sql.ExecQuery($"SELECT (SELECT name FROM pragma_index_info(pmi.name)) AS UniqueColumn FROM pragma_index_list("${TableName}") AS pmi"$)
	Do While rs.NextRow
		If rs.GetString("UniqueColumn") = ColumnName Then
			Return True
		End If
	Loop
	Return False
End Sub

Private Sub IsImmutable(TableName As String, ColumnName As String) As Boolean
	Dim rs As ResultSet = sql.ExecQuery($"SELECT (SELECT name FROM pragma_index_info(pmi.name)) AS UniqueColumn, origin FROM pragma_index_list("${TableName}") AS pmi WHERE origin = "pk""$)
	Do While rs.NextRow
		If rs.GetString("UniqueColumn") = ColumnName Then
			Return True
		End If
	Loop
	Return False
End Sub

Private Sub GetForeignKeyReference(TableName As String, ColumnName As String) As String
	Dim Reference As String
	Dim rsForeignKeys As ResultSet = sql.ExecQuery("SELECT * FROM pragma_foreign_key_list('" & TableName & "');")
	Do While rsForeignKeys.NextRow
		If rsForeignKeys.GetString("from") = ColumnName Then
			Reference = rsForeignKeys.GetString("table") & "|" & rsForeignKeys.GetString("to") 
		End If
	Loop
	Return Reference
End Sub

Private Sub MapDatabaseTypeToB4XType(DatabaseType As String) As String
	Select DatabaseType
		Case "TEXT"
			Return "String"
		Case "BLOB"
			Return "String"
		Case "INTEGER"
			Return "Int"
		Case "NUMERIC"
			Return "Boolean"
		Case Else
			Return "Double"
	End Select
End Sub

Public Sub ToJson() As JSONGenerator
	Dim TableList As List
	TableList.Initialize
	For Each t As Table In mTableList
		TableList.Add(t.ToMap)
	Next
	
	Dim projectMap As Map = CreateMap("databasepath": mDatabasePath, "tables":TableList)
	
	Dim json As JSONGenerator
	json.Initialize(projectMap)
	Return json
End Sub

public Sub ListB4XTypes As List
	Dim b4xtypelist As List
	b4xtypelist.Initialize
	b4xtypelist.AddAll(Array As String("String", "Int", "Long", "Double", "Boolean"))
	Return b4xtypelist
End Sub

Public Sub GetB4XTypesIndex(B4XType As String) As Int
	Return ListB4XTypes.IndexOf(B4XType)
End Sub
#End Region