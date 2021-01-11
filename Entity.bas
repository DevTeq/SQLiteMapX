B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private fx As JFX
	Private mName As String
	Private mFieldsList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Name As String)
	mName = Name
End Sub

Public Sub getName As String
	Return mName
End Sub

Public Sub setName(Name As String)
	mName = Name
End Sub