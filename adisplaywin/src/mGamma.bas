Attribute VB_Name = "mGamma"
' mGamma BASIC based on RoadRunner's source

Public gammaEnabled As Integer
Public gammaData As String

Private ramp(0 To 255, 0 To 2) As Integer
Private savedRamp(0 To 255, 0 To 2) As Integer
Private Declare Function GetDeviceGammaRamp Lib "gdi32" (ByVal hDC As Long, lpv As Any) As Long
Private Declare Function SetDeviceGammaRamp Lib "gdi32" (ByVal hDC As Long, lpv As Any) As Long

Private Declare Function GetDesktopWindow Lib "user32" () As Long
Private Declare Function GetDC Lib "user32" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32" (ByVal hwnd As Long, ByVal hDC As Long) As Long

Private Function SignedValue(lngValue As Long) As Integer
  
  If lngValue <= 32767 Then
    SignedValue = CInt(lngValue)
  Else
    SignedValue = CInt(lngValue - 65535)
  End If

End Function

Private Function UnSignedValue(intValue As Integer) As Long

  If intValue >= 0 Then
    UnSignedValue = intValue
  Else
    UnSignedValue = intValue + 65535
  End If

End Function

Private Function timeToMinutes(t As String) As Long
  timeToMinutes = Val(Left$(t, 2)) * 60 + Val(Mid$(t, 4, 2))
End Function

Public Function gammaCalc() As Integer

  Dim m As Integer
  
  Dim baseGamma As Integer: baseGamma = 160
  Dim allGamma As Integer: allGamma = 255
  Dim ratedGamma As Integer: ratedGamma = allGamma - baseGamma
  
  Dim times As String
  Dim sunrise As Long
  Dim sunset As Long
  Dim minoff As Integer
  
  ' comprobar el tipo de cálculo que se debe hacer
  Select Case gammaEnabled
  Case GAMMA_FIXED
    sunrise = timeToMinutes(prm$(gammaData, "1"))
    sunset = timeToMinutes(prm$(gammaData, "2"))
    
  'Case GAMMA_GPS
  '  times = gammaGPStimes(Val(prm$(gammaData, "1")), Val(prm$(gammaData, "2")))
  '  sunrise = timeToMinutes(prm$(times, "1"))
  '  sunset = timeToMinutes(prm$(times, "2"))
    
  Case Else
    gammaCalc = allGamma
    Exit Function
    
  End Select
  
  ' minutos transcurridos para la hora actual
  m = timeToMinutes(Time$)
  
  ' ***************** parche horario de verano
  'If m > 60 Then m = m - 60 ' *** PATH, horario de verano
  
  ' tiempo en minutos en los que se irá realizando una transición
  minoff = 30
  
  ' de noche
  If m < sunrise Or m > sunset Then
    gammaCalc = baseGamma
    Exit Function
  End If
  
  ' amaneciendo
  If m >= sunrise And m <= sunrise + minoff Then
    gammaCalc = baseGamma + ((m - sunrise) / minoff) * ratedGamma
    Exit Function
  End If
  
  ' anocheciendo
  If m >= sunset - minoff And m <= sunset Then
    gammaCalc = baseGamma + ((sunset - m) / minoff) * ratedGamma
    Exit Function
  End If
  
  ' por defecto, de día
  gammaCalc = allGamma
  
End Function

Public Sub gammaAll(ByVal all As Integer)

  gammaSet all, all, all

End Sub

Public Sub gammaSet(ByVal red As Integer, ByVal green As Integer, ByVal blue As Integer)
    
  Dim i As Long
  Dim ScrDC As Long
  
  ScrDC = GetDC(GetDesktopWindow())
  
  GetDeviceGammaRamp ScrDC, ramp(0, 0)
  
  For i = 0 To 255
    ramp(i, 0) = SignedValue(i * red)
    ramp(i, 1) = SignedValue(i * green)
    ramp(i, 2) = SignedValue(i * blue)
  Next
  
  SetDeviceGammaRamp ScrDC, ramp(0, 0)
  Call ReleaseDC(GetDesktopWindow(), ScrDC)

End Sub

Public Sub gammaSave()
  
  Dim ScrDC As Long
  
  ScrDC = GetDC(GetDesktopWindow())
  GetDeviceGammaRamp ScrDC, savedRamp(0, 0)
  Call ReleaseDC(GetDesktopWindow(), ScrDC)

End Sub

Public Sub gammaRestore()
  
  Dim ScrDC As Long
  
  ScrDC = GetDC(GetDesktopWindow())
  SetDeviceGammaRamp ScrDC, savedRamp(0, 0)
  ReleaseDC GetDesktopWindow(), ScrDC

End Sub
