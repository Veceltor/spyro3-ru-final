unit SHL_ModelS1; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Windows, SysUtils, Classes, SHL_GmlModel, SHL_Models3D, SHL_ObjModel,
  SHL_Types;

type
  TModelS1 = class(TObject)
  private
    FData: DataString;
    FMemory: Pointer;
    FSize: Integer;
  public
    procedure Clear();
    function OpenRead(Memory: Pointer; Size: Integer): Boolean; overload;
    function OpenRead(const Data: DataString): Boolean; overload;
    function OpenWrite(VertexCount, NormalCount, PolyCount: Integer): Boolean;
    function VertexCount(): Integer;
    function NormalCount(): Integer;
    function PolyCount(): Integer;
    function ModelID(): Byte;
    function VertexGet(Index: Integer; out Point: RPoint): Boolean;
    function VertexPut(Index: Integer; const Point: RPoint): Boolean;
    function NormalGet(Index: Integer; out Point: RPoint): Boolean;
    function NormalPut(Index: Integer; const Point: RPoint): Boolean;
    function PolyGet(Index: Integer; out Vertex, Smooth: RQuadData; out Normal:
      RPoint; out Transparent, Flat: Boolean): Boolean;
    function PolyPut(Index: Integer; const Vertex, Smooth: RQuadData; const
      Normal: RPoint; Transparent, Flat: Boolean): Boolean;
    procedure GmlSaveVertex(Gml: TGmlModel; Radius: Real; Steps: Integer);
    procedure GmlSaveEdge(Gml: TGmlModel; Triangulate: Trilean);
    procedure GmlSavePoly(Gml: TGmlModel);
    function SaveObj(Obj: TObjModel): Boolean;
    function LoadObj(Obj: TObjModel): Boolean;
    function RawData(): DataString;
  end;

implementation

type
  PHeader = ^RHeader;

  RHeader = record
    VertexCount: Byte;
    PolyCount: Byte;
    ModelID: Byte;
    FFh: Byte;
    VertexOffset: Integer;
    ColorOffset: Integer;
    PolyOffset: Integer;
  end;

  PVertex = ^RVertex;

  RVertex = record
    X, Y, Z: Byte;
  end;

  PNormal = ^RNormal;

  RNormal = record
    X, Y, Z: Byte;
  end;

  PPoly = ^RPoly;

  RPoly = record
    Vertex: Integer;
    Normal: Integer;
  end;

procedure TModelS1.Clear();
begin
  FData := '';
  FMemory := nil;
  FSize := -1;
end;

function TModelS1.OpenRead(Memory: Pointer; Size: Integer): Boolean;
begin
  Result := False;
  Clear();
  if Size < SizeOf(RHeader) then
    Exit;
  with PHeader(Memory)^ do
    if (VertexCount > 127) or (VertexCount = 0) or (PolyCount = 0) or (FFh <> 255) then
      Exit;
  SetString(FData, CastChar(Memory), Size);
  FMemory := Cast(FData);
  FSize := Size;
end;

function TModelS1.OpenRead(const Data: DataString): Boolean;
begin
  Result := OpenRead(Cast(Data), Length(Data));
end;

function TModelS1.OpenWrite(VertexCount, NormalCount, PolyCount: Integer): Boolean;
var
  Header: PHeader;
  Offset, Vert: Integer;
begin
  Result := False;
  Clear();
  if (VertexCount < 1) or (PolyCount < 1) or (VertexCount > 127) or (NormalCount
    > 127) then
    Exit;
  Offset := SizeOf(RHeader) + AlignValue(SizeOf(RNormal) * NormalCount, 4);
  Vert := AlignValue(SizeOf(RVertex) * VertexCount, 4);
  FSize := Offset + Vert + SizeOf(RPoly) * PolyCount;
  SetLength(FData, FSize);
  FMemory := Cast(FData);
  ZeroMem(FMemory, FSize);
  Header := FMemory;
  Header.VertexCount := VertexCount;
  Header.PolyCount := PolyCount;
  Header.ModelID := 0;
  Header.FFh := 255;
  Header.VertexOffset := Offset;
  Header.ColorOffset := 0;
  Header.PolyOffset := Offset + Vert;
  Result := TRue;
