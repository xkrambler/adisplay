Attribute VB_Name = "mMain"
Public Declare Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)

Public serial As cSerial
Public comSelected As String
Public isConnected As Boolean
Public pingTimer As Double

Public Const mxConBuffer = 524288

Public Function sizeText(xSize As Currency)
  If xSize > 1099511627776@ Then sizeText = (CLng(xSize / 10485.76) / 100) & "TB": Exit Function
  If xSize > 1073741824 Then sizeText = (CLng(xSize / 10485.76) / 100) & "GB": Exit Function
  If xSize > 1048576 Then sizeText = (CLng(xSize / 10485.76) / 100) & "MB": Exit Function
  If xSize > 1024 Then sizeText = (CLng(xSize / 10.24) / 100) & "KB": Exit Function
  sizeText = xSize
End Function

Public Sub msg(xText As String)
  If InIDE Then
    Dim xAddCRLF As String
    Dim t As Double: t = Timer: t = CLng((t - Fix(t)) * 100)
    If zMain.scr.Text <> "" Then xAddCRLF = vbCrLf
    msgn xAddCRLF & "808080[A0A0FF" & Time$ & "." & t & "808080] " & xText
  End If
End Sub

Public Sub msgn(xText As String)
  Dim xAddCRLF As String
  Dim lastColor As Long
  With zMain.scr
    .SelStart = Len(.Text)
    .SelColor = scrDefaultColor
    .SelText = xAddCRLF
    msgl xAddCRLF
    '
    XA& = 1: Do
    X& = InStr(XA&, xText, Chr$(3))
    If X& = 0 Then
      TT$ = Mid$(xText, XA&)
      .SelText = TT$: msgl TT$
      If Len(.Text) > mxConBuffer Then
        .SelStart = 0
        .SelLength = Len(.Text) - mxConBuffer / 2
        .SelText = ""
        .SelStart = Len(.Text)
        msgn vbCrLf & "FF8080Buffer of FFFFFF" & sizeText(mxConBuffer) & "8080FF exceded ->FF8080 Croping into FFFFFF" & sizeText(mxConBuffer / 2) & ""
      Else
        .SelStart = Len(.Text)
      End If
      Exit Do
    End If
    c$ = Mid$(xText, X& + 1, 6)
    TT$ = Mid$(xText, XA&, X& - XA&)
    .SelText = TT$: msgl TT$
    If Left$(c$, 1) = Chr$(3) Then
      If Mid$(c$, 2, 1) = Chr$(3) Then
        .SelColor = lastColor: j% = 3
      Else
        .SelColor = scrDefaultColor: j% = 2
      End If
    Else
      lastColor = Val("&H" & UCase$(Mid$(c$, 5, 2) & Mid$(c$, 3, 2) & Mid$(c$, 1, 2)))
      .SelColor = lastColor: j% = 7
    End If
    XA& = X& + j%
    Loop
  End With
End Sub

Public Sub msgl(xTextData As String)
  'On Error Resume Next
  'FF& = FreeFile
  'Open App.Path & "\" & App.EXEName & ".log" For Append As #FF&
  'Print #FF&, xTextData;
  'Close #FF&
End Sub
