pro auto_crater_area

seed = 92911L

; In this code, we compare the distances between the observed craters and a random distribution
; of (lat, long) points.  Choosing a threshold distance, we find the surface area that is not
; covered by craters. 

astrolib
colors, names = names

openw, 6, 'results_earth_craters.data'

delta_dist = [500., 550., 600, 650.]
diam_crater_thresh = [5.]
age_thresh = [0.]

for j1 = 0, n_elements (delta_dist) -1 do begin 
for j2 = 0, n_elements (diam_crater_thresh) -1 do begin 
for j3 = 0, n_elements (age_thresh) -1 do begin 

readcol, 'revised_earth_crater.data', num, earth_lat, earth_long, diam, age

index = where (age gt age_thresh (j3) and diam gt diam_crater_thresh (j2))

earth_lat = earth_lat (index)
earth_long = earth_long (index)
diam = diam (index)

n_particles = 30000
thresh_dist = delta_dist (j1)

i_thresh = fltarr (n_particles)

; Choose random orientation in x, y, z

bx    = fltarr (n_particles)
by    = fltarr (n_particles)
bz    = fltarr (n_particles)
xlong = fltarr (n_particles)
xlat  = fltarr (n_particles)

for ii = 0, n_particles -1 do begin
   bsq = 1.d30
   while (bsq gt 1.d0) do begin                 ; Try again if not inside unit sphere
 
      bx (ii) = 2.d0 * randomu (seed, 1) - 1.d0      ; Trick to avoid
      by (ii) = 2.d0 * randomu (seed, 1) - 1.d0      ; evaluation of trig.
      bz (ii) = 2.d0 * randomu (seed, 1) - 1.d0      ; functions

      bsq = bx (ii) * bx (ii) + by (ii) * by (ii) + bz (ii) * bz (ii)   ; Radius ** 2 in unit cube

      bmag = sqrt (bsq)                         ; Get vector from origin to point 
   endwhile

   bx (ii) = bx (ii) / bmag
   by (ii) = by (ii) / bmag
   bz (ii) = bz (ii) / bmag

   rect_coord = [bx (ii), by (ii), bz (ii)]
   sphere_coord = CV_COORD (From_Rect=rect_coord, /To_sphere, /degrees) ; [longitude, latitude, radius]

;   print, rect_coord
;   print, sphere_coord ; [longitude, latitude, radius]

   xlong (ii) = sphere_coord (0)
   xlat  (ii) = sphere_coord (1)

endfor

for ii = 0, n_particles - 1 do begin

; Calculate the distance between two points on a sphere
; http://www.exelisvis.com/docs/MAP_2POINTS.html
;
; B = [ -105.19, 40.02]   ; Longitude, latitude in degrees.
; L = [ -0.07,   51.30]   ; Longitude, latitude in degrees.

; Define distance in km 

   dist = fltarr (n_elements (earth_long))

   for jj = 0, n_elements (earth_long) -1 do begin
      dist (jj) = MAP_2POINTS (xlong [ii], xlat (ii), earth_long (jj), earth_lat (jj), radius = 6371.)
   endfor

   min_dist = min (dist)

   if (min_dist ge thresh_dist) then begin
      i_thresh (ii) = 1  ; Out of reach
   endif
endfor

index = where (i_thresh eq 1)
frac_outside = float (n_elements (index)) / float (n_particles)
frac_inside = 1. - frac_outside

fmt = "('Crater Area = ', f5.1, '% for dist. threshold = ', f5.1, ' km')" 
text = string (fo = fmt, 100. * frac_inside, thresh_dist)

window, xsize = 1000, ysize = 500

map_set, 0., 0., /robinson, /grid, /isotropic, /noerase, $
     charsize = 1.5, color = 7

MAP_CONTINENTS, /FILL_CONTINENTS, COLOR = 13

plotsym, 0, 1.0, /fill

oplot, earth_long, earth_lat, color = 4, psym = 8 

plotsym, 0, 1.0, /fill
index = where (i_thresh eq 1)
; oplot, xlong (index), xlat (index), color = 3, psym = 3 

index = where (i_thresh eq 0)
oplot, xlong (index), xlat (index), color = 5, psym = 8 

plotsym, 0, 1.0, /fill
oplot, earth_long, earth_lat, color = 4, psym = 8 

print, delta_dist (j1), diam_crater_thresh (j2), age_thresh (j3), frac_inside
printf, 6, delta_dist (j1), diam_crater_thresh (j2), age_thresh (j3), frac_inside

; xyouts, 0., 80., text, charsize = 2.0, color = 10, alignment = 0.5 

; delta_dist = [500., 550., 600, 650.]
; diam_crater_thresh = [8.]
; age_thresh = [0.]

fmt5 = '("map_earth_crater_delta_", i3.3, "_dth_", i2.2, "_age_", i2.2, ".png")'
filename = string (fix (delta_dist (j1)), fix (diam_crater_thresh (j2)), fix (age_thresh (j3)), fo = fmt5)
saveimage, filename, /png

endfor
endfor
endfor

close, 2

stop
end
