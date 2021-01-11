B4J=true
Group=Classes
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mName As String
	Private mDatabaseType As String
	Private mB4XType As String
	Private mNotNull As Boolean
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Name As String, DatabaseType As String, B4XType As String, NotNull As Boolean)
	mName = Name
	mDatabaseType = DatabaseType
	mB4XType = B4XType
	mNotNull = NotNull
End Sub