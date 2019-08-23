VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "c32bppDIB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' Credits/Acknowledgements - Thanx goes to:
'   Paul Caton for his class on calling non VB-Friendly DLLs that use _cdecl calling convention
'       Used when calling non VB-friendly zLIB dll versions
'   Alfred Koppold for his PNG, VB-only, decompression routines.
'       Used when zLib & GDI+ not available
'   Carles P.V for his pvResize logic
'       Used when manually scaling images with NearestNeighbor or BiLinear interpolation
'   www.zlib.net for their free zLIB.dll, the standard DLL for compressing/decompressing PNGs
'       Without it, we'd be limited to GDI+ for creating PNGs
'   coders like you that provide constructive criticism to make this class better & more all-inclusive
'       Without your comments, this project probably would have died several versions/updates ago
' For most current updates/enhancements visit the following:
'   Visit http://www.planetsourcecode.com/vb/scripts/ShowCode.asp?txtCodeId=67466&lngWId=1
' To see a usercontrol applying a version of this class
'   AlphaImage Control. http://www.planetsourcecode.com/vb/scripts/ShowCode.asp?txtCodeId=68262&lngWId=1
'   Image List Control. http://www.planetsourcecode.com/vb/scripts/ShowCode.asp?txtCodeId=69621&lngWId=1

' = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
'                                    O V E R V I E W
' = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
' AlphaBlend API :: (msimg32.dll) , GDI+ API (gdiplus.dll)

' About 32bpp pre-multiplied RGB (pARGB) bitmaps, if you are not aware.
'   - These are used specifically for the AlphaBlend API & are GDI+ compatible
'   Advantages:
'       - Images can be per-pixel alpha blended
'       - Opacity can be simultaneously adjusted during rendering
'       - AlphaBlend does both BitBlt & StretchBlt for pARGB images.
'       - Speed: AlphaBlend & GDI+ are pretty quick APIs vs manual blending
'   Disadvantages:
'       - The original RGB values are permanently destroyed during pre-multiplying
'           -- Premultiplied formula: preMultipliedRed=(OriginalRed * Alpha) \ 255
'           -- There is no way to convert pARGB back to non-premultiplied RGB values
'              The formula would be: reconstructedRed=(preMultipliedRed * 255) \ Alpha.
'               but because of integer division when pre-multiplying, the result is very
'               close and if this should be premultiplied again & converted again, the
'               calculated colors can eventually be completely different than the original.
'               Fully opaque pixels & fully transparent pixels are not affected.
'           ** Note: When images are converted to PNG formats, removal of
'              premultiplication is performed to meet PNG specs.
'       - Displaying a pre-multiplied bitmap without AlphaBlend/GDI+ will not result in
'           the image being displayed as expected.
'       - Not ideal for saving due to its size: SizeOf= W x H x 4
'           -- better to save source image instead or compress the DIB bytes using favorite compression utility
'           -- with GDI+ or zLib, image can be converted to PNG for storage
'       - AlphaBlend API is not included/compatible with Win95, NT4 and lower
'       - AlphaBlend on Win9x systems can be buggy, especially when rendering to DIBs vs DDBs
' Note that GDI+ is standard on WinXP+, and can be used on Win98,ME,2K & on NT4 if SP6 is installed
' Download GDI+ from:
' http://msdn.microsoft.com/library/default.asp?url=/library/en-us/gdicpp/GDIPlus/GDIPlus.asp
' Download ZLib from: http://www.zlib.net

' ----------------------------------------------
' About Win95, Win98, WinME, NT3.5 & NT4 support
' ----------------------------------------------
' These routines may not honor AlphaBlend if it exists on those systems. Win98's version,
' for example, has several bugs that can crash the application when AlphaBlending to DIBs.
' NT4, NT3.5 & Win95 do not come with AlphaBlend and I do not have WinME to test with.
' Therefore, to support these older systems, the Render routine will alphablend manually
' regardless if the AlhpaBlend API exists on the older system or not. However, this can
' be overridden by you. See isAlphaBlendFriendly routine. Therefore, AlphaBlend is only
' reliable on Win2K and above. XP & above already have GDI+


' Class Purpose:
' ----------------------------------------------
' This class holds the 32bpp image. It also marshals any new image thru
' the battery of parsers to determine best method for converting the image
' to a 32bpp alpha-compatible image. It handles rendering, rotating, scaling,
' mirroring of DIBs using manual processes, AlphaBlend, and/or GDI+.

' The parser order is very important for fastest/best results...
' cPNGparser :: will convert PNG, all bit depths; aborts quickly if not PNG
' cGIFparser :: will convert non-transparent/transparent GIFs; aborts quickly
' cICOpraser :: will convert XP-Alpha, paletted, true color, & Vista PNG icons
'               -- can also convert most non-animated cursors
' cBMPparser :: will convert bitmaps, wmf/emf & jpgs

' As a last resort, when GDI+ exists, anything unable to be processed by the
' parsers (i.e., TIFFs) are sent to GDI+. If GDI+ can process the image, then
' the image will be converted, internally, to PNG to enable additional processing.

' The parsers are efficient. Most image formats have a magic number that give
'   a hint to what type of image the file/stream is. However, checks need to
'   be employed because non-image files could feasibly have those same magic
'   numbers. If the image is determined not to be one the parser is designed
'   to handle, the parser rejects it and the next parser takes over.  The
'   icon parser is slightly different because PNG files can be included into
'   a Vista ico file. When this occurs, the icon parser will pass off the
'   PNG format to the PNG parser automatically.
' And last but not least, the parsers have no advanced knowledge of the image
' format; as far as they are concerned, anything passed is just a byte array

' Class Organization:
' ----------------------------------------------
' Search the class for the words NEW SECTION
' The class routines are organized in the following sections:
'   Class Initialization & Termination Routines
'   Public Properties & Methods (almost 60 and growing)
'       Public Read-Only Properties
'       Public Methods
'       Class to Class Communication Methods
'   Local Support Functions
' ----------------------------------------------

' = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
'                                       CHANGE HISTORY
' = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
' Accompanying FAQ.rtf is updated with every change
' Last changed: 18 Nov 07. See change history within the FAQ file
' 26 Dec 06: First version
' = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =

' No APIs are declared public. This is to prevent possibly, differently
' declared APIs, or different versions of the same API, from conflicting
' with any APIs you declared in your project. Same rule for UDTs.
' Note: I did take liberties, changing parameter types, in several APIs throughout

' Used to determine operating system
Private Declare Function GetVersionEx Lib "kernel32" Alias "GetVersionExA" (lpVersionInformation As Any) As Long
Private Type OSVERSIONINFOEX
   dwOSVersionInfoSize As Long
   dwMajorVersion As Long
   dwMinorVersion As Long
   dwBuildNumber As Long
   dwPlatformId As Long
   szCSDVersion As String * 128 ' up to here is OSVERSIONINFO vs EX
   wServicePackMajor As Integer ' 8 bytes larger than OSVERSIONINFO
   wServicePackMinor As Integer
   wSuiteMask As Integer
   wProductType As Byte
   wReserved As Byte
End Type

