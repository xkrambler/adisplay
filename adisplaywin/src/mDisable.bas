Attribute VB_Name = "mDisable"
'Disable: Disable/Modify/Enter diferent parameters in Windows
'============================================================
Public Declare Function ClipCursor Lib "user32" (lpRect As Any) As Long
Public Declare Function ExitWindowsEx Lib "user32" (ByVal dwOptions As Long, ByVal dwReserved As Long) As Long
Public Declare Function FindWindow Lib "user32" Alias "FindWindowA" (ByVal lpClassName As String, ByVal lpWindowName As String) As Long
Public Declare Function FindWindowEx Lib "user32" Alias "FindWindowExA" (ByVal hWnd1 As Long, ByVal hWnd2 As Long, ByVal lpsz1 As String, ByVal lpsz2 As String) As Long
Public Declare Function GetWindowRect Lib "user32" (ByVal hwnd As Long, lpRect As RECT) As Long
Public Declare Function GetDesktopWindow Lib "user32" () As Long
Public Declare Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Public Declare Function SetWindowPos Lib "user32" (ByVal hwnd As Long, ByVal hwndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Public Declare Function ShowCursor& Lib "user32" (ByVal bShow As Long)
Public Declare Function ShowWindow Lib "user32" (ByVal hwnd As Long, ByVal nCmdShow As Long) As Long
Public Declare Function SystemParametersInfo Lib "user32" Alias "SystemParametersInfoA" (ByVal uAction As Long, ByVal uParam As Long, lpvParam As Any, ByVal fuWinIni As Long) As Long
Public Declare Function GetWindowText Lib "user32" Alias "GetWindowTextA" (ByVal hwnd As Long, ByVal lpString As String, ByVal cch As Long) As Long
Public Declare Sub keybd_event Lib "user32" (ByVal bVk As Byte, ByVal bScan As Byte, ByVal dwFlags As Long, ByVal dwExtraInfo As Long)
Public Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type
Public Sub TaskBar(enabled As Boolean)
Dim lBool As Long: SystemParametersInfo 97, Not enabled, lBool, vbNull
End Sub
Public Sub Halt(Forced As Boolean)
If Forced = True Then xf% = 4 Else xf% = 0
ExitWindowsEx (1 + xf%), 0
End Sub
Public Sub Reboot(Forced As Boolean)
If Forced = True Then xf% = 4 Else xf% = 0
ExitWindowsEx (2 + xf%), 0
End Sub
Public Sub Logoff(Forced As Boolean)
If Forced = True Then xf% = 4 Else xf% = 0
ExitWindowsEx (0 + xf%), 0
End Sub
Public Sub Mouse(enabled As Boolean)
Dim x As RECT
Select Case enabled
Case True: GetWindowRect GetDesktopWindow, x
Case False: x.Left = 0: x.Top = 0: x.Right = 0: x.Bottom = 0
End Select
Call ClipCursor(x)
End Sub
Public Sub MouseCursor(enabled As Boolean)
1 x = ShowCursor(enabled)
If enabled = True And x < 0 Then GoTo 1
If enabled = False And x >= 0 Then GoTo 1
End Sub
Public Sub StartButton(enabled As Boolean)
OurParent& = FindWindow("Shell_TrayWnd", "")
OurHandle& = FindWindowEx(OurParent&, 0, "Button", vbNullString)
If enabled = True Then s% = 5 Else s% = 0
ShowWindow OurHandle&, s%
End Sub
Public Sub RunScreenSaver()
'Call SendMessage(Main.hwnd, &H112&, &HF140&, 0&)
End Sub
Public Sub RunStart()
'Call SendMessage(Main.hwnd, &H112&, &HF130, 0)
End Sub
Public Sub RunSuspend(Forced As Boolean)
'Select Case Forced: Case False: Call SendMessage(Main.hwnd, &H112&, &HF140&, 1)
'Case True: Call keybd_event(&H5B, 0, 0, 0): Call keybd_event(&H5E, 0, 0, 0)
'Call keybd_event(&H5B, 0, &H2, 0): End Select
End Sub
Public Sub ShellAction(ActionToDo As Integer)
Select Case ActionToDo
Case 0: f% = 77 'Minimizar Todo!
Case 1: f% = 82 'Ejecutar (Menú Inicio)
Case 2: f% = 68 'Quita la barra de inicio y miniminiza todo (?)
Case 3: f% = 69 'Explorer
Case 4: f% = 70 'Buscar
Case Else: Beep: Exit Sub
End Select
Call keybd_event(&H5B, 0, 0, 0)
Call keybd_event(f%, 0, 0, 0)
Call keybd_event(&H5B, 0, &H2, 0)
End Sub
Public Sub WindowsTaskBar(enabled As Boolean)
Dim rtn As Long: rtn = FindWindow("Shell_traywnd", "")
Select Case enabled
Case True: Call SetWindowPos(rtn, 0, 0, 0, 0, 0, &H40)
Case False: Call SetWindowPos(rtn, 0, 0, 0, 0, 0, &H80)
End Select
End Sub
Public Sub Desktop(enabled As Boolean)
OurParent& = FindWindow("Progman", "Program Manager")
OurParent2& = FindWindowEx(OurParent&, 0, "SHELLDLL_DefView", vbNullString)
OurHandle& = FindWindowEx(OurParent2&, 0, "SysListView32", vbNullString)
If enabled = True Then s% = 5 Else s% = 0
ShowWindow OurHandle&, s%
End Sub
Public Sub TrayNotify(enabled As Boolean)
OurParent& = FindWindow("Shell_traywnd", "")
OurHandle& = FindWindowEx(OurParent&, 0, "TrayNotifyWnd", vbNullString)
If enabled = True Then s% = 5 Else s% = 0
ShowWindow OurHandle&, s%
End Sub
Public Sub WinTaskBar(enabled As Boolean)
OurParent& = FindWindow("Shell_traywnd", "")
OurHandle& = FindWindowEx(OurParent&, 0, "ReBarWindow32", vbNullString)
If enabled = True Then s% = 5 Else s% = 0
ShowWindow OurHandle&, s%
End Sub

