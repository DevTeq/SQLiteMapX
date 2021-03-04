B4J=true
Group=Classes\Project
ModulesStructureVersion=1
Type=Class
Version=8.9
@EndOfDesignText@
Sub Class_Globals
	Private mLeftColumn As Column
	Private mRightColumn As Column
	Private mColumnList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(LeftColumn As Column, RightColumn As Column, ColumnList As List)
	mColumnList.Initialize2(ColumnList)
	Log("Newly init m2m with " & LeftColumn.Name & " and " & RightColumn.Name)
	mLeftColumn = LeftColumn
	mRightColumn = RightColumn
End Sub

Public Sub getLeftColumn As Column
	Return mLeftColumn
End Sub

Public Sub getRightColumn As Column
	Return mRightColumn
End Sub

Public Sub getColumns As List
	Return mColumnList
End Sub

Public Sub getColumnByName(Name As String) As Column
	For Each c As Column In mColumnList
		If c.Name = Name Then
			Return c
		End If
	Next
	Return Null
End Sub