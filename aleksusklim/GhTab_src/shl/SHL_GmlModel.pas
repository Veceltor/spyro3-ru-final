unit SHL_GmlModel; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Classes, SysUtils, SHL_ObjModel, SHL_Models3D, SHL_Types;

type
  NGmlPrimitive = (GmlPrimitivePointlist = 1, GmlPrimitiveLinelist = 2,
    GmlPrimitiveLinestrip = 3, GmlPrimitiveTrianglelist = 4,
    GmlPrimitiveTrianglestrip = 5, GmlPrimitiveTrianglefan = 6);

type
  TGmlModel = class(TObject)
  private
    FText: Text;
    FName: string;
    FCount: Integer;
  public
    constructor Create(Filename: string);
    destructor Destroy(); override;
  public
    class function Color(r, g, b: Real): Integer;
    procedure Send(Mode: Integer; v1, v2, v3, v4, v5, v6, v7, v8, v9, v10: Real);
    procedure Ellipsoid(x1, y1, z1, x2, y2, z2, hrepeat, vrepeat, steps: Real);
    procedure Ball(x, y, z, r, steps: Real);
    procedure Vertex(x, y, z: Real);
    procedure VertexNormal(x, y, z, nx, ny, nz: Real);
    procedure VertexColor(x, y, z: Real; c: Integer; alpha: Real = 1);
    procedure VertexNormalColor(x, y, z, nx, ny, nz: Real; c: Integer; alpha: Real = 1);
    procedure VertexTexture(x, y, z, xtex, ytex: Real);
    procedure VertexNormalTexture(x, y, z, nx, ny, nz, xtex, ytex: Real);
    procedure VertexTextureColor(x, y, z, xtex, ytex: Real; c: Integer; alpha: Real = 1);
    procedure VertexNormalTextureColor(x, y, z, nx, ny, nz, xtex, ytex: Real; c:
      Integer; alpha: Real = 1);
    procedure PrimitiveBegin(PrimitiveMode: NGmlPrimitive);
    procedure PrimitiveEnd();
    procedure TriaRec(Level: Integer; x1, y1, z1, x2, y2, z2, x3, y3, z3, nx, ny,
      nz: Real);
    procedure Background(Size: Real; Color: Integer);
    procedure ObjVertex(Obj: TObjModel; Radius: Real; Steps: Integer);
    procedure ObjEdges(Obj: TObjModel);
    procedure ObjNormals(Obj: TObjModel; Len: Real);
    procedure ObjFaces(Obj: TObjModel; ColorNormal, ColorTexture: Boolean; Norms,
      Texts, Sides: Trilean; Alpha: Real);
  private
    function NormalColor(X, Y, Z: Real): Integer; overload;
    function NormalColor(const Normal: RPoint): Integer; overload;
    function TextureColor(X, Y, Z: Real): Integer; overload;
    function TextureColor(const Texture: RPoint): Integer; overload;
  end;

implementation

constructor TGmlModel.Create(Filename: string);
begin
  inherited Create();
  FName := Filename;
  Assign(FText, FName);
  Rewrite(FText);
  Writeln(Ftext, 100);
  Writeln(Ftext, '0          ');
  FCount := 0;
end;

destructor TGmlModel.Destroy();
var
  Stream: TFileStream;
  Header: string;
begin
  Close(FText);
  Header := '100'#13#10 + IntToStr(FCount);
  Stream := TFileStream.Create(FName, fmOpenReadWrite or fmShareDenyNone);
  Stream.WriteBuffer(Cast(Header)^, Length(Header));
  Stream.Free();
  inherited Destroy();
end;

class function TGmlModel.Color(r, g, b: Real): Integer;
begin
  Result := Round(Abs(b) * 256 * 256 + Abs(g) * 256 + Abs(r));
end;

procedure TGmlModel.Send(Mode: Integer; v1, v2, v3, v4, v5, v6, v7, v8, v9, v10: Real);
var
  Settings: TFormatSettings;
