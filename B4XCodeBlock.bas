B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mCodeLineList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(FirstCodeLine As String)
	mCodeLineList.Initialize
	AddCodeLine(FirstCodeLine)
End Sub

Public Sub AddCodeLine(CodeLine As String)
	mCodeLineList.Add(CodeLine)
End Sub

Public Sub ToString() As String
	Dim Code As String
	
	For Each Codeline As String In mCodeLineList
		Code = Code & Codeline & CRLF
	Next
	
	Return Code.SubString2(0, Code.Length - 1)
End Sub

Public Sub ToCodeLines() As List
	Return mCodeLineList
End Sub