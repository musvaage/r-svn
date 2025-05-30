% File src/library/graphics/man/points.Rd
% Part of the R package, https://www.R-project.org
% Copyright 1995-2015 R Core Team
% Distributed under GPL 2 or later

\name{points}
\alias{points}
\alias{points.default}
\alias{pch}
\title{Add Points to a Plot}
\description{
  \code{points} is a generic function to draw a sequence of points at
  the specified coordinates.  The specified character(s) are plotted,
  centered at the coordinates.
}
\usage{
points(x, \dots)

\method{points}{default}(x, y = NULL, type = "p", \dots)
}
\arguments{
  \item{x, y}{coordinate vectors of points to plot.}
  \item{type}{character indicating the type of plotting; actually any of
    the \code{type}s as in \code{\link{plot.default}}.}
  \item{\dots}{Further \link{graphical parameters} may also be supplied as
    arguments.  See \sQuote{Details}.}
}
\details{
  The coordinates can be passed in a plotting structure
  (a list with \code{x} and \code{y} components), a two-column matrix, a
  time series, \dots.  See \code{\link{xy.coords}}.  If supplied
  separately, they must be of the same length.

  Graphical parameters commonly used are
  \describe{
    \item{\code{pch}}{plotting \sQuote{character}, i.e., symbol to use.
      This can either be a single character or an integer code for one
      of a set of graphics symbols.  The full set of S symbols is
      available with \code{pch = 0:18}, see the examples below.
      (NB: \R uses circles instead of the octagons used in S.)

      Value \code{pch = "."} (equivalently \code{pch = 46}) is handled
      specially.  It is a rectangle of side 0.01 inch (scaled by
      \code{cex}).  In addition, if \code{cex = 1} (the default), each
      side is at least one pixel (1/72 inch on the \code{\link{pdf}} and
      \code{\link{postscript}} devices).

      For other text symbols, \code{cex = 1} corresponds to the default
      font size of the device, often specified by an argument
      \code{pointsize}.  For \code{pch} in \code{0:25} the default size
      is about 75\% of the character height (see \code{par("cin")}).
    }
    \item{\code{col}}{color code or name, see \code{\link{par}}.}
    \item{\code{bg}}{background (fill) color for the open plot
      symbols given by \code{pch = 21:25}.}
    \item{\code{cex}}{character (or symbol) expansion: a numerical vector.
      This works as a multiple of \code{\link{par}("cex")}.}
    \item{\code{lwd}}{line width for drawing symbols see \code{\link{par}}.}
  }
  Others less commonly used are \code{lty} and \code{lwd} for
  types such as \code{"b"} and \code{"l"}.

  The \link{graphical parameters} \code{pch}, \code{col}, \code{bg},
  \code{cex} and \code{lwd} can be vectors (which will be recycled as
  needed) giving a value for each point plotted.  If lines are to be
  plotted (e.g., for \code{type = "b"}) the first element of \code{lwd}
  is used.

  Points whose \code{x}, \code{y}, \code{pch}, \code{col} or \code{cex}
  value is \code{NA} are omitted from the plot.
}
\section{\code{pch} values}{
  Values of \code{pch} are stored internally as integers.  The
  interpretation is
  \itemize{
    \item \code{NA_integer_}: no symbol.
    \item \code{0:18}: S-compatible vector symbols.
    \item \code{19:25}: further \R vector symbols.
    \item \code{26:31}: unused (and ignored).
    \item \code{32:127}: ASCII characters.
    \item \code{128:255} native characters \emph{only in a
      single-byte locale and for the symbol font}.  (\code{128:159} are
    only used on Windows.)
    \item \code{-32 \dots} Unicode code point (where supported).
  }
  Note that unlike S (which uses octagons), symbols \code{1}, \code{10},
  \code{13} and \code{16} use circles.  The filled shapes \code{15:18}
  do not include a border.

% SVG support in browsers is patchy, e.g. not Konqueror
%  \if{html}{\figure{pch.svg}{options: width=100\%}}
  \if{html}{\figure{pch.png}{Illustration of pch = 0:25}}
  \if{latex}{\figure{pch.pdf}{options: width=15cm}}

  The following  \R plotting symbols are can be obtained with
  \code{pch = 19:25}: those with \code{21:25} can be colored and
  filled with different colors: \code{col} gives the border color
  and \code{bg} the background color
  \if{html}{(which is \samp{"grey"} in the figure)}
  \if{latex}{(which is \samp{"grey"} in the figure)}
  \itemize{
    \item \code{pch = 19}: solid circle,
    \item \code{pch = 20}: bullet (smaller solid circle,
    2/3 the size of \code{19}),
    \item \code{pch = 21}: filled circle,
    \item \code{pch = 22}: filled square,
    \item \code{pch = 23}: filled diamond,
    \item \code{pch = 24}: filled triangle point-up,
    \item \code{pch = 25}: filled triangle point down.
  }
  Note that all of these both fill the shape and draw a border.  Some
  care in interpretation is needed when semi-transparent colours are
  used for both fill and border (and the result might be device-specific
  and even viewer-specific for \code{\link{pdf}}).

  The difference between \code{pch = 16} and \code{pch = 19} is that the
  latter uses a border and so is perceptibly larger when \code{lwd} is
  large relative to \code{cex}.

  Values \code{pch = 26:31} are currently unused and \code{pch = 32:127}
  give the ASCII characters.  In a single-byte locale
  \code{pch = 128:255} give the corresponding character (if any) in
  the locale's character set.  Where supported by the OS, negative
  values specify a Unicode code point, so e.g.\sspace{}\code{-0x2642L}
  is a \sQuote{male sign} and \code{-0x20ACL} is the Euro.

  A character string consisting of a single character is converted to an
  integer: \code{32:127} for ASCII characters, and usually to the
  Unicode code point otherwise.  (In non-Latin-1 single-byte locales,
  \code{128:255} will be used for 8-bit characters.)

  If \code{pch} supplied is a logical, integer or character
  \code{NA} or an empty character string the point is omitted from
  the plot.

  If \code{pch} is \code{NULL} or otherwise of length 0,
  \code{par("pch")} is used.

  If the symbol font (\code{\link{par}(font = 5)}) is used, numerical
  values should be used for \code{pch}: the range is
  \code{c(32:126, 160:254)} in all locales (but \code{240} is not
  defined (used for \sQuote{apple} on macOS) and \code{160}, Euro, may
  not be present).
}
\note{
  A single-byte encoding may include the characters in
  \code{pch = 128:255}, and if it does, a font may not include all (or
  even any) of them.

  Not all negative numbers are valid as Unicode code points, and no
  check is done.  A display device is likely to use a rectangle for (or
  omit) Unicode code points which are invalid or for which it does not
  have a glyph in the font used.

  What happens for very small or zero values of \code{cex} is
  device-dependent: symbols or characters may become invisible or
  they may be plotted at a fixed minimum size.  Circles of zero radius
  will not be plotted.
}
\references{
  Becker, R. A., Chambers, J. M. and Wilks, A. R. (1988)
  \emph{The New S Language}.
  Wadsworth & Brooks/Cole.
}
\seealso{
  \code{\link{points.formula}} for the formula method;
  \code{\link{plot}}, \code{\link{lines}}, and the underlying
  workhorse function \code{\link{plot.xy}}.
}
\examples{
require(stats) # for rnorm
plot(-4:4, -4:4, type = "n")  # setting up coord. system
points(rnorm(200), rnorm(200), col = "red")
points(rnorm(100)/2, rnorm(100)/2, col = "blue", cex = 1.5)

op <- par(bg = "light blue")
x <- seq(0, 2*pi, length.out = 51)
## something "between type='b' and type='o'":
plot(x, sin(x), type = "o", pch = 21, bg = par("bg"), col = "blue", cex = .6,
 main = 'plot(..., type="o", pch=21, bg=par("bg"))')
par(op)

## Illustration of pch = 0:25 (as in the figure shown above in PDF/HTML help)
\dontrun{png("pch.png", height = 0.7, width = 7, res = 100, units = "in")}
par(mar = rep(0,4))
plot(c(-1, 26), 0:1, type = "n", axes = FALSE)
text(0:25, 0.6, 0:25, cex = 0.5)
points(0:25, rep(0.3, 26), pch = 0:25, bg = "grey")


##-------- Showing all the extra & some char graphics symbols ---------
pchShow <-
  function(extras = c("*",".", "o","O","0","+","-","|","\%","#"),
           cex = 3, ## good for both .Device=="postscript" and "x11"
           col = "red3", bg = "gold", coltext = "brown", cextext = 1.2,
           main = paste("plot symbols :  points (...  pch = *, cex =",
                        cex,")"))
  {
    nex <- length(extras)
    np  <- 26 + nex
    ipch <- 0:(np-1)
    k <- floor(sqrt(np))
    dd <- c(-1,1)/2
    rx <- dd + range(ix <- ipch \%/\% k)
    ry <- dd + range(iy <- 3 + (k-1)- ipch \%\% k)
    pch <- as.list(ipch) # list with integers & strings
    if(nex > 0) pch[26+ 1:nex] <- as.list(extras)
    plot(rx, ry, type = "n", axes  =  FALSE, xlab = "", ylab = "", main = main)
    abline(v = ix, h = iy, col = "lightgray", lty = "dotted")
    for(i in 1:np) {
      pc <- pch[[i]]
      ## 'col' symbols with a 'bg'-colored interior (where available) :
      points(ix[i], iy[i], pch = pc, col = col, bg = bg, cex = cex)
      if(cextext > 0)
          text(ix[i] - 0.3, iy[i], pc, col = coltext, cex = cextext)
    }
  }

pchShow()
pchShow(c("o","O","0"), cex = 2.5)
pchShow(NULL, cex = 4, cextext = 0, main = NULL)

\donttest{
## ------------ test code for various pch specifications -------------
# Try this in various font families (including Hershey)
# and locales.  Use sign = -1 asserts we want Latin-1.
# Standard cases in a MBCS locale will not plot the top half.
TestChars <- function(sign = 1, font = 1, ...)
{
   MB <- l10n_info()$MBCS
   r <- if(font == 5) { sign <- 1; c(32:126, 160:254)
       } else if(MB) 32:126 else 32:255
   if (sign == -1) r <- c(32:126, 160:255)
   par(pty = "s")
   plot(c(-1,16), c(-1,16), type = "n", xlab = "", ylab = "",
        xaxs = "i", yaxs = "i",
        main = sprintf("sign = \%d, font = \%d", sign, font))
   grid(17, 17, lty = 1) ; mtext(paste("MBCS:", MB))
   for(i in r) try(points(i\%\%16, i\%/\%16, pch = sign*i, font = font,...))
}
TestChars()
try(TestChars(sign = -1))
TestChars(font = 5)  # Euro might be at 160 (0+10*16).
                     # macOS has apple at 240 (0+15*16).
try(TestChars(-1, font = 2))  # bold
}}
\keyword{aplot}
