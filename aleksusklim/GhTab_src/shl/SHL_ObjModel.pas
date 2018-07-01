unit SHL_ObjModel; // SpyroHackingLib is licensed under WTFPL

interface

uses
  Math, SysUtils, SHL_Models3D, SHL_Files, SHL_Helpers, SHL_MemoryManager,
  SHL_Types;

type
  TObjModel = class(TObject)
    constructor Create();
    destructor Destroy(); override;
  public
    procedure Clear();
    function AddVertex(X, Y, Z: Real): Integer; overload;
    function AddVertex(Vertex: RPoint): Integer; overload;
    function AddVertex(X, Y, Z, W, V, U: Real): Integer; overload;
    function AddVertex(Vertex, Weight: RPoint): Integer; overload;
    function AddVertexColor(X, Y, Z: Real; R, G, B: Byte): Integer; overload;
    function AddVertexColor(Vertex: RPoint; Color: Integer): Integer; overload;
    function AddTexture(U, V, W: Real): Integer; overload;
    function AddTexture(Texture: RPoint): Integer; overload;
    function AddTextureColor(R, G, B: Byte): Integer; overload;
    function AddTextureColor(Color: Integer): Integer; overload;
    function AddNormal(I, J, K: Real): Integer; overload;
    function AddNormal(Normal: RPoint): Integer; overload;
    function AddFace(V1, V2, V3: Integer; V4: Integer = 0): Integer; overload;
    function AddFaceTexture(V1, T1, V2, T2, V3, T3: Integer; V4: Integer = 0; T4:
      Integer = 0): Integer;
    function AddFaceNormal(V1, N1, V2, N2, V3, N3: Integer; V4: Integer = 0; N4:
      Integer = 0): Integer;
    function AddFaceTextureNormal(V1, T1, N1, V2, T2, N2, V3, T3, N3: Integer;
      V4: Integer = 0; T4: Integer = 0; N4: Integer = 0): Integer;
    function AddFace(Poly: RQuad): Integer; overload;
    function AddQuad(Quad: RPolyQuad; UseColors: Boolean): Integer;
    function AddGroup(const Name: TextString = ''): Integer;
    procedure WriteTo(Filename: TextString; MaxPrecision: Integer = 15); overload;
    procedure WriteTo(Filename: WideString; MaxPrecision: Integer = 15); overload;
    function GetVertex(Index: Integer; out X, Y, Z, W, V, U: Real): Boolean; overload;
    function GetVertex(Index: Integer; out X, Y, Z: Real): Boolean; overload;
    function GetVertex(Index: Integer; out Vertex, Weight: RPoint): Boolean; overload;
    function GetVertex(Index: Integer; out Vertex: RPoint): Boolean; overload;
    function GetVertexColor(Index: Integer): Integer; overload;
    function GetVertexColor(Index: Integer; out R, G, B: Real): Boolean; overload;
    function GetVertex(Index: Integer): RPoint; overload;
    function GetTexture(Index: Integer; out U, V, W: Real): Boolean; overload;
    function GetTexture(Index: Integer): RPoint; overload;
    function GetTextureColor(Index: Integer; out R, G, B: Byte): Boolean; overload;
    function GetTextureColor(Index: Integer; out Color: Integer): Boolean; overload;
    function GetTextureColor(Index: Integer): Integer; overload;
    function GetNormal(Index: Integer; out I, J, K: Real): Boolean; overload;
    function GetNormal(Index: Integer): RPoint; overload;
    function GetFace(Index: Integer; out V1, V2, V3: Integer): Boolean; overload;
    function GetFace(Index: Integer; out V1, V2, V3, V4: Integer): Boolean; overload;
    function GetFaceTexture(Index: Integer; out V1, T1, V2, T2, V3, T3: Integer):
      Boolean; overload;
    function GetFaceTexture(Index: Integer; out V1, T1, V2, T2, V3, T3, V4, T4:
      Integer): Boolean; overload;
    function GetFaceNormal(Index: Integer; out V1, N1, V2, N2, V3, N3: Integer):
      Boolean; overload;
    function GetFaceNormal(Index: Integer; out V1, N1, V2, N2, V3, N3, V4, N4:
      Integer): Boolean; overload;
    function GetFaceTextureNormal(Index: Integer; out V1, T1, N1, V2, T2, N2, V3,
      T3, N3: Integer): Boolean; overload;
    function GetFaceTextureNormal(Index: Integer; out V1, T1, N1, V2, T2, N2, V3,
      T3, N3, V4, T4, N4: Integer): Boolean; overload;
    function GetFace(Index: Integer): RQuad; overload;
    function GetGroup(Index: Integer): Integer; overload;
    function GetGroupName(Index: Integer): TextString; overload;
    function GetGroup(Index: Integer; out Face: Integer): Boolean; overload;
    function GetGroup(Index: Integer; out Face: Integer; out Name: TextString):
      Boolean; overload;
    procedure GetGroup(Index: Integer; out Start, Finish: Integer); overload;
    function FaceHave(Index: Integer; out Texture, Normal, Quadro: Boolean): Boolean;
    procedure ReadFrom(Filename: TextString; DoClear: Boolean = True); overload;
    procedure ReadFrom(Filename: WideString; DoClear: Boolean = True); overload;
    procedure PrepareTexture(const TextureQuad: RTextureQuad; var Quad: RPolyQuad);
    procedure Optimize();
    procedure SortDepth(CamX, CamY, CamZ: Real; Ortho: Boolean); overload;
    procedure SortDepth(Cam: RPoint; Ortho: Boolean); overload;
    procedure FlatNormals();
    procedure SmoothNormals();
    procedure Assign(From: TObjModel; Group: Integer = 0);
    procedure ScaleVertex(Value: Real);
    procedure Center();
    procedure TextureToColor();
    procedure BoundBox(out Min, Max: RPoint);
    procedure SplitTriangles();
  private
    function NewLength(Size: Integer): Integer;
    function Negative(Value, Count: Integer): Integer;
  private
    FVertex: array of array[0..5] of Real;
    FTexture, FNormal: array of array[0..2] of Real;
    FFace: array of array[0..3, 0..2] of Integer;
    FGroup: array of record
      Index: Integer;
      Name: TExtString;
    end;
    FNextGroup: Boolean;
    FVertexCount, FTextureCount, FNormalCount, FFaceCount, FGroupCount: Integer;
  public
    property Vertexes: Integer read FVertexCount;
    property Textures: Integer read FTextureCount;
    property Normals: Integer read FNormalCount;
    property Faces: Integer read FFaceCount;
    property Groups: Integer read FGroupCount;
  end;

implementation

uses
  Classes;

constructor TObjModel.Create();
begin
  inherited Create();
  Clear();
end;

destructor TObjModel.Destroy();
begin
  Clear();
  inherited Destroy();
end;

procedure TObjModel.Clear();
begin
  FVertexCount := 0;
  FTextureCount := 0;
  FNormalCount := 0;
  FFaceCount := 0;
  FGroupCount := 0;
  SetLength(FVertex, 0);
  SetLength(FNormal, 0);
  SetLength(FTexture, 0);
  SetLength(FFace, 0);
  SetLength(FGroup, 0);
  FNextGroup := True;
