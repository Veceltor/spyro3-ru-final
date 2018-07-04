unit SHL_Knapsack; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Classes, SysUtils, SHL_Types, SHL_MemoryManager;

type
  TKnapsack = class(TObject)
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Clear();
    procedure AddSpace(Offset, Count: Integer);
    procedure AddItem(Addr: Pointer; Name, Size, Align: Integer);
    function Compute(): Integer;
    procedure GetItem(Index: Integer; out Addr: Pointer; out Offset, Name, Size:
      Integer; out Fit: Boolean);
    function ExtraSpace(): Integer;
  private
    FItem, FSpace: TList;
    FMem: TMemorySimple;
    FIndex: Integer;
    FComputed: Boolean;
  public
    property ItemCount: Integer read FIndex;
  end;

implementation

type
  PItem = ^RItem;

  RItem = record
    Index, Name, Size, Take, Align: Integer;
    Addr: Pointer;
  end;

  PSpace = ^RSpace;

  RSpace = record
    Offset, Count, Walk: Integer;
  end;

function ItemSort(Item1, Item2: Pointer): Integer;
begin
  Result := PItem(Item1).Size - PItem(Item2).Size;
end;

function SpaceSort(Space1, Space2: Pointer): Integer;
begin
  Result := PSpace(Space1).Offset - PSpace(Space2).Offset;
end;

procedure ListRestoreByIndex(List: TList);
var
  Index: Integer;
begin
  for Index := 0 to List.Count - 1 do
    while PInteger(List[Index])^ <> Index do
      List.Exchange(Index, PInteger(List[Index])^);
end;

constructor TKnapsack.Create();
begin
  inherited Create();
  FItem := TList.Create();
  FSpace := TList.Create();
  FMem := TMemorySimple.Create();
end;

destructor TKnapsack.Destroy();
begin
  FItem.Free();
  FSpace.Free();
  FMem.Free();
  inherited Destroy();
end;

procedure TKnapsack.Clear();
begin
  FItem.Clear();
  FSpace.Clear();
  FMem.Clear();
  FIndex := 0;
  FComputed := False;
end;

procedure TKnapsack.AddSpace(Offset, Count: Integer);
var
  Space: PSpace;
begin
  if (Count = 0) or FComputed then
    Exit;
  Space := FMem.Alloc(SizeOf(RSpace), 4);
  Space.Offset := Offset;
  Space.Count := Count;
  FSpace.Add(Space);
end;

procedure TKnapsack.AddItem(Addr: Pointer; Name, Size, Align: Integer);
var
  Item: PItem;
begin
  if FComputed then
    Exit;
  Item := FMem.Alloc(SizeOf(RItem), 4);
  Item.Addr := Addr;
  Item.Name := Name;
  Item.Size := Size;
  Item.Align := Align;
  Item.Take := -1;
  Item.Index := FIndex;
  Inc(FIndex);
  FItem.Add(Item);
end;

function TKnapsack.Compute(): Integer;
var
  Index, Size, Current, Take, Need: Integer;
  Item: PItem;
  Space: PSpace;
begin
  Result := 0;
  if FComputed then
    Exit;
  FComputed := True;
  if FItem.Count = 0 then
    Exit;
  if FSpace.Count = 0 then
  begin
    for Index := 0 to FItem.Count - 1 do
    begin
      Item := FItem[Index];
      Item.Take := -2;
      Item.Index := AlignValue(Result, Item.Align);
      Result := Item.Index + Item.Size;
    end;
    Exit;
  end;

  FItem.Sort(ItemSort);
  FSpace.Sort(SpaceSort);

  Size := 0;
  Space := FSpace[0];
  Space.Walk := Space.Offset;
  for Index := 1 to FSpace.Count - 1 do
    if Space.Offset + Space.Count >= PSpace(FSpace[Index]).Offset then
      Space.Count := PSpace(FSpace[Index]).Count + PSpace(FSpace[Index]).Offset - Space.Offset
    else
    begin
      Inc(Size);
      FSpace[Size] := FSpace[Index];
      Space := FSpace[Size];
      Space.Walk := Space.Offset;
    end;

  repeat
    Index := FItem.Count - 1;
    while True do
      if PItem(FItem[Index]).Take = -1 then
        Break
      else
        Dec(Index);
    Item := FItem[Index];
    Take := -2;
    Current := Size;
    repeat
      Space := PSpace(FSpace[Current]);
      Need := Item.Size + AlignInc(Space.Offset, Item.Align);
      if (Space.Count >= Need) and ((Take = -2) or (Space.Count < PSpace(FSpace[Take]).Count))
        then
        Take := Current;
      Dec(Current);
    until Current < 0;
    Item.Take := Take;
    if Take <> -2 then
    begin
      Space := PSpace(FSpace[Take]);
      Dec(Space.Count, Need);
      Inc(Space.Offset, Need);
    end;
  until Index = 0;

  ListRestoreByIndex(FItem);

  Result := 0;
  for Index := 0 to FItem.Count - 1 do
  begin
    Item := PItem(FItem[Index]);
    Take := Item.Take;
    if Take = -2 then
    begin
      Item.Index := AlignValue(Result, Item.Align);
      Result := Item.Index + Item.Size;
    end
    else
    begin
      Space := PSpace(FSpace[Take]);
      Item.Index := AlignValue(Space.Walk, Item.Align);
      Space.Walk := Item.Index + Item.Size;
    end;
  end;
end;

procedure TKnapsack.GetItem(Index: Integer; out Addr: Pointer; out Offset, Name,
  Size: Integer; out Fit: Boolean);
var
  Item: PItem;
begin
  if (Index >= FItem.Count) or (Index < 0) or not FComputed then
  begin
    Fit := False;
    Offset := -1;
    Name := -1;
    Size := -1;
    Addr := nil;
    Exit;
  end;
  Item := FItem[Index];
  Addr := Item.Addr;
  Offset := Item.Index;
  Size := Item.Size;
  Name := Item.Name;
  Fit := Item.Take >= 0;
end;

function TKnapsack.ExtraSpace(): Integer;
var
  Index: Integer;
begin
  Result := 0;
  if FComputed then
    for Index := 0 to FItem.Count - 1 do
      if PItem(FItem[Index]).Take < 0 then
        Inc(Result, PItem(FItem[Index]).Size);
end;

end.

