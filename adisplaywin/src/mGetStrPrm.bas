Attribute VB_Name = "mGetStrPrm"
Public Function prm$(t$, n$)
XA& = 1: NP% = 0: Do: NP% = NP% + 1: X& = InStr(XA&, t$, " ")
If X& = 0 Then X& = Len(t$) + 1
NPS$ = LTrim$(Str$(NP%)): Select Case Mid$(t$, XA&, 1)
Case Chr$(34): X2& = InStr(XA& + 1, t$, Chr$(34))
If X2& = 0 Then X2& = Len(t$) + 1: NDE% = 1
TM& = X2& - X& + 1: If Right$(n$, 1) <> "-" Then p$ = Mid$(t$, XA& + 1, X2& - XA& - 1) Else p$ = Mid$(t$, XA&)
If Mid$(t$, X2& + 1, 1) = " " Then TM& = TM& + 1
Case Else: TM& = 1: If Right$(n$, 1) <> "-" Then p$ = Mid$(t$, XA&, X& - XA&) Else p$ = Mid$(t$, XA&)
End Select: If NPS$ = n$ Or NPS$ + "-" = n$ Then prm$ = p$: Exit Function
XA& = X& + TM&: If X& = Len(t$) + 1 Or NDE% = 1 Then prm$ = "": Exit Function
Loop
End Function
