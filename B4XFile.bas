B4J=true
Group=Classes\B4XCodeGeneration
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mName As String
	Private mIsClass As Boolean
	Private mB4XSubMap As Map
	Private mGroup As String = "ORM"
	Private mTextCode As String
End Sub

Public Sub Initialize(Name As String, IsClass As Boolean)
	mB4XSubMap.Initialize
	mName = Name
	mIsClass = IsClass
End Sub

Public Sub getName() As String
	Return mName
End Sub

Public Sub setGroup(Group As String)
	mGroup = Group
End Sub

Public Sub AddB4XSub(SubRoutine As B4XSub)
	mB4XSubMap.Put(SubRoutine.Name, SubRoutine)
End Sub

Public Sub getB4XSub(SubName As String) As B4XSub
	Return mB4XSubMap.Get(SubName)
End Sub

Public Sub setTextCode(Code As String)
	mTextCode = Code
End Sub

Public Sub ToString() As String
	Dim Code As String
	
	For Each subroutine As B4XSub In mB4XSubMap.Values
		If Code <> "" Then
			Code = Code & CRLF & CRLF
		End If
		Code = Code & subroutine.ToString
	Next
	
	Code = GenerateHeader & Code & CRLF & CRLF & mTextCode
	
	Return Code
End Sub

Private Sub GenerateHeader() As String
	Dim header As String
	header = "B4J=true" & CRLF
	header = header & "Group=" & mGroup & CRLF
	header = header & "ModulesStructureVersion=1" & CRLF
	If mIsClass Then
		header = header & "Type=Class" & CRLF
	Else
		header = header & "Type=StaticCode" & CRLF
	End If
	header = header & "Version=8.5" & CRLF
	header = header & "@EndOfDesignText@" & CRLF
	Return header
End Sub