end;

function TObjModel.NewLength(Size: Integer): Integer;
begin
  Result := 8 + Size * 2;
end;

function TObjModel.Negative(Value, Count: Integer): Integer;
begin
  if Value < 0 then
    Result := Count + Value + 1
  else
    Result := Value;
end;

function TObjModel.AddVertex(X, Y, Z, W, V, U: Real): Integer;
begin
  Inc(FVertexCount);
  Result := FVertexCount;
  if Length(FVertex) <= Result then
    SetLength(FVertex, NewLength(Result));
  FVertex[Result][0] := X;
  FVertex[Result][1] := Y;
  FVertex[Result][2] := Z;
  FVertex[Result][3] := W;
  FVertex[Result][4] := V;
  FVertex[Result][5] := U;
end;

function TObjModel.AddVertex(X, Y, Z: Real): Integer;
begin
  Result := AddVertex(X, Y, Z, NaN, NaN, NaN);
end;

function TObjModel.AddVertex(Vertex: RPoint): Integer;
begin
  Result := AddVertex(Vertex.X, Vertex.Y, Vertex.Z, NaN, NaN, NaN);
end;

function TObjModel.AddVertex(Vertex, Weight: RPoint): Integer;
begin
  Result := AddVertex(Vertex.X, Vertex.Y, Vertex.Z, Weight.X, Weight.Y, Weight.Z);
end;

function TObjModel.AddVertexColor(X, Y, Z: Real; R, G, B: Byte): Integer;
begin
  Result := AddVertex(X, Y, Z, R / 255, G / 255, B / 255);
end;

function TObjModel.AddVertexColor(Vertex: RPoint; Color: Integer): Integer;
begin
  Result := AddVertex(Vertex.X, Vertex.Y, Vertex.Z, Color, Color shr 8, Color shr 16);
end;

function TObjModel.AddTexture(U, V, W: Real): Integer;
begin
  Inc(FTextureCount);
  Result := FTextureCount;
  if Length(FTexture) <= Result then
    SetLength(FTexture, NewLength(Result));
  FTexture[Result][0] := U;
  FTexture[Result][1] := V;
  FTexture[Result][2] := W;
end;

function TObjModel.AddTexture(Texture: RPoint): Integer;
begin
  Result := AddTexture(Texture.X, Texture.Y, Texture.Z);
end;

function TObjModel.AddTextureColor(R, G, B: Byte): Integer;
begin
  Result := AddTexture(R / 255, G / 255, B / 255);
end;

function TObjModel.AddTextureColor(Color: Integer): Integer;
begin
  Result := AddTextureColor(Color, Color shr 8, Color shr 16);
end;

function TObjModel.AddNormal(I, J, K: Real): Integer;
begin
  Inc(FNormalCount);
  Result := FNormalCount;
  if Length(FNormal) <= Result then
    SetLength(FNormal, NewLength(Result));
  FNormal[Result][0] := I;
  FNormal[Result][1] := J;
  FNormal[Result][2] := K;
end;

function TObjModel.AddNormal(Normal: RPoint): Integer;
begin
  Result := AddNormal(Normal.X, Normal.Y, Normal.Z);
end;

function TObjModel.AddFace(V1, V2, V3: Integer; V4: Integer = 0): Integer;
begin
  Result := AddFaceTextureNormal(V1, 0, 0, V2, 0, 0, V3, 0, 0, V4, 0, 0);
end;

function TObjModel.AddFaceTexture(V1, T1, V2, T2, V3, T3: Integer; V4: Integer =
  0; T4: Integer = 0): Integer;
begin
  Result := AddFaceTextureNormal(V1, T1, 0, V2, T2, 0, V3, T3, 0, V4, T4, 0);
end;

function TObjModel.AddFaceNormal(V1, N1, V2, N2, V3, N3: Integer; V4: Integer =
  0; N4: Integer = 0): Integer;
begin
  Result := AddFaceTextureNormal(V1, 0, N1, V2, 0, N2, V3, 0, N3, V4, 0, N4);
end;

function TObjModel.AddFaceTextureNormal(V1, T1, N1, V2, T2, N2, V3, T3, N3:
  Integer; V4: Integer = 0; T4: Integer = 0; N4: Integer = 0): Integer;
begin
  if FNextGroup then
    AddGroup();
  Inc(FFaceCount);
  Result := FFaceCount;
  if Length(FFace) <= Result then
    SetLength(FFace, NewLength(Result));
  FFace[Result][0, 0] := Negative(V1, FVertexCount);
  FFace[Result][1, 0] := Negative(V2, FVertexCount);
  FFace[Result][2, 0] := Negative(V3, FVertexCount);
  FFace[Result][3, 0] := Negative(V4, FVertexCount);
  FFace[Result][0, 1] := Negative(T1, FTextureCount);
  FFace[Result][1, 1] := Negative(T2, FTextureCount);
  FFace[Result][2, 1] := Negative(T3, FTextureCount);
  FFace[Result][3, 1] := Negative(T4, FTextureCount);
  FFace[Result][0, 2] := Negative(N1, FNormalCount);
  FFace[Result][1, 2] := Negative(N2, FNormalCount);
  FFace[Result][2, 2] := Negative(N3, FNormalCount);
  FFace[Result][3, 2] := Negative(N4, FNormalCount);
end;

function TObjModel.AddFace(Poly: RQuad): Integer;
begin
  Result := AddFaceTextureNormal(Poly.P1.V, Poly.P1.T, Poly.P1.N, Poly.P2.V,
    Poly.P2.T, Poly.P2.N, Poly.P3.V, Poly.P3.T, Poly.P3.N, Poly.P4.V, Poly.P4.T,
    Poly.P4.N);
end;

function TObjModel.AddQuad(Quad: RPolyQuad; UseColors: Boolean): Integer;
begin
  if UseColors then
    Result := AddFaceTextureNormal(Quad.Vertex[1], Quad.Color[1], Quad.Normal[1],
      Quad.Vertex[2], Quad.Color[2], Quad.Normal[2], Quad.Vertex[3], Quad.Color[3],
      Quad.Normal[3], Quad.Vertex[4], Quad.Color[4], Quad.Normal[4])
  else
    Result := AddFaceTextureNormal(Quad.Vertex[1], Quad.Texture[1], Quad.Normal[1],
      Quad.Vertex[2], Quad.Texture[2], Quad.Normal[2], Quad.Vertex[3], Quad.Texture
      [3], Quad.Normal[3], Quad.Vertex[4], Quad.Texture[4], Quad.Normal[4]);
end;

function TObjModel.AddGroup(const Name: TextString = ''): Integer;
begin
  Inc(FGroupCount);
  Result := FGroupCount;
  if Length(FGroup) <= Result then
    SetLength(FGroup, NewLength(Result));
  FGroup[FGroupCount].Index := FFaceCount + 1;
  FGroup[FGroupCount].Name := Name;
  FNextGroup := False;
