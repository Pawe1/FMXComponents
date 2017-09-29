unit FMX.LoadingIndicator;

interface

uses
  System.Classes,
  System.Types,
  System.UITypes,
  System.Math,
  FMX.Types,
  FMX.Controls,
  FMX.Graphics,
  FMX.Objects,
  FMX.Layouts,
  FMX.Ani,
  FMX.Utils,
  FMX.ComponentsCommon;

type
  TLoadingIndicatorKind = (LoadingArcs, LoadingDoubleBounce, LoadingFlipPlane,
    LoadingPulse, LoadingArcsRing, LoadingRing, LoadingThreeDots, LoadingWave);

  [ComponentPlatformsAttribute(TFMXPlatforms)]
  TFMXLoadingIndicator = class(TLayout)
  private type
    TCell = record
      Col: Integer;
      Row: Integer;
      ColSpan: Integer;
      RowSpan: Integer;
    end;
  private const
    INDICATOR_DURING: array [TLoadingIndicatorKind] of Single = (
      3, 1, 1.6, 1.5, 0.8, 0.8, 1.9, 1
      );
    INDICATOR_AUTOREVERSE: array [TLoadingIndicatorKind] of Boolean = (
      False, True, False, True, False, False, False, False
      );
    INDICATOR_MINSIZE: array [TLoadingIndicatorKind] of TSizeF = (
      (cx: 45; cy: 45),
      (cx: 45; cy: 45),
      (cx: 45; cy: 45),
      (cx: 45; cy: 45),
      (cx: 45; cy: 45),
      (cx: 45; cy: 45),
      (cx: 70; cy: 20),
      (cx: 50; cy: 25)
      );
    RING_CELLS: array [0 .. 7] of TCell = (
      (Col: 2; Row: 0; ColSpan: 1; RowSpan: 1),
      (Col: 3; Row: 0; ColSpan: 2; RowSpan: 2),
      (Col: 4; Row: 2; ColSpan: 1; RowSpan: 1),
      (Col: 3; Row: 3; ColSpan: 2; RowSpan: 2),
      (Col: 2; Row: 4; ColSpan: 1; RowSpan: 1),
      (Col: 0; Row: 3; ColSpan: 2; RowSpan: 2),
      (Col: 0; Row: 2; ColSpan: 1; RowSpan: 1),
      (Col: 0; Row: 0; ColSpan: 2; RowSpan: 2)
      );
    RING_CIRCLE_SIZE = 7;
    procedure ConfirmSize;
  private
    FKind: TLoadingIndicatorKind;
    FBrush: TBrush;
    FAnimation: TAnimation;
    FShapes: TArray<TShape>;
    function GetCellRect(CellWidth, CellHeight: Single;
      const Cell: TCell): TRectF;
    procedure SetKind(const Value: TLoadingIndicatorKind);
    procedure SetColor(const Value: TAlphaColor);
    procedure LoadingThreeDotsAnimationProcess(Sender: TObject);
    procedure LoadingWaveAnimationProcess(Sender: TObject);
    procedure OnAnimation(Sender: TObject);
    procedure CreateAnimation;
    procedure CreateLoadingThreeDots;
    procedure CreateLoadingWave;
    procedure DrawLoadingArcs;
    procedure DrawLoadingArcsRing;
    procedure DrawLoadingDoubleBounce;
    procedure DrawLoadingFlipPlane;
    procedure DrawLoadingPulse;
    procedure DrawLoadingRing;
    function GetColor: TAlphaColor;
  protected
    procedure Resize; override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;
    procedure Start;
  published
    property Color: TAlphaColor read GetColor write SetColor;
    property Kind: TLoadingIndicatorKind read FKind write SetKind
      default TLoadingIndicatorKind.LoadingPulse;
    property Align;
    property Anchors;
    property ClipChildren default False;
    property ClipParent default False;
    property Cursor default crDefault;
    property DragMode default TDragMode.dmManual;
    property EnableDragHighlight default True;
    property Enabled default True;
    property Locked default False;
    property Height;
    property HitTest default True;
    property Padding;
    property Opacity;
    property Margins;
    property PopupMenu;
    property Position;
    property RotationAngle;
    property RotationCenter;
    property Scale;
    property Size;
    property Visible default True;
    property Width;
    { Drag and Drop events }
    property OnDragEnter;
    property OnDragLeave;
    property OnDragOver;
    property OnDragDrop;
    property OnDragEnd;
    { Mouse events }
    property OnClick;
    property OnDblClick;

    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseEnter;
    property OnMouseLeave;

    property OnPainting;
    property OnPaint;
    property OnResize;
{$IF (RTLVersion >= 32)} // Tokyo
    property OnResized;
{$ENDIF}
  end;

