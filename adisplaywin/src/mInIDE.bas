Attribute VB_Name = "mInIDE"
'Módulo de Detección en IDE

Public Function InIDE() As Boolean
Static bRun As Boolean, bIDE As Boolean
If Not bRun Then
bRun = True: On Error Resume Next
Err.Clear: Debug.Print 1 / 0
bIDE = CBool(Err): Err.Clear
On Error GoTo 0
End If
InIDE = bIDE
If notInIDE Then InIDE = False
End Function
