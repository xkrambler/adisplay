VERSION 5.00
Begin VB.Form comSelect 
   BorderStyle     =   4  'Fixed ToolWindow
   Caption         =   "Seleccione puerto"
   ClientHeight    =   4920
   ClientLeft      =   45
   ClientTop       =   285
   ClientWidth     =   5430
   BeginProperty Font 
      Name            =   "Arial"
      Size            =   8.25
      Charset         =   0
      Weight          =   400
      Underline       =   0   'False
      Italic          =   0   'False
      Strikethrough   =   0   'False
   EndProperty
   LinkTopic       =   "Form1"
   MaxButton       =   0   'False
   MinButton       =   0   'False
   ScaleHeight     =   4920
   ScaleWidth      =   5430
   ShowInTaskbar   =   0   'False
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton cmdcancel 
      Cancel          =   -1  'True
      Caption         =   "&Cancelar"
      Height          =   375
      Left            =   3720
      TabIndex        =   3
      Top             =   4320
      Width           =   1455
   End
   Begin VB.CommandButton cmdok 
      Caption         =   "&Seleccionar"
      Default         =   -1  'True
      Enabled         =   0   'False
      Height          =   375
      Left            =   240
      TabIndex        =   2
      Top             =   4320
      Width           =   1455
   End
   Begin VB.ListBox lst 
      BeginProperty Font 
         Name            =   "Arial"
         Size            =   15.75
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   3300
      Left            =   240
      TabIndex        =   0
      Top             =   600
      Width           =   4935
   End
   Begin VB.Label lb 
      AutoSize        =   -1  'True
      Caption         =   "Seleccione puerto de conexión al interface:"
      Height          =   210
      Left            =   240
      TabIndex        =   1
      Top             =   240
      Width           =   3135
   End
End
Attribute VB_Name = "comSelect"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Private Type puertoType
  puerto As String
  nombre As String
End Type
Private puertos() As puertoType

Private Sub cmdcancel_Click()

  End

End Sub

Private Sub cmdok_Click()

  If lst.ListIndex < 0 Then Exit Sub
  comSelected = puertos(lst.ListIndex).puerto
  Unload Me

End Sub

Private Sub Form_Activate()

  If Command$ <> "" Then
    comSelected = Command$
  End If

End Sub

Private Sub Form_Load()
  
  Dim i As Integer
  Dim key As String
  Dim value As String

  Center Me
  'OnTop Me.hwnd, True
  
  lst.Clear
  rgEnumKeys HKEY_LOCAL_MACHINE, "HARDWARE\DEVICEMAP\SERIALCOMM"
  Do While rgEnumKey(key, value)
    ReDim Preserve puertos(i)
    With puertos(i)
      .puerto = Replace(value, Chr$(0), "")
      .nombre = key
      lst.AddItem .puerto & " - " & .nombre
    End With
    i = i + 1
  Loop
  rgEnumKeysEnd

End Sub

Private Sub lst_Click()

  If lst.ListIndex >= 0 Then cmdok.Enabled = True

End Sub

Private Sub lst_DblClick()

  cmdok_Click

End Sub
