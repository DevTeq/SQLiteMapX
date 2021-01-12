B4J=true
Group=Classes\Project
ModulesStructureVersion=1
Type=Class
Version=8.5
@EndOfDesignText@
Sub Class_Globals
	Private mName As String
	Private mDatabaseType As String
	Private mB4XType As String
	Private mIsMandatory As Boolean
	Private mUnique As Boolean
	Private mISGenerated As Boolean
	Private mDefaultValue As String
	Private mIsImmutable As Boolean
End Sub

'Initializes the object. You can add parameters to this method if needed.
Public Sub Initialize(Name As String, DatabaseType As String, B4XType As String, IsMandatory As Boolean, Unique As Boolean, IsGenerated As Boolean, DefaultValue As String, IsImmutable As Boolean)
	mName = Name
	mDatabaseType = DatabaseType
	mB4XType = B4XType
	mIsMandatory = IsMandatory
	mUnique = Unique
	mISGenerated = IsGenerated
	mDefaultValue = DefaultValue
	mIsImmutable = IsImmutable
End Sub

Public Sub getName() As String
	Return mName
End Sub

Public Sub getDatabaseType() As String
	Return mDatabaseType
End Sub

Public Sub getIsMandatory() As Boolean
	Return mIsMandatory
End Sub

Public Sub setIsMandatory(value As Boolean)
	mIsMandatory = value
End Sub

Public Sub setB4XType(value As String)
	mB4XType = value
End Sub

Public Sub getB4XType() As String
	Return mB4XType
End Sub

Public Sub setUnique(value As Boolean)
	mUnique = value
End Sub

Public Sub getUnique As Boolean
	Return mUnique
End Sub

Public Sub setIsGenerated(value As Boolean)
	mISGenerated = value
End Sub

Public Sub getIsGenerated As Boolean
	Return mISGenerated
End Sub

Public Sub setDefaultValue(value As String)
	mDefaultValue = value
End Sub

Public Sub getDefaultValue() As String
	Return mDefaultValue
End Sub

Public Sub setIsImmutable(value As Boolean)
	mIsImmutable = value
End Sub

Public Sub getIsImmutable As Boolean
	Return mIsImmutable
End Sub

Public Sub ToMap() As Map
	Return CreateMap("name":mName, "databasetype":mDatabaseType, "b4xtype":mB4XType, "ismandatory":mIsMandatory, "unique":mUnique, "isgenerated":mISGenerated, "defaultvalue":mDefaultValue)
End Sub