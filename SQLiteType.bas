B4J=true
Group=Classes
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Public Const sqlInteger As Int 	= 1
	Public Const sqlReal As Int		= 2
	Public Const sqlNumeric As Int 	= 3
	Public Const sqlBlob As Int 	= 4
	Public Const sqlText As Int 	= 5
End Sub

Public Sub ParseFromString(DatabaseType As String) As Int
	Select DatabaseType.ToUpperCase
		Case "TEXT"
			Return sqlInteger
		Case "BLOB"
			Return sqlBlob
		Case Else
			Return sqlInteger
	End Select
End Sub