unit SHL_IsoReader; // SpyroHackingLib is licensed under WTFPL

interface

uses
  SysUtils, Classes, SHL_Files, SHL_Types;

type
  NImageFormat = (ifUnknown, ifIso, ifMdf, ifStr, ifEcm);

type
  RIsoFileList = record
    Name: TextString;
    Size: Integer;
    Lba: Integer;
  end;

  AIsoFileList = array of RIsoFileList;

type
  TIsoReader = class(THandleStream)
  private
    FCachedSize: Integer;
    FSectorsCount: Integer;
    FHeader: Integer;
    FFooter: Integer;
    FBody: Integer;
    FOffset: Integer;
    FTotal: Integer;
    FSector: Integer;
    FEcm: Boolean;
  protected
    function GetSize(): Int64; override;
  public
    constructor Create(Writable: Boolean; Filename: TextString); overload;
    constructor Create(Writable: Boolean; Filename: WideString); overload;
  public
    function SetFormat(Header: Integer = 0; Footer: Integer = 0; Body: Integer =
      2336; Ecm: Boolean = False): Boolean; overload;
    function SetFormat(Format: NImageFormat): Boolean; overload;
    procedure SeekToSector(Sector: Integer);
    function ReadSectors(SaveDataTo: Pointer; Count: Integer = 0): Integer;
    function ReadSector(): DataString;
    function WriteSectors(ReadDataFrom: Pointer; Count: Integer = 0): Integer;
    function GuessImageFormat(Text: PTextChar = nil): NImageFormat;
    function GetFileList(): AIsoFileList;
  public
    property SectorsCount: Integer read FSectorsCount;
    property Header: Integer read FHeader;
    property Footer: Integer read FFooter;
    property Body: Integer read FBody;
    property Total: Integer read FTotal;
    property Offset: Integer read FOffset;
    property Sector: Integer read FSector write SeekToSector;
  end;

implementation

type
  RIsoDir = packed record
    Len: Byte;
    Len_ext: Byte;
    Sector: Integer;
    Sector_big: Integer;
    Size: Integer;
    Size_big: Integer;
    Date: array[1..7] of Byte;
    Flag: Byte;
    File_unit: Byte;
    File_gap: Byte;
    Volume: Integer;
    Name_len: Byte;
    Name: DataChar;
  end;

  PIsoDir = ^RIsoDir;

function TIsoReader.GetSize(): Int64;
begin
  Result := Int64(FCachedSize);
end;

constructor TIsoReader.Create(Writable: Boolean; Filename: TextString);
var
  Temp: THandleStream;
begin
  if Writable then
  begin
    Temp := SFiles.OpenWrite(Filename);
    if Temp = nil then
      Temp := SFiles.OpenNew(Filename);
  end
  else
    Temp := SFiles.OpenRead(Filename);
  inherited Create(Temp.Handle);
  Temp.Free();
  SetFormat();
end;

constructor TIsoReader.Create(Writable: Boolean; Filename: WideString);
var
  Temp: THandleStream;
begin
  if Writable then
  begin
    Temp := SFiles.OpenWrite(Filename);
    if Temp = nil then
      Temp := SFiles.OpenNew(Filename);
  end
  else
    Temp := SFiles.OpenRead(Filename);
  inherited Create(Temp.Handle);
  Temp.Free();
  SetFormat();
end;

function TIsoReader.SetFormat(Header: Integer = 0; Footer: Integer = 0; Body:
  Integer = 2336; Ecm: Boolean = False): Boolean;
begin
  if Ecm then
  begin
    FEcm := True;
    Result := True;
    FHeader := -1;
    FBody := -1;
    FTotal := -1;
    FCachedSize := -1;
    FSectorsCount := -1;
    Exit;
  end;
  FEcm := False;
  FHeader := Header;
  FFooter := Footer;
  FBody := Body;
  FTotal := FHeader + FBody + FFooter;
  FCachedSize := Integer(inherited GetSize());
  FSectorsCount := FCachedSize div FTotal;
  Result := (FCachedSize mod FTotal) = 0;
end;

function TIsoReader.SetFormat(Format: NImageFormat): Boolean;
begin
  Result := False;
  case Format of
    ifIso:
      Result := SetFormat(16, 0);
    ifMdf:
      Result := SetFormat(16, 96);
    ifStr:
      Result := SetFormat(0, 0);
    ifEcm:
      Result := SetFormat(0, 0, 0, True);
    ifUnknown:
      Result := SetFormat();
  end;
