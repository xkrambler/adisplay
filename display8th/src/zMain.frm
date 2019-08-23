VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "richtx32.ocx"
Begin VB.Form zMain 
   BackColor       =   &H00000000&
   Caption         =   "Display 8th Hack"
   ClientHeight    =   6240
   ClientLeft      =   60
   ClientTop       =   435
   ClientWidth     =   14880
   BeginProperty Font 
      Name            =   "Segoe UI"
      Size            =   14.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   ForeColor       =   &H00E0E0E0&
   Icon            =   "zMain.frx":0000
   LinkTopic       =   "Form1"
   Picture         =   "zMain.frx":014A
   ScaleHeight     =   6240
   ScaleWidth      =   14880
   StartUpPosition =   3  'Windows Default
   Begin VB.PictureBox Picture1 
      Appearance      =   0  'Flat
      BackColor       =   &H00202020&
      BorderStyle     =   0  'None
      FillColor       =   &H000080FF&
      ForeColor       =   &H00C0C0FF&
      Height          =   810
      Left            =   360
      ScaleHeight     =   810
      ScaleWidth      =   735
      TabIndex        =   17
      Top             =   1320
      Width           =   735
      Begin VB.Label lbkey 
         Alignment       =   2  'Center
         AutoSize        =   -1  'True
         BackStyle       =   0  'Transparent
         Caption         =   "0"
         BeginProperty Font 
            Name            =   "Sansation"
            Size            =   36
            Charset         =   0
            Weight          =   700
            Underline       =   0   'False
            Italic          =   0   'False
            Strikethrough   =   0   'False
         EndProperty
         ForeColor       =   &H00C0FFFF&
         Height          =   825
         Left            =   120
         TabIndex        =   18
         Top             =   0
         Width           =   480
      End
   End
   Begin VB.Timer tmr 
      Interval        =   1
      Left            =   0
      Top             =   0
   End
   Begin VB.ListBox lst 
      Appearance      =   0  'Flat
      BackColor       =   &H00202020&
      BeginProperty Font 
         Name            =   "Pragmata"
         Size            =   14.25
         Charset         =   0
         Weight          =   500
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00C0FFC0&
      Height          =   2190
      IntegralHeight  =   0   'False
      Left            =   0
      TabIndex        =   16
      Top             =   2400
      Width           =   4095
   End
   Begin RichTextLib.RichTextBox scr 
      Height          =   1335
      Left            =   4200
      TabIndex        =   0
      Top             =   2400
      Width           =   3135
      _ExtentX        =   5530
      _ExtentY        =   2355
      _Version        =   393217
      BackColor       =   3158064
      BorderStyle     =   0
      ReadOnly        =   -1  'True
      ScrollBars      =   2
      Appearance      =   0
      TextRTF         =   $"zMain.frx":2A318C
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Pragmata"
         Size            =   14.25
         Charset         =   0
         Weight          =   500
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
   Begin VB.Label lbnum 
      Alignment       =   1  'Right Justify
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "000"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   36
         Charset         =   0
         Weight          =   300
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00C0C0FF&
      Height          =   825
      Left            =   1920
      TabIndex        =   15
      Top             =   1320
      Width           =   1440
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD6"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   5
      Left            =   8520
      TabIndex        =   14
      Top             =   720
      Width           =   810
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD5"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   4
      Left            =   7440
      TabIndex        =   13
      Top             =   720
      Width           =   795
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD4"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   3
      Left            =   6480
      TabIndex        =   12
      Top             =   720
      Width           =   795
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD3"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   2
      Left            =   5520
      TabIndex        =   11
      Top             =   720
      Width           =   795
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD2"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   1
      Left            =   4560
      TabIndex        =   10
      Top             =   720
      Width           =   810
   End
   Begin VB.Label lbcd 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "CD1"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Index           =   0
      Left            =   3600
      TabIndex        =   9
      Top             =   720
      Width           =   690
   End
   Begin VB.Label lbusb 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "USB"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   10560
      TabIndex        =   8
      Top             =   240
      Width           =   810
   End
   Begin VB.Label lbbluetooth 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "BLUETOOTH"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   8040
      TabIndex        =   7
      Top             =   240
      Width           =   2385
   End
   Begin VB.Label lbstereo 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "STEREO"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   6360
      TabIndex        =   6
      Top             =   240
      Width           =   1530
   End
   Begin VB.Label lbtp 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "TP"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   5520
      TabIndex        =   5
      Top             =   240
      Width           =   450
   End
   Begin VB.Label lbta 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "TA"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   4680
      TabIndex        =   4
      Top             =   240
      Width           =   525
   End
   Begin VB.Label lbclock 
      Alignment       =   1  'Right Justify
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "00:00"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   51.75
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFFFC0&
      Height          =   1170
      Left            =   360
      TabIndex        =   3
      Top             =   120
      Width           =   3000
   End
   Begin VB.Label lbrds 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "RDS"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   20.25
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00F0B000&
      Height          =   465
      Left            =   3600
      TabIndex        =   2
      Top             =   240
      Width           =   825
   End
   Begin VB.Label lbmsg 
      AutoSize        =   -1  'True
      BackStyle       =   0  'Transparent
      Caption         =   "WAITING DATA"
      BeginProperty Font 
         Name            =   "Sansation"
         Size            =   36
         Charset         =   0
         Weight          =   700
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      ForeColor       =   &H00FFFFFF&
      Height          =   825
      Left            =   3600
      TabIndex        =   1
      Top             =   1320
      Width           =   5175
   End
