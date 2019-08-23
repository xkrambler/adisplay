Attribute VB_Name = "mDock"
Option Explicit

Public Const EXPOSURE = 4         'Pixels exposed on an Autohide appbar.
Public Const DOCKINGMARGIN = 400  'Margin around screen edges.
Public Const DISPLAY_TITLE = "Appbar Example"

' Screen attributes.
Public glScreenHeight       As Long    'Height in pixels.
Public glScreenWidth        As Long    'Width in pixels.
Public glTwipsPerPixelX     As Long    'Twips per horizontal pixel.
Public glTwipsPerPixelY     As Long    'Twips per vertical pixel.

' Appbar attributes.
Public glFormTop            As Long    'Floating form's top.
Public glFormLeft           As Long    'Floating form's Left edge.
Public glFormHeight         As Long    'Floating form's height.
Public glFormWidth          As Long    'Floating form's width.
Public glAppBarHandle       As Long    'Fixed appbar's handle.
Public glHeight             As Long    'Fixed applbar's height.
Public glWidth              As Long    'Fixed appbar's width.
Public glAppBarTop          As Long    'Fixed appbar's top.
Public glAppBarLeft         As Long    'Fixed appbar's left edge.
Public glAppBarRight        As Long    'Fixed appbar's right edge.
Public glAppBarBottom       As Long    'Fixed appbar's bottom edge.

' Misc.
Public gbAutoHide           As Boolean 'AutoHide appbar indicator.
Public gbEnd                As Boolean 'End application indicator.
Public gbSwapForms          As Boolean 'Swap fixed/float appbar indicator.
'
' AppBar location constants.
'
Public Enum AppbarLocations
    abDockedTop = 1
    abDockedBottom = 2
    abDockedLeft = 3
    abDockedRight = 4
    abFloating = 5
End Enum
Public abPosition    As AppbarLocations
Public abOldPosition As AppbarLocations
'
'----------------------------------------------------------------------
'
' Win32 API values.
'
'----------------------------------------------------------------------
'
' Values used by various Win32 API calls.
'
Public Const ABE_LEFT = 0
Public Const ABE_TOP = 1
Public Const ABE_RIGHT = 2
Public Const ABE_BOTTOM = 3
'
' These constants are used with the SHAppBarMessage and
' refer to the APPBARDATA structure defined below.
'
' Returns the handle of the autohide appbar associated
' with an edge of the screen. The return value is NULL
' if an error occurs or if no autohide appbar is
' associated with the given edge. You must specify the
' cbSize, hWnd, and uEdge members when sending this message,
' all other members are ignored.
'
Public Const ABM_GETAUTOHIDEBAR = &H7
'
' Registers a new appbar and specifies the message identifier
' that the system should use to send notification messages to
' the appbar. An appbar should send this message before sending
' any other appbar messages. Returns TRUE if successful or FALSE
' if an error occurs or the appbar is already registered. You
' must specify the cbSize, hWnd, and uCallbackMessage members
' when sending this message, all other members are ignored.
'
Public Const ABM_NEW = &H0
'
' Unregisters an appbar, removing it from the system’s internal
' list. The system no longer sends notification messages to the
' appbar nor prevents other applications from using the screen
' area occupied by the appbar. This message causes the system to
' send the ABN_POSCHANGED notification message to all appbars.
' You must specify the cbSize and hWnd members when sending this
' message, all other members are ignored.
'
Public Const ABM_REMOVE = &H1
'
' Registers or unregisters an autohide appbar for an edge of the
' screen. The system allows only one autohide appbar for each edge
' on a first come, first served basis. Returns TRUE if successful
' or FALSE if an error occurs or an autohide appbar is already
' registered for the given edge. The lParam parameter is set to
' TRUE to register the appbar or FALSE to unregister it. You must
' specify the cbSize, hWnd, uEdge, and lParam members when sending
' this message, all other members are ignored.
'
Public Const ABM_SETAUTOHIDEBAR = &H8
'
' Sets the size and screen position of an appbar. The message specifies
' a screen edge to and the bounding rectangle for the appbar. The system
' may adjust the bounding rectangle so that the appbar does not interfere
' with the Windows taskbar or any other appbars. Always returns TRUE.
' This message causes the system to send the ABN_POSCHANGED notification
' message to all appbars. The uEdge member specifies a screen edge, and the
' rc member contains the bounding rectangle. When the SHAppBarMessage
' function returns, rc contains the approved bounding rectangle. You must
' specify the cbSize, hWnd, uEdge, and rc members when sending this message,
' all other members are ignored.
'
Public Const ABM_SETPOS = &H3

