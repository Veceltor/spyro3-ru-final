
#define VOS_NT_WINDOWS32	(0x40004L)
#define VFT_APP	(0x1L)
#define VFT_DLL	(0x2L)
#ifdef PRODUCT_ISDLL
#define VFT_MY VFT_DLL
#define EXT_MY ".dll"
#else
#define VFT_MY VFT_APP
#define EXT_MY ".exe"
#endif
#define STR2(s) #s
#define STR(s) STR2(s)
#define VERSION_STRING STR(VERSION_MAJOR) "." STR(VERSION_MINOR)

#define DONE \
VS_VERSION_INFO VERSIONINFO \
FILEVERSION VERSION_MAJOR,VERSION_MINOR,0,0 \
FILEOS VOS_NT_WINDOWS32 \
FILETYPE VFT_APP \
{BLOCK "StringFileInfo" \
{BLOCK "040904E4"{ \
VALUE "FileDescription", PRODUCT_NAME " v" VERSION_STRING "!\0" \
VALUE "CompanyName", "Kly_Men_COmpany\0" \
VALUE "LegalCopyright", "Licensed under WTFPL\0" \
VALUE "OriginalFilename", PRODUCT_NAME EXT_MY "\0"  \
VALUE "FileVersion", VERSION_STRING "\0" \
VALUE "Comments", COMMENTS \
}} \
BLOCK "VarFileInfo" \
{VALUE "Translation", 0x409, 1251}} \
