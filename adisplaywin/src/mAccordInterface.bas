Attribute VB_Name = "mAccordInterface"
Option Explicit

Public adisplay_connected As Boolean
Public adisplay_t1 As String
Public adisplay_t2 As String
Public adisplay_manual As String
Public adisplay_ac As String
Public adisplay_mode As String

Public aiCommands() As String
Public Buffer As String

Public Sub aiInit()
  ReDim aiCommands(0)
End Sub

Public Sub adisplayDataReset()

  adisplay_t1 = ""
  adisplay_t2 = ""
  adisplay_manual = ""
  adisplay_ac = ""
  adisplay_mode = ""

End Sub

Public Sub dataReceive(d As String)

  Dim cmd As String
  Dim i As Integer
  Dim p As Integer

  Buffer = Buffer & d
  p = InStr(1, Buffer, vbLf)
  If p > 0 Then
    cmd = Left$(Buffer, p - 1)
    Buffer = Mid$(Buffer, p + 1)
    i = UBound(aiCommands) + 1
    ReDim Preserve aiCommands(i)
    aiCommands(i) = cmd
  End If

End Sub

Public Function bcd2number(s As String) As Long

  Dim i As Integer
  Dim R As String
  R = ""
  For i = 1 To Len(s)
    R = R & strHex(Asc(Mid$(s, i, 1)))
  Next
  For i = 1 To Len(R)
    If Mid$(R, i, 1) = "F" Then Mid$(R, i) = " "
  Next
  
  On Error Resume Next
  bcd2number = 0
  bcd2number = Val(R)

End Function

Public Function strHex(v As Integer) As String
  strHex = IIf(v < 16, "0", "") & Hex$(v)
End Function

Public Function strData(Data As String) As String
  Dim i As Integer
  Dim v As Integer
  Dim s As String
  For i = 1 To Len(Data)
    v = Asc(Mid$(Data, i, 1))
    s = s & IIf(v < 33 Or v > 127, "(" & strHex(v) & ")", Chr$(v))
  Next
  strData = s
End Function

