B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
End Sub

Public Sub Open
	Dim CreateReferenceForm As Form
	CreateReferenceForm.Initialize("CreateReferenceForm", -1, -1)
	CreateReferenceForm.AlwaysOnTop = True
	CreateReferenceForm.Resizable = False
	CreateReferenceForm.Show
End Sub