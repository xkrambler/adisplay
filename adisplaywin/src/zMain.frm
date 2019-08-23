VERSION 5.00
Object = "{3B7C8863-D78F-101B-B9B5-04021C009402}#1.2#0"; "RICHTX32.OCX"
Begin VB.Form zMain 
   BackColor       =   &H00000000&
   Caption         =   "Display 8th Hack"
   ClientHeight    =   7995
   ClientLeft      =   60
   ClientTop       =   435
   ClientWidth     =   14445
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
   ScaleHeight     =   7995
   ScaleWidth      =   14445
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer tmr 
      Interval        =   1
      Left            =   0
      Top             =   0
   End
   Begin RichTextLib.RichTextBox scr 
      Height          =   1335
      Left            =   720
      TabIndex        =   0
      Top             =   480
      Width           =   3135
      _ExtentX        =   5530
      _ExtentY        =   2355
      _Version        =   393217
      BackColor       =   3158064
      BorderStyle     =   0
      ReadOnly        =   -1  'True
      ScrollBars      =   2
      Appearance      =   0
      TextRTF         =   $"zMain.frx":014A
      BeginProperty Font {0BE35203-8F91-11CE-9DE3-00AA004BB851} 
         Name            =   "Arial"
         Size            =   14.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
   End
End
Attribute VB_Name = "zMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private batteryTimer As Double
Private pingTimer As Double
Private dataReceivedTimer As Double

Private Sub hexStringToBinary(s As String, ByRef a() As Byte)
  Dim i As Integer
  Dim c As Integer: c = 0
  For i = 1 To Len(s) Step 3
    a(c) = Val("&H" & Mid$(s, i, 2))
    c = c + 1
    If c = 10 Then Exit Sub
  Next
End Sub

Private Sub parseCommand(c As String)

  If Left$(c, 4) = "SPI " Then
        
    dataReceivedTimer = TimerD
    
    Dim p(10) As Byte
    hexStringToBinary Mid$(c, 5), p
    'MsgBox p(0)
    'msg "****" & c

    adisplayDataReset

    If p(3) = &HDC Then adisplay_t1 = "LO"
    If p(3) = &HEF Then adisplay_t1 = 19
    If p(3) = &H86 Then adisplay_t1 = 21
    If p(3) = &H9B Then adisplay_t1 = 22
    If p(3) = &H8F Then adisplay_t1 = 23
    If p(3) = &HE6 Then adisplay_t1 = 24
    If p(3) = &HAD Then adisplay_t1 = 25
    If p(3) = &HFD Then adisplay_t1 = IIf(p(5) And &H4, 26, 16)
    If p(3) = &HC7 Then adisplay_t1 = IIf(p(5) And &H4, 27, 17)
    If p(3) = &HBF Then adisplay_t1 = IIf(p(5) And &H4, IIf(p(5) And &H8, 28, 20), 18)
    If p(3) = &HD0 Then adisplay_t1 = "HI"

    If p(1) = &H1C Then adisplay_t2 = "LO"
    If p(1) = &H2F Then adisplay_t2 = 19
    If p(1) = &H46 Then adisplay_t2 = 21
    If p(1) = &H5B Then adisplay_t2 = 22
    If p(1) = &H4F Then adisplay_t2 = 23
    If p(1) = &H26 Then adisplay_t2 = 24
    If p(1) = &H6D Then adisplay_t2 = 25
    If p(1) = &H3D Then adisplay_t2 = IIf(p(5) And &H10, 26, 16)
    If p(1) = &H7 Then adisplay_t2 = IIf(p(5) And &H10, 27, 17)
    If p(1) = &H7F Then adisplay_t2 = IIf(p(5) And &H10, IIf(p(5) And &H20, 28, 20), 18)
    If p(1) = &H10 Then adisplay_t2 = "HI"

    If (p(6) And &HF0) = &HE0 Then adisplay_manual = 1
    If (p(6) And &HF0) = &HD0 Then adisplay_manual = 2
    If (p(6) And &HF0) = &HB0 Then adisplay_manual = 3
    If (p(6) And &HF0) = &HC0 Then adisplay_manual = 4
    If (p(6) And &HF0) = &HA0 Then adisplay_manual = 5
    If (p(6) And &HF0) = &H90 Then adisplay_manual = 6
    If (p(6) And &HF0) = &HF0 Then adisplay_manual = 7
    
    If (p(6) And &HF) = &H0 Then adisplay_ac = "auto"
    If (p(6) And &HF) = &H5 Then adisplay_ac = "on"
    If (p(6) And &HF) = &H6 Then adisplay_ac = "off"
    
    If p(7) = &HF8 Then adisplay_mode = "feet_defrost"
    If p(7) = &HB0 Then adisplay_mode = "feet"
    If p(7) = &HF4 Then adisplay_mode = "feet_front"
    If p(7) = &HA4 Then adisplay_mode = "front"

    clima.doRedraw

  End If
  