Public Const HWND_TOP = 0
Public Const HWND_TOPMOST = -1
Public Const SHOWNORMAL = 5
Public Const SM_CXSCREEN = 0
Public Const SM_CYSCREEN = 1
Public Const SWP_NOACTIVATE = &H10
Public Const SWP_NOSIZE = &H1
Public Const SWP_NOMOVE = &H2
Public Const SWP_SHOWWINDOW = &H40
Public Const WM_MOUSEMOVE = &H200
'
' Structure used by various Win32 API calls.
'
Type POINTAPI
    x As Long
    y As Long
End Type

Type RECT
    Left   As Long
    Top    As Long
    Right  As Long
    Bottom As Long
End Type

Type WINDOWPLACEMENT
    Length           As Long
    flags            As Long
    ShowCmd          As Long
    ptMinPosition    As POINTAPI
    ptMaxPosition    As POINTAPI
    rcNormalPosition As RECT
End Type

Type APPBARDATA
    cbSize           As Long
    hwnd             As Long
    uCallbackMessage As Long
    uEdge            As Long
    rc               As RECT
    lParam           As Long
End Type
'
' Variables used by various Win32 API calls.
'
Public CursorLoc  As POINTAPI
Public lpwndpl    As WINDOWPLACEMENT
Public BarData    As APPBARDATA
'
' Win32 API declares.
'
Declare Function GetCursorPos Lib "user32" (lpPoint As POINTAPI) As Long
Declare Function GetSystemMetrics Lib "user32" (ByVal nIndex As Long) As Long
Declare Function GetWindowPlacement Lib "user32" (ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long
Declare Function SHAppBarMessage Lib "Shell32.dll" (ByVal dwMessage As Long, pData As APPBARDATA) As Long
Declare Function SetWindowPlacement Lib "user32" (ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long
Declare Function SetWindowPos Lib "user32" (ByVal hwnd As Long, ByVal hwndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Declare Function SetRect Lib "user32" (lpRect As RECT, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long

Public Sub pSetAppBarLocation(ByVal sSource As String, ByVal lFormLeft As Long, ByVal lFormTop As Long)
Dim bWasDocked As Boolean
Dim bNowDocked As Boolean
'
' See where to position the appbar depending the cursor's
' present coordinates.
'
On Error GoTo pSetAppBarLocationError
Screen.MousePointer = vbHourglass
abOldPosition = abPosition

Dim frmFloat As Form

If lFormLeft <= DOCKINGMARGIN Then
    '
    ' The left edge of a docked top appbar extends beyond the
    ' left margin.  This prevents a docked top appbar from
    ' docking left when the timer triggers.
    '
    If sSource = "TIMER" And abOldPosition = abDockedTop Then
        abPosition = abOldPosition
    Else
        abPosition = abDockedLeft
    End If
ElseIf (lFormLeft + frmFloat.Width) >= (Screen.Width - DOCKINGMARGIN) Then
    abPosition = abDockedRight
ElseIf lFormTop <= DOCKINGMARGIN Then
    abPosition = abDockedTop
ElseIf (lFormTop + frmFloat.Height) >= (Screen.Height - DOCKINGMARGIN) Then
    abPosition = abDockedBottom
Else
    abPosition = abFloating
End If
'
' See if we must swap between floating and docked forms.
'
bWasDocked = (abOldPosition <> abFloating)
bNowDocked = (abPosition <> abFloating)
             
gbSwapForms = (bWasDocked And Not bNowDocked) Or _
              (bNowDocked And Not bWasDocked)
Screen.MousePointer = vbDefault
Exit Sub

pSetAppBarLocationError:
    Call pDisplayError("Error setting appbar position.")
End Sub


Public Sub pSetAppBarDimensions(ByVal bSettingsChanged As Boolean)
Dim lResult      As Long
Dim sError       As String
Dim bFail        As Boolean
Dim bSetPosition As Boolean

On Error GoTo pSetABDimensionsError
Screen.MousePointer = vbHourglass
'
'------------------------------------------------------------------------------------
'
' Floating form positioning.
'
'------------------------------------------------------------------------------------
'
Dim frmFloat As Form
Dim frmDock As Form
If abPosition = abFloating Then
    sError = "Error dimensioning floating form."
    bSetPosition = gbSwapForms
    If gbSwapForms Then
        '
        ' The docked appbar was moved.  Position the
        ' floating form where the docked one was moved to.
        '
        frmFloat.Top = frmDock.Top
        frmFloat.Left = frmDock.Left
        gbSwapForms = False
        Call pUnregisterAppBar(abPosition)
    End If
    
    frmDock.Hide
    With frmFloat
        .Show
        glFormTop = .Top
        glFormLeft = .Left
        .tmrFloat.enabled = True
    End With
    
    Screen.MousePointer = vbDefault
    Exit Sub
End If
'
'------------------------------------------------------------------------------------
'
' Docked appbar sizing and positioning.
'
'------------------------------------------------------------------------------------
'
' If a docked appbar's position changed or the AutoHide
' setting changed, unregister the appbar.
'
sError = "Error dimensioning docked appbar."
frmFloat.tmrFloat.enabled = False
frmDock.tmrHide.enabled = False
If (abPosition <> abOldPosition And _
    abOldPosition <> abFloating) Or _
    bSettingsChanged Then
   '
   ' When moving an appbar, unregister the old one.
   ' When changing autohide setting, unregister the current one.
   '
   If bSettingsChanged Then
       Call pUnregisterAppBar(abPosition)
   Else
       Call pUnregisterAppBar(abOldPosition)
   End If
End If
'
' Don't show the form until the end to prevent flicker.
'
frmFloat.Hide

If gbSwapForms Then
    frmFloat.tmrFloat.enabled = False
    gbSwapForms = False
End If

With frmDock
    glFormTop = .Top
    glFormLeft = .Left
End With
'
' Register a new appbar. Reserve the screen area.
'
lResult = SHAppBarMessage(ABM_NEW, BarData)
lResult = SetRect(BarData.rc, 0, 0, glScreenWidth, glScreenHeight)
bSetPosition = False

Select Case abPosition
    Case abDockedTop
        '
        ' Reserve a portion of the screen and set the desired appbar location.
        '
        With BarData
        .uEdge = ABE_TOP
        .rc.Top = 0
        .rc.Left = 0
        .rc.Right = glScreenWidth
        glHeight = (300 + 60) \ glTwipsPerPixelY
        'glHeight = (frmDock.tbrToolbar.ButtonHeight + 60) \ glTwipsPerPixelY
        
        If gbAutoHide Then
            '
            ' If we want an AutoHide appbar, see if one exists on
            ' this edge of the screen. Only one can exists at a time.
            '
            If SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData) = 0 Then
                '
                ' Register our appbar as AutoHide. If successful, request
                ' the desired position (ABM_SETPOS), retrieve its handle
                ' and move the form to that location.
                '
                .lParam = True
                If SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData) <> 0 Then
                    .rc.Bottom = .rc.Top + EXPOSURE
                    lResult = SHAppBarMessage(ABM_SETPOS, BarData)
                    .rc.Top = 0
                    lResult = SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData)
                    glAppBarHandle = lResult
                    lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top - glHeight, .rc.Right - .rc.Left, glHeight + EXPOSURE, SWP_NOACTIVATE)
                Else
                    bSetPosition = True
                End If
            Else
                '
                ' There already was an AutoHide appbar on this screen edge.
                '
                bSetPosition = True
                bFail = True
            End If
        Else
            '
            ' An AutoHide appbar already exists.
            '
            bSetPosition = True
        End If
        If bSetPosition Then
            '
            ' An autohide appbar exists on this edge.
            ' Use a non-autohide appbar instead.
            '
            gbAutoHide = False
            .rc.Bottom = glHeight
            lResult = SHAppBarMessage(ABM_SETPOS, BarData)
            lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, .rc.Right - .rc.Left, glHeight, SWP_NOACTIVATE)
        End If
        '
        ' Save the ACTUAL appbar coordinates and position the form.
        ' The ABM_SETPOS doesn't actually set the appbar position
        ' but requests the location specified by the rc structure.
        ' The .rc values are set to actual coordinates assigned to
        ' the appbar which may differ from the requested ones.
        '
        glAppBarTop = .rc.Top
        glAppBarLeft = .rc.Left
        glAppBarRight = .rc.Right
        glAppBarBottom = .rc.Top + .rc.Bottom
        frmDock.tbrToolbar.Align = vbAlignTop
        frmDock.tbrToolbar.Height = glHeight
        End With
    
    Case abDockedBottom
        With BarData
        .uEdge = ABE_BOTTOM
        .rc.Left = 0
        .rc.Right = glScreenWidth
        .rc.Bottom = glScreenHeight
        glHeight = (300 + 60) \ glTwipsPerPixelY
        'glHeight = (frmDock.tbrToolbar.ButtonHeight + 60) \ glTwipsPerPixelY

        If gbAutoHide Then
            If SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData) = 0 Then
                .lParam = True
                If SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData) <> 0 Then
                    .rc.Top = .rc.Bottom - EXPOSURE
                    lResult = SHAppBarMessage(ABM_SETPOS, BarData)
                    .rc.Bottom = glScreenHeight
                    lResult = SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData)
                    glAppBarHandle = lResult
                    lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, .rc.Right - .rc.Left, glHeight + EXPOSURE, SWP_NOACTIVATE)
                Else
                    bSetPosition = True
                End If
            Else
                bSetPosition = True
                bFail = True
            End If
        Else
            bSetPosition = True
        End If
        If bSetPosition Then
            gbAutoHide = False
            .rc.Top = .rc.Bottom - glHeight
            lResult = SHAppBarMessage(ABM_SETPOS, BarData)
            .rc.Top = .rc.Bottom - glHeight
            lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, .rc.Right - .rc.Left, glHeight, SWP_NOACTIVATE)
        End If
        glAppBarTop = .rc.Top
        glAppBarLeft = .rc.Left
        glAppBarRight = .rc.Right
        glAppBarBottom = glHeight
        frmDock.tbrToolbar.Align = vbAlignTop
        frmDock.tbrToolbar.Height = glHeight
        End With
    
    Case abDockedRight
        With BarData
        .uEdge = ABE_RIGHT
        .rc.Top = 0
        .rc.Right = glScreenWidth
        .rc.Bottom = glScreenHeight
        glWidth = (300 + 60) \ glTwipsPerPixelX
        'glWidth = (frmDock.tbrToolbar.ButtonWidth + 60) \ glTwipsPerPixelX

        If gbAutoHide Then
            If SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData) = 0 Then
                .lParam = True
                If SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData) <> 0 Then
                    .rc.Left = .rc.Right - EXPOSURE
                    lResult = SHAppBarMessage(ABM_SETPOS, BarData)
                    .rc.Right = glScreenWidth
                    lResult = SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData)
                    glAppBarHandle = lResult
                    lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, glWidth + EXPOSURE, .rc.Bottom - .rc.Top, SWP_NOACTIVATE)
                Else
                    bSetPosition = True
                End If
            Else
                bSetPosition = True
                bFail = True
            End If
        Else
            bSetPosition = True
        End If
        If bSetPosition Then
            gbAutoHide = False
            .rc.Left = .rc.Right - glWidth
            lResult = SHAppBarMessage(ABM_SETPOS, BarData)
            .rc.Left = .rc.Right - glWidth
            lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, glWidth, .rc.Bottom - .rc.Top, SWP_NOACTIVATE)
        End If
        glAppBarTop = .rc.Top
        glAppBarLeft = .rc.Left
        glAppBarRight = .rc.Right
        glAppBarBottom = .rc.Bottom
        frmDock.tbrToolbar.Align = vbAlignRight
        frmDock.tbrToolbar.Width = glWidth
        End With

    Case abDockedLeft
        With BarData
        .uEdge = ABE_LEFT
        .rc.Top = 0
        .rc.Left = 0
        .rc.Bottom = glScreenHeight
        glWidth = (300 + 60) \ glTwipsPerPixelX
        'glWidth = (frmDock.tbrToolbar.ButtonWidth + 60) \ glTwipsPerPixelX

        If gbAutoHide Then
            If SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData) = 0 Then
                .lParam = True
                If SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData) <> 0 Then
                    .rc.Right = .rc.Left + EXPOSURE
                    lResult = SHAppBarMessage(ABM_SETPOS, BarData)
                    .rc.Left = 0
                    lResult = SHAppBarMessage(ABM_GETAUTOHIDEBAR, BarData)
                    glAppBarHandle = lResult
                    lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left - glWidth, .rc.Top, glWidth + EXPOSURE, .rc.Bottom - .rc.Top, SWP_NOACTIVATE)
                Else
                    bSetPosition = True
                End If
            Else
                bSetPosition = True
                bFail = True
            End If
        Else
            bSetPosition = True
        End If
        If bSetPosition Then
            gbAutoHide = False
            .rc.Right = .rc.Left + glWidth
            lResult = SHAppBarMessage(ABM_SETPOS, BarData)
            .rc.Right = .rc.Left + glWidth
            lResult = SetWindowPos(.hwnd, HWND_TOP, .rc.Left, .rc.Top, glWidth, .rc.Bottom - .rc.Top, SWP_NOACTIVATE)
        End If
        glAppBarTop = .rc.Top
        glAppBarLeft = .rc.Left
        glAppBarRight = .rc.Right
        glAppBarBottom = .rc.Bottom
        frmDock.tbrToolbar.Align = vbAlignRight
        frmDock.tbrToolbar.Width = glWidth
        End With