implementation


type
  TMyAnimation = class(TAnimation)
  protected
    procedure ProcessAnimation; override;
  end;

{ TFMXLoadingIndicator }
procedure TFMXLoadingIndicator.LoadingThreeDotsAnimationProcess(
  Sender: TObject);
var
  T: Single;
  I: Integer;
  s: Single;
  Circle: TCircle;
  R: TRectF;
  C: TPointF;
  W, H, Space: Single;
begin
  T := FAnimation.CurrentTime;
  W := (Width - 10) / 3;
  H := Height;
  Space := 0;
  for I := Low(FShapes) to High(FShapes) do
  begin
    if T < 0.5 then
      s := InterpolateSingle(0, 1, T / 0.5)
    else if T < 0.6 then
      s := 1
    else if T < 1.1 then
      s := InterpolateSingle(1, 0, (T - 0.6) / 0.5)
    else
      s := 0;
    T := T - 0.25;
    if T < 0 then
      T := T + 1.9;
    R := RectF(0, 0, W, H);
    R.Offset(I * W + Space, 0);
    Space := Space + 5;
    Circle := FShapes[I] as TCircle;
    Circle.Scale.Point := PointF(s, s);
    C := R.CenterPoint;
    Circle.Position.Point := PointF(
      C.X - Circle.Width * s / 2,
      C.Y - Circle.Height * s / 2
      );
  end;
end;

procedure TFMXLoadingIndicator.LoadingWaveAnimationProcess(Sender: TObject);
var
  T: Single;
  I: Integer;
  s: Single;
  Rectangle: TRectangle;
  R: TRectF;
  C: TPointF;
  W, H, Space: Single;
begin
  T := FAnimation.NormalizedTime;
  W := (Width - 20) / 5;
  H := Height;
  Space := 0;
  for I := Low(FShapes) to High(FShapes) do
  begin
    if T < 0.1 then
      s := InterpolateSingle(1, 1.6, T / 0.1)
    else if (T < 0.15) then
      s := 1.6
    else if T < 0.35 then
      s := InterpolateSingle(1.6, 1, (T - 0.15) / 0.2)
    else
      s := 1;
    T := T - 0.05;
    if T < 0 then
      T := T + 1;
    R := RectF(0, 0, W, H);
    R.Offset(I * W + Space, 0);
    Space := Space + 5;
    Rectangle := FShapes[I] as TRectangle;
    Rectangle.Scale.Y := s;
    C := R.CenterPoint;
    Rectangle.Position.Y := C.Y - Rectangle.Height * s / 2;
  end;
end;

procedure TFMXLoadingIndicator.OnAnimation(Sender: TObject);
begin
  Repaint;
end;

procedure TFMXLoadingIndicator.Paint;
begin
  inherited;
  case Kind of
    LoadingArcs:
      DrawLoadingArcs;
    LoadingDoubleBounce:
      DrawLoadingDoubleBounce;
    LoadingFlipPlane:
      DrawLoadingFlipPlane;
    LoadingPulse:
      DrawLoadingPulse;
    LoadingArcsRing:
      DrawLoadingArcsRing;
    LoadingRing:
      DrawLoadingRing;
    LoadingThreeDots:
      ;
    LoadingWave:
      ;
  end;
end;

procedure TFMXLoadingIndicator.Resize;
begin
  inherited;
  ConfirmSize;
  Repaint;
end;

constructor TFMXLoadingIndicator.Create(AOwner: TComponent);
begin
  inherited;
  FBrush := TBrush.Create(TBrushKind.Solid, $FF1282B2);
  FKind := TLoadingIndicatorKind.LoadingPulse;
  Width := 46;
  Height := 46;
  CreateAnimation;
  FAnimation.Duration := INDICATOR_DURING[FKind];
  FAnimation.AutoReverse := INDICATOR_AUTOREVERSE[FKind]
end;

procedure TFMXLoadingIndicator.Loaded;
begin
  inherited;
  Start;
end;

procedure TFMXLoadingIndicator.SetColor(const Value: TAlphaColor);
var
  Shape: TShape;
begin
  if FBrush.Color <> Value then
  begin
    FBrush.Color := Value;
  end;
end;

