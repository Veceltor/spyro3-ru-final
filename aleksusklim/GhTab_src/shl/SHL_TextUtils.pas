unit SHL_TextUtils; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, SysUtils, Classes, DateUtils, IniFiles, SHL_Types;

type
  STextUtils = class(TObject)
  public
    class function IntToStrPad(Value, Len: Integer; Z: TextChar = '0'): TextString;
    class function StrPad(const T: TextString; C: Integer; Z: TextChar = ' '): TextString;
    class function DateToString(const Time: TFileTime; Empty: TextString = '-/-'):
      TextString;
    class function SizeToString(Bytes: Int64; Pad: Boolean = False): TextString;
    class procedure DebugPrintArray(const Arr: ArrayOfWide);
    class function StringToken(var Line: PTextChar; const Delims: array of
      TextChar): PTextChar;
    class function IntegerToBase26(Number, Size: Integer): TextString;
    class function TimeToString(Time: TDateTime): TextString;
    class function WriteText(Stream: TStream; const Text: TextString): Boolean; overload;
    class function WriteText(Stream: TStream; const Text: WideString): Boolean; overload;
    class function WriteText(Stream: TStream; Text: PTextChar): Boolean; overload;
    class function WriteText(Stream: TStream; Text: PWideChar): Boolean; overload;
    class function WriteText(Stream: TStream; Text: Pointer; Size: Integer):
      Boolean; overload;
    class function WriteLine(Stream: TStream; Utf8: Boolean): Boolean;
    class function WriteBom(Stream: TStream; Utf8: Boolean): Boolean;
    class procedure PrintWide(Text: Pointer);
    class function StrToHex(const Data: DataString): TextString;
    class function HexToStr(const Text: TextString): DataString;
    class function SplitChar(const Data: DataString; Delims: SetOfChar): ArrayOfData;
    class function JoinString(const Data: ArrayOfData; const Separator:
      DataString; LastToo: Boolean): DataString;
    class function WideToData(const Wide: WideString): DataString;
    class function DataToWide(const Data: DataString): WideString;
    class function IniRead(const Path: WideString; Ini: TMemIniFile = nil): TMemIniFile;
    class function IniWrite(const Path: WideString; Ini: TMemIniFile): Boolean;
  end;

implementation

uses
  SHL_Files;

class function STextUtils.IntToStrPad(Value, Len: Integer; Z: TextChar = '0'): TextString;
begin
  Result := IntToStr(Value);
  Dec(Len, Length(Result));
  if Len > 0 then
    Result := StringOfChar('0', Len) + Result;
end;

class function STextUtils.StrPad(const T: TextString; C: Integer; Z: TextChar =
  ' '): TextString;
var
  D: Integer;
begin
  if C > 0 then
    D := C - Length(T)
  else
    D := -C - Length(T);
  if (C = 0) or (D < 1) then
  begin
    Result := T;
    Exit;
  end;
  if C < 0 then
    Result := T + StringOfChar(Z, D)
  else
    Result := StringOfChar(Z, D) + T;
end;

class function STextUtils.DateToString(const Time: TFileTime; Empty: TextString
  = '-/-'): TextString;
var
  Sys: TSystemTime;
  Loc: TFileTime;
begin
  if (Time.dwLowDateTime = 0) and (Time.dwHighDateTime = 0) then
  begin
    Result := Empty;
    Exit;
  end;
  FileTimeToLocalFileTime(Time, Loc);
  FileTimeToSystemTime(Loc, Sys);
  Result := IntToStrPad(Sys.wDay, 2, ' ') + '.' + IntToStrPad(Sys.wMonth, 2) +
    '.' + IntToStr(Sys.wYear) + ',' + IntToStrPad(Sys.wHour, 2, ' ') + ':' +
    IntToStrPad(Sys.wMinute, 2);
end;

class function STextUtils.SizeToString(Bytes: Int64; Pad: Boolean = False): TextString;
var
  Index, L, R: Integer;
  Size: Int64;
const
  Names: array[0..4] of TextString = (' b ', ' Kb', ' MB', ' GB', ' TB');

  function StrPad(const I: TextString; Z: Integer): TextString;
  begin
    Result := I;
  end;

