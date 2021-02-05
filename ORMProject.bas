B4J=true
Group=Classes\Project
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mTableList As List
	Private mDatabasePath As String
	Private sql As SQL
	Private mName As String
End Sub

'Initialize the ORMProject from a project file (.b4orm file)
Public Sub Initialize()
	mTableList.Initialize
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

#Region InterpretDatabase
Private Sub MapDatabaseTablesToTables
	Dim rs As ResultSet = sql.ExecQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
	Do While rs.NextRow
		Dim t As Table
		Dim Modelname As String = GuessSingularNoun(rs.GetString("name"))
		t.Initialize(rs.GetString("name"), Modelname, Modelname & "Manager")
		t.AddColumns(MapDatabaseColumnsToColumns(t.Name))
		mTableList.Add(t)
	Loop
End Sub

Private Sub MapDatabaseColumnsToColumns(TableName As String) As List
	Dim ColumnList As List
	ColumnList.Initialize
	Dim rs As ResultSet = sql.ExecQuery("PRAGMA table_info('" & TableName & "')")

	Do While rs.NextRow
		Dim SplittedReference() As String = Regex.Split("|", GetForeignKeyReference(TableName, rs.GetString("name")))
		Dim ReferenceTable As String = SplittedReference(0)
		Dim ReferenceColumn As String = SplittedReference(1)
		Dim c As Column
		c.Initialize(rs.GetString("name"), rs.GetString("type"), MapDatabaseTypeToB4XType(rs.GetString("type")), ReferenceTable, ReferenceColumn,Parser.IntToBoolean(rs.GetInt("notnull")), False, False, "", False)
		ColumnList.Add(c)
	Loop
	Return ColumnList
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
	Dim b4xtypelist As List = Array As String("String", "Int", "Long", "Double", "Boolean")
	For Each t As Table In mTableList
		b4xtypelist.Add(t.Name)
	Next
	Return b4xtypelist
End Sub

Public Sub GetB4XTypesIndex(B4XType As String) As Int
	Return ListB4XTypes.IndexOf(B4XType)
End Sub
#End Region

Public Sub GuessSingularNoun(Noun As String) As String
	Dim Nouns As Map = File.ReadMap(File.DirAssets, "nouns.txt")
	
	If Nouns.ContainsKey(Noun.ToLowerCase) Then
		Dim Singular As String = Nouns.Get(Noun)
		Return Singular.SubString2(0, 1).ToUpperCase & Singular.SubString(1)
	End If
	
	Dim LastLetter As String = Noun.SubString(Noun.Length - 1)
	If LastLetter.ToLowerCase = "s" Then
		Return Noun.SubString2(0, Noun.Length - 1)
	End If
	Return Noun
End Sub