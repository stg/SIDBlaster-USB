VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "clsTray"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' =======================================================
' Name:      Shell Icon Class
' Author:    Kim Pedersen, vbCode Magician
' Homepage:  vbCode Magician at
'            http://hjem.get2net.dk/vcoders/cm
' Date:      15/05-2000
' Copyright: ©2000 Visual Coders. All rights reserved
' =======================================================

Option Explicit
' Properties
Private m_Icon As StdPicture
Private m_ParentHandle As Long
Private m_ToolTip As String * 64
' Response that will be sent back to
' the parent window. You may modify this
' to suit your needs
' Declarations
Private Declare Function Shell_NotifyIcon Lib "shell32.dll" Alias "Shell_NotifyIconA" (ByVal dwMessage As Long, lpData As NOTIFYICONDATA) As Long
' UDT's
Private Type NOTIFYICONDATA
    cbSize As Long
    hwnd As Long
    uID As Long
    uFlags As Long
    uCallbackMessage As Long
    hIcon As Long
    szTip As String * 64
End Type
Private icoType As NOTIFYICONDATA
' Shell NotifyIcon Constants
Private Const NIM_ADD = &H0
Private Const NIM_MODIFY = &H1
Private Const NIM_DELETE = &H2
Private Const NIF_MESSAGE = &H1
Private Const NIF_ICON = &H2
Private Const NIF_TIP = &H4
Public Property Get Icon() As StdPicture
    Set Icon = m_Icon
End Property

Public Property Set Icon(ByVal NewValue As StdPicture)
    Set m_Icon = NewValue
End Property

Public Property Get ToolTip() As String
    ToolTip = m_ToolTip
End Property

Public Property Let ToolTip(ByVal NewValue As String)
    m_ToolTip = Left(NewValue, 64) & Chr$(0)
End Property

Public Function trayCreate() As Long
    
    ' This function will put and icon
    ' in the systray.
    
    Dim rtnVal As Long
    
    ' Set up NOTIFYICONDATA Structure
    With icoType
        .cbSize = LenB(icoType)
        .hwnd = m_ParentHandle
        .uID = 114&
        .uFlags = NIF_MESSAGE Or NIF_ICON Or NIF_TIP
        .uCallbackMessage = HardSID_Tray
        .hIcon = m_Icon
        .szTip = m_ToolTip
    End With
    
    ' Add the icon to the SysTray and return a
    ' non zero value if succesfull. Otherwise
    ' zero is returned.
    trayCreate = Shell_NotifyIcon(NIM_ADD, icoType)
    
End Function

Public Function trayModify() As Long
    
    ' This function will put and icon
    ' in the systray.
    
    Dim rtnVal As Long
    
    ' Set up NOTIFYICONDATA Structure
    With icoType
        .cbSize = LenB(icoType)
        .hwnd = m_ParentHandle
        .uID = 114&
        .uFlags = NIF_MESSAGE Or NIF_ICON Or NIF_TIP
        .uCallbackMessage = HardSID_Tray
        .hIcon = m_Icon
        .szTip = m_ToolTip
    End With
    
    ' Modify the icon to the SysTray and return a
    ' non zero value if succesfull. Otherwise
    ' zero is returned.
    trayModify = Shell_NotifyIcon(NIM_MODIFY, icoType)
    
End Function
Public Function trayDelete() As Long
    
    ' This function will put and icon
    ' in the systray.
    
    Dim rtnVal As Long
    
    ' Remove the icon to the SysTray and return a
    ' non zero value if succesfull. Otherwise
    ' zero is returned.
    trayDelete = Shell_NotifyIcon(NIM_DELETE, icoType)
    
End Function
Private Sub Class_Terminate()
    ' Clean up
    Set m_Icon = Nothing
    ' Remove the trayicon if it is
    ' still present
    trayDelete
End Sub



Public Property Get ParentHandle() As Long
    ParentHandle = m_ParentHandle
End Property

Public Property Let ParentHandle(ByVal NewValue As Long)
    m_ParentHandle = NewValue
End Property


