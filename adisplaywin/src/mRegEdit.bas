Attribute VB_Name = "mRegEdit"
Option Explicit

'mRegEdit: Functions for Control the Windows Registry.
'========= Base and Extension by XKrÄmBlÊR[ïNêRt,ÎNC.]
'
' rgCreateKey(HKEY, KeyName)
' rgCreateKeyPath(HKEY, KeyName)
' rgDelKey(HKEY, KeyName)
' rgDelValue(HKEY, KeyName, ValueName)
' rgGetValue(HKEY, KeyName, ValueName)
' rgSetValue(HKEY, KeyName, ValueName, ValueData, ValueType)
' rgGetKeyName(KeyName, KeyPosition)
' rgEnumKeys(HKEY, KeyName)
' rgEnumKey(&key, &value)
' rgEnumKeysEnd

Public Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (Destination As Any, Source As Any, ByVal length As Long)
Public Declare Function RegCloseKey Lib "advapi32.dll" (ByVal hKey As Long) As Long
Public Declare Function RegCreateKeyEx Lib "advapi32.dll" Alias "RegCreateKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal reserved As Long, ByVal lpClass As String, ByVal dwOptions As Long, ByVal samDesired As Long, ByVal lpSecurityAttributes As Long, phkResult As Long, lpdwDisposition As Long) As Long
Public Declare Function RegOpenKeyEx Lib "advapi32.dll" Alias "RegOpenKeyExA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal ulOptions As Long, ByVal samDesired As Long, phkResult As Long) As Long
Public Declare Function RegQueryValueExString Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, ByVal lpData As String, lpcbData As Long) As Long
Public Declare Function RegQueryValueExLong Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, lpData As Long, lpcbData As Long) As Long
Public Declare Function RegQueryValueExNULL Lib "advapi32.dll" Alias "RegQueryValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal lpReserved As Long, lpType As Long, ByVal lpData As Long, lpcbData As Long) As Long
Public Declare Function RegSetValueExString Lib "advapi32.dll" Alias "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal reserved As Long, ByVal dwType As Long, ByVal lpValue As String, ByVal cbData As Long) As Long
Public Declare Function RegSetValueExLong Lib "advapi32.dll" Alias "RegSetValueExA" (ByVal hKey As Long, ByVal lpValueName As String, ByVal reserved As Long, ByVal dwType As Long, lpValue As Long, ByVal cbData As Long) As Long
Public Declare Function RegDeleteKey& Lib "advapi32.dll" Alias "RegDeleteKeyA" (ByVal hKey As Long, ByVal lpSubKey As String)
Public Declare Function RegDeleteValue& Lib "advapi32.dll" Alias "RegDeleteValueA" (ByVal hKey As Long, ByVal lpValueName As String)
Public Declare Function RegEnumValue Lib "advapi32.dll" Alias "RegEnumValueA" (ByVal hKey As Long, ByVal dwIndex As Long, ByVal lpValueName As String, lpcbValueName As Long, ByVal lpReserved As Long, lpType As Long, lpData As Any, lpcbData As Long) As Long
Public Declare Function RegEnumKey Lib "advapi32.dll" Alias "RegEnumKeyA" (ByVal hKey As Long, ByVal dwIndex As Long, ByVal lpName As String, ByVal cbName As Long) As Long
Public Declare Function RegQueryValue Lib "advapi32.dll" Alias "RegQueryValueA" (ByVal hKey As Long, ByVal lpSubKey As String, ByVal lpValue As String, lpcbValue As Long) As Long

Public Const ERROR_SUCCESS = 0&

Public Const REG_NONE = 0                       ' Sin tipo de valor
Public Const REG_SZ = 1                         ' Cadena Unicode terminada en valor nulo
Public Const REG_EXPAND_SZ = 2                  ' Cadena Unicode terminada en valor nulo
Public Const REG_BINARY = 3                     ' Binario de formato libre
Public Const REG_DWORD = 4                      ' Número de 32 bits
Public Const REG_DWORD_LITTLE_ENDIAN = 4        ' Número de 32 bits (el mismo que en REG_DWORD)
Public Const REG_DWORD_BIG_ENDIAN = 5           ' Número de 32 bits
Public Const REG_LINK = 6                       ' Vínculo simbólico (Unicode)
Public Const REG_MULTI_SZ = 7                   ' Cadenas múltiples Unicode
Public Const REG_RESOURCE_LIST = 8              ' Lista de recursos en el mapa de recursos
Public Const REG_FULL_RESOURCE_DESCRIPTOR = 9   ' Lista de recursos en la descripción del hardware
Public Const REG_RESOURCE_REQUIREMENTS_LIST = 10