end;

procedure TObjModel.WriteTo(Filename: TextString; MaxPrecision: Integer = 15);
var
  Obj: Text;
  Index, Group: Integer;
  Settings: TFormatSettings;
  OldFileMode: Byte;
  Form: string;

  procedure PrintFloats(var Obj: Text; Form: string; Settings: TFormatSettings;
    Mode: string; Six: Boolean; const Data: array of Real);
  begin
    if Six then
      Writeln(Obj, Mode, ' ', FormatFloat(Form, Data[0], Settings), ' ',
        FormatFloat(Form, Data[1], Settings), ' ', FormatFloat(Form, Data[2],
        Settings), ' ', FormatFloat(Form, Data[3], Settings), ' ', FormatFloat(Form,
        Data[4], Settings), ' ', FormatFloat(Form, Data[5], Settings))
    else
      Writeln(Obj, Mode, ' ', FormatFloat(Form, Data[0], Settings), ' ',
        FormatFloat(Form, Data[1], Settings), ' ', FormatFloat(Form, Data[2], Settings));
  end;

  function StrIf(Value: string; Condition: Boolean): string;
  begin
    if Condition then
      Result := Value
    else
      Result := '';
  end;

begin
  if MaxPrecision < 0 then
    MaxPrecision := 15;
  Form := '0.' + StringOfChar('#', MaxPrecision);
  ZeroMem(@Settings, SizeOf(Settings));
  Settings.DecimalSeparator := '.';
  OldFileMode := FileMode;
  FileMode := 2;
  AssignFile(Obj, Filename);
  Rewrite(Obj);
  for Index := 1 to FVertexCount do
    PrintFloats(Obj, Form, Settings, 'v', not IsNaN(FVertex[Index][3]), [FVertex
      [Index][0], FVertex[Index][1], FVertex[Index][2], FVertex[Index][3],
      FVertex[Index][4], FVertex[Index][5]]);
  for Index := 1 to FTextureCount do
    PrintFloats(Obj, Form, Settings, 'vt', False, [FTexture[Index][0], FTexture[Index]
      [1], FTexture[Index][2]]);
  for Index := 1 to FNormalCount do
    PrintFloats(Obj, Form, Settings, 'vn', False, [FNormal[Index][0], FNormal[Index]
      [1], FNormal[Index][2]]);
  Group := 1;
  for Index := 1 to FFaceCount do
  begin
    if (Group <= FGroupCount) and (FGroup[Group].Index = Index) then
    begin
      Writeln(Obj, 'g ', FGroup[Group].Name);
      Inc(Group);
    end;
    if FFace[Index][0, 1] <> 0 then
      if FFace[Index][0, 2] <> 0 then
        Writeln(Obj, Format('f %d/%d/%d %d/%d/%d %d/%d/%d' + StrIf(' %d/%d/%d',
          FFace[Index][3, 0] <> 0), [FFace[Index][0, 0], FFace[Index][0, 1],
          FFace[Index][0, 2], FFace[Index][1, 0], FFace[Index][1, 1], FFace[Index]
          [1, 2], FFace[Index][2, 0], FFace[Index][2, 1], FFace[Index][2, 2],
          FFace[Index][3, 0], FFace[Index][3, 1], FFace[Index][3, 2]], Settings))
      else
        Writeln(Obj, Format('f %d/%d %d/%d %d/%d' + StrIf(' %d/%d', FFace[Index]
          [3, 0] <> 0), [FFace[Index][0, 0], FFace[Index][0, 1], FFace[Index][1,
          0], FFace[Index][1, 1], FFace[Index][2, 0], FFace[Index][2, 1], FFace[Index]
          [3, 0], FFace[Index][3, 1]], Settings))
    else if FFace[Index][0, 2] <> 0 then
      Writeln(Obj, Format('f %d//%d %d//%d %d//%d' + StrIf(' %d//%d', FFace[Index]
        [3, 0] <> 0), [FFace[Index][0, 0], FFace[Index][0, 2], FFace[Index][1, 0],
        FFace[Index][1, 2], FFace[Index][2, 0], FFace[Index][2, 2], FFace[Index]
        [3, 0], FFace[Index][3, 2]], Settings))
    else
      Writeln(Obj, Format('f %d %d %d' + StrIf(' %d', FFace[Index][3, 0] <> 0),
        [FFace[Index][0, 0], FFace[Index][1, 0], FFace[Index][2, 0], FFace[Index]
        [3, 0]], Settings));
  end;
  Close(Obj);
  FileMode := OldFileMode;
end;

procedure TObjModel.WriteTo(Filename: WideString; MaxPrecision: Integer = 15);
var
  Old: RHandles;
begin
  if SFiles.RedirectFile(Old, '', Filename, '') then
  try
    WriteTo(TextString(''), MaxPrecision);
  finally
    SFiles.RedirectRestore(Old);
  end;
end;

function TObjModel.GetVertex(Index: Integer; out X, Y, Z, W, V, U: Real): Boolean;
begin
  if (Index < 1) or (Index > FVertexCount) then
  begin
    Result := False;
    Exit
  end;
  Result := True;
  X := FVertex[Index][0];
  Y := FVertex[Index][1];
  Z := FVertex[Index][2];
  W := FVertex[Index][3];
  V := FVertex[Index][4];
  U := FVertex[Index][5];
end;

function TObjModel.GetVertex(Index: Integer; out X, Y, Z: Real): Boolean;
var
  W, V, U: Real;
begin
  Result := GetVertex(Index, X, Y, Z, W, V, U);
end;

function TObjModel.GetVertex(Index: Integer; out Vertex, Weight: RPoint): Boolean;
begin
  Result := GetVertex(Index, Vertex.X, Vertex.Y, Vertex.Z, Weight.X, Weight.Y, Weight.Z);
end;

function TObjModel.GetVertex(Index: Integer; out Vertex: RPoint): Boolean;
var
  X, Y, Z: Real;
begin
  Result := GetVertex(Index, Vertex.X, Vertex.Y, Vertex.Z, X, Y, Z);
end;

function TObjModel.GetVertexColor(Index: Integer): Integer;
var
  R, G, B: Real;
begin
  if GetVertexColor(Index, R, G, B) then
  begin
    if R < 0 then
      R := 0
    else if R > 255 then
      R := 255;
    if G < 0 then
      G := 0
    else if G > 255 then
      G := 255;
    if B < 0 then
      B := 0
    else if B > 255 then
      B := 255;
    Result := Round(R) or (Round(G) shl 8) or (Round(B) shl 16);
  end
  else
    Result := -1;
end;

function TObjModel.GetVertexColor(Index: Integer; out R, G, B: Real): Boolean;
var
  X, Y, Z: Real;
begin
  Result := GetVertex(Index, X, Y, Z, R, G, B);
  if Result then
  begin
    if not IsNan(R) then
    begin
      R := R * 255;
      G := G * 255;
      B := B * 255;
    end
    else
      Result := False;
  end;
end;

