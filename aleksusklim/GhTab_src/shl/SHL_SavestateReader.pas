unit SHL_SavestateReader; // SpyroHackingLib is licensed under WTFPL

interface

uses
  SysUtils, Classes, SHL_Gzip, SHL_Files, SHL_Types;

type
  NSavestateType = (SavestateUnknown, SavestateEpsxe);

  TSavestateReader = class(TObject)
    constructor Create();
    destructor Destroy(); override;
  public
    function ReadFrom(const Savestate: WideString): Boolean; overload;
    function ReadFrom(Stream: TStream): Boolean; overload;
    function WriteTo(const Savestate: WideString): Boolean; overload;
    function WriteTo(Stream: TStream): Boolean; overload;
  private
    function GetType(): Boolean;
    procedure UseType();
    function GetMemorySize(): Integer;
    function GetVramSize(): Integer;
    function NextSection(out Memory: Pointer; out Size: Integer): TextString;
  private
    FBuffer, FMemory, FVram: Pointer;
    FActualSize: Integer;
    FType: NSavestateType;
    FSeeker: Integer;
    FRamFrom, FGpuFrom: Pointer;
  public
    property Memory: Pointer read FMemory;
    property Vram: Pointer read FVram;
    property MemorySize: Integer read GetMemorySize;
    property VramSize: Integer read GetVramSize;
  end;

implementation

const
  MaxBufferSize = 1024 * 1024 * 6;
  MemorySizeRAM = 1024 * 1024 * 2;
  MemorySizeGPU = 1024 * 512 * 2;

constructor TSavestateReader.Create();
begin
  GetMem(FBuffer, MaxBufferSize);
  GetMem(FMemory, MemorySizeRAM);
  GetMem(FVram, MemorySizeGPU);
  FActualSize := 0;
  FType := SavestateUnknown;
end;

destructor TSavestateReader.Destroy();
begin
  FreeMem(FBuffer);
  FreeMem(FMemory);
  FreeMem(FVram);
end;

function TSavestateReader.ReadFrom(const Savestate: WideString): Boolean;
var
  Stream: THandleStream;
begin
  Stream := SFiles.OpenRead(Savestate);
  Result := ReadFrom(Stream);
  SFiles.CloseStream(Stream)
end;

function TSavestateReader.ReadFrom(Stream: TStream): Boolean;
var
  Gz: TGzipFile;
begin
  Result := False;
  Gz := nil;
  try
    Gz := TGzipFile.CreateRead(Stream);
    FActualSize := Gz.Read(FBuffer^, MaxBufferSize);
    Result := GetType();
  except
  end;
  Gz.Free();
end;

function TSavestateReader.WriteTo(const Savestate: WideString): Boolean;
var
  Stream: THandleStream;
begin
  Stream := SFiles.OpenNew(Savestate);
  Result := WriteTo(Stream);
  SFiles.CloseStream(Stream)
end;

function TSavestateReader.WriteTo(Stream: TStream): Boolean;
var
  Gz: TGzipFile;
begin
  UseType();
  Gz := nil;
  Result := False;
  try
    Gz := TGzipFile.CreateNew(Stream);
    Gz.WriteBuffer(FBuffer^, FActualSize);
    Result := True;
  except
  end;
  Gz.Free();
end;

function TSavestateReader.GetType(): Boolean;
var
  Adr: Pointer;
  Sect: TextString;
  HaveRam, HaveGpu: Boolean;
  Len: Integer;
begin
  FType := SavestateUnknown;
  Result := False;
  if not CompareMem(FBuffer, Cast('ePSXe'), 5) then
    Exit;
  HaveRam := False;
  HaveGpu := False;
  FSeeker := 64;
  repeat
    Sect := NextSection(Adr, Len);
    if (Sect = 'MEM') and (Len >= MemorySizeRAM) then
    begin
      CopyMem(Adr, FMemory, MemorySizeRAM);
      FRamFrom := Adr;
      HaveRam := True;
    end
    else if (Sect = 'GPU') and (Len >= MemorySizeGPU) then
    begin
      Adv(Adr, Len - MemorySizeGPU);
      FGpuFrom := Adr;
      CopyMem(Adr, FVram, MemorySizeGPU);
      HaveGpu := True;
    end;
  until Adr = nil;
  if HaveRam and HaveGpu then
  begin
    FType := SavestateEpsxe;
    Result := True;
  end;
end;

procedure TSavestateReader.UseType();
begin
  if FType = SavestateEpsxe then
  begin
    CopyMem(FMemory, FRamFrom, MemorySizeRAM);
    CopyMem(FVram, FGpuFrom, MemorySizeGPU);
  end;
end;

function TSavestateReader.GetMemorySize(): Integer;
begin
  if FType <> SavestateUnknown then
    Result := MemorySizeRAM
  else
    Result := 0;
end;

function TSavestateReader.GetVramSize(): Integer;
begin
  if FType <> SavestateUnknown then
    Result := MemorySizeGPU
  else
    Result := 0;
end;

function TSavestateReader.NextSection(out Memory: Pointer; out Size: Integer): TextString;
var
  Max: Integer;
begin
  Memory := nil;
  Result := '';
  Size := 0;
  Max := MaxBufferSize - 8;
  if FSeeker > Max then
    Exit;
  while CastByte(FBuffer, FSeeker)^ = 0 do
  begin
    if FSeeker > Max then
      Exit;
    Inc(FSeeker);
  end;
  SetLength(Result, 3);
  CopyMem(Cast(FBuffer, FSeeker), Cast(Result), 3);
  Inc(FSeeker, 3);
  CopyMem(Cast(FBuffer, FSeeker), @Size, 4);
  Inc(FSeeker, 4);
  Memory := Cast(FBuffer, FSeeker);
  Inc(FSeeker, Size);
  if FSeeker >= MaxBufferSize then
  begin
    Result := '';
    Memory := nil;
    Size := 0;
  end;
end;

end.