end;

function TModelS1.VertexCount(): Integer;
begin
  if FMemory = nil then
    Result := 0
  else
    Result := PHeader(FMemory).VertexCount;
end;

function TModelS1.NormalCount(): Integer;
begin
  if FMemory = nil then
    Result := 0
  else
    Result := (PHeader(FMemory).VertexOffset - SizeOf(RHeader)) div SizeOf(RNormal);
end;

function TModelS1.PolyCount(): Integer;
begin
  if FMemory = nil then
    Result := 0
  else
    Result := PHeader(FMemory).PolyCount;
end;

function TModelS1.ModelID(): Byte;
begin
  if FMemory = nil then
    Result := 0
  else
    Result := PHeader(FMemory).ModelID;
end;

function TModelS1.VertexGet(Index: Integer; out Point: RPoint): Boolean;
var
  Offset: Integer;
  Vertex: PVertex;
begin
  Result := False;
  if (Index < 0) or (Index >= VertexCount()) then
    Exit;
  Offset := PHeader(FMemory).VertexOffset + Index * SizeOf(RVertex);
  if Offset + SizeOf(RVertex) > FSize then
    Exit;
  Vertex := Cast(FMemory, Offset);
  Point.X := SignExtend(Vertex.X, 8);
  Point.Y := SignExtend(Vertex.Y, 8);
  Point.Z := -SignExtend(Vertex.Z, 8);
  Result := True;
end;

function TModelS1.VertexPut(Index: Integer; const Point: RPoint): Boolean;
var
  Offset: Integer;
  Vertex: PVertex;
  X, Y, Z: Integer;
begin
  Result := False;
  if (Index < 0) or (Index >= VertexCount()) then
    Exit;
  Offset := PHeader(FMemory).VertexOffset + Index * SizeOf(RVertex);
  if Offset + SizeOf(RVertex) > FSize then
    Exit;
  Vertex := Cast(FMemory, Offset);
  X := Round(Point.X);
  Y := Round(Point.Y);
  Z := Round(-Point.Z);
  if not TestBounds(-128, [X, Y, Z], 127) then
    Exit;
  Vertex.X := X;
  Vertex.Y := Y;
  Vertex.Z := Z;
  Result := True;
end;

function TModelS1.NormalGet(Index: Integer; out Point: RPoint): Boolean;
var
  Offset: Integer;
  Normal: PNormal;
var
  X, Y, Z: Integer;
begin
  Result := False;
  if Index < 0 then
    Exit;
  Offset := SizeOf(RHeader) + Index * SizeOf(RNormal);
  if Offset + SizeOf(RNormal) > FSize then
    Exit;
  if Offset + SizeOf(RNormal) > PHeader(FMemory).VertexOffset then
    Exit;
  Normal := Cast(FMemory, Offset);
  X := SignExtend(Normal.X, 8);
  Y := SignExtend(Normal.Y, 8);
  Z := SignExtend(Normal.Z, 8);
  if X < 0 then
    Point.X := X / 128
  else
    Point.X := X / 127;
  if Y < 0 then
    Point.Y := Y / 128
  else
    Point.Y := Y / 127;
  if Z < 0 then
    Point.Z := -Z / 128
  else
    Point.Z := -Z / 127;
  Result := True;
end;

function TModelS1.NormalPut(Index: Integer; const Point: RPoint): Boolean;
var
  Offset: Integer;
  Normal: PNormal;
var
  X, Y, Z: Integer;