Global Const HKEY_CLASSES_ROOT = &H80000000
Global Const HKEY_CURRENT_USER = &H80000001
Global Const HKEY_LOCAL_MACHINE = &H80000002
Global Const HKEY_USERS = &H80000003
Global Const HKEY_CURRENT_CONFIG = &H80000005
Global Const HKEY_DYN_DATA = &H80000006
Global Const HKEY_PERFORMANCE_DATA = &H80000004

Global Const ERROR_NONE = 0
Global Const ERROR_BADDB = 1
Global Const ERROR_BADKEY = 2
Global Const ERROR_CANTOPEN = 3
Global Const ERROR_CANTREAD = 4
Global Const ERROR_CANTWRITE = 5
Global Const ERROR_OUTOFMEMORY = 6
Global Const ERROR_INVALID_PARAMETER = 7
Global Const ERROR_ACCESS_DENIED = 8
Global Const ERROR_INVALID_PARAMETERS = 87
Global Const ERROR_NO_MORE_ITEMS = 259

Global Const KEY_ALL_ACCESS = &H3F
Global Const REG_OPTION_NON_VOLATILE = 0

Private rgEnumKeysKey As Long
Private rgEnumKeysCounter As Long

Public Function rgDelKey(lPredefinedKey As Long, sKeyName As String)
  Dim lRetVal As Long, hKey As Long
  lRetVal = RegOpenKeyEx(lPredefinedKey, sKeyName, 0, KEY_ALL_ACCESS, hKey)
  lRetVal = RegDeleteKey(lPredefinedKey, sKeyName)
  RegCloseKey (hKey)
End Function

Public Function rgDelValue(lPredefinedKey As Long, sKeyName As String, sValueName As String)
  Dim lRetVal As Long, hKey As Long
  lRetVal = RegOpenKeyEx(lPredefinedKey, sKeyName, 0, KEY_ALL_ACCESS, hKey)
  lRetVal = RegDeleteValue(hKey, sValueName)
  RegCloseKey (hKey)
End Function

Public Function rgSetValueEx(ByVal hKey As Long, sValueName As String, lType As Long, vValue As Variant) As Long
  Dim lValue As Long, sValue As String
  Select Case lType
  Case REG_SZ: sValue = vValue: rgSetValueEx = RegSetValueExString(hKey, sValueName, 0&, lType, sValue, Len(sValue))
  Case REG_BINARY: sValue = vValue: rgSetValueEx = RegSetValueExString(hKey, sValueName, 0&, lType, sValue, Len(sValue))
  Case REG_DWORD: lValue = vValue: rgSetValueEx = RegSetValueExLong(hKey, sValueName, 0&, lType, lValue, 4)
  End Select
End Function

Function rgQueryValueEx(ByVal lhKey As Long, ByVal szValueName As String, vValue As Variant) As Long
  Dim cch As Long, lrc As Long, lType As Long, lValue As Long, sValue As String
  lrc = RegQueryValueExNULL(lhKey, szValueName, 0&, lType, 0&, cch)
  If lrc = ERROR_NONE Then
    Select Case lType
    Case REG_SZ
      sValue = String(cch, 0)
      lrc = RegQueryValueExString(lhKey, szValueName, 0&, lType, sValue, cch)
      If lrc = ERROR_NONE Then vValue = Left$(sValue, cch - 1) Else vValue = Empty
    Case REG_BINARY
      sValue = String(cch, 0)
      lrc = RegQueryValueExString(lhKey, szValueName, 0&, lType, sValue, cch)
      If lrc = ERROR_NONE Then vValue = Left$(sValue, cch) Else vValue = Empty
    Case REG_DWORD
      lrc = RegQueryValueExLong(lhKey, szValueName, 0&, lType, lValue, cch)
      If lrc = ERROR_NONE Then vValue = lValue
    Case Else
      lrc = -1
    End Select
  End If
End Function

Public Function rgCreateKey(lPredefinedKey As Long, sNewKeyName As String)
  Dim hNewKey As Long, lRetVal As Long
  lRetVal = RegCreateKeyEx(lPredefinedKey, sNewKeyName, 0&, vbNullString, REG_OPTION_NON_VOLATILE, KEY_ALL_ACCESS, 0&, hNewKey, lRetVal)
  RegCloseKey (hNewKey)