End Select
'
' Needed to refresh the toolbar so all buttons are
' correctly WRAPPED so they are all visible.  The
' toolbar control doesn't wrap the buttons until
' it is realigned or resized.
'
Select Case abPosition
    Case abDockedLeft, abDockedRight
        DoEvents
        frmDock.tbrToolbar.Align = vbAlignTop
        DoEvents
        frmDock.tbrToolbar.Align = vbAlignLeft
        DoEvents
        frmDock.tbrToolbar.Refresh
End Select

frmDock.Show
If (abPosition = abDockedLeft) Or (abPosition = abDockedRight) Then
    Call pForceButtonsToShowUp
End If
Call SetWindowPos(frmDock.hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE Or SWP_NOMOVE)

Dim frmMessage As Form
If bFail Then
    '
    ' Displaying a modal dialog locks up Windows so a non modal form is used.
    ' The message is the exact one Windows uses in this situation.
    '
    DoEvents
    frmMessage.Show vbModeless
End If
Screen.MousePointer = vbDefault
Exit Sub

pSetABDimensionsError:
    Call pDisplayError(sError)
End Sub


Public Sub pDisplayError(ByVal sError As String)
'
' Common procedure to display an error message.
'
Screen.MousePointer = vbDefault
If (Err.Number = 0) And (sError = "") Then Exit Sub