begin
  ZeroMem(@Settings, SizeOf(Settings));
  Settings.DecimalSeparator := '.';
  Writeln(FText, Format('%d %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f %.4f',
    [Mode, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10], Settings));
  Inc(FCount);
end;

procedure TGmlModel.Ellipsoid(x1, y1, z1, x2, y2, z2, hrepeat, vrepeat, steps: Real);
begin
  Send(13, x1, y1, z1, x2, y2, z2, hrepeat, vrepeat, steps, 0);
end;

procedure TGmlModel.Ball(x, y, z, r, steps: Real);
begin
  Ellipsoid(x - r, y - r, z - r, x + r, y + r, z + r, 1, 1, steps);
end;

procedure TGmlModel.Vertex(x, y, z: Real);
begin
  Send(2, x, y, z, 0, 0, 0, 0, 0, 0, 0);
end;

procedure TGmlModel.VertexNormal(x, y, z, nx, ny, nz: Real);
begin
  Send(6, x, y, z, nx, ny, nz, 0, 0, 0, 0);
end;

procedure TGmlModel.VertexColor(x, y, z: Real; c: Integer; alpha: Real = 1);
begin
  Send(3, x, y, z, c, alpha, 0, 0, 0, 0, 0);
end;

procedure TGmlModel.VertexNormalColor(x, y, z, nx, ny, nz: Real; c: Integer;
  alpha: Real = 1);
begin
  Send(7, x, y, z, nx, ny, nz, c, alpha, 0, 0);
end;

procedure TGmlModel.VertexTexture(x, y, z, xtex, ytex: Real);
begin
  Send(4, x, y, z, xtex, ytex, 0, 0, 0, 0, 0);
end;

procedure TGmlModel.VertexNormalTexture(x, y, z, nx, ny, nz, xtex, ytex: Real);
begin
  Send(8, x, y, z, nx, ny, nz, xtex, ytex, 0, 0);
end;

procedure TGmlModel.VertexTextureColor(x, y, z, xtex, ytex: Real; c: Integer;
  alpha: Real = 1);
begin
  Send(5, x, y, z, xtex, ytex, c, alpha, 0, 0, 0);
end;

procedure TGmlModel.VertexNormalTextureColor(x, y, z, nx, ny, nz, xtex, ytex:
  Real; c: Integer; alpha: Real = 1);
begin
  Send(9, x, y, z, nx, ny, nz, xtex, ytex, c, alpha);
end;

procedure TGmlModel.PrimitiveBegin(PrimitiveMode: NGmlPrimitive);
begin
  Send(0, Integer(PrimitiveMode), 0, 0, 0, 0, 0, 0, 0, 0, 0);
end;

