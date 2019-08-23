VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "cCDECL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Following is from Paul Caton, no modifications made by myself except value of MAX_ARG
'--------------------------------------------------------------------------
'
' cCDECL - Class that enables the user to call cdecl dynamic link libraries.
'          Supports cdecl style variable argument lists and bas module
'          callbacks.
'
'031029 First cut.................................................... v1.00
'
Option Explicit
Option Base 0

'API declarations
Private Declare Sub RtlMoveMemory Lib "kernel32" (Destination As Any, Source As Any, ByVal Length As Long)
Private Declare Function FreeLibrary Lib "kernel32" (ByVal hLibModule As Long) As Long
Private Declare Function GetLastError Lib "kernel32" () As Long
Private Declare Function GetProcAddress Lib "kernel32" (ByVal hModule As Long, ByVal lpProcName As String) As Long
Private Declare Function LoadLibraryA Lib "kernel32" (ByVal lpLibFileName As String) As Long
Private Declare Sub SetLastError Lib "kernel32" (ByVal dwErrCode As Long)

'Private constants
Private Const ERR_SRC       As String = "cCDECL"    'Error source name
Private Const ERR_NUM       As Long = vbObjectError 'cCDECL error number base
Private Const MAX_ARG       As Long = 5&            'Maximum number of parameters, you can change this if required
Private Const PATCH_01      As Long = 15&           'CDECL patch, CDECL function address
Private Const PATCH_02      As Long = 10&           'Callback patch, bas mod function address patch
Private Const PATCH_03      As Long = 16&           'Callback patch, stack adjustment patch

Private Const CODE_CDECL    As String = "538B5C240C8B0BE305FF348BE2FBE8<fix 01>8B0BC1E10201CC5B8B54240C890231C0C20C00"
Private Const CODE_WRAPPER  As String = "E8000000005A8F4219E8<fix 02>81EC<fix 03>E8000000005AFF7205C300000000"

'Parameter block
Private Type tParamBlock
  ParamCount                As Long                 'Number of parameters to be forwarded to the cdecl function
  Params(0 To MAX_ARG - 1)  As Long                 'Array of parameters to be forwarded to the cdecl function
End Type

'Private member
Private m_LastError         As Long                 'Last error private member

'Private variables
Private bNewDLL             As Boolean              'Flag to indicate that the loaded DLL has changed
Private pMe                 As Long                 'vtable address
Private hMod                As Long                 'DLL module handle
Private nAddr               As Long                 'Cache the previous cdecl function's address
Private nEntry              As Long                 'vtable entry index
Private pCode               As Long                 'Pointer to the CDECL code
Private sLastFunc           As String               'Cache the previous cdecl function's name
Private sCode()             As String               'Code buffer string array...
Private pb                  As tParamBlock          'Parameter block instance

'Replace the stub proc (z_DO_NOT_CALL) with machine-code to handle the cdecl function
'stored in sCode(0). Load the wrapper code into sCode(1)
Private Sub Class_Initialize()
  'ObjPtr returns the address of me, at that address is the address of the vtable, copy it to pMe.
  Call RtlMoveMemory(pMe, ByVal ObjPtr(Me), 4)

  Call Redirect(CODE_CDECL, True)                   'CDECL code
  pCode = StrPtr(sCode(0&))                         'Remember the address of the CDECL code
  
  Call Redirect(CODE_WRAPPER, False)                'Callback wrapper code, vtable not patched... we don't call it
End Sub

'Convert the passed string of hex character pairs to bytes stored in an ASCII
'string buffer. If indicated, patch the appropriate vtable entry to point to the byte codes
Private Sub Redirect(ByVal sHexCode As String, ByVal bPatch As Boolean)
  Dim i     As Long
  Dim nLen  As Long
  Dim s     As String
  
  nLen = Len(sHexCode)
  
  For i = 1 To nLen Step 2
    s = s & ChrB$(Val("&H" & Mid$(sHexCode, i, 2)))
  Next i
  
  ReDim Preserve sCode(0 To nEntry)
  sCode(nEntry) = s
  
  If bPatch Then
    'Patch the vtable entry to point to the code
    Call RtlMoveMemory(ByVal pMe + &H1C + (nEntry * 4), StrPtr(sCode(nEntry)), 4)
  End If
  
  nEntry = nEntry + 1                               'In case another patch is added to the class
End Sub

Public Function z_DO_NOT_CALL(ByVal nAddrParamBlock As Long) As Long
'This sub is replaced by machine code in sCode(0) at class instance creation...
'IT MUST ONLY be called internally by CallFunc. It can't be made Private as it wouldn't
'then use the vtable. Being the first public method in this class, we know that the vtable
'pointer to this function will be located at [vtable + &H1C]
End Function