If Err.Number = 0 Then
    MsgBox sError, vbCritical, DISPLAY_TITLE
Else
    If sError = "" Then
        MsgBox Err.Description & _
           " (" & CStr(Err.Number) & ").", vbCritical, DISPLAY_TITLE
    Else
        MsgBox sError & vbCrLf & vbCrLf & Err.Description & _
           " (" & CStr(Err.Number) & ").", vbCritical, DISPLAY_TITLE
     End If
End If
End Sub


Public Sub Main()
Dim sError As String
'
' This is the startup routine for this app.
'
On Error GoTo SubMainError
'
' If we are already running, get out.
'
If App.PrevInstance Then
    MsgBox "Application is already running!", vbInformation, DISPLAY_TITLE
    GoTo SubMainError
End If
'
' Get the screen information.
'
Screen.MousePointer = vbHourglass
glScreenWidth = GetSystemMetrics(SM_CXSCREEN)
glScreenHeight = GetSystemMetrics(SM_CYSCREEN)
glTwipsPerPixelX = Screen.TwipsPerPixelX
glTwipsPerPixelY = Screen.TwipsPerPixelY
'
' Initialize the length of the WindowPlacement
' structure. Hide the docked appbar form, position
' the floating form and show it.
'
lpwndpl.Length = 44
gbSwapForms = False
abPosition = abFloating
Dim frmDock As Form
Dim frmFloat As Form
frmDock.Hide

