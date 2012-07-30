Attribute VB_Name = "HardSID_Host"
Option Explicit

'Windows API
Public Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Public Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Public Declare Function QueryPerformanceCounter Lib "kernel32" (lpPerformanceCount As Currency) As Long
Public Declare Function QueryPerformanceFrequency Lib "kernel32" (lpFrequency As Currency) As Long

'Constants
Public Const GWL_WNDPROC = (-4)
Private Const WM_LBUTTONUP = &H202
Private Const WM_RBUTTONUP = &H205
Private Const WM_USER = &H400

'Custom messages
Private Const HardSID_Reset = WM_USER + &H0
Private Const HardSID_Write = WM_USER + &H1
Private Const HardSID_Read = WM_USER + &H2
Private Const HardSID_Sync = WM_USER + &H3
Private Const HardSID_Flush = WM_USER + &H4
Private Const HardSID_Mute = WM_USER + &H5
Private Const HardSID_MuteAll = WM_USER + &H6
Private Const HardSID_SoftFlush = WM_USER + &H7
Private Const HardSID_Lock = WM_USER + &H8
Private Const HardSID_Filter = WM_USER + &H9
Private Const HardSID_MuteLine = WM_USER + &H9
Private Const HardSID_Init = WM_USER + &HF
Public Const HardSID_Tray = WM_USER + &H10

'Device
Public Devs As New D2XX
Public SID As D2XXDevice

'Packets
Private RegW(1) As Byte     'Register write packet
Private RegR(0) As Byte     'Register read packet
Private MuteCh(3) As Byte   'Mute channel packet
Private MuteAll(11) As Byte 'Mute all packet

'State
Public WndProc As Long      'Original window handler
Private pf As Currency      'Performance frequency
Private pce As Currency     'Performance counter tracking
Private cpuc As Long        'CPU cycle accumulator
Private buf As String       'Data buffer
Public wd As Long           'Watchdog timer

'Settings
Public devix As Integer     'Device index
Public frate As Integer     'Rate selection
Public vis As Boolean       'Visualization active

'Q
Private Const QBUFSZ = 2500
Private qbuf(QBUFSZ - 1) As Byte
Private qpos As Long
Private qloc As Long

'Visualization
Public regv(&H1F) As Byte
Public regc(&H1F) As Byte
Public rego(&H1F) As Byte

Sub SID_Open()


    'Refresh
    Devs.Refresh
    
    'Unload
    If Not SID Is Nothing Then
        Set SID = Nothing
    End If
    
    'Load new
    On Error GoTo NoSID
    Set SID = Devs.DeviceByIndex(CLng(devix))
    
    On Error Resume Next
    SID.SetFormat 500000, DATABITS_8, STOPBITS_1, PARITY_NONE
    On Error GoTo 0
    
    'Init
    QueryPerformanceFrequency pf
    MuteAll(2) = &HE1
    MuteAll(4) = &HE7
    MuteAll(6) = &HE8
    MuteAll(8) = &HEE
    MuteAll(10) = &HEF
    Exit Sub
NoSID:
    Set SID = Nothing
End Sub

Sub SID_Reset()
    pce = 0
    If Not SID Is Nothing Then
        On Error GoTo FailSID
        While SID.RxQueue
            SID.Recv vbNull, SID.RxQueue
        Wend
ResumeSID:
        On Error GoTo 0
    End If
    RegW(0) = &HC0
    RegW(1) = &H0
    On Error Resume Next
    If Not SID Is Nothing Then SID.Send RegW
    On Error GoTo 0
    RegW(0) = &HE0
    On Error Resume Next
    If Not SID Is Nothing Then SID.Send RegW
    On Error GoTo 0
    Exit Sub
FailSID:
    Resume ResumeSID
End Sub

Sub SID_Write(ByVal Register As Byte, ByVal data As Byte)
    RegW(0) = Register Or &HE0
    RegW(1) = data
    On Error Resume Next
    If Not SID Is Nothing Then SID.Send RegW
    On Error GoTo 0
End Sub

Function SID_Read(ByVal Register As Byte, ByRef data As Byte) As Byte
    Dim pcs As Currency
    Dim pce As Currency
    If SID Is Nothing Then
        SID_Read = 0
        Exit Function
    End If
    On Error GoTo FailSID1
    While SID.RxQueue
        SID.Recv vbByte Or vbArray, SID.RxQueue
    Wend
ResumeSID1:
    On Error GoTo 0
    RegR(0) = Register Or &HA0
    QueryPerformanceCounter pcs
    pce = pcs + pf / 10
    Do
        On Error GoTo FailSID2
        If SID.RxQueue Then
            SID_Read = SID.Recv(vbByte)
            Exit Do
        End If
ResumeSID2:
        On Error GoTo 0
        QueryPerformanceCounter pcs
        If pcs >= pce Then Exit Function
    Loop
    Exit Function
