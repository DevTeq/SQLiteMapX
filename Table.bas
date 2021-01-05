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
	Private mModelname As String
	Private mManagername As String
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Name As String, Modelname As String, Managername As String)
	mColumnList.Initialize
	mName = Name
	mModelname = Modelname
	mManagername = Managername
End Sub

Public Sub getName As String
	Return mName
End Sub

Public Sub setName(Name As String)
	mName = Name
End Sub

Public Sub getModelname As String
	Return mModelname
End Sub

Public Sub setModelname(Modelname As String)
	mModelname = Modelname
End Sub

Public Sub getManagername() As String
	Return mManagername
End Sub

Public Sub setManagername(Managername As String)
	mManagername = Managername
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

Public Sub ToB4XModel() As String
	Dim code As String
	code = code + "Sub Class_Globals"
	For Each c As Column In mColumnList
		code = code + CRLF + "Private m" + c.Name + " As " + c.B4XType 
	Next
	code = code + "End Sub"
	
	
End Sub