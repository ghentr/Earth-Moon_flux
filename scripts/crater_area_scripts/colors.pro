PRO COLORS, START=START, NAMES=NAMES, VALUES=VALUES

;+
; NAME:
;    COLORS
;
; PURPOSE:
;    Load sixteen graphics colors into the color table.
;
; CATEGORY:
;    Startup utilities.
;
; CALLING SEQUENCE:
;    COLORS
;
; INPUTS:
;    None
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;     START     Start index in the color table where the graphics
;               colors will be loaded (default = 0).
;     NAMES     If set to a named variable, returns an array of color names.
;     VALUES    If set to a named variable, returns an array of color index values.
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    None
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    This routine modifies the color table.
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
; ; Display a greyscale image with color text overlaid.
; device, decomposed=0
; window, /free, xs = 500, ys = 500
; colors, names=names
; bottom = 16B
; ncolors = !d.table_size - bottom
; loadct, 0, bottom=bottom, ncolors=ncolors
; tv, bytscl( dist(256), top=ncolors-1 ) + bottom
; for i=1,8 do xyouts, 30*i, 30*i, names[i], /device, charsize=1.5, color=i
;
; MODIFICATION HISTORY:
;    Written by: Liam.Gumley@ssec.wisc.edu
;
; NOTES:
;     The color table assignments are as follows
;   Entry   Color
;   -----   -----
;      0 => Black
;      1 => Magenta
;      2 => Cyan
;      3 => Yellow
;      4 => Green
;      5 => Red
;      6 => Blue
;      7 => White
;      8 => Navy
;      9 => Gold
;     10 => Pink
;     11 => Aquamarine
;     12 => Orchid
;     13 => Gray
;     14 => Sky
;     15 => Beige
;-

rcs_id = "$Id: colors.pro,v 1.2 1999/04/20 15:14:45 gumley Exp $"
    
;- Check keyword values

if n_elements( start ) ne 1 then start = 0

;- Load graphics colors (derived from McIDAS)

r = [0,255,0,255,0,255,0,255,0,255,255,112,219,127,0,255]
g = [0,0,255,255,255,0,0,255,0,187,127,219,112,127,163,171]
b = [0,255,255,0,0,0,255,255,115,0,127,147,219,127,255,127]
tvlct, r, g, b, start

;- Set return keywords

names = [ $
  'Black', 'Magenta', 'Cyan', 'Yellow', 'Green', 'Red', 'Blue', 'White', $
  'Navy', 'Gold', 'Pink', 'Aquamarine', 'Orchid', 'Gray', 'Sky', 'Beige' ]
values = byte( indgen( 16 ) + start )

END