'Purpose:
' Call the named cdecl function with the passed parameters
'
'Arguments:
' sFunction - Name of the cdecl function to call
' ParmLongs - ParamArray of parameters to pass to the named cdecl function
'
'Return:
'  The return value of the named cdecl function
'
Public Function CallFunc(ByVal sFunction As String, ParamArray ParmLongs() As Variant) As Long
  Dim i As Long
  Dim j As Long
  
  'Check that the DLL is loaded
  If hMod = 0& Then
    
    'If in the IDE just stop, programmer may have On Error Resume Next protection and miss the problem.
    Debug.Assert False
    Call Err.Raise(ERR_NUM + 0, ERR_SRC, "DLL not loaded")
  End If

  'Check to see if we're calling the same cdecl function as the previous call to CallFunc
  If (StrComp(sLastFunc, sFunction) <> 0) Or bNewDLL Then
    
    'Get the address of the function
    nAddr = GetProcAddress(hMod, sFunction)
    If nAddr = 0 Then
      
      'If in the IDE just stop, programmer may have On Error Resume Next protection and miss the problem.
      Debug.Assert False
      Call Err.Raise(ERR_NUM + 1, ERR_SRC, "Failed to locate function: " & sFunction)
    End If

    'Patch the code buffer to call the relative address to the cdecl function
    Call RtlMoveMemory(ByVal pCode + PATCH_01, nAddr - pCode - (PATCH_01 + 4), 4)
    bNewDLL = False
    sLastFunc = sFunction
  End If
  
  With pb
    j = UBound(ParmLongs)
    If j >= MAX_ARG Then
      
      'If in the IDE just stop, programmer may have On Error Resume Next protection and miss the problem.
      Debug.Assert False
      Call Err.Raise(ERR_NUM + 2, ERR_SRC, "Too many parameters")
    End If
    
    'Fill the parameter block
    For i = 0 To j
      .Params(i) = ParmLongs(i)
    Next i
    
    .ParamCount = i                                         '(j + 1)
  End With
  
  Call SetLastError(0)                                      'Clear the error code
  CallFunc = z_DO_NOT_CALL(VarPtr(pb))                      'Execute the code buffer passing the address of the parameter block
  m_LastError = GetLastError()                              'Get error code
End Function

'Load the DLL
Public Function DllLoad(ByVal sName As String) As Boolean
  hMod = LoadLibraryA(sName)

  If hMod <> 0 Then
    DllLoad = True
    'It's remotely possible that the programmer could change the dll and then call a function
    'in the new dll with exactly the same name as the previous CallFunc to the previous DLL. This would
    'defeat the caching scheme and result in the old function in the old dll being called. An unlikely
    'scenario, but stranger things have happened. Soooo, explicitly indicate that we're using a new dll
    bNewDLL = True
  End If
  
  'If in the IDE just stop on failure, programmer may not be checking the return value.
  Debug.Assert DllLoad
End Function

'It's not important to do this, but, if you've finished with a DLL there's no harm in releasing
'its memory. Don't bother at app end... it will be dealt with automatically when the process ends.
Public Function DllUnload() As Boolean
  If hMod <> 0 Then
    DllUnload = (FreeLibrary(hMod) <> 0)
    hMod = 0
  End If
  
  'If in the IDE, get the programmer's attention
  Debug.Assert DllUnload
End Function

'Return the cdecl function's error code
Public Property Get LastError() As Long
  LastError = m_LastError
End Property

'Purpose:
' Setup a wrapper so that a bas module function can act as a cdecl callback
'
'Arguments:
' nModFuncAddr - The address of the bas module function to act as a cdecl callback (use AddressOf)
' nParms       - The number of parameters that will be passed to the bas module function
'
'Return:
'  The address to pass to the cdecl function as the callback address
'
Public Function WrapCallback(ByVal nModFuncAddr As Long, ByVal nParms As Long) As Long
  Dim nStackAdjust As Long                                  'The number of bytes to adjust the stack
  
  WrapCallback = StrPtr(sCode(1))                           'Address of the callback wrapper
  nStackAdjust = nParms * 4                                 'Four bytes per parameter

  'Patch the code buffer to call the vb bas module callback function
  Call RtlMoveMemory(ByVal WrapCallback + PATCH_02, nModFuncAddr - WrapCallback - (PATCH_02 + 4), 4)
  
  'Patch the code buffer to apply the necessary stack adjustment
  Call RtlMoveMemory(ByVal WrapCallback + PATCH_03, nStackAdjust, 4)
End Function
