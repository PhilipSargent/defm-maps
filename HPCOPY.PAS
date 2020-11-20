{ hpcopy.pas }
{ PMS 12-June-1993 02:23 }
Unit HpCopy;
{ This unit is designed to dump graphics images produced by }
{ Turbo Pascal's Graph Unit to a Hewlett-Packard LaserJet   }
{ printer.  You must be sure to set the aspect ratio with   }
{ the command SetAspectRatio( 3000,5000 ); before drawing a }
{ circular object.                                          }
{ If the Aspect ratio is Not set, the image produced by this}
{ routine will appear ellipsoid.                            }

Interface

Uses
  Crt, Dos, Graph;  { Link in the necessary support units   }

Var
  lst : Text;       { Must Redefine because Turbo's Printer }
                    { Unit does not open LST with the file  }
                    { Mode as BINARY.                       }

Procedure HPHardCopy;

Implementation

Var
  Width, Height : Word; { variable used to store settings  }
  Vport : ViewPortType; { Used in the call GetViewSettings }

{$F+}
Function LSTNoFunction( Var F : TextRec ) : Integer;
{ This function performs a NUL operation for a Reset or    }
{ Rewrite on LST.                                          }

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
      REgs.AH := 0;
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
{ AssignLST both sets up the LST text file record as would }
{ ASSIGN, and initializes it as would a RESET.             }
{ The parameter passed to this procedure corresponds to    }
{ DOS's LPT number. It is set to 1 by default, but can     }
{ easily be changed to any LPT number by changing the      }
{ parameter passed to this procedure in this unit's        }
{ initialization code.                                     }

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

Procedure HPHardCopy;
{ Unlike Graphix Toolbox procedure Hardcopy, this procedure  }
{ has no parameters, though it could easily be rewritten to  }
{ include resolution in dots per inch, starting column,      }
{ inverse image, etc.                                        }

Const
  DotsPerInch = '100';
                      { 100 dots per inch gives full-screen     }
                      { width of 7.2 inches for Hercules card   }
                      { graphics, 6.4 inches for IBM color card }
                      { and 6.4 inches for EGA card. Other      }
                      { allowable values are 75, 150, and 300.  }
                      { 75 dots per inch will produce a Larger  }
                      { full-screen graph which may be too large}
                      { to fit on an 8 1/2 inch page; 150 and   }
                      { dots per inch will produces smaller graphs }

  CursorPosition = '5';
                      { Column position of left side of graph   }
  Esc            = #27;
                      { Escape character                        }

Var
  LineHeader : String[6];
                      { Line Header used for each line sent     }
                      { to the LaserJet printer.                }
  LineLength : String[2];
                      { Length in bytes of the line to be       }
                      { sent to the LaserJet.                   }
  Y          : Integer;
                      { Temporary Loop Variable.                }

Procedure DrawLine( Y : Integer );
{ Draw a single line of dots.  No of Bytes sent to printer      }
{ is Width + 1.  Argument of the procedure is the row no, Y     }

Var
  GraphStr   : String[255];  { String used for OutPut           }
  Base       : Word;         { Starting position of output byte }
  BitNo,                     { Bit Number worked on             }
  ByteNo,                    { Byte number worked on            }
  DataByte   : Byte;         { Data Byte being built            }

Begin
  FillChar( GraphStr, SizeOf( GraphStr ), #0 );
  GraphStr := LineHeader;
  For ByteNo := 0 to Width Do
  Begin
    DataByte := 0;
    Base := 8 * ByteNo;
    For BitNo := 0 to 7 Do
    Begin
      If( GetPixel(BitNo+Base, Y ) > 0) Then
        DataByte := DataByte + 128 Shr BitNo;
    End;
    GraphStr := GraphStr + Chr (DataByte)
  End;
  Write (Lst,GraphStr)
End; { of DrawLine }

Begin { Main procedure HPCopy }
  FillChar( LineLength, SizeOf( LineLength ), #0);
  FillChar( LineHeader, SizeOf( LineLength ), #0);
  GetViewSettings( Vport );
  Width := ( Vport.X2 + 1 ) - Vport.X1;
  Width := ( ( Width - 7 ) Div 8 );
  Height := Vport.Y2 - Vport.Y1;
  Write (Lst, Esc + 'E');                  { Reset Printer                }
  Write (Lst, Esc+'*t'+DotsPerInch+'R');   { Set density in dots per inch }
  Write (Lst, Esc+'&a'+CursorPosition+'C');{ Move cursor to starting col  }
  Write (Lst, Esc + '*r1A');               { Begin raster graphics        }
  Str (Width + 1, LineLength);
  LineHeader := Esc + '*b' + LineLength + 'W';
  For Y := 0 to Height + 1 Do
  Begin
    DrawLine ( Y );
    DrawLine ( Y );
  End;
  Write (Lst, Esc + '*rB');                 { End Raster graphics         }
  Write (Lst, Esc + 'E');                   { Reset printer and eject page}
End;

Begin
  AssignLST( 2 );   { This is the number to change if you want the ouput  }
                    { to be directed to a different LST devices.          }
End.                { Of Unit HPCopy }

