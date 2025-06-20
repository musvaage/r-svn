#  File src/library/graphics/R/fourfoldplot.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 1995-2016 The R Core Team
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  https://www.R-project.org/Licenses/

fourfoldplot <-
function(x, color = c("#99CCFF", "#6699CC"), conf.level = 0.95,
         std = c("margins", "ind.max", "all.max"), margin = c(1, 2),
         space = 0.2, main = NULL, mfrow = NULL, mfcol = NULL)
{
    ## Code for producing fourfold displays.
    ## Reference:
    ##   Friendly, M. (1994).
    ##   A fourfold display for 2 by 2 by \eqn{k} tables.
    ##   Technical Report 217, York University, Psychology Department.
    ##   http://www.math.yorku.ca/SCS/Papers/4fold/4fold.ps.gz
    ##
    ## Implementation notes:
    ##
    ##   We need plots with aspect ratio FIXED to 1 and glued together.
    ##   Hence, even if k > 1 we prefer keeping everything in one plot
    ##   region rather than using a multiple figure layout.
    ##   Each 2 by 2 pie is is drawn into a square with x/y coordinates
    ##   between -1 and 1, with row and column labels in [-1-space, -1]
    ##   and [1, 1+space], respectively.  If k > 1, strata labels are in
    ##   an area with y coordinates in [1+space, 1+(1+gamma)*space],
    ##   where currently gamma=1.25.  The pies are arranged in an nr by
    ##   nc layout, with horizontal and vertical distances between them
    ##   set to space.
    ##
    ##   The drawing code first computes the complete are of the form
    ##     [0, totalWidth] x [0, totalHeight]
    ##   needed and sets the world coordinates using plot.window().
    ##   Then, the strata are looped over, and the corresponding pies
    ##   added by filling rows or columns of the layout as specified by
    ##   the mfrow or mfcol arguments.  The world coordinates are reset
    ##   in each step by shifting the origin so that we can always plot
    ##   as detailed above.

    if(!is.array(x))
        stop("'x' must be an array")
    if(length(dim(x)) == 2L) {
        x <- if(is.null(dimnames(x)))
            array(x, c(dim(x), 1L))
        else
            array(x, c(dim(x), 1L), c(dimnames(x), list(NULL)))
    }
    if(length(dim(x)) != 3L)
        stop("'x' must be 2- or 3-dimensional")
    if(any(dim(x)[1L:2L] != 2L))
        stop("table for each stratum must be 2 by 2")
    dnx <- dimnames(x)
    if(is.null(dnx))
        dnx <- vector("list", 3L)
    for(i in which(vapply(dnx, is.null, NA)))
        dnx[[i]] <- LETTERS[seq_len(dim(x)[i])]
    if(is.null(names(dnx)))
        i <- 1L : 3L
    else
        i <- which(is.null(names(dnx)))
    if(any(i))
        names(dnx)[i] <- c("Row", "Col", "Strata")[i]
    dimnames(x) <- dnx
    k <- dim(x)[3L]

    if(!((length(conf.level) == 1) && is.finite(conf.level) &&
         (conf.level >= 0) && (conf.level < 1)))
        stop("'conf.level' must be a single number between 0 and 1")
    if(conf.level == 0)
        conf.level <- FALSE

    std <- match.arg(std)

    findTableWithOAM <- function(or, tab) {
        ## Find a 2x2 table with given odds ratio 'or' and the margins
        ## of a given 2x2 table 'tab'.
        m <- rowSums(tab)[1L]
        n <- rowSums(tab)[2L]
        t <- colSums(tab)[1L]
        if(or == 1)
            x <- t * n / (m + n)
        else if(or == Inf)
            x <- max(0, t - m)
        else {
            A <- or - 1
            B <- or * (m - t) + (n + t)
            C <- - t * n
            x <- (- B + sqrt(B ^ 2 - 4 * A * C)) / (2 * A)
        }
        matrix(c(t - x, x, m - t + x, n - x), nrow = 2)
    }

    drawPie <- function(r, from, to, n = 500, col = NA) {
        p <- 2 * pi * seq.int(from, to, length.out = n) / 360
        x <- c(cos(p), 0) * r
        y <- c(sin(p), 0) * r
        polygon(x, y, col = col)
        invisible(NULL)
    }

    stdize <- function(tab, std, x) {
        ## Standardize the 2 x 2 table 'tab'.
        if(std == "margins") {
            if(all(sort(margin) == c(1L, 2L))) {
                ## standardize to equal row and col margins
                u <- sqrt(odds(tab)$or)
                u <- u / (1 + u)
                y <- matrix(c(u, 1 - u, 1 - u, u), nrow = 2L)
            }
            else if(margin %in% c(1, 2))
                y <- proportions(tab, margin)
            else
                stop("incorrect 'margin' specification")
        }
        else if(std == "ind.max")
            y <- tab / max(tab)
        else if(std == "all.max")
            y <- tab / max(x)
        y
    }

    odds <- function(x) {
        ## Given a 2 x 2 or 2 x 2 x k table 'x', return a list with
        ## components 'or' and 'se' giving the odds ratios and standard
        ## deviations of the log odds ratios.
        if(length(dim(x)) == 2L) {
            dim(x) <- c(dim(x), 1L)
            k <- 1
        }
        else
            k <- dim(x)[3L]
        or <- double(k)
        se <- double(k)
        for(i in 1 : k) {
            f <- x[ , , i]
            storage.mode(f) <- "double" # protect against integer overflow
            if(any(f == 0))
                f <- f + 0.5
            or[i] <- (f[1L, 1L] * f[2L, 2L]) / (f[1L, 2L] * f[2L, 1L])
            se[i] <- sqrt(sum(1 / f))
        }
        list(or = or, se = se)
    }

    gamma <- 1.25                       # Scale factor for strata labels
    debug <- FALSE                      # Visualize the geometry.
                                        # Not settable by user!
    angle.f <- c( 90, 180,  0, 270)     # 'f' for 'from'
    angle.t <- c(180, 270, 90, 360)     # 't' for 'to'

    opar <- par(mar = c(0, 0, if(is.null(main)) 0 else 2.5, 0))
    on.exit(par(opar))

    byrow <- FALSE
    if(!is.null(mfrow)) {
        nr <- mfrow[1L]
        nc <- mfrow[2L]
    }
    else if(!is.null(mfcol)) {
        nr <- mfcol[1L]
        nc <- mfcol[2L]
        byrow <- TRUE
    }
    else {
        nr <- ceiling(sqrt(k))
        nc <- ceiling(k / nr)
    }
    if(nr * nc < k)
        stop("incorrect geometry specification")
    if(byrow)
        indexMatrix <- expand.grid(1 : nc, 1 : nr)[, c(2, 1)]
    else
        indexMatrix <- expand.grid(1 : nr, 1 : nc)

    totalWidth <- nc * 2 * (1 + space) + (nc - 1L) * space
    totalHeight <- if(k == 1)
        2 * (1 + space)
    else
        nr * (2 + (2 + gamma) * space) + (nr - 1L) * space
    xlim <- c(0, totalWidth)
    ylim <- c(0, totalHeight)

    dev.hold(); on.exit(dev.flush(), add = TRUE)
    plot.new()
    plot.window(xlim = xlim, ylim = ylim, asp = 1)

    o <- odds(x)

    scale <- space / (2 * strheight("Ag"))
    v <- 0.95 - max(strwidth(as.character(c(x)), cex = scale)) / 2

    for(i in 1 : k) {

        tab <- x[ , , i]

        fit <- stdize(tab, std, x)

        xInd <- indexMatrix[i, 2L]
        xOrig <- 2 * xInd - 1 + (3 * xInd - 2) * space
        yInd <- indexMatrix[i, 1L]
        yOrig <- if(k == 1)
            (1 + space)
        else
            (totalHeight
             - (2 * yInd - 1 + ((3 + gamma) * yInd - 2) * space))
        plot.window(xlim - xOrig, ylim - yOrig, asp = 1)

        if(debug) {
            abline(h = -1 - space)
            abline(h =  1 + space)
            abline(h =  1 + (1 + gamma) * space)
            abline(v = -1 - space)
            abline(v =  1 + space)
        }

        ## drawLabels()
        u <- 1 + space / 2
        adjCorr <- 0.2
        text(0, u,
             paste(names(dimnames(x))[1L],
                   dimnames(x)[[1L]][1L],
                   sep = ": "),
             adj = c(0.5, 0.5 - adjCorr),
             cex = scale)
        text(-u, 0,
             paste(names(dimnames(x))[2L],
                   dimnames(x)[[2L]][1L],
                   sep = ": "),
             adj = c(0.5, 0.5 - adjCorr),
             cex = scale,
             srt = 90)
        text(0, -u,
             paste(names(dimnames(x))[1L],
                   dimnames(x)[[1L]][2L],
                   sep = ": "),
             adj = c(0.5, 0.5 + adjCorr),
             cex = scale)
        text(u, 0,
             paste(names(dimnames(x))[2L],
                   dimnames(x)[[2L]][2L],
                   sep = ": "),
             adj = c(0.5, 0.5 + adjCorr),
             cex = scale,
             srt = 90)
        if(k > 1) {
            text(0, 1 + (1 + gamma / 2) * space,
                 paste(names(dimnames(x))[3L],
                       dimnames(x)[[3L]][i],
                       sep = ": "),
                 cex = gamma * scale)
        }

        ## drawFrequencies()
        d <- odds(tab)$or
        drawPie(sqrt(fit[1,1]),  90, 180, col = color[1 + (d > 1)])
        drawPie(sqrt(fit[2,1]), 180, 270, col = color[2 - (d > 1)])
        drawPie(sqrt(fit[1,2]),   0,  90, col = color[2 - (d > 1)])
        drawPie(sqrt(fit[2,2]), 270, 360, col = color[1 + (d > 1)])
        u <- 1 - space / 2
        text(c(-v, -v,  v,  v),
             c( u, -u,  u, -u),
             as.character(c(tab)),
             cex = scale)

        ## drawConfBands()
        if(is.numeric(conf.level)) {
            or <- o$or[i]
            se <- o$se[i]
            ## lower
            theta <- or * exp(stats::qnorm((1 - conf.level) / 2) * se)
            tau <- findTableWithOAM(theta, tab)
            r <- sqrt(c(stdize(tau, std, x)))
            for(j in 1 : 4)
                drawPie(r[j], angle.f[j], angle.t[j])
            ## upper
            theta <- or * exp(stats::qnorm((1 + conf.level) / 2) * se)
            tau <- findTableWithOAM(theta, tab)
            r <- sqrt(c(stdize(tau, std, x)))
            for(j in 1 : 4)
                drawPie(r[j], angle.f[j], angle.t[j])
        }

        ## drawBoxes()
        polygon(c(-1,  1, 1, -1),
                c(-1, -1, 1,  1))
        lines(c(-1, 1), c(0, 0))
        for(j in seq.int(from = -0.8, to = 0.8, by = 0.2))
            lines(c(j, j), c(-0.02, 0.02))
        for(j in seq.int(from = -0.9, to = 0.9, by = 0.2))
            lines(c(j, j), c(-0.01, 0.01))
        lines(c(0, 0), c(-1, 1))
        for(j in seq.int(from = -0.8, to = 0.8, by = 0.2))
            lines(c(-0.02, 0.02), c(j, j))
        for(j in seq.int(from = -0.9, to = 0.9, by = 0.2))
            lines(c(-0.01, 0.01), c(j, j))

    }

    if(!is.null(main))
        mtext(main, cex = 1.5, adj = 0.5)

    return(invisible())
}
