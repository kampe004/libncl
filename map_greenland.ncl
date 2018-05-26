; 
; Utilities for map plotting over greenland 
; The functions and procedures are designed to produce a SINGLE figure
;
; Multiplot routines for creating panels are found in map_panelling.ncl
;
undef("size")
function size(x)
local n
begin
   n = num(.not.ismissing(x))
   return n
end


;********************************************************
undef("getGreenlandMapProjection")
; 
; internal function
;
;********************************************************
function getGreenlandMapProjection(wks,res)
local plot, res1
begin
   res1 := res
	res1@gsnDraw  	= False
	res1@gsnFrame  	= False

   res1@mpFillOn = False    ; normally, land is colored grey
   ;res@mpOutlineOn = False ; when Fill is disabled, coastlines are drawn
   res1@mpFillColors = (/"background","transparent","LightGray","transparent"/); (..., Ocean, Land, InlandWater)
   
   if (.not. isatt(res, "mpGeophysicalLineColor")) then
      res1@mpGeophysicalLineColor = "gray50"
   end if

   if (.not. isatt(res, "mpGeophysicalLineThicknessF")) then
      res1@mpGeophysicalLineThicknessF = 2 ;  Changes the thickness of continental outlines.
   end if

	; force lat/lon lines
 	;res1@mpGridAndLimbOn = False
 	res1@mpGridAndLimbOn = True
   res1@mpGridLineDashPattern  = 2                  ; lat/lon lines dashed
   res1@mpGridLatSpacingF      = 5.
   res1@mpGridLonSpacingF      = 10.
   res1@mpGridPolarLonSpacingF = 10.
	;res@pmTickMarkDisplayMode  = "Always" ; DISABLED: custom tick labels below

  	plot = gsn_csm_map(wks,res1)        ; draw global map

	return plot
end


;********************************************************
undef("getGreenlandMapRes")
; 
; Returns map of Greenland (graphics object) with land filled in
;
;********************************************************
function getGreenlandMapRes(wks,res1)
local plot, res
begin
   res = res1
   res@mpLimitMode            = "LatLon"           ; method to zoom
   res@mpMaxLatF              = 84
   res@mpMinLatF              = 59.5
   res@mpMaxLonF              = -27
   res@mpMinLonF              = -54.5
	res@mpPerimOn 					= True
   res@mpProjection           = "Stereographic"
   res@mpCenterLonF           = -40.
   res@mpCenterLatF           = 50.
	res@mpDataBaseVersion = "MediumRes"

   res@tiXAxisOn  = False
   res@tiYAxisOn  = False

   plot =  getGreenlandMapProjection(wks,res)
   return plot
end


;********************************************************
undef("getGreenlandMap")
; 
; Returns map of Greenland (graphics object) with land filled in
;
;********************************************************
function getGreenlandMap(wks)
local plot, res
begin
	res = True
   return getGreenlandMapRes(wks,res)
end



;********************************************************
undef("overlayHeightRes")
; 
; overlay height contour lines
; custom res
;
;********************************************************
procedure overlayHeightRes(wks, plot_id, topo, res)
local height1, resh
begin
   resh = res

   ; -------------------------
   ; height contour lines every 1000m
   ; -------------------------
   resh@cnLinesOn              = True   ; contour lines
   resh@cnInfoLabelOn          = False  
   resh@cnLineLabelsOn         = False
   resh@cnLevelSelectionMode   = "ExplicitLevels"
   ;resh@cnLevels               = (/ 0., 1000., 2000., 3000., 4000./)
   resh@cnLevels               = (/ 0., 500, 1000., 1500., 2000., 2500., 3000., 3500., 4000./)
   resh@cnLineDashPattern     = 2 ; dashed
   resh@cnLineColor           = "grey60" ; LvK: make contour lines lighter

   resh@gsnLeftString        = ""
   resh@gsnRightString        = ""
   resh@gsnFrame               = False
   resh@gsnDraw                = False

   resh@tiXAxisOn  = False
   resh@tiYAxisOn  = False

   height1 = gsn_csm_contour(wks,topo,resh)
   overlay(plot_id, height1)
end


;********************************************************
undef("overlayHeight")
; 
; overlay height contour lines
;
;********************************************************
procedure overlayHeight(wks, plot_id, topo)
local height1, resh
begin
   resh = True
   overlayHeightRes(wks,plot_id,topo,resh)