function TObjModel.GetVertex(Index: Integer): RPoint;
begin
  if not GetVertex(Index, Result.X, Result.Y, Result.Z) then
  begin
    Result.X := 0;
    Result.Y := 0;
    Result.Z := 0;
  end;
end;

function TObjModel.GetTexture(Index: Integer; out U, V, W: Real): Boolean;
begin
  if (Index < 1) or (Index > FTextureCount) then
  begin
    Result := False;
    Exit
  end;
  Result := True;
  U := FTexture[Index][0];
  V := FTexture[Index][1];
  W := FTexture[Index][2];
end;

function TObjModel.GetTexture(Index: Integer): RPoint;
begin
  if not GetTexture(Index, Result.X, Result.Y, Result.Z) then
  begin
    Result.X := 0;
    Result.Y := 0;
    Result.Z := 0;
  end;
end;

function TObjModel.GetTextureColor(Index: Integer; out R, G, B: Byte): Boolean;
var
  U, V, W: Real;
begin
  Result := GetTexture(Index, U, V, W);
  R := Round(U * 255);
  G := Round(V * 255);
  B := Round(W * 255);
end;

function TObjModel.GetTextureColor(Index: Integer; out Color: Integer): Boolean;
var
  R, G, B: Byte;
begin
  Result := GetTextureColor(Index, R, G, B);
  Color := R or (G shl 8) or (B shl 16);
end;

function TObjModel.GetTextureColor(Index: Integer): Integer;
begin
  if not GetTextureColor(Index, Result) then
    Result := 0;
end;

function TObjModel.GetNormal(Index: Integer; out I, J, K: Real): Boolean;
begin
  if (Index < 1) or (Index > FNormalCount) then
  begin
    Result := False;
    Exit
  end;
  Result := True;
  I := FNormal[Index][0];
  J := FNormal[Index][1];
  K := FNormal[Index][2];
end;

function TObjModel.GetNormal(Index: Integer): RPoint;
begin
  if not GetNormal(Index, Result.X, Result.Y, Result.Z) then
  begin
    Result.X := 0;
    Result.Y := 0;
    Result.Z := 0;
  end;
end;

function TObjModel.GetFace(Index: Integer; out V1, V2, V3: Integer): Boolean;
var
  T1, N1, T2, N2, T3, N3, V4, T4, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFace(Index: Integer; out V1, V2, V3, V4: Integer): Boolean;
var
  T1, N1, T2, N2, T3, N3, T4, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceTexture(Index: Integer; out V1, T1, V2, T2, V3, T3:
  Integer): Boolean;
var
  N1, N2, N3, V4, T4, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceTexture(Index: Integer; out V1, T1, V2, T2, V3, T3, V4,
  T4: Integer): Boolean;
var
  N1, N2, N3, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceNormal(Index: Integer; out V1, N1, V2, N2, V3, N3:
  Integer): Boolean;
var
  T1, T2, T3, V4, N4, T4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceNormal(Index: Integer; out V1, N1, V2, N2, V3, N3, V4,
  N4: Integer): Boolean;
var
  T1, T2, T3, T4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceTextureNormal(Index: Integer; out V1, T1, N1, V2, T2,
  N2, V3, T3, N3: Integer): Boolean;
var
  V4, T4, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
end;

function TObjModel.GetFaceTextureNormal(Index: Integer; out V1, T1, N1, V2, T2,
  N2, V3, T3, N3, V4, T4, N4: Integer): Boolean;
begin
  if (Index < 1) or (Index > FFaceCount) then
  begin
    Result := False;
    Exit
  end;
  Result := True;
  V1 := FFace[Index][0, 0];
  V2 := FFace[Index][1, 0];
  V3 := FFace[Index][2, 0];
  V4 := FFace[Index][3, 0];
  T1 := FFace[Index][0, 1];
  T2 := FFace[Index][1, 1];
  T3 := FFace[Index][2, 1];
  T4 := FFace[Index][3, 1];
  N1 := FFace[Index][0, 2];
  N2 := FFace[Index][1, 2];
  N3 := FFace[Index][2, 2];
  N4 := FFace[Index][3, 2];
end;

