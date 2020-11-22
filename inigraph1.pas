Program inigraph1;

{ Program to demonstrate static graphics mode selection }
{ https://www.freepascal.org/docs-html/current/rtl/graph/modes.html }

uses graph;

const
  TheLine = 'We are now in 640 x 480 x 256 colors!'+
            ' (press <Return> to continue)';

  Line2 = 'We are now in 800 x6 00 x 256 colors!'+
            ' (press <Return> to continue)';

var
  gd, gm, lo, hi, error,tw,th: integer;
  found: boolean;

begin
  { We want an 8 bit mode }
  gd := D8bit;
  gm := m640x480;
  initgraph(gd,gm,'');
  { Make sure you always check graphresult! }
  error := graphResult;
  if (error <> grOk) Then
    begin
    writeln('640x480x256 is not supported!');
    halt(1)
    end;
  { We are now in 640x480x256 }
  setColor(cyan);
  rectangle(0,0,getmaxx,getmaxy);
  { Write a nice message in the center of the screen }
  setTextStyle(defaultFont,horizDir,1);
  tw:=TextWidth(TheLine);
  th:=TextHeight(TheLine);
  outTextXY((getMaxX - TW) div 2,
            (getMaxY - TH) div 2,TheLine);
  { Wait for return }
  readln;
  { Back to text mode }
  closegraph;
  
  gd := D8bit;
  gm := m800x600;
  initgraph(gd,gm,'');
  { Make sure you always check graphresult! }
  error := graphResult;
  if (error <> grOk) Then
    begin
    writeln('800x600x256 is not supported!');
    halt(1)
    end;
  { We are now in 800x600x256 }
  setColor(red);
  rectangle(0,0,getmaxx,getmaxy);
  { Write a nice message in the center of the screen }
  setTextStyle(defaultFont,horizDir,1);
  tw:=TextWidth(Line2);
  th:=TextHeight(Line2);
  outTextXY((getMaxX - TW) div 2,
            (getMaxY - TH) div 2,Line2);
  { Wait for return }
  readln;
  { Back to text mode }
  closegraph;
end.