begin
  if Pad then
  begin
    L := 3;
    R := -2;
  end
  else
  begin
    L := 0;
    R := 0;
  end;
  Result := '0';
  if Bytes < 0 then
    Exit;
  if Bytes < 1024 then
  begin
    if Pad then
      Result := StrPad(IntToStr(Bytes), L) + StrPad('', R - 1) + Names[0]
    else
      Result := IntToStr(Bytes) + ' b';
    Exit;
  end;
  if Bytes > $100000 then
    Size := (Bytes div 1024) * 1000
  else
    Size := (Bytes * 1000) div 1024;
  for Index := 1 to 4 do
  begin
    if Size < 1000 then
    begin
      Result := IntToStr(Size);
      Result := StrPad('0', L) + '.' + StrPad(Result[1] + Result[2], R) + Names[Index];
      Exit;
    end;
    if Size < 10000 then
    begin
      Result := IntToStr(Size);
      Result := StrPad(Result[1], L) + '.' + StrPad(Result[2] + Result[3], R) +
        Names[Index];
      Exit;
    end;
    if Size < 100000 then
    begin
      Result := IntToStr(Size);
      Result := StrPad(Result[1] + Result[2], L) + '.' + StrPad(Result[3], R) +
        Names[Index];
      Exit;
    end;
    if Size < 1000000 then
    begin
      Result := IntToStr(Size);
      Result := StrPad(Result[1] + Result[2] + Result[3], L) + StrPad('', R - 1)
        + Names[Index];
      Exit;
    end;
    Size := Size div 1024;
  end;
end;

class procedure STextUtils.DebugPrintArray(const Arr: ArrayOfWide);
var
  Index: Integer;
begin
  for Index := 0 to Length(Arr) - 1 do
    Writeln(Arr[Index]);
end;

class function STextUtils.StringToken(var Line: PTextChar; const Delims: array
  of TextChar): PTextChar;
var
  I, J, Len: Integer;
  F: Boolean;
begin
  Result := Line;
  if Line = nil then
    Exit;
  Len := Length(Delims) - 1;
  while Line^ <> #0 do
  begin
    for I := 0 to Len do
      if Line^ = Delims[I] then
      begin
        repeat
          Line^ := #0;
          Inc(Line);
          F := True;
          for J := 0 to Len do
          begin
            if Line^ = Delims[J] then
            begin
              F := False;
              Break;
            end;
          end;
          if F then
            Exit;
        until Line^ = #0;
        Exit;
      end;
    Inc(Line);
  end;
  Line := nil;
end;

class function STextUtils.IntegerToBase26(Number, Size: Integer): TextString;
var
  Modulo: Integer;
begin
  Result := StringOfChar('A', Size);
  repeat
    if Size = 0 then
    begin
      Size := 1;
      Result := '_' + Result;
    end;
    Modulo := Number mod 26;
    Result[Size] := Chr(Ord('A') + Modulo);
    Number := Number div 26;
    Dec(Size);
  until Number = 0;
end;

class function STextUtils.TimeToString(Time: TDateTime): TextString;
begin
  Result := IntegerToBase26(DateTimeToUnix(Time) - DateTimeToUnix(EncodeDate(2017,
    1, 1)), 6);
end;

class function STextUtils.WriteText(Stream: TStream; const Text: TextString): Boolean;
var
  Size: Integer;
begin
  Result := False;
  if Stream = nil then
    Exit;
  Size := Length(Text);
  if Size < 1 then
    Exit;
  Result := Stream.Write(Cast(Text)^, Size) = Size;
end;

class function STextUtils.WriteText(Stream: TStream; const Text: WideString): Boolean;
var
  Size: Integer;
begin
  Result := False;
  if Stream = nil then
    Exit;
  Size := Length(Text) * 2;
  if Size < 1 then
    Exit;
  Result := Stream.Write(Cast(Text)^, Size) = Size;
end;

class function STextUtils.WriteText(Stream: TStream; Text: PTextChar): Boolean;
var
  Size: Integer;
begin
  Result := False;
  if Stream = nil then
    Exit;
  Size := lstrlenA(Text);
  if Size < 1 then
    Exit;
  Result := Stream.Write(Pointer(Text)^, Size) = Size;
end;

class function STextUtils.WriteText(Stream: TStream; Text: PWideChar): Boolean;
var
  Size: Integer;
begin
  Result := False;
  if Stream = nil then
    Exit;
  Size := lstrlenW(Text) * 2;
  if Size < 1 then
    Exit;
  Result := Stream.Write(Pointer(Text)^, Size) = Size;
end;

class function STextUtils.WriteText(Stream: TStream; Text: Pointer; Size:
  Integer): Boolean;
begin
  Result := False;
  if (Stream = nil) or (Size < 1) then
    Exit;
  Result := Stream.Write(Text^, Size) = Size;
end;

class function STextUtils.WriteLine(Stream: TStream; Utf8: Boolean): Boolean;
var
  Nl: Integer;
begin
  Result := False;
  if Stream = nil then
    Exit;
  if Utf8 then
  begin
    Nl := $0A0D;
    Result := Stream.Write(Nl, 2) = 2;
    Exit;
  end;
  Nl := $000A000D;
  Result := Stream.Write(Nl, 4) = 4;
end;

class function STextUtils.WriteBom(Stream: TStream; Utf8: Boolean): Boolean;
var
  Bom: Integer;
