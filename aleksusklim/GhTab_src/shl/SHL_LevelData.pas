unit SHL_LevelData; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, Classes, SysUtils, SHL_WadManager, SHL_Types;

type
  PLevelObject = ^RLevelObject;

  RLevelObject = record
    Variables: Integer; //
    Pfriend: Integer;
    Pcollision: Integer;
    X, Y, Z: Integer;
    User1: array[0..1] of Byte;
    Dead: Byte;
    User2: array[3..27] of Byte;
    Rtype: Word;
    Entity: Word; //
    Middle: array[0..3] of Byte;
    Atype: Byte;
    Frame: Byte;
    Animation: array[0..3] of Byte;
    Critical: array[0..1] of Byte;
    U, V, W, D: Byte;
    State: Byte;
    Additional: array[1..6] of Byte;
    S: Byte;
    Last: array[0..7] of Byte;
  end;

  PLevelObjectsArr = ^RLevelObjectsArr;

  RLevelObjectsArr = array[0..1023] of RLevelObject;

  PLevelCharacter = ^RLevelCharacter;

  RLevelCharacter = record
    V1, V2: Integer;
    What: Integer;
    NameOffset: Integer;
    TextOffset: array[1..31] of Integer;
  end;

type
  TLevelData = class(TObject)
    constructor Create();
    destructor Destroy(); override;
  public
    procedure OpenData(Memory: Pointer; Game: NGame);
    function SaveData(): DataString; overload;
    procedure SaveData(Memory: Pointer); overload;
    function DataLength(): Integer;
    function FirstOffset(): Integer;
    function PartObjects(): Integer;
    function PartVariables(): Integer;
    function PartList(): Integer;
    function PartMenu(): Integer;
    function TakeSomeObjects(Count: Integer): Integer;
    function GetObjects(out Active, Total: Integer): PLevelObjectsArr;
    function GetVariables(out Offset, Size: Integer): Pointer;
    function GetList(out Len: Integer): PIntegerArray;
    function ListChangePointer(Old: Integer; New: Integer = -1): Boolean;
//    function IsCharacter(ObjectIndex: Integer): Boolean;
  private
    procedure IndexData();
  public
    FParts: array[0..16] of record
      Offset: Integer;
      Data: DataString;
    end;
  private
    FData: Pointer;
    FGame: NGame;
  end;

implementation

constructor TLevelData.Create();
begin
  inherited Create();
end;

destructor TLevelData.Destroy();
var
  Index: Integer;
begin
  for Index := 0 to Length(FParts) - 1 do
    FParts[Index].Data := '';
  inherited Destroy();
end;

procedure TLevelData.IndexData();
var
  Data: Pointer;
  Index, Offset, Size, Last: Integer;
begin
  Last := PartList();
  if Last > 0 then
  begin
    Offset := 0;
    Data := FData;
    Size := FirstOffset();
    SetString(FParts[0].Data, CastChar(Data), Size);
    Adv(Data, Size);
    Inc(Offset, Size);
    for Index := 1 to Last - 1 do
    begin
      FParts[Index].Offset := Offset + 4;
      Size := CastInt(Data)^ - 4;
      SetString(FParts[Index].Data, CastChar(Data, 4), Size);
      Adv(Data, Size + 4);
      Inc(Offset, Size + 4);
    end;
    FParts[Last].Offset := Offset + 4;
    Size := CastInt(Data)^ * 4;
    SetString(FParts[Last].Data, CastChar(Data, 4), Size);
  end;
end;

procedure TLevelData.SaveData(Memory: Pointer);
var
  Index, Size, Last: Integer;
begin
  Last := PartList();
  if Last > 0 then
  begin
    Size := Length(FParts[0].Data);
    CopyMem(Cast(FParts[0].Data), Memory, Size);
    Adv(Memory, Size);
    for Index := 1 to Last - 1 do
    begin
      Size := Length(FParts[Index].Data);
      CastInt(Memory)^ := Size + 4;
      CopyMem(Cast(FParts[Index].Data), Cast(Memory, 4), Size);
      Adv(Memory, Size + 4);
    end;
    Size := Length(FParts[Last].Data);
    CastInt(Memory)^ := Size div 4;
    CopyMem(Cast(FParts[Last].Data), Cast(Memory, 4), Size);
    Adv(Memory, Size + 4);
    CastInt(Memory)^ := 0;
  end;
end;

function TLevelData.SaveData(): DataString;
begin
  SetLength(Result, DataLength());
  SaveData(Cast(Result));
end;

function TLevelData.DataLength(): Integer;
var
  Index: Integer;
