VERSION 5.00
Begin VB.Form frmMain 
   Caption         =   "HardSID_Host"
   ClientHeight    =   3975
   ClientLeft      =   225
   ClientTop       =   855
   ClientWidth     =   6375
   Icon            =   "main.frx":0000
   LinkTopic       =   "Form1"
   ScaleHeight     =   3975
   ScaleWidth      =   6375
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Visible         =   0   'False
   Begin VB.Timer tQuiet 
      Interval        =   100
      Left            =   60
      Top             =   60
   End
   Begin VB.Menu mnuPopup 
      Caption         =   "mnuPopup"
      Begin VB.Menu mniDev 
         Caption         =   "\\ftdi0"
         Checked         =   -1  'True
         Index           =   0
      End
      Begin VB.Menu mnl1 
         Caption         =   "-"
      End
      Begin VB.Menu mniRate 
         Caption         =   "50hz PAL (0.985MHz)"
         Checked         =   -1  'True
         Index           =   0
         Visible         =   0   'False
      End
      Begin VB.Menu mniRate 
         Caption         =   "60hz NTSC (1.02MHz)"
         Index           =   1
         Visible         =   0   'False
      End
      Begin VB.Menu mniRegs 
         Caption         =   "Show registers"
      End
      Begin VB.Menu mnl2 
         Caption         =   "-"
      End
      Begin VB.Menu mniReset 
         Caption         =   "Reset"
      End
      Begin VB.Menu mniMute 
         Caption         =   "Mute"
      End
      Begin VB.Menu mnl3 
         Caption         =   "-"
      End
      Begin VB.Menu mniQuit 
         Caption         =   "Quit"
      End
   End
End
Attribute VB_Name = "frmMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
    
Private tray As New clsTray

Private Sub Form_Load()
    Dim n As Long
    
    'Get devices
    Devs.Refresh
    If Devs.Count = 0 Then
        MsgBox "No device found!", vbCritical
        mniDev(0).Visible = False
    End If
    For n = 1 To Devs.Count - 1
        Load mniDev(n)
        mniDev(n).Caption = "\\ftdi" + CStr(n)
        mniDev(n).Checked = False
    Next
    
    'Restore device index
    devix = Val(GetSetting("HardSID_host", "Cfg", "Dev", 0))
    If devix >= mniDev.Count Then
        devix = mniDev.Count - 1
    End If
    mniDev_Click devix
    
    'Restore rate
    frate = Val(GetSetting("HardSID_host", "Cfg", "Osc", 1))
    frate = IIf(frate, 1, 0)
    mniRate_Click frate
    
    'Replace window handler
    WndProc = SetWindowLong(frmMain.hwnd, GWL_WNDPROC, AddressOf HardSID_Message)

    'Add to systray
    Set tray.Icon = Me.Icon
    tray.ParentHandle = frmMain.hwnd
    tray.ToolTip = "HardSID host"
    tray.trayCreate

End Sub

Private Sub Form_Unload(Cancel As Integer)
    'Quiet
    SID_Reset
    
    'Store settings
    SaveSetting "HardSID_host", "Cfg", "Dev", CStr(devix)
    SaveSetting "HardSID_host", "Cfg", "Osc", CStr(frate)
    
    'Renive from systray
    tray.trayDelete
    
    'Restore window handler
    SetWindowLong frmMain.hwnd, GWL_WNDPROC, WndProc
    
    'Unload visualization
    Unload frmVis
End Sub

Private Sub mniDev_Click(Index As Integer)
    Dim n As Long
    
    'Set new device
    For n = 0 To mniDev.Count - 1
        mniDev(n).Checked = (n = Index)
    Next
    devix = Index
    
    'Quiet
    SID_Reset
    
    'Open new device
    SID_Open
End Sub

Private Sub mniMute_Click()
    SID_MuteAll
End Sub

Private Sub mniQuit_Click()
    Unload Me
End Sub

Private Sub mniRate_Click(Index As Integer)
    'Set new rate
    mniRate(1 - Index).Checked = False
    mniRate(Index).Checked = True
    frate = Index
End Sub

Private Sub mniRegs_Click()
    'Hide/show visualization
    vis = Not vis
    mniRegs.Checked = vis
    If vis Then
        frmVis.Show
    Else
        Unload frmVis
    End If
End Sub

Private Sub mniReset_Click()
    'Quiet
    SID_Reset
End Sub

Private Sub tQuiet_Timer()
    If wd > 0 Then
        wd = wd - 10
        'Quiet
        If wd <= 0 Then
            SID_MuteAll
            SID_Sync
        End If
    End If
End Sub
