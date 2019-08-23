Attribute VB_Name = "mPacket"
Option Explicit

Private Const BS_INITIAL = 0
Private Const BS_START = 1
Private Const BS_LENGHT = 2
Private Const BS_DATA = 3
Private Const BS_PREEND = 4
Private Const BS_END = 5
Private Const BS_LRC = 6

Public bufferState As Integer
Public buffer As String
Public Type packetType
  lenght As Long
  data As String
  ok As Boolean
End Type
Public packets() As packetType

Public Function packetInit()
  packetClear
End Function

Public Function packetClear()
  ReDim packets(0)
End Function

Public Function packetNum() As Long
  packetNum = UBound(packets)
End Function

Public Function bcd2number(s As String) As Long

  Dim i As Integer
  Dim r As String
  r = ""
  For i = 1 To Len(s)
    r = r & strHex(Asc(Mid$(s, i, 1)))
  Next
  For i = 1 To Len(r)
    If Mid$(r, i, 1) = "F" Then Mid$(r, i) = " "
  Next
  
  On Error Resume Next
  bcd2number = 0
  bcd2number = Val(r)

End Function

Public Function strHex(v As Integer) As String
  strHex = IIf(v < 16, "0", "") & Hex$(v)
End Function

Public Function strData(data As String) As String
  Dim i As Integer
  Dim v As Integer
  Dim s As String
  For i = 1 To Len(data)
    v = Asc(Mid$(data, i, 1))
    s = s & IIf(v < 33 Or v > 127, "(" & strHex(v) & ")", Chr$(v))
  Next
  strData = s
End Function

Public Function dataLRC(data As String) As Integer
  Dim i As Integer
  Dim v As Integer
  Dim r As Integer
  r = 0
  For i = 1 To Len(data)
    r = r Xor Asc(Mid$(data, i, 1))
  Next
  dataLRC = r
End Function

Public Sub dataReceive(d As String)

  Dim p As packetType
  
  Dim i As Integer
  Dim c As String
  Dim v As Integer
  Dim lenght As Integer
  Dim errors As Long

  buffer = buffer & d
  
  Dim f As Long: f = FreeFile
  Open App.EXEName & ".binlog" For Append As #f
  Print #f, d;
  Close #f
  
  bufferState = BS_INITIAL
  errors = 0
  i = 0
  Do
    i = i + 1
    If i >= Len(buffer) Then Exit Do
    c = Mid$(buffer, i, 1)
    v = Asc(c)
    'MsgBox "bufferState=" & bufferState & " I=" & i & " C=" & v
    Select Case bufferState
    Case BS_INITIAL
      If v = 16 Then
        bufferState = BS_START
      Else
        errors = errors + 1
        ' borrar buffer hasta el puntero actual
        buffer = Mid$(buffer, i + 1): i = 0
      End If
      
    Case BS_START
      bufferState = IIf(v = 2, BS_LENGHT, BS_INITIAL)
      p.data = ""
      
    Case BS_LENGHT
      p.data = p.data & c
      p.lenght = v
      lenght = v
      bufferState = BS_DATA
      If v = 16 Then i = i + 1 ' saltar siguiente
      
    Case BS_DATA
      p.data = p.data & c
      lenght = lenght - 1
      If v = 16 Then i = i + 1 ' saltar siguiente
      If lenght <= 0 Then bufferState = BS_PREEND
      
    Case BS_PREEND
      bufferState = IIf(v = 16, BS_END, BS_INITIAL)
      
    Case BS_END
      bufferState = IIf(v = 3, BS_LRC, BS_INITIAL)
      
    Case BS_LRC
      'MsgBox "errors=" & errors & " packet=" & strData(p.data) & " LRC:" & v & "=" & dataLRC(p.data & Chr$(16) & Chr$(3))
      ' verificar
      p.ok = IIf(v = dataLRC(p.data & Chr$(16) & Chr$(3)), True, False)
      ' añadir paquete a la cola de proceso
      Dim NP As Long: NP = UBound(packets) + 1
      ReDim Preserve packets(NP)
      packets(NP) = p
      ' borrar buffer hasta el puntero actual
      buffer = Mid$(buffer, i + 1): i = 0
      ' volver al estado inicial
      bufferState = BS_INITIAL
      
    End Select
  Loop

End Sub
