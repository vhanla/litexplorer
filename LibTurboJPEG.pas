unit LibTurboJPEG;

interface

uses
  Windows, SysUtils, SyncObjs;

const
  {$IFDEF WIN64}
  TURBOJPEG_DLL = 'turbojpeg.dll'; // Standard name, or 'turbojpeg64.dll' if renamed
  {$ELSE}
  TURBOJPEG_DLL = 'turbojpeg.dll';
  {$ENDIF}

  // Common Constants
  TJ_NUMSAMP = 6;
  TJ_NUMPF = 12;
  TJ_NUMCS = 5;

  // Flags
  TJFLAG_BOTTOMUP = 2;
  TJFLAG_FASTUPSAMPLE = 256;
  TJFLAG_NOREALLOC = 1024;
  TJFLAG_FASTDCT = 2048;
  TJFLAG_ACCURATEDCT = 4096;
  TJFLAG_STOPONWARNING = 8192;
  TJFLAG_PROGRESSIVE = 16384;
  TJFLAG_LIMITSCANS = 32768;

  // Error Codes
  TJERR_WARNING = 0;
  TJERR_FATAL = 1;

type
  PPByte = ^PByte;
  TJHandle = Pointer;

  // Subsampling types
  TJSAMP = (
    TJSAMP_444 = 0,
    TJSAMP_422 = 1,
    TJSAMP_420 = 2,
    TJSAMP_GRAY = 3,
    TJSAMP_440 = 4,
    TJSAMP_411 = 5
  );

  // Pixel Formats
  TJPF = (
    TJPF_RGB = 0,
    TJPF_BGR = 1,
    TJPF_RGBX = 2,
    TJPF_BGRX = 3,
    TJPF_XBGR = 4,
    TJPF_XRGB = 5,
    TJPF_GRAY = 6,
    TJPF_RGBA = 7,
    TJPF_BGRA = 8,
    TJPF_ABGR = 9,
    TJPF_ARGB = 10,
    TJPF_CMYK = 11,
    TJPF_UNKNOWN = -1
  );

  TJScalingFactor = record
    num: Integer;
    denom: Integer;
  end;
  PTJScalingFactor = ^TJScalingFactor;

// Global Function Pointers
var
  // Lifecycle
  tjInitCompress: function: TJHandle; cdecl;
  tjInitDecompress: function: TJHandle; cdecl;
  tjDestroy: function(handle: TJHandle): Integer; cdecl;
  tjAlloc: function(bytes: Integer): PByte; cdecl;
  tjFree: procedure(buffer: PByte); cdecl;

  // Error Handling
  tjGetErrorStr2: function(handle: TJHandle): PAnsiChar; cdecl;
  tjGetErrorCode: function(handle: TJHandle): Integer; cdecl;

  // Compression
  tjCompress2: function(handle: TJHandle; const srcBuf: PByte; width: Integer;
    pitch: Integer; height: Integer; pixelFormat: TJPF; jpegBuf: PPByte;
    jpegSize: PCardinal; jpegSubsamp: TJSAMP; jpegQual: Integer; flags: Integer): Integer; cdecl;

  // Decompression
  tjDecompressHeader3: function(handle: TJHandle; const jpegBuf: PByte;
    jpegSize: Cardinal; width: PInteger; height: PInteger;
    jpegSubsamp: PInteger; jpegColorspace: PInteger): Integer; cdecl;

//  tjDecompress2: function(handle: TJHandle; const jpegBuf: PByte;
//    jpegSize: Cardinal; dstBuf: PByte; width: Integer; pitch: Integer;
//    height: Integer; pixelFormat: TJPF; flags: Integer): Integer; cdecl;
// Change TJPF to Integer here to ensure 4-byte passing
  tjDecompress2: function(handle: TJHandle; const jpegBuf: PByte;
    jpegSize: Cardinal; dstBuf: PByte; width: Integer; pitch: Integer;
    height: Integer; pixelFormat: Integer; flags: Integer): Integer; cdecl;

  // Plane/YUV functions (Subset)
  tjPlaneWidth: function(componentID: Integer; width: Integer; subsamp: Integer): Integer; cdecl;
  tjPlaneHeight: function(componentID: Integer; height: Integer; subsamp: Integer): Integer; cdecl;

procedure InitLibTurboJPEG(const ADllName: string = TURBOJPEG_DLL);

implementation

var
  GHandle: THandle = 0;
  GLock: TCriticalSection = nil;
  GIsInitialized: Boolean = False;

procedure UnloadLib; forward;

procedure InitLibTurboJPEG(const ADllName: string);
  function GetProcAddr(const AProcName: PAnsiChar): Pointer;
  begin
    Result := GetProcAddress(GHandle, AProcName);
    if Result = nil then
      raise Exception.CreateFmt('Unable to find "%s" in %s', [AProcName, ADllName]);
  end;
begin
  if GIsInitialized then Exit;

  GLock.Acquire;
  try
    if GIsInitialized then Exit;

    if GHandle = 0 then
    begin
      GHandle := SafeLoadLibrary(PChar(ADllName));
      if GHandle = 0 then
        raise Exception.CreateFmt('Unable to load library %s - %s', [ADllName, SysErrorMessage(GetLastError)]);
    end;

    try
      tjInitCompress    := GetProcAddr('tjInitCompress');
      tjInitDecompress  := GetProcAddr('tjInitDecompress');
      tjDestroy         := GetProcAddr('tjDestroy');
      tjAlloc           := GetProcAddr('tjAlloc');
      tjFree            := GetProcAddr('tjFree');
      tjGetErrorStr2    := GetProcAddr('tjGetErrorStr2');
      tjGetErrorCode    := GetProcAddr('tjGetErrorCode');
      tjCompress2       := GetProcAddr('tjCompress2');
      tjDecompressHeader3 := GetProcAddr('tjDecompressHeader3');
      tjDecompress2     := GetProcAddr('tjDecompress2');
      tjPlaneWidth      := GetProcAddr('tjPlaneWidth');
      tjPlaneHeight     := GetProcAddr('tjPlaneHeight');

      GIsInitialized := True;
    except
      UnloadLib;
      raise;
    end;
  finally
    GLock.Release;
  end;
end;

procedure UnloadLib;
begin
  GLock.Acquire;
  try
    if GHandle <> 0 then
    begin
      FreeLibrary(GHandle);
      GHandle := 0;
    end;

    tjInitCompress := nil;
    tjInitDecompress := nil;
    tjDestroy := nil;
    tjAlloc := nil;
    tjFree := nil;
    tjGetErrorStr2 := nil;
    tjGetErrorCode := nil;
    tjCompress2 := nil;
    tjDecompressHeader3 := nil;
    tjDecompress2 := nil;
  finally
    GIsInitialized := False;
    GLock.Release;
  end;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  UnloadLib;
  FreeAndNil(GLock);

end.