end

 
;********************************************************
undef("overlayMargin")
; 
; overlay ice sheet margin 
;
;********************************************************
procedure overlayMargin(wks, plot_id, margin)
local margin1, resm
begin 

   ; -------------------------
   ; ice sheet margin
   ; -------------------------
   resm = True
   resm@cnLinesOn              = True   ; contour lines
   resm@cnInfoLabelOn          = False  
   resm@cnLineLabelsOn         = False
   resm@cnLevelSelectionMode   = "ExplicitLevels"

   resm@cnLineDashPattern     = 0 ; solid
   resm@cnLineColor           = "red"
   resm@cnLevels              := (/ 0.5 /)
   resm@cnLineThicknessF      = 2.0

   resm@gsnLeftString        = ""
   resm@gsnRightString        = ""
   resm@tiXAxisOn  = False
   resm@tiYAxisOn  = False

   resm@gsnFrame               = False
   resm@gsnDraw                = False

   margin1 = gsn_csm_contour(wks,margin,resm)
   overlay(plot_id, margin1)
end
	

;********************************************************
undef("overlayHeightAndMargin")
; 
; overlay height contour lines and ice sheet edge
;
;********************************************************
procedure overlayHeightAndMargin(wks, plot_id, topo, margin)
begin
   overlayHeight(wks, plot_id, topo)
   overlayMargin(wks, plot_id, margin)
end


;********************************************************
undef("overlayNoLabelbar")
; 
; Overlay existing plot, no labelbar
;
;********************************************************
procedure overlayNoLabelbar(wks, plot_id, field, res)
local res1, contour
begin
   res1 := res
   res1@lbLabelBarOn           = False
 
   contour = gsn_csm_contour(wks,field,res1)
   overlay(plot_id, contour)
end




;********************************************************
undef("overlayLeftLabelbarPos")
; 
; allows the specification of pmLabelBarOrthogonalPosF (pos)
;
;********************************************************
procedure overlayLeftLabelbarPos(wks, plot_id, field, res, pos)
local res1, contour
begin
   res1 := res
   res1@lbLabelBarOn             = True
   res1@lbOrientation            = "Vertical"        ; orientation
   res1@lbLabelPosition          = "Left"
   res1@pmLabelBarOrthogonalPosF = pos ; move labelbar to left 

   res1@lbTopMarginF             = 0.0
   res1@lbBottomMarginF          = 0.0

   res1@lbFillColors             := span_color_rgba(res@cnFillPalette,size(res@cnLevels)+1); must be RGB triplets
   res1@lbLabelAlignment         = "InteriorEdges"
   res1@lbBoxCount               = size(res@cnLevels)+1
   ;res1@lbLabelFontHeightF      = 0.008
   res1@lbBoxEndCapStyle         = "TriangleBothEnds"
   ;res1@lbLabelFontHeightF       = 0.025 ; moved to resources.ncl to enable overriding

   res1@lbTitlePosition          = "Left"
   ;res1@lbTitleExtentF          = 0.3
   ;res1@lbTitleOffsetF          = 0.15
   res1@lbTitleAngleF            = 90.
   res1@lbTitleDirection         = "Across"
;   res1@lbTitleOn               = False
;   res1@lbTitleString           = lbres@lbTitleString
   res1@lbTitleFontHeightF       = 0.025
   res1@lbTitleFont              = 21

   contour = gsn_csm_contour(wks,field,res1)
   overlay(plot_id, contour)
end


;********************************************************
undef("overlayLeftLabelbar")
; 
; Overlay existing plot, with labelbar on the left side
;
;********************************************************
procedure overlayLeftLabelbar(wks, plot_id, field, res)
begin
   pos = -1.25 ; move labelbar to left
   overlayLeftLabelbarPos(wks, plot_id, field, res, pos)
end
 
 

