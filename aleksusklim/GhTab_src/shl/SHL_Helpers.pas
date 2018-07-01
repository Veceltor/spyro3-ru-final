unit SHL_Helpers; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, Classes, SHL_Types;

type
  TIntegerListSortCompare = function(Item1, Item2: Integer): Integer;

  TIntegerList = class(TList)
  protected
    function Get(Index: Integer): Integer;
    procedure Put(Index: Integer; Item: Integer);
  public
    function Add(Item: Integer): Integer;
    function Extract(Item: Integer): Integer;
    function First(): Integer;
    function IndexOf(Item: Integer): Integer;
    procedure Insert(Index: Integer; Item: Integer);
    function Last(): Integer;
    function Remove(Item: Integer): Integer;
    procedure Sort(Compare: TIntegerListSortCompare);
    property Items[Index: Integer]: Integer read Get write Put; default;
  end;

implementation

function TIntegerList.Get(Index: Integer): Integer;
begin
  Result := Integer(inherited Get(Index));
end;

procedure TIntegerList.Put(Index: Integer; Item: Integer);
begin
  inherited Put(Index, Pointer(Item));
end;

function TIntegerList.Add(Item: Integer): Integer;
begin
  Result := inherited Add(Pointer(Item));
end;

function TIntegerList.Extract(Item: Integer): Integer;
begin
  Result := Integer(inherited Extract(Pointer(Item)));
end;

function TIntegerList.First(): Integer;
begin
  Result := Integer(inherited First());
end;

function TIntegerList.IndexOf(Item: Integer): Integer;
begin
  Result := inherited IndexOf(Pointer(Item));
end;

procedure TIntegerList.Insert(Index: Integer; Item: Integer);
begin
  inherited Insert(Index, Pointer(Item));
end;

function TIntegerList.Last(): Integer;
begin
  Result := Integer(inherited Last());
end;

function TIntegerList.Remove(Item: Integer): Integer;
begin
  Result := inherited Remove(Pointer(Item));
end;

procedure TIntegerList.Sort(Compare: TIntegerListSortCompare);
begin
  inherited Sort(TListSortCompare(Compare));
end;

end.