End
Attribute VB_Name = "zMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Const COLOR_ON = &HFFFFFF
Private Const COLOR_OFF = &HF0B000

Private activePackets(8) As packetType

Private Sub refreshPackets()

  Dim i As Long
  Dim p As packetType

  If packetNum() > 0 Then
    For i = 1 To UBound(packets)
      p = packets(i)
      msg IIf(p.ok, "509010OK", "994444ERR") & "808080:FFFFFF" & strData(p.data)
      refreshPacket p
    Next
    packetClear
  End If

End Sub

Private Sub refreshPacket(p As packetType)

  Dim i As Long
  Dim v As Long

  Select Case p.lenght
  Case &H5
    If Mid$(p.data, 2, 1) = ":" Then
      activePackets(1) = p
      'MsgBox strData(p.data)
      lbclock.Caption = strHex(Asc(Mid$(p.data, 4, 1))) & ":" & strHex(Asc(Mid$(p.data, 5, 1)))
    Else
      activePackets(2) = p
    End If
  
  Case &H8
    activePackets(3) = p
  
  Case &H9
    activePackets(4) = p
    If Mid$(p.data, 2, 1) = "2" Then
      v = Asc(Mid$(p.data, 7, 1))
      lbta.ForeColor = IIf(v And 1, COLOR_ON, COLOR_OFF)
      lbusb.ForeColor = IIf(v And 2, COLOR_ON, COLOR_OFF)
    End If
  
  Case &H10
    ' timming 100210103003101003000B05FF01FF54FFF4050000100376
    'MsgBox strData(p.data)
    If Mid$(p.data, 12, 1) = "T" Then
      Dim m As Integer: m = bcd2number(Mid$(p.data, 13, 2))
      Dim s As Integer: s = bcd2number(Mid$(p.data, 15, 1))
      'lbusb.ForeColor = COLOR_ON
      lbta.ForeColor = COLOR_OFF
      lbstereo.ForeColor = COLOR_OFF
      lbkey.Caption = ""
      lbnum.Caption = m & "'" & IIf(s < 10, "0", "") & s & Chr$(34)
    End If
  
  Case &H15
    activePackets(6) = p
    If Mid$(p.data, 6, 1) = Chr$(34) Then
      v = Asc(Mid$(p.data, 14, 1))
      lbstereo.ForeColor = IIf(v And 1, COLOR_ON, COLOR_OFF)
      lbkey.Caption = bcd2number(Mid$(p.data, 9, 1))
      lbmsg.Caption = Mid$(p.data, 15)
      lbnum.Caption = bcd2number(Mid$(p.data, 10, 2)) & "." & bcd2number(Mid$(p.data, 12, 1))
    End If
  
  Case &H17
    activePackets(7) = p
    'If Mid$(p.data, 6, 1) = Chr$(34) Then
      'MsgBox Mid$(p.data, 2, 1) ' esto debería ser un 4
      lbkey.Caption = ""
      lbnum.Caption = ""
      lbmsg.Caption = Replace(Mid$(p.data, 2, 15), Chr$(0), "") ' no era necesario el replace, pero acordarse de que las cadenas terminan en 0
      ' NOTA: Hay MENUs que tienen \0 en medio de la cadena
    'End If
  
  End Select
  
  ' si faltan líneas en la lista, añadir
  If lst.ListCount < UBound(activePackets) Then
    For i = 1 To UBound(activePackets) - lst.ListCount
      lst.AddItem ""
    Next
  End If
  
  ' actualizar lineas de la lista
  For i = 1 To UBound(activePackets)
    lst.List(i - 1) = strData(activePackets(i).data)
  Next
  
