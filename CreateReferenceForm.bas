B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.8
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private cmbTables As ComboBox
	Private cmbColumns As ComboBox
	Private mTableList As List
End Sub

Public Sub Open(TableList As List) As String
	mTableList = TableList
	Dim frm As Form
	frm.Initialize("CreateReferenceForm", -1, -1)
	frm.RootPane.LoadLayout("CreateReference")
	frm.AlwaysOnTop = True
	frm.Resizable = False
	frm.Show
	LoadTables(TableList)
	cmbTables.SelectedIndex = 0
	Return "Test"
End Sub

Private Sub LoadTables(TableList As List)
	For Each t As Table In TableList
		Log(t.Name)
		cmbTables.Items.Add(t.Name)
	Next
End Sub

Private Sub LoadColumns(T As Table)
	cmbColumns.Items.Clear
	
	For Each c As Column In T.Columns
		cmbColumns.Items.Add(c.Name)
	Next
End Sub

Private Sub cmbTables_SelectedIndexChanged(Index As Int, Value As Object)
	LoadColumns(mTableList.Get(Index))
End Sub