;********************************************************
undef("overlayRightLabelbar")
; 
; Overlay existing plot, with labelbar on the left side
;
;********************************************************
procedure overlayRightLabelbar(wks, plot_id, field, res)
local res1, contour
begin
   res1 := res
   res1@lbLabelBarOn             = True
   res1@lbOrientation            = "Vertical"        ; orientation
   res1@lbLabelPosition          = "Right"
   ;res1@pmLabelBarOrthogonalPosF = -1.2 ; move labelbar to left 

   res1@lbTopMarginF             = 0.0
   res1@lbBottomMarginF          = 0.0

   res1@lbFillColors             := span_color_rgba(res@cnFillPalette,size(res@cnLevels)+1); must be RGB triplets
   res1@lbLabelAlignment         = "InteriorEdges"
   res1@lbBoxCount               = size(res@cnLevels)+1
   ;res1@lbLabelFontHeightF      = 0.008
   res1@lbBoxEndCapStyle         = "TriangleBothEnds"
   ;res1@lbLabelFontHeightF       = 0.025 ; moved to resources.ncl to enable overriding

   res1@lbTitlePosition          = "Right"
   ;res1@lbTitleExtentF          = 0.3
   ;res1@lbTitleOffsetF          = 0.15
   res1@lbTitleAngleF            = 90.
   res1@lbTitleDirection         = "Across"
;   res1@lbTitleOn               = False
;   res1@lbTitleString           = lbres@lbTitleString
   res1@lbTitleFontHeightF       = 0.025
   res1@lbTitleFont              = 21

   contour = gsn_csm_contour(wks,field,res1)
   overlay(plot_id, contour)
end
 

;********************************************************
undef("overlayBottomLabelbar")
; 
; Overlay existing plot, with labelbar on the bottom
;
;********************************************************
procedure overlayBottomLabelbar(wks, plot_id, field, res)
local res1, contour
begin
   res1 := res
   res1@lbLabelBarOn             = True
   res1@lbOrientation            = "Horizontal"        ; orientation
   res1@lbLabelPosition          = "Bottom"
   ;res1@pmLabelBarOrthogonalPosF = -1.2 ; move labelbar to left 

   ;res1@lbTopMarginF             = 0.0
   ;res1@lbBottomMarginF          = 0.0

   res1@lbFillColors             := span_color_rgba(res@cnFillPalette,size(res@cnLevels)+1); must be RGB triplets
   res1@lbLabelAlignment         = "InteriorEdges"
   res1@lbBoxCount               = size(res@cnLevels)+1
   res1@lbBoxEndCapStyle         = "TriangleBothEnds"
   ;res1@lbLabelFontHeightF       = 0.025 ; moved to resources.ncl to enable overriding

   res1@lbTitlePosition          = "Bottom"
   ;res1@lbTitleExtentF          = 0.3
   ;res1@lbTitleOffsetF          = 0.15
   ;res1@lbTitleAngleF            = 90.
   ;res1@lbTitleDirection         = "Across"
;   res1@lbTitleOn               = False
;   res1@lbTitleString           = lbres@lbTitleString
   res1@lbTitleFontHeightF       = 0.025
   res1@lbTitleFont              = 21

   contour = gsn_csm_contour(wks,field,res1)
   overlay(plot_id, contour)