begin
  Result := False;
  if Index < 0 then
    Exit;
  Offset := SizeOf(RHeader) + Index * SizeOf(RNormal);
  if Offset + SizeOf(RNormal) > FSize then
    Exit;
  if Offset + SizeOf(RNormal) > PHeader(FMemory).VertexOffset then
    Exit;
  Normal := Cast(FMemory, Offset);
  if Point.X < 0 then
    X := Round(Point.X * 128)
  else
    X := Round(Point.X * 127);
  if Point.Y < 0 then
    Y := Round(Point.Y * 128)
  else
    Y := Round(Point.Y * 127);
  if -Point.Z < 0 then
    Z := Round(-Point.Z * 128)
  else
    Z := Round(-Point.Z * 127);
  if not TestBounds(-128, [X, Y, Z], 127) then
    Exit;
  Normal.X := X;
  Normal.Y := Y;
  Normal.Z := Z;
  Result := True;
end;

function TModelS1.PolyGet(Index: Integer; out Vertex, Smooth: RQuadData; out
  Normal: RPoint; out Transparent, Flat: Boolean): Boolean;
var
  Offset: Integer;
  Poly: PPoly;
  Flag, Zero: Byte;
  Vert, Norm: Integer;
  X, Y, Z: Integer;
begin
  Result := False;
  if (Index < 0) or (Index >= PolyCount()) then
    Exit;
  Offset := PHeader(FMemory).PolyOffset + Index * SizeOf(RPoly);
  if Offset + SizeOf(RPoly) > FSize then
    Exit;
  Poly := Cast(FMemory, Offset);
  Vert := Poly.Vertex;
  Norm := Poly.Normal;
  Flag := Bit(Vert, 2, False);
  Vertex[1] := Bit(Vert, 7, False);
  Vertex[2] := Bit(Vert, 7, False);
  Vertex[3] := Bit(Vert, 7, False);
  Vertex[4] := Bit(Vert, 7, False);
  Zero := Bit(Vert, 2, False);
  if (Zero <> 0) or (Flag = 2) then
    Exit;
  if Flag = 0 then
  begin
    Flat := False;
    Transparent := False;
    Normal.X := 0;
    Normal.Y := 0;
    Normal.Z := 0;
    Flag := Bit(Norm, 2, False);
    Smooth[1] := Bit(Norm, 7, False);
    Smooth[2] := Bit(Norm, 7, False);
    Smooth[3] := Bit(Norm, 7, False);
    Smooth[4] := Bit(Norm, 7, False);
    Zero := Bit(Norm, 2, False);
    if Zero <> 0 then
      Exit;
    if Flag = 255 then
      Exit;
  end
  else
  begin
    Flat := True;
    Transparent := Flag = 3;
    Smooth[1] := -1;
    Smooth[2] := -1;
    Smooth[3] := -1;
    Smooth[4] := -1;
    Zero := Bit(Norm, 8, False);
    Z := Bit(Norm, 8, True);
    Y := Bit(Norm, 8, True);
    X := Bit(Norm, 8, True);
    if Zero <> 0 then
      Exit;
    if X < 0 then
      Normal.X := X / 128
    else
      Normal.X := X / 127;
    if Y < 0 then
      Normal.Y := Y / 128
    else
      Normal.Y := Y / 127;
    if Z < 0 then
      Normal.Z := -Z / 128
    else
      Normal.Z := -Z / 127;
  end;
  Result := True;
end;

function TModelS1.PolyPut(Index: Integer; const Vertex, Smooth: RQuadData; const
  Normal: RPoint; Transparent, Flat: Boolean): Boolean;
var
  Offset: Integer;
  Poly: PPoly;
  Flag: Byte;
  Vert, Norm: Integer;
  X, Y, Z: Integer;