With frmFloat
    glFormTop = .Top
    glFormLeft = .Left
    glFormHeight = .Height
    glFormWidth = .Width

    .Top = glFormTop
    .Left = glFormLeft
    .Height = glFormHeight
    .Width = glFormWidth
    .Show
    .tmrFloat.enabled = True
End With
Screen.MousePointer = vbDefault
Exit Sub
'
' Display error messages.
'
SubMainError:
    Call pDisplayError(sError)
    End
End Sub

Public Sub pUnregisterAppBar(ByVal abPos As AppbarLocations)
'
' Un-autohide an autohide appbar by specifing the screen
' edge, setting the lParam False and issuing the
' ABM_SETAUTOHIDEBAR message.
'
On Error GoTo sUnregisterError
If glAppBarHandle Then
    With BarData
        Select Case abPos
            Case abDockedTop
                .uEdge = ABE_TOP
            Case abDockedBottom
                .uEdge = ABE_BOTTOM
            Case abDockedLeft
                .uEdge = ABE_LEFT
            Case abDockedRight
                .uEdge = ABE_RIGHT
        End Select
        .lParam = False
        .hwnd = glAppBarHandle
    End With
    Call SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData)
End If
'
' Remove the appbar from Window's list.
'
If BarData.hwnd <> 0 Then
    Call SHAppBarMessage(ABM_REMOVE, BarData)
