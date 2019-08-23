VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cSerial"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private isOpen As Boolean
Public idHandle As Integer
Private portName As String
Private portBauds As Long
Private portParity As String
Private portBits As Integer
Private portStop As Integer
Private dataBuffer As String

Private Sub Class_Initialize()

  Dim i As Integer

  idHandle = 0
  portBauds = 9600
  portParity = "N"
  portBits = 8
  portStop = 1
  
  For i = 1 To UBound(udtPorts)
    If udtPorts(i).lngHandle = 0 Then
      idHandle = i
      Exit Sub
    End If
  Next
  
End Sub

Public Property Get Port() As String
  Port = portName
End Property

Public Property Let Port(ByVal vNewValue As String)
  portName = vNewValue
End Property

Public Property Get Bauds() As Long
  Bauds = portBauds
End Property

Public Property Let Bauds(ByVal vNewValue As Long)
  portBauds = vNewValue
End Property

Public Function PortOpen() As Boolean
  Dim lngStatus As Long
  lngStatus = CommOpen(idHandle, portName, "baud=" & portBauds & " parity=" & portParity & " data=" & portBits & " stop=" & portStop)
  isOpen = IIf(lngStatus = 0, True, False)
  PortOpen = isOpen
End Function

Public Sub PortClose()
  Call CommClose(idHandle)
  isOpen = False
End Sub

Public Function PortReconnect() As Boolean
  PortClose
  PortReconnect = PortOpen()
End Function

Public Function Send(data As String) As Boolean
  Send = IIf(CommWrite(idHandle, data) = Len(data), True, False)
End Function

Public Function Receive(Optional Length As Long = -1, Optional timeout As Long = 0) As String
  Dim strData As String
  Dim lngStatus As Long
  Dim timeoutCount As Integer
  timeoutCount = 0
  Do
    lngStatus = CommRead(idHandle, strData, Length)
    If lngStatus <> -1 Then
      dataBuffer = dataBuffer & Left$(strData, lngStatus)
    End If
    If Length = -1 Then
      Receive = dataBuffer
      dataBuffer = ""
      Exit Function
    End If
    If Len(dataBuffer) >= Length Then
      Receive = IIf(Length > 0, Left$(dataBuffer, Length), "")
      dataBuffer = Mid$(dataBuffer, Length + 1)
      Exit Function
    End If
    If timeoutCount >= timeout Or lngStatus = -1 Then Exit Do
    Sleep 1
    timeoutCount = timeoutCount + 1
  Loop
  Receive = ""
End Function

Public Function IsErrors() As Boolean
  IsErrors = IIf(LastErrNum() > 0, True, False)
End Function

Public Function LastErrNum() As Long
  Dim strError As String
  LastErrNum = CommGetError(strError)
End Function

Public Function LastError() As String
  Dim strError As String
  LastError = IIf(CommGetError(strError) > 0, strError, "")
End Function

Public Function IsPortOpen() As Boolean
  IsPortOpen = isOpen
End Function
