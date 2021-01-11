B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mSelectValue As String
	Private mCompareList As List
	Private mCodeToExecuteList As List
End Sub

Public Sub Initialize(SelectValue As String, CompareList As List, CodeToExecute As List)
	mSelectValue = SelectValue
	mCompareList = CompareList
	mCodeToExecuteList = CodeToExecute
End Sub

Public Sub ToCodeBlock As B4XCodeBlock
	Dim SelectCodeBlock As B4XCodeBlock
	SelectCodeBlock.Initialize("Select " & mSelectValue)
	
	Dim Index As Int
	For Each CompareValue As String In mCompareList
		SelectCodeBlock.AddCodeLine(TAB & "Case " & CompareValue)
		Dim ExecuteCodeBlock As B4XCodeBlock = mCodeToExecuteList.Get(Index)
		For Each CodeLine In ExecuteCodeBlock.ToCodeLines
			SelectCodeBlock.AddCodeLine(TAB & TAB & CodeLine)
		Next
		Index = Index + 1
	Next
	
	If mCodeToExecuteList.Size > mCompareList.Size Then
		SelectCodeBlock.AddCodeLine(TAB & "Case Else")
		Dim ExectueCodeBlock As B4XCodeBlock = mCodeToExecuteList.Get(mCompareList.Size + 1)
		For Each CodeLine In ExectueCodeBlock.ToCodeLines
			SelectCodeBlock.AddCodeLine(TAB & TAB & CodeLine)
		Next
	End If
	
	SelectCodeBlock.AddCodeLine("End Select")
	
	Return SelectCodeBlock
End Sub