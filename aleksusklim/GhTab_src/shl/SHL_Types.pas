unit SHL_Types; // SpyroHackingLib is licensed under WTFPL

interface

uses
  SysUtils;

type
  TextString = type AnsiString;

  DataString = type AnsiString;

  TextChar = type AnsiChar;

  DataChar = type AnsiChar;

  SetOfChar = set of Char;

type
  PTextChar = PAnsiChar;

  PDataChar_ = PAnsiChar;

  ArrayOfText = array of TextString;

  ArrayOfData = array of DataString;

  ArrayOfWide = array of WideString;

type
  Trilean = (Anything = 0, Include = 1, Exclude = -1);

type
  DeprecatedType = array[0..0, 0..0] of Byte;

  //{
  Char = DeprecatedType;

  PChar = DeprecatedType;

  Pstring = DeprecatedType;

  Cardinal = DeprecatedType;

  PCardinal = DeprecatedType;

  LongInt = DeprecatedType;

  PLongInt = DeprecatedType;

  AnsiChar = DeprecatedType;

  PAnsiChar = DeprecatedType;
  //}

procedure FillChar(out Data; Count: Integer; Value: DataChar); overload;

procedure FillChar(out Data; Count: Integer; Value: Byte); overload;

procedure ZeroMemory(const Deprecat: DeprecatedType);

procedure CopyMemory(const Deprecat: DeprecatedType);

procedure ZeroMem(Destination: Pointer; Length: Integer);

procedure CopyMem(const Source: Pointer; Destination: Pointer; Length: Integer);

function Ignore(const Value): Pointer; overload;

function Ignore(const Value1, Value2): Integer; overload;

function Ignore(const Value1, Value2, Value3): Pointer; overload;

function Ignore(const Value1, Value2, Value3, Value4): Integer; overload;

function Inits(out Value): Pointer;

procedure Assure(Expression: Boolean);

function LittleWord(Big: Word): Word;

function LittleInteger(Big: Integer): Integer;

function TriCheck(Tri: Trilean; Boo: Boolean): Boolean;

function TriMake(Value: Integer): Trilean;

function Bit(var Value: Integer; Bits: Integer; Ext: Boolean): Integer;

procedure Fit(var Value: Integer; Bits: Integer; Data: Integer);

function ShiftAr(s, i: Integer): Integer;

function SignExtend(Value: Integer; Bits: Integer): Integer;

function Adv(var Value: Integer; Add: Integer): Integer; overload;

function Adv(var Value: Pointer; Add: Integer): Pointer; overload;

function CastPtr(From: Pointer; Add: Integer = 0): PPointer; overload;

function CastPtr(const From: DataString; Add: Integer = 0): PPointer; overload;

function CastInt(From: Pointer; Add: Integer = 0): PInteger; overload;

function CastInt(const From: DataString; Add: Integer = 0): PInteger; overload;

function CastWord(From: Pointer; Add: Integer = 0): PWord; overload;

function CastWord(const From: DataString; Add: Integer = 0): PWord; overload;

function CastByte(From: Pointer; Add: Integer = 0): PByte; overload;

function CastByte(const From: DataString; Add: Integer = 0): PByte; overload;

function CastChar(From: Pointer; Add: Integer = 0): PDataChar_; overload;

function CastChar(const From: DataString; Add: Integer = 0): PDataChar_; overload;

function Cast(From: Pointer; Add: Integer): Pointer; overload;

function Cast(const From: DataString): Pointer; overload;

function Cast(const From: DataString; Add: Integer): Pointer; overload;

function Cast(const From: WideString): Pointer; overload;

function Diff(Big: Pointer; Small: Pointer): Integer; overload;

function Diff(Big: Pointer; const Small: DataString): Integer; overload;

procedure Move(DeprecatedCall: DeprecatedType);

function AlignInc(Offset, Align: Integer): Integer;

function AlignValue(Offset, Align: Integer): Integer;

