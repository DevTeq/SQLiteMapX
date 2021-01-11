B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

'Sub GetDir (Path As String) As String
'	If Path.Contains("/") Then Return Path.SubString2(0,Path.LastIndexOf("/"))
'	If Path.Contains("\") Then Return Path.SubString2(0,Path.LastIndexOf("\"))
'	Return ""
'End Sub

Sub GetFilename (Path As String) As String
	If Path.Contains("/") Then Return Path.SubString(Path.LastIndexOf("/") + 1)
	If Path.Contains("\") Then Return Path.SubString(Path.LastIndexOf("\") + 1)
	Return Path
End Sub