begin
  Result := False;
  if (Index < 0) or (Index >= PolyCount()) then
    Exit;
  Offset := PHeader(FMemory).PolyOffset + Index * SizeOf(RPoly);
  if Offset + SizeOf(RPoly) > FSize then
    Exit;
  if Transparent and not Flat then
    Exit;
  Poly := Cast(FMemory, Offset);
  if Flat then
  begin
    if Transparent then
      Flag := 3
    else
      Flag := 1;
    if Normal.X < 0 then
      X := Round(Normal.X * 128)
    else
      X := Round(Normal.X * 127);
    if Normal.Y < 0 then
      Y := Round(Normal.Y * 128)
    else
      Y := Round(Normal.Y * 127);
    if -Normal.Z < 0 then
      Z := Round(-Normal.Z * 128)
    else
      Z := Round(-Normal.Z * 127);
    if not TestBounds(-128, [X, Y, Z], 127) then
      Exit;
    Fit(Norm, 8, X);
    Fit(Norm, 8, Y);
    Fit(Norm, 8, Z);
    Fit(Norm, 8, 0);
  end
  else
  begin
    Flag := 0;
    Fit(Norm, 2, 0);
    Fit(Norm, 7, Smooth[4]);
    Fit(Norm, 7, Smooth[3]);
    Fit(Norm, 7, Smooth[2]);
    Fit(Norm, 7, Smooth[1]);
    Fit(Norm, 2, Flag);
  end;
  Vert := 0;
  Fit(Vert, 2, 0);
  Fit(Vert, 7, Vertex[4]);
  Fit(Vert, 7, Vertex[3]);
  Fit(Vert, 7, Vertex[2]);
  Fit(Vert, 7, Vertex[1]);
  Fit(Vert, 2, Flag);
  Poly.Vertex := Vert;
  Poly.Normal := Norm;
  Result := True;
end;

procedure TModelS1.GmlSaveVertex(Gml: TGmlModel; Radius: Real; Steps: Integer);
var
  Index: Integer;
  Point: RPoint;
begin
  if FMemory = nil then
    Exit;
  for Index := 0 to VertexCount() - 1 do
    if VertexGet(Index, Point) then
      Gml.Ball(Point.X, Point.Y, Point.Z, Radius, Steps);
end;

procedure TModelS1.GmlSaveEdge(Gml: TGmlModel; Triangulate: Trilean);
var
  Index: Integer;
  Vertex, Smooth: RQuadData;
  Normal: RPoint;
  Transparent, Flat: Boolean;
  Vert1, Vert2, Vert3, Vert4: RPoint;
begin
  if FMemory = nil then
    Exit;
  Gml.PrimitiveBegin(GmlPrimitiveLinelist);
  for Index := 0 to PolyCount() - 1 do
    if PolyGet(Index, Vertex, Smooth, Normal, Transparent, Flat) then
      if VertexGet(Vertex[1], Vert1) and VertexGet(Vertex[2], Vert2) and
        VertexGet(Vertex[3], Vert3) and VertexGet(Vertex[4], Vert4) then
      begin
        if TriCheck(Triangulate, False) then
        begin
          Gml.Vertex(Vert1.X, Vert1.Y, Vert1.Z);
          Gml.Vertex(Vert2.X, Vert2.Y, Vert2.Z);
          Gml.Vertex(Vert2.X, Vert2.Y, Vert2.Z);
          Gml.Vertex(Vert4.X, Vert4.Y, Vert4.Z);
          Gml.Vertex(Vert4.X, Vert4.Y, Vert4.Z);
          Gml.Vertex(Vert3.X, Vert3.Y, Vert3.Z);
          Gml.Vertex(Vert3.X, Vert3.Y, Vert3.Z);
          Gml.Vertex(Vert1.X, Vert1.Y, Vert1.Z);
        end;
        if (Vertex[1] <> Vertex[2]) and TriCheck(Triangulate, True) then
        begin
          Gml.Vertex(Vert2.X, Vert2.Y, Vert2.Z);
          Gml.Vertex(Vert3.X, Vert3.Y, Vert3.Z);
        end;
      end;
  Gml.PrimitiveEnd();
end;

procedure TModelS1.GmlSavePoly(Gml: TGmlModel);
var
  Index: Integer;
  Vertex, Smooth: RQuadData;
  Normal: RPoint;
  Transparent, Flat: Boolean;
  Vert1, Vert2, Vert3, Vert4: RPoint;
  Norm1, Norm2, Norm3, Norm4: RPoint;