end
 
 
;********************************************************
undef("getGreenlandMapLatLonLabels")
; 
; Returns map of Greenland (graphics object) with lat/lon labels
;
;********************************************************
function getGreenlandMapLatLonLabels(wks)
local plot, txres
begin
   plot = getGreenlandMap(wks)

   txres               = True                      ; text mods desired
   txres@txFontHeightF = 0.012                     ; text font height
   txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".
   ;txres@txBackgroundFillColor = "White"
   txres@txFont                = "helvetica"


   ; ADD LABELS
   lab1 = gsn_create_text(wks,"60~F34~0~F~ N",txres)
	annoid = NhlAddAnnotation(plot,lab1)

  	setvalues annoid
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.05            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab2 = gsn_create_text(wks,"65~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab2)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.25            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab3 = gsn_create_text(wks,"70~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab3)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.47            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab4 = gsn_create_text(wks,"75~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab4)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.69            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab5 = gsn_create_text(wks,"80~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab5)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.95            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab6 = gsn_create_text(wks,"50~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab6)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.15            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab7 = gsn_create_text(wks,"40~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab7)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.52            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab8 = gsn_create_text(wks,"30~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab8)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.90            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues
   return plot
end


;********************************************************
undef("getLargeGreenlandMap")
; 
; Returns map of the larger Greenland area
;
;********************************************************
function getLargeGreenlandMap(wks)
local plot
begin
   res = True
   res@mpLimitMode                 = "LatLon"           ; method to zoom
   res@mpMaxLatF                   = 85
   res@mpMinLatF                   = 56
   res@mpMaxLonF                   = -25
   res@mpMinLonF                   = -60
   res@mpPerimOn              = True
   ;res@mpGridMaskMode         = "MaskFillArea"
   res@mpProjection           = "Stereographic"
   res@mpCenterLonF           = -40.
   res@mpCenterLatF           = 50.
   res@mpDataBaseVersion = "MediumRes"            ; choose higher resolution

   plot = getGreenlandMapProjection(wks,res)

   txres               = True                      ; text mods desired
   txres@txFontHeightF = 0.012                     ; text font height
   txres@txJust        = "CenterLeft"              ; Default is "CenterCenter".
   ;txres@txBackgroundFillColor = "White"
   txres@txFont                = "helvetica"


   ; ADD LABELS
   lab1 = gsn_create_text(wks,"60~F34~0~F~ N",txres)
	annoid = NhlAddAnnotation(plot,lab1)

  	setvalues annoid
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.19            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab2 = gsn_create_text(wks,"65~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab2)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.38            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab3 = gsn_create_text(wks,"70~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab3)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.58            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab4 = gsn_create_text(wks,"75~F34~0~F~ N",txres)
	annoid2 = NhlAddAnnotation(plot,lab4)

  	setvalues annoid2
 	  "amSide" 			   : "Left"
  	  "amZone"           : 2
  	  "amParallelPosF"   : 0.78            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.02            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab6 = gsn_create_text(wks,"50~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab6)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.27            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab7 = gsn_create_text(wks,"40~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab7)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.58            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues

   lab8 = gsn_create_text(wks,"30~F34~0~F~ W",txres)
	annoid2 = NhlAddAnnotation(plot,lab8)

  	setvalues annoid2
 	  "amSide" 			   : "Bottom"
  	  "amZone"           : 3
  	  "amParallelPosF"   : 0.88            ; Center labelbar.
  	  "amOrthogonalPosF" : 0.01            ; Move down, away from plot
  	  "amResizeNotify"   : True           ; Allow resize if plot resized.
  	end setvalues


   return plot
end

;********************************************************
undef("getHugeGreenlandMap")
; 
; Returns map of Greenland (graphics object) with land filled in
;
;********************************************************
function getHugeGreenlandMap(wks)
local plot, res
begin
	res = True
   res@mpLimitMode            = "LatLon"           ; method to zoom
   res@mpMaxLatF                   = 85
   res@mpMinLatF                   = 50
   res@mpMaxLonF                   = -10
   res@mpMinLonF                   = -85
	res@mpPerimOn 					= True
   res@mpProjection           = "Stereographic"
   res@mpCenterLonF           = -40.
   res@mpCenterLatF           = 50.
	res@mpDataBaseVersion = "MediumRes"

   res@tiXAxisOn  = False
   res@tiYAxisOn  = False

   plot =  getGreenlandMapProjection(wks,res)
   return plot
end



undef("DisableIfYouWishToTest")
function DisableIfYouWishToTest() ; comment this line to make a program
local wks, pplot
begin
 	wks  = gsn_open_wks("pdf","map_greenland")    ; send graphics to PNG file
 
    pplot = new(3, graphic)
 	;plot1 = getGreenlandMap(wks)
 	;plot2 = getGreenlandMap(wks)

 	pplot(0) = getLargeGreenlandMap(wks)
 	pplot(1) = getLargeGreenlandMap(wks)
 	pplot(2) = getLargeGreenlandMap(wks)
 
 	pres = True
 	pres@gsnMaximize = True
   pres@gsnFrame = False

 	gsn_panel(wks,pplot,(/1,1/),pres)
   drawNDCGrid(wks)
 
 	;draw(plot)
 	frame(wks)
 
    ;; Retrieve the bounding box of the given object.
    ;bb  = NhlGetBB(plot)
    ;top = bb(0)
    ;bot = bb(1)
    ;lft = bb(2)
    ;rgt = bb(3)
 
    ;; Make a box with the bounding box values.
    ;xbox = (/rgt,lft,lft,rgt,rgt/)
    ;ybox = (/top,top,bot,bot,top/)
 
    ;; Set up some line resources.
    ;lnres                   = True
    ;lnres@gsLineColor       = "Brown"
    ;lnres@gsLineThicknessF  = 2.5
 
    ;; Draw a box showing the bounding box.
    ;gsn_polyline_ndc(wks,xbox,ybox,lnres)
 
 	;maximize_output(wks,True)
 
end
