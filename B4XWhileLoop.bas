B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mCondition As String
	Private mCodeToExecute As B4XCodeBlock
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Condition As String, CodeToExecuteList As B4XCodeBlock)
	mCondition = Condition
	mCodeToExecute = CodeToExecuteList
End Sub

Public Sub ToCodeBlock As B4XCodeBlock
	Dim LoopBlock As B4XCodeBlock
	LoopBlock.Initialize("Do While " & mCondition)
	For Each CodeLine As String In mCodeToExecute.ToCodeLines
		LoopBlock.AddCodeLine(TAB & CodeLine)
	Next
	LoopBlock.AddCodeLine("Loop")
	Return LoopBlock
End Sub