End If
Exit Sub

sUnregisterError:
    Call pDisplayError("Error unregistering docked appbar.")
End Sub

Public Sub ptbrButtonClick(ByVal iBtnIndex As Integer)

Dim frmDock As Form
Dim frmFloat As Form

'
' Exit when the first button is clicked, toggle autohide otherwise.
'
On Error GoTo ptbrButtonClickError
Select Case iBtnIndex
    Case 1 'Exit
          Call fUnloadForm
    Case 2 'Turn on autohide
        gbAutoHide = True
        frmFloat.tmrFloat.enabled = False
        Call pSetAppBarDimensions(True)
    Case 3 'Turn off autohide
        gbAutoHide = False
        frmFloat.tmrFloat.enabled = False
        Call pSetAppBarDimensions(True)
End Select
Exit Sub

ptbrButtonClickError:
    Call pDisplayError("")
End Sub

Public Function fUnloadForm() As Boolean


Dim frm    As Form
Dim sError As String
'
' This is a common exit routine called from the Unload event in
' frmDock and frmFloat.
'
On Error GoTo fUnloadFormError
'
' Unregister any docked appbars.
'
If BarData.hwnd <> 0 Then
    BarData.lParam = True
    Call SHAppBarMessage(ABM_SETAUTOHIDEBAR, BarData)
    SHAppBarMessage ABM_REMOVE, BarData
End If
gbEnd = True
'
' Unload all forms to end this application.
'
For Each frm In Forms
    Unload frm
Next
Exit Function

fUnloadFormError:
    Call pDisplayError(sError)
    fUnloadForm = False
End Function

Public Sub pForceButtonsToShowUp()
Dim dTemp As Single

Dim frmDock As Form
Dim frmFloat As Form


'
' Yea, this kludge should not be needed but it is.
' This forces the toolbar buttons to show up.  When
' ToolBar controls are Left or Right aligned, they
' do not automatically resize themselves as the form
' size changes as do Top and Bottom aligned toolbars.
'
DoEvents
With frmDock.tbrToolbar
    If .Align >= vbAlignLeft Then
        dTemp = .Width
        .Width = dTemp \ 2
        .Width = dTemp
    End If
End With
End Sub








