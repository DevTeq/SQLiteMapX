B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Public Sub Class_Globals
	Private mAccessModifier As String
	Private mName As String
	Private mReturnType As String
	Private mCodeBlockList As List
	Private mParameterList As List
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(AccessModifier As String, Name As String)
	mCodeBlockList.Initialize
	mParameterList.Initialize
	mAccessModifier = AccessModifier
	mName = Name
End Sub

Public Sub getName As String
	Return mName
End Sub

Public Sub AddCodeBlock(CodeBlock As B4XCodeBlock)
	mCodeBlockList.Add(CodeBlock)
End Sub

Public Sub AddCodeLine(Code As String)
	Dim CodeBlock As B4XCodeBlock
	CodeBlock.Initialize(Code)
	mCodeBlockList.Add(CodeBlock)
End Sub

Public Sub getCode() As String
	Dim Code As String
	For Each CodeBlock As B4XCodeBlock In mCodeBlockList
		Code = Code & CodeBlock.ToString & CRLF & CRLF
	Next
	Return Code.SubString2(0, Code.Length - 2)
End Sub

Public Sub AddParameter(Parameter As String)
	mParameterList.Add(Parameter)
End Sub

Public Sub AddParameters(Parameters As List)
	For Each Parameter As String In Parameters
		AddParameter(Parameter)
	Next
End Sub

Public Sub getParameters() As List
	Return mParameterList
End Sub

Public Sub getReturnType As String
	Return mReturnType
End Sub

Public Sub setReturnType(ReturnType As String)
	mReturnType = ReturnType
End Sub

Public Sub ToString() As String
	Dim ReturnString As String = mAccessModifier & " Sub " & mName & "("
	For Each s As String In mParameterList
		ReturnString = ReturnString & s & ", "
	Next
	If mParameterList.Size > 0 Then
		ReturnString = ReturnString.SubString2(0, ReturnString.Length - 2)
	End If

	ReturnString = ReturnString & ")"
	
	If mReturnType <> "" Then
		ReturnString = ReturnString & " As " & mReturnType
	End If
	
	ReturnString = ReturnString & CRLF
	
	For Each CodeBlock As B4XCodeBlock In mCodeBlockList
		For Each CodeLine As String In CodeBlock.ToCodeLines
			ReturnString = ReturnString & TAB & CodeLine & CRLF
		Next
	Next
	
	ReturnString = ReturnString.SubString2(0, ReturnString.Length - 1) & CRLF & "End Sub"
	
	Return ReturnString
End Sub