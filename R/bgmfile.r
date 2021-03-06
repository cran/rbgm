

#' Read BGM
#'
#' Read geometry and full topology from BGM files. 
#' 
#' BGM is a file format used for the 'Box Geometry Model' in the Atlantis Ecosystem Model. 
#' This function reads everything from the .bgm file and returns it as linked tables. 
#' @param x path to a bgm file
#' @param ... ignored for now
#'
#' @export
#' @seealso 
#' See helper functions to convert the bgm tables to `Spatial` objects, \code{\link{boxSpatial}}, 
#' \code{\link{faceSpatial}}, \code{\link{nodeSpatial}}, \code{\link{boundarySpatial}}, \code{\link{pointSpatial}}
#' @importFrom dplyr %>% select arrange bind_rows bind_cols distinct mutate inner_join
#' @importFrom utils  head type.convert
#' @examples 
#' library(bgmfiles)
#' bfile <- sample(bgmfiles(), 1L)
#' bgm <- bgmfile(bfile)
#' str(bgm)
bgmfile <- function(x, ...) {

  if (nchar(x) < 1) stop("file path is empty string")
  if (!file.exists(x)) mess <- stop(sprintf("no file found '%s'\n", x))
  #system.time(tx <- readLines(x)) 
  
  x0 <- readLines(x)
  if (all(nchar(x0) < 1)) {
    stop(sprintf("no lines found in file %s", x))
  }
  #browser()
  tx <- unlist(strsplit(x0, "\n")) ##[[1]]
  nch <- length(tx)
  if (nch == 0) {
    stop(sprintf("no lines found in file %s", x))
  }
  
  ## all indexes
  facesInd <- grep("^face", tx)
#  facesInd <- which(stringr::str_detect(tx, "^face"))
  boxesInd <- grep("^box", tx)
 # boxesInd <- which(stringr::str_detect(tx, "^box"))
  bnd_vertInd <- grep("^bnd_vert", tx)
#  bnd_vertInd <- which(stringr::str_detect(tx, "^bnd_vert"))
  ## all comments
  hashInd <- grep("^#", tx)
 #hashInd <- which(stringr::str_detect(tx, "^#")) 
  ## unique starting tokens
  ust <- sort(unique(unlist(lapply(strsplit(tx[-c(facesInd, boxesInd, bnd_vertInd, hashInd)], "\\s+"), "[", 1))))
  ust <- ust[nchar(ust) > 0]
  extra <- lapply(ust, function(x) gsub("\\s+$", "", gsub("^\\s+", "", gsub(x, "", grep(x, tx, value = TRUE)))))
  names(extra) <- ust

  ## some (most?) .bgm have PROJ.4 strings without "+" denoting arguments
  extra$projection <- fixproj(extra$projection)  # <- sprintf("+%s", gsub(" ", " +", extra["projection"]))
  ## nface is repeated in Guam_utm1.bgm
  
  ## numfaces by declaration in the file
  numfaces <- as.numeric(strsplit(extra["nface"][[1]], "\\s+")[[1]][1])
  ## actual numfaces is
  actual_numfaces <- length(unique(unlist(lapply(strsplit(tx[facesInd], "\\."), "[", 1L))))
  if (!numfaces == actual_numfaces) {
    cat(sprintf("%s \nfile declares %i faces but contains data for %i faces\n\n ... returning all %i faces", x, numfaces, actual_numfaces, actual_numfaces))
    
  }
  
  faceslist <- grepItems(tx[facesInd], "face", actual_numfaces)
  ## remove len, cs, lr from faceparse, all belong on the face not the face verts
  faceverts <-  dplyr::bind_rows(lapply(seq_along(faceslist), function(xi) {a <- facevertsparse(faceslist[[xi]]); a$.fx0 <- xi - 1; a}))
  faces <-   dplyr::bind_rows(lapply(seq_along(faceslist), function(xi) {a <-facedataparse(faceslist[[xi]]); a$.fx0 <- xi - 1; a}))
  faces$label <- unlist(lapply(faceslist, function(x) strsplit(x[1], "\\.")[[1]][1]))
  
  boxeslist <- grepItems(tx[boxesInd], "box", as.numeric(extra["nbox"]))
  boxes0 <- lapply(seq_along(boxeslist), function(xi) {a <- boxparse(boxeslist[[xi]]); a$.bx0 <- xi - 1; a})
  ## we only need boxverts for non-face boxes (boundary faces), but use to check data sense
  boxverts <- dplyr::bind_rows(lapply(seq_along(boxes0), function(xa) {aa <- boxes0[[xa]]$verts; .bx0 = rep(xa - 1, nrow(boxes0[[xa]]$verts)); aa$.bx0 <- .bx0; aa}))
  boxes<- dplyr::bind_rows( 
                  lapply(boxes0, function(a) dplyr::bind_cols(.as_tibble(a[["meta"]]), 
                                                              .as_tibble(a[c("insideX", "insideY", ".bx0")]))))
  ## ibox/iface are the component faces, and ibox the neighbouring box (.bx0 is the box we belong to!)
  facesXboxes <- dplyr::bind_rows(lapply(boxes0, "[[", "faces"), .id = ".bx0") %>% 
    dplyr::mutate(.bx0 = as.numeric(.data$.bx0) - 1)

  bnd_verts <- do.call(rbind, lapply(strsplit(tx[bnd_vertInd], "\\s+"), function(x) as.numeric(x[-1])))
  boundaryverts <- .mk_tibble(x = bnd_verts[,1], y = bnd_verts[,2], bndvert = seq(nrow(bnd_verts)))
  
  for (i in seq(ncol(boxes))) {
    if (is.character(boxes[[i]])) {
      boxes[[i]] <- type.convert(boxes[[i]], as.is = TRUE)
    }
  }
  
  ## OUTPUT
  ## vertices     x,y, .vx0
  ## facesXverts  .vx0, .fx0, .p0 ## .po is p1/p2 ends of face
  ## faces        .fx0, length, cos0, sin0, leftbox, rightbox  ## cos/sin rel. to (0, 0) left/right looking from p2
  ## facesXboxes  .bx0, .fx0
  ## boxesXverts  .bx0, .vx0
  ## boxes        .bx0, label, insideX, insideY, nconn, botz, area, vertmix, horizmix
  
  
  
  ## I think bnd_verts already all included in box_verts
  vertices <- bind_rows(faceverts[, c("x", "y")], boxverts[, c("x", "y")], boundaryverts[, c("x", "y")]) %>% 
    distinct() %>% dplyr::arrange(.data$x, .data$y) %>% mutate(.vx0 = row_number())
  
  facesXverts <- faceverts %>% mutate(.p0 = rep(1:2, length = nrow(faceverts)))  %>% inner_join(vertices, c("x" = "x", "y" = "y")) %>% 
    dplyr::select(-.data$x, -.data$y)
  
  boxesXverts <- boxverts %>% inner_join(vertices, c("x" = "x", "y" = "y")) %>% dplyr::select(-.data$x, -.data$y)
  
  # allverts <- allverts %>% select(x, y)
  list(vertices = vertices, facesXverts = facesXverts, faces = faces, facesXboxes = facesXboxes, boxesXverts = boxesXverts, boxes = boxes, boundaryvertices = boundaryverts, extra = extra)
}


#' @name bgmfile
#' @export
read_bgm <- function(x, ...) {
  bgmfile(x, ...)
}

