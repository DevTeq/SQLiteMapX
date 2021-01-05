B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	
End Sub

Sub IntToBoolean(Value As Int) As Boolean
	If Value = 0 Then
		Return False
	Else
		Return True
	End If
End Sub