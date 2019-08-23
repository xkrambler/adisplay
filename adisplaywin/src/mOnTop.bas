Attribute VB_Name = "mOnTop"
Private Declare Function SetWindowPos Lib "user32" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal X As Long, Y, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Const HWND_TOPMOST = -1
Const HWND_NOTOPMOST = -2
Const SWP_NOMOVE = &H2
Const SWP_NOSIZE = &H1
Const SWP_NOACTIVATE = &H10
Const SWP_SHOWWINDOW = &H40
Const TOPMOST_FLAGS = SWP_NOMOVE Or SWP_NOSIZE

Public Sub OnTop(hwndEx As Long, T As Boolean)
Select Case T: Case True: SetWindowPos hwndEx, HWND_TOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS
Case False: SetWindowPos hwndEx, HWND_NOTOPMOST, 0, 0, 0, 0, TOPMOST_FLAGS: End Select
End Sub
