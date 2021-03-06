## ----fig.width=9, fig.height = 9----------------------------------------------
library(rbgm)
library(bgmfiles)

## turn +proj into line separated text
breakproj <- function(x) {
  paste(strsplit(x, " ")[[1]], collapse = "\n")
}
files <- bgmfiles()
for (i in seq_along(files)) {
  bgm <- bgmfile(files[i])
  boxes <- boxSpatial(bgm)
  plot(boxes, col = ifelse(boxes$boundary, "#88888880", sample(rainbow(nrow(boxes), alpha = 0.5))))
  op <- par(xpd = NA)
  par(op)
  title(basename(files[i]), cex = 0.8)
  mtext(breakproj(proj4string(boxes)), cex = 0.75, side = 2, las = 1, adj = 0, line = 2, at = par("usr")[3], xpd = NA)
 
}



## ---- eval = FALSE------------------------------------------------------------
#  library(rbgm)
#  library(bgmfiles)
#  library(mapview)
#  
#  
#  mp <- mapview()  ## empty map view
#  
#  fs <- bgmfiles::bgmfiles()  ## paths of all files collected
#  cols <- rainbow(length(fs), alpha = 0.2)
#  ## read in all boxes, convert to SpatialPolygonsDataFrame, and add to the map view
#  for (i in seq_along(fs)) {
#    mp <- mp + mapview(boxSpatial(bgmfile(fs[i])), color = cols[i], alpha = 0.3, layer.name = basename(fs[i]))
#  }
#  
#  ## view the mapview
#  mp
#  

