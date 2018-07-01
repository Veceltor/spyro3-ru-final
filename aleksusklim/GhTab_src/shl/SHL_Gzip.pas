unit SHL_Gzip; // SpyroHackingLib is licensed under WTFPL

{$DEFINE SHL_GNU}

interface

uses
  SysUtils, Classes, SHL_Files, SHL_Types;

type
  TGzipFile = class(TStream)
    constructor CreateRead(const Filename: TextString); overload;
    constructor CreateRead(const Filename: WideString); overload;
    constructor CreateRead(Stream: TStream); overload;
    constructor CreateNew(const Filename: TextString; Level: Integer = 1); overload;
    constructor CreateNew(const Filename: WideString; Level: Integer = 1); overload;
    constructor CreateNew(Stream: TStream; Level: Integer = 1); overload;
    destructor Destroy(); override;
  public
    function Write(const Buffer; Count: Integer): Integer; override;
    function Read(var Buffer; Count: Integer): Integer; override;
    function Seek(Offset: Integer; Origin: Word): Integer; override;
  protected
    function GetSize(): Int64; override;
  private
    FStream: THandleStream;
    FGzip: Pointer;
  end;

implementation

{$IFDEF SHL_GNU}

uses
  GNU_gzip;

{$ELSE}

function gzopen(strm: TStream; mode: TextString; dstream: boolean = false): Pointer;
begin
  Ignore(mode, dstream);
  Result := strm;
end;

function gzread(f: Pointer; buf: Pointer; len: Integer): Integer;
begin
  Result := TStream(f).Read(buf^, len);
end;

function gzwrite(f: Pointer; buf: Pointer; len: Integer): Integer;
begin
  Result := TStream(f).Write(buf^, len);
end;

function gzclose(f: Pointer): Integer;
begin
  Ignore(f);
  Result := 0;
end;

{$ENDIF}

constructor TGzipFile.CreateRead(const Filename: TextString);
begin
  Assure(FStream = nil);
  FStream := SFiles.OpenRead(Filename);
  Assure(FStream <> nil);
  FGzip := gzopen(FStream, 'r');
end;

constructor TGzipFile.CreateRead(const Filename: WideString);
begin
  Assure(FStream = nil);
  FStream := SFiles.OpenRead(Filename);
  Assure(FStream <> nil);
  FGzip := gzopen(FStream, 'r');
end;

constructor TGzipFile.CreateRead(Stream: TStream);
begin
  Assure(FStream = nil);
  FStream := Int2Obj(-1);
  Assure(Stream <> nil);
  FGzip := gzopen(Stream, 'r');
end;

constructor TGzipFile.CreateNew(const Filename: TextString; Level: Integer = 1);
begin
  Assure(FStream = nil);
  FStream := SFiles.OpenNew(Filename);
  Assure(FStream <> nil);
  FGzip := gzopen(FStream, 'w' + Chr(Ord('0') + Level));
end;

constructor TGzipFile.CreateNew(const Filename: WideString; Level: Integer = 1);
begin
  Assure(FStream = nil);
  FStream := SFiles.OpenNew(Filename);
  Assure(FStream <> nil);
  FGzip := gzopen(FStream, 'w' + Chr(Ord('0') + Level));
end;

constructor TGzipFile.CreateNew(Stream: TStream; Level: Integer = 1);
begin
  Assure(FStream = nil);
  FStream := Int2Obj(-1);
  Assure(Stream <> nil);
  FGzip := gzopen(Stream, 'w' + Chr(Ord('0') + Level));
end;

destructor TGzipFile.Destroy();
begin
  gzclose(FGzip);
  if Obj2Int(FStream) <> -1 then
    SFiles.CloseStream(FStream);
end;

function TGzipFile.Write(const Buffer; Count: Integer): Integer;
begin
  Result := gzwrite(FGzip, @Buffer, Count);
end;

function TGzipFile.Read(var Buffer; Count: Integer): Integer;
begin
  Result := gzread(FGzip, @Buffer, Count);
end;

function TGzipFile.Seek(Offset: Integer; Origin: Word): Integer;
begin
  Ignore(Offset, Origin);
  Result := 0;
end;

function TGzipFile.GetSize(): Int64;
begin
  Result := 0;
end;

end.