begin
  if Utf8 then
  begin
    Bom := $BFBBEF;
    Result := Stream.Write(Bom, 3) = 3;
    Exit;
  end;
  Bom := $FEFF;
  Result := Stream.Write(Bom, 2) = 2;
end;

class procedure STextUtils.PrintWide(Text: Pointer);
begin
  if Text <> nil then
    while CastWord(Text)^ <> 0 do
    begin
      Write(IntToHex(LittleWord(CastWord(Text)^), 4));
      Adv(Text, 2);
    end;
  Writeln('');
end;

class function STextUtils.StrToHex(const Data: DataString): TextString;
begin
  SetLength(Result, Length(Data) * 2);
  BinToHex(Cast(Data), Cast(Result), Length(Data));
end;

class function STextUtils.HexToStr(const Text: TextString): DataString;
begin
  SetLength(Result, Length(Text) div 2);
  HexToBin(Cast(LowerCase(Text)), Cast(Result), Length(Result));
end;

class function STextUtils.SplitChar(const Data: DataString; Delims: SetOfChar):
  ArrayOfData;
var
  Step, From, Last: PDataChar_;
  Index: Integer;
begin
  SetLength(Result, 0);
  if Data = '' then
    Exit;
  Index := 0;
  Step := Cast(Data);
  Last := Cast(Data, Length(Data));
  while Step < Last do
  begin
    repeat
      if not (Step^ in Delims) then
        Break;
      Inc(Step);
    until Step = Last;
    if Step = Last then
      Break;
    repeat
      if Step^ in Delims then
        Break;
      Inc(Step);
    until Step = Last;
    Inc(Index);
  end;
  if Index = 0 then
    Exit;
  SetLength(Result, Index);
  Index := 0;
  Step := Cast(Data);
  while Step < Last do
  begin
    repeat
      if not (Step^ in Delims) then
        Break;
      Inc(Step);
    until Step = Last;
    if Step = Last then
      Break;
    From := Step;
    repeat
      if Step^ in Delims then
        Break;
      Inc(Step);
    until Step = Last;
    SetString(Result[Index], From, Step - From);
    Inc(Index);
  end;
end;

class function STextUtils.JoinString(const Data: ArrayOfData; const Separator:
  DataString; LastToo: Boolean): DataString;
var
  Index, Len, All, Sep: Integer;
  Step: Pointer;
begin
  All := Length(Data) - 1;
  if All < 0 then
  begin
    Result := '';
    Exit;
  end;
  Sep := Length(Separator);
  if LastToo then
    Len := Sep * (All + 1)
  else
    Len := Sep * All;
  for Index := 0 to Length(Data) - 1 do
    Inc(Len, Length(Data[Index]));
  SetLength(Result, Len);
  Step := Cast(Result);
  for Index := 0 to All do
  begin
    Len := Length(Data[Index]);
    CopyMem(Cast(Data[Index]), Step, Len);
    Adv(Step, Len);
    if LastToo or (Index < All) then
      CopyMem(Cast(Separator), Step, Sep);
    Adv(Step, Sep);
  end;
end;

class function STextUtils.WideToData(const Wide: WideString): DataString;
begin
  if Wide = '' then
    Result := ''
  else
    SetString(Result, PDataChar_(PWideChar(Wide)), Length(Wide) * 2);
end;

class function STextUtils.DataToWide(const Data: DataString): WideString;
begin
  if Data = '' then
    Result := ''
  else
    SetString(Result, PWideChar(Cast(Data)), (Length(Data) + 1) div 2);
end;

class function STextUtils.IniRead(const Path: WideString; Ini: TMemIniFile = nil):
  TMemIniFile;
var
  Stream: THandleStream;
  List: TStringList;
begin
  Result := nil;
  if Path = '' then
    Exit;
  List := nil;
  Stream := SFiles.OpenRead(Path);
  if Stream = nil then
    Exit;
  try
    List := TStringList.Create();
    List.LoadFromStream(Stream);
    if Ini <> nil then
      Result := Ini
    else
      Result := TMemIniFile.Create('');
    Result.SetStrings(List);
  except
    if Ini <> nil then
      Result.Free();
    Result := nil
  end;
  SFiles.CloseStream(Stream);
  List.Free();
end;

class function STextUtils.IniWrite(const Path: WideString; Ini: TMemIniFile): Boolean;
var
  Stream: THandleStream;
  List: TStringList;
begin
  Result := False;
  if (Ini = nil) or (Path = '') then
    Exit;
  List := nil;
  Stream := SFiles.OpenNew(Path);
  if Stream = nil then
    Exit;
  try
    List := TStringList.Create();
    Ini.GetStrings(List);
    List.SaveToStream(Stream);
    Result := True;
  except
  end;
  SFiles.CloseStream(Stream);
  List.Free();
end;

end.

