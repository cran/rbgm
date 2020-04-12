## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)
library(raster)
library(sp)
library(dplyr)

## -----------------------------------------------------------------------------
library(rbgm)
library(dplyr)
mfile <- bgmfiles::bgmfiles()[1]

bgm <- bgmfile(mfile)

names(bgm)

## -----------------------------------------------------------------------------
print(bgm$boxes)

## -----------------------------------------------------------------------------
print(bgm$faces)

## -----------------------------------------------------------------------------
bgm$boxes %>% 
  filter(label %in% c("Box1", "Box11"))  %>% 
  inner_join(bgm$boxesXverts, ".bx0") %>% 
  head()


## -----------------------------------------------------------------------------
boxes <- subset(boxSpatial(bgm), label %in% c("Box2", "Box16"))

## -----------------------------------------------------------------------------
allfaces <- faceSpatial(bgm)
faces <- allfaces[match(bgm$facesXboxes$iface[which(bgm$facesXboxes$.bx0 %in% boxes$.bx0)], allfaces$.fx0), ]


## -----------------------------------------------------------------------------
plot(boxes, main = "boxes only")
text(coordinates(boxes), lab = sprintf("%s\nnconn: %s", boxes$label, boxes$nconn))

plot(boxes, main = "boxes and faces overlaid")
text(coordinates(boxes), lab = sprintf("%s\nnconn: %s", boxes$label, boxes$nconn))
plot(faces, col = c("firebrick"), lwd = 1, add = TRUE)