end;

procedure TIsoReader.SeekToSector(Sector: Integer);
begin
  FSector := Sector;
  Position := Int64(FOffset) + Int64(FTotal) * Int64(FSector) + Int64(FHeader);
end;

function TIsoReader.ReadSectors(SaveDataTo: Pointer; Count: Integer = 0): Integer;
begin
  if Count = 0 then
    Result := Ord(inherited Read(SaveDataTo^, FBody) = FBody)
  else
    Result := inherited Read(SaveDataTo^, FTotal * Count) div FTotal;
  Inc(FSector, Result);
end;

function TIsoReader.ReadSector(): DataString;
begin
  SetLength(Result, FBody);
  ReadSectors(Cast(Result));
end;

function TIsoReader.WriteSectors(ReadDataFrom: Pointer; Count: Integer = 0): Integer;
begin
  if Count = 0 then
    Result := Ord(inherited Write(ReadDataFrom^, FBody) = FBody)
  else
    Result := inherited Write(ReadDataFrom^, FTotal * Count) div FTotal;
  Inc(FSector, Result);
end;

function TIsoReader.GuessImageFormat(Text: PTextChar = nil): NImageFormat;
var
  Sector: array[0..615] of Integer;
  OldPos: Integer;
const
  ID_ECM = 5063493;
begin
  Result := ifUnknown;
  FBody := 2336;
  FHeader := 0;
  FFooter := 0;
  OldPos := Position;
  Inits(Sector);
  ReadBuffer(Sector, 2464);
  Position := OldPos;
  if Sector[0] = ID_ECM then
    Result := ifEcm
  else
    while True do
    begin
      if (Sector[0] = Sector[1]) and (Sector[584] = Sector[585]) then
      begin
        if Text <> nil then
          StrCopy(Text, 'STR');
        Result := ifStr;
        Break;
      end;
      FHeader := 16;
      if (Sector[0] = Sector[588]) and (Sector[1] = Sector[589]) then
      begin
        if Text <> nil then
          StrCopy(Text, 'ISO');
        Result := ifIso;
        Break;
      end;
      FFooter := 96;
      if (Sector[0] = Sector[612]) and (Sector[1] = Sector[613]) then
      begin
        if Text <> nil then
          StrCopy(Text, 'MDF');
        Result := ifMdf;
        Break;
      end;
      if Text <> nil then
        StrCopy(Text, 'UNK');
      Break;
    end;
  SetFormat(Result);
end;

function TIsoReader.GetFileList(): AIsoFileList;
var
  Have: TList;
  Len: Integer;

  procedure ReadDir(From: Integer; const Path: TextString);
  var
    Sector: DataString;
    Dir: PIsoDir;
    Offset, Filesize: Integer;
    Filename: TextString;
  begin
    Have.Add(Pointer(From));
    SeekToSector(From);
    Sector := ReadSector();
    Dir := Cast(Sector, 8);
    while Dir.Len <> 0 do
    begin
      CopyMem(@Dir.Sector, @Offset, 4);
      if Have.IndexOf(Pointer(Offset)) = -1 then
      begin
        CopyMem(@Dir.Size, @Filesize, 4);
        SetString(Filename, CastChar(@Dir.Name), Dir.Name_len);
        if (Dir.Flag and 2) <> 0 then
          Filename := Filename + '\'
        else
        begin
          if Length(Result) = Len then
            SetLength(Result, Len * 2);
          with Result[Len] do
          begin
            Name := Path + Filename;
            Size := Filesize;
            Lba := Offset;
          end;
          Inc(Len);
        end;
        if (Dir.Flag and 2) <> 0 then
          ReadDir(Offset, Path + Filename);
      end;
      Dir := Cast(Dir, Dir.Len);
    end;

  end;

var
  Sector: DataString;
  Dir: PIsoDir;
  Offset: Integer;
begin
  SetLength(Result, 32);
  Have := TList.Create();
  try
    Len := 0;
    SeekToSector(16);
    Sector := ReadSector();
    Dir := Cast(Sector, 8 + 156);
    CopyMem(@Dir.Sector, @Offset, 4);
    ReadDir(Dir.Sector, '\');
    SetLength(Result, Len);
  except
    SetLength(Result, 0);
  end;
  Have.Free();
end;

end.

