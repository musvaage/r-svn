% File src/library/utils/man/apropos.Rd
% Part of the R package, https://www.R-project.org
% Copyright 1995-2022 R Core Team
% Distributed under GPL 2 or later

\name{apropos}
\title{Find Objects by (Partial) Name}
\usage{
apropos(what, where = FALSE, ignore.case = TRUE,
        dot_internals = FALSE, mode = "any")

find(what, mode = "any", numeric = FALSE, simple.words = TRUE)
}
\alias{apropos}
\alias{find}
\arguments{
  \item{what}{a character string.  For \code{find} with
    \code{simple.words = TRUE}, the name of an object; otherwise
    a \link{regular expression} to match object names against.}
  \item{where, numeric}{logical indicating whether positions in the
    search list should also be returned.}
  \item{ignore.case}{logical indicating if the search should be
    case-insensitive, \code{TRUE} by default.}
  \item{dot_internals}{logical indicating if the search result should show
    \pkg{base} internal objects, \code{FALSE} by default.}
  \item{mode}{a character string; if not \code{"any"}, only objects whose
    \code{\link{mode}} equals \code{mode} are searched.}
  \item{simple.words}{logical; if \code{TRUE}, the \code{what} argument is
    only searched as a whole word.}
}
\description{
  \code{apropos()} returns a character vector giving the names of
  objects in the search list matching (as a regular expression)
  \code{what}.

  \code{find()} returns where objects of a given name can be found.
}
\details{
  If \code{mode != "any"} only those objects which are of mode \code{mode}
  are considered.

  \code{find} is a different user interface for a similar task to
  \code{apropos}. By default (\code{simple.words == TRUE}),
  only whole names are matched. Unlike \code{apropos}, matching is
  always case-sensitive.

  Unlike the default behaviour of \code{\link{ls}}, names which
  begin with a \samp{.} are included, but base \sQuote{internal} objects
  are included only when \code{dot_internals} is true.
}
\author{Originally, Kurt Hornik and Martin Maechler (May 1997).}
\value{
  For \code{apropos}, a character vector sorted by name.  For
  \code{where = TRUE} this has names giving the (numerical) positions on
  the search path.

  For \code{find}, either a character vector of environment names or
  (for \code{numeric = TRUE}) a numerical vector of positions on the
  search path with names the names of the corresponding environments.
}
\seealso{
  \code{\link{glob2rx}} to convert wildcard patterns to regular expressions.

  \code{\link{objects}} for listing objects from one place,
  \code{\link{help.search}} for searching the help system,
  \code{\link{search}} for the search path.
}
\examples{
require(stats)

%% some of these have enormous output that varies a lot by version
\dontrun{apropos("lm")}
apropos("GLM")                      # several
apropos("GLM", ignore.case = FALSE) # not one
apropos("lq")

cor <- 1:pi
find("cor")                         #> ".GlobalEnv"   "package:stats"
find("cor", numeric = TRUE)                     # numbers with these names
find("cor", numeric = TRUE, mode = "function")  # only the second one
rm(cor)

\dontrun{apropos(".", mode = "list")  # includes many datasets}

# extraction/replacement methods (need a DOUBLE backslash '\\\\')
apropos("\\\\[")

\donttest{# everything % not diff-able
length(apropos("."))

# those starting with 'pr'
apropos("^pr")

# the 1-letter things
apropos("^.$")
# the 1-2-letter things
apropos("^..?$")
# the 2-to-4 letter things
apropos("^.{2,4}$")
# frequencies of 8-and-more letter things
table(nchar(apropos("^.{8,}$")))
}}
\keyword{data}
\keyword{documentation}
\keyword{environment}
