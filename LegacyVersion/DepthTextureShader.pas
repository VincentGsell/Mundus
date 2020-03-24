unit DepthTextureShader;

interface

uses
  Classes, Types, SysUtils,
  Graphics,
  Mundus.Shader,
  Mundus.Math,
  Mundus.Mesh,
  Mundus.Types,
  Mundus.Shader.Texture;


const
  CST_FARAWAY = 99999;
type
  TSimpleDethBuffer = array of array of single;
  TDepthBuffer = class
  private
    FEmptyDepth : TSimpleDethBuffer;
  public
    Depth : TSimpleDethBuffer;

    procedure resize(width, height : integer);
    procedure clear;
  end;

  TDepthTextureShader = class(TTextureShader)
  private
    FDepthBuffer : TDepthBuffer;

  public
    constructor Create;
    destructor destroy; override;
    procedure InitDepthBuffer(width, height : Integer);
    procedure clearDepthBuffer;
    procedure Shade8X8Quad();
    procedure ShadeSinglePixel();
  end;

implementation

uses
  Math;

{ TDepthTextureShader }

procedure TDepthTextureShader.clearDepthBuffer;
begin
  FDepthBuffer.clear;
end;

constructor TDepthTextureShader.Create;
begin
  inherited;
  FDepthBuffer :=  TDepthBuffer.Create;
end;

destructor TDepthTextureShader.destroy;
begin
  FreeAndNil(FDepthBuffer);
  inherited;
end;

procedure TDepthTextureShader.InitDepthBuffer(width, height: Integer);
begin
  if length(FDepthBuffer.Depth)<>height then
    FDepthBuffer.resize(width,height);
end;


{$CODEALIGN 16}
procedure TDepthTextureShader.Shade8X8Quad;
var
  LX, LY, LPixelY: Integer;
  LTexX, LTexY: Integer;
  LZ: Double;
  LFUX, LFUY, LFVX, LFVY, LFZX, LFZY: Single;
  LMaxX, LMaxY: Integer;
  LZAverage : Single;
begin
  LMaxX := FTexMaxX;
  LMaxY := FTexMaxY;
  LFZY := FZB*Pixel.Y + FZD;
  LFUY := FUB*Pixel.Y + FUD;
  LFVY := FVB*Pixel.Y + FVD;
  LPixelY := Pixel.Y*LineLength;
  for LY  := Pixel.Y to Pixel.Y + 7 do
  begin
    LFZX := FZA * Pixel.X + LFZY;
    LFUX := FUA * Pixel.X + LFUY;
    LFVX := FVA * Pixel.X + LFVY;
    for LX := Pixel.X to Pixel.X + 7 do
    begin
      LZ := 1/(LFZX);
      LZAverage := 1/(FZA*LX + FZB * LY + FZD);
      if (FDepthBuffer.Depth[LX,LY] = CST_FARAWAY) Or (LZAverage>FDepthBuffer.Depth[LX,LY]) then
      begin

      {$IFDEF WIN32}
  //      LTexX := Round(LFUX*LMaxX*LZ);
        asm
          fild LMaxX
          FMul LFUX
          FMul LZ
          FISTP LTexX
          wait
        end;
  //      LTexY := Round(LFVX*FTexMaxY*LZ);
        asm
          fild LMaxY
          FMul LFVX
          FMul LZ
          FISTP LTexY
          wait
        end;
      {$ELSE}
        LTexX := Round(LFUX*LMaxX*LZ);
        LTexY := Round(LFVX*FTexMaxY*LZ);
      {$ENDIF}


        FDepthBuffer.Depth[LX,LY] := LZAverage;
        FirstLine[LPixelY + LX] := FTexFirstLine[LTexY*FTexLineLength + LTexX];
      end;

      LFZX := LFZX + FZA;
      LFUX := LFUX + FUA;
      LFVX := LFVX + FVA;
    end;
    LFZY := LFZY + FZB;
    LFUY := LFUY + FUB;
    LFVY := LFVY + FVB;
    LPixelY := LPixelY + LineLength;
  end;
end;

{$CODEALIGN 16}
procedure TDepthTextureShader.ShadeSinglePixel;
var
  LX, LY, LPixel, LTexPixel: Integer;
  LTexX, LTexY: Integer;
  LU, LV: Single;
  LZ: Single;
begin
  LY := Pixel.Y;
  LX := Pixel.X;

  LZ := 1/(FZA*LX + FZB * LY + FZD);
  if (FDepthBuffer.Depth[LX,LY] = CST_FARAWAY) Or (LZ>FDepthBuffer.Depth[LX,LY]) then
  begin
    FDepthBuffer.Depth[LX,LY] := LZ;
    LPixel := LY*LineLength + LX;
    LU := (FUA*LX + FUB * LY + FUD)*LZ;
    LV := (FVA*LX + FVB * LY + FVD)*LZ;
    LTexX := Round(abs(LU*(FTexMaxX)));
    LTexY := Round(abs(LV*(FTexMaxY)));

    LTexPixel := (LTexY mod FTexHeight)*FTexLineLength + (LTexX mod FTexWidth);
    FirstLine[LPixel] := FTexFirstLine[LTexPixel];
  end;
end;

{ TDepthBuffer }

procedure TDepthBuffer.clear;
var i,j : integer;
begin
  for i := 0 to Length(FEmptyDepth)-1 do
  begin
    for j := 0 to Length(FEmptyDepth[i])-1 do
      FEmptyDepth[i,j] := CST_FARAWAY;
  end;
  Depth := FEmptyDepth;

end;

procedure TDepthBuffer.resize(width, height: integer);
var i,j : integer;
begin
  SetLength(Depth,width);
  for i := 0 to width-1 do
    SetLength(Depth[i],height);

  SetLength(FEmptyDepth,width);
  for i := 0 to width-1 do
  begin
    SetLength(FEmptyDepth[i],height);
    for j := 0 to height-1 do
      FEmptyDepth[i,j] := CST_FARAWAY;
  end;

end;

end.
