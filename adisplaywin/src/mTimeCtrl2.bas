Attribute VB_Name = "mTimeCtrl"
'Módulo de Control de Tiempo para Visual CyberGest 6P
'(c)03/2002. Demiurgo Networks Corporation,,Inc.
Public LastTimerN As Long
Public TimerNdif As Long
Public DetectedTimeFail As Boolean
Public Function DateSP() As String
DateSP = Mid$(Date$, 4, 2) + "/" + Left$(Date$, 2) + "/" + Right$(Date$, 4)
End Function
Public Sub RS(TM As Single)
Dim T As Single: T = Timer: Do: DoEvents: Loop While Not Timer - T >= TM
End Sub
Public Function TimeF(TimePS As Long) As String
Dim AA As Long: Dim AB As String
Dim BA As Long: Dim BB As String
Dim CA As Long: Dim CB As String
AA = Fix(TimePS / 3600): AB = LTrim$(Str$(AA))
BA = Fix(TimePS / 60) Mod 60: BB = LTrim$(Str$(BA))
CA = TimePS Mod 60: CB = LTrim$(Str$(CA))
On Error GoTo NOTIMESHOW
TimeF = String$(2 - Len(AB), "0") + AB + ":" + String$(2 - Len(BB), "0") + BB + ":" + String$(2 - Len(CB), "0") + CB
Exit Function
NOTIMESHOW: Resume NOTIMESHOWB
NOTIMESHOWB: TimeF = "??:??:??"
End Function
Public Function TimerN() As Long
Dim RM%(12): E$ = Date$: TM$ = Time$
RM%(1) = 31: RM%(2) = 28: RM%(3) = 31: RM%(4) = 30
RM%(5) = 31: RM%(6) = 30: RM%(7) = 31: RM%(8) = 31
RM%(9) = 30: RM%(10) = 31: RM%(11) = 30: RM%(12) = 31
TimerND% = Val(Mid$(E$, 4, 2)): TimerNM% = Val(Mid$(E$, 1, 2))
TimerNA% = Val(Mid$(E$, 7, 4)): TimerNH# = Val(Mid$(TM$, 1, 2))
TimerNN# = Val(Mid$(TM$, 4, 2)): TimerNS# = Val(Mid$(TM$, 7, 2))
DA& = (TimerNA% - 1980): DB% = Fix((DA& + 3) / 4): TimerNTA& = (365 * DA&) + DB%
For B% = 1 To TimerNM% - 1: S% = S% + RM%(B%): Next
If TimerNA% Mod 4 = 0 And M% > 2 Then B% = 1 Else B% = 0
DDz& = (TimerNTA& + S% + TimerND% + B%)
timerNR = ((DDz& * 86400) + (TimerNH# * 3600) + (TimerNN# * 60) + TimerNS#)
DIF& = LastTimerN - timerNR
If LastTimerN <> 0 Then
If Abs(DIF&) >= 10 Then
DetectedTimeFail = True
TimerNdif = TimerNdif + DIF&
End If
End If
LastTimerN = timerNR
TimerN = timerNR + TimerNdif
End Function
Public Function TimerD() As Double
ttmr = Timer: TimerD = TimerN + (ttmr - Fix(ttmr))
End Function
Public Function DateN(TimerND%, TimerNM%, TimerNA%) As Long
Dim RM%(12): E$ = Date$: TM$ = Time$
RM%(1) = 31: RM%(2) = 28: RM%(3) = 31: RM%(4) = 30
RM%(5) = 31: RM%(6) = 30: RM%(7) = 31: RM%(8) = 31
RM%(9) = 30: RM%(10) = 31: RM%(11) = 30: RM%(12) = 31
DA& = (TimerNA% - 1980): DB% = Fix((DA& + 3) / 4): TimerNTA& = (365 * DA&) + DB%
For B% = 1 To TimerNM% - 1: S% = S% + RM%(B%): Next
If TimerNA% Mod 4 = 0 And M% > 2 Then B% = 1 Else B% = 0
DateN = (TimerNTA& + S% + TimerND% + B%)
End Function
Public Function DateDMY(TP%, T2$) As Integer: T$ = T2$ & "/"
On Error GoTo 1
For A% = 1 To 3: x% = InStr(1, T$, "/")
If x% = 0 Then x% = InStr(1, T$, "-")
If x% = 0 Then Exit Function
If TP% = (A% - 1) Then DateDMY = Left$(T$, x% - 1): Exit Function
T$ = Mid$(T$, x% + 1): Next
Exit Function
1 Resume 2
2 MsgBox imFuckingWithTheReg & "> -- [" & T$ & "] --- [" & T2$ & "] ----- " & x% - 1
End Function
Public Function TimeHMS(TP%, T2$) As Integer: T$ = T2$ & ":"
For A% = 1 To 3: x% = InStr(1, T$, ":"): If x% = 0 Then Exit Function
If TP% = (A% - 1) Then TimeHMS = Left$(T$, x% - 1): Exit Function
T$ = Mid$(T$, x% + 1): Next
End Function
Public Function TimeN(TH%, TM%, TS%) As Long
TimeN = (TH% * 3600&) + (TM% * 60&) + TS%
End Function