begin
  Result := -4;
  for Index := 0 to PartList() do
    Inc(Result, Length(FParts[Index].Data) + 4)
end;

procedure TLevelData.OpenData(Memory: Pointer; Game: NGame);
begin
  if Memory = nil then
    Exit;
  FData := Memory;
  FGame := Game;
  IndexData();
end;

function TLevelData.FirstOffset(): Integer;
begin
  case FGame of
    GameSpyro1:
      Result := 136;
    GameSpyro2:
      Result := 44;
    GameSpyro3:
      Result := 48;
  else
    Result := -1;
  end;
end;

function TLevelData.PartObjects(): Integer;
begin
  case FGame of
    GameSpyro1:
      Result := 8;
    GameSpyro2:
      Result := 9;
    GameSpyro3:
      Result := 13;
  else
    Result := -1;
  end;
end;

function TLevelData.PartVariables(): Integer;
begin
  case FGame of
    GameSpyro1:
      Result := 9;
    GameSpyro2:
      Result := 10;
    GameSpyro3:
      Result := 14;
  else
    Result := -1;
  end;
end;

function TLevelData.PartList(): Integer;
begin
  case FGame of
    GameSpyro1:
      Result := 12;
    GameSpyro2:
      Result := 12;
    GameSpyro3:
      Result := 16;
  else
    Result := -1;
  end;
end;

function TLevelData.PartMenu(): Integer;
begin
  case FGame of
    GameSpyro3:
      Result := 10;
  else
    Result := -1;
  end;
end;

function TLevelData.TakeSomeObjects(Count: Integer): Integer;
var
  Objs, Vars: Integer;
  Temp: DataString;
begin
  Result := 0;
  if Count < 1 then
    Exit;
  Objs := PartObjects();
  Vars := PartVariables();
//  if FGame = GameSpyro1 then    begin
  Result := Count * 88;
  SetLength(FParts[Objs].Data, Length(FParts[Objs].Data) - Result);
  SetLength(Temp, Length(FParts[Vars].Data) + Result);
  CopyMem(Cast(FParts[Vars].Data), Cast(Temp, Result), Length(FParts[Vars].Data));
  ZeroMem(Cast(Temp), Result);
  FParts[Vars].Data := Temp;
  Dec(FParts[Vars].Offset, Result);
//  end;
end;

function TLevelData.GetObjects(out Active, Total: Integer): PLevelObjectsArr;
var
  Data: Pointer;
  Objs, Size: Integer;
begin
  Objs := PartObjects();
  Data := Cast(FParts[Objs].Data);
  Size := Length(FParts[Objs].Data);
  Total := Size div 88;
  Active := CastInt(Data)^;
  Result := Cast(Data, 4);
end;

function TLevelData.GetVariables(out Offset, Size: Integer): Pointer;
var
  Vars: Integer;
begin
  Vars := PartVariables();
  Offset := FParts[Vars].Offset;
  Result := Cast(FParts[Vars].Data);
  Size := Length(FParts[Vars].Data);
end;

function TLevelData.GetList(out Len: Integer): PIntegerArray;
var
  List: Integer;
begin
  List := PartList();
  Result := Cast(FParts[List].Data);
  Len := Length(FParts[List].Data) div 4;
end;

function TLevelData.ListChangePointer(Old: Integer; New: Integer = -1): Boolean;
var
  List: PIntegerArray;
  Index, Len: Integer;
begin
  List := GetList(Len);
  Result := False;
  for Index := 0 to Len - 1 do
    if List[Index] = Old then
    begin
      if New <> -1 then
        List[Index] := New;
      Result := True;
    end;
end;
 {
function TLevelData.IsCharacter(ObjectIndex: Integer): Boolean;
var
  Act, Tot: Integer;
  Obj: PLevelObjectsArr;
  Data, Part: Integer;
  Offset, Size: Integer;
  Character: PLevelCharacter;
  From: Pointer;
begin
  Result := False;
  Obj := GetObjects(Act, Tot);
  if (Obj = nil) or (ObjectIndex < 0) or (ObjectIndex >= Tot) then
    Exit;
  From := GetVariables(Offset, Size);
  Dec(Size, 13);
  Data := Obj[ObjectIndex].Variables - Offset;
  if (Data < 0) or (Data > Size) then
    Exit;
  Character := Cast(From, Data);
  if Character.What <> 255 then
    Exit;
  Data := Character.NameOffset - Offset;
  if (Data < 0) or (Data > Size) then
    Exit;
  Data := Character.TextOffset[1] - Offset;
  if (Data < 0) or (Data > Size) then
    Exit;
  Result := True;
end;
}

end.