procedure TFMXLoadingIndicator.SetKind(const Value: TLoadingIndicatorKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    FAnimation.Duration := INDICATOR_DURING[Kind];
    FAnimation.AutoReverse := INDICATOR_AUTOREVERSE[Kind];
    ConfirmSize;
    Repaint;
  end;
end;

procedure TFMXLoadingIndicator.Start;
begin
  CreateAnimation;
  FAnimation.Start;
end;

procedure TFMXLoadingIndicator.ConfirmSize;
var
  MinSize: TSizeF;
begin
  MinSize := INDICATOR_MINSIZE[Kind];
  if Height < MinSize.Width then
    Height := MinSize.Width;
  if Width < MinSize.Height then
    Width := MinSize.Height;
end;

procedure TFMXLoadingIndicator.CreateAnimation;
begin
  if not Assigned(FAnimation) then
  begin
    FAnimation := TMyAnimation.Create(Self);
    FAnimation.Stored := False;
    FAnimation.Loop := True;
    FAnimation.OnProcess := OnAnimation;
    AddObject(FAnimation);
  end;
end;

procedure TFMXLoadingIndicator.CreateLoadingThreeDots;
var
  Circle: TCircle;
  W, H: Single;
  I: Integer;
  R: TRectF;
  Space: Single;
begin
  SetLength(FShapes, 3);
  W := (Width - 10) / 3;
  H := Height;
  Space := 0;
  for I := 0 to 2 do
  begin
    R := RectF(0, 0, W, H);
    R.Offset(I * W + Space, 0);
    Space := Space + 5;

    Circle := TCircle.Create(Self);
    Circle.Stored := False;
    Circle.Fill.Kind := TBrushKind.Solid;
    Circle.Fill.Color := Color;
    Circle.Stroke.Kind := TBrushKind.None;
    Circle.BoundsRect := R;
    FShapes[I] := Circle;
    AddObject(Circle);
  end;
  CreateAnimation;
  FAnimation.Duration := 1.9;
  FAnimation.OnProcess := LoadingThreeDotsAnimationProcess;
end;

procedure TFMXLoadingIndicator.CreateLoadingWave;
var
  Rectangle: TRectangle;
  W, H: Single;
  I: Integer;
  R: TRectF;
  Space: Single;
begin
  SetLength(FShapes, 5);
  W := (Width - 20) / 5;
  H := Height;
  Space := 0;
  for I := 0 to 4 do
  begin
    R := RectF(0, 0, W, H);
    R.Offset(I * W + Space, 0);
    Space := Space + 5;

    Rectangle := TRectangle.Create(Self);
    Rectangle.Stored := False;
    Rectangle.Fill.Kind := TBrushKind.Solid;
    Rectangle.Fill.Color := Color;
    Rectangle.Stroke.Kind := TBrushKind.None;
    Rectangle.BoundsRect := R;
    FShapes[I] := Rectangle;
    AddObject(Rectangle);
  end;
  CreateAnimation;
  FAnimation.Duration := 1;
  FAnimation.OnProcess := LoadingWaveAnimationProcess;
end;

destructor TFMXLoadingIndicator.Destroy;
begin
  FBrush.Free;
  inherited;
end;

procedure TFMXLoadingIndicator.DrawLoadingArcs;
var
  Arc: TPathData;
  P: TPointF;
  R: Single;
  T, A: Single;
begin
  T := FAnimation.NormalizedTime;
  A := InterpolateSingle(0, 360, T);

  P := PointF(Width / 2, Height / 2);
  R := Min(P.X, P.Y);
  Arc := TPathData.Create;
  try
    Arc.AddArc(P, PointF(R, R), A, 270);
    Arc.AddArc(P, PointF(R - 5, R - 5), A + 270, -270);
    Arc.ClosePath;
    Canvas.FillPath(Arc, 1, FBrush);

    R := R - 5;
    A := 360 - A;
    Arc.Clear;
    Arc.AddArc(P, PointF(R, R), A + 45, -210);
    Arc.AddArc(P, PointF(R - 5, R - 5), A + 45 - 210, 210);
    Arc.ClosePath;
    Canvas.FillPath(Arc, 0.3, FBrush);
  finally
    Arc.Free;
  end;
end;

procedure TFMXLoadingIndicator.DrawLoadingArcsRing;
var
  P: TPointF;
  R: Single;
  StartAngle: Single;
  path: TPathData;
  I: Integer;
  T: Single;
  O: Single;
begin
  T := FAnimation.NormalizedTime;
  P := PointF(Width / 2, Height / 2);
  R := Min(P.X, P.Y);
  StartAngle := -15;
  path := TPathData.Create;
  try
    for I := 0 to 7 do
    begin
      if T < 0.125 then
        O := InterpolateSingle(1, 0.3, T * 8)
      else
        O := 0.3;
      T := T - 0.125;
      if T < 0 then
        T := T + 1;
      path.Clear;
      path.AddArc(P, PointF(R, R), StartAngle, 30);
      path.AddArc(P, PointF(R - 5, R - 5), StartAngle + 30, -30);
      path.ClosePath;
      Canvas.FillPath(path, O, FBrush);
      StartAngle := StartAngle + 45;
    end;
  finally
    path.Free;
  end;
end;

procedure TFMXLoadingIndicator.DrawLoadingDoubleBounce;
var
  T, S: Single;
  P: TPointF;
  R, R1, R2: Single;
  DR: TRectF;
begin
  T := FAnimation.NormalizedTime;
  S := InterpolateSingle(1, 0, T);
  P := PointF(Width / 2, Height / 2);
  R := Min(P.X, P.Y);
  R1 := R * S;
  R2 := R * (1 - S);
  DR := RectF(P.X - R1, P.Y - R1, P.X + R1, P.Y + R1);
  Canvas.FillEllipse(DR, 0.3, FBrush);
  DR := RectF(P.X - R2, P.Y - R2, P.X + R2, P.Y + R2);
  Canvas.FillEllipse(DR, 0.3, FBrush);
end;

procedure TFMXLoadingIndicator.DrawLoadingFlipPlane;
  function CalcScale(T: Single): Single;
  begin
    if T < 0.25 then
      Result := InterpolateSingle(1, 0, T / 0.25)
    else if T < 0.5 then
      Result := InterpolateSingle(0, 1, (T - 0.25) / 0.25)
    else
      Result := 1;
  end;

var
  R: TRectF;
  SX, SY: Single;
  T: Single;
begin
  T := FAnimation.NormalizedTime;
  SY := CalcScale(T);
  T := T - 0.5;
  if T < 0 then
    T := T + 1;
  SX := CalcScale(T);
  R := RectF(0, 0, Width * SX, Height * SY);
  R := R.CenterAt(RectF(0,0,Width,Height));
  Canvas.FillRect(R, 0, 0, AllCorners, 1, FBrush);
end;

procedure TFMXLoadingIndicator.DrawLoadingPulse;
var
  T, S: Single;
  P: TPointF;
  R: Single;
  DR: TRectF;
begin
  T := FAnimation.NormalizedTime;
  S := InterpolateSingle(0, 1, T);
  P := PointF(Width / 2, Height / 2);
  R := Min(P.X, P.Y) * S;
  DR := RectF(P.X - R, P.Y - R, P.X + R, P.Y + R);
  Canvas.FillEllipse(DR, 1-S, FBrush);
end;

procedure TFMXLoadingIndicator.DrawLoadingRing;
var
  T: Single;
  I: Integer;
  s: Single;
  Circle: TCircle;
  R, DR: TRectF;
  C: TPointF;
begin
  T := FAnimation.NormalizedTime;
  for I := 0 to 7 do
  begin
    if T < 0.4 then
      s := InterpolateSingle(0, 1, T / 0.4)
    else if T < 0.8 then
      s := InterpolateSingle(1, 0, (T - 0.4) / 0.4)
    else
      s := 0;
    R := GetCellRect(Width / 5, Height / 5, RING_CELLS[I]);
    DR := RectF(0, 0, RING_CIRCLE_SIZE * s, RING_CIRCLE_SIZE * s);
    DR := DR.CenterAt(R);
    Canvas.FillEllipse(DR, 1, FBrush);
    T := T - 0.125;
    if T < 0 then
      T := T + 1;
  end;
end;


function TFMXLoadingIndicator.GetCellRect(CellWidth, CellHeight: Single;
  const Cell: TCell): TRectF;
var
  R: TRectF;
begin
  R.Left := CellWidth * Cell.Col;
  R.Top := CellHeight * Cell.Row;
  R.Right := CellWidth * (Cell.Col + Cell.ColSpan);
  R.Bottom := CellHeight * (Cell.Row + Cell.RowSpan);
  Result := RectF(0, 0, CellWidth, CellHeight);
  RectCenter(Result, R);
end;

function TFMXLoadingIndicator.GetColor: TAlphaColor;
begin
  Result := FBrush.Color
end;

{ TMyAnimation }

procedure TMyAnimation.ProcessAnimation;
begin

end;

end.
