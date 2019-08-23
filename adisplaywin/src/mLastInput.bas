Attribute VB_Name = "mLastInput"
Option Explicit

Public Type LASTINPUTINFO
  cbSize As Long
  dwTime As Long
End Type

Public Declare Function GetLastInputInfo Lib "user32" (li As LASTINPUTINFO) As Long
Public Declare Function GetTickCount Lib "kernel32" () As Long

' returns system tick count when last input occurred
Private Function GetInputTick() As Long
  Dim myLI As LASTINPUTINFO
  myLI.cbSize = Len(myLI)
  GetLastInputInfo myLI
  GetInputTick = myLI.dwTime
End Function

' returns idle ticks
Public Function getIdleTicks() As Long
  getIdleTicks = GetTickCount() - GetInputTick()
End Function
