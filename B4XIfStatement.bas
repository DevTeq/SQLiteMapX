B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mVariablesAList As List
	Private mVariablesBList As List
	Private mConditionsList As List
	Private mCodeToExecuteList As List
End Sub

Public Sub Initialize(VariablesAList As List, ConditionsList As List, VariablesBList As List, CodeToExecuteList As List)
	mVariablesAList = VariablesAList
	mConditionsList = ConditionsList
	mVariablesBList = VariablesBList
	mCodeToExecuteList = CodeToExecuteList
End Sub

Public Sub ToCodeBlock As B4XCodeBlock
	Dim CodeBlock As B4XCodeBlock
	
	Dim Index As Int
	For Each VarA As String In mVariablesAList
		If Index > 0 Then
			CodeBlock.AddCodeLine("Else If " & VarA & " " & mConditionsList.Get(Index) & " " & mVariablesBList.Get(Index) & " Then")
		Else
			CodeBlock.Initialize("If " & VarA & " " & mConditionsList.Get(Index) & " " & mVariablesBList.Get(Index) & " Then")
		End If
		
		Dim CodeToExecuteBlock As B4XCodeBlock = mCodeToExecuteList.Get(Index)
		For Each CodeLine In CodeToExecuteBlock.ToCodeLines
			CodeBlock.AddCodeLine(TAB & CodeLine)
		Next
		Index = Index + 1
	Next
	
	If mCodeToExecuteList.Size > mVariablesAList.Size Then
		CodeBlock.AddCodeLine("Else")
		Dim ElseBlock As B4XCodeBlock = mCodeToExecuteList.Get(mCodeToExecuteList.Size - 1)
		For Each CodeLine In ElseBlock.ToCodeLines
			CodeBlock.AddCodeLine(TAB & CodeLine)
		Next
	End If
	
	CodeBlock.AddCodeLine("End If")
	
	Return CodeBlock
End Sub