End Sub

Private Sub testReceive()

  Dim i As Long
  Dim T As String
  T = ""
  T = T & "100217342020424153532020202020202B330000000211000000100338"
  T = T & "10021530010000220B0102FF9130400243554152454E544110031A10021530010000220B0102FF9130400343554152454E544110031A10021530010000220B0102FF9130400343554152454E544110031A10021530010000220B0103FF9130400343554152454E544110031A10021530010000220B0103FF9130400343554152454E544110031A10021530010000220B0103FF9130400343554152454E544110031A100208300000000000FFFF10032B1002093200000002030000BE100396100208300000000000FFFF10032B1002053A0117010410033F100208300000000000FFFF10032B10021530010000220B0103FF9130400343554152454E544110031A"
  't = t & "100210103003101003000B05FF01FF54FFF4050000100376"
  For i = 1 To Len(T) / 2
    'Open "1.txt" For Append As #1
    'Print #1, "0x" & Mid(t, i * 2 - 1, 2) & ", ";
    'If i Mod 10 = 0 Then Print #1, ""
    'Close #1
    dataReceive Chr$(Val("&H" & Mid(T, i * 2 - 1, 2)))
  Next

  Exit Sub
  'Dim i As Long
  'Dim t As String
  T = ""
  T = T & "100210103003101003000B05FF01FF54FFF4050000100376"
  For i = 1 To Len(T)
    dataReceive Chr$(Val("&H" & Mid(T, i * 2 - 1, 2)))
  Next
  refreshPackets


End Sub

Private Sub Form_Load()
  
  Set serial = New cSerial

  packetInit
  'testReceive
  
  If Command$ <> "" Then
    comSelected = Command$
  Else
    comSelect.Show vbModal
    If comSelected = "" Then End
  End If

  serial.Port = "\\.\" & comSelected 'COM14
  serial.Bauds = 19200 ' 9600 38400 115200
  serial.PortClose
  serial.PortOpen
  
  If Not serial.IsPortOpen Then
    MsgBox "No se puede conectar a " & comSelected
    End
  End If
  
  'serial.Send Chr$(&H50) & Chr$(&H51) & Chr$(&H0) & Chr$(0)
  'serial.PortClose

  msgl vbCrLf
  msg "CCCCCCStarted"
  
  Me.WindowState = 2
  
End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
  
  serial.PortClose

End Sub

Private Sub Form_Resize()
  On Error Resume Next
  Dim h As Long: h = (Me.ScaleHeight - lst.Top) / 2
  lst.Move 0, lst.Top, Me.ScaleWidth, h
  scr.Move 0, lst.Top + lst.Height, Me.ScaleWidth, Me.ScaleHeight - lst.Top - lst.Height
End Sub

Private Sub lst_DblClick()
  Clipboard.Clear
  Clipboard.SetText lst.List(lst.ListIndex), vbCFText
End Sub

Private Sub tmr_Timer()

  If serial.IsPortOpen Then
    dataReceive serial.Receive
    serial.Send Chr$(6)
    refreshPackets
    If serial.IsErrors Then
      msg "FF8080DESCONECTADO: CCCCCC" & serial.LastError
      serial.PortClose
    End If
 Else
    lbmsg.Caption = "Connecting... " & serial.LastError
    serial.PortReconnect
    If serial.IsPortOpen Then msg "80FF80CONECTADO A " & serial.Port
  End If

End Sub
