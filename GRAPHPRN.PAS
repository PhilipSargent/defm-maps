Unit GraphPRN;

Interface

Uses Dos, Graph;

Var  LST : Text;

Procedure HardCopy (Gmode: Integer);

Implementation

Procedure Hardcopy;

Const
  Bits : Array [0..7] of Byte = (128,64,32,16,8,4,2,1);

Var
  X,Y,YOfs         : Integer;
  BitData,MaxBits  : Byte;
  Vport            : ViewportType;
  Height, Width    : Word;
  HiBit, LoBit     : Char;
  LineSpacing,
  GraphixPrefix    : String[10];
  BkColor          : Byte;

Begin
  LineSpacing := #27+'3'+#24;
  Case Gmode Of
    -1:   GraphixPrefix := #27+'K';
    -2:   GraphixPrefix := #27+'L';
    -3:   GraphixPrefix := #27+'Y';
    -4:   GraphixPrefix := #27+'Z';
    0..7: GraphixPrefix := #27+'*'+Chr( Gmode );
    Else
      Exit;
  End;
  BkColor := GetBkcolor;
  GetViewSettings( Vport );
  Height := Vport.Y2 - Vport.Y1;
  Width := ( Vport.X2 + 1 ) - Vport.X1;
  HiBit := Chr( Hi( Width ) );
  LoBit := Chr( Lo( Width ) );
  Write( LST, LineSpacing );
  Y := 0;
  While Y < Height Do
  Begin
    Write( LST,GraphixPrefix,LoBit,HiBit );
    For X := 0 to Width-1 Do
    Begin
      BitData := 0;
      If Y + 7 <= Height Then
        MaxBits := 7
      Else
        MaxBits := Height - Y;
      For YOfs := 0 to MaxBits Do
        If( GetPixel( X, YOfs+Y ) <> BkColor ) Then
          BitData := BitData or Bits[YOfs];
      Write( Lst, Chr( BitData ) );
    End;
    WriteLn ( LST );
    Inc ( Y,8 );

  End;
    Write( LST, #27 + '@' );
End;

{$F+}
Function LSTNoFunction( Var F : TextRec ) : Integer;
{ This function performs a NUL operation on LST in case a Reset or }
{ a Rewrite is called.                                             }

Begin
  LSTNoFunction := 0;
End;

Function LSTOutPutToPrinter( Var F : TextRec ) : Integer;
{ LSTOutPutToPrinter sends the output to the printer port  }
{ number stored in the first byte of the UserData area of  }
{ the Text Record.                                         }

Var
  Regs : Registers;
  P : Word;

Begin
  With F Do
  Begin
    P := 0;
    Regs.AH := 16;
    While( P < BufPos ) and ( ( Regs.AH and 16 ) = 16 ) Do
    Begin
      Regs.AL := Ord( BufPtr^[P] );
      Regs.AH := 0;
      Regs.DX := UserData[1];
      Intr( $17, Regs );
      Inc( P );
    End;
    BufPos := 0;
  End;
  If( ( Regs.AH And 16 ) = 16 ) Then
    LstOutPutToPrinter := 0            { No Error }
  Else
    If( ( Regs.AH And 32 ) = 32 ) Then
      LstOutPutToPrinter := 159        { out of Paper }
    Else
      LstOutPutToPrinter := 160;       { Device Write Fault }
End;
{$F-}

Procedure AssignLST( Port : Byte );

Begin
  With TextRec( Lst ) Do
  Begin
    Handle := $FFF0;
    Mode := fmOutput;
    BufSize := Sizeof( Buffer );
    BufPtr := @Buffer;
    BufPos := 0;
    OpenFunc := @LSTNoFunction;
    InOutFunc := @LSTOutPutToPrinter;
    FlushFunc := @LSTOutPutToPrinter;
    CloseFunc := @LSTOutPutToPrinter;
    UserData[1] := Port - 1;
  End;
End;

Begin
  AssignLST( 1 );
End.

