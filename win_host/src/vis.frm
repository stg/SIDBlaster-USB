VERSION 5.00
Begin VB.Form frmVis 
   AutoRedraw      =   -1  'True
   BackColor       =   &H00000000&
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "SID registers"
   ClientHeight    =   1440
   ClientLeft      =   45
   ClientTop       =   285
   ClientWidth     =   3765
   ControlBox      =   0   'False
   BeginProperty Font 
      Name            =   "Courier New"
      Size            =   15.75
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   Icon            =   "vis.frx":0000
   LinkTopic       =   "Form2"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   96
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   251
   StartUpPosition =   2  'CenterScreen
End
Attribute VB_Name = "frmVis"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

'Refresh
Public Sub update()
    Dim x As Long
    Dim y As Long
    Dim n As Double
    Dim z As Byte
    Dim q As Byte
    Dim a As Byte
    Dim b As Byte
    Me.Cls
    For y = 0 To 3
        For x = 0 To 7
            Me.CurrentY = y * 24
            Me.CurrentX = x * 32
            q = y * 8 + x
            If regc(q) And 2 Then
                Me.ForeColor = vbGreen
            ElseIf regc(q) And 1 Then
                Me.ForeColor = vbRed
            Else
                Me.ForeColor = vbWhite
            End If
            regc(q) = False
            Me.Print IIf(regv(q) < 16, "0", "") + Hex(regv(q));
            For z = 0 To 7
                a = (regv(q) And (2 ^ (7 - z)))
                b = (rego(q) And (2 ^ (7 - z)))
                If (regv(q) And 2 ^ (7 - z)) <> 0 Then
                    Me.Line (x * 32 + z * 3 + 2, y * 24 + 20)-(x * 32 + z * 3 + 3, y * 24 + 21), &HFF7F7F, BF
                End If
                If a <> b Then
                    Me.Line (x * 32 + z * 3 + 1, y * 24 + 19)-(x * 32 + z * 3 + 4, y * 24 + 22), IIf(a < b, &HFF3F3F, &HFFFFFF), B
                End If
                
            Next
            rego(q) = regv(q)
        Next
    Next
End Sub

