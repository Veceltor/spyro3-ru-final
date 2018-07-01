unit SHL_Models3D; // SpyroHackingLib is licensed under WTFPL

interface

uses
  SysUtils, Classes, SHL_Types;

type
  RPoint = record
    X, Y, Z: Real;
  end;

  RVertex = record
    X, Y, Z: Integer;
  end;

  RColor = record
    case Boolean of
      True:
        (Color: Integer);
      False:
        (R, G, B, A: Byte);
  end;

  RFace = record
    V, C, T, N: Integer;
  end;

  RQuad = record
    P1, P2, P3, P4: RFace;
  end;

  RTexture = record
    U, V: Integer;
  end;

  RTextureQuad = record
    U, V: array[1..4] of Real;
  end;

  RQuadData = array[1..4] of Integer;

  RVramTexture = record
    Texture: array[1..4] of RTexture;
    Pal: RTexture;
    Bpp, Alpha: Integer;
  end;

  RPolyVertex = record
    V, C, T, N: Integer;
  end;

  RPolyQuad = record
    Vertex, Normal, Color, Texture: RQuadData;
  end;

  RBox = record
    Corner, Size: RPoint;
  end;

type
  SModels3D = class(TObject)
  public
    class function Vertex2Point(Vertex: RVertex): RPoint;
    class function Same(const A, B: RPoint): Boolean; overload;
    class function PointSubs(const A, B: RPoint): RPoint;
    class function PointAdd(const A, B: RPoint): RPoint;
    class function PointNeg(const A: RPoint): RPoint;
    class function PointCross(const A, B: RPoint): RPoint;
    class function PointLen(const A: RPoint): Real;
    class function PointCoordMin(const A: RPoint): Real;
    class function PointCoordMax(const A: RPoint): Real;
    class function PointMult(const A: RPoint; B: Real): RPoint;
    class function PointDiv(const A: RPoint; B: Real): RPoint;
    class function PointNorm(const A: RPoint): RPoint;
    class function PointZero(): RPoint;
    class function PointScalar(const A, B: RPoint): Real;
    class function PointAngle(const A, B: RPoint): Real;
    class function PointMake(X, Y, Z: Real): RPoint;
    class procedure PointOut(const P: RPoint; out X, Y, Z: Real);
    class function PointAbs(const A: RPoint): RPoint;
    class function PointMean(const A, B: RPoint): RPoint;
  end;

implementation

uses
  Math;

class function SModels3D.Vertex2Point(Vertex: RVertex): RPoint;
begin
  Result.X := Vertex.X;
  Result.Y := Vertex.Y;
  Result.Z := Vertex.Z;
end;

class function SModels3D.Same(const A, B: RPoint): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y) and (A.Z = B.Z);
end;

class function SModels3D.PointSubs(const A, B: RPoint): RPoint;
begin
  Result.X := A.X - B.X;
  Result.Y := A.Y - B.Y;
  Result.Z := A.Z - B.Z;
end;

class function SModels3D.PointAdd(const A, B: RPoint): RPoint;
begin
  Result.X := A.X + B.X;
  Result.Y := A.Y + B.Y;
  Result.Z := A.Z + B.Z;
end;

class function SModels3D.PointNeg(const A: RPoint): RPoint;
begin
  Result.X := -A.X;
  Result.Y := -A.Y;
  Result.Z := -A.Z;
end;

class function SModels3D.PointCross(const A, B: RPoint): RPoint;
begin
  Result.X := A.Y * B.Z - A.Z * B.Y;
  Result.Y := A.Z * B.X - A.X * B.Z;
  Result.Z := A.X * B.Y - A.Y * B.X;
end;

class function SModels3D.PointLen(const A: RPoint): Real;
begin
  Result := Sqrt(A.X * A.X + A.Y * A.Y + A.Z * A.Z);
end;

class function SModels3D.PointCoordMin(const A: RPoint): Real;
begin
  Result := A.X;
  if A.Y < Result then
    Result := A.Y;
  if A.Z < Result then
    Result := A.Z;
end;

class function SModels3D.PointCoordMax(const A: RPoint): Real;
begin
  Result := A.X;
  if A.Y > Result then
    Result := A.Y;
  if A.Z > Result then
    Result := A.Z;
end;

class function SModels3D.PointMult(const A: RPoint; B: Real): RPoint;
begin
  Result.X := A.X * B;
  Result.Y := A.Y * B;
  Result.Z := A.Z * B;
end;

class function SModels3D.PointDiv(const A: RPoint; B: Real): RPoint;
begin
  if B = 0 then
    Result := PointZero()
  else
  begin
    Result.X := A.X / B;
    Result.Y := A.Y / B;
    Result.Z := A.Z / B;
  end;
end;

class function SModels3D.PointNorm(const A: RPoint): RPoint;
begin
  Result := PointDiv(A, PointLen(A));
end;

class function SModels3D.PointZero(): RPoint;
begin
  Result.X := 0;
  Result.Y := 0;
  Result.Z := 0;
end;

class function SModels3D.PointScalar(const A, B: RPoint): Real;
begin
  Result := A.X * B.X + A.Y * B.Y + A.Z * B.Z;
end;

class function SModels3D.PointAngle(const A, B: RPoint): Real;
begin
  Result := PointLen(A) * PointLen(B);
  if Result = 0 then
    Exit;
  begin
    Result := PointScalar(A, B) / Result;
    if Result > 1 then
      Result := 1
    else if Result < -1 then
      Result := -1;
    Result := ArcCos(Result);
  end;
end;

class function SModels3D.PointMake(X, Y, Z: Real): RPoint;
begin
  Result.X := X;
  Result.Y := Y;
  Result.Z := Z;
end;

class procedure SModels3D.PointOut(const P: RPoint; out X, Y, Z: Real);
begin
  X := P.X;
  Y := P.Y;
  Z := P.Z;
end;

class function SModels3D.PointAbs(const A: RPoint): RPoint;
begin
  if A.X < 0 then
    Result.X := -A.X
  else
    Result.X := A.X;
  if A.Y < 0 then
    Result.Y := -A.Y
  else
    Result.Y := A.Y;
  if A.Z < 0 then
    Result.Z := -A.Z
  else
    Result.Z := A.Z;
end;

class function SModels3D.PointMean(const A, B: RPoint): RPoint;
begin
  Result.X := (A.X + B.X) / 2;
  Result.Y := (A.Y + B.Y) / 2;
  Result.Z := (A.Z + B.Z) / 2;
end;

end.