function Obj2Int(Obj: TObject): Integer;

function Int2Obj(Int: Integer): Pointer;

function TestBounds(Low: Integer; Arr: array of Integer; High: Integer): Boolean;

function Median(A, X, B: Integer): Integer;

procedure ExchangeBytes(Ptr1, Ptr2: Pointer; SizeInBytes: Integer);

procedure ExchangeDwords(Ptr1, Ptr2: Pointer; SizeInBytes: Integer);

procedure ExchangeInteger(var Int1, Int2: Integer);

implementation

procedure FillChar(out Data; Count: Integer; Value: DataChar); overload;
begin
  System.FillChar((@Data)^, Count, Value);
end;

procedure FillChar(out Data; Count: Integer; Value: Byte); overload;
begin
  System.FillChar((@Data)^, Count, Chr(Value));
end;

procedure ZeroMemory(const Deprecat: DeprecatedType);
begin
  Ignore(Deprecat);
end;

procedure CopyMemory(const Deprecat: DeprecatedType);
begin
  Ignore(Deprecat);
end;

procedure ZeroMem(Destination: Pointer; Length: Integer);
begin
  if Length > 0 then
    System.FillChar(Destination^, Length, #0);
end;

procedure CopyMem(const Source: Pointer; Destination: Pointer; Length: Integer);
begin
  System.Move(Source^, Destination^, Length);
end;

function Ignore(const Value): Pointer;
begin
  Result := @Value;
end;

function Ignore(const Value1, Value2): Integer;
begin
  Result := PDataChar_(@Value1) - PDataChar_(@Value2);
end;

function Ignore(const Value1, Value2, Value3): Pointer;
begin
  Result := PDataChar_(@Value1) + (PDataChar_(@Value2) - PDataChar_(Value3));
end;

function Ignore(const Value1, Value2, Value3, Value4): Integer;
begin
  Result := PDataChar_(@Value1) + (PDataChar_(@Value2) - PDataChar_(Value3)) -
    PDataChar_(Value4);
end;

function Inits(out Value): Pointer;
begin
  Result := @Value;
end;

procedure Assure(Expression: Boolean);
begin
  if not Expression then
    Abort;
end;

function LittleWord(Big: Word): Word;
begin
  Result := $ffff and ((Big shr 8) or (Big shl 8));
end;

function LittleInteger(Big: Integer): Integer;
begin
  Result := (Big shl 24) or (Big shr 24) or ((Big shr 8) and $ff00) or ((Big shl
    8) and $ff0000);
end;

function TriCheck(Tri: Trilean; Boo: Boolean): Boolean;
begin
  Result := (Tri = Anything) or ((Tri = Include) and Boo) or (Tri = Exclude) and not Boo;
end;

function TriMake(Value: Integer): Trilean;
begin
  if Value > 0 then
    Result := Include
  else if Value < 0 then
    Result := Exclude
  else
    Result := Anything;
end;

function Bit(var Value: Integer; Bits: Integer; Ext: Boolean): Integer;
begin
  Result := Value and ((1 shl Bits) - 1);
  Value := Value shr Bits;
  if Ext then
    if (Result and (1 shl (Bits - 1))) > 0 then
      Result := Result or not ((1 shl Bits) - 1);
end;

procedure Fit(var Value: Integer; Bits: Integer; Data: Integer);
begin
  Value := (Value shl Bits) or (Data and ((1 shl Bits) - 1));
end;

function ShiftAr(s, i: Integer): Integer;
begin
  if (s and Integer($80000000)) <> 0 then
    Result := (s shr i) or Integer(not ((-1) shr i))
  else
    Result := s shr i;
end;

function SignExtend(Value: Integer; Bits: Integer): Integer;
begin
  Result := Bit(Value, Bits, True);
end;

function Adv(var Value: Integer; Add: Integer): Integer; overload;
begin
  Inc(Value, Add);
  Result := Value;
end;

function Adv(var Value: Pointer; Add: Integer): Pointer; overload;
begin
  Inc(PDataChar_(Value), Add);
  Result := Value;
end;

function CastPtr(From: Pointer; Add: Integer = 0): PPointer; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastPtr(const From: DataString; Add: Integer = 0): PPointer;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastInt(From: Pointer; Add: Integer = 0): PInteger; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastInt(const From: DataString; Add: Integer = 0): PInteger; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastWord(From: Pointer; Add: Integer = 0): PWord; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastWord(const From: DataString; Add: Integer = 0): PWord; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastByte(From: Pointer; Add: Integer = 0): PByte; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastByte(const From: DataString; Add: Integer = 0): PByte; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastChar(From: Pointer; Add: Integer = 0): PDataChar_; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function CastChar(const From: DataString; Add: Integer = 0): PDataChar_; overload;
begin
  Result := Pointer(PDataChar_(From) + Add);
end;

function Cast(From: Pointer; Add: Integer): Pointer; overload;
begin
  Result := PDataChar_(From) + Add;
end;

function Cast(const From: DataString): Pointer; overload;
begin
  Result := PDataChar_(From);
end;

function Cast(const From: DataString; Add: Integer): Pointer; overload;
begin
  Result := PDataChar_(From) + Add;
end;

function Cast(const From: WideString): Pointer; overload;
begin
  Result := PWideChar(From);
end;

function Diff(Big: Pointer; Small: Pointer): Integer; overload;
begin
  Result := PDataChar_(Big) - PDataChar_(Small);
end;

function Diff(Big: Pointer; const Small: DataString): Integer; overload;
begin
  Result := PDataChar_(Big) - PDataChar_(Small);
end;

procedure Move(DeprecatedCall: DeprecatedType);
begin
  Abort;
end;

function AlignInc(Offset, Align: Integer): Integer;
begin
  if (Align < 2) then
  begin
    Result := 0;
    Exit;
  end;
  Result := Offset mod Align;
  if Result <> 0 then
    if Offset < 0 then
      Result := -Result
    else
      Result := Align - Result;
end;

function AlignValue(Offset, Align: Integer): Integer;
begin
  Result := Offset + AlignInc(Offset, Align);
end;

function Obj2Int(Obj: TObject): Integer;
begin
  Result := Integer(Pointer(Obj));
end;

function Int2Obj(Int: Integer): Pointer;
begin
  Result := Pointer(Int);
end;

function TestBounds(Low: Integer; Arr: array of Integer; High: Integer): Boolean;
var
  Index: Integer;
begin
  Result := False;
  for Index := 0 to Length(Arr) - 1 do
    if (Arr[Index] < Low) or (Arr[Index] > High) then
      Exit;
  Result := True;
end;

function Median(A, X, B: Integer): Integer;
begin
  Result := X;
  if X < A then
    Result := A;
  if X > B then
    Result := B;
end;

procedure ExchangeBytes(Ptr1, Ptr2: Pointer; SizeInBytes: Integer);
var
  T: Byte;
  A, B: PByte;
begin
  A := Ptr1;
  B := Ptr2;
  while SizeInBytes > 0 do
  begin
    T := A^;
    A^ := B^;
    B^ := T;
    Inc(A);
    Inc(B);
    Dec(SizeInBytes);
  end;
end;

procedure ExchangeDwords(Ptr1, Ptr2: Pointer; SizeInBytes: Integer);
var
  T: Integer;
  A, B: PInteger;
begin
  A := Ptr1;
  B := Ptr2;
  while SizeInBytes > 0 do
  begin
    T := A^;
    A^ := B^;
    B^ := T;
    Inc(A);
    Inc(B);
    Dec(SizeInBytes, 4);
  end;
end;

procedure ExchangeInteger(var Int1, Int2: Integer);
var
  Temp: Integer;
begin
  Temp := Int1;
  Int1 := Int2;
  Int2 := Temp;
end;

end.