End Function

Public Function rgSetValue(lPredefinedKey As Long, sKeyName As String, sValueName As String, vValueSetting As Variant, lValueType As Long)
  Dim lRetVal As Long, hKey As Long
  lRetVal = RegOpenKeyEx(lPredefinedKey, sKeyName, 0, KEY_ALL_ACCESS, hKey)
  lRetVal = rgSetValueEx(hKey, sValueName, lValueType, vValueSetting): RegCloseKey (hKey)
End Function

Public Function rgGetValue(lPredefinedKey As Long, sKeyName As String, sValueName As String)
  Dim lRetVal As Long, hKey As Long, vValue As Variant
  lRetVal = RegOpenKeyEx(lPredefinedKey, sKeyName, 0, KEY_ALL_ACCESS, hKey)
  lRetVal = rgQueryValueEx(hKey, sValueName, vValue)
  RegCloseKey (hKey): rgGetValue = vValue
End Function

Public Sub rgCreateKeyPath(lPredefinedKey As Long, sNewKeyName As String)

  Dim i As Integer
  i = 0
  Do
    i = InStr(i + 1, sNewKeyName & "\", "\")
    If i = 0 Then Exit Do
    rgCreateKey lPredefinedKey, Left$(sNewKeyName, i - 1)
  Loop

End Sub

Public Function rgGetKeyName(T$, N$)
  Dim XA&, NP%, X&, NPS$, TM&, p$, NDE%
  XA& = 1: NP% = 0
  Do
    NP% = NP% + 1: X& = InStr(XA&, T$, "\")
    If X& = 0 Then X& = Len(T$) + 1
    NPS$ = LTrim$(Str$(NP%)): TM& = 1
    If Right$(N$, 1) <> "-" Then p$ = Mid$(T$, XA&, X& - XA&) Else p$ = Mid$(T$, XA&)
    If NPS$ = N$ Or NPS$ + "-" = N$ Then rgGetKeyName = p$: Exit Function
    XA& = X& + TM&: If X& = Len(T$) + 1 Or NDE% = 1 Then rgGetKeyName = "": Exit Function
  Loop
End Function

Public Function rgEnumKeys(ByVal lPredefinedKey As Long, ByVal sKeyName As String) As Boolean
  
  If RegOpenKeyEx(lPredefinedKey, sKeyName, 0&, KEY_ALL_ACCESS, rgEnumKeysKey) = ERROR_SUCCESS Then
    rgEnumKeysCounter = 0
    rgEnumKeys = True
  End If

End Function

Public Function rgEnumKey(ByRef key As String, ByRef value As Variant) As Boolean

  Dim value_type As Long
  Dim value_name_len As Long
  Dim value_name As String
  Dim value_data(0 To 1024) As Byte
  Dim value_data_len As Long
  Dim value_long As Long

  value_name_len = UBound(value_data)
  value_name = Space$(value_name_len)
  value_data_len = UBound(value_data)
  If RegEnumValue(rgEnumKeysKey, rgEnumKeysCounter, value_name, value_name_len, 0, value_type, value_data(0), value_data_len) <> ERROR_SUCCESS Then
    Exit Function
  End If
  key = Left$(value_name, value_name_len)
  
  Select Case value_type
  Case REG_DWORD, REG_DWORD_BIG_ENDIAN, REG_DWORD_LITTLE_ENDIAN
    CopyMemory ByVal VarPtr(value_long), value_data(0), Len(value_long)
    value = value_long
  
  Case REG_EXPAND_SZ, REG_FULL_RESOURCE_DESCRIPTOR, REG_LINK, REG_NONE, REG_RESOURCE_LIST, _
       REG_RESOURCE_REQUIREMENTS_LIST, REG_SZ, REG_MULTI_SZ, REG_BINARY
    value = Left$(StrConv(value_data, vbUnicode), value_data_len)
  
  Case REG_NONE
    value = Null
  
  Case Else
    value = Null
  
  End Select
  
  rgEnumKeysCounter = rgEnumKeysCounter + 1
  rgEnumKey = True

End Function

Public Function rgEnumKeysEnd() As Boolean
  If RegCloseKey(rgEnumKeysKey) <> ERROR_SUCCESS Then Exit Function
  rgEnumKeysEnd = True
End Function
