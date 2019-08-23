VERSION 5.00
Begin VB.Form clima 
   AutoRedraw      =   -1  'True
   BackColor       =   &H00000000&
   BorderStyle     =   0  'None
   ClientHeight    =   2025
   ClientLeft      =   0
   ClientTop       =   0
   ClientWidth     =   14895
   ForeColor       =   &H00FFFFFF&
   LinkTopic       =   "Form1"
   ScaleHeight     =   135
   ScaleMode       =   3  'Pixel
   ScaleWidth      =   993
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.Timer redraw 
      Interval        =   500
      Left            =   120
      Top             =   120
   End
End
Attribute VB_Name = "clima"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Private Declare Function GetDeviceCaps Lib "gdi32" _
  (ByVal hDC As Long, _
   ByVal nIndex As Long) As Long
   
Dim firstTime As Boolean
Dim BarData As APPBARDATA

Const HWND_TOPMOST = -1

Dim battery As New c32bppDIB
Dim ac_auto As New c32bppDIB
Dim ac_off As New c32bppDIB
Dim ac_on As New c32bppDIB
Dim manual1 As New c32bppDIB
Dim manual2 As New c32bppDIB
Dim manual3 As New c32bppDIB
Dim manual4 As New c32bppDIB
Dim manual5 As New c32bppDIB
Dim manual6 As New c32bppDIB
Dim manual7 As New c32bppDIB
Dim clima_feet As New c32bppDIB
Dim clima_feet_defrost As New c32bppDIB
Dim clima_feet_front As New c32bppDIB
Dim clima_front As New c32bppDIB

Private Const HORZRES As Long = 8
Private Const VERTRES As Long = 10
Private Const BITSPIXEL As Long = 12
Private Const VREFRESH As Long = 116

Dim screenWidth As Long
Dim screenHeight As Long
Dim screenVRefresh As Long


Public Sub doRedraw()

  screenResize

  Dim s As String
  Dim t2_width As Long
  Dim sepGradosBorderX As Long: sepGradosBorderX = 15
  Dim sepGradosBorderY As Long: sepGradosBorderY = 8
  
  Static grados As Long
  grados = grados + 1
  If grados < 16 Then grados = 16
  If grados > 28 Then grados = 28

  Me.Cls
  
  Me.FontBold = True
  Me.FontSize = 112
  Me.FontName = "LCD"
  
  If adisplay_t1 <> "" Then
    
    s = IIf(adisplay_t1 <> "", adisplay_t1, "")
    Me.CurrentX = sepGradosBorderX
    Me.CurrentY = -9
    Me.Print s;
    
    s = IIf(adisplay_t2 <> "", adisplay_t2, "")
    Me.CurrentX = Me.ScaleWidth - Me.TextWidth(s) - sepGradosBorderX
    Me.CurrentY = -9
    Me.Print s;
  
    t2_width = Me.TextWidth(s)
  
  Else
  
    t2_width = Me.TextWidth("22")

  End If

  Me.FontBold = True
  Me.FontSize = 12
  Me.FontName = "Calibri"

  s = getBatteryPercent() & "%" & IIf(isOnBattery(), "*", "")
  Me.CurrentX = Me.ScaleWidth - battery.Width - t2_width - sepGradosBorderX * 2
  Me.CurrentY = (Me.ScaleHeight - battery.Height) / 2
  imageRender battery, Me.CurrentX, Me.CurrentY, 1
  Me.CurrentX = Me.CurrentX - (TextWidth(s)) / 2 - 3
  Me.CurrentY = Me.CurrentY + 5
  Me.Print s;

  If Not adisplay_connected Then
    Me.CurrentX = sepGradosBorderX
    Me.CurrentY = sepGradosBorderY
    Me.Print "·";
  End If

  If adisplay_t1 <> "" Then

    Dim ac_image As c32bppDIB
    Select Case adisplay_ac
    Case "auto": Set ac_image = ac_auto
    Case "on": Set ac_image = ac_on
    Case "off": Set ac_image = ac_off
    End Select
    If Not ac_image Is Nothing Then imageRender ac_image, Me.ScaleWidth / 3.5, sepGradosBorderY, 1

    Dim manual_image As c32bppDIB
    Set manual_image = Nothing
    Select Case adisplay_manual
    Case 1: Set manual_image = manual1
    Case 2: Set manual_image = manual2
    Case 3: Set manual_image = manual3
    Case 4: Set manual_image = manual4
    Case 5: Set manual_image = manual5
    Case 6: Set manual_image = manual6
    Case 7: Set manual_image = manual7
    End Select
    If Not manual_image Is Nothing Then imageRender manual_image, Me.ScaleWidth / 2, sepGradosBorderY, 1

    Dim clima_image As c32bppDIB
    Set clima_image = Nothing
    Select Case adisplay_mode
    Case "feet_defrost": Set clima_image = clima_feet_defrost
    Case "feet":         Set clima_image = clima_feet
    Case "feet_front":   Set clima_image = clima_feet_front
    Case "front":        Set clima_image = clima_front
    End Select
    If Not clima_image Is Nothing Then imageRender clima_image, Me.ScaleWidth / 1.4, sepGradosBorderY, 1

  End If