' APIs used to manage the 32bpp DIB
Private Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory" (ByRef Destination As Any, ByRef Source As Any, ByVal Length As Long)
Private Declare Sub FillMemory Lib "kernel32.dll" Alias "RtlFillMemory" (ByRef Destination As Any, ByVal Length As Long, ByVal Fill As Byte)
Private Declare Function CreateCompatibleDC Lib "gdi32.dll" (ByVal hDC As Long) As Long
Private Declare Function GetDC Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function ReleaseDC Lib "user32.dll" (ByVal hwnd As Long, ByVal hDC As Long) As Long
Private Declare Function DeleteDC Lib "gdi32.dll" (ByVal hDC As Long) As Long
Private Declare Function SelectObject Lib "gdi32.dll" (ByVal hDC As Long, ByVal hObject As Long) As Long
Private Declare Function DeleteObject Lib "gdi32.dll" (ByVal hObject As Long) As Long
Private Declare Function CreateDIBSection Lib "gdi32.dll" (ByVal hDC As Long, ByRef pBitmapInfo As Any, ByVal un As Long, ByRef Pointer As Long, ByVal Handle As Long, ByVal dw As Long) As Long
Private Declare Function AlphaBlend Lib "msimg32.dll" (ByVal hdcDest As Long, ByVal nXOriginDest As Long, ByVal nYOriginDest As Long, ByVal nWidthDest As Long, ByVal nHeightDest As Long, ByVal hdcSrc As Long, ByVal nXOriginSrc As Long, ByVal nYOriginSrc As Long, ByVal nWidthSrc As Long, ByVal nHeightSrc As Long, ByVal lBlendFunction As Long) As Long
Private Declare Function SetStretchBltMode Lib "gdi32.dll" (ByVal hDC As Long, ByVal nStretchMode As Long) As Long
Private Declare Function GetObjectType Lib "gdi32.dll" (ByVal hgdiobj As Long) As Long
Private Declare Function GetCurrentObject Lib "gdi32.dll" (ByVal hDC As Long, ByVal uObjectType As Long) As Long
Private Declare Function GetIconInfo Lib "user32.dll" (ByVal hIcon As Long, ByRef piconinfo As ICONINFO) As Long
Private Declare Function BitBlt Lib "gdi32.dll" (ByVal hDestDC As Long, ByVal X As Long, ByVal Y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
Private Declare Function SetDIBitsToDevice Lib "gdi32.dll" (ByVal hDC As Long, ByVal X As Long, ByVal Y As Long, ByVal dX As Long, ByVal dY As Long, ByVal SrcX As Long, ByVal SrcY As Long, ByVal Scan As Long, ByVal NumScans As Long, ByRef Bits As Any, ByRef BitsInfo As BITMAPINFO, ByVal wUsage As Long) As Long
Private Declare Function GetDIBits Lib "gdi32.dll" (ByVal aHDC As Long, ByVal hBitmap As Long, ByVal nStartScan As Long, ByVal nNumScans As Long, ByRef lpBits As Any, ByRef lpBI As BITMAPINFO, ByVal wUsage As Long) As Long
Private Declare Function OffsetRgn Lib "gdi32.dll" (ByVal hRgn As Long, ByVal X As Long, ByVal Y As Long) As Long
Private Const STRETCH_HALFTONE As Long = &H4&
Private Const OBJ_BITMAP As Long = &H7&
Private Const OBJ_METAFILE As Long = &H9&
Private Const OBJ_ENHMETAFILE As Long = &HD&

' APIs used to create files
Private Declare Function WriteFile Lib "kernel32" (ByVal hFile As Long, lpBuffer As Any, ByVal nNumberOfBytesToWrite As Long, lpNumberOfBytesWritten As Long, lpOverlapped As Any) As Long
Private Declare Function CloseHandle Lib "kernel32" (ByVal hObject As Long) As Long
Private Declare Function GetFileSize Lib "kernel32.dll" (ByVal hFile As Long, ByRef lpFileSizeHigh As Long) As Long
Private Declare Function ReadFile Lib "kernel32.dll" (ByVal hFile As Long, ByRef lpBuffer As Any, ByVal nNumberOfBytesToRead As Long, ByRef lpNumberOfBytesRead As Long, ByRef lpOverlapped As Any) As Long
Private Declare Function SetFilePointer Lib "kernel32.dll" (ByVal hFile As Long, ByVal lDistanceToMove As Long, ByRef lpDistanceToMoveHigh As Long, ByVal dwMoveMethod As Long) As Long
Private Const INVALID_HANDLE_VALUE = -1&

' ////////////////////////////////////////////////////////////////
' Unicode-capable Drag and Drop of file names with wide characters
' ////////////////////////////////////////////////////////////////
Private Declare Function DispCallFunc Lib "oleaut32" (ByVal pvInstance As Long, _
    ByVal offsetinVft As Long, ByVal CallConv As Long, ByVal retTYP As VbVarType, _
    ByVal paCNT As Long, ByRef paTypes As Integer, _
    ByRef paValues As Long, ByRef retVAR As Variant) As Long
Private Declare Function lstrlenW Lib "kernel32.dll" (lpString As Any) As Long
Private Declare Function GlobalFree Lib "kernel32.dll" (ByVal hMem As Long) As Long

' ////////////////////////////////////////////////////////////////
' Unicode-capable Pasting of file names with wide characters
' ////////////////////////////////////////////////////////////////
Private Declare Function DragQueryFile Lib "shell32.dll" Alias "DragQueryFileA" (ByVal hDrop As Long, ByVal UINT As Long, ByVal lpStr As String, ByVal ch As Long) As Long
Private Declare Function OpenClipboard Lib "user32.dll" (ByVal hwnd As Long) As Long
Private Declare Function GetClipboardData Lib "user32.dll" (ByVal wFormat As Long) As Long
Private Declare Function CloseClipboard Lib "user32.dll" () As Long
Private Type FORMATETC
    cfFormat As Long
    pDVTARGETDEVICE As Long
    dwAspect As Long
    lIndex As Long
    TYMED As Long
End Type
Private Type DROPFILES
    pFiles As Long
    ptX As Long
    ptY As Long
    fNC As Long
    fWide As Long
End Type
Private Type STGMEDIUM
    TYMED As Long
    Data As Long
    pUnkForRelease As IUnknown
End Type
' ////////////////////////////////////////////////////////////////


' used to create the checkerboard pattern on demand
Private Declare Function FillRect Lib "user32.dll" (ByVal hDC As Long, ByRef lpRect As RECT, ByVal hBrush As Long) As Long
Private Declare Function CreateSolidBrush Lib "gdi32.dll" (ByVal crColor As Long) As Long
Private Declare Function OffsetRect Lib "user32.dll" (ByRef lpRect As RECT, ByVal X As Long, ByVal Y As Long) As Long
Private Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

' used when saving an image or part of the image
Private Declare Function VarPtrArray Lib "msvbvm60.dll" Alias "VarPtr" (Ptr() As Any) As Long
Private Type SafeArray
    cDims As Integer
    fFeatures As Integer
    cbElements As Long
    cLocks As Long
    pvData As Long
    rgSABound(0 To 3) As Long ' reusable UDT for 1 & 2 dim arrays
    ' array items: 0=1D item count, 1=1D LBound, 2=2D item count, 3=2D LBound
End Type

Private Type ICONINFO
    fIcon As Long
    xHotspot As Long
    yHotspot As Long
    hbmMask As Long
    hbmColor As Long
End Type
Private Type BITMAPINFOHEADER
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type
Private Type BITMAPINFO
    bmiHeader As BITMAPINFOHEADER
    bmiPalette As Long
End Type

Private Enum eOScapability
    osAlphaBlendUsable = 1  ' then AlphaBlend enabled & used when needed
    osGDIplusUsable = 2     ' then GDI+ enabled & used when needed (set in isGDIplusEnabled)
   'oszLIBusable = 4        ' then zLib enabled & can be used to create/read PNGs (no longer used, tested as needed)
    osWin2KorBetter = 8     ' AlphaBlend capable system else it isn't for these classes. See isAlphaBlendFriendly property for more info
    osWin98MEonly = 16      ' Win98 or WinME. When m_OScap includes osWin98MEonly+osAlphaBlendUsable then user overrode isAlphaBlendFriendly
    osGDIplusNotAvail = 32  ' then NT4 w/less than SP6 or Win95. Otherwise system is GDI+ capable else it isn't
    osIsNT = 64             ' NT-based system. Unicode compatible
End Enum

Public Enum eImageFormat    ' source image format
    imgError = -1  ' no DIB has been initialized
    imgNone = 0    ' no image loaded
    imgBitmap = 1  ' standard bitmap or jpg
    imgIcon = 3    ' standard icon
    imgWMF = 2     ' windows meta file
    imgEMF = 4     ' enhanced WMF
    imgCursor = 5  ' standard cursor
    imgBmpARGB = 6  ' 32bpp bitmap where RGB is not pre-multiplied
    imgBmpPARGB = 7 ' 32bpp bitmap where RGB is pre-multiplied
    imgIconARGB = 8 ' XP-type icon; 32bpp ARGB
    imgGIF = 9      ' gif; if class.Alpha=True, then transparent GIF
    imgPNG = 10     ' PNG image
    imgPNGicon = 11 ' PNG in icon file (Vista)
    imgCursorARGB = 12 ' alpha blended cursors? do they exist yet?
    imgCheckerBoard = 64 ' image is displaying own checkerboard pattern; no true image
End Enum

Public Enum ePngProperties      ' following are recognized "Captions" within a PNG file
    pngProp_Title = 1           ' See cPNGwriter.SetPngProperty for more information
    pngProp_Author = 2
    pngProp_Description = 4
    pngProp_Copyright = 8
    pngProp_CreationTime = 16
    pngProp_Software = 32
    pngProp_Disclaimer = 64
    pngProp_Warning = 128
    pngProp_Source = 256
    pngProp_Comment = 512
    ' special properties
    pngProp_Miscellaneous = 1024 ' this is free-form text can be of any length & contain most any characters
    pngProp_DateTimeModified = 2048  ' date/time of the last image modification (not the time of initial image creation)
    pngProp_DefaultBkgColor = 4096   ' default background color to use if PNG viewer does not do transparency
    pngProp_FilterMethod = 8192        ' one of the eFilterMethods values
    pngProp_ClearProps = -1     ' resets all PNG properties
End Enum

Public Enum eTrimOptions    ' see TrimImage method
    trimAll = 0             ' can be combined using OR
    trimLeft = 1
    trimTop = 2
    trimRight = 4
    trimBottom = 8
End Enum

Public Enum eScaleOptions   ' See ScaleImage method
    ScaleToSize = 0         ' [Default] will always scale
    scaleDownAsNeeded = 1   ' will only scale down if image won't fit
    ScaleStretch = 2        ' wll always stretch/distort
End Enum

Public Enum eGrayScaleFormulas
    gsclNTSCPAL = 0     ' R=R*.299, G=G*.587, B=B*.114 - Default
    gsclCCIR709 = 1     ' R=R*.213, G=G*.715, B=B*.072
    gsclSimpleAvg = 2   ' R,G, and B = (R+G+B)/3
    gsclRedMask = 3     ' uses only the Red sample value: RGB = Red / 3
    gsclGreenMask = 4   ' uses only the Green sample value: RGB = Green / 3
    gsclBlueMask = 5    ' uses only the Blue sample value: RGB = Blue / 3
    gsclRedGreenMask = 6 ' uses Red & Green sample value: RGB = (Red+Green) / 2
    gsclBlueGreenMask = 7 ' uses Blue & Green sample value: RGB = (Blue+Green) / 2
    gsclNone = -1
End Enum

Public Enum eFilterMethods
    filterDefault = 0     ' paletted PNGs will use filterNone while others will use filterPaeth
    filterNone = 1        ' no byte preparation used; else preps bytes using one of the following
    filterAdjLeft = 2     ' see cPNGwriter.EncodeFilter_Sub
    filterAdjTop = 3      ' see cPNGwriter.EncodeFilter_Up
    filterAdjAvg = 4      ' see cPNGwriter.EncodeFilter_Avg
    filterPaeth = 5       ' see cPNGwriter.EncodeFilter_Paeth
    filterAdaptive = 6    ' this is a best guess of the above 4 (can be different for each DIB scanline)
End Enum

Public Enum eRegionStyles     ' See CreateRegion
    regionBounds = 0
    regionEnclosed = 1
    regionShaped = 2
End Enum

Public Enum eConstants      ' See SourceIconSizes
    HIGH_COLOR = &HFFFF00
    TRUE_COLOR = &HFF000000
    TRUE_COLOR_ALPHA = &HFFFFFFFF
End Enum

Private m_Tag As Variant            ' user-defined, user usage only. See TAG property
Private m_PNGprops As cPNGwriter    ' used for more advanced PNG creation options
Private m_StretchQuality As Boolean ' if true will use BiLinear or better interpolation
Private m_Handle As Long        ' handle to 32bpp DIB
Private m_Pointer As Long       ' pointer to DIB bits
Private m_Height As Long        ' height of DIB
Private m_Width As Long         ' width of DIB
Private m_hDC As Long           ' DC if self-managing one
Private m_prevObj As Long       ' object deselected from DC when needed
Private m_osCAP As eOScapability ' See eOScapability enumeration above
Private m_Format As eImageFormat ' type of source image
Private m_ManageDC As Boolean   ' does class manage its own DC
Private m_AlphaImage As Boolean ' does the DIB contain alpha/transparency
Private m_GDItoken As Long
Private m_ImageByteCache() As Byte  ' should you want the DIB class to cache original bytes
' ^^ N/A if image is loaded by handle, stdPicture, or resource

Private m_GDIplus As cGDIPlus   ' maintains instance to speed up drawing
Private m_KeepGDIplusActive As Boolean

' NEW SECTION *******************************************************************************
'                   CLASS INITIALIZATION & TERMINATION ROUTINES
' *******************************************************************************************


Private Sub Class_Initialize()

    ' Determine operating system for compatibility of 32bpp images
    ' http://vbnet.mvps.org/code/helpers/iswinversion.htm
    ' http://msdn2.microsoft.com/en-gb/library/ms724834.aspx
    
   Dim osType As OSVERSIONINFOEX
   Const VER_PLATFORM_WIN32_WINDOWS As Long = 1

   ' Retrieve version data for OS.
   osType.dwOSVersionInfoSize = Len(osType)
   If GetVersionEx(osType) = 0 Then
      ' The OSVERSIONINFOEX structure is only supported
      ' in NT4/SP6+ and NT5.x, so we're likely running
      ' on an earlier version of Windows. Revert structure
      ' size to OSVERSIONINFO and try again.
      osType.dwOSVersionInfoSize = Len(osType) - 8
      Call GetVersionEx(osType)
   End If
   
    If osType.dwPlatformId = VER_PLATFORM_WIN32_WINDOWS Then

        If osType.dwMinorVersion = 0 Then ' Win95; can't use AlphaBlend nor GDI+
            m_osCAP = osGDIplusNotAvail

        Else ' flag as Alphablend disabled, but capable & is Win98/ME
            m_osCAP = osWin98MEonly
        End If

    Else

        If osType.dwMajorVersion > 4 Then ' if Win2K or better
            m_osCAP = osAlphaBlendUsable Or osWin2KorBetter ' flag as AlphaBlend enabled (Win2K or better) and capable

        Else ' WinNT4. If SP6 or better than GDI+ capable else not. Regardless, not AlphaBlend capable
            If osType.wServicePackMajor < 6 Then m_osCAP = osGDIplusNotAvail
        End If
        m_osCAP = m_osCAP Or osIsNT

    End If

    Me.isGDIplusEnabled = True  ' attempt to start GDI+, test system capability, add osGDIplusUsable to m_OScap
    If Me.isGDIplusEnabled Then Me.HighQualityInterpolation = True
    
    m_Format = imgError

End Sub

Private Sub Class_Terminate()
    DestroyDIB ' simply clean up
End Sub

' NEW SECTION *******************************************************************************
'                           PUBLIC PROPERTIES AND METHODS
' *******************************************************************************************


Public Property Let Alpha(isAlpha As Boolean)
    m_AlphaImage = isAlpha  ' determines the flags used for AlphaBlend API
    ' this flag is set by the various image parsers; setting it yourself
    ' can produce less than desirable effects.
    ' Used in Me.Render & Me.TrimImage, cPNGwriter.OptimizeTrueColor & cPNGwriter.PalettizeImage
End Property
Public Property Get Alpha() As Boolean
    Alpha = m_AlphaImage
End Property

Public Property Let HighQualityInterpolation(Value As Boolean)
    ' When possible GDI+ will be used for stretching & rotation.
    ' If GDI+ is used,then high quality equates to BiCubic interpolation
    ' If not used, then BiLinear (manual processing) will be used.
    ' If High Quality is false, then Nearest Neighbor (very fast, less quality) interpolation used
    m_StretchQuality = Value
End Property
Public Property Get HighQualityInterpolation() As Boolean
    HighQualityInterpolation = m_StretchQuality
End Property

Public Property Get ImageType() As eImageFormat
    ImageType = m_Format    ' returns image format of the source image
End Property
Friend Property Let ImageType(iType As eImageFormat)
    m_Format = iType    ' set by the various image parsers. This is not used
    ' anywhere in these classes, you can do with it what you want -- for now.
End Property

Public Property Let ManageOwnDC(bManage As Boolean)
    ' Determines whether or not this class will manage its own DC
    ' If false, then a DC is created each time the image needs to be Rendered
    Dim tDC As Long
    If bManage = False Then     ' removing management of DC
        If Not m_hDC = 0& Then   ' DC does exist, destroy it
            ' first remove the dib, if one exists
            If Not m_Handle = 0& Then SelectObject m_hDC, m_prevObj
            m_prevObj = 0&
        End If
        DeleteDC m_hDC
        m_hDC = 0&
    Else                        ' allowing creation of dc
        If m_hDC = 0& Then        ' create DC only if we have a dib to put in it
            If Not m_Handle = 0& Then
                tDC = GetDC(0&)
                m_hDC = CreateCompatibleDC(tDC)
                ReleaseDC 0&, tDC
            End If
        End If
    End If
    m_ManageDC = bManage
End Property
Public Property Get ManageOwnDC() As Boolean
    ManageOwnDC = m_ManageDC
End Property

Public Property Get isAlphaBlendFriendly() As Boolean
    isAlphaBlendFriendly = ((m_osCAP And osAlphaBlendUsable) = osAlphaBlendUsable)
    ' WinNT4 & below and Win95 are not shipped with msimg32.dll (AlphaBlend API)
    ' Win98 has bugs & would believe that WinME is buggy too but don't know for sure
    ' Therefore, the Rendering in this class will not use AlphaBlend on these
    ' operating systems even if the DLL exists, but will use GDI+ if available
    ' Can be overridden by setting this property to True
End Property
Public Property Let isAlphaBlendFriendly(Enabled As Boolean)
    ' This has been provided to override safety of using AlphaBlend on Win9x systems.
    ' Caution. Only set this when rendering to a known device dependent bitmap (DDB)
    ' Alphablend can crash when rendering DIB to DIB vs DIB to DDB. Be warned.
    If Enabled = True Then
        ' Overriding in play: allow AlphaBlend if system is Win98 or better
        ' By default this is already set for Win2K or better
        If ((m_osCAP And osWin2KorBetter) = osWin2KorBetter) Then
            m_osCAP = m_osCAP Or osAlphaBlendUsable
        ElseIf ((m_osCAP And osWin98MEonly) = osWin98MEonly) Then
            m_osCAP = m_osCAP Or osAlphaBlendUsable
        End If
    Else
        m_osCAP = m_osCAP And Not osAlphaBlendUsable ' disallow AlphaBlend
    End If
End Property
Public Property Get isGDIplusEnabled() As Boolean
    ' identifies if GDI+ is usable on the system.
    ' Before this property is set, GDI+ is tested to ensure it is usable
    isGDIplusEnabled = ((m_osCAP And osGDIplusUsable) = osGDIplusUsable)
End Property
Public Property Let isGDIplusEnabled(Enabled As Boolean)
    ' Sets the property. If set to False by you, GDI+ will not be used
    ' for any rendering, but still may be used to create PNG files if needed
    
    ' You can reset it to true at any time. If the system won't support
    ' GDI+, then the True setting will simply be ignored -- no harm, no foul
    ' To test success:  c32class.isGDIplusEnabled=True: If c32class.isGDIplusEnabled=True Then ' success
    
    ' Note. My GDI+ dll works on Win95. Therefore, the O/S capabilities check below
    ' has been removed to create a hard test vs simply assuming
    
    If Not Enabled = Me.isGDIplusEnabled Then
        m_osCAP = (m_osCAP And Not osGDIplusUsable)
        If Enabled Then
'            If (m_osCAP And osGDIplusNotAvail) = 0 Then ' else Win95, NT4 SP5 or lower
                Dim cGDIp As cGDIPlus
                If m_GDIplus Is Nothing Then
                    Set cGDIp = New cGDIPlus
                Else
                    Set cGDIp = m_GDIplus
                End If
                If cGDIp.isGDIplusOk() = True Then m_osCAP = m_osCAP Or osGDIplusUsable
'            End If
        End If
    End If
End Property

Public Property Let gdiToken(Token As Long)
    ' Everytime a GDI+ API function is called, the class calls GDI+ apis to
    ' create a GDI+ token first then destroys the token after the function is called.
    
    ' This occurs quite often. However, you can create your own token by calling
    ' GdiplusStartup and then passing the token to each class for the class to use.
    ' You would call GdiplusShutdown during your main form's Terminate event to
    ' release the Token.
    
    ' When Token is zero, the classes will revert to creating a token on demand.
    ' When the Token is not zero, any other DIB class created by this class will
    ' pass the token as needed. The only routine that can create a new instance and
    ' returns that new instance is the CreateDropShadow method. You must set the
    ' token for that class at some point for that dropshadow class to use it.
    
    m_GDItoken = Token
    
End Property
Public Property Get gdiToken() As Long
    ' returns the GDI+ token if one was created
    gdiToken = m_GDItoken
End Property

Public Property Let Tag(vValue As Variant)
    If IsObject(vValue) Then
        Set m_Tag = vValue
    Else
        m_Tag = vValue
    End If
End Property
Public Property Set Tag(vValue As Variant)
    Me.Tag = vValue ' use the object check in the Let property
End Property
Public Property Get Tag() As Variant
    If IsObject(m_Tag) Then
        Set Tag = m_Tag
    Else
        Tag = m_Tag
    End If
End Property


' NEW SECTION *******************************************************************************
'                               PUBLIC READ-ONLY PROPERTIES
' *******************************************************************************************

Public Property Get Width() As Long
    Width = m_Width     ' width of image in pixels
End Property
Public Property Get Height() As Long
    Height = m_Height   ' height of image in pixels
End Property
Public Property Get BitsPointer() As Long
    BitsPointer = m_Pointer ' pointer to the bits of the image
End Property
Public Property Get scanWidth() As Long
    scanWidth = m_Width * 4&    ' number of bytes per scan line
End Property
Public Property Get Handle() As Long
    Handle = m_Handle   ' the picture handle of the image
End Property
Public Property Get isZlibEnabled() As Boolean
    ' Read Only
    ' To create PNG files, GDI+ or zLib is required. This property informs
    ' you if zLIB exists in the system's DLL path
    isZlibEnabled = iparseValidateZLIB(vbNullString, 0, False, False, True)
    
End Property

' This setting will keep the current cGDI+ class active which
' prevents destroying the GDI+ hImage and Token objects.  This
' can speed up rendering. This option SHOULD NOT be set when the
' class is not compiled. Else crashes will happen when
' user hits END or VB toolbar's STOP button while in IDE
Public Property Get KeepGDIplusActive() As Boolean
    KeepGDIplusActive = m_KeepGDIplusActive
End Property
Public Property Let KeepGDIplusActive(keepActive As Boolean)
    m_KeepGDIplusActive = keepActive
    If keepActive = False Then
        Set m_GDIplus = Nothing
    ElseIf Me.isGDIplusEnabled = False Then
        ' can't set to True if GDI+ not installed
        m_KeepGDIplusActive = False
    End If
End Property


' NEW SECTION *******************************************************************************
'                                       PUBLIC METHODS
' *******************************************************************************************

Public Function LoadPicture_File(ByVal FileName As String, _
                                Optional ByVal iconCx As Long, _
                                Optional ByVal iconCy As Long, _
                                Optional ByVal SaveFormat As Boolean, _
                                Optional ByVal iconBitDepth As Long = 32) As Boolean

    ' PURPOSE: Convert passed image file into a 32bpp image
    
    ' Parameters.
    ' FileName :: full path of file. Validation occurs before we continue
    ' iconCx :: desired width of icon if file is an icon file. Default is 32x32
    ' iconCy :: desired height of icon if file is an icon file. Default is 32x32
    ' SaveFormat :: if true, then the image will be cached as a byte array only
    '   if the image was successfully loaded. Call GetOrginalFormat to retrieve them.
    ' iconBitDepth :: the desired bit depth of an icon if the resource is an icon file
    
    ' Why would you want to save the bytes? If this is being used in a usercontrol,
    ' saving the bytes will almost always be less size than saving the 32bit DIB.
    ' Additionally, these classes have the ability to get different sizes from
    ' the original source (i.e., WMF, icon, cursors) if available, but if the
    ' 32bit DIB is saved, it is a constant size. The potential of different sizes
    ' could allow better resizing of the image vs stretching the DIB.

    On Error Resume Next
    Dim hFile As Long
    
    hFile = iparseGetFileHandle(FileName, True, ((m_osCAP And osIsNT) = osIsNT))
    If hFile = INVALID_HANDLE_VALUE Then Exit Function
    
    If GetFileSize(hFile, 0&) > 56 Then
        
        ' no image file/stream can be less than 57 bytes and still be an image
        Dim aDIB() As Byte  ' dummy array
        LoadPicture_File = spt_LoadPictureEx(hFile, FileName, aDIB(), iconCx, iconCy, 0&, 0&, SaveFormat, iconBitDepth)
    
    End If
    CloseHandle hFile
    
End Function

Public Function LoadPicture_Stream(inStream() As Byte, _
                                    Optional ByVal iconCx As Long, _
                                    Optional ByVal iconCy As Long, _
                                    Optional ByVal streamStart As Long = 0&, _
                                    Optional ByVal streamLength As Long = 0&, _
                                    Optional ByVal SaveFormat As Boolean, _
                                    Optional ByVal iconBitDepth As Long = 32) As Boolean
    
    ' PURPOSE: Convert passed array into a 32bpp image
    
    ' Parameters.
    ' inStream:: byte stream containing the image. Validation occurs below
    ' iconCx :: desired width of icon if file is an icon file. Default is 32x32
    ' iconCy :: desired height of icon if file is an icon file. Default is 32x32
    ' streamStart :: array position of 1st byte of the image file. Validated.
    ' streamLength :: total length of the image file. Validated.
    ' SaveFormat :: if true, then the image will be cached as a byte array only
    '   if the image was successfully loaded. Call GetOrginalFormat to retrieve them.
    ' iconBitDepth :: the desired bit depth of an icon if the resource is an icon stream
    
    ' Why would you want to save the bytes? If this is being used in a usercontrol,
    ' saving the bytes will almost always be less size than saving the 32bit DIB.
    ' Additionally, these classes have the ability to get different sizes from
    ' the original source (i.e., WMF, icon, cursors) if available, but if the
    ' 32bit DIB is saved, it is a constant size. The potential of different sizes
    ' could allow better resizing of the image vs stretching the DIB.
    
    If iparseIsArrayEmpty(VarPtrArray(inStream)) = 0& Then Exit Function
    If streamStart < LBound(inStream) Then streamStart = LBound(inStream)
    If streamLength = 0& Then streamLength = UBound(inStream) - streamStart + 1&
    If streamLength < 57 Then Exit Function
    ' no image file/stream can be less than 57 bytes and still be an image
    LoadPicture_Stream = spt_LoadPictureEx(0&, vbNullString, inStream, iconCx, iconCy, streamStart, streamLength, SaveFormat, iconBitDepth)

End Function

Public Function LoadPicture_Resource(ByVal ResIndex As Variant, ByVal ResSection As Variant, _
                            Optional VBglobal As IUnknown, _
                            Optional ByVal iconCx As Long, _
                            Optional ByVal iconCy As Long, _
                            Optional ByVal streamStart As Long = 0&, _
                            Optional ByVal streamLength As Long = 0&, _
                            Optional ByVal iconBitDepth As Long = 32) As Boolean

    ' PURPOSE: Convert passed resource into a 32bpp image
    
    ' Parameters.
    ' ResIndex :: the resource file index (i.e., 101)
    ' ResSection :: one of the VB LoadResConstants or String value of
    '       your resource section, i.e., vbResBitmap, vbResIcon, "Custom", etc
    ' VbGlobal :: pass as VB.GLOBAL of the project containing the resource file
    '       - Allows class to be mobile; can exist in DLL or OCX
    '       - if not provided, class will use resource from existing workspace
    '       - For example, if this class was in a compiled OCX, then the only way
    '           to use the host's resource file is passing the host's VB.Global reference
    ' iconCx :: desired width of icon if file is an icon file. Default is 32x32
    ' iconCy :: desired height of icon if file is an icon file. Default is 32x32
    ' streamStart :: array position of 1st byte of the image file. Validated.
    ' streamLength :: total length of the image file. Validated.
    '   -- See LoadPicture_Stream for the validation
    ' iconBitDepth :: the desired bit depth of an icon if the resource is an icon
    
    ' Tips:
    ' 1) Store 32bpp bitmaps in the "Custom" resource always. Storing in the
    '       Bitmap resource can change color depth of the image created by VB
    '       depending on your screen settings
    ' 2) Icons, normal bitmaps, & cursors are generally stored in their own sections
    '       However, with icons containing multiple formats, VB will extract the
    '       closest format to 32x32. May want to consider storing these in "Custom"
    ' 3) All other types of images are normally stored in the "Custom" section

    On Error GoTo ExitRoutine
    
    Dim oWorkSpace As VB.Global, tPic As StdPicture
    
    If VBglobal Is Nothing Then
        Set oWorkSpace = VB.Global
    ElseIf TypeOf VBglobal Is VB.Global Then
        Set oWorkSpace = VBglobal
    Else
        Set oWorkSpace = VB.Global
    End If
    
    If VarType(ResSection) = vbString Then
        Dim inStream() As Byte
        ' could be anything, PNG,icon,gif,32bpp bitmap,wmf, etc
        inStream = oWorkSpace.LoadResData(ResIndex, ResSection)
        LoadPicture_Resource = LoadPicture_Stream(inStream, iconCx, iconCy, streamStart, streamLength, , iconBitDepth)
    Else
        ' can only be single icon, bitmap or cursor
        Set tPic = oWorkSpace.LoadResPicture(ResIndex, ResSection)
        LoadPicture_StdPicture tPic
    End If
    LoadPicture_Resource = Not (m_Handle = 0&)
    
ExitRoutine:
    If Err Then Err.Clear
End Function

Public Function LoadPicture_StdPicture(Picture As StdPicture) As Boolean

    ' PURPOSE: Convert passed stdPicture into a 32bpp image
    ' Revised to allow 32bpp stdPicture objects which can be loaded
    
    Me.DestroyDIB
    If Not Picture Is Nothing Then
        ' simply pass off to other parsers
        If Picture.Type = vbPicTypeIcon Then
            ' pass to icon/cursor parser
            Dim cICO As New cICOparser
            Call cICO.ConvertstdPicTo32bpp(Picture.Handle, Me)
            Set cICO = Nothing
        ElseIf Not Picture.Type = vbPicTypeNone Then
            ' pass to bmp,jpg,wmf parser
            ' Note: transparent GIFs should not be passed as stdPictures
            '   Pass transparent GIFs by Stream or FileName
            Dim cBMP As New cBMPparser
            If Picture.Type = vbPicTypeBitmap Then
                ' pass by handle to ensure 32bpp stdPicture objects are processed correctly
                Call cBMP.ConvertstdPicTo32bpp(Nothing, Picture.Handle, Me, 0&)
            Else ' probably wmf/emf, pass by stdPicture
                Call cBMP.ConvertstdPicTo32bpp(Picture, 0&, Me, 0&)
            End If
            Set cBMP = Nothing
        End If
        LoadPicture_StdPicture = Not (m_Handle = 0&)
    End If
    

End Function

Public Function LoadPicture_ByHandle(Handle As Long) As Boolean

    ' PURPOSE: Convert passed image handle into a 32bpp image
    ' Revised. Previously, I cheated by creating a stdPicture from the handle
    '           then used existing LoadPicture_stdPicture to process. This had
    '           the nasty side effect of not processing 32bpp images correctly
    '           if they were loaded from LoadImage API

    Dim icoInfo As ICONINFO, tPic As StdPicture
    DestroyDIB
    If Not Handle = 0& Then
        Select Case GetObjectType(Handle)
        Case OBJ_BITMAP
            ' process bitmaps by handle
            Dim cBMP As New cBMPparser
            LoadPicture_ByHandle = cBMP.ConvertstdPicTo32bpp(Nothing, Handle, Me, 0&)
        Case OBJ_METAFILE, OBJ_ENHMETAFILE
            ' we should be able to convert this to a stdPicture...
            ' Really don't want to mess with metafile DCs if I don't have to
            Set tPic = iparseHandleToStdPicture(Handle, vbPicTypeBitmap)
            If Not tPic Is Nothing Then
                ' send to this routine to process
                LoadPicture_ByHandle = LoadPicture_StdPicture(tPic)
            End If
        Case Else
            ' Test for icons & cursors
            If Not GetIconInfo(Handle, icoInfo) = 0 Then
                ' got it; clean up the bitmap(s) created by GetIconInfo API
                If Not icoInfo.hbmColor = 0& Then DeleteObject icoInfo.hbmColor
                If Not icoInfo.hbmMask = 0& Then DeleteObject icoInfo.hbmMask
                Dim cICO As New cICOparser
                ' process icons by handle
                LoadPicture_ByHandle = cICO.ConvertstdPicTo32bpp(Handle, Me)
            End If
        End Select
    End If
    
End Function

Public Function LoadPicture_ClipBoard() As Boolean
    
    ' PURPOSE: Convert clipboard object into a 32bpp image

    On Error Resume Next
    With Clipboard
        If (.GetFormat(vbCFBitmap) Or .GetFormat(vbCFDIB) Or .GetFormat(vbCFEMetafile) Or .GetFormat(vbCFMetafile)) Then
            If Not Err Then LoadPicture_ClipBoard = LoadPicture_StdPicture(.GetData())
        End If
    End With
    If Err Then Err.Clear
End Function

Public Function LoadPicture_FromOrignalFormat(Optional ByVal iconCx As Long, _
                            Optional ByVal iconCy As Long, _
                            Optional ByVal iconBitDepth As Long) As Boolean

    ' PURPOSE: Reload the current image from the cached bytes (if any)
    ' If the original bytes were not cached when the image was loaded, then no action
    ' will be taken.  See LoadPicture_File & LoadPicture_Stream
    
    ' iconCx :: desired width of icon if file is an icon file. Default is 32x32
    ' iconCy :: desired height of icon if file is an icon file. Default is 32x32
    ' iconBitDepth :: the desired bit depth of an icon if the resource is an icon
    
    Dim tBytes() As Byte
    tBytes() = m_ImageByteCache() ' copy bytes; original are destroyed when DIB is recreated
    LoadPicture_FromOrignalFormat = Me.LoadPicture_Stream(tBytes, iconCx, iconCy, , , True, iconBitDepth)
    
End Function

Public Sub ScaleImage(ByVal destWidth As Long, ByVal destHeight As Long, newWidth As Long, newHeight As Long, Optional ByVal ScaleMode As eScaleOptions = scaleDownAsNeeded)
                            
    ' Purpose: Returns the width and height needed to draw the image to the requested dimensions.
    ' The actual image is not modified.
    
    ' Function should be called before .Render or .Resize should you want to scale the image.
    ' Additionally, scaling can assist in positioning image too, i.e., centering.
    
    ' destWidth [in]:: the width of the target canvas (drawing area)
    ' destHeight [in]:: the height the target canvas
    ' NewWidth [out]:: returns the width to use for the supplied ScaleMode
    ' NewHeight [out]:: returns the height to use for the supplied ScaleMode
    ' ScaleMode [in]::
    '   scaleToSize [Default] - will always proportionally stretch the image to the target canvas size
    '   scaleDownAsNeeded - will only shrink the image if needed; otherwise the original image size is passed
    '   scaleStretch - the return value is always the canvas width and height; image distortion can occur
                            
    If m_Handle = 0& Then Exit Sub
    
    Dim ratioX As Single, ratioY As Single
    ' calculate scale and offsets
    Select Case ScaleMode
    
    Case scaleDownAsNeeded, ScaleToSize: ' scaled
        ratioX = destWidth / m_Width
        ratioY = destHeight / m_Height
        If ScaleMode = scaleDownAsNeeded Then
            If ratioX > 1 And ratioY > 1 Then
                ratioX = 1: ratioY = ratioX
            End If
        End If
        If ratioX > ratioY Then ratioX = ratioY
        newWidth = Int(ratioX * m_Width)
        newHeight = Int(ratioX * m_Height)
    
        ' To center your image in the target canvas: Use the passed & returned parameters like so:
        ' canvasX = (destWidth - NewWidth) \ 2 + any Left offset you may be using
        ' canvasY = (destHeight - NewHeight) \ 2 + any Top offset you may be using
        ' returned results would then be passed to Render like so:
        '       class.Render canvasX, canvasY, NewWidth, NewHeight, .... additional optional parameters
        
    Case ScaleStretch
        newWidth = destWidth
        newHeight = destHeight
    
    Case Else
        newWidth = m_Width
        newHeight = m_Height
        
    End Select


End Sub

Public Function GetPixel(ByVal X As Long, ByVal Y As Long, Optional ByRef AlphaValue As Long, _
                            Optional ByRef asPreMultiplied As Boolean) As Long

    ' Function will return the pixel color value and alpha value from the DIB
    ' Note that the DIB is always referenced top down within this function
    
    ' X is the left coordinate of the pixel to be returned, image always starts at 0,0
    ' Y is the top coordinate of the pixel to be returned, image always starts at 0,0
    ' AlphaValue will contain the alpha value of the pixel.
    ' asPreMultiplied. If false, then premultiplication is removed else it isn't
    
    ' Return value is the RGB color value of the pixel.
    ' If return value is -1 then the X,Y coordinates passed are invalid
    
    ' It is far more efficient to use GetDIBits or overlaying your own array when more than
    ' one pixel is required to be returned; in other words, recommend not using this
    ' function within a loop
    
    AlphaValue = 0&
    If X < 0& Or X > m_Width - 1& Then
        GetPixel = -1&
    ElseIf Y < 0& Or Y > m_Height - 1& Then
        GetPixel = -1&
    Else
        Dim pOffset As Long, pColor As Long
        ' calculate the location of the X,Y coordinate in relation to a bottom-up DIB
        pOffset = iparseSafeOffset(m_Pointer, X * 4& + ((m_Height - Y - 1&) * m_Width * 4&))
        
        ' get the alpha value
        CopyMemory AlphaValue, ByVal iparseSafeOffset(pOffset, 3&), 1&
        
        ' get the pixel color & convert it to RGB
        CopyMemory pColor, ByVal pOffset, 3&
        If asPreMultiplied = True Or (AlphaValue Mod 255) = 0 Then
            GetPixel = ((pColor And &HFF) * &H10000) Or ((pColor \ &H100) And &HFF) * &H100 Or ((pColor \ &H10000) And &HFF)
        Else    ' remove premultiplication
            pOffset = ((255& * (pColor And &HFF)) \ AlphaValue) * &H10000
            pOffset = pOffset Or ((255& * ((pColor \ &H100) And &HFF)) \ AlphaValue) * &H100
            GetPixel = pOffset Or ((255& * ((pColor \ &H10000) And &HFF)) \ AlphaValue)
        End If
    End If

End Function

Public Function GetDIBbits(outStream() As Byte, _
                Optional ByVal as2dArray As Boolean = True, _
                Optional ByVal asBGRformat As Boolean = True, _
                Optional ByVal as32bpp As Boolean = True, _
                Optional ByVal asWordAligned As Boolean = True, _
                Optional ByVal asBottomUp As Boolean = True, _
                Optional ByVal X As Long, Optional ByVal Y As Long, _
                Optional ByVal Width As Long, Optional ByVal Height As Long, _
                Optional ByVal asPreMultiplied As Boolean = True) As Boolean
                
    ' Function replicates the GetDIBits API with more flexibility.
    ' Note: Unless you need a copy of the bytes for other purposes than just
    ' referencing them, it is much more efficient to overlay your own
    ' SafeArray on the Me.BitsPointer property vs copying the bytes into an array
    
    ' Function returns True if an image exists and the array was filled.
    
    ' Parameters
    ' outStream(). An array to hold the returned bytes. Array is always zero-bound
    ' as2dArray. If True, array is returned as (0 to Columns*4-1, 0 to Rows-1) else (0 to Columns*Rows*4-1)
    ' asBGRformat. If True, pixels are in BGRalpha format else RGBalpha format
    '              The alpha byte may be excluded depending on as32bpp parameter
    ' as32bpp. If true, pixels use 4 bytes else pixels use 3 bytes (24bpp)
    ' asWordAligned. If true, scanlines/columns are word aligned else scanlines are byte aligned
    ' asBottomUp. If true, 1st row of array is bottom of picture else is top of picture
    ' X,Y. The left,top position of the image to return
    ' Width,Height. The number of columns,rows to return. Defaults are entire image
    ' asPreMultiplied. If true, returned pixels are in their default state, premultiplied
    '                  If false, premultiplication is removed.
    
    ' Tip: How to determine the scanwidth of the returned rows?
    ' 1. If as32bpp=True, then it is always Width parameter x 4
    ' 2. Otherwise, regardless of asWordAligned parameter
    '   a. If as2dArray=True, UBound(outStream,1)+1
    '   b. If as2dArray=False, (UBound(outStream)+1)\Height parameter
    
    If m_Handle = 0& Then Exit Function
    If X < 0& Or Y < 0& Then Exit Function
    
    Dim dstX As Long, dstY As Long
    Dim dstYincr As Long, bytesPP As Long
    Dim dstScanWidth As Long, srcScanWidth As Long
    
    Dim dstBytes() As Byte, srcBytes() As Byte
    Dim dstSA As SafeArray, srcSA As SafeArray
    
    Dim Rows As Long, Cols As Long, pAlpha As Byte
    
    ' validate parameters
    If Width = 0 Then Width = m_Width
    If Height = 0 Then Height = m_Height
    If Width + X > m_Width Then Width = m_Width - X
    If Height + Y > m_Height Then Height = m_Height - Y
    ' now we will set up the scanwidth and dimensioning the return array
    If as32bpp = True Then
        bytesPP = 4&
        dstScanWidth = Width * bytesPP
    Else
        bytesPP = 3&
        If asWordAligned = True Then
            dstScanWidth = iparseByteAlignOnWord(24, Width)
        Else
            dstScanWidth = Width * bytesPP
        End If
    End If
    ' size the destination array
    If as2dArray = True Then
        ReDim outStream(0 To dstScanWidth - 1&, 0 To Height - 1&)
        dstSA.pvData = VarPtr(outStream(0, 0)) ' track pointer of 1st element
    Else
        ReDim outStream(0 To dstScanWidth * Height - 1&)
        dstSA.pvData = VarPtr(outStream(0)) ' track pointer of 1st element
    End If
    
    ' quick check for copying. This is probably going to be most used
    If as32bpp = True And asBGRformat = True And asBottomUp = True Then
        If Width = m_Width And Height = m_Height And asPreMultiplied = True Then
            If as2dArray = True Then
                CopyMemory outStream(0, 0), ByVal m_Pointer, scanWidth * Height
            Else
                CopyMemory outStream(0), ByVal m_Pointer, scanWidth * Height
            End If
            GetDIBbits = True
            Exit Function
        End If
    End If
    
    ' set up overlays using identical 2D arrays
    iparseOverlayHost_Byte dstBytes, VarPtr(dstSA), 2, Height, dstScanWidth, dstSA.pvData ' overlay DMA array
    iparseOverlayHost_Byte srcBytes, VarPtr(srcSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    
    ' calculate destination starting row
    If asBottomUp = True Then
        dstY = Height - 1&
        dstYincr = -1&
    Else
        dstYincr = 1&
    End If
    
    srcScanWidth = (Width + X) * 4& - 1& ' position of 1st byte in DIB
    If asPreMultiplied = True Then
        For Rows = m_Height - Y - 1& To m_Height - Height - Y Step -1&
            dstX = 0&   ' destination column
            For Cols = X * 4 To srcScanWidth Step 4&
                If asBGRformat = True Then
                    CopyMemory dstBytes(dstX, dstY), srcBytes(Cols, Rows), bytesPP
                Else
                    dstBytes(dstX, dstY) = srcBytes(Cols + 2&, Rows)
                    dstBytes(dstX + 1&, dstY) = srcBytes(Cols + 1&, Rows)
                    dstBytes(dstX + 2&, dstY) = srcBytes(Cols, Rows)
                    If bytesPP = 4& Then ' want the alpha array too
                        dstBytes(dstX + 3&, dstY) = srcBytes(Cols + 3&, Rows)
                    End If
                End If
                dstX = dstX + bytesPP ' move to next destination column
            Next
            dstY = dstY + dstYincr ' next destination row
        Next
    
    Else        ' remove premultiplication
        
        For Rows = m_Height - Y - 1& To m_Height - Height - Y Step -1&
            dstX = 0&   ' destination column
            For Cols = X * 4 To srcScanWidth Step 4&
                pAlpha = srcBytes(Cols + 3&, Rows)
                If asBGRformat = True Then
                    If pAlpha = 255 Then
                        CopyMemory dstBytes(dstX, dstY), srcBytes(Cols, Rows), 3&
                    ElseIf Not pAlpha = 0 Then
                        dstBytes(dstX, dstY) = (255& * srcBytes(Cols, Rows) \ pAlpha)
                        dstBytes(dstX + 1&, dstY) = (255& * srcBytes(Cols + 1&, Rows) \ pAlpha)
                        dstBytes(dstX + 2&, dstY) = (255& * srcBytes(Cols + 2&, Rows) \ pAlpha)
                    End If
                Else        ' convert to RGB
                    If pAlpha = 255 Then
                        dstBytes(dstX, dstY) = srcBytes(Cols + 2&, Rows)
                        dstBytes(dstX + 1&, dstY) = srcBytes(Cols + 1&, Rows)
                        dstBytes(dstX + 2&, dstY) = srcBytes(Cols, Rows)
                    ElseIf Not pAlpha = 0 Then
                        dstBytes(dstX, dstY) = (255& * srcBytes(Cols + 2&, Rows) \ pAlpha)
                        dstBytes(dstX + 1&, dstY) = (255& * srcBytes(Cols + 1&, Rows) \ pAlpha)
                        dstBytes(dstX + 2&, dstY) = (255& * srcBytes(Cols, Rows) \ pAlpha)
                    End If
                End If
                If bytesPP = 4& Then dstBytes(dstX + 3&, dstY) = pAlpha   ' want the alpha array too
                dstX = dstX + bytesPP ' move to next destination column
            Next
            dstY = dstY + dstYincr ' next destination row
        Next
    End If
    ' release arrays
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    GetDIBbits = True

eh:
    If Err Then
        Err.Clear
        'Stop           ' troubleshooting only
        'Resume
    End If
End Function

Public Function SetPixel(ByVal X As Long, ByVal Y As Long, ByVal Color As Long, _
                Optional ByVal AlphaValue As Long = 255, Optional ByVal isPreMultiplied As Boolean) As Long

    ' Function will set the pixel color value and alpha value to the DIB
    ' Note that the DIB is always referenced top down within this function
    
    ' X is the left coordinate of the pixel to be set, image always starts at 0,0
    ' Y is the top coordinate of the pixel to be set, image always starts at 0,0
    ' Color is the color to be set and must be a valid RGB color value
    ' AlphaValue is the desired opacity of the pixel between 0 and 255
    ' isPreMultiplied when True, then Color has been premultiplied against the AlphaValue
    
    ' Return value is non-zero if the pixel was set, otherwise the return value is zero
    
    ' It is far more efficient to use SetDIBits or overlaying your own array when more than
    ' one pixel is required to be set; in other words, recommend not using this
    ' function within a loop
    
    If m_Handle = 0& Then Exit Function
    
    Dim pOffset As Long
    Dim bRGB(0 To 3) As Byte
    
    If AlphaValue > -1& And AlphaValue < 256& Then
        If X > -1& And X < m_Width Then
            If Y > -1& And Y < m_Height Then
                ' calculate the location of the X,Y coordinate in relation to a bottom-up DIB
                pOffset = iparseSafeOffset(m_Pointer, X * 4& + ((m_Height - Y - 1&) * m_Width * 4&))
                If Not AlphaValue = 0& Then
                    ' extract RGB parts and  convert to BGR
                    
                    If isPreMultiplied = True Or AlphaValue = 255 Then ' validate it, leave nothing to chance
                    
                        bRGB(2) = Color And &HFF
                        If bRGB(2) > AlphaValue Then bRGB(2) = AlphaValue * bRGB(2) \ &HFF
                        bRGB(1) = (Color \ &H100) And &HFF
                        If bRGB(1) > AlphaValue Then bRGB(1) = AlphaValue * bRGB(1) \ &HFF
                        bRGB(0) = (Color \ &H10000) And &HFF
                        If bRGB(0) > AlphaValue Then bRGB(0) = AlphaValue * bRGB(0) \ &HFF
                        
                    Else ' premultiply against the alpha
                        bRGB(2) = ((AlphaValue * (Color And &HFF)) \ &HFF) And &HFF             ' set red
                        bRGB(1) = ((AlphaValue * ((Color \ &H100) And &HFF)) \ &HFF) And &HFF   ' set green
                        bRGB(0) = ((AlphaValue * ((Color \ &H10000) And &HFF)) \ &HFF) And &HFF ' set blue
                        
                    End If
                    bRGB(3) = AlphaValue
                    If Not AlphaValue = 255 Then m_AlphaImage = True
                Else
                    m_AlphaImage = True
                End If
                CopyMemory ByVal pOffset, bRGB(0), 4&
            End If
        End If
    End If
    SetPixel = pOffset

End Function

Public Function SetDIBbits(inStream() As Byte, _
                Optional ByVal isBGRformat As Boolean = True, _
                Optional ByVal is32bpp As Boolean = True, _
                Optional ByVal isWordAligned As Boolean = True, _
                Optional ByVal isBottomUp As Boolean = True, _
                Optional ByVal dstX As Long, Optional ByVal dstY As Long, _
                Optional ByVal dstWidth As Long, Optional ByVal dstHeight As Long) As Boolean
                
    ' Function replicates the SetDIBits API with more flexibility.
    ' Note: It is much more efficient to overlay your own SafeArray on
    ' the Me.BitsPointer property and updating directly
    
    ' Function returns True if an image exists and updated.
    
    ' Parameters
    ' inStream(). An array containing new DIB bytes. Can be any dimension
    ' isBGRformat. If True, pixels are in BGRalpha format else RGBalpha format
    '              The alpha byte may be excluded depending on is32bpp parameter
    ' is32bpp. If true, pixels use 4 bytes else pixels use 3 bytes (24bpp)
    ' isWordAligned. If true, scanlines are word aligned else scanlines are byte aligned
    ' isBottomUp. If true, 1st row of array is bottom of picture else is top of picture
    ' dstX,Y. The left,top position of the image to update
    ' dstWidth,Height. The number of columns,rows to update. Defaults are entire image
    
    If m_Handle = 0& Then Exit Function
    If dstX < 0& Or dstY < 0& Then Exit Function
    
    Dim SrcX As Long, SrcY As Long
    Dim srcYincr As Long, bytesPP As Long
    Dim dstScanWidth As Long, srcScanWidth As Long
    
    Dim dstBytes() As Byte, srcBytes() As Byte
    Dim dstSA As SafeArray, srcSA As SafeArray
    Dim srcBounds() As Long
    
    Dim Rows As Long, Cols As Long
    
    ' test and cache the passed inStream's pointer
    srcYincr = iparseIsArrayEmpty(VarPtrArray(inStream))
    If srcYincr = 0& Then Exit Function
    
    ' validate parameters
    If dstWidth = 0 Then dstWidth = m_Width
    If dstHeight = 0 Then dstHeight = m_Height
    If dstWidth + dstX > m_Width Then dstWidth = m_Width - dstX
    If dstHeight + dstY > m_Height Then dstHeight = m_Height - dstY
    
    ' now we will set up the scanwidth of the source array
    If is32bpp = True Then
        bytesPP = 4&
        srcScanWidth = dstWidth * bytesPP
    Else
        bytesPP = 3&
        If isWordAligned = True Then
            srcScanWidth = iparseByteAlignOnWord(24, dstWidth)
        Else
            srcScanWidth = dstWidth * bytesPP
        End If
    End If
    ' Get 1st 16 bytes of source SafeArray
    CopyMemory srcSA, ByVal srcYincr, 16&
    ' copy the array dimension's bounds to tempoary array
    ReDim srcBounds(1 To 2 * srcSA.cDims)
    CopyMemory srcBounds(1), ByVal srcYincr + 16&, 8& * srcSA.cDims
    ' tally up the amount of bytes contained in the array
    dstScanWidth = srcBounds(1)
    For srcSA.cDims = 3 To 2 * srcSA.cDims Step 2
        dstScanWidth = (srcBounds(srcSA.cDims) * dstScanWidth)
    Next
    ' does passed array have enough bytes?
    If dstScanWidth * srcSA.cbElements < srcScanWidth * Height Then Exit Function
    Erase srcBounds()
    
    iparseOverlayHost_Byte srcBytes, VarPtr(srcSA), 2, dstHeight, srcScanWidth, srcSA.pvData ' overlay DMA array
    iparseOverlayHost_Byte dstBytes, VarPtr(dstSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    
    ' set source starting row
    If isBottomUp = True Then
        SrcY = dstHeight - 1
        srcYincr = -1
    Else
        srcYincr = 1
    End If
    
    dstScanWidth = (dstWidth + dstX) * 4& - 1& ' position for 1st byte in our DIB
    For Rows = m_Height - dstY - 1& To m_Height - dstHeight - dstY Step -1&
        SrcX = 0&
        For Cols = dstX * 4 To dstScanWidth Step 4&
            If isBGRformat = True Then
                CopyMemory dstBytes(Cols, Rows), srcBytes(SrcX, SrcY), bytesPP
            Else
                dstBytes(Cols, Rows) = srcBytes(SrcX + 2&, SrcY)
                dstBytes(Cols + 1&, Rows) = srcBytes(SrcX + 1&, SrcY)
                dstBytes(Cols + 2&, Rows) = srcBytes(SrcX, SrcY)
                If bytesPP = 4& Then ' want the alpha byte too
                    dstBytes(Cols + 3&, Rows) = srcBytes(SrcX + 3&, SrcY)
                End If
            End If
            SrcX = SrcX + bytesPP ' position of next source byte
        Next
        SrcY = SrcY + srcYincr  ' next source row
    Next
    ' release overlays
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    
    ' our image must remain pre-multiplied, ensure it now
    iparseValidateAlphaChannel dstBytes(), True, m_AlphaImage, 0&
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    
    SetDIBbits = True
    
End Function

Public Function GetAlphaMask(outStream() As Byte, _
                Optional ByVal as2dArray As Boolean = True, _
                Optional ByVal asWordAligned As Boolean = True, _
                Optional ByVal asBottomUp As Boolean = True, _
                Optional ByVal X As Long, Optional ByVal Y As Long, _
                Optional ByVal Width As Long, Optional ByVal Height As Long) As Boolean

    ' Function returns the Alpha bytes as an 8-byte, 256 color, grayscaled array
    ' Note: Unless you need a copy of the bytes for other purposes than just
    ' referencing them, it is much more efficient to overlay your own
    ' SafeArray on the Me.BitsPointer property vs copying the bytes into an array
    
    ' Function returns True if an image exists and the array was filled.
    
    ' Parameters
    ' outStream(). An array to hold the returned bytes. Array is always zero-bound
    ' as2dArray. If True, array is returned as (0 to Columns-1, 0 to Rows-1) else (0 to Columns*Rows-1)
    ' asWordAligned. If true, scanlines/columns are word aligned else scanlines are byte aligned
    ' asBottomUp. If true, 1st row of array is bottom of picture else is top of picture
    ' X,Y. The left,top position of the image to return
    ' Width,Height. The number of columns,rows to return. Defaults are entire image

    ' Tip: How to determine the scanwidth of the returned rows?
    ' 1. If as2dArray=True, UBound(outStream,1)+1
    ' 2. Otherwise, regardless of asWordAligned parameter: (UBound(outStream)+1)\Height parameter
    
    If m_Handle = 0& Then Exit Function
    If X < 0& Or Y < 0& Then Exit Function
    
    Dim dstX As Long, dstY As Long
    Dim dstYincr As Long
    Dim dstScanWidth As Long, srcScanWidth As Long
    
    Dim dstBytes() As Byte, srcBytes() As Byte
    Dim dstSA As SafeArray, srcSA As SafeArray
    
    Dim Rows As Long, Cols As Long
    
    ' validate parameters
    If Width = 0& Then Width = m_Width
    If Height = 0& Then Height = m_Height
    If Width + X > m_Width Then Width = m_Width - X
    If Height + Y > m_Height Then Height = m_Height - Y
    
    ' size the destination array
    If asWordAligned = True Then
        dstScanWidth = iparseByteAlignOnWord(8, Width)
    Else
        dstScanWidth = Width
    End If
    If as2dArray = True Then
        ReDim outStream(0 To dstScanWidth - 1&, 0 To Height - 1&)
        dstSA.pvData = VarPtr(outStream(0, 0)) ' track pointer of 1st element
    Else
        ReDim outStream(0 To dstScanWidth * Height - 1&)
        dstSA.pvData = VarPtr(outStream(0)) ' track pointer of 1st element
    End If
    
    ' set up overlays using identical 2D arrays
    iparseOverlayHost_Byte dstBytes, VarPtr(dstSA), 2, Height, dstScanWidth, dstSA.pvData ' overlay DMA array
    iparseOverlayHost_Byte srcBytes, VarPtr(srcSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    
    ' calculate destination starting row
    If asBottomUp = True Then
        dstY = Height - 1&
        dstYincr = -1&
    Else
        dstYincr = 1&
    End If
    
    srcScanWidth = (Width + X) * 4& - 1& ' position of 1st byte in DIB
    For Rows = m_Height - Y - 1& To m_Height - Height - Y Step -1&
        dstX = 0&   ' destination column
        For Cols = X * 4& + 3& To srcScanWidth Step 4&
            dstBytes(dstX, dstY) = srcBytes(Cols, Rows)
            dstX = dstX + 1& ' move to next destination column
        Next
        dstY = dstY + dstYincr ' next destination row
    Next
    ' release arrays
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    GetAlphaMask = True

End Function

Public Function CreateRegion(Optional ByVal Style As eRegionStyles = regionBounds, Optional ByVal xOffset As Long, Optional ByVal yOffset As Long) As Long
    ' Creates a region that can be used for clipping, filling, hit testing
    ' You ARE responsible for destroying the region with a call to DeleteObject
    
    ' Note: This region is created from this DIB, not the rendered DIB, therefore
    '   should the rendered DIB be of different size, mirrored, rotated or otherwise modified
    '   you should render this to a new/blank DIB and create the region from that one
    
    ' Style must be one of the following. Default is regionBounds
    '   - regionShaped: region consists of only non-transparent pixels
    '       :: example: region for the letter O would only contain the outline
    '   - regionEnclosed: transparent pixels between furthest left and furtherst right
    '       non-transparent pixels in each scan line are included in the region
    '       :: example: region for the letter O would be like filling the center then creating the region
    '   - regionBounds: all pixels within the rectangular bounds of the image are included
    '       :: example: region for the letter O would be like drawing a tight rectangle around it then creating a solid rectangular region
    ' xOffset is used to shift the region n pixels left or right
    ' yOffset is used to shift the region n pixels up or down
    
    Dim hRgn As Long
    If Not m_Handle = 0& Then
        If Style >= regionBounds And Style <= regionShaped Then
            hRgn = iparseCreateShapedRegion(Me, Style)
            If Not ((xOffset Or yOffset) = 0&) Then OffsetRgn hRgn, xOffset, yOffset
        End If
    End If
    CreateRegion = hRgn
    
End Function

Public Sub CopyImageTo(cDIBclass As c32bppDIB, Optional ByVal newWidth As Long, _
            Optional ByVal newHeight As Long, Optional ByVal CopyOriginalFormat As Boolean = False)
    
    ' Function replicates the the current image to another DIB class and optionally resizes it
    
    ' NewWidth is optional. if zero, will use the source DIB width. If negative will mirror & resize if needed
    ' NewHeight is optional. if zero, will use the source DIB height. If negative will mirror & resize if needed
    ' If CopyOriginalFormat = True then, and only, if class loaded its image
    '   with the optional SaveFormat=True, then the original image bytes
    '   were cached and will be copied to the target cDIBclass also
    '   See LoadPicture_File & LoadPicture_Stream for more info
    
    Dim dDC As Long, aResized() As Byte
    Dim bUnselect As Boolean, bResetAlphaCap As Boolean
    
    If Not m_Handle = 0& Then                ' do we have an image to copy?
    
        If newWidth = 0& Then newWidth = m_Width
        If newHeight = 0& Then newHeight = m_Height
        
        If cDIBclass Is Nothing Then
            Set cDIBclass = New c32bppDIB  ' was a valid ref passed?
            cDIBclass.gdiToken = m_GDItoken
            cDIBclass.isGDIplusEnabled = Me.isGDIplusEnabled
            cDIBclass.HighQualityInterpolation = Me.HighQualityInterpolation
            cDIBclass.InitializeDIB Abs(newWidth), Abs(newHeight) ' Create new one
        Else
            cDIBclass.gdiToken = m_GDItoken
            If Not (Abs(newWidth) = cDIBclass.Width And Abs(newHeight) = cDIBclass.Height) Then
                cDIBclass.InitializeDIB Abs(newWidth), Abs(newHeight) ' Create new one
            End If
        End If
        cDIBclass.Alpha = m_AlphaImage       ' carry over the alpha flag
        cDIBclass.ImageType = m_Format       ' and image type flag
            
        If newWidth = m_Width And newHeight = m_Height Then
            ' can copy using CopyMemory vs AlphaBlend
            CopyMemory ByVal cDIBclass.BitsPointer, ByVal m_Pointer, newWidth * 4& * newHeight
        Else
            
            If Not (m_osCAP And (osWin98MEonly Or osAlphaBlendUsable)) = 0 Then ' system is Win98/ME with AlphaBlend capability overridden
                ' but we will be resizing DIB to DIB so disallow it for now
                m_osCAP = (m_osCAP And Not osAlphaBlendUsable)
                bResetAlphaCap = True
            End If
                
            bUnselect = (m_prevObj = 0&)
            If Me.isGDIplusEnabled And (m_StretchQuality = True Or Me.isAlphaBlendFriendly = False) Then ' use GDI+ to resize
                Dim cGDIp As cGDIPlus
                If m_GDIplus Is Nothing Then
                    Set cGDIp = New cGDIPlus
                Else
                    Set cGDIp = m_GDIplus
                End If
                dDC = cDIBclass.LoadDIBinDC(True)
                If bUnselect Then Me.LoadDIBinDC True
                cGDIp.RenderGDIplus Me, dDC, 0&, 100&, 0&, 0&, newWidth, newHeight, 0&, 0&, m_Width, m_Height, True, gsclNone, m_GDItoken
                cDIBclass.LoadDIBinDC False
                If bUnselect Then Me.LoadDIBinDC False
        
            ElseIf newWidth < 0& Or newHeight < 0& Then   ' handle mirroring, AlphaBlend cannot do mirroring
                spt_MirrorDIB 0&, 0&, 0&, 0&, newWidth, newHeight, aResized(), cDIBclass ' routine mirrors directly to DIB bytes
        
            ElseIf Me.isAlphaBlendFriendly And m_StretchQuality = False Then ' O/S has no alphablending shortfalls that are known
                dDC = cDIBclass.LoadDIBinDC(True)   ' load target into a DC
                If bUnselect Then Me.LoadDIBinDC True
                Me.Render dDC, 0&, 0&, newWidth, newHeight, 0&, 0&, m_Width, m_Height, , , False, cDIBclass
                cDIBclass.LoadDIBinDC False         ' remove DIB from DC
                If bUnselect Then Me.LoadDIBinDC False
            Else
                ' stretching is involved, resize
                Call spt_pvResize(0&, aResized(), aResized(), cDIBclass) ' routine resizes directly to DIB bytes
            End If
            
            If bResetAlphaCap Then m_osCAP = m_osCAP Or osAlphaBlendUsable
        
        End If
        ' if the original image bytes are to be copied, do them too
        If CopyOriginalFormat = True Then Call cDIBclass.SetOriginalFormat(m_ImageByteCache)
    
    End If
    
End Sub

Public Function GetOrginalFormat(outStream() As Byte) As Boolean

    ' If SaveFormat is true when LoadPicture_Stream or LoadPicture_File was
    ' called, the original bytes were cached when the image was successfully
    ' loaded. Call this to return those original bytes

    ' If there are no original bytes, the function returns False & outStream is uninitialized
    
    outStream() = m_ImageByteCache()
    GetOrginalFormat = Not (iparseIsArrayEmpty(VarPtrArray(m_ImageByteCache)) = 0&)

End Function

Public Function LoadDIBinDC(ByVal bLoad As Boolean) As Long

    ' Purpose: Select/Unselect the DIB into a DC.
    ' Returns the DC handle when image is loaded
    ' Called by image parser if it needs to paint the image into the DIB
       
    If bLoad = True Then
        Dim tDC As Long
        If Not m_Handle = 0& Then    ' do we have an image?
            If m_hDC = 0& Then        ' do we have a DC?
                tDC = GetDC(0&)     ' if not create one
                m_hDC = CreateCompatibleDC(tDC)
                ReleaseDC 0&, tDC
            End If
            If m_prevObj = 0& Then
                m_prevObj = SelectObject(m_hDC, m_Handle)
            End If
            LoadDIBinDC = m_hDC
        End If
    Else
        If Not m_prevObj = 0& Then
            SelectObject m_hDC, m_prevObj
            If m_ManageDC = False Then
                DeleteObject m_hDC
                m_hDC = 0&
            End If
            m_prevObj = 0&
        End If
    End If
End Function


Public Function InitializeDIB(ByVal Width As Long, ByVal Height As Long) As Boolean

    ' Creates a blank (all black, all transparent) DIB of requested height & width
    
    Dim tBMPI As BITMAPINFO, tDC As Long
    
    DestroyDIB ' clear any pre-existing dib
    
    If Width < 0& Then Exit Function
    If Height = 0& Then
        Exit Function
    ElseIf Height < 0& Then
        Height = Abs(Height) ' no top-down dibs
    End If
    
    On Error Resume Next
    With tBMPI.bmiHeader
        .biBitCount = 32
        .biHeight = Height
        .biWidth = Width
        .biPlanes = 1
        .biSize = 40&
        .biSizeImage = .biHeight * .biWidth * 4&
    End With
    If Err Then
        Err.Clear
        ' only possible error would be that Width*Height*4& is absolutely huge
        Exit Function
    End If
    
    tDC = GetDC(0&) ' get screen DC
    m_Handle = CreateDIBSection(tDC, tBMPI, 0&, m_Pointer, 0&, 0&)
    If m_ManageDC = True Then
        ' create a DC if class is managing its own & one isn't created yet
        If m_hDC = 0& Then m_hDC = CreateCompatibleDC(tDC)
    End If
    ' release the screen DC if we captured it
    ReleaseDC 0&, tDC
    
    If Not m_Handle = 0& Then    ' let's hope system resources allowed DIB creation
        m_Width = Width
        m_Height = Height
        ' on my Win95 system, I have found cases where the creation of the DIB
        ' resulted in Windows filling the DIB with garbage, not zeroes as expected
        EraseDIB                ' ensure dib starts out blank
        InitializeDIB = True
    End If

End Function

Public Sub DestroyDIB()
    
    ' PURPOSE: Destroy any existing image
    Set m_GDIplus = Nothing
    If Not m_hDC = 0& Then   ' do we have a DC?
        ' do we have an image; if so get it out of the DC
        If Not m_prevObj = 0& Then SelectObject m_hDC, m_prevObj
        ' destroy our DC, no point in keeping it w/o image
        DeleteObject m_hDC
        m_hDC = 0&
    End If
    ' if we do have an image, destroy it now
    If Not m_Handle = 0& Then
        DeleteObject m_Handle
        Erase m_ImageByteCache
    End If
    ' reset other image attributes
    m_Width = 0&
    m_Height = 0&
    m_Handle = 0&
    m_Pointer = 0&
    m_prevObj = 0&
    m_AlphaImage = False
    m_Format = imgError
End Sub

Public Sub EraseDIB()
    ' Function clears out an existing DIB, making it 100% transparent/black
    If Not m_Handle = 0& Then
        FillMemory ByVal m_Pointer, m_Width * m_Height * 4&, 0
        m_Format = imgNone
        m_AlphaImage = True
    End If
    
End Sub

Public Function Render(ByVal destinationDC As Long, _
                Optional ByVal destX As Long, Optional ByVal destY As Long, _
                Optional ByVal destWidth As Long, Optional ByVal destHeight As Long, _
                Optional ByVal SrcX As Long, Optional ByVal SrcY As Long, _
                Optional ByVal srcWidth As Long, Optional ByVal srcHeight As Long, _
                Optional ByVal Opacity As Long = 100&, _
                Optional ByVal Blend As Boolean = True, _
                Optional ByVal SetHalfTone As Boolean = True, _
                Optional ByRef destHostDIB As c32bppDIB = Nothing, _
                Optional ByVal grayScale As eGrayScaleFormulas = gsclNone, _
                Optional ByVal LightAdjustment As Single = 0!, _
                Optional ByVal Angle As Single = 0!, _
                Optional ByVal CenterOnDestXY As Boolean = False) As Boolean

    ' PURPOSE: Render an existing 32bpp DIB to a target DC
    ' Angle & CenterOnDestXY added to allow this routine to replace the RotateAtCenterPoint & RotateAtTopLeft calls
    
    ' Mirroring: When destWidth & srcWidth are compared, if one is negative and the other positive, mirroring horizontally occurs
    '            When destHeight & srcHeight are compared, if one is negative and the other positive, mirroring vertically occurs
    ' All four of those parameters are optional & any that are not passed will default to the image's width/height as needed
    ' before the mirroring check is applied
    
    ' Parameters. Only destinationDC is required
    ' destinationDC :: target DC to draw to. Ignored if destHostDIB is passed
    ' destX, destY :: the top/left coordinates to draw to, default is 0,0
    ' destWidth, destHeight :: the width and height to draw to, default is the image's width & height
    ' srcX, srcY :: the left & top offset within the DIB
    ' srcWidth, srcHeight :: the amount of DIB to be rendered
    ' Opacity :: how opaque to draw the image, default is 100% opaque
    ' Blend :: no longer used, reserved & left in for backward compatibility
    ' SetHalfTone :: if True, then the destination DC's stretch mode will be modified to
    '       produce better quality results. This option is not available on Win9x systems.
    '       Tip: When AlphaBlending to another DIB set to False
    '            When AlphaBlending to CompatibleBitmap (DDB) or visible DC set to True
    ' destHostDIB :: When rendering from DIB class to DIB class, pass the destination
    '       DIB class to ensure alpha blending occurs correctly on systems that do not
    '       support GDI+ or AlphaBlend APIs. When passed, destinationDC is ignored
    ' grayscale :: one of several formulas to grayscale while rendering (optional)
    ' LightAdjustment :: values between -100 and 100 percent of added pixel darkeness/lightness
    '       -100% will display a black image & 100 percent will display a white image
    ' Angle :: between -360 and 360. Rotation is clockwise
    ' CenterOnDestXY :: If true then rendering is centered on the destX,destY coordinates
    
    Dim lBlendFunc As Long, tDC As Long, hOldImage As Long
    Dim lStretchMode As Long
    Dim aResizedBytes() As Byte, aMirrorBytes() As Byte
    Dim bStretching As Boolean
    Dim bMirroring As Boolean
    Dim bRotating As Boolean
    Dim bCanUseAlphaBlend As Boolean
    
    Const AC_SRC_OVER = &H0&
    Const AC_SRC_ALPHA = &H1&
    
    ' validate a few things
    If Opacity < 1& Then        ' nothing to render if image is 100% transparent
        Render = Not (m_Handle = 0)
        Exit Function
    ElseIf m_Handle = 0& Then
        Exit Function
    ElseIf destinationDC = 0& Then
        If destHostDIB Is Nothing Then Exit Function
    End If
    
    ' validate optional destination parameters
        If destWidth = 0& Then destWidth = m_Width
        If destHeight = 0& Then destHeight = m_Height
    
    ' validate optional parameters for source image
        If SrcX < 0& Then SrcX = 0&  ' source X,Y cannot be negative
        If SrcY < 0& Then SrcY = 0&  ' but the dest X,Y can be
        If srcWidth = 0& Then
            srcWidth = m_Width
        ElseIf srcWidth < 0& Then        ' locally, only the destWidth can be negative for mirroring, not srcHeight
            destWidth = -destWidth
            srcWidth = -srcWidth
        End If
        If srcHeight = 0& Then
            srcHeight = m_Height
        ElseIf srcHeight < 0& Then      ' locally, only the destHeight can be negative for mirroring, not srcHeight
            destHeight = -destHeight
            srcHeight = -srcHeight
        End If
        If SrcX + srcWidth > m_Width Then srcWidth = m_Width - SrcX
        If SrcY + srcHeight > m_Height Then srcHeight = m_Height - SrcY
        
    
    ' angle is Single. See if passed angle is evenly divisible by 360
    If Int(Angle) = Angle Then
        bRotating = Not ((Angle Mod 360) = 0)
    Else    ' angle has fractional component; therefore can't be Mod 360
        bRotating = True
    End If
    
    ' validate opacity is within range
    Opacity = Abs(Opacity) Mod 100
    If Opacity = 0& Then Opacity = 100&
    
    ' validate light adjustment is within range. Disqualify LigthAdjustmnet if out of range
    If Not LightAdjustment = 0! Then
        If LightAdjustment > 100! Then
            LightAdjustment = 0!
        ElseIf LightAdjustment < -100! Then
            LightAdjustment = 0!
        End If
    End If
    
    If CenterOnDestXY = True Then
        If bRotating Then
            destX = destX - Abs(destWidth) \ 2       ' use negative destWidth,destHeight if mirroring - rotation routines expect it
            destY = destY - Abs(destHeight) \ 2
            If Not destHostDIB Is Nothing Then destinationDC = destHostDIB.LoadDIBinDC(True)
            Render = spt_RotateImage(destinationDC, Angle, destX, destY, destWidth, destHeight, SrcX, SrcY, srcWidth, srcHeight, Opacity, destHostDIB, grayScale, LightAdjustment)
            If Not destHostDIB Is Nothing Then destHostDIB.LoadDIBinDC False
            Exit Function
        Else
            destX = destX - Abs(destWidth \ 2)  ' not rotating, don't allow negative destWidth,destHeight for calculations
            destY = destY - Abs(destHeight \ 2)
        End If
    ElseIf bRotating Then
        If Not destHostDIB Is Nothing Then destinationDC = destHostDIB.LoadDIBinDC(True)
        Render = spt_RotateImage(destinationDC, Angle, destX, destY, destWidth, destHeight, SrcX, SrcY, srcWidth, srcHeight, Opacity, destHostDIB, grayScale, LightAdjustment)
        If Not destHostDIB Is Nothing Then destHostDIB.LoadDIBinDC False
        Exit Function
    End If
    
    ' are we mirroring? rules out AlphaBlend usage if we are
    If destWidth > 0& Then
        bMirroring = (destHeight < 0&)
    Else
        bMirroring = True
    End If
    ' are we resizing? may rule out AlphaBlend usage (stretching DIB to DIB can crash on Win9x)
    If (Abs(destWidth) = srcWidth) Then
        bStretching = Not (Abs(destHeight) = srcHeight)
    Else
        bStretching = True
    End If
    
    ' The following IF tree and above boolean assignments are to determine:
    ' 1. Do we use AlphaBlend
    ' 2. Do we use GDI+
    ' 3. Do we do it manually.
    ' The answer depends on user settings, O/S, graphics manipulation & DLL abilities
    If m_KeepGDIplusActive = False Then
        ' if user provided token, allow GDI+ to override AlphaBlend
        If Me.isGDIplusEnabled = False Or Me.gdiToken = 0& Then
            ' see if alphablend will support the various rendering options
            If Me.isAlphaBlendFriendly Then     ' Win98 or better with AlphaBlend enabled & GDI+ disabled
                If Not bMirroring Then                  ' can't use alphaBlend if mirroring
                    If grayScale = gsclNone Then        ' can't use alphaBlend if gray scaling
                        If LightAdjustment = 0! Then    ' can't use alphaBlend if modifying pixel brightness
                            If bStretching Then
                                bCanUseAlphaBlend = Not m_StretchQuality ' can't use alphaBlend if using Bilinear interpolation
                            Else
                                bCanUseAlphaBlend = True
                            End If
                        End If
                    End If
                End If
            End If
        End If
    End If
    ' note. If AlphaBlend cannot support the rendering options, we will want to use GDI+
    
    If Me.isGDIplusEnabled = True And bCanUseAlphaBlend = False Then
        ' we will use GDI+ to render when system is not AlphaBlend friendly, user supplied gdi+ token, or AlphaBlend cannot handle rendering options
        Dim cGDIp As cGDIPlus
        If m_GDIplus Is Nothing Then
            Set cGDIp = New cGDIPlus
            If m_KeepGDIplusActive Then Set m_GDIplus = cGDIp
        Else
            Set cGDIp = m_GDIplus
        End If
        If Not destHostDIB Is Nothing Then destinationDC = destHostDIB.LoadDIBinDC(True)
        Render = cGDIp.RenderGDIplus(Me, destinationDC, 0&, Opacity, destX, destY, destWidth, destHeight, SrcX, SrcY, srcWidth, srcHeight, m_StretchQuality, grayScale, m_GDItoken, LightAdjustment)
        If Not destHostDIB Is Nothing Then destHostDIB.LoadDIBinDC False
    
    Else
        
        
        If m_hDC = 0& Then  ' do we have a DC to select our image into?
            tDC = GetDC(0&) ' if not create one, if ManageOwnDC=True, we will have one
            m_hDC = CreateCompatibleDC(tDC)
            ReleaseDC 0&, tDC
            hOldImage = SelectObject(m_hDC, m_Handle)
        Else
            ' we have a DC, but is the image selected into it?
            If m_prevObj = 0& Then hOldImage = SelectObject(m_hDC, m_Handle)
        End If
        
        If bCanUseAlphaBlend = False Then
            ' Ruled out use of AlphaBlend (preferred when GDI+ isn't available)
            ' Win95/NT4 - not shipped with AlphaBlend
            ' Mirroring or high quality interpolation stretching - can't use AlphaBlend
            ' Grayscaling/light adjustments on the fly - can't use AlphaBlend
            ' Stretching from DIB to destination - can crash with Win9x
            ' AlphaBlend can't do high quality interpolation
            

            ' doing it completely manually
            ' 1. Mirror and change light intensity as needed
            If bMirroring Then spt_MirrorDIB SrcX, SrcY, srcWidth, srcHeight, destWidth, destHeight, aMirrorBytes(), , LightAdjustment
            ' 2. Resize using Nearest Neighbor or Bi-Linear algorithms & change light intensity as needed, then Render
            If bStretching Then
                If spt_pvResize(destinationDC, aResizedBytes(), aMirrorBytes(), Nothing, SrcX, SrcY, srcWidth, srcHeight, destX, destY, destWidth, destHeight, LightAdjustment) = False Then Exit Function
                ' use custom blending routine, passing aResizedBytes array
                Render = spt_Win9xBlend(destinationDC, aResizedBytes(), SrcX, SrcY, destX, destY, destWidth, destHeight, (255& * Opacity) \ 100&, destHostDIB, grayScale, LightAdjustment)
            Else
                ' use custom blending routine, passing aMirrorBytes array. If LigthAdjustment not applied above, it will be applied in spt_Win9xBlend
                Render = spt_Win9xBlend(destinationDC, aMirrorBytes(), SrcX, SrcY, destX, destY, destWidth, destHeight, (255& * Opacity) \ 100&, destHostDIB, grayScale, LightAdjustment)
            End If
            
        Else ' we can use AlphaBlend
        
            If Not destHostDIB Is Nothing Then destinationDC = destHostDIB.LoadDIBinDC(True)
            
            If SetHalfTone Then ' Stretch_Halftone not compatible with win9x
                If ((m_osCAP And osIsNT) = osIsNT) Then lStretchMode = SetStretchBltMode(destinationDC, STRETCH_HALFTONE)
            End If
            
            ' calculate the opacity required & add it to the BlendFunction variable
            lBlendFunc = AC_SRC_OVER Or (((255& * Opacity) \ 100&) * &H10000)
            ' if the image has transparency, then we add the AC_SRC_ALPHA flag too
            If Me.Alpha = True Then lBlendFunc = lBlendFunc Or (AC_SRC_ALPHA * &H1000000)
            Render = Not (AlphaBlend(destinationDC, destX, destY, destWidth, destHeight, m_hDC, SrcX, SrcY, srcWidth, srcHeight, lBlendFunc) = 0&)
            
            If SetHalfTone Then ' Stretch_Halftone not compatible with win9x
                If ((m_osCAP And osIsNT) = osIsNT) Then SetStretchBltMode destinationDC, lStretchMode
            End If
            If Not destHostDIB Is Nothing Then destHostDIB.LoadDIBinDC False
            
        End If
        
        ' remove the image from the DC if necessary
        If Not hOldImage = 0& Then SelectObject m_hDC, hOldImage
        If Not tDC = 0& Then    ' if we created a DC, let's destroy it now
            DeleteDC m_hDC
            m_hDC = 0&
        End If
        
    End If
    
End Function

Public Function SaveToFile(ByVal FileName As String, Optional ByVal PromptOverwrite As Boolean = True) As Boolean

    ' Should you want to save a 32bpp image to a file
    ' Did you know? A 32bpp "XP-icon" saved in bitmap format is actually smaller
    '               than saving it in an icon format....
    '   BMP Format: 14byte header + 40byte BitmapInfo + 32bpp image bytes
    '   ICO Format: 22byte header + 40byte BitmapInfo + 32bpp image bytes + 1bpp mask bytes
    
    ' FileName :: full path & name of file to be created
    ' PromptOverwrite :: if True, the user will be offered an option to abort
    '    if the target file already exists
    
    If FileName = vbNullString Then Exit Function
    If m_Handle = 0& Then Exit Function
    
    On Error GoTo ExitRoutine
    If iparseFileExists(FileName, ((m_osCAP And osIsNT) = osIsNT)) Then
        If PromptOverwrite = True Then
            If MsgBox("Overwrite existing file?", vbYesNo + vbDefaultButton2 + vbQuestion, "Overwrite Confirmation") = vbNo Then
                Exit Function
            End If
        End If
    End If
    
    Dim fileNum As Long, rwLen As Long
    Dim tBMPI As BITMAPINFO
    Dim b24bpp() As Byte
    
    fileNum = iparseGetFileHandle(FileName, False, ((m_osCAP And osIsNT) = osIsNT))
    If (fileNum = INVALID_HANDLE_VALUE) Then Exit Function
    
    With tBMPI.bmiHeader
        .biHeight = m_Height
        .biWidth = m_Width
        .biPlanes = 1
        .biSize = 40
        .biBitCount = 24 + m_AlphaImage * -8    ' either save as 24bpp or 32bpp
        .biSizeImage = iparseByteAlignOnWord(.biBitCount, .biWidth) * .biHeight
    End With
    
    ' simply write the file
    WriteFile fileNum, &H4D42&, 2&, rwLen, ByVal 0& ' write BMP magic number
    If rwLen = 2& Then                              ' write the overall size of bitmap
        WriteFile fileNum, CLng(54& + tBMPI.bmiHeader.biSizeImage), 4&, rwLen, ByVal 0&
        If rwLen = 4& Then                          ' write reserved bytes
            WriteFile fileNum, 0&, 4&, rwLen, ByVal 0&
            If rwLen = 4& Then                      ' write image offset from beginning of file
                WriteFile fileNum, 54&, 4&, rwLen, ByVal 0&
                If rwLen = 4& Then                  ' write the bitmap info structure
                    WriteFile fileNum, tBMPI.bmiHeader.biSize, 40&, rwLen, ByVal 0&
                    If rwLen = 40& Then             ' write the bitmap pixels
                        If tBMPI.bmiHeader.biBitCount = 32 Then
                            WriteFile fileNum, ByVal m_Pointer, tBMPI.bmiHeader.biSizeImage, rwLen, ByVal 0&
                        Else
                            Me.GetDIBbits b24bpp(), , , False
                            WriteFile fileNum, b24bpp(0, 0), tBMPI.bmiHeader.biSizeImage, rwLen, ByVal 0&
                        End If
                        SaveToFile = (rwLen = tBMPI.bmiHeader.biSizeImage)
                    End If
                End If
            End If
        End If
    End If
    
ExitRoutine:
If Not fileNum = 0& Then CloseHandle fileNum
If Err Then Err.Clear

End Function

Public Function SaveToFile_PNG(ByVal FileName As String, Optional ByVal PromptOverwrite As Boolean = True) As Boolean

    ' Requires GDI+ and/or zLib installed on the system, otherwise function fails
    ' TEST isGDIplusEnabled or isZlibEnabled
    ' To use the optional PNG properties, isZlibEnabled must be True
    '   See PngPropertySet and PngPropertyGet
    
    ' Function saves the 32bpp image to file, converting it to a PNG format first
    ' FileName :: full path & name of file to be created
    ' PromptOverwrite :: if True, the user will be offered an option to abort
    '    if the target file already exists
    ' Per PNG recommendations, the PNG is converted with non-premultiplied pixels
    
    If FileName = vbNullString Then Exit Function
    If m_Handle = 0& Then Exit Function
    
    If iparseFileExists(FileName, ((m_osCAP And osIsNT) = osIsNT)) Then
        If PromptOverwrite = True Then
            If MsgBox("Overwrite existing file?", vbYesNo + vbDefaultButton2 + vbQuestion, "Overwrite Confirmation") = vbNo Then
                Exit Function
            End If
        End If
        If iparseDeleteFile(FileName, ((m_osCAP And osIsNT) = osIsNT)) = False Then Exit Function
    End If
    
    Dim aDummy() As Byte
    Dim cGDIp As cGDIPlus, cZlib As cPNGwriter
    Dim bSuccess As Boolean
    
    If m_PNGprops Is Nothing Then   ' no special PNG properties set, use GDI+
        If m_GDIplus Is Nothing Then
            Set cGDIp = New cGDIPlus
        Else
            Set cGDIp = m_GDIplus
        End If
        If cGDIp.SaveToPNG(FileName, aDummy(), Me, m_GDItoken) = False Then
            Set cZlib = New cPNGwriter  ' failed, attempt to use zLIB
            bSuccess = cZlib.SavePNGex(Me, FileName, aDummy())
        Else
            bSuccess = True         ' GDI+ created the PNG
        End If
    Else
        ' user set some optional PNG properties (See PngPropertySet), use zLib
        If m_PNGprops.SavePNGex(Me, FileName, aDummy()) = False Then
            If m_GDIplus Is Nothing Then
                Set cGDIp = New cGDIPlus    ' failed, attempt to use GDI+
            Else
                Set cGDIp = m_GDIplus
            End If
            bSuccess = cGDIp.SaveToPNG(FileName, aDummy(), Me, m_GDItoken)
        Else
            bSuccess = True         ' zLIB created the PNG
        End If
    End If
    SaveToFile_PNG = bSuccess
    
End Function

Public Function SaveToStream(outStream() As Byte) As Boolean

    ' Should you want to serialize the 32bpp DIB.
    ' Stream is formatted as a complete bitmap; therefore,
    ' one could simply write the bytes to file and a true bitmap is created
    ' Use GetDibBits function to return just the pixel data
    
    On Error GoTo ExitRoutine   ' should out of memory occur?
    
    If m_Handle = 0& Then Exit Function
    
    Dim tBMPI As BITMAPINFO
    Dim b24bpp() As Byte
    
    With tBMPI.bmiHeader
        .biHeight = m_Height
        .biWidth = m_Width
        .biPlanes = 1
        .biSize = 40
        .biBitCount = 24 + m_AlphaImage * -8
        .biSizeImage = iparseByteAlignOnWord(.biBitCount, .biWidth) * .biHeight
    End With
    
    ReDim outStream(0 To 53 + tBMPI.bmiHeader.biSizeImage)
    
    CopyMemory outStream(0), &H4D42, 2& ' bmp magic number
    CopyMemory outStream(2), CLng(54 + tBMPI.bmiHeader.biSizeImage), 4& ' overall size of image
    ' ^^ 54 = 14 byte bmp header + 40 for the tBMPI structure
    CopyMemory outStream(10), 54&, 4& ' image offset from beginning of file
    CopyMemory outStream(14), tBMPI, 40&
    If tBMPI.bmiHeader.biBitCount = 32 Then
        CopyMemory outStream(54), ByVal m_Pointer, tBMPI.bmiHeader.biSizeImage
    Else
        GetDIBbits b24bpp(), , , False
        CopyMemory outStream(54), b24bpp(0, 0), tBMPI.bmiHeader.biSizeImage
    End If
    SaveToStream = True
    
ExitRoutine:
    If Err Then
        Err.Clear
        Erase outStream()
    End If
End Function

Public Function SaveToStream_PNG(outStream() As Byte) As Boolean
'Exit Function
    ' Requires GDI+ and/or zLib installed on the system, otherwise function fails.
    ' Tesst isGDIplusEnabled or isZlibEnabled
    ' To use the optional PNG properties, isZlibEnabled must be True
    '   See PngPropertySet and PngPropertyGet
    
    ' Function saves the current 32bpp DIB to an array containing the DIB in PNG format
    ' Per PNG recommendations, the PNG is created with non-premultiplied pixels
        
    If m_Handle = 0& Then Exit Function

    Dim cGDIp As cGDIPlus, cZlib As cPNGwriter
    Dim bSuccess As Boolean
    
    If m_PNGprops Is Nothing Then   ' no special PNG properties set, use GDI+
        If m_GDIplus Is Nothing Then
            Set cGDIp = New cGDIPlus
        Else
            Set cGDIp = m_GDIplus
        End If
        If cGDIp.SaveToPNG(vbNullString, outStream(), Me, m_GDItoken) = False Then
            Set cZlib = New cPNGwriter  ' failed, attempt to use zLIB
            bSuccess = cZlib.SavePNGex(Me, vbNullString, outStream())
        Else
            bSuccess = True         ' GDI+ created the PNG
        End If
    Else
        ' user set some optional PNG properties (See PngPropertySet), use zLib
        If m_PNGprops.SavePNGex(Me, vbNullString, outStream()) = False Then
            ' failed, attempt to use GDI+
            If m_GDIplus Is Nothing Then
                Set cGDIp = New cGDIPlus
            Else
                Set cGDIp = m_GDIplus
            End If
            bSuccess = cGDIp.SaveToPNG(vbNullString, outStream(), Me, m_GDItoken)
        Else
            bSuccess = True         ' zLIB created the PNG
        End If
    End If
    SaveToStream_PNG = bSuccess
        
End Function

Public Function PngPropertySet(ByVal PropertyID As ePngProperties, Optional PropertyValue As Variant, Optional ByVal Caption_Misc As String) As Boolean

    ' Sets several optional properties: the properties are described below
    ' Once set, properties are forever applied until PngPropetySet(pngProp_ClearProps)
    '   is called or this class is terminated
    
    ' [PropertyID]
    ' pngProp_Title - Short (one line) title or caption for image
    ' pngProp_Author - Name of image's creator
    ' pngProp_Description - Description of image
    ' pngProp_Copyright - Copyright notice
    ' pngProp_CreationTime - Creation Time of original image creation
    ' pngProp_Software - Software used to create the image
    ' pngProp_Disclaimer - Legal disclaimer
    ' pngProp_Warning - Warning or nature of content
    ' pngProp_Source - Device used to create the image
    ' pngProp_Comment - Comment
    ' :: the above are registered/recognized keywords usable in PNGs
    
    ' pngProp_Miscellaneous - miscellaneous, can contain most any text and size.
    '   When used, you must supply a Caption/Keyword for the text in Caption_Misc parameter
    
    ' pngProp_DefaultBkgColor - background color used if a PNG viewer opts to compose against only solid colors
    
    ' pngProp_DateTimeModified - date/time when the PNG was last modified.
    
    ' pngProp_FilterMethod - changes the precompression filter method applied to PNG data
    '   See cPNGwriter filter functions for details on how filters modify data
    
    ' pngProp_ClearProps - removes all properties, the other parameters are not used
    '   When a property is set, zLIB will be used over GDI+. When properties are cleared
    '   then GDI+ will be used over zLIB
    
    '[PropertyValue]
    ' If not provided, the property associated with PropertyID is removed
    '   for pngProp_DefaultBkgColor, this parameter is a valid RGB color
    '   for pngProp_DateTimeModified, this parameter is a valid date/time. IsDate(PropertyValue) must be True
    '   for pngProp_FilterMethod, this parameter is one of the eFilterMethods enumeration values. Default is filterDefault
    '   for all others properties, this is text
    
    '[Caption_Misc]
    '   Only used when PropertyID is pngProp_Miscellaneous. This is the caption/keyword to
    '   be used with the supplied text. Cannot be one of the registered keywords
    
    If PropertyID = pngProp_ClearProps Then
        Set m_PNGprops = Nothing
        PngPropertySet = True
        
    ElseIf IsMissing(PropertyValue) = True Then
        If Not m_PNGprops Is Nothing Then
            PngPropertySet = m_PNGprops.RemoveProperty(PropertyID, Caption_Misc)
        End If
    
    Else
        If m_PNGprops Is Nothing Then Set m_PNGprops = New cPNGwriter
        PngPropertySet = m_PNGprops.AddProperty(PropertyID, PropertyValue, Caption_Misc)
    End If

End Function

Public Function PngPropertyGet(ByVal PropertyID As ePngProperties, Optional ByVal Caption_Misc As String) As Variant

    ' Returns a property previously set
    ' See PngPropertySet for parameter details
    ' Note that Caption_Misc is required if PropertyID = pngProp_Miscellaneous

    Dim vReturn As Variant

    If m_PNGprops Is Nothing Then
        If PropertyID = pngProp_DefaultBkgColor Then
            vReturn = -1&
        ElseIf PropertyID = pngProp_DateTimeModified Then
            vReturn = CDate(0)
        Else
            vReturn = vbNullString
        End If
    Else
        vReturn = m_PNGprops.GetProperty(PropertyID, Caption_Misc)
    End If
    
    PngPropertyGet = vReturn
End Function


Public Function Resize(ByVal newWidth As Long, ByVal newHeight As Long) As Boolean

    ' Function simply resizes the current DIB to passed dimensions of Width & Height
    ' If newWidth is negative, the image will be horizontally mirrored
    ' If newHeight is negative, the image will be vertically mirrored
    
    If m_Handle = 0& Then Exit Function
    
    If newWidth = 0& Then newWidth = m_Width
    If newHeight = 0& Then newHeight = m_Height
    
    If newWidth = m_Width And newHeight = m_Height Then
        Resize = True                   ' no change
        Exit Function
    End If

    Dim tHost As New c32bppDIB
    Dim tDC As Long, sDC As Long
    Dim aDummy() As Byte
    Dim bUnselect As Boolean, bResetAlphaCap As Boolean
    
    With tHost
        .gdiToken = m_GDItoken
        .InitializeDIB Abs(newWidth), Abs(newHeight)   ' create new DIB
        .isGDIplusEnabled = Me.isGDIplusEnabled
        .HighQualityInterpolation = Me.HighQualityInterpolation
        .ImageType = m_Format          ' transfer format & alpha format
        .Alpha = m_AlphaImage
        .SetOriginalFormat m_ImageByteCache
        .Tag = Me.Tag
    End With
    
    bUnselect = (m_prevObj = 0&)
    If m_StretchQuality And Me.isGDIplusEnabled Then ' use GDI+ for resizing
        Dim cGDIp As cGDIPlus
        If m_GDIplus Is Nothing Then
            Set cGDIp = New cGDIPlus
        Else
            Set cGDIp = m_GDIplus
        End If
        tDC = tHost.LoadDIBinDC(True)
        If bUnselect Then Me.LoadDIBinDC True
        cGDIp.RenderGDIplus Me, tDC, 0&, 100&, 0&, 0&, newWidth, newHeight, 0&, 0&, m_Width, m_Height, True, gsclNone, m_GDItoken
        tHost.LoadDIBinDC False
        If bUnselect Then Me.LoadDIBinDC False
        
    ElseIf newWidth < 0& Or newHeight < 0& Then ' handle mirroring, AlphaBlend cannot do mirroring
        spt_MirrorDIB 0&, 0&, 0&, 0&, newWidth, newHeight, aDummy(), tHost ' routine mirrors directly to DIB bytes
    
    ElseIf Me.isAlphaBlendFriendly And m_StretchQuality = False Then
    
        If Not (m_osCAP And (osWin98MEonly Or osAlphaBlendUsable)) = 0& Then ' system is Win98/ME with AlphaBlend capability overridden
            ' but we will be resizing DIB to DIB so disallow it for now
            m_osCAP = (m_osCAP And Not osAlphaBlendUsable)
            bResetAlphaCap = True
        End If
    
        tDC = tHost.LoadDIBinDC(True)               ' select into DC
        If bUnselect Then Me.LoadDIBinDC True
        Me.Render tDC, 0&, 0&, newWidth, newHeight, , , , , , , False, tHost ' stretch AlphaBlend
        tHost.LoadDIBinDC False                     ' remove from DC
        If bUnselect Then Me.LoadDIBinDC False
        If bResetAlphaCap Then m_osCAP = m_osCAP Or osAlphaBlendUsable
        
    Else
        spt_pvResize 0&, aDummy(), aDummy(), tHost   ' use custom resizing routine for nonAlphaBlend-friendly systems
    End If
    
    tHost.CopyImageTo Me, , , True    ' copy it back to us
    
    Set tHost = Nothing                 ' done
    Resize = True

End Function

Public Function TrimImage(ByVal UpdateDIB As Boolean, ByVal Method As eTrimOptions, _
                          Optional ByRef X As Long, Optional ByRef Y As Long, _
                          Optional ByRef Width As Long, Optional ByRef Height As Long) As Boolean
    
    ' Function can remove excess transparency from an image and/or return the
    ' X,Y,width & height needed to render out the excess transaprency
    
    ' Parameters
    ' UpdateDIB. If true, the image will be permanently resized/cropped/trimmed
    ' X,Y.
    '   If UpdateDIB=True, then these will be zero,zero
    '   If UpdateDIB=False, then X,Y will be the top,left coordinate of 1st non-transparent pixel
    ' Width,Height. the adjusted width/height after trimming the image
    '   If either Width/Height are zero, then the image is 100% transparent
    
    ' Note: Trimming alpha images may not produce desired results. Many alpha images may
    ' have buffered transparent borders to visually center the image within the overall
    ' dimensions of the image. For example, if the image is heavily shaded on the right side,
    ' the image may have an equal amount of transparent columns on the left side to compensate.
    
    If m_Handle = 0& Then Exit Function
    If m_AlphaImage = False Then
        X = 0&: Y = 0&: Width = m_Width: Height = m_Height
        TrimImage = True
        Exit Function
    End If
    If Method = trimAll Then Method = trimBottom Or trimLeft Or trimRight Or trimTop
    If Method < trimAll Then Exit Function
    
    Dim tSA As SafeArray, sBytes() As Byte
    Dim dSA As SafeArray, dBytes() As Byte
    Dim SrcX As Long, SrcY As Long, sWidth As Long
    Dim tHost As c32bppDIB
    
    sWidth = m_Width * 4&
    iparseOverlayHost_Byte sBytes, VarPtr(tSA), 2, m_Height, sWidth, m_Pointer ' overlay DMA array
    
    ' define trimmed top edge
    If (Method And trimTop) = trimTop Then
        For Y = m_Height - 1& To 0& Step -1&
            For SrcX = 3& To sWidth - 1& Step 4&
                If Not sBytes(SrcX, Y) = 0& Then Exit For
            Next
            If SrcX < sWidth Then Exit For ' row is NOT fully transparent
        Next
        If Y = -1& Then ' the entire image is transparent
            Y = 0&: X = 0&: Width = 0&: Height = 0&
            iparseOverlayHost_Byte sBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
            Exit Function
        End If
    Else
        Y = m_Height - 1&
    End If
    
    Y = m_Height - Y - 1&    ' calculate top trimmed row
    
    If (Method And trimBottom) = trimBottom Then
        ' define trimmed bottom edge
        For Height = 0& To m_Height - Y - 1&
            For SrcX = 3& To sWidth - 1& Step 4&
                If Not sBytes(SrcX, Height) = 0& Then Exit For
            Next
            If SrcX < sWidth Then Exit For ' row is NOT fully transparent
        Next
        If (Method And trimTop) = 0& Then ' check for full transparency image
            If Height = m_Height Then ' the entire image is transparent
                Y = 0&: X = 0&: Width = 0&: Height = 0&
                iparseOverlayHost_Byte sBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
                Exit Function
            End If
        End If
    Else
        Height = 0&
    End If
    
    TrimImage = True
    
    If Height = m_Height - Y Then
        Height = m_Height - Y ' there are no transparent rows from bottom edge
    Else
        Height = m_Height - (Height + Y) ' calculate height of trimmed image
    End If
    
    ' define trimmed left edge
    If (Method And trimLeft) = trimLeft Then
        For X = 3& To sWidth - 1& Step 4&
            For SrcY = Y To Y + Height - 1&
                If Not sBytes(X, SrcY) = 0& Then Exit For
            Next
            If SrcY < Y + Height Then Exit For ' column is NOT fully transparent
        Next
    Else
        X = 3&
    End If
    
    ' define trimmed left edge
    If (Method And trimRight) = trimRight Then
        For Width = sWidth - 1& To X + 1& Step -4&
            For SrcY = Y To Y + Height - 1&
                If Not sBytes(Width, SrcY) = 0& Then Exit For
            Next
            If SrcY < Y + Height Then Exit For ' column is NOT fully transparent
        Next
    Else
        Width = sWidth - 1&
    End If
    
    If Width < X Then Width = X     ' only one column of non-transparent pixels
    X = X \ 4                       ' calculate left offset of trimmed image
    Width = Width \ 4 - X + 1&      ' calculate width of trimmed image
    
    If UpdateDIB = True And Not (Width = m_Width And Height = m_Height) Then
    
        ' create a temporary DIB to copy
        Set tHost = New c32bppDIB
        tHost.gdiToken = m_GDItoken
        tHost.InitializeDIB Width, Height
        tHost.Alpha = m_AlphaImage
        tHost.ImageType = m_Format
        tHost.SetOriginalFormat m_ImageByteCache
        tHost.Tag = Me.Tag
        
        iparseOverlayHost_Byte dBytes, VarPtr(dSA), 2, Height, Width * 4&, tHost.BitsPointer ' overlay DMA array
        SrcY = 0&           ' current destination row
        SrcX = X * 4&       ' current source column
        sWidth = Width * 4& ' scanwidth of trimmed image
        
        For Y = m_Height - (Y + Height) To m_Height - Y - 1&
            CopyMemory dBytes(0&, SrcY), sBytes(SrcX, Y), sWidth
            SrcY = SrcY + 1&    ' increment destination row
        Next
        iparseOverlayHost_Byte dBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
        iparseOverlayHost_Byte sBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
        
        ' transfer the updated DIB to our DIB
        tHost.CopyImageTo Me, , , True
        X = 0&: Y = 0&
        
    Else
    
        iparseOverlayHost_Byte sBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    End If
    
End Function

Public Function SourceIconSizes(sizeArray() As Long) As Long
    ' Function will return a 2D array that contains the icon width, height,
    '   bit depth and color count for each icon in the source image/file
    ' The 2D array is always zero bound and the return value of the function
    ' indicates how many icons exist in the source
    
    ' 1st dimension of the array
    ' 0 element: icon width
    ' 1 element: icon height
    ' 2 element: icon bit depth: 1,2,4,8,16,24,32
    ' 3 element: icon colors: 2,4,16,256,HIGH_COLOR,TRUE_COLOR, TRUE_COLOR_ALPHA
    ' HIGH_COLOR, TRUE_COLOR,& TRUE_COLOR_ALPHA are public variables
    ' 2nd dimension of the array is 0 to number of icons - 1
    
    If m_Handle = 0& Then Exit Function
    Select Case m_Format
        Case imgIcon, imgIconARGB, imgPNGicon, imgCursor, imgCursorARGB
            If iparseIsArrayEmpty(VarPtrArray(m_ImageByteCache)) = 0& Then
                ' original bytes were not kept, therefore, we only have one image
                ReDim sizeArray(0 To 3, 0 To 0)
                sizeArray(0, 0) = m_Width
                sizeArray(1, 0) = m_Height
                sizeArray(2, 0) = 32
                sizeArray(3, 0) = TRUE_COLOR_ALPHA
                SourceIconSizes = 1
            Else
                Dim cICO As cICOparser, i As Long
                Set cICO = New cICOparser
                If cICO.LoadStream(m_ImageByteCache, 32, 32, Nothing, 0, UBound(m_ImageByteCache) + 1, 32) = True Then
                    ReDim sizeArray(0 To 3, 0 To cICO.IconCount - 1)
                    With cICO
                        For i = 1 To .IconCount
                            sizeArray(0, i - 1) = .Width(i)
                            sizeArray(1, i - 1) = .Height(i)
                            sizeArray(2, i - 1) = .bitDepth(i)
                            Select Case .bitDepth(i)
                                Case 1: sizeArray(3, i - 1) = 2
                                Case 2: sizeArray(3, i - 1) = 4
                                Case 4: sizeArray(3, i - 1) = 16
                                Case 8: sizeArray(3, i - 1) = 256
                                Case Is < 24: sizeArray(3, i - 1) = HIGH_COLOR
                                Case 24: sizeArray(3, i - 1) = TRUE_COLOR
                                Case Else: sizeArray(3, i - 1) = TRUE_COLOR_ALPHA
                            End Select
                        Next
                    End With
                    SourceIconSizes = cICO.IconCount
                End If
            End If
        Case Else
            ' not an icon/cursor source
    End Select
End Function

Public Function CreateCheckerBoard(Optional ByVal CheckerSize As Long = 12&, _
            Optional ByVal FirstColor As Long = vbWhite, Optional ByVal SecondColor As Long = 12632256) As Boolean

    ' Function simply creates a checkerboard pattern.  This can be desirable when the DIB currently has no
    ' image but something should be displayed. When this is set, you can test whether or not this class
    ' created the Checkerboard by testing class.ImageType = imgCheckerBoard
    
    ' The checker size is used for both the width and height of each square. Default value is 12.
    ' FirstColor is the colored checker at the top left corner of the pattern. Default is white
    ' SecondColor is the alternating checker color. Default is gray RGB: 192,192,192
    
    If m_Handle = 0& Then Exit Function

    Dim hBrush As Long, hBr1 As Long, hBr2 As Long
    Dim cRect As RECT, tSA As SafeArray
    Dim X As Long, Y As Long, tDC As Long
    Dim bUnselect As Boolean, bEven As Boolean
    Dim dibBytes() As Byte
    
    bUnselect = (m_prevObj = 0&)
    tDC = LoadDIBinDC(True)
    
    hBr1 = CreateSolidBrush(FirstColor)
    hBr2 = CreateSolidBrush(SecondColor)
    
    cRect.Right = CheckerSize
    cRect.Bottom = CheckerSize
    For Y = 0& To m_Height - 1& Step CheckerSize
        If bEven Then hBrush = hBr2 Else hBrush = hBr1
        For X = 0& To m_Width - 1& Step CheckerSize
            FillRect tDC, cRect, hBrush
            If hBrush = hBr1 Then hBrush = hBr2 Else hBrush = hBr1
            OffsetRect cRect, CheckerSize, 0&
        Next
        bEven = Not bEven
        OffsetRect cRect, -cRect.Left, CheckerSize
    Next
    DeleteObject hBr1
    DeleteObject hBr2
    
    If bUnselect Then LoadDIBinDC False
    
    ' here we will force every alpha byte to be fully opaque
    iparseOverlayHost_Byte dibBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    For Y = 0& To m_Height - 1&
        For X = 3& To m_Width * 4& - 1& Step 4&
            dibBytes(X, Y) = 255
        Next
    Next
    iparseOverlayHost_Byte dibBytes, 0, 0, 0, 0, 0  ' remove DMA overlay

    m_AlphaImage = False            ' we are not using transparency
    m_Format = imgCheckerBoard      ' special flag for user
    
    CreateCheckerBoard = True
End Function

Public Function MakeGrayScale(ByVal Formula As eGrayScaleFormulas) As Boolean

    ' Purpose: Convert premultiplied bytes to gray scale using one of several formulas
    ' To render grayscaled without modifying the DIB bytes, include the optional grayscale formula in the Render function
    
    ' Note: to add in your favorite formula, add it first to the eGRayScaleForumals enumeration
    ' in the declarations section, then add the R,G,B percentages in the modParsers.iparseGrayScaleRatios routine

    If m_Handle = 0& Then Exit Function
    If Formula = gsclNone Then Exit Function
    
    Dim tSA As SafeArray, gBytes() As Byte
    Dim R As Single, G As Single, B As Single
    Dim X As Long, Y As Long
    
    iparseOverlayHost_Byte gBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    Call iparseGrayScaleRatios(Formula, R, G, B)
    
    On Error Resume Next
    For Y = 0& To m_Height - 1&
        For X = 0& To m_Width * 4& - 1& Step 4&
            If Not gBytes(X + 3&, Y) = 0 Then   ' otherwise fully transparent pixel
                gBytes(X, Y) = CByte((gBytes(X, Y) * B) + (gBytes(X + 1&, Y) * G) + (gBytes(X + 2&, Y) * R))
                gBytes(X + 1&, Y) = gBytes(X, Y)
                gBytes(X + 2&, Y) = gBytes(X, Y)
            End If
        Next
    Next
    iparseOverlayHost_Byte gBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    MakeGrayScale = True
    
End Function

Public Function MakeImageInverse() As Boolean
    
    ' Function will invert the RGB values creating a color negative of the image
    ' Calling this function again, returns the image to its previous state
    
    If m_Handle = 0& Then Exit Function
    
    Dim tSA As SafeArray, gBytes() As Byte
    Dim pAlpha As Byte
    Dim X As Long, Y As Long
    
    iparseOverlayHost_Byte gBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    On Error Resume Next
    For Y = 0& To m_Height - 1&
        For X = 0& To m_Width * 4& - 1& Step 4&
            pAlpha = gBytes(X + 3&, Y)
            If Not pAlpha = 0 Then   ' otherwise fully transparent pixel
                gBytes(X, Y) = -gBytes(X, Y) + pAlpha
                gBytes(X + 1&, Y) = -gBytes(X + 1&, Y) + pAlpha
                gBytes(X + 2&, Y) = -gBytes(X + 2&, Y) + pAlpha
            End If
        Next
    Next
    iparseOverlayHost_Byte gBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    MakeImageInverse = True
    
End Function

Public Function MakeTransparent(ByVal TransparentColor As Long, Optional ByVal Revert As Boolean = False) As Boolean

    ' if Revert = False
    '   Function will convert all pixels that are of the TransparentColor to fully transparent.
    '   Additionally, only if the alpha value of the color is fully opaque will the pixel become transparent.
    ' if Revert = True
    '   All fully transparent colors are made fully opaque and changed to the TransparentColor
    
    If m_Handle = 0& Then Exit Function
    
    Dim tSA As SafeArray, dPixels() As Long, bPixels() As Byte
    Dim X As Long, Y As Long, bAlpha As Boolean
    
    ' convert passed color from RGB to BGRA
    TransparentColor = ((TransparentColor And &HFF) * &H10000) Or ((TransparentColor \ &H100) And &HFF) * &H100 _
                    Or ((TransparentColor \ &H10000) And &HFF) Or &HFF000000
    
    iparseOverlayHost_Long dPixels, VarPtr(tSA), 2, m_Height, m_Width, m_Pointer  ' overlay DMA array
    If Revert Then
        ' change all fully transparent pixels to passed color
        For Y = 0& To m_Height - 1&
            For X = 0& To m_Width - 1&
                If dPixels(X, Y) = 0& Then
                    dPixels(X, Y) = TransparentColor
                End If
            Next
        Next
        iparseOverlayHost_Long dPixels, 0, 0, 0, 0, 0  ' remove DMA overlay
        ' image may or may not contain alpha any longer, validate it
        ' The validation routine expects a 2D byte array, not long, so...
        iparseOverlayHost_Byte bPixels, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
        iparseValidateAlphaChannel bPixels(), False, bAlpha, 0&
        iparseOverlayHost_Byte bPixels, 0, 0, 0, 0, 0  ' remove DMA overlay
        Me.Alpha = bAlpha
        If bAlpha = False Then
            If m_Format = imgBmpPARGB Or m_Format = imgBmpARGB Then m_Format = imgBitmap
        End If
        
    Else
        ' change all fully opaque colors matching TransparentColor to fully transparent
        For Y = 0& To m_Height - 1&
            For X = 0& To m_Width - 1&
                If dPixels(X, Y) = TransparentColor Then
                    dPixels(X, Y) = 0&
                    bAlpha = True
                End If
            Next
        Next
        iparseOverlayHost_Long dPixels, 0, 0, 0, 0, 0  ' remove DMA overlay
        If bAlpha Then
            m_AlphaImage = True
            If m_Format = imgBitmap Then m_Format = imgBmpPARGB
        End If
    End If
    MakeTransparent = True

End Function

Public Function MirrorImage(ByVal MirrorAxisX As Boolean, ByVal MirrorAxisY As Boolean) As Boolean
    
    ' Function will mirror an image onto the same DIB.
    ' This function should be called when any image is mirrored vs mirroring the image
    ' within the Render function or rotate functions. Faster rendering will then occur.
    ' Mirroring never destroys original data and can be easily unmirrored.
    
    ' MirrorAxisX: If true, then image is mirrored horizontally
    ' MirrorAxisY: If true, then image is mirrored vertically
    
    If Not m_Handle = 0& Then
        If MirrorAxisX Or MirrorAxisY Then
            Dim tBytes() As Byte, cX As Long, cY As Long
            If MirrorAxisX = True Then cX = -m_Width Else cX = m_Width
            If MirrorAxisY = True Then cY = -m_Height Else cY = m_Height
            spt_MirrorDIB 0&, 0&, m_Width, m_Height, cX, cY, tBytes()
            CopyMemory ByVal m_Pointer, tBytes(0, 0), m_Width * m_Height * 4&
            MirrorImage = True
        End If
    End If
End Function


Public Function CreateDropShadow(Optional ByVal blurDepth As Long = 4, _
                        Optional ByVal Color As Long = 12632256) As c32bppDIB

    ' Purpose: This routine creates a separate DIB class to hold a shadow.
    ' The shadow is always created based of the current image contained in this class.
    ' Should you later modify the image, you should recreate the shadow.\
    ' And always draw your shadow first, using same basic rendering methods you would
    ' use for the main image, offsetting the shadow's X,Y coordinates as needed.
    
    ' Tip: Adjust shadow's X,Y coordinates equal to the blur depth of the shadow for
    ' the average use. However, the shadow's X,Y coords can be adjusted as desired.
    
    ' See RenderDropShadow_JIT also. That function renders a shadow directly without
    ' creating a separate DIB class, but has very basic rendering options.

' this routine is basically a faster (quite faster) version of vbAccelerator's shadow class
' http://www.vbaccelerator.com/home/VB/Code/vbMedia/Image_Processing/Drop_Shadows/article.asp

' The speed efficiency is obtained by caching the total alpha values per column that
' will be used for blurring. If 10 columns are used to blur, we cache 10 alpha sums.
' Then when the next source column is queried to be added to the blur calcs, we simply
' subtract the oldest column sum from the grand total, calculate the new column sum,
' cache it, add that sum to the grand total and move on. This approach reduces
' (blurDepth*blurDepth-blurDepth) calculations per pixel. Using, say, a 10 pixel blur
' depth, the savings are immense: a 69x100 image; my version in IDE: 38 ms, vbAccelerator: 232 ms

    If m_Handle = 0 Then Exit Function

    Dim X As Long, Y As Long
    Dim vTally() As Long
    Dim tAlpha As Long, tColumn As Long, tAvg As Long
    Dim dBytes() As Byte, tSA As SafeArray
    Dim t2xBlur As Long
    Dim R As Long, G As Long, B As Long
    
    Dim srcBytes() As Byte, sSA As SafeArray
    Dim shadowDIB As c32bppDIB
    
    Dim initY As Long, initYstop As Long, initYstart As Long
    Dim initX As Long, initXstop As Long
    
    If blurDepth < 0 Then
        blurDepth = 0
    ElseIf blurDepth > 10 Then
        blurDepth = 10
    End If
    t2xBlur = blurDepth * 2
    
    Set shadowDIB = New c32bppDIB
    shadowDIB.InitializeDIB m_Width + t2xBlur, m_Height + t2xBlur
    
    iparseOverlayHost_Byte dBytes, VarPtr(tSA), 2, m_Height + t2xBlur, (m_Width + t2xBlur) * 4&, shadowDIB.BitsPointer ' overlay DMA array
    iparseOverlayHost_Byte srcBytes, VarPtr(sSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    
    R = Color And &HFF
    G = (Color \ &H100&) And &HFF
    B = (Color \ &H10000) And &HFF
    
    tAvg = (t2xBlur + 1) * (t2xBlur + 1)    ' how many pixels are being blurred
    
    ReDim vTally(0 To t2xBlur)              ' number of blur columns per pixel
    
    For Y = 0 To m_Height + t2xBlur - 1     ' loop thru shadow dib
    
        FillMemory vTally(0), (t2xBlur + 1) * 4, 0  ' reset column totals
        
        If Y < t2xBlur Then         ' y does not exist in source
            initYstart = 0          ' use 1st row
        Else
            initYstart = Y - t2xBlur ' start n blur rows above y
        End If
        ' how may source rows can we use for blurring?
        If Y < m_Height Then initYstop = Y Else initYstop = m_Height - 1
        
        tAlpha = 0  ' reset alpha sum
        tColumn = 0    ' reset column counter
        
        ' the first n columns will all be zero
        ' only the far right blur column has values; tally them
        For initY = initYstart To initYstop
            tAlpha = tAlpha + srcBytes(3, initY)
        Next
        ' assign the right column value
        vTally(t2xBlur) = tAlpha
        
        For X = 3 To (m_Width - 2) * 4 - 1 Step 4
            ' loop thru each source pixel's alpha
            
            ' set shadow alpha using blur average
            dBytes(X, Y) = tAlpha \ tAvg
            ' and set shadow color
            Select Case dBytes(X, Y)
            Case 255
                dBytes(X - 1, Y) = R
                dBytes(X - 2, Y) = G
                dBytes(X - 3, Y) = B
            Case 0
            Case Else
                dBytes(X - 1, Y) = R * dBytes(X, Y) \ 255
                dBytes(X - 2, Y) = G * dBytes(X, Y) \ 255
                dBytes(X - 3, Y) = B * dBytes(X, Y) \ 255
            End Select
            ' remove the furthest left column's alpha sum
            tAlpha = tAlpha - vTally(tColumn)
            ' count the next column of alphas
            vTally(tColumn) = 0&
            For initY = initYstart To initYstop
                vTally(tColumn) = vTally(tColumn) + srcBytes(X + 4, initY)
            Next
            ' add the new column's sum to the overall sum
            tAlpha = tAlpha + vTally(tColumn)
            ' set the next column to be recalculated
            tColumn = (tColumn + 1) Mod (t2xBlur + 1)
        Next
        
        ' now to finish blurring from right edge of source
        For X = X To (m_Width + t2xBlur - 1) * 4 - 1 Step 4
            dBytes(X, Y) = tAlpha \ tAvg
            Select Case dBytes(X, Y)
            Case 255
                dBytes(X - 1, Y) = R
                dBytes(X - 2, Y) = G
                dBytes(X - 3, Y) = B
            Case 0
            Case Else
                dBytes(X - 1, Y) = R * dBytes(X, Y) \ 255
                dBytes(X - 2, Y) = G * dBytes(X, Y) \ 255
                dBytes(X - 3, Y) = B * dBytes(X, Y) \ 255
            End Select
            ' remove this column's alpha sum
            tAlpha = tAlpha - vTally(tColumn)
            ' set next column to be removed
            tColumn = (tColumn + 1) Mod (t2xBlur + 1)
        Next
    Next
    
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte dBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    
    shadowDIB.Alpha = True
    shadowDIB.ImageType = imgBmpPARGB
    Set CreateDropShadow = shadowDIB
    
End Function

Public Function RenderDropShadow_JIT(ByVal hDC As Long, ByVal X As Long, ByVal Y As Long, _
                                Optional ByVal blurDepth As Long = 4, _
                                Optional ByVal Color As Long = 12632256, _
                                Optional ByVal Opacity As Long = 50, _
                                Optional ByVal LightAdjustment As Single = 0!, _
                                Optional destHostDIB As c32bppDIB = Nothing) As Boolean

    ' Purpose: A simple version of the CreateShadow routine.
    ' Useful should the rendered image not need to be rotated, mirrored, or stretched and you
    ' simply want to draw a shadow on demand.
    
    ' FYI: JIT is an acronym meaning Just In Time
    
    ' Parameters:
    ' hDC :: target DC to draw the shadow
    ' X,Y :: Left and Top coordinats to render shadow at
    ' blurDepth :: the bluriness of the shadow
    ' Opacity :: values between 0 and 100 percent. 0 is transparent and 100 is fully opaque
    ' LightAdjustment :: values between -100 and 100 percent of added pixel darkeness/lightness
    '       -100% will display a black image & 100 percent will display a white image
    ' destHostDIB :: When rendering from DIB class to DIB class, pass the destination
    '       DIB class to ensure alpha blending occurs correctly on systems that do not
    '       support GDI+ or AlphaBlend APIs
    
        
    Dim dibShadow As c32bppDIB
    Set dibShadow = CreateDropShadow(blurDepth, Color)
    If Not dibShadow Is Nothing Then
        RenderDropShadow_JIT = dibShadow.Render(hDC, X, Y, , , , , , , Opacity, , , destHostDIB, , LightAdjustment)
    End If
        
End Function

Public Function MakeLighterDarker(ByVal Percent As Single) As Boolean

    ' Function permanently adds levels of darkness or lightness to the image
    ' To render image with variable lightness without modifying the image,
    '   pass the optional LightAdjustment parameters to Render & RenderDropShadow_JIT

    ' Percent is any valid value between -100% and 100%.
    '   Passing -100 will create pure blackness while passing 100% creates pure whiteness

    Dim rtnArray() As Byte
    ' validate passed param within range
    If Percent > 100! Then
        Percent = 0!
    ElseIf Percent < -100! Then
        Percent = -0!
    End If
    
    If Not (Percent = 0! Or m_Handle = 0&) Then
        Call spt_LightenDarken(Me, Percent, rtnArray(), 0, 0, m_Width, m_Height)
        CopyMemory ByVal m_Pointer, rtnArray(0, 0), m_Height * Me.scanWidth
        MakeLighterDarker = True
    End If
    
End Function

Public Function CreateGDIplusToken() As Long
    ' function used to create a GDI+ token for you.
    ' Creating a token does not assign it to the class. Call gdiToken property
    Dim cGDI As cGDIPlus
    Dim gToken As Long
    If m_GDIplus Is Nothing Then
        Set cGDI = New cGDIPlus
    Else
        Set cGDI = m_GDIplus
    End If
    If cGDI.isGDIplusOk(gToken, True) = True Then
        CreateGDIplusToken = gToken
    End If
End Function

Public Function DestroyGDIplusToken(ByVal Token As Long) As Boolean
    ' function will release GDI+ for you. If the passed Token is used
    ' by other classes, you must set the other class' gdiToken property to zero
    ' before calling this routine.
    If Not Token = 0 Then
        Dim cGDI As cGDIPlus
        If m_GDIplus Is Nothing Then
            Set cGDI = New cGDIPlus
        Else
            Set cGDI = m_GDIplus
        End If
        DestroyGDIplusToken = cGDI.InitializeGDIplus(Token, True)
    End If
End Function

Public Function BlendToColor(ByVal BlendColor As Long, Optional ByVal BlendOpacity As Long = 33) As Boolean

    ' Function will fade an image to a solid background color. This permanenly modifies the image
    
    ' Usage can be to colorize an image to say red, green, blue, yellow, etc.
    
    ' One can also fade to gray and create a nice "disabled" image with colors. However, this method
    ' permanently modifies the image whereas rendering an image 10-15% darker or grayscaling can
    ' produce another nice "disabled" image without modifying the image.
    
    ' Parameters:
    ' BlendColor :: the solid background color, a valid RGB color
    ' BlendOpacity :: values between 0 & 100 is percentage of the BlendColor that will be opaque
    '   Example. If BlendOpacity=30 then the image will be 70% original color & 30% BlendColor

    If m_Handle = 0& Then Exit Function
    If BlendOpacity < 1 Then     ' background color won't be included in calcs; don't waste time
        BlendToColor = True
        Exit Function
    End If
    
    Dim tSA As SafeArray, srcBytes() As Byte
    Dim X As Long, Y As Long
    Dim blendR As Long, blendB As Long, blendG As Long
    Dim srcPct As Long, srcAlpha As Byte
    Dim blendLUT(0 To 255) As Long
    
    ' validate BlendOpacity doesn't exceed max value
    If BlendOpacity > 100 Then BlendOpacity = 100
    ' calculate what percentage of source color will be used
    srcPct = (100 - BlendOpacity)
    
    ' speed up processing on larger images; pretty much no effect for small images
    For X = 1 To 255
        blendLUT(X) = srcPct * X
    Next
    
    ' extract the RGB elements from the BlendColor & premultiply by BlendOpacity
    blendR = (BlendColor And &HFF) * BlendOpacity
    blendG = ((BlendColor \ &H100&) And &HFF) * BlendOpacity
    blendB = ((BlendColor \ &H10000) And &HFF) * BlendOpacity
    
    iparseOverlayHost_Byte srcBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    For Y = 0 To m_Height - 1
        For X = 0 To m_Width * 4 - 1 Step 4
            srcAlpha = srcBytes(X + 3, Y)
            If Not srcAlpha = 0 Then
                ' blend source pixel to BlendColor
                srcBytes(X, Y) = (((blendLUT(srcBytes(X, Y))) + blendB) * srcAlpha) \ 25500
                srcBytes(X + 1, Y) = ((blendLUT((srcBytes(X + 1, Y))) + blendG) * srcAlpha) \ 25500
                srcBytes(X + 2, Y) = (((blendLUT(srcBytes(X + 2, Y))) + blendR) * srcAlpha) \ 25500
            End If
        Next
    Next
    
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    BlendToColor = True
    
End Function

Public Function GetDroppedFileNames(OLEDragDrop_DataObject As DataObject) As Boolean

    ' This function is only included to make things a little easier for those that want
    ' to fully support unicode filenames whereas VB only provides ANSI filenames.
    ' It is designed to be called from your OLEDragDrop event, passing that event's Data
    ' parameter's object like so: Possible example from your project
    
'    Private Sub Picture1_OLEDragDrop(Data As DataObject, Effect As Long, Button As Integer, Shift As Integer, X As Single, Y As Single)
'        ' simmple OLE drag/drop example, assuming this class declared as cImage
'
'        If cImage.GetDroppedFileNames(Data) = True Then
'            [add code here]. The Data object will contain unicode filenames as necessary
'        Else
'            [add code here]. No file names were dropped, something else was
'        End If
'
'    End Sub
    
    ' Caution: Editing this routine after it has been called may crash the IDE
    ' I believe I have fixed that issue but am not 100% positive
    ' See posting by John Kleinen for more information regarding this method of calling GetData
    ' http://www.planet-source-code.com/vb/scripts/ShowCode.asp?txtCodeId=49268&lngWId=1
    
    If OLEDragDrop_DataObject Is Nothing Then Exit Function
    If OLEDragDrop_DataObject.GetFormat(vbCFFiles) = False Then Exit Function
    
    Dim fmtEtc As FORMATETC, pMedium As STGMEDIUM
    Dim dFiles As DROPFILES
    Dim Vars(0 To 1) As Variant, pVars(0 To 1) As Long, pVartypes(0 To 1) As Integer
    Dim varRtn As Variant
    Dim iFiles As Long, iCount As Long, hDrop As Long
    Dim lLen As Long, sFiles() As String
    
    Dim IID_IDataObject As Long ' IDataObject Interface ID
    Const IDataObjVTable_GetData As Long = 12 ' 4th vtable entry
    Const CC_STDCALL As Long = 4&
    Const TYMED_HGLOBAL = 1
    Const DVASPECT_CONTENT = 1

    With fmtEtc
        .cfFormat = vbCFFiles         ' same as CF_DROP
        .lIndex = -1                    ' want all data
        .TYMED = TYMED_HGLOBAL        ' want global ptr to files
        .dwAspect = DVASPECT_CONTENT  ' no rendering
    End With

    ' The IDataObject pointer is 16 bytes after VBs DataObject
    CopyMemory IID_IDataObject, ByVal ObjPtr(OLEDragDrop_DataObject) + 16, 4&
    
    ' Here we are going to do something very new to me and kinda cool
    ' Since we know the objPtr of the IDataObject interface, we therefore know
    ' the beginning of the interface's VTable
    
    ' So, if we know the VTable address and we know which function index we want
    ' to call, we can call it directly using the following OLE API. Otherwise we
    ' would need to use a TLB to define the IDataObject interface since VB doesn't
    ' 't expose it. This has some really neat implications if you think about it.
    ' The IDataObject function we want is GetData which is the 4th function in
    ' the VTable... http://msdn2.microsoft.com/en-us/library/ms688421.aspx
    
    pVartypes(0) = vbLong: Vars(0) = VarPtr(fmtEtc): pVars(0) = VarPtr(Vars(0))
    pVartypes(1) = vbLong: Vars(1) = VarPtr(pMedium): pVars(1) = VarPtr(Vars(1))
    
    ' The variants are required by the OLE API: http://msdn2.microsoft.com/en-us/library/ms221473.aspx
    If DispCallFunc(IID_IDataObject, IDataObjVTable_GetData, CC_STDCALL, _
                        vbLong, 2, pVartypes(0), pVars(0), varRtn) = 0 Then
        
        If pMedium.Data = 0 Then
            Exit Function      ' nothing to do
        Else
            ' we have a pointer to the files, kinda sorta
            CopyMemory hDrop, ByVal pMedium.Data, 4&
            If Not hDrop = 0 Then
                ' the hDrop is a pointer to a DROPFILES structure
                ' copy the 20-byte structure for our use
                CopyMemory dFiles, ByVal hDrop, 20&
            End If
        End If
        
        If dFiles.fWide = 0 Then ' ansi
            GlobalFree pMedium.Data
        
        Else
            ' use the pFiles member to track offsets for file names
            dFiles.pFiles = dFiles.pFiles + hDrop
            ReDim sFiles(1 To OLEDragDrop_DataObject.files.Count)
        
            For iCount = 1 To UBound(sFiles)
                ' get the length of the current file & multiply by 2 because it is unicode
                ' lstrLenW is supported in Win9x
                lLen = lstrlenW(ByVal dFiles.pFiles) * 2
                sFiles(iCount) = String$(lLen \ 2, 0)    ' build a buffer to hold the file name
                CopyMemory ByVal StrPtr(sFiles(iCount)), ByVal dFiles.pFiles, lLen ' populate the buffer
                ' move the pointer to location for next file, adding 2 because of a double null separator/delimiter btwn file names
                dFiles.pFiles = dFiles.pFiles + lLen + 2
            Next
            
            GlobalFree pMedium.Data
            OLEDragDrop_DataObject.files.Clear
            For iCount = 1 To iCount - 1
                OLEDragDrop_DataObject.files.Add sFiles(iCount), iCount
            Next
            
        End If
        
        GetDroppedFileNames = True

    End If
    
End Function

Public Function GetPastedFileNames(ListOfFiles() As String) As Long

    ' Another support function for unicode filenames. The filenames returned by
    ' VB's Clipboard object only contains ANSI.
    
    ' This function will return the number of file names in the clipboard, if any.
    ' The returned string array will contain the unicode/ansi filenames as needed.
    ' If the function returns zero, then the string array is not valid

    Dim hDrop As Long
    Dim sFile As String
    Dim lLen As Long
    Dim iCount As Long
    Dim dFiles As DROPFILES

   ' Get handle to CF_HDROP if any:
   If OpenClipboard(0&) = 0 Then Exit Function
        
    hDrop = GetClipboardData(vbCFFiles)
    If Not hDrop = 0 Then   ' then copied/cut files exist in memory
        iCount = DragQueryFile(hDrop, -1&, vbNullString, 0)
        ' the hDrop is a pointer to a DROPFILES structure
        ' copy the 20-byte structure for our use
        CopyMemory dFiles, ByVal hDrop, 20&
        ' use the pFiles member to track offsets for file names
        dFiles.pFiles = dFiles.pFiles + hDrop
    
        ReDim ListOfFiles(1 To iCount)
    
        For iCount = 1 To iCount
            If dFiles.fWide = 0 Then   ' ANSI text, use API to get file name
               lLen = DragQueryFile(hDrop, iCount - 1, vbNullString, 0&)       ' query length
               ListOfFiles(iCount) = String$(lLen, 0)                          ' set up buffer
               DragQueryFile hDrop, iCount - 1, ListOfFiles(iCount), lLen + 1  ' populate buffer
            Else
               ' get the length of the current file & multiply by 2 because it is unicode
               ' lstrLenW is supported in Win9x
               lLen = lstrlenW(ByVal dFiles.pFiles) * 2
               sFile = String$(lLen \ 2, 0)    ' build a buffer to hold the file name
               CopyMemory ByVal StrPtr(sFile), ByVal dFiles.pFiles, lLen ' populate the buffer
               ' move the pointer to location for next file, adding 2 because of a double null separator/delimiter btwn file names
               dFiles.pFiles = dFiles.pFiles + lLen + 2
               ' add our file name to the list.
               ListOfFiles(iCount) = sFile ' this may contain unicode characters if your system supports it
           End If
        Next
        
        GetPastedFileNames = iCount - 1
        
    End If
    CloseClipboard

End Function

Public Sub SwapDIBs(SwapFromDIB As c32bppDIB)
    ' Useful for more advanced users
    ' This class has no way for you to manually set the class' DIB handle and pointer.
    ' Should you be doing your own manipulations on another DIB and want to use its
    ' DIB in this class, you could simply Set thisClass=otherClass. However, if you
    ' have other cached references to this class or want to keep this class'
    ' object pointer from changing, then this routine is for you. The only requirement
    ' is that the other DIB must exist in a c32bppDIB class also.
    
    ' Parameter:
    '   SwapFromDIB :: the c32bppDIB class holding the other DIB.
    
    If SwapFromDIB Is Nothing Then Exit Sub
    If SwapFromDIB.Handle = 0& Then ' the DIB
        DestroyDIB
        Exit Sub
    End If

    Set m_GDIplus = Nothing
    If SwapFromDIB.Width < 0& Then
        ' flag indicating that this is being called within the fromDIB's context
        With SwapFromDIB
            m_Handle = .Handle
            m_Pointer = .BitsPointer
            m_Width = -.Width
            m_Height = .Height
            m_Format = .ImageType
            m_AlphaImage = .Alpha
            If .GetOrginalFormat(m_ImageByteCache) = False Then Erase m_ImageByteCache
        End With
    Else
        Dim newHandle As Long, newPtr As Long
        Dim newWidth As Long, newHeight As Long
        Dim newType As eImageFormat
        Dim newAlpha As Boolean, origBytes() As Byte
        
        With SwapFromDIB
            newHandle = .Handle
            newPtr = .BitsPointer
            newWidth = .Width
            newHeight = .Height
            newType = .ImageType
            newAlpha = .Alpha
            .GetOrginalFormat origBytes()
        End With
        
        m_Width = -m_Width      ' set flag so next line know it is setting props now
        SwapFromDIB.SwapDIBs Me ' have other dib copy our dib's properties
        
        m_Handle = newHandle    ' now set our dib's properties
        m_Pointer = newPtr
        m_Width = newWidth
        m_Height = newHeight
        m_Format = newType
        m_AlphaImage = newAlpha
        m_ImageByteCache = origBytes
    
    End If
    
End Sub


' NEW SECTION *******************************************************************************
'                   CLASS TO CLASS COMMUNICATION METHODS
' *******************************************************************************************

Friend Sub SetOriginalFormat(inStream() As Byte)

    ' Purpose: Pass the original image file/bytes to this DIB from another DIB
    ' This is only called by the CopyImageTo function. Note it is Friend vs Public
    
    m_ImageByteCache() = inStream()

End Sub


' NEW SECTION *******************************************************************************
'                       LOCAL SUPPORT FUNCTIONS FOR THIS CLASS ONLY
' *******************************************************************************************


Private Function spt_RotateImage(ByVal hDC As Long, ByVal Angle As Single, _
                            ByVal TopX As Long, ByVal TopY As Long, _
                            ByVal destWidth As Long, ByVal destHeight As Long, _
                            ByVal SrcX As Long, ByVal SrcY As Long, _
                            ByVal srcWidth As Long, ByVal srcHeight As Long, _
                            ByVal Opacity As Long, _
                            ByRef destHostDIB As c32bppDIB, _
                            ByVal grayScale As eGrayScaleFormulas, _
                            ByVal LightAdjustment As Single) As Boolean

    ' Internal function will rotate an image by passed Angle and render to the passed hDC.
    ' This function simultaneously rotates, scales and then blends.
    
    ' Note: Me.HighQualityInterpolation property setting is used to determine quality of rotation/scaling
    ' Called only by the Render method
    
    
    ' first see if we can do this via GDI+
    If Me.isGDIplusEnabled Then
        Dim cGDIp As cGDIPlus
        If m_GDIplus Is Nothing Then
            Set cGDIp = New cGDIPlus
        Else
            Set cGDIp = m_GDIplus
        End If
        If cGDIp.RenderGDIplus(Me, hDC, Angle, Opacity, TopX, TopY, destWidth, destHeight, SrcX, SrcY, srcWidth, srcHeight, m_StretchQuality, grayScale, m_GDItoken, LightAdjustment) = True Then
            spt_RotateImage = True
            Exit Function
        End If
    End If
        
    Dim cosTx As Double, sinTx As Double
    Dim cosTy As Double, sinTy As Double
    Dim scalerX As Double, scalerY As Double
    
    Dim maxX As Long, maxY As Long, maxSize As Long
    Dim ctrX As Long, ctrY As Long
    Dim xOffset As Double, yOffset As Double
    Dim targetX As Double, targetY As Double
    
    Dim dSA As SafeArray, sSA As SafeArray
    Dim dBytes() As Byte, sBytes() As Byte
    Dim lRow As Long, lCol As Long
    
    ' following variables are used for the BiLinear interpolation only
    Dim tgtY As Long, tgtX As Long
    Dim srcPixel As Long, dstPixel As Long, srcRow As Long
    Dim edgeOffsetX As Long, edgeOffsetY As Long
    Dim fY As Double, fX As Double, iX As Long, iY As Long
    Dim R As Double, G As Double, B As Double, a As Double
    
    ' handle mirroring as needed. Fix negative values as needed
    If spt_MirrorDIB(SrcX, SrcY, srcWidth, srcHeight, destWidth, destHeight, sBytes(), , LightAdjustment) = False Then
        ' if light adjustments, preprocess bytes
        If Not LightAdjustment = 0! Then Call spt_LightenDarken(Me, LightAdjustment, sBytes, SrcX, SrcY, srcWidth, srcHeight)
    End If
    
    ' determine the scale to use based off the passed
    ' source and destination widths,heights
    scalerX = destWidth / srcWidth      ' scale x coordinates
    scalerY = destHeight / srcHeight    ' scale y coordinates
    
    ' convert angle to radians & calculate scaled COS/SIN of the angle
    ' Multiplying by Negative so we rotate clockwise
    sinTx = -((Angle Mod 360) * (4& * Atn(1))) / 180  ' convert Degree to Radian
    cosTy = Cos(sinTx) / scalerY      ' get cosine of angle (Y coordinates)
    sinTy = Sin(sinTx) / scalerY      ' get sine of angle (Y coordinates)
    
    cosTx = Cos(sinTx) / scalerX      ' get cosine of angle (X coordinates)
    sinTx = Sin(sinTx) / scalerX      ' get sine of angle  (X coordinates)
    ' determine maximum size image we will need to cover any angle
    maxSize = Sqr(destWidth * destWidth + destHeight * destHeight)
    
    On Error GoTo eh
    ' create a temporary array to hold the rotated image
    ReDim dBytes(0 To maxSize * 4& - 1, 0 To maxSize - 1)
    
    ' overlay the temp DIB and our host DIB
    If iparseIsArrayEmpty(VarPtrArray(sBytes)) = 0& Then
        iparseOverlayHost_Byte sBytes, VarPtr(sSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    End If
    
    ' bottom up dib, vertical offset is from bottom, not top
    SrcY = UBound(sBytes, 2) - srcHeight - SrcY + 1&
    ' set up offsets for calculating rotated/scaled points
    maxX = srcWidth + SrcX      ' the right edge of the source image
    maxY = srcHeight + SrcY     ' the bottom edge of the source image
    ' determine where the center of the source selected bounds falls within the maxSize bounds
    ctrX = srcWidth \ 2 + SrcX  ' the center of the source image
    ctrY = srcHeight \ 2 + SrcY
    ' calculate offsets to "center" destination image in its maxSize window
    xOffset = ((maxSize - srcWidth) \ 2) - SrcX
    yOffset = ((maxSize - srcHeight) \ 2) - SrcY
    
    ' here's where we apply all of the above offsets
    ' This is a bit complicated because we allow any angle rotation,
    ' and also allowing portions of the image or entire image to be rotated
    ' and also allows scaling up or down
    If m_StretchQuality = False Then
    
        For lRow = -yOffset To maxSize - yOffset - 1&
            
            ' Calculate the point in the source image needed for the rotated point in destination image
            ' This only needs to be done once per image scan line & contains many math executions
            targetX = (-xOffset - ctrX) * cosTx + (lRow - ctrY) * sinTx + ctrX
            targetY = (lRow - ctrY) * cosTy - (-xOffset - ctrX) * sinTy + ctrY
        
            For lCol = -xOffset To maxSize - xOffset - 1&
            
                ' validate rotated point is within bounds of the image/portion
                If targetY >= SrcY Then                    ' is Y within area of source?
                    If targetY < maxY Then
                        If targetX >= SrcX Then            ' is X within area of source?
                            If targetX < maxX Then
                                ' validation complete, copy pixel to destination
                                CopyMemory dBytes((xOffset + lCol) * 4&, yOffset + lRow), sBytes(Int(targetX) * 4&, Int(targetY)), 4&
                            End If
                        End If
                    End If
                End If
        
                ' Excellent optimization I found (wish I remember where so I can give credit)
                ' But the logic is simple: once the initial X,Y coordinates for the
                ' current source row is found, the next point is always a constant value from
                ' the last point. In this case, increments of cosT & sinT.
                ' Therefore we don't need to recalculate targetX,targetY for every point
                ' since we did it once for current row. Thus we have 2 simple additions per pixel
                ' vs 4 multiplications & 12 additions per pixel
                targetX = targetX + cosTx
                targetY = targetY - sinTy
            Next
        Next
        
    Else
        ' BiLinear interpolation with rotation. This can produce better quality
        ' results but takes significantly (x4) longer. Recommend using this option
        ' when you need a static rotated image, but when rotating via a scrollbar
        ' or some other method where scrolling is expected to be repeated often,
        ' then use the non-BiLinear method. COMPILED IS MUCH FASTER !!!
        
        ' Up to 4 source pixels (16 bytes) are blended for each destination pixel (4 bytes)
        srcWidth = maxX - 1& ' reuse variable & subtract now vs subtraction for every pixel in the image
        For lRow = -yOffset To maxSize - yOffset - 1&
            
            ' Calculate the rotated point in relation to host image
            ' These calcs only needs to be done once per image scan line
            targetX = (-xOffset - ctrX) * cosTx + (lRow - ctrY) * sinTx + ctrX
            targetY = (lRow - ctrY) * cosTy - (-xOffset - ctrX) * sinTy + ctrY
        
            For lCol = -xOffset To maxSize - xOffset - 1&
                If targetY >= SrcY Then                    ' is Y within area of source?
                    If targetY < maxY Then
                        If targetX >= SrcX Then            ' is X within area of source?
                            If targetX < maxX Then
                            
                                tgtY = Int(targetY)     ' whole number of the double
                                If tgtY = 0& Then       ' for top down images check for last row vs 0
                                    ' last row of source image, will use only this row
                                    edgeOffsetY = 0&
                                    fY = 0#
                                Else
                                    ' will use this row & next row for blending
                                    edgeOffsetY = 1&
                                    fY = 1# - (targetY - tgtY) ' for top down images, use: fY = targetY-tgtY
                                    ' ^ Y coordinate fraction; pct of next vertical pixel that is used
                                End If
                                               
                                R = 0#: G = 0#: B = 0#: a = 0#
                                
                                tgtX = Int(targetX)  ' coordinate rounded down to whole number
                                If tgtX = srcWidth Then
                                    ' at far edge of source image, will use only this pixel for blending
                                    edgeOffsetX = 0&
                                    fY = 0#: fX = 0#
                                Else
                                    ' will use this pixel and next pixel for blending
                                    edgeOffsetX = 1&
                                    fX = targetX - tgtX
                                    ' ^ X coordinate fraction, pct of next horizontal pixel that is used
                                End If
                                
                                For iY = 0& To edgeOffsetY
                                    scalerY = Abs(iY - fY)   ' percentage of current row's pixel to blend
                                    
                                    If Not scalerY = 1& Then  ' else zero
                                        srcRow = tgtY - iY    ' for top down images Add iY vs subtracting
                                        For iX = 0& To edgeOffsetX
                                            scalerX = Abs(fX - iX)   ' percentage of current column's pixel to blend
                                            
                                            If Not scalerX = 1& Then  ' else zero
                                                scalerX = (1# - scalerX) * (1# - scalerY) ' combine percentages
                                                srcPixel = (tgtX + iX) * 4&
                                                B = B + sBytes(srcPixel, srcRow) * scalerX
                                                G = G + sBytes(srcPixel + 1&, srcRow) * scalerX
                                                R = R + sBytes(srcPixel + 2&, srcRow) * scalerX
                                                a = a + sBytes(srcPixel + 3&, srcRow) * scalerX
                                            End If
                                            
                                        Next
                                    End If
                    
                                Next
                                dstPixel = (xOffset + lCol) * 4&
                                iY = lRow + yOffset
                                dBytes(dstPixel, iY) = Int(B)
                                dBytes(dstPixel + 1&, iY) = Int(G)
                                dBytes(dstPixel + 2&, iY) = Int(R)
                                dBytes(dstPixel + 3&, iY) = Int(a)
                            End If
                        End If
                    End If
                End If
            targetX = targetX + cosTx
            targetY = targetY - sinTy
            Next
        Next
    End If
    
    If sSA.pvData = 0& Then ' image was also mirrored
        Erase sBytes()
    Else                    ' remove overlay of non-mirrored image
        iparseOverlayHost_Byte sBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    End If
    
    xOffset = (TopX + destWidth \ 2) - (maxSize \ 2)
    yOffset = (TopY + destHeight \ 2) - (maxSize \ 2)
    
    ' now render it.  We won't pass some parameters because they have been handled here or don't apply with this temp DIB
    spt_Win9xBlend hDC, dBytes(), 0, 0, xOffset, yOffset, maxSize, maxSize, (Opacity * 255) \ 100, destHostDIB, grayScale, 0!
    
    
eh:
    If Err Then
        Stop
        Err.Clear ' troubleshooting only, should be removed before compiling to final app
        Resume
    End If
End Function

Private Function spt_LoadPictureEx(ByVal FileHandle As Long, FileName As String, aStream() As Byte, _
                            cX As Long, cY As Long, _
                            streamOffset As Long, streamLength As Long, _
                            SaveFormat As Boolean, bitDepth As Long) As Boolean
    
    ' PURPOSE: Marshal passed file/array to image classes for conversion to 32bpp image
    ' For parameter information, see LoadPicture_File & LoadPicture_Stream
    
    Me.DestroyDIB
    
    ' various image parsers, in order of precedence
    ' All 4 recognize transparency
    Dim cPNG As cPNGparser  ' very fast to abort if not a PNG file
    Dim cGIF As cGIFparser  ' very fast to abort if not a GIF file
    Dim cICO As cICOparser  ' must parse key parts of a file. handles icons & Vista PNG Icons
    Dim cBMP As cBMPparser  ' catchall. Handles bitmaps, wmf, emf & jpgs
    Dim cGDI As cGDIPlus
    
    Dim bReturn As Boolean  ' function return value
    Dim rtnRead As Long
    
    ' validate passed desired icon sizes
    If cX < 0& Then cX = 0&
    If cY < 0& Then cY = 0&
    If bitDepth < 0& Then
        bitDepth = 32
    ElseIf bitDepth > 32 Then
        bitDepth = 32
    End If
    
    Set cPNG = New cPNGparser   ' see if image is a PNG; aborts quickly if not
    If FileHandle = 0 Then
        bReturn = cPNG.LoadStream(aStream(), Me, streamOffset, streamLength, m_GDItoken)
    Else     ' note: processing from file is slightly faster than via array
        bReturn = cPNG.LoadFile(FileHandle, FileName, Me, m_GDItoken)
        'If bReturn = True Then Close #fileNum         ' close the file
    End If
    If Err Then MsgBox Err.Description
    Set cPNG = Nothing
    If Not bReturn Then
        If Not FileHandle = 0& Then
            streamOffset = 0&
            streamLength = GetFileSize(FileHandle, 0&)
            'streamLength = LOF(fileNum) ' cache length of file
            ReDim aStream(streamOffset To streamLength - 1&)
            'Get #fileNum, , aStream()   ' populate our stream with the file contents
            'Close #fileNum
            SetFilePointer FileHandle, 0&, 0&, 0&
            ReadFile FileHandle, aStream(streamOffset), streamLength, rtnRead, ByVal 0&
        End If
        Set cGIF = New cGIFparser ' what about a GIF; aborts quickly if not
        bReturn = cGIF.LoadStream(aStream(), Me, streamOffset, streamLength)
        Set cGIF = Nothing
        If Not bReturn Then
            Set cICO = New cICOparser   ' will process Vista PNG icon if needed
            bReturn = cICO.LoadStream(aStream(), cX, cY, Me, streamOffset, streamLength, bitDepth, m_GDItoken)
            Set cICO = Nothing
            If Not bReturn Then ' check for bmp, emf, wmf & jpg << last chance
                Set cBMP = New cBMPparser
                bReturn = cBMP.LoadStream(aStream(), Me, streamOffset, streamLength)
                Set cBMP = Nothing
            End If
        End If
    End If
    If m_Handle = 0& Then ' hmmm, not an image file processed here, we can try
                          ' one more thing... Send it GDI+ if possible
        If Me.isGDIplusEnabled Then
            If m_GDIplus Is Nothing Then
                Set cGDI = New cGDIPlus
            Else
                Set cGDI = m_GDIplus
            End If
            If cGDI.GDIplusLoadPNG(FileName, aStream(), Me, m_GDItoken) = True Then
                ' it worked, whatever file type it was. Convert it to PNG
                If SaveFormat = True Then
                    Call cGDI.SaveToPNG(vbNullString, aStream, Me, m_GDItoken)
                    FileHandle = 0& ' prevent next IF from trying to re-load it from file if applicable
                End If
                Me.ImageType = imgPNG
            End If
        End If
    End If
    If Not m_Handle = 0 Then
        If SaveFormat = True Then ' we will cache the original bytes
            If iparseIsArrayEmpty(VarPtrArray(aStream)) = 0& And Not FileHandle = 0& Then
                ' we loaded the image from the file and not a stream (PNG), need to get stream
                'fileNum = FreeFile()
                'Open FileName For Binary Access Read As #fileNum
                If streamLength = 0& Then streamLength = GetFileSize(FileHandle, 0&)
                ReDim m_ImageByteCache(0 To streamLength - 1)
                SetFilePointer FileHandle, 0&, 0&, 0&
                ReadFile FileHandle, m_ImageByteCache(0), streamLength, rtnRead, ByVal 0&
                'Get #fileNum, 1, m_ImageByteCache
                'Close #fileNum
            Else
                m_ImageByteCache() = aStream()
            End If
        End If
        spt_LoadPictureEx = True
    End If

End Function

Private Function spt_pvResize(ByVal destDC As Long, _
                        rSizedBytes() As Byte, rMirror() As Byte, _
                        Optional tHost As c32bppDIB, _
                        Optional ByVal SrcX As Long, Optional ByVal SrcY As Long, _
                        Optional ByVal srcWidth As Long, Optional ByVal srcHeight As Long, _
                        Optional ByVal destX As Long, Optional ByVal destY As Long, _
                        Optional ByRef destWidth As Long, Optional ByRef destHeight As Long, _
                        Optional ByRef LightAdjustment As Single = 0!) As Boolean
                            
    ' Function resizes an alpha image, maintaining premultiplied pixels & alpha values
    ' Code originally by Carles P.V. but significantly modified for this project.
    
    ' Parameters:
    ' destDC :: DC being rendered to, may be null
    ' rSizedbytes() : array to hold resized alpha section; not used if tHost is not Nothing
    ' tHost : when resizing to another DIB class, the destination DIB class
    ' srcX,Y : the coordinates of the source image to start resizing from
    ' srcWidth,srcHeight : the width/height of the source image to resize from
    ' destX,Y : the coordinates of the destination image to resize to
    ' destWidth,destHeight : the width/height of the destination image to resize to

    If srcWidth = 0& Then srcWidth = m_Width
    If srcHeight = 0& Then srcHeight = m_Height

    Dim aNewBits() As Byte, dSA As SafeArray   ' new size, overlay of DIB pointer
    Dim aOldBits() As Byte, tSA As SafeArray   ' old size, overlay of DIB pointer
    
    Dim xLUdbl() As Double                     ' look up table (LUT)
    Dim xRatio As Double, yRatio As Double     ' scaled ratios
    Dim srcPixel As Long, dstPixel As Long     ' source/destination pixel locations
    Dim lCol As Long, lRow As Long             ' loop variables
    
    Dim newWidth As Long, newHeight As Long
    
    ' following used with BiLinear scaling
    Dim fX As Double, fY As Double
    Dim tgtX As Long, tgtY As Long
    Dim edgeOffsetX As Long, edgeOffsetY As Long
    Dim iX As Long, iY As Long
    Dim R As Double, G As Double, B As Double, a As Double
    Dim scalerX As Double, scalerY As Double
    
    ' fill in optional parameters
    If Not tHost Is Nothing Then
        newWidth = tHost.Width
        newHeight = tHost.Height
        ' Scaling ratio (ratio of actual image to scaled image)
        xRatio = srcWidth / newWidth
        yRatio = srcHeight / newHeight
        If newWidth > tHost.Width Then newWidth = tHost.Width
        If newHeight > tHost.Height Then newHeight = tHost.Height
    Else
        newWidth = Abs(destWidth)
        newHeight = Abs(destHeight)
        
        ' Scaling ratio (ratio of actual image to scaled image)
        xRatio = srcWidth / newWidth
        yRatio = srcHeight / newHeight

        ' safety checks, recalculation of bounding destination size
        ' if not done, we could very easily access unallocated memory.
        If destX < 0 Then   ' negative DC offset
            newWidth = newWidth + destX    ' reduce width to process
            destX = -destX                 ' used to offset LUT; adjust so not processing bytes not used
        Else
            destX = 0&                        ' fits within destination bitmap; no offsetting needed
        End If
        
        ' now to check the vertical
        If destY < 0& Then  ' negative DC offset
            newHeight = newHeight + destY
            destY = 0&
        Else
            destY = 0&
        End If
        
    End If
    If newHeight < 1& Or newWidth < 1& Then Exit Function
    
    ' set DMA overlays on destination & source
    If tHost Is Nothing Then
        ReDim rSizedBytes(0& To newWidth * 4& - 1&, 0& To newHeight - 1&)
        dSA.pvData = VarPtr(rSizedBytes(0&, 0&))
    Else
        dSA.pvData = tHost.BitsPointer ' called by CopyImageTo & Resize routines
    End If
    iparseOverlayHost_Byte aNewBits, VarPtr(dSA), 2, newHeight, newWidth * 4&, dSA.pvData ' overlay DMA array
    
    If iparseIsArrayEmpty(VarPtrArray(rMirror)) = 0& Then
        iparseOverlayHost_Byte aOldBits, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    Else ' source is the mirrored DIB; clipped as needed
        iparseOverlayHost_Byte aOldBits, VarPtr(tSA), 2, UBound(rMirror, 2) + 1&, UBound(rMirror, 1) + 1&, VarPtr(rMirror(0&, 0&))    ' overlay DMA array
    End If
    
    On Error GoTo eh
    
    SrcY = UBound(aOldBits, 2) - srcHeight - SrcY + 1&     ' adjust Y position in source for bottom up DIBs
    
    If (m_StretchQuality = False) Then ' nearest neighbor algorithm (very fast but lowest quality)
        
        ' Scaling LUT, cache actual X position of DIB in relation to scaled X
        ' Cache one scan line of X coords so we don't have to calculate for every pixel
        ReDim xLUdbl(0 To newWidth - 1&)
        For lCol = 0 To newWidth - 1&
            ' offset destX used for negative coordinates, X is location in source to start blending at
            xLUdbl(lCol) = Int(((lCol + destX) * xRatio) + SrcX) * 4&
        Next
        
        For lRow = newHeight - 1& To 0& Step -1&
            '^ current scanline for the scaled image
            ' offset destY is used for negative coordinates
            srcPixel = Int((lRow + destY) * yRatio) + SrcY  ' recalcualted once per scanline
            ' current scanline for the scaled image
            dstPixel = 0&
            For lCol = 0& To newWidth - 1&
                ' copy into resized array the nearest raw/actual pixel
                CopyMemory aNewBits(dstPixel, lRow), aOldBits(Int(xLUdbl(lCol)), srcPixel), 4&
                dstPixel = dstPixel + 4&
            Next lCol
        Next lRow
        
    Else
        
        ' BiLinear interoplation, up to 4 source pixels (16 bytes) are blended for each destination pixel (4 bytes)
 
        ReDim xLUd(0 To newWidth - 1&)   ' work with doubles, we need the decimal portions
        ' Cache one scan line of X coords so we don't have to calculate for every pixel
        For lCol = 0& To newWidth - 1&
            ' offset destX used for negative coordinates, X is location in source to start blending at
            xLUd(lCol) = (((lCol + destX) * xRatio) + SrcX)
        Next
        srcWidth = srcWidth - 1& ' subtract now vs subtracting in loop below
        For lRow = newHeight - 1& To 0& Step -1&
            
            fY = (lRow + destY) * yRatio + SrcY ' get the scaled source row
            tgtY = Int(fY)              ' get whole number of double
            If tgtY = 0& Then         ' for top down images, test for last row vs 0
                ' last row of source image, will use only this row
                edgeOffsetY = 0&
                fY = 0#
            Else
                ' will use this row & next row for blending
                edgeOffsetY = 1&
                fY = Abs(1# - (fY - tgtY)) ' for top down images, use fY = fY-tgtY
                ' ^ Y coordinate fraction; pct of next vertical pixel that is used
            End If
            
            For lCol = 0& To newWidth - 1&
                
                R = 0#: G = 0#: B = 0#: a = 0#
                
                tgtX = Int(xLUd(lCol))  ' coordinate rounded down to whole number
                If tgtX = srcWidth Then
                    ' at far edge of source image, will use only this pixel for blending
                    edgeOffsetX = 0&
                    fX = 0#
                Else
                    ' will use this pixel and next pixel for blending
                    edgeOffsetX = 1&
                    fX = xLUd(lCol) - tgtX
                    ' ^ X coordinate fraction, pct of next horizontal pixel that is used
                End If
                
                For iY = 0& To edgeOffsetY
    
                    scalerY = Abs(iY - fY)   ' percentage of current row's pixel to blend
                    If Not scalerY = 1# Then  ' else result will be zero
                    
                        For iX = 0& To edgeOffsetX
                            scalerX = Abs(fX - iX)   ' percentage of current column's pixel to blend
                            
                            If Not scalerX = 1# Then  ' else result will be zero
                                scalerX = (1# - scalerX) * (1# - scalerY) ' combine percentages
    
                                ' Build the blended RGB values. For top down images Add iY vs subtracting
                                srcPixel = (tgtX + iX) * 4&
                                B = B + aOldBits(srcPixel, tgtY - iY) * scalerX
                                G = G + aOldBits(srcPixel + 1&, tgtY - iY) * scalerX
                                R = R + aOldBits(srcPixel + 2&, tgtY - iY) * scalerX
                                a = a + aOldBits(srcPixel + 3&, tgtY - iY) * scalerX
    
                            End If
                        Next
                    End If
                Next
                iX = lCol * 4&
                ' update destination with adjusted pixel
                aNewBits(iX, lRow) = Int(B)
                aNewBits(iX + 1&, lRow) = Int(G)
                aNewBits(iX + 2&, lRow) = Int(R)
                aNewBits(iX + 3&, lRow) = Int(a)
            Next
        Next
    End If
    
    iparseOverlayHost_Byte aOldBits, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte aNewBits, 0, 0, 0, 0, 0  ' remove DMA overlay
    
    ' the passed destWidth,destHeight params are used when rendering; we are just sizing now
    destWidth = newWidth ' the parameter is ByRef, update it now
    destHeight = newHeight ' the parameter is ByRef, update it now
    Erase rMirror()
    
    If Not LightAdjustment = 0! Then
        Call spt_LightenDarken(Nothing, LightAdjustment, rSizedBytes(), SrcX, SrcY, srcWidth, srcHeight)
        LightAdjustment = 0!    ' reset, taken care of now
    End If
    
    spt_pvResize = True
eh:
    If Err Then
        Err.Clear   ' troubleshooting only, should be removed before compiling to final app
        Stop
        Resume
    End If
End Function

Private Sub spt_LightenDarken(cImage As c32bppDIB, ByVal Lightness As Single, rtnArray() As Byte, _
            SrcX As Long, SrcY As Long, srcWidth As Long, srcHeight As Long)

    ' called by Render, Win9xRender, MirrorDB, & spt_pvResize drawing routines as needed
    
    ' Routine will lighten or darken non-transparent pixels and pass results in rtnArray
    ' Parameters:
    '   cImage :: if Nothing, then rtnArray has source bytes
    '   Lightness :: values between -100 and 100 percent. -100 will produce blackness & 100 will produce whiteness
    '   rtnArray :: the array that will hold the modified bytes
    ' Note: when rtnArray is also the source array, it must contain pre-multiplied bytes
    '       and be a 2-dimensional, zero-bound arrray
    ' Checks on the array dimensions and bounds are not made here. They are guaranteed by calling routines
    
    If Lightness = 0! Then Exit Sub
    If Not cImage Is Nothing Then
        ' ensure an image exists if passing a dib class
        If cImage.Handle = 0 Then Exit Sub
    End If
    
    Dim tSA As SafeArray, srcBytes() As Byte
    Dim dSA As SafeArray, dstBytes() As Byte
    
    Dim X As Long, Y As Long, B As Long
    Dim dstX As Long, dstY As Long
    Dim tVal As Long, alphaAdj As Long
    Dim srcAlpha As Byte
    
    If cImage Is Nothing Then   ' source is the return array
        iparseOverlayHost_Byte srcBytes, VarPtr(tSA), 2, UBound(rtnArray, 2) + 1, UBound(rtnArray, 1) + 1, VarPtr(rtnArray(0, 0)) ' overlay DMA array
    Else                        ' source is a dib class
        iparseOverlayHost_Byte srcBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    End If
    
    If cImage Is Nothing Then ' source & destination are same
        dSA.pvData = tSA.pvData
    Else
        ReDim rtnArray(0 To srcWidth * 4 - 1, 0 To srcHeight - 1)
        dSA.pvData = VarPtr(rtnArray(0, 0))
    End If
    iparseOverlayHost_Byte dstBytes, VarPtr(dSA), 2, srcHeight, srcWidth * 4&, dSA.pvData ' overlay dest DMA array
    dstY = UBound(dstBytes, 2)
    
    Lightness = 255! * (Lightness / 100!) ' calculate pct of 255 that ligthness equates to
    
    ' when pre-multiplied bytes are in effect, we can't just add Lightness because
    '   the alpha value restricts what percent of the source rgb is actually used in relation to alpha.
    '   So we must modify lightness in relation to the alpha byte too.
    ' Separate loops used to prevent having to compare if the adjusted pixel is > 255 and also < 0
    
    If Lightness > 0! Then ' make lighter
          ' loop thru the rows
        For Y = UBound(srcBytes, 2) - SrcY To UBound(srcBytes, 2) - SrcY - srcHeight + 1 Step -1
            dstX = 0&
            For X = SrcX * 4& To (SrcX + srcWidth) * 4& - 1 Step 4&
                srcAlpha = srcBytes(X + 3&, Y)
                If srcAlpha = 0 Then
                    dstX = dstX + 4
                Else
                    ' calculate lightness in relation to alpha
                    alphaAdj = (srcAlpha * Lightness) \ 255
                    For B = X To X + 2&
                        tVal = srcBytes(B, Y) + alphaAdj
                        If tVal > srcAlpha Then
                            dstBytes(dstX, dstY) = srcAlpha
                        Else
                            dstBytes(dstX, dstY) = (tVal And &HFF)
                        End If
                        dstX = dstX + 1
                    Next
                    dstBytes(dstX, dstY) = srcAlpha   ' ensure alpha is copied too
                    dstX = dstX + 1
                End If
            Next
            dstY = dstY - 1
        Next
    Else    ' make darker
        For Y = UBound(srcBytes, 2) - SrcY To UBound(srcBytes, 2) - SrcY - srcHeight + 1 Step -1
            dstX = 0&
            For X = SrcX * 4& To (SrcX + srcWidth) * 4& - 1 Step 4&
                srcAlpha = srcBytes(X + 3&, Y)
                If srcAlpha = 0 Then
                    dstX = dstX + 4
                Else
                    ' calculate lightness in relation to alpha
                    alphaAdj = (srcAlpha * Lightness) \ 255
                    For B = X To X + 2&
                        tVal = srcBytes(B, Y) + alphaAdj
                        If tVal < 0& Then
                            dstBytes(dstX, dstY) = 0
                        Else
                            dstBytes(dstX, dstY) = (tVal And &HFF)
                        End If
                        dstX = dstX + 1
                    Next
                    dstBytes(dstX, dstY) = srcAlpha ' ensure alpha is copied too
                    dstX = dstX + 1
                End If
            Next
            dstY = dstY - 1
        Next
    End If
    
    ' remove overlays
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    SrcX = 0: SrcY = 0
End Sub


Private Function spt_MirrorDIB(ByRef SrcX As Long, ByRef SrcY As Long, _
                    ByVal srcWidth As Long, ByVal srcHeight As Long, _
                    ByRef newWidth As Long, ByRef newHeight As Long, _
                    ByRef mirrorBytes() As Byte, Optional ByRef tHost As c32bppDIB, _
                    Optional ByRef LightAdjustment As Single = 0!) As Boolean

    ' Parameters.
    ' srcX,Y :: position in source image where mirroring begins
    ' srcWidth,Height :: amount of source image that will be mirrored
    ' newWidth,Height :: size of destination mirrored image
    ' mirrorBytes() :: byte array to hold mirrored image
    ' tHost :: called by CopyImageTo & Resize when mirroring
    ' LightAdjustment :: values between -255 and 255
    
    ' is image being mirrored?
    If newWidth > 0& And newHeight > 0& Then Exit Function
    
    Dim tSA As SafeArray, srcBytes() As Byte
    Dim dSA As SafeArray, dstBytes() As Byte
    Dim X As Long, Y As Long, yOffset As Long, xOffset As Long
    
    iparseOverlayHost_Byte srcBytes, VarPtr(tSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay source DMA array
    If tHost Is Nothing Then    ' destination is mirrorBytes
        ReDim mirrorBytes(0& To srcWidth * 4& - 1&, 0& To srcHeight - 1&)
        dSA.pvData = VarPtr(mirrorBytes(0&, 0&))
    Else                        ' destination is passed DIB class
        dSA.pvData = tHost.BitsPointer ' called by CopyImageTo & Resize routines
    End If
    iparseOverlayHost_Byte dstBytes, VarPtr(dSA), 2, srcHeight, srcWidth * 4&, dSA.pvData ' overlay dest DMA array
    
    If newHeight < 0& Then
        If newWidth > 0& Then   ' flipping vertically only, faster/easier
            xOffset = srcWidth * 4& ' number of bytes to flip at once
            Y = SrcY    ' when flipping, our Y is adjusted from the bottom
            X = SrcX * 4&   ' starting X position in source
            For yOffset = srcHeight - 1& To 0& Step -1&
                CopyMemory dstBytes(0&, yOffset), srcBytes(X, Y), xOffset
                Y = Y + 1&   ' move source Y to next row
            Next
        Else   ' flipping both vertically/horizontally
            Y = SrcY ' when flipping vertically, adjust from the bottom
            For yOffset = srcHeight - 1& To 0& Step -1&
                X = (m_Width - SrcX) * 4& - 4&  ' X adjusted from right when flipping
                For xOffset = 0 To srcWidth * 4 - 4& Step 4&
                    CopyMemory dstBytes(xOffset, yOffset), srcBytes(X, Y), 4&
                    X = X - 4&  ' move source X to next pixel
                Next
                Y = Y + 1&   ' move source Y to next row
            Next
        End If
    
    Else  ' flipping horizontally only, same comments as above
        Y = m_Height - SrcY - 1& ' not fipping vertically, so read from bottom up
        For yOffset = srcHeight - 1& To 0& Step -1&
            X = (srcWidth + SrcX) * 4& - 4&
            For xOffset = 0 To srcWidth * 4 - 4& Step 4&
                CopyMemory dstBytes(xOffset, yOffset), srcBytes(X, Y), 4&
                X = X - 4&
            Next
            Y = Y - 1&
        Next
    End If
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    
    ' rendering routines will now use the mirrored byte array
    ' so we ensure the bounds parameters match the mirrored array bounds
    SrcX = 0&
    SrcY = 0&
    newWidth = Abs(newWidth)
    newHeight = Abs(newHeight)
    
    ' if light adjustments, preprocess bytes now
    If Not LightAdjustment = 0! Then
        Call spt_LightenDarken(Nothing, LightAdjustment, mirrorBytes(), SrcX, SrcY, newWidth, newHeight)
        LightAdjustment = 0!    ' reset, taken care of now
    End If
    spt_MirrorDIB = True
    
End Function

Private Function spt_Win9xBlend(ByVal destinationDC As Long, aResizedBytes() As Byte, _
                            ByVal SrcX As Long, ByVal SrcY As Long, _
                            ByVal destX As Long, ByVal destY As Long, _
                            ByVal destWidth As Long, ByVal destHeight As Long, _
                            ByVal GlobalAlpha As Long, tHost As c32bppDIB, _
                            ByVal grayScale As eGrayScaleFormulas, _
                            ByVal lightAdj As Single) As Boolean
    
    ' Function manually blends an alpha bitmap to a target DC
    
    ' Never called when GDI+ is available unless user forced isGDIplusEnabled=False.
    ' Used when AlphaBlend is not available or when AlphaBlend is available but cannot
    '   perform the graphic manipulation required
    
    ' Parameters identify the destination more than anything else. The source was already pre-processed if needed
    
    ' destinationDC :: DC to blend to
    ' aResizedBytes() :: array of bytes sized to target destination blend area.
    '   if array is null, then the destination size is same size as our DIB's image
    ' srcX,Y :: the position on source to begin blending
    ' destX,Y :: the position on destination where blending starts
    ' destWidth,Height :: the amount of columns/rows to blend
    ' globalAlpha :: the AlphaBlend global alpha value: between 0 and 255
    ' tHost :: blending will occur DIB to DIB vs DIB to DC
    ' grayScale :: if simultaneously grayscaling then the grayscale formula
    ' ligthAdj :: light adjustment value adds/subtracts -100 to 100 percent intensity per pixel
    
    ' Special note. Having problems rendering 32bpp DIBs to WinME; artifacts are being rendered
    ' from the alpha channel. Therefore, to completely eliminate this problem (hopefully), the
    ' destination array will be 24bpp vs 32bpp which will then be updated and rendered onto the
    ' destination DC.  32bpp would be easier, but oh well.

    ' through trial and error, the rule, rendering appears to be
    ' flip first, then stretch and/or rotate, then clip as needed
    
    Dim srcBytes() As Byte, srcSA As SafeArray
    Dim dstBytes() As Byte, dstSA As SafeArray
    Dim srcCol As Long, srcRow As Long
    Dim srcAlpha As Long, dstAlpha As Long
    Dim Y As Long, X As Long
    Dim sX As Long, sY As Long
    Dim dX As Long, dY As Long
    Dim dDC As Long, tDC As Long, hOldBmp As Long, hDib As Long
    Dim Rg As Single, Gg As Single, Bg As Single
    Dim gScaleByte As Long
    
    Dim BMPI As BITMAPINFO
    
    ' The following is just a wee bit confusing.
    ' Our source can be 2 different objects:
    '   1) Our host DIB
    '   2) The passed aResizedBytes() array if pre-processing was required
    ' Likewise, the destination can be 2 different objects
    '   1) A passed DC handle (DIB to 24bpp bitmap (render 32bpp to 24bpp)
    '   2) Another DIB class if tHost is passed (render 32bpp to 32bpp)
    ' So to use a common base for all possibilities, we use SafeArrays
    
    If iparseIsArrayEmpty(VarPtrArray(aResizedBytes)) = 0& Then
        If lightAdj = 0! Then
            srcSA.pvData = m_Pointer
            ' need to tweak for negative offsets
            If destX < 0& Then
                SrcX = SrcX - destX ' less area that needs to be rendered
                destWidth = destWidth + destX ' adjust amount of destination we copy
                destX = 0&                    ' set destination offset to zero
            End If
            If destY < 0& Then
                SrcY = SrcY - destY ' less area that needs to be rendered
                destHeight = destHeight + destY ' adjust amount of destination we copy
                destY = 0&                      ' set destination offset to zero
            End If
            SrcY = m_Height - SrcY  ' set DIB offset for 1st row to be blended
        Else
            ' if light adjustments, preprocess bytes
            spt_LightenDarken Me, lightAdj, aResizedBytes(), SrcX, SrcY, destWidth, destHeight
            srcSA.pvData = VarPtr(aResizedBytes(0, 0))
            SrcX = 0&: SrcY = destHeight
        End If
     Else ' source is the resized array
         srcSA.pvData = VarPtr(aResizedBytes(0, 0))
         If destX < 0& Then 'destX = 0& ' Abs(destX) ' when negative target coords are used, we set to
            destWidth = destWidth + destX
            SrcX = -destX: destX = 0&
         Else
            SrcX = 0&
         End If
         If destY < 0& Then 'destY = 0& 'Abs(destY) ' zero to match the resized array (zero-based)
            SrcY = destHeight + destY
            destHeight = destHeight + destY
            destY = 0&
        Else
            SrcY = destHeight
         End If
    End If
     
     If Not tHost Is Nothing Then
        ' need to ensure we won't be copying memory to unallocated memory
        If destWidth > tHost.Width Then destWidth = tHost.Width
        If destHeight > tHost.Height Then destHeight = tHost.Height
     End If
     If destWidth < 1& Or destHeight < 1& Then Exit Function  ' nothing to Blt, passed bad params
    
    If tHost Is Nothing Then
        ' we need the contents of the target DC, describe its bitmap
        With BMPI.bmiHeader
            .biSize = 40
            .biHeight = destHeight
            .biWidth = destWidth
            .biPlanes = 1
            .biBitCount = 24    ' see Special note above
        End With
        dDC = GetDC(0&)
        tDC = CreateCompatibleDC(dDC)
        If Not tDC = 0& Then
            hDib = CreateDIBSection(dDC, BMPI, 0&, dstSA.pvData, 0&, 0&)
        End If
        ReleaseDC 0&, dDC
        If tDC = 0& Or hDib = 0& Then Exit Function
        hOldBmp = SelectObject(tDC, hDib)
        BitBlt tDC, 0&, 0&, destWidth, destHeight, destinationDC, destX, destY, vbSrcCopy
        SelectObject tDC, hOldBmp
        DeleteDC tDC
        iparseOverlayHost_Byte dstBytes, VarPtr(dstSA), 2, destHeight, iparseByteAlignOnWord(24, destWidth), dstSA.pvData ' overlay DMA array
    
    Else
        ' DIB class to DIB class blending
        iparseOverlayHost_Byte dstBytes, VarPtr(dstSA), 2, tHost.Height, tHost.scanWidth, tHost.BitsPointer ' overlay DMA array
        dstSA.rgSABound(1) = -(tHost.Height - destY - destHeight)
        dstSA.rgSABound(3) = -destX * 4
    End If
    
    If srcSA.pvData = m_Pointer Then ' using DIB as source
        iparseOverlayHost_Byte srcBytes, VarPtr(srcSA), 2, m_Height, m_Width * 4&, m_Pointer ' overlay DMA array
    Else                        ' using resized array as source
        iparseOverlayHost_Byte srcBytes, VarPtr(srcSA), 2, UBound(aResizedBytes, 2) + 1, UBound(aResizedBytes, 1) + 1, srcSA.pvData ' overlay DMA array
    End If
    
    On Error Resume Next ' expected errors? using a corrupted pre-multiplied image possibly, but will just draw wrong
    
    ' this loop is broken into several different loops to enhance speed when less options are used
    ' 1. separate loop when rendering DIB to DC or DIB to DIB
    ' 2. separate loop when using global alpha of 255 or using less than 255
    ' 3. separate loop when grayscaling and not grayscaling
    
    SrcX = SrcX * 4&                    ' first pixel to be procesed
    For srcRow = 0& To destHeight - 1&
    
        ' offset our DIB row as we go
        SrcY = SrcY - 1                 ' current source row being processed
        sX = SrcX                       ' 1st column of source row
        dY = destHeight - srcRow - 1    ' next row for destination image
        dX = 0&                         ' 1st column of destination row
        
        If tHost Is Nothing Then        ' DIB to DC rendering (4 pixel source to 3 pixel target)
            
            If grayScale = gsclNone Then
                If GlobalAlpha = &HFF& Then
                    ' with full opaqueness, use separate loop, less calculations
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If (srcAlpha = &HFF&) Then
                             ' copy pixel to destination, adjusting for destination row/column as needed
                             CopyMemory dstBytes(dX, dY), srcBytes(sX, SrcY), 3&
                         ElseIf Not srcAlpha = 0& Then
                             '-- Blend
                            dstAlpha = &HFF& - srcAlpha ' calculate dest alpha value
                            dstBytes(dX, dY) = (dstAlpha * dstBytes(dX, dY)) \ &HFF + srcBytes(sX, SrcY)
                            dstBytes(dX + 1&, dY) = (dstAlpha * dstBytes(dX + 1&, dY)) \ &HFF + srcBytes(sX + 1&, SrcY)
                            dstBytes(dX + 2&, dY) = (dstAlpha * dstBytes(dX + 2&, dY)) \ &HFF + srcBytes(sX + 2&, SrcY)
                         End If
                        dX = dX + 3&
                        sX = sX + 4&
                     Next
                Else
                    ' global alpha and per-pixel blending
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If Not srcAlpha = 0& Then
                            ' following formula is for already pre-multiplied bytes
                            dstAlpha = &HFF& - ((srcAlpha * GlobalAlpha) \ &HFF&)
                            dstBytes(dX, dY) = (dstAlpha * (dstBytes(dX, dY)) + (srcBytes(sX, SrcY) * GlobalAlpha)) \ &HFF
                            dstBytes(dX + 1&, dY) = (dstAlpha * (dstBytes(dX + 1&, dY)) + (srcBytes(sX + 1&, SrcY) * GlobalAlpha)) \ &HFF
                            dstBytes(dX + 2&, dY) = (dstAlpha * (dstBytes(dX + 2&, dY)) + (srcBytes(sX + 2&, SrcY) * GlobalAlpha)) \ &HFF
                         End If
                         dX = dX + 3&
                         sX = sX + 4&
                     Next
                End If
            Else    ' gray scaling
                Call iparseGrayScaleRatios(grayScale, Rg, Gg, Bg)
                If GlobalAlpha = &HFF& Then
                    ' with full opaqueness, use separate loop, less calculations
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If (srcAlpha = &HFF&) Then
                             ' copy pixel to destination, adjusting for destination row/column as needed
                             dstBytes(dX, dY) = (srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg)
                             dstBytes(dX + 1&, dY) = dstBytes(dX, dY)
                             dstBytes(dX + 2&, dY) = dstBytes(dX, dY)
                         ElseIf Not srcAlpha = 0& Then
                             '-- Blend
                            dstAlpha = &HFF& - srcAlpha ' calculate dest alpha value
                            ' calculate green,red channel grayscale value
                            gScaleByte = ((srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg)) And &HFF
                            ' blend grayscale to target
                            dstBytes(dX + 1&, dY) = (dstAlpha * dstBytes(dX + 1&, dY)) \ &HFF + gScaleByte
                            dstBytes(dX + 2&, dY) = (dstAlpha * dstBytes(dX + 2&, dY)) \ &HFF + gScaleByte
                            dstBytes(dX, dY) = (dstAlpha * dstBytes(dX, dY)) \ &HFF + gScaleByte
                         End If
                        dX = dX + 3&
                        sX = sX + 4&
                     Next
                Else
                    ' global alpha and per-pixel blending
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If Not srcAlpha = 0& Then
                            ' following formula is for already pre-multiplied bytes
                            dstAlpha = &HFF& - ((srcAlpha * GlobalAlpha) \ &HFF&)
                            ' calculate green,red channel grayscale value
                            gScaleByte = (((srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg)) And &HFF) * GlobalAlpha
                            ' calculate green,red channels
                            dstBytes(dX, dY) = (dstAlpha * (dstBytes(dX, dY)) + gScaleByte) \ &HFF
                            dstBytes(dX + 1&, dY) = (dstAlpha * (dstBytes(dX + 1&, dY)) + gScaleByte) \ &HFF
                            dstBytes(dX + 2&, dY) = (dstAlpha * (dstBytes(dX + 2&, dY)) + gScaleByte) \ &HFF
                         End If
                         dX = dX + 3&
                         sX = sX + 4&
                     Next
                End If
            End If
    
        Else    ' DIB class to DIB class rendering  (4 pixel source to 4 pixel target)
        
            If grayScale = gsclNone Then
                If GlobalAlpha = &HFF& Then
                    ' with full opaqueness, use separate loop, less calculations
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If (srcAlpha = &HFF&) Then
                             ' copy pixel to destination, adjusting for destination row/column as needed
                             CopyMemory dstBytes(dX, dY), srcBytes(sX, SrcY), 4&
                         ElseIf Not srcAlpha = 0& Then
                             '-- Blend
                            dstAlpha = &HFF& - srcAlpha ' calculate dest alpha value
                            dstBytes(dX, dY) = (dstAlpha * dstBytes(dX, dY)) \ &HFF + srcBytes(sX, SrcY)
                            dstBytes(dX + 1&, dY) = (dstAlpha * dstBytes(dX + 1&, dY)) \ &HFF + srcBytes(sX + 1&, SrcY)
                            dstBytes(dX + 2&, dY) = (dstAlpha * dstBytes(dX + 2&, dY)) \ &HFF + srcBytes(sX + 2&, SrcY)
                            dstBytes(dX + 3&, dY) = (dstAlpha * dstBytes(dX + 3&, dY)) \ &HFF + srcBytes(sX + 3&, SrcY)
                         End If
                        dX = dX + 4&
                        sX = sX + 4&
                     Next
                Else
                    ' global alpha and per-pixel blending
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If Not srcAlpha = 0& Then
                             ' following formula is for already pre-multiplied bytes
                             dstAlpha = &HFF& - ((srcAlpha * GlobalAlpha) \ &HFF&)
                             dstBytes(dX, dY) = (dstAlpha * (dstBytes(dX, dY)) + (srcBytes(sX, SrcY) * GlobalAlpha)) \ &HFF
                             dstBytes(dX + 1&, dY) = (dstAlpha * (dstBytes(dX + 1&, dY)) + (srcBytes(sX + 1&, SrcY) * GlobalAlpha)) \ &HFF
                             dstBytes(dX + 2&, dY) = (dstAlpha * (dstBytes(dX + 2&, dY)) + (srcBytes(sX + 2&, SrcY) * GlobalAlpha)) \ &HFF
                             dstBytes(dX + 3&, dY) = (dstAlpha * (dstBytes(dX + 3&, dY)) + (srcBytes(sX + 3, SrcY) * GlobalAlpha)) \ &HFF
                         End If
                         dX = dX + 4&
                         sX = sX + 4&
                     Next
                End If
            Else
                Call iparseGrayScaleRatios(grayScale, Rg, Gg, Bg)
                If GlobalAlpha = &HFF& Then
                    ' with full opaqueness, use separate loop, less calculations
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If (srcAlpha = &HFF&) Then
                             ' copy pixel to destination, adjusting for destination row/column as needed
                             dstBytes(dX, dY) = ((srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg))
                             dstBytes(dX + 1&, dY) = dstBytes(dX, dY)
                             dstBytes(dX + 2&, dY) = dstBytes(dX, dY)
                             dstBytes(dX + 3&, dY) = &HFF
                         ElseIf Not srcAlpha = 0& Then
                             '-- Blend
                            dstAlpha = &HFF& - srcAlpha ' calculate dest alpha value
                            gScaleByte = ((srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg) And &HFF)
                            dstBytes(dX, dY) = (dstAlpha * dstBytes(dX, dY)) \ &HFF + gScaleByte
                            dstBytes(dX + 1&, dY) = (dstAlpha * dstBytes(dX + 1&, dY)) \ &HFF + gScaleByte
                            dstBytes(dX + 2&, dY) = (dstAlpha * dstBytes(dX + 2&, dY)) \ &HFF + gScaleByte
                            dstBytes(dX + 3&, dY) = (dstAlpha * dstBytes(dX + 3&, dY)) \ &HFF + (srcBytes(sX + 3, SrcY))
                         End If
                        dX = dX + 4&
                        sX = sX + 4&
                     Next
                Else
                    ' global alpha and per-pixel blending
                    For srcCol = 0& To destWidth - 1&
                         srcAlpha = srcBytes(sX + 3&, SrcY)     ' get its alpha value
                         If Not srcAlpha = 0& Then
                             ' following formula is for already pre-multiplied bytes
                             dstAlpha = &HFF& - ((srcAlpha * GlobalAlpha) \ &HFF&)
                             gScaleByte = (((srcBytes(sX, SrcY) * Bg) + (srcBytes(sX + 1&, SrcY) * Gg) + (srcBytes(sX + 2&, SrcY) * Rg)) And &HFF) * GlobalAlpha
                             dstBytes(dX, dY) = (dstAlpha * (dstBytes(dX, dY)) + gScaleByte) \ &HFF
                             dstBytes(dX + 1&, dY) = (dstAlpha * (dstBytes(dX + 1&, dY)) + gScaleByte) \ &HFF
                             dstBytes(dX + 2&, dY) = (dstAlpha * (dstBytes(dX + 2&, dY)) + gScaleByte) \ &HFF
                             dstBytes(dX + 3&, dY) = (dstAlpha * (dstBytes(dX + 3&, dY)) + (srcBytes(sX + 3, SrcY) * GlobalAlpha)) \ &HFF
                         End If
                         dX = dX + 4&
                         sX = sX + 4&
                     Next
                End If
            End If
        End If
    Next
    ' remove overlay
    iparseOverlayHost_Byte srcBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    Erase aResizedBytes()
    If Err Then Err.Clear
    
    ' transfer results
    If tHost Is Nothing Then
        SetDIBitsToDevice destinationDC, destX, destY, destWidth, destHeight, 0&, 0&, 0&, destHeight, dstBytes(0, 0), BMPI, 0&
    End If
    iparseOverlayHost_Byte dstBytes, 0, 0, 0, 0, 0  ' remove DMA overlay
    If Not hDib = 0& Then DeleteObject hDib
    
    spt_Win9xBlend = True

End Function