End Sub

Private Sub Form_Load()

  batteryTimer = 0

  tmr.Enabled = False

  If Command$ <> "" Then
    comSelected = Command$
  Else
    comSelect.Show vbModal
    If comSelected = "" Then End
  End If

  aiInit
  
  Set serial = New cSerial
  serial.Port = "\\.\" & comSelected 'COM14
  serial.Bauds = 115200 ' 9600 38400 115200
  serial.PortClose
  serial.PortOpen

  'If Not serial.IsPortOpen Then
  '  MsgBox "No se puede conectar a " & comSelected
  '  End
  'End If

  'msgl vbCrLf
  msg "CCCCCCStarted"

  'Clipboard.Clear
  'Clipboard.SetText lst.List(lst.ListIndex), vbCFText

  If Not InIDE Then Me.Visible = False

  Load clima
  clima.Show

  tmr.Enabled = True

End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)
 
  On Error Resume Next
  serial.PortClose
  On Error GoTo 0
  
  Unload clima
  
  End

End Sub

Private Sub Form_Resize()
  On Error Resume Next
  scr.Move 0, 0, Me.ScaleWidth, Me.ScaleHeight
End Sub

Private Sub tmr_Timer()

  Dim i As Integer
  Dim s As String
  
  adisplay_connected = serial.IsPortOpen
  If serial.IsPortOpen Then

    Do
      s = serial.Receive
      If s <> "" Then dataReceive s
    Loop While s <> ""

    For i = 1 To UBound(aiCommands)
      msg "CCCCCC" & aiCommands(i)
      parseCommand aiCommands(i)
    Next
    ReDim aiCommands(0)

    If serial.IsErrors Then
      msg "FF8080DESCONECTADO: CCCCCC" & serial.LastError
      serial.PortClose
    End If

    If pingTimer = 0 Or TimerD - pingTimer >= 3 Then
      pingTimer = TimerD
      msg "PING!"
      serial.Send "p" ' PING!
    End If

    If dataReceivedTimer > 0 And TimerD - dataReceivedTimer > 1 Then
      dataReceivedTimer = 0
      adisplayDataReset
      clima.doRedraw
      msg "*** No data"
    End If

  Else
    
    adisplayDataReset
    clima.doRedraw

    serial.PortReconnect
    If serial.IsPortOpen Then msg "80FF80CONECTADO A " & serial.Port

  End If

  If isOnBattery() Then

    ' contador de tiempo en modo batería
    If batteryTimer = 0 Then
      batteryTimer = TimerD
    Else
      ' si ha pasado 1 minuto en batería y más de 1 minuto en idle, o está en menos del 15%, hibernar
      'If (TimerD - batteryTimer > 6 And getIdleTicks() > (5 * 1000&)) Or getBatteryPercent() < 15 Then
      If (TimerD - batteryTimer > 60 And getIdleTicks() > (1 * 60 * 1000&)) Or getBatteryPercent() < 15 Then
        batteryTimer = 0
        If InIDE Then
          msg "*** Evento de Hibernacion"
        Else
          'MsgBox "voy a hibernar! " & getIdleTicks()
          Shell "rundll32.exe powrprof.dll,SetSuspendState Standby", vbHide
        End If
      End If
    End If
  
  Else
    
    batteryTimer = 0
  
  End If

End Sub