begin
  if FMemory = nil then
    Exit;
  Gml.PrimitiveBegin(GmlPrimitiveTrianglelist);
  for Index := 0 to PolyCount() - 1 do
    if PolyGet(Index, Vertex, Smooth, Normal, Transparent, Flat) then
      if VertexGet(Vertex[1], Vert1) and VertexGet(Vertex[2], Vert2) and
        VertexGet(Vertex[3], Vert3) and VertexGet(Vertex[4], Vert4) then
      begin
        if Flat then
        begin
          Norm1 := Normal;
          Norm2 := Normal;
          Norm3 := Normal;
          Norm4 := Normal;
        end
        else if not (NormalGet(Smooth[1], Norm1) and NormalGet(Smooth[2], Norm2)
          and NormalGet(Smooth[3], Norm3) and NormalGet(Smooth[4], Norm4)) then
          Continue;
        if Vertex[1] <> Vertex[2] then
        begin
          Gml.VertexNormal(Vert1.X, Vert1.Y, Vert1.Z, Norm1.X, Norm1.Y, Norm1.Z);
          Gml.VertexNormal(Vert2.X, Vert2.Y, Vert2.Z, Norm2.X, Norm2.Y, Norm2.Z);
          Gml.VertexNormal(Vert3.X, Vert3.Y, Vert3.Z, Norm3.X, Norm3.Y, Norm3.Z);
        end;
        Gml.VertexNormal(Vert2.X, Vert2.Y, Vert2.Z, Norm2.X, Norm2.Y, Norm2.Z);
        Gml.VertexNormal(Vert4.X, Vert4.Y, Vert4.Z, Norm4.X, Norm4.Y, Norm4.Z);
        Gml.VertexNormal(Vert3.X, Vert3.Y, Vert3.Z, Norm3.X, Norm3.Y, Norm3.Z);
      end;
  Gml.PrimitiveEnd();
end;

function TModelS1.SaveObj(Obj: TObjModel): Boolean;
var
  Index, J, N, T: Integer;
  Point: RPoint;
  Vertex, Smooth: RQuadData;
  Normal: RPoint;
  Transparent, Flat: Boolean;
  VertexIndex, NormalIndex, ColorIndex: Integer;
begin
  Result := False;
  try
    Assure(Obj <> nil);
    VertexIndex := Obj.Vertexes + 1;
    for Index := 0 to VertexCount() - 1 do
    begin
      Assure(VertexGet(Index, Point));
      Obj.AddVertex(Point);
    end;
    NormalIndex := Obj.Normals + 1;
    for Index := 0 to NormalCount() - 1 do
    begin
      Assure(NormalGet(Index, Point));
      Obj.AddNormal(Point);
    end;
    ColorIndex := Obj.Textures + 1;
    Obj.AddTextureColor(255, 255, 0);
    Obj.AddTextureColor(0, 0, 255);
    for Index := 0 to PolyCount() - 1 do
    begin
      Assure(PolyGet(Index, Vertex, Smooth, Normal, Transparent, Flat));
      if Flat then
      begin
        N := Obj.AddNormal(Normal);
        for J := 1 to 4 do
          Smooth[J] := N;
      end
      else
        for J := 1 to 4 do
          Smooth[J] := NormalIndex + Smooth[J];
      T := ColorIndex + Ord(Transparent);
      if Vertex[1] = Vertex[2] then
        Obj.AddFaceTextureNormal(VertexIndex + Vertex[2], T, Smooth[2],
          VertexIndex + Vertex[4], T, Smooth[4], VertexIndex + Vertex[3], T, Smooth[3])
      else
        Obj.AddFaceTextureNormal(VertexIndex + Vertex[2], T, Smooth[2],
          VertexIndex + Vertex[4], T, Smooth[4], VertexIndex + Vertex[3], T,
          Smooth[3], VertexIndex + Vertex[1], T, Smooth[1]);
    end;
    Result := True;
  except
  end;