FailSID1:
    Resume ResumeSID1
FailSID2:
    Resume ResumeSID2
End Function

Public Sub SID_Mute(ch As Byte)
    MuteCh(0) = (ch * 7 + 0) Or &HE0
    MuteCh(2) = (ch * 7 + 1) Or &HE0
    On Error Resume Next
    SID.Send MuteCh
    On Error GoTo 0
End Sub

Public Sub SID_MuteAll()
    On Error Resume Next
    SID.Send MuteAll
    On Error GoTo 0
    wd = 0
End Sub

Public Sub SID_Sync()
    pce = 0
    cpuc = 0
    wd = 100
End Sub

Function HardSID_Message(ByVal hwnd As Long, ByVal msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
        Dim pcc As Currency
        
        Select Case msg
            
            Case HardSID_Tray                       'Tray handler
                If lParam = WM_LBUTTONUP Or lParam = WM_RBUTTONUP Then
                    frmMain.PopupMenu frmMain.mnuPopup
                End If
            
            Case HardSID_Sync                       'Sync tracking
                SID_Sync
                
            Case HardSID_Init, HardSID_Reset        'Reset state
                'Reset state on init and reset
                buf = ""
                SID_Sync
                SID_Reset
                
            Case HardSID_Write                      'HardSID write
                
                'Init PCE
                If pce = 0 Then
                    QueryPerformanceCounter pce
                End If
                
                'Track CPU cycles
                cpuc = cpuc + wParam
                
                'Q
                If 0 Then
                While qloc < cpuc
                    'qbuf = qbuf + Chr(&HFF) + Chr(0)
                    
                    qbuf(qpos) = &HFF
                    qpos = qpos + 1
                    qbuf(qpos) = 0
                    qpos = qpos + 1
                    qloc = qloc + 40
                
                    If qpos = QBUFSZ Then
                        On Error Resume Next
                        If Not SID Is Nothing Then SID.Send qbuf 'Left(qbuf, 50000)
                        DoEvents
                        On Error GoTo 0
                        qpos = 0
                        'qbuf = Mid(qbuf, 50001)
                    End If
                
                Wend
                
                qbuf(qpos) = (lParam \ &H100) Or &HE0
                qpos = qpos + 1
                qbuf(qpos) = lParam And &HFF
                qpos = qpos + 1
                qloc = qloc + 40
                
                If qpos = QBUFSZ Then
                    On Error Resume Next
                    If Not SID Is Nothing Then SID.Send qbuf 'Left(qbuf, 50000)
                    'DoEvents
                    On Error GoTo 0
                    qpos = 0
                    'qbuf = Mid(qbuf, 50001)
                End If
                End If
                
                
                If 1 Then
                If cpuc > 4000 Then 'Max 250 refresh per second
                    'Track performance counter
                    pce = pce + (CCur(cpuc) * pf) / 1000000
                    cpuc = 0
                    
                    'Wait until it's time...
                    Do
                        QueryPerformanceCounter pcc
                    Loop While pcc < pce
                    
                    'Send data
                    On Error Resume Next
                    If Not SID Is Nothing Then SID.Send buf
                    On Error GoTo 0
                    buf = ""
                    
                    'Update visualization
                    If vis Then frmVis.update
                    
                End If
                End If
                                
                'Kick watchdog
                wd = 100
            
                'Update visualization
                If lParam \ &H100 < &H20 Then
                    buf = buf + Chr((lParam \ &H100) Or &HE0) + Chr(lParam And &HFF)
                    If vis Then
                        If regv(lParam \ &H100) <> (lParam And &HFF) Then
                            regv(lParam \ &H100) = lParam And &HFF
                            regc(lParam \ &H100) = regc(lParam \ &H100) Or 2
                        Else
                            regc(lParam \ &H100) = regc(lParam \ &H100) Or 1
                        End If
                    End If
                End If
            
            Case HardSID_Read                       'HardSID simulated read
                If (lParam \ &H100) < &H20 Then
                    HardSID_Message = regv(lParam \ &H100)
                End If
                
            Case HardSID_Flush, HardSID_SoftFlush   'Flush buffers
                buf = ""
                SID_Sync
                
            Case HardSID_Mute
                If lParam <= &H200 Then
                    SID_Mute lParam \ &H100
                End If
                
            Case HardSID_MuteAll
                SID_MuteAll
                
            Case HardSID_Lock
                Debug.Print "Lock "; Hex(lParam), Hex(wParam)
            Case HardSID_Filter
                Debug.Print "Filter "; Hex(lParam), Hex(wParam)
            Case HardSID_MuteLine
                Debug.Print "MuteLine "; Hex(lParam), Hex(wParam)

            Case Else                           'Default handler
                HardSID_Message = CallWindowProc(WndProc, hwnd, msg, wParam, lParam)
        End Select
End Function
