B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=8.5
@EndOfDesignText@
'Static code module
Sub Process_Globals
	Private fx As JFX
	Private ProjectForm As Form
	Private xui As XUI
	Private cmbTables As ComboBox
	Private CurrentProject As ORMProject
	Private lstColumns As CustomListView
	Private CurrentTable As Table
	Private lblColumnName As B4XView
	Private lblDatabaseColumnType As B4XView
	Private cmbB4XType As ComboBox
	Private chkNotNull As B4XView
	Private mSavePath As String
End Sub
'Opens a project from a file.
'Pass the SQLite file and True if you want to create a new project
Sub OpenProject(FilePath As String, isDatabaseFile As Boolean)
	CurrentProject.Initialize
	If isDatabaseFile Then
		CurrentProject.LoadProjectSQLite(FilePath)
	End If
	ProjectForm.Initialize("ProjectForm", -1, -1)
	ProjectForm.RootPane.LoadLayout("Project")
	ProjectForm.Show
	ProjectForm.Title = "Working with database: " & CurrentProject.DatabasePath
	FormExtension.FullScreen(ProjectForm)
	UpdateTableCombobox
	cmbTables.SelectedIndex = 0
	CurrentTable = CurrentProject.GetTable(cmbTables.Value)
	UpdateColumnList
End Sub

Sub UpdateTableCombobox
	For Each t As Table In CurrentProject.Tables
		cmbTables.Items.Add(t.Name)
	Next
End Sub

Sub UpdateColumnList
	For Each c As Column In CurrentTable.Columns
		lstColumns.Add(CreateListItem(c), c.Name)
	Next
End Sub

Sub CreateListItem(c As Column) As B4XView
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, lstColumns.AsView.Width, 50)
	p.LoadLayout("clvColumns")
	lblColumnName.Text = c.Name
	lblDatabaseColumnType.Text = c.DatabaseType
	cmbB4XType.Items.AddAll(CurrentProject.ListDatabaseTypeToB4XTypes(c.DatabaseType))
	cmbB4XType.SelectedIndex = 0
	chkNotNull.Checked = c.NotNull
	Return p
End Sub

Sub chkNotNull_CheckedChange(Checked As Boolean)
	Dim index As Int = lstColumns.GetItemFromView(Sender)
	Dim c As Column = CurrentTable.GetColumnByName(lstColumns.GetValue(index))
	c.NotNull = Checked
End Sub

Sub chkUnique_CheckedChange(Checked As Boolean)
	Dim index As Int = lstColumns.GetItemFromView(Sender)
	Dim c As Column = CurrentTable.GetColumnByName(lstColumns.GetValue(index))
	c.Unique = Checked
End Sub

Sub cmbB4XType_ValueChanged (Value As Object)
	Dim index As Int = lstColumns.GetItemFromView(Sender)
	Dim c As Column = CurrentTable.GetColumnByName(lstColumns.GetValue(index))
	c.B4XType = Value
End Sub

Sub menuMain_Action
	Dim mi As MenuItem = Sender
	Select mi.Text
		Case "Save project" 
			MenuSave
		Case "Save project as..."
				
	End Select
	If mi.Text = "Save project" Then
		MenuSave
	Else If mi.Text = "Save project as..." Then
		MenuSaveAs
	End If
End Sub

Sub MenuSaveAs
	Dim dc As DirectoryChooser
	dc.Initialize
	dc.Title = "Save As..."
	Dim SavePath As String = dc.Show(ProjectForm)
	If SavePath <> "" Then
		File.WriteString(SavePath, FileExtension.GetFilename(CurrentProject.DatabasePath) & ".b4orm", CurrentProject.ToJson.ToString)
		mSavePath = SavePath
	End If
End Sub

Sub MenuSave
	If mSavePath <> "" Then
		File.WriteString(FileExtension.GetDir(mSavePath), FileExtension.GetFilename(CurrentProject.DatabasePath) & ".b4orm", CurrentProject.ToJson.ToString)
	Else
		MenuSaveAs
	End If
End Sub