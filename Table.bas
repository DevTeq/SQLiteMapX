B4J=true
Group=Classes\Project
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private mName As String
	Private mColumnList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Name As String)
	mColumnList.Initialize
	mName = Name
End Sub

Public Sub getName As String
	Return mName
End Sub

Public Sub setName(Name As String)
	mName = Name
End Sub

Public Sub AddColumns(Columns As List)
	mColumnList.AddAll(Columns)
End Sub

Public Sub getColumns As List
	Return mColumnList
End Sub

Public Sub GetColumnByName(Name As String) As Column
	For Each c As Column In mColumnList
		If c.Name = Name Then
			Return c
		End If
	Next
End Sub

Public Sub ToMap() As Map
	Dim columnList As List
	columnList.Initialize
	For Each c As Column In mColumnList
		columnList.Add(c.ToMap)
	Next
	
	Return CreateMap("name":mName, "columns":columnList)
End Sub