function TObjModel.GetFace(Index: Integer): RQuad;
begin
  if not GetFaceTextureNormal(Index, Result.P1.V, Result.P1.T, Result.P1.N,
    Result.P2.V, Result.P2.T, Result.P2.N, Result.P3.V, Result.P3.T, Result.P3.N,
    Result.P4.V, Result.P4.T, Result.P4.N) then
    FillChar(Result, SizeOf(Result), #0);
end;

function TObjModel.GetGroup(Index: Integer): Integer;
begin
  if (Index < 1) or (Index > FGroupCount) then
    Result := 0
  else
    Result := FGroup[Index].Index;
end;

function TObjModel.GetGroupName(Index: Integer): TextString;
begin
  if (Index < 1) or (Index > FGroupCount) then
    Result := ''
  else
    Result := FGroup[Index].Name;
end;

function TObjModel.GetGroup(Index: Integer; out Face: Integer): Boolean;
begin
  if (Index >= 1) and (Index <= FGroupCount) then
  begin
    Result := True;
    Face := FGroup[Index].Index;
  end
  else
    Result := False;
end;

function TObjModel.GetGroup(Index: Integer; out Face: Integer; out Name:
  TextString): Boolean;
begin
  if (Index >= 1) and (Index <= FGroupCount) then
  begin
    Result := True;
    Face := FGroup[Index].Index;
    Name := FGroup[Index].Name;
  end
  else
    Result := False;
end;

procedure TObjModel.GetGroup(Index: Integer; out Start, Finish: Integer);
begin
  Start := 0;
  Finish := 0;
  if (Index < 0) or (Index > FGroupCount) then
    Exit;
  Finish := FFaceCount;
  if Index = 0 then
    Exit;
  Start := FGroup[Index].Index;
  if Index = FGroupCount then
    Exit;
  Finish := FGroup[Index + 1].Index - 1;
end;

function TObjModel.FaceHave(Index: Integer; out Texture, Normal, Quadro: Boolean):
  Boolean;
var
  V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4: Integer;
begin
  Result := GetFaceTextureNormal(Index, V1, T1, N1, V2, T2, N2, V3, T3, N3, V4, T4, N4);
  Texture := T1 <> 0;
  Normal := N1 <> 0;
  Quadro := V4 <> 0;
end;

procedure TObjModel.ReadFrom(Filename: TextString; DoClear: Boolean = True);
var
  OldVertex, OldTexture, OldNormal: Integer;
  Obj: Text;
  OldFileMode: Byte;
  Line, Orig: TextString;
  Cur: PTextChar;
  Loop, Count, Len: Integer;
  Tokens: array[0..7] of PTextChar;
  Got: Boolean;
  Format: TFormatSettings;

  function Take(Index: Integer; Def: Real): Real;
  begin
    if Index < Count then
      Result := StrToFloatDef(TextString(Tokens[Index]), Def, Format)
    else
      Result := Def;
  end;

  function Poly(Index, Token: Integer): Integer;
  var
    Own: string;
    Value, Last: Integer;
  begin
    if Index >= Count then
    begin
      Result := 0;
      Exit;
    end;
    if Token = 1 then
    begin
      Value := OldVertex;
      Last := FVertexCount;
    end
    else if Token = 2 then
    begin
      Value := OldTexture;
      Last := FTextureCount;
    end
    else if Token = 3 then
    begin
      Value := OldNormal;
      Last := FNormalCount;
    end
    else
    begin
      Result := 0;
      Exit;
    end;
    Own := TextString(Tokens[Index]);
    for Index := 1 to Length(Own) do
      if Own[Index] = '/' then
      begin
        Own[Index] := ' ';
        Dec(Token);
      end
      else if Token <> 1 then
        Own[Index] := ' ';
    Result := StrToIntDef(Trim(Own), 0);
    if Result > 0 then
      if Result > Last - Value then
        Result := 0
      else
        Inc(Result, Value)
    else if Result < 0 then
      if Result < Value - Last then
        Result := 0;
  end;

begin
  if DoClear then
    Clear();
  FNextGroup := True;
  Inits(Tokens);
  OldVertex := FVertexCount;
  OldTexture := FTextureCount;
  OldNormal := FNormalCount;
  OldFileMode := FileMode;
  ZeroMem(@Format, SizeOf(Format));
  Format.DecimalSeparator := '.';
  FileMode := 0;
  AssignFile(Obj, Filename);
  Reset(Obj);
  while not Eof(Obj) do
  begin
    Readln(Obj, Orig);
    Orig := Trim(Orig);
    Line := LowerCase(Orig);
    UniqueString(string(Line));
    Len := Length(Line);
    Cur := Cast(Line);
    Got := False;
    Count := 0;
    for Loop := 1 to Len do
    begin
      if not (Cur^ in ['0'..'9', '.', ',', '-', '+', 'a'..'z', 'A'..'Z', '/']) then
      begin
        Cur^ := #0;
        Got := False;
      end
      else if not Got then
      begin
        if Cur^ = ',' then
          Cur^ := '.';
        Got := True;
        Tokens[Count] := Cur;
        Inc(Count);
        if Count > 7 then
          Break;
      end;
      Inc(Cur);
    end;
    if Count < 2 then
      Continue;
    if StrComp(Tokens[0], Cast('v'#0)) = 0 then
      AddVertex(Take(1, 0), Take(2, 0), Take(3, 0), Take(4, 0), Take(5, 0), Take(6, 0))
    else if StrComp(Tokens[0], Cast('vt'#0)) = 0 then
      AddTexture(Take(1, 0), Take(2, 0), Take(3, 0))
    else if StrComp(Tokens[0], Cast('vn'#0)) = 0 then
      AddNormal(Take(1, 0), Take(2, 0), Take(3, 0))
    else if StrComp(Tokens[0], Cast('f'#0)) = 0 then
    begin
      AddFaceTextureNormal(Poly(1, 1), Poly(1, 2), Poly(1, 3), Poly(2, 1), Poly(2,
        2), Poly(2, 3), Poly(3, 1), Poly(3, 2), Poly(3, 3), Poly(4, 1), Poly(4,
        2), Poly(4, 3));
    end
    else if StrComp(Tokens[0], Cast('g'#0)) = 0 then
    begin
      Delete(Orig, 1, 1);
      AddGroup(Trim(Orig));
    end;
  end;
  Close(Obj);
  FileMode := OldFileMode;
end;

procedure TObjModel.ReadFrom(Filename: WideString; DoClear: Boolean = True);
var
  Old: RHandles;
begin
  if SFiles.RedirectFile(Old, Filename, '', '') then
  try
    ReadFrom(TextString(''), DoClear);
  finally
    SFiles.RedirectRestore(Old);
  end;
end;

procedure TObjModel.PrepareTexture(const TextureQuad: RTextureQuad; var Quad: RPolyQuad);
var
  Index: Integer;
begin
  for Index := 1 to 4 do
    AddTexture(TextureQuad.U[Index], TextureQuad.V[Index], 0);
  for Index := 1 to 4 do
    Quad.Texture[Index] := Index - 5;
end;

var
  Me: TObjModel;

function SortByVertex(A, B: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  with Me do
    for I := 0 to 5 do
    begin
      if Me.FVertex[A][I] < Me.FVertex[B][I] then
      begin
        Result := -1;
        Exit;
      end;
      if Me.FVertex[A][I] > Me.FVertex[B][I] then
      begin
        Result := 1;
        Exit;
      end;
    end;
end;

function SortByTexture(A, B: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  with Me do
    for I := 0 to 2 do
    begin
      if Me.FTexture[A][I] < Me.FTexture[B][I] then
      begin
        Result := -1;
        Exit;
      end;
      if Me.FTexture[A][I] > Me.FTexture[B][I] then
      begin
        Result := 1;
        Exit;
      end;
    end;
end;

function SortByNormal(A, B: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  with Me do
    for I := 0 to 2 do
    begin
      if Me.FNormal[A][I] < Me.FNormal[B][I] then
      begin
        Result := -1;
        Exit;
      end;
      if Me.FNormal[A][I] > Me.FNormal[B][I] then
      begin
        Result := 1;
        Exit;
      end;
    end;
end;

procedure TObjModel.Optimize();
var
  Sorter: TIntegerList;
  Reverse: array of Integer;

  procedure Proc(What: Integer; var Size: Integer; Func: TIntegerListSortCompare);

    function Arr(Index: Integer): Pointer;
    begin
      case What of
        0:
          Result := @FVertex[Index];
        1:
          Result := @FTexture[Index];
        2:
          Result := @FNormal[Index];
      else
        Result := nil;
      end;
    end;

  var
    Index, Temp, Count: Integer;
    Len: Integer;
  begin
    if Size < 1 then
      Exit;
    case What of
      0:
        Len := SizeOf(FVertex[0]);
      1:
        Len := SizeOf(FTexture[0]);
      2:
        Len := SizeOf(FNormal[0]);
    else
      Exit;
    end;
    Sorter.Count := Size;
    for Index := 1 to Size do
      Sorter[Index - 1] := Index;
    Sorter.Sort(Func);
    for Index := 1 to Size do
      Reverse[Sorter[Index - 1]] := Index;
    for Index := 1 to FFaceCount do
      for Temp := 0 to 3 do
        if FFace[Index][Temp, What] <> 0 then
          FFace[Index][Temp, What] := Reverse[FFace[Index][Temp, What]];
    for Index := 1 to Size do
      while Reverse[Index] <> Index do
      begin
        ExchangeDwords(Arr(Reverse[Index]), Arr(Index), Len);
        ExchangeInteger(Reverse[Index], Reverse[Reverse[Index]]);
      end;
    Count := 0;
    for Index := 1 to Size do
    begin
      if (Index = 1) or not CompareMem(Arr(Index), Arr(Index - 1), Len) then
        Inc(Count);
      Reverse[Index] := Count;
      if Count <> Index then
        CopyMem(Arr(Index), Arr(Count), Len);
    end;
    for Index := 1 to FFaceCount do
      for Temp := 0 to 3 do
        if FFace[Index][Temp, What] <> 0 then
          FFace[Index][Temp, What] := Reverse[FFace[Index][Temp, What]];
    Size := Count;
  end;

var
  Max: Integer;
begin
  Sorter := TIntegerList.Create();
  Me := Self;
  Max := FVertexCount;
  if FTextureCount > Max then
    Max := FTextureCount;
  if FNormalCount > Max then
    Max := FNormalCount;
  SetLength(Reverse, Max + 1);
  Proc(1, FTextureCount, SortByTexture);
  Proc(2, FNormalCount, SortByNormal);
  Proc(0, FVertexCount, SortByVertex);
  Sorter.Free();
end;

var
  Dist: array of Real;

function SortByDist(A, B: Integer): Integer;
begin
  if Dist[A] < Dist[B] then
    Result := 1
  else if Dist[A] > Dist[B] then
    Result := -1
  else
    Result := 0;
end;

procedure TObjModel.SortDepth(CamX, CamY, CamZ: Real; Ortho: Boolean);
var
  Sorter: TIntegerList;
  Reverse: array of Integer;
  Index: Integer;
  V1, V2, V3, V4: RPoint;
  X, Y, Z: Real;
  Cam: RPoint;
begin
  if Ortho then
    Cam := SModels3D.PointNorm(SModels3D.PointMake(CamX, CamY, CamZ));
  Sorter := TIntegerList.Create();
  Me := Self;
  SetLength(Dist, FFaceCount + 1);
  Sorter.Count := FFaceCount;
  for Index := 1 to FFaceCount do
  begin
    Sorter[Index - 1] := Index;
    V1 := GetVertex(FFace[Index][0, 0]);
    V2 := GetVertex(FFace[Index][1, 0]);
    V3 := GetVertex(FFace[Index][2, 0]);
    X := V1.X + V2.X + V3.X;
    Y := V1.Y + V2.Y + V3.Y;
    Z := V1.Z + V2.Z + V3.Z;
    if FFace[Index][3, 0] <> 0 then
    begin
      V4 := GetVertex(FFace[Index][3, 0]);
      X := (X + V4.X) / 4;
      Y := (Y + V4.Y) / 4;
      Z := (Z + V4.Z) / 4;
    end
    else
    begin
      X := X / 3;
      Y := Y / 3;
      Z := Z / 3;
    end;
    if Ortho then
      Dist[Index] := X * Cam.X + Y * Cam.Y + Z * Cam.Z
    else
    begin
      X := X - CamX;
      Y := Y - CamY;
      Z := Z - CamZ;
      Dist[Index] := X * X + Y * Y + Z * Z;
    end;
  end;
  Sorter.Sort(SortByDist);
  SetLength(Dist, 0);
  SetLength(Reverse, FFaceCount + 1);
  for Index := 1 to FFaceCount do
    Reverse[Sorter[Index - 1]] := Index;
  for Index := 1 to FFaceCount do
    while Reverse[Index] <> Index do
    begin
      ExchangeDwords(@FFace[Reverse[Index]], @FFace[Index], SizeOf(FFace[0]));
      ExchangeInteger(Reverse[Index], Reverse[Reverse[Index]]);
    end;
  Sorter.Free();
end;

procedure TObjModel.SortDepth(Cam: RPoint; Ortho: Boolean);
begin
  SortDepth(Cam.X, Cam.Y, Cam.Z, Ortho);
end;

procedure TObjModel.FlatNormals();

  function Flat(Index: Integer): RPoint;
  var
    N1, N2, N3, N4: RPoint;
  begin
    N1 := GetVertex(FFace[Index][0, 0]);
    N2 := GetVertex(FFace[Index][1, 0]);
    N3 := GetVertex(FFace[Index][2, 0]);
    N4 := GetVertex(FFace[Index][3, 0]);
    with SModels3D do
      if FFace[Index][3, 0] = 0 then
        Result := PointNorm(PointCross(PointSubs(N3, N2), PointSubs(N1, N2)))
      else
        Result := PointNorm(PointAdd(PointCross(PointSubs(N3, N2), PointSubs(N1,
          N2)), PointNorm(PointCross(PointSubs(N1, N4), PointSubs(N3, N4)))));
  end;

var
  Index: Integer;
begin
  FNormalCount := 0;
  with SModels3D do
    for Index := 1 to FFaceCount do
    begin
      FFace[Index][0, 2] := Index;
      FFace[Index][1, 2] := Index;
      FFace[Index][2, 2] := Index;
      if FFace[Index][3, 0] = 0 then
        FFace[Index][3, 2] := 0
      else
        FFace[Index][3, 2] := Index;
      AddNormal(Flat(Index));
    end;
end;

procedure TObjModel.SmoothNormals();

  procedure Smooth(Index: Integer);
  var
    N1, N2, N3, N4, Point: RPoint;
    A1, A2, A3, A4: Real;
    V1, V2, V3, V4: Integer;
  begin
    with SModels3D do
    begin
      V1 := FFace[Index][0, 2];
      V2 := FFace[Index][1, 2];
      V3 := FFace[Index][2, 2];
      V4 := FFace[Index][3, 2];
      N1 := GetVertex(FFace[Index][0, 0]);
      N2 := GetVertex(FFace[Index][1, 0]);
      N3 := GetVertex(FFace[Index][2, 0]);
      Point := PointNorm(PointCross(PointSubs(N3, N2), PointSubs(N1, N2)));
      A1 := PointAngle(PointSubs(N2, N1), PointSubs(N3, N1));
      A2 := PointAngle(PointSubs(N3, N2), PointSubs(N1, N2));
      A3 := PointAngle(PointSubs(N1, N3), PointSubs(N2, N3));
      FNormal[V1][0] := FNormal[V1][0] + Point.X * A1;
      FNormal[V1][1] := FNormal[V1][1] + Point.Y * A1;
      FNormal[V1][2] := FNormal[V1][2] + Point.Z * A1;
      FNormal[V2][0] := FNormal[V2][0] + Point.X * A2;
      FNormal[V2][1] := FNormal[V2][1] + Point.Y * A2;
      FNormal[V2][2] := FNormal[V2][2] + Point.Z * A2;
      FNormal[V3][0] := FNormal[V3][0] + Point.X * A3;
      FNormal[V3][1] := FNormal[V3][1] + Point.Y * A3;
      FNormal[V3][2] := FNormal[V3][2] + Point.Z * A3;
      if FFace[Index][3, 0] <> 0 then
      begin
        N4 := GetVertex(FFace[Index][3, 0]);
        Point := PointNorm(PointCross(PointSubs(N1, N4), PointSubs(N3, N4)));
        A3 := PointAngle(PointSubs(N4, N3), PointSubs(N1, N3));
        A4 := PointAngle(PointSubs(N1, N4), PointSubs(N3, N4));
        A1 := PointAngle(PointSubs(N3, N1), PointSubs(N4, N1));
        FNormal[V3][0] := FNormal[V3][0] + Point.X * A3;
        FNormal[V3][1] := FNormal[V3][1] + Point.Y * A3;
        FNormal[V3][2] := FNormal[V3][2] + Point.Z * A3;
        FNormal[V4][0] := FNormal[V4][0] + Point.X * A4;
        FNormal[V4][1] := FNormal[V4][1] + Point.Y * A4;
        FNormal[V4][2] := FNormal[V4][2] + Point.Z * A4;
        FNormal[V1][0] := FNormal[V1][0] + Point.X * A1;
        FNormal[V1][1] := FNormal[V1][1] + Point.Y * A1;
        FNormal[V1][2] := FNormal[V1][2] + Point.Z * A1;
      end;
    end;
  end;

var
  Index, Current, Vertex, Me, G: Integer;
  VertStack: TBackStack;
  FaceStack: TFastStack;
  VertFace: array of PInteger;
  FaceTake: array of Boolean;
  VertNorm: array of Integer;
  FirstNormal: Integer;
  Used: PInteger;

  function Connected(A, B: Integer): Boolean;
  var
    I, J, X, Y, N, T: Integer;
    C: array[0..3] of Integer;
  begin
    G := 0;
    Result := False;
    if FFace[A][3, 0] = 0 then
      X := 2
    else
      X := 3;
    if FFace[B][3, 0] = 0 then
      Y := 2
    else
      Y := 3;
    for I := 0 to X do
    begin
      C[I] := -1;
      for J := 0 to Y do
        if FFace[A][I, 0] = FFace[B][J, 0] then
        begin
          if C[I] <> -1 then
            Exit;
          C[I] := J;
        end;
    end;
    for I := 0 to X do
      if C[I] <> -1 then
      begin
        if I = X then
          N := 0
        else
          N := I + 1;
        J := C[I];
        if J = 0 then
          T := Y
        else
          T := J - 1;
        if C[N] <> -1 then
        begin
          if C[N] = T then
          begin
            Result := True;
            Inc(G);
            if G > 2 then
            begin
              Result := False;
              Exit;
            end;
          end
          else
          begin
            Result := False;
            Exit;
          end;
        end;
      end;
  end;

begin
  with SModels3D do
  begin
    VertStack := TBackStack.Create(SizeOf(Integer));
    FaceStack := TFastStack.Create(SizeOf(Integer));
    SetLength(VertFace, FVertexCount + 1);
    ZeroMem(@VertFace[0], SizeOf(VertFace[0]) * Length(VertFace));
    SetLength(FaceTake, FFaceCount + 1);
    ZeroMem(@FaceTake[0], SizeOf(FaceTake[0]) * Length(FaceTake));
    SetLength(VertNorm, FVertexCount + 1);
    ZeroMem(@VertNorm[0], SizeOf(VertNorm[0]) * Length(VertNorm));
    for Index := 1 to FFaceCount do
      for Vertex := 0 to 3 do
      begin
        Current := FFace[Index][Vertex, 0];
        if Current = 0 then
          Break;
        VertFace[Current] := VertStack.NewElem(VertFace[Current]);
        VertFace[Current]^ := Index;
      end;
    FNormalCount := 0;
    for Index := 1 to FFaceCount do
      if not FaceTake[Index] then
      begin
        FirstNormal := FNormalCount;
        PInteger(FaceStack.Push())^ := Index;
        while not FaceStack.Empty() do
        begin
          Current := PInteger(FaceStack.Pop())^;
          FaceTake[Current] := True;
          for Vertex := 0 to 3 do
            if FFace[Current][Vertex, 0] = 0 then
              Break
            else
            begin
              Me := FFace[Current][Vertex, 0];
              if VertNorm[Me] <= FirstNormal then
                VertNorm[Me] := AddNormal(0, 0, 0);
              FFace[Current][Vertex, 2] := VertNorm[Me];
              Used := VertFace[Me];
              while Used <> nil do
              begin
                if not FaceTake[Used^] and Connected(Current, Used^) then
                begin
                  PInteger(FaceStack.Push())^ := Used^;
                end;
                Used := VertStack.Next(Used);
              end;
            end;
        end;
      end;
    for Index := 1 to FFaceCount do
      Smooth(Index);
    for Index := 1 to FNormalCount do
      PointOut(PointNorm(PointMake(FNormal[Index][0], FNormal[Index][1], FNormal
        [Index][2])), FNormal[Index][0], FNormal[Index][1], FNormal[Index][2]);
  end;
  VertStack.Free();
  FaceStack.Free();
end;

procedure TObjModel.Assign(From: TObjModel; Group: Integer = 0);
var
  Start, Finish, Count: Integer;
  Search: array of Integer;

  procedure Proc(What: Integer; Size: Integer);

    procedure Cop(A: Integer; var Count: Integer);
    begin
      Inc(Count);
      Search[A] := 0;
      case What of
        0:
          FVertex[Count] := From.FVertex[A];
        1:
          FTexture[Count] := From.FTexture[A];
        2:
          FNormal[Count] := From.FNormal[A];
      end;
    end;

  var
    Index, Count, Ordinal: Integer;
    A1, A2, A3, A4: Integer;
  begin
//    if Size < 1 then
//      Exit;
    SetLength(Search, Size + 1);
    ZeroMem(@Search[0], SizeOf(Search[0]) * (Size + 1));
    Count := 0;
    Ordinal := 0;
    for Index := Start to Finish do
    begin
      Inc(Ordinal);
      A1 := From.FFace[Index][0, What];
      A2 := From.FFace[Index][1, What];
      A3 := From.FFace[Index][2, What];
      A4 := From.FFace[Index][3, What];
      if (A1 <> 0) and (Search[A1] = 0) then
      begin
        Inc(Count);
        Search[A1] := Count;
      end;
      if (A2 <> 0) and (Search[A2] = 0) then
      begin
        Inc(Count);
        Search[A2] := Count;
      end;
      if (A3 <> 0) and (Search[A3] = 0) then
      begin
        Inc(Count);
        Search[A3] := Count;
      end;
      if (A4 <> 0) and (Search[A4] = 0) then
      begin
        Inc(Count);
        Search[A4] := Count;
      end;
      FFace[Ordinal][0, What] := Search[A1];
      FFace[Ordinal][1, What] := Search[A2];
      FFace[Ordinal][2, What] := Search[A3];
      FFace[Ordinal][3, What] := Search[A4];
    end;
    case What of
      0:
        begin
          FVertexCount := Count;
          SetLength(FVertex, Count + 1);
        end;
      1:
        begin
          FTextureCount := Count;
          SetLength(FTexture, Count + 1);
        end;
      2:
        begin
          FNormalCount := Count;
          SetLength(FNormal, Count + 1);
        end;
    end;
    Count := 0;
    for Index := Start to Finish do
    begin
      A1 := From.FFace[Index][0, What];
      A2 := From.FFace[Index][1, What];
      A3 := From.FFace[Index][2, What];
      A4 := From.FFace[Index][3, What];
      if Search[A1] <> 0 then
        Cop(A1, Count);
      if Search[A2] <> 0 then
        Cop(A2, Count);
      if Search[A3] <> 0 then
        Cop(A3, Count);
      if Search[A4] <> 0 then
        Cop(A4, Count);
    end;
  end;

begin
  if (From = nil) or (Group < 0) or (Group > From.FGroupCount) then
  begin
    Clear();
    Exit;
  end;
  if Group = 0 then
  begin
    FVertexCount := From.FVertexCount;
    FTextureCount := From.FTextureCount;
    FNormalCount := From.FNormalCount;
    FFaceCount := From.FFaceCount;
    FGroupCount := From.FGroupCount;
    SetLength(FVertex, FVertexCount + 1);
    SetLength(FTexture, FTextureCount + 1);
    SetLength(FNormal, FNormalCount + 1);
    SetLength(FFace, FFaceCount + 1);
    SetLength(FGroup, FGroupCount + 1);
    if FVertexCount <> 0 then
      CopyMem(@From.FVertex[0], @FVertex[0], SizeOf(FVertex[0]) * (FVertexCount + 1));
    if FTextureCount <> 0 then
      CopyMem(@From.FTexture[0], @FTexture[0], SizeOf(FTexture[0]) * (FTextureCount + 1));
    if FNormalCount <> 0 then
      CopyMem(@From.FNormal[0], @FNormal[0], SizeOf(FNormal[0]) * (FNormalCount + 1));
    if FFaceCount <> 0 then
      CopyMem(@From.FFace[0], @FFace[0], SizeOf(FFace[0]) * (FFaceCount + 1));
    for Count := 1 to FGroupCount do
      FGroup[Count] := From.FGroup[Count];
    Exit;
  end;
  From.GetGroup(Group, Start, Finish);
  FFaceCount := Finish - Start + 1;
  SetLength(FFace, FFaceCount + 1);
  Proc(0, From.FVertexCount);
  Proc(1, From.FTextureCount);
  Proc(2, From.FNormalCount);
  FGroupCount := 1;
  SetLength(FGroup, FGroupCount + 1);
  FGroup[1].Index := 1;
  FGroup[1].Name := From.FGroup[Group].Name;
end;

procedure TObjModel.ScaleVertex(Value: Real);
var
  Index, Vertex: Integer;
begin
  for Vertex := 1 to FVertexCount do
    for Index := 0 to 2 do
      FVertex[Vertex][Index] := FVertex[Vertex][Index] * Value;
end;

procedure TObjModel.Center();
var
  Vertex: Integer;
  Cur, MinX, MinY, MinZ, MaxX, MaxY, MaxZ, X, Y, Z: Real;
begin
  if FVertexCount < 1 then
    Exit;
  MinX := FVertex[1][0];
  MinY := FVertex[1][1];
  MinZ := FVertex[1][2];
  MaxX := MinX;
  MaxY := MinY;
  MaxZ := MinZ;
  for Vertex := 2 to FVertexCount do
  begin
    Cur := FVertex[Vertex][0];
    if Cur < MinX then
      MinX := Cur;
    if Cur > MaxX then
      MaxX := Cur;
    Cur := FVertex[Vertex][1];
    if Cur < MinY then
      MinY := Cur;
    if Cur > MaxY then
      MaxY := Cur;
    Cur := FVertex[Vertex][2];
    if Cur < MinZ then
      MinZ := Cur;
    if Cur > MaxZ then
      MaxZ := Cur;
  end;
  X := -(MinX + MaxX) / 2;
  Y := -(MinY + MaxY) / 2;
  Z := -(MinZ + MaxZ) / 2;
  for Vertex := 1 to FVertexCount do
  begin
    FVertex[Vertex][0] := FVertex[Vertex][0] + X;
    FVertex[Vertex][1] := FVertex[Vertex][1] + Y;
    FVertex[Vertex][2] := FVertex[Vertex][2] + Z;
  end;
end;

procedure TObjModel.TextureToColor();
var
  Index, Vertex, Color, Quad: Integer;
  Texture: RPoint;
  Store: array of Byte;
begin
  SetLength(Store, FTextureCount + 1);
  ZeroMem(@Store[0], FTextureCount + 1);
  for Index := 1 to FFaceCount do
    for Quad := 0 to 3 do
    begin
      Vertex := FFace[Index][Quad, 0];
      if Vertex <> 0 then
      begin
        Color := FFace[Index][Quad, 1];
        Texture := GetTexture(Color);
        if Store[Vertex] = 0 then
        begin
          FVertex[Vertex][3] := Texture.X;
          FVertex[Vertex][4] := Texture.Y;
          FVertex[Vertex][5] := Texture.Z;
          Store[Vertex] := 1;
        end
        else if (FVertex[Vertex][3] <> Texture.X) or (FVertex[Vertex][4] <>
          Texture.Y) or (FVertex[Vertex][5] <> Texture.Z) then
          FFace[Index][Quad, 0] := AddVertex(FVertex[Vertex][0], FVertex[Vertex]
            [1], FVertex[Vertex][2], Texture.X, Texture.Y, Texture.Z);
        FFace[Index][Quad, 1] := 0;
      end;
    end;
  FTextureCount := 0;
  SetLength(FTexture, 0);
end;

procedure TObjModel.BoundBox(out Min, Max: RPoint);
var
  Index: Integer;
  X, Y, Z: Real;
begin
  Min := SModels3D.PointZero();
  Max := SModels3D.PointZero();
  for Index := 1 to FVertexCount do
  begin
    X := FVertex[Index][0];
    Y := FVertex[Index][1];
    Z := FVertex[Index][2];
    if X < Min.X then
      Min.X := X;
    if Y < Min.Y then
      Min.Y := Y;
    if Z < Min.Z then
      Min.Z := Z;
    if X > Max.X then
      Max.X := X;
    if Y > Max.Y then
      Max.Y := Y;
    if Z > Max.Z then
      Max.Z := Z;
  end;
end;

procedure TObjModel.SplitTriangles();
var
  Index, Count, Param: Integer;
begin
  Count := 0;
  for Index := 1 to FFaceCount do
  begin
    if FFace[Index][2, 0] <> 0 then
      Inc(Count);
    if FFace[Index][3, 0] <> 0 then
      Inc(Count);
  end;
  if Count <= FFaceCount then
    Exit;
  Index := FFaceCount;
  FFaceCount := Count;
  if Length(FFace) <= FFaceCount then
    SetLength(FFace, NewLength(FFaceCount));
  while (Index > 0) and (Count <> Index) do
  begin
    if FFace[Index][3, 0] <> 0 then
    begin
      for Param := 0 to 2 do
      begin
        FFace[Count][0, Param] := FFace[Count][2, Param];
        FFace[Count][1, Param] := FFace[Count][3, Param];
        FFace[Count][2, Param] := FFace[Count][0, Param];
        FFace[Count][3, Param] := 0;
      end;
      Dec(Count);
    end;
    CopyMem(@FFace[Index], @FFace[Count], SizeOf(FFace[0]));
    Dec(Count);
    Dec(Index);
  end;
end;

{
 Tria:
     2
   / |
 0 - 1

 Quad:
 3 - 2
 | / |
 0 - 1
}

end.

