B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.8
@EndOfDesignText@
Sub Class_Globals
	Private mObjectType As String
	Private mCollection As String
	Private mCodeToExecute As B4XCodeBlock
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(ObjectType As String, Collection As String, CodeToExecute As B4XCodeBlock)
	mObjectType = ObjectType
	mCollection = Collection
	mCodeToExecute = CodeToExecute
End Sub

Public Sub ToCodeBlock As B4XCodeBlock
	Dim CodeBlock As B4XCodeBlock
	CodeBlock.Initialize("For Each Value As " & mObjectType & " in " & mCollection)
	For Each CodeLine As String In mCodeToExecute.ToCodeLines
		CodeBlock.AddCodeLine(TAB & CodeLine)
	Next
	CodeBlock.AddCodeLine("Next")
	
	Return CodeBlock
End Sub