End Sub

Private Sub imageRender(Image As c32bppDIB, X As Long, Y As Long, align As Integer)
  Dim w As Long: w = 0
  Dim h As Long: h = 0
  If (align Mod 3) = 1 Then w = Image.Width / 2
  If (align Mod 3) = 2 Then w = Image.Width
  If (align / 3) = 1 Then h = Image.Height / 2
  If (align / 3) = 2 Then h = Image.Height
  Image.Render clima.hDC, X - w, Y - h
End Sub

Private Sub screenResize()

  If screenWidth <> Screen.Width Or screenHeight <> Screen.Height Or screenVRefresh <> GetDeviceCaps(hDC, VREFRESH) Then
    
    msg "ScreenResize " & screenWidth & "/" & Screen.Width & " " & screenHeight & "/" & Screen.Height & " " & screenVRefresh & "/" & GetDeviceCaps(hDC, VREFRESH)
    screenWidth = Screen.Width
    screenHeight = Screen.Height
    screenVRefresh = GetDeviceCaps(hDC, VREFRESH)

    Me.Top = Screen.Height - Me.Height
    Me.Left = 0
    Me.Width = Screen.Width
  
    With BarData
      .cbSize = Len(BarData)
      .hwnd = Me.hwnd
      .uEdge = ABE_BOTTOM
      '.uCallbackMessage = WM_MOUSEMOVE
    End With
  
    Dim lResult As Long
    lResult = SetRect(BarData.rc, 0, 0, Me.Width / Screen.TwipsPerPixelY, Me.Height / Screen.TwipsPerPixelY)
    If Not firstTime Then
      lResult = SHAppBarMessage(ABM_REMOVE, BarData)
    End If
    'If firstTime Then
      lResult = SHAppBarMessage(ABM_NEW, BarData)
      lResult = SHAppBarMessage(ABM_SETPOS, BarData)
      firstTime = False
      'screenWidth = Screen.Width
      'screenHeight = Screen.Height
    'End If
  
    BarData.rc.Left = Me.Left / Screen.TwipsPerPixelY
    BarData.rc.Top = Me.Top / Screen.TwipsPerPixelY
    'lResult = SHAppBarMessage(ABM_SETPOS, BarData)
  
    Me.Refresh
    lResult = SetWindowPos(Me.hwnd, HWND_TOP, BarData.rc.Left, BarData.rc.Top, BarData.rc.Right - BarData.rc.Left, BarData.rc.Bottom, SWP_NOACTIVATE)
    lResult = SetWindowPos(Me.hwnd, HWND_TOPMOST, BarData.rc.Left, BarData.rc.Top, BarData.rc.Right - BarData.rc.Left, BarData.rc.Bottom, SWP_NOACTIVATE)
  
  End If
  
End Sub

Private Sub Form_DblClick()
  Unload zMain
End Sub

Private Sub Form_Load()
  
  'Me.Picture = LoadPicture("images/ac_auto.png")
  'image.LoadPicture_StdPicture "images/ac_auto.png"
  
  battery.LoadPicture_File "images/battery.png"
  ac_auto.LoadPicture_File "images/ac_auto.png"
  ac_off.LoadPicture_File "images/ac_off.png"
  ac_on.LoadPicture_File "images/ac_on.png"
  manual1.LoadPicture_File "images/manual1.png"
  manual2.LoadPicture_File "images/manual2.png"
  manual3.LoadPicture_File "images/manual3.png"
  manual4.LoadPicture_File "images/manual4.png"
  manual5.LoadPicture_File "images/manual5.png"
  manual6.LoadPicture_File "images/manual6.png"
  manual7.LoadPicture_File "images/manual7.png"
  clima_feet.LoadPicture_File "images/clima_feet.png"
  clima_feet_defrost.LoadPicture_File "images/clima_feet_defrost.png"
  clima_feet_front.LoadPicture_File "images/clima_feet_front.png"
  clima_front.LoadPicture_File "images/clima_front.png"

  ' si no se ha podido cargar, usar la imágen predefinida de imágen no encontrada
  'Select Case displayImages(ip).image.ImageType
  'Case imgIcon, imgIconARGB, imgPNG, imgPNGicon, imgWMF, imgGIF, imgEMF, imgBitmap, imgBmpARGB, imgBmpPARGB, imgCursor, imgCursorARGB
  'Case Else: displayImages(ip).image.LoadPicture_StdPicture zMain.imgNotFound.Picture
  'End Select

  firstTime = True
  
  WindowsTaskBar False
  
  Me.Show
  doRedraw

End Sub

Private Sub Form_QueryUnload(Cancel As Integer, UnloadMode As Integer)

  Dim lResult As Long
  lResult = SHAppBarMessage(ABM_REMOVE, BarData)

  WindowsTaskBar True

  End

End Sub

Private Sub redraw_Timer()

  doRedraw

End Sub
