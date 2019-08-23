Attribute VB_Name = "mCenterFrm"

Public Sub Center(frm As Form)
frm.Left = (Screen.Width - frm.Width) / 2
frm.Top = (Screen.Height - frm.Height) / 2
End Sub
