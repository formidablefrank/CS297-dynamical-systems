globals [
;;  L    ;; # of lightning strikes
;;  Temp ;; Temperature [0-9]
;;  T    ;; Time to dry after storm
;;  P    ;; Precipitation (# of storms)
  Fc   ;; Flammability coefficient (= maximum patch flamability; each pixel's flammability
       ;;   still depends on age as well, and approaches F over time)
  B    ;; Burnable days
  N    ;; # of lightning strikes hitting dry veg this burning season
;;  lag  ;; # of years after burn before a pixel has any chance of reburn
;;  mat_age ;; forest time to maturity
  fire_speed ;; how fast is the visualization of fire spread? (1-100 fps)
  aab ;; annual area burned
  anf ;; annual number of fires
  x   ;; dummy variable
  K   ;; flammability parameter
  p   ;; temporary prob variable
  j   ;; temporary prob variable
;;  g   ;; immunity parameter
]

patches-own [f age lag_age] ;; patch-specific flamability & age
breed [fires fire]
breed [embers ember]


to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set-default-shape turtles "square"


  ;; setup variables
  set fire_speed 500
  set Fc (Fm / 100)
  set x -1


  ;; setup patches.  They all start as fully mature forest.
  ask patches [
    set pcolor 52
    set age Mature_Age
    set f Fc ;; set each patch's flamability to maximum
  ]

end


to go
  ;; Setup variables (these are done in "go" so that they can change based on new user input
  ;;   without resetting the forest

  set B (max list (Fire_Season_Length - Dry_time * Precipitation) 0)
  set N (round (Lightning * B / Fire_Season_Length))
  set K ((Mature_Age - Fc * Mature_Age) / Fc)
  set aab 0
  set anf 0

  ;; Check if fire possible, warn if not
  ifelse N = 0 [
    if x != 0 [ ;; first warning
      print "*** Lightning will never strike on a dry day with these parameters! ***"
      beep
      set x 0
    ]
  ][
    if x != N [
      set x N
      type "There are currently "
      type N
      print " lightning strikes per season on days when the forest is dry enough to burn."
    ]
  ]

  ask n-of N patches [
    if (random-float 1) < f [
      set anf (anf + 1)
      ignite
    ]
  ]

  suppress
  spread
  grow
  do-plots
  tick
  wait 0.5
end


to ignite
    sprout-fires 1 [set color red]
    set age 0
    set lag_age 0
    set pcolor black ;; burned patches turn grey
    set aab (aab + 1)
end

to spread
  while [any? turtles] [;; either fires or embers
    every (1.01 - fire_speed * 0.01) [
      ;; first, have fires try to spread
      ask fires [
          ask neighbors4 [
            if age != 0 [
              set j sum[count fires-here] of neighbors4
              set p (1 - g ^ j)
              ;type n
              ;type ", "
              ;type p
              if random-float 1 < p [
                ignite
                ;type " ignite"
              ]
              ;print " end"
            ]
          ]
        set breed embers
      ]
      ;; then burn embers down
      ask embers [
        set color color - 0.3 ;; make red darker
        if color < red - 3.5 [die] ;; almost to black? then kill the ember
      ]
    ]
  ]

end

to grow
  ask patches [
    ifelse age = 0 [
      set lag_age (lag_age + 1)
      if lag_age > 1 [set pcolor 33] ;; patch turns brown after first year
      if lag_age > lag [set age 1] ;; start regrowth next year
    ][
      ;; for all patches older than lag
      ifelse pcolor < 50 [
        set pcolor 59  ;; if it's first year of growth, turn green
        ][
        set pcolor max list (pcolor - 7 / Mature_Age) 52 ;; otherwise darken a bit (darkest = 52)
      ]
      set age (age + 1)
    ]

    ;; set flammability
    ifelse age = 0 [ ;; no burning during lag phase
      set f 0
    ][
      set f (Fc * age / Mature_Age)
    ]
  ]
end

to do-plots
  set-current-plot "Annual Area Burned"
  set-current-plot-pen "Annual Area Burned"
  plot aab
  set-current-plot "Number of Fires"
  set-current-plot-pen "Number of Fires"
  plot anf
  set-current-plot "Frequency-Size Distribution"
  set-current-plot-pen "Frequency-Size Distribution"
  plotxy anf aab
end

to suppress
  let extinguish 1
  while [(extinguish < 2 * Suppression) and ((count fires) > 1)] [
    ask fires [
      if (random-float 1) > (([f] of patch-here) * extinguish / Suppression / 2) [
        set breed embers
        set extinguish (extinguish + 1)
      ]
    ]
  ]
end

to reset-params
  set g 0.7
  set Lightning 10
  set Dry_time 0
  set Precipitation 0
  set Fm 20
  set Fire_Season_Length 120
  set Mature_Age 5
  set Lag 1
  set Suppression 0
end
@#$#@#$#@
GRAPHICS-WINDOW
345
10
759
445
-1
-1
4.0
1
10
1
1
1
0
0
0
1
0
100
0
100
0
0
1
ticks
30.0

BUTTON
8
10
114
43
Setup Model
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
167
342
200
Lightning
Lightning
0
60
10
1
1
Strikes per season (wet and dry days)
HORIZONTAL

SLIDER
4
202
342
235
Dry_time
Dry_time
0
10
0
.2
1
Days to dry after storm
HORIZONTAL

SLIDER
4
237
342
270
Precipitation
Precipitation
0
100
0
1
1
Rainy days per season
HORIZONTAL

SLIDER
4
272
342
305
Fm
Fm
0
100
20
1
1
% Chance of mature forest catching fire
HORIZONTAL

SLIDER
4
307
342
340
Fire_Season_Length
Fire_Season_Length
0
365
120
1
1
days
HORIZONTAL

BUTTON
8
48
114
81
NIL
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
4
451
759
571
Annual Area Burned
NIL
NIL
0.0
100.0
0.0
1000.0
true
false
"" ""
PENS
"Annual Area Burned" 1.0 1 -16777216 true "" ""

SLIDER
4
342
342
375
Mature_Age
Mature_Age
0
200
5
1
1
Years until "mature"
HORIZONTAL

SLIDER
4
377
342
410
Lag
Lag
0
20
1
1
1
Years before regrowth begins
HORIZONTAL

SLIDER
4
412
342
445
Suppression
Suppression
0
100
0
1
1
= Power of fire suppression
HORIZONTAL

PLOT
4
575
759
695
Number of Fires
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"Number of Fires" 1.0 1 -16777216 true "" ""

BUTTON
199
30
337
63
Reset Parameters
reset-params
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
764
10
1297
444
Frequency-Size Distribution
freq
area
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Frequency-Size Distribution" 1.0 0 -7500403 true "" "plotxy anf aab"

SLIDER
4
132
342
165
g
g
0
1
0.7
0.05
1
Immunity parameter (1=immune)
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a simplified but reasonable model of wildfire occurrence intended for use as an educational tool.  It has specific applications to wildfire ecology and management, but primarily serves as an example of the complex effects possible when many variables interact to produce a result, and the important role models can play in experimenting with such a system.

## HOW IT WORKS

The model calculates the number of lightning strikes occurring on dry days, based on the length of the fire season, the number of days it rains, the time it takes for the landscape to dry after a rain, and the number of lightning strikes per season.

Each lightning strike occurring on a dry day then has a certain probability of igniting a fire, which is based on the age of the patch of forest struck, and the flamability (Fm) of the forest type.  Ignited fires spread from patch to patch based on the same parameters.

As in a real forest, a patch can't burn for a certain amount of time after it's burned already (set by variable Lag).  In addition, forests become more flammable as they age, modeled by the Mature_Age variable; the longer it takes to reach Mature_Age, the slower the flammability of the forest increases.

Finally, the model includes an approximation of (human) fire suppression effort.  The higher the value of the Suppression variable, the more burning pixels will be targeted for suppression (whether suppression is successful is random).  As a result of this design, even a small amount of suppression will likely be effective as long as there are only a few burning pixels.  If a fire chances to get rather large, however, the suppression effort quickly becomes ineffective.

## HOW TO USE IT

"Setup" and "Go" buttons work as usual, and "Reset Parameters" returns all parameters to their default values.

All parameters can be modified in real time.  A message in the command center lets you know how many dry-day lightning strikes are occurring each year (one time step), and alerts you if your parameters are such that fire is impossible.

The plots keep track of the number of individual fires per year, as well as the area burned each year.

## THINGS TO NOTICE

Notice that the different variables all affect fire occurrence in their own way, and that different ones may enhance or negate each other.  There are many ways to produce huge or very frequent fires, or to stop fire occurrence altogether.  Most natural ecosystems fall somewhere in between, highlighting their delicate balance of vegetation species, climate, and fire occurrence.

## THINGS TO TRY

Model the effects of intense fire suppression: A potential concern of fire managers arises from the increasing flamability of forests the longer they go without burning (this arises from accumulation of dead plant fuels).  If parameters are adjusted such that suppression makes a large fire extremely unlikely, but not impossible, eventually a fire will get out of hand...

Model scenarios in which multiple parameters change: What happens if a new climate system arises that increases both the amount of lightning and the number of rainy days?  And what if the temperature (Dry_time) is changing too?  To what extent do these different parameters outwheigh one another?  Arrival or evolution of new vegetation could have similar effects, changing Fm, Mature_Age, and Lag variables simultaneously.
In nature, such situations often arise, in which the obvious effects of one variable are confounded by (sometimes surprising) influence of another.

## EXTENDING THE MODEL

The mechanisms of the model were written to produce "reasonable" results, but don't really reflect the current understanding of mechanisms which really drive wildfire ignition and spread.  One might want to try implementing the same parameters (and perhaps others) with more mechanistically accurate mathematical models.

Specific scenarios could be designed for use in a classroom setting, and then the output data (# and area of fires) could be used in a quantitative assessment of the effects of certain parameter combinations.

## RELATED MODELS

Fire, Percolation, Rumor Mill

## CITING THIS MODEL

To refer to this model in academic publications, please use: Kelly, R. (2009). NetLogo Fire Ecology model. Department of Plant Biology, University of Illinois, Urbana, IL.

In other publications, please use: Copyright 2009 Ryan Kelly. All rights reserved.

## ACKNOWLEDGEMENTS

The visual technique for representing fire was borrowed from an existing NetLogo model:

"Fire" Copyright 1997 Uri Wilensky. All rights reserved. See http://ccl.northwestern.edu/netlogo/models/Fire for terms of use.

This model was designed and as part of a National Science Foundation GK-12 fellowship.

Special thanks to Susan Camasta and the 2008-09 Hinsdale South AP Environmental Science classes for testing and evaluation of this model as a teaching aid.

## QUESTIONS AND COMMENTS

Please send questions and comments to: rkelly AT life DOT illinois DOT edu
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
