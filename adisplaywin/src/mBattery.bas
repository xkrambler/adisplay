Attribute VB_Name = "mBattery"
Private Declare Function GetSystemPowerStatus Lib "kernel32" (lpSystemPowerStatus As SYSTEM_POWER_STATUS) As Long

Private Type SYSTEM_POWER_STATUS
  ACLineStatus As Byte
  BatteryFlag As Byte
  BatteryLifePercent As Byte
  Reserved1 As Byte
  BatteryLifeTime As Long
  BatteryFullLifeTime As Long
End Type

Public Function isOnBattery() As Boolean

  Dim ps As SYSTEM_POWER_STATUS

  GetSystemPowerStatus ps

  If ps.ACLineStatus = 0 Then
    isOnBattery = True
  Else
    isOnBattery = False
  End If

End Function

Public Function getBatteryPercent() As Byte

  Dim ps As SYSTEM_POWER_STATUS

  GetSystemPowerStatus ps
  getBatteryPercent = ps.BatteryLifePercent
  ' MyLifeTime / 3600 & " hours remaining on battery."

End Function