procedure TGmlModel.PrimitiveEnd();
begin
  Send(1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
end;

procedure TGmlModel.TriaRec(Level: Integer; x1, y1, z1, x2, y2, z2, x3, y3, z3,
  nx, ny, nz: Real);
const
  nr = 4;
begin
  Inc(Level);
  if Level > 3 then
    Exit;
  VertexColor(x1, y1, z1, Color(nx, ny, nz));
  VertexColor(x1 + nx * nr, y1 + ny * nr, z1 + nz * nr, Color(nx, ny, nz));
  VertexColor(x2, y2, z2, Color(nx, ny, nz));
  VertexColor(x2 + nx * nr, y2 + ny * nr, z2 + nz * nr, Color(nx, ny, nz));
  VertexColor(x3, y3, z3, Color(nx, ny, nz));
  VertexColor(x3 + nx * nr, y3 + ny * nr, z3 + nz * nr, Color(nx, ny, nz));
  TriaRec(Level, (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, (x1 + x3) / 2, (y1
    + y3) / 2, (z1 + z3) / 2, (x3 + x2) / 2, (y3 + y2) / 2, (z3 + z2) / 2, nx, ny, nz);
  TriaRec(Level, (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, (x1 + x3) / 2, (y1
    + y3) / 2, (z1 + z3) / 2, x1, y1, z1, nx, ny, nz);
  TriaRec(Level, x3, y3, z3, (x1 + x3) / 2, (y1 + y3) / 2, (z1 + z3) / 2, (x3 +
    x2) / 2, (y3 + y2) / 2, (z3 + z2) / 2, nx, ny, nz);
  TriaRec(Level, (x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2, x2, y2, z2, (x3 +
    x2) / 2, (y3 + y2) / 2, (z3 + z2) / 2, nx, ny, nz);
end;

procedure TGmlModel.Background(Size: Real; Color: Integer);
var
  len, hei: Real;
  Vertex: array[1..4, 1..3] of Real;
  i, j: Integer;
const
  Seq: array[1..4, 1..3] of Integer = ((1, 3, 2), (1, 2, 4), (2, 3, 4), (3, 1, 4));
begin
  len := Size * Sqrt(3) / 3;
  hei := Size * Sqrt(6) / 6;
  Vertex[1, 1] := -len * 2;
  Vertex[1, 2] := 0;
  Vertex[1, 3] := -hei;
  Vertex[2, 1] := len;
  Vertex[2, 2] := -Size;
  Vertex[2, 3] := -hei;
  Vertex[3, 1] := len;
  Vertex[3, 2] := Size;
  Vertex[3, 3] := -hei;
  Vertex[4, 1] := 0;
  Vertex[4, 2] := 0;
  Vertex[4, 3] := hei * 3;
  for i := 1 to 4 do
    for j := 1 to 3 do
      VertexColor(Vertex[Seq[i, j], 1], Vertex[Seq[i, j], 2], Vertex[Seq[i, j],
        3], Color);
end;

function TGmlModel.NormalColor(X, Y, Z: Real): Integer;
var
  R, G, B: Integer;
begin
  if X > 0 then
    R := Round(X * 255)
  else
    R := Round(-X * 255);
  if Y > 0 then
    G := Round(Y * 255)
  else
    G := Round(-Y * 255);
  if Z > 0 then
    B := Round(Z * 255)
  else
    B := Round(-Z * 255);
  if R > 255 then
    R := 255;
  if G > 255 then
    G := 255;
  if B > 255 then
    B := 255;
  Result := (R and 255) or ((G and 255) shl 8) or ((B and 255) shl 16);
end;

function TGmlModel.NormalColor(const Normal: RPoint): Integer;
begin
  Result := NormalColor(Normal.X, Normal.Y, Normal.Z)
end;

function TGmlModel.TextureColor(X, Y, Z: Real): Integer;
var
  R, G, B: Integer;
begin
  R := Round(X * 255);
  G := Round(Y * 255);
  B := Round(Z * 255);
  Result := (R and 255) or ((G and 255) shl 8) or ((B and 255) shl 16);
end;

function TGmlModel.TextureColor(const Texture: RPoint): Integer;
begin
  Result := TextureColor(Texture.X, Texture.Y, Texture.Z)
end;

procedure TGmlModel.ObjVertex(Obj: TObjModel; Radius: Real; Steps: Integer);
var
  Index: Integer;
  X, Y, Z: Real;
begin
  for Index := 1 to Obj.Vertexes do
    if Obj.GetVertex(Index, Y, X, Z) then
      Ball(X, Y, Z, Radius, Steps);
end;

procedure TGmlModel.ObjEdges(Obj: TObjModel);
var
  Index, Counter: Integer;
  V1, V2, V3, V4: Integer;
  X1, Y1, Z1, X2, Y2, Z2, X3, Y3, Z3, X4, Y4, Z4: Real;
begin
  Counter := 0;
  PrimitiveBegin(GmlPrimitiveLinelist);
  for Index := 1 to Obj.Faces do
    if Obj.GetFace(Index, V1, V2, V3, V4) then
      if Obj.GetVertex(V1, Y1, X1, Z1) and Obj.GetVertex(V2, Y2, X2, Z2) and Obj.GetVertex
        (V3, Y3, X3, Z3) and ((V4 = 0) or (Obj.GetVertex(V4, Y4, X4, Z4))) then
      begin
        if Counter = 2048 then
        begin
          Counter := 0;
          PrimitiveEnd();
          PrimitiveBegin(GmlPrimitiveLinelist);
        end;
        Inc(Counter);
        Vertex(X1, Y1, Z1);
        Vertex(X2, Y2, Z2);

        Vertex(X2, Y2, Z2);
        Vertex(X3, Y3, Z3);

        Vertex(X3, Y3, Z3);
        Vertex(X1, Y1, Z1);
        if V4 <> 0 then
        begin
          Vertex(X3, Y3, Z3);
          Vertex(X4, Y4, Z4);

          Vertex(X4, Y4, Z4);
          Vertex(X1, Y1, Z1);
        end;
      end;
  PrimitiveEnd();
end;

procedure TGmlModel.ObjNormals(Obj: TObjModel; Len: Real);

  procedure Norm(const V, N: RPoint);
  var
    X, Y, Z, D: Real;
  begin
    D := Sqrt(N.X * N.X + N.Y * N.Y + N.Z * N.Z);
    if D = 0 then
      Exit;
    X := N.X / D;
    Y := N.Y / D;
    Z := N.Z / D;
    VertexColor(V.Y, V.X, V.Z, 0, 1);
    VertexColor(V.Y + Len * Y, V.X + Len * X, V.Z + Len * Z, NormalColor(Y, X, Z), 1);
  end;

  function Two(P1, P2: RPoint): RPoint;
  begin
    Result.X := (P1.X + P2.X) / 2;
    Result.Y := (P1.Y + P2.Y) / 2;
    Result.Z := (P1.Z + P2.Z) / 2;
  end;

  procedure Tria(const V1, N1, V2, N2, V3, N3: RPoint; L: Integer);
  var
    AN, AV, BN, BV, CN, CV: RPoint;
  begin
    if L = 3 then
      Exit;
    Inc(L);
    Norm(V1, N1);
    Norm(V2, N2);
    Norm(V3, N3);
    AV := Two(V2, V3);
    AN := Two(N2, N3);
    BV := Two(V1, V3);
    BN := Two(N1, N3);
    CV := Two(V2, V1);
    CN := Two(N2, N1);
    Tria(V1, N1, BV, BN, CV, CN, L);
    Tria(AV, AN, V2, N2, CV, CN, L);
    Tria(AV, AN, BV, BN, V3, N3, L);
  end;

var
  Index: Integer;
  V1, V2, V3, V4: Integer;
  N1, N2, N3, N4: Integer;
  P1, P2, P3, P4: RPoint;
  C1, C2, C3, C4: RPoint;
begin
  for Index := 1 to Obj.Faces do
    if Obj.GetFaceNormal(Index, V1, N1, V2, N2, V3, N3, V4, N4) then
      if Obj.GetVertex(V1, C1.X, C1.Y, C1.Z) and Obj.GetVertex(V2, C2.X, C2.Y,
        C2.Z) and Obj.GetVertex(V3, C3.X, C3.Y, C3.Z) and ((V4 = 0) or (Obj.GetVertex
        (V4, C4.X, C4.Y, C4.Z))) then
      begin
        PrimitiveBegin(GmlPrimitiveLinelist);
        P1 := Obj.GetNormal(N1);
        P2 := Obj.GetNormal(N2);
        P3 := Obj.GetNormal(N3);
        Tria(C1, P1, C2, P2, C3, P3, 0);
        if V4 <> 0 then
        begin
          P4 := Obj.GetNormal(N4);
          Tria(C1, P1, C4, P4, C3, P3, 0);
        end;
        PrimitiveEnd();
      end;
end;

procedure TGmlModel.ObjFaces(Obj: TObjModel; ColorNormal, ColorTexture: Boolean;
  Norms, Texts, Sides: Trilean; Alpha: Real);
var
  Index, Counter: Integer;
  V1, V2, V3, V4: Integer;
  N1, N2, N3, N4: Integer;
  T1, T2, T3, T4: Integer;
  P1, P2, P3, P4: RPoint;
  M1, M2, M3, M4: RPoint;
  L1, L2, L3, L4: RPoint;
  C1, C2, C3, C4: Integer;
  HaveNormal, HaveTexture, UseColor, HaveColor: Boolean;
begin
  UseColor := ColorNormal or ColorTexture;
  Counter := 0;
  PrimitiveBegin(GmlPrimitiveTrianglelist);
  for Index := 1 to Obj.Faces do
    if Obj.GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4,
      T4, N4) then
      if Obj.GetVertex(V1, P1) and Obj.GetVertex(V2, P2) and Obj.GetVertex(V3,
        P3) and ((V4 = 0) or (Obj.GetVertex(V4, P4))) then
      begin
        if Counter = 2048 then
        begin
          Counter := 0;
          PrimitiveEnd();
          PrimitiveBegin(GmlPrimitiveTrianglelist);
        end;
        Inc(Counter);
        L1 := Obj.GetNormal(N1);
        L2 := Obj.GetNormal(N2);
        L3 := Obj.GetNormal(N3);
        M1 := Obj.GetTexture(T1);
        M2 := Obj.GetTexture(T2);
        M3 := Obj.GetTexture(T3);
        C1 := Obj.GetVertexColor(V1);
        C2 := Obj.GetVertexColor(V2);
        C3 := Obj.GetVertexColor(V3);
        HaveColor := (C1 <> -1) and (C2 <> -1) and (C3 <> -1);
        if ColorNormal then
        begin
          if not ColorTexture then
          begin
            C1 := NormalColor(L1);
            C2 := NormalColor(L2);
            C3 := NormalColor(L3);
            HaveColor := (N1 <> 0) and (N2 <> 0) and (N3 <> 0);
          end;
        end
        else
        begin
          C1 := TextureColor(M1);
          C2 := TextureColor(M2);
          C3 := TextureColor(M3);
          HaveColor := (T1 <> 0) and (T2 <> 0) and (T3 <> 0);
        end;
        HaveNormal := (N1 <> 0) and (N2 <> 0) and (N3 <> 0);
        HaveTexture := (T1 <> 0) and (T2 <> 0) and (T3 <> 0);
        if TriCheck(Norms, HaveNormal) and TriCheck(Texts, HaveTexture) then
        begin

          if TriCheck(Sides, False) then
          begin
            if UseColor and HaveColor then
            begin
              VertexNormalTextureColor(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X,
                1 - M1.Y, C1, Alpha);
              VertexNormalTextureColor(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X,
                1 - M3.Y, C3, Alpha);
              VertexNormalTextureColor(P2.Y, P2.X, P2.Z, L2.Y, L2.X, L2.Z, M2.X,
                1 - M2.Y, C2, Alpha);
            end
            else
            begin
              VertexNormalTexture(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X, 1 - M1.Y);
              VertexNormalTexture(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X, 1 - M3.Y);
              VertexNormalTexture(P2.Y, P2.X, P2.Z, L2.Y, L2.X, L2.Z, M2.X, 1 - M2.Y);
            end;
          end;
          if TriCheck(Sides, True) then
          begin
            L1 := SModels3D.PointNeg(L1);
            L2 := SModels3D.PointNeg(L2);
            L3 := SModels3D.PointNeg(L3);
            if UseColor and HaveColor then
            begin
              VertexNormalTextureColor(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X,
                1 - M1.Y, C1, Alpha);
              VertexNormalTextureColor(P2.Y, P2.X, P2.Z, L2.Y, L2.X, L2.Z, M2.X,
                1 - M2.Y, C2, Alpha);
              VertexNormalTextureColor(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X,
                1 - M3.Y, C3, Alpha);
            end
            else
            begin
              VertexNormalTexture(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X, 1 - M1.Y);
              VertexNormalTexture(P2.Y, P2.X, P2.Z, L2.Y, L2.X, L2.Z, M2.X, 1 - M2.Y);
              VertexNormalTexture(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X, 1 - M3.Y);
            end;
            if V4 <> 0 then
            begin
              L1 := SModels3D.PointNeg(L1);
              L2 := SModels3D.PointNeg(L2);
              L3 := SModels3D.PointNeg(L3);
            end;
          end;

        end;
        if V4 <> 0 then
        begin
          L4 := Obj.GetNormal(N4);
          M4 := Obj.GetTexture(T4);
          C4 := Obj.GetVertexColor(V4);
          HaveColor := (C4 <> -1) and (C1 <> -1) and (C3 <> -1);
          if ColorNormal then
          begin
            if not ColorTexture then
            begin
              C4 := NormalColor(L4);
              HaveColor := (N4 <> 0) and (N1 <> 0) and (N3 <> 0);
            end;
          end
          else
          begin
            C4 := TextureColor(M4);
            HaveColor := (T4 <> 0) and (T1 <> 0) and (T3 <> 0);
          end;
          HaveNormal := (N4 <> 0) and (N1 <> 0) and (N3 <> 0);
          HaveTexture := (T4 <> 0) and (T1 <> 0) and (T3 <> 0);
          if TriCheck(Norms, HaveNormal) and TriCheck(Texts, HaveTexture) then
          begin
            if TriCheck(Sides, False) then
            begin
              if UseColor and HaveColor then
              begin
                VertexNormalTextureColor(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X,
                  1 - M1.Y, C1, Alpha);
                VertexNormalTextureColor(P4.Y, P4.X, P4.Z, L4.Y, L4.X, L4.Z, M4.X,
                  1 - M4.Y, C4, Alpha);
                VertexNormalTextureColor(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X,
                  1 - M3.Y, C3, Alpha);
              end
              else
              begin
                VertexNormalTexture(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X, 1 - M1.Y);
                VertexNormalTexture(P4.Y, P4.X, P4.Z, L4.Y, L4.X, L4.Z, M4.X, 1 - M4.Y);
                VertexNormalTexture(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X, 1 - M3.Y);
              end;
            end;
            if TriCheck(Sides, True) then
            begin
              L1 := SModels3D.PointNeg(L1);
              L4 := SModels3D.PointNeg(L4);
              L3 := SModels3D.PointNeg(L3);
              if UseColor and HaveColor then
              begin
                VertexNormalTextureColor(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X,
                  1 - M1.Y, C1, Alpha);
                VertexNormalTextureColor(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X,
                  1 - M3.Y, C3, Alpha);
                VertexNormalTextureColor(P4.Y, P4.X, P4.Z, L4.Y, L4.X, L4.Z, M4.X,
                  1 - M4.Y, C4, Alpha);
              end
              else
              begin
                VertexNormalTexture(P1.Y, P1.X, P1.Z, L1.Y, L1.X, L1.Z, M1.X, 1 - M1.Y);
                VertexNormalTexture(P3.Y, P3.X, P3.Z, L3.Y, L3.X, L3.Z, M3.X, 1 - M3.Y);
                VertexNormalTexture(P4.Y, P4.X, P4.Z, L4.Y, L4.X, L4.Z, M4.X, 1 - M4.Y);
              end;
            end;

          end;
        end;
      end;
  PrimitiveEnd();
end;

end.