end;

function TModelS1.LoadObj(Obj: TObjModel): Boolean;
var
  Normals: array[0..127] of RPoint;
  Norms: Integer;

  function AddNormal(Point: RPoint): Byte;
  var
    I: Integer;
  begin
    Result := 255;
    if Norms = 255 then
      Exit;
    with SModels3D do
      for I := 0 to Norms - 1 do
        if Same(Point, Normals[I]) then
        begin
          Result := I;
          Exit;
        end;
    if Norms > 127 then
    begin
      Norms := 255;
      Exit;
    end
    else
    begin
      Result := Norms;
      Inc(Norms);
      Normals[Result] := Point;
    end;
  end;

  function ColorTest(Color: RColor): Boolean;
  begin
    if (Color.B > Color.R) and (Color.B > Color.G) then
      Result := True
    else if (Color.B < Color.R) and (Color.B < Color.G) then
      Result := False
    else
    begin
      Result := False;
      Abort;
    end;
  end;

var
  Index: Integer;
  V1, V2, V3, V4, T1, T2, T3, T4, N1, N2, N3, N4: Integer;
  Point: RPoint;
  Quad, Flat: Boolean;
  Color: RColor;
  Poly: array of record
    Vertex, Smooth: RQuadData;
    Normal: RPoint;
    Transparent, Flat: Boolean;
  end;
begin
  Result := False;
  with SModels3D do
  try
    Assure((Obj <> nil) and (Obj.Faces > 0) and (Obj.Vertexes <= 128));
    Norms := 0;
    SetLength(Poly, Obj.Faces + 1);
    for Index := 1 to Obj.Faces do
    begin
      Obj.GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
      Quad := V4 <> 0;
      Assure((N1 <> 0) and (N2 <> 0) and (N3 <> 0) and (not Quad or (N4 <> 0)));
      Point := Obj.GetNormal(N1);
      Flat := Same(Point, Obj.GetNormal(N2)) and Same(Point, Obj.GetNormal(N3))
        and (not Quad or Same(Point, Obj.GetNormal(N4)));
//      Flat := False;
      Poly[Index].Flat := Flat;
      Assure((T1 = T2) and (T1 = T3) and (not Quad or (T1 = T4)));
      Assure(Obj.GetTextureColor(T1, Color.Color));
      Poly[Index].Transparent := ColorTest(Color);
      if not Quad then
        V4 := V1;
      Poly[Index].Vertex[1] := V4 - 1;
      Poly[Index].Vertex[2] := V1 - 1;
      Poly[Index].Vertex[3] := V3 - 1;
      Poly[Index].Vertex[4] := V2 - 1;
      if Flat then
        Poly[Index].Normal := Point
      else
      begin
        Poly[Index].Smooth[1] := AddNormal(Obj.GetNormal(N1));
        Poly[Index].Smooth[2] := AddNormal(Obj.GetNormal(N2));
        Poly[Index].Smooth[3] := AddNormal(Obj.GetNormal(N3));
        if Quad then
          Poly[Index].Smooth[4] := AddNormal(Obj.GetNormal(N4));
      end;
    end;
    Assure(Norms <> 255);
    Assure(OpenWrite(Obj.Vertexes, Norms, Obj.Faces));
    for Index := 0 to Obj.Vertexes - 1 do
    begin
      Assure(Obj.GetVertex(Index + 1, Point.X, Point.Y, Point.Z));
      Assure(VertexPut(Index, Point));
    end;
    for Index := 0 to Norms - 1 do
      Assure(NormalPut(Index, Normals[Index]));
    for Index := 1 to Obj.Faces do
      Assure(PolyPut(Index - 1, Poly[Index].Vertex, Poly[Index].Smooth, Poly[Index].Normal,
        Poly[Index].Transparent, Poly[Index].Flat));
    Result := True;
  except
  end;
end;

function TModelS1.RawData(): DataString;
begin
  SetString(Result, CastChar(FMemory), FSize);
end;

end.

