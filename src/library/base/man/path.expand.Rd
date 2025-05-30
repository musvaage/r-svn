% File src/library/base/man/path.expand.Rd
% Part of the R package, https://www.R-project.org
% Copyright 1995-2022 R Core Team
% Distributed under GPL 2 or later

\name{path.expand}
\alias{path.expand}
\alias{tilde expansion}
\title{Expand File Paths}
\description{
  Expand a path name, for example by replacing a leading tilde by the
  user's home directory (if defined on that platform).
}
\usage{
path.expand(path)
}
\arguments{
  \item{path}{character vector containing one or more path names.}
}
\details{
  \describe{
    \item{On Unix - alikes:}{
   On most builds of \R a leading \code{~user} will expand to the home
  directory of \code{user}.

  There are possibly different concepts of \sQuote{home directory}: that
  usually used is the setting of the environment variable \env{HOME}.

  The \sQuote{path names} need not exist nor be valid path names but
  they do need to be representable in the session encoding.
  }
   \item{On Windows:}{
  The definition of the \sQuote{home} directory is in the \file{rw-FAQ}
  2.13: it is taken from the \env{R_USER} environment variable (or
  possibly \env{HOME} if \env{R_USER} is not set)
  when \code{path.expand} is first called in a session.

  The \sQuote{path names} need not exist nor be valid path names.
  }
 }
}
\value{
  A character vector of possibly expanded path names: where the home
  directory is unknown or none is specified the path is returned unchanged.

  %% Currently truncates with readline, returns unchanged on Windows and
  %% Unix without readline.
  If the expansion would exceed the maximum path length the result may
  be truncated or the path may be returned unchanged.
}
\seealso{
  \code{\link{basename}}, \code{\link{normalizePath}}, \code{\link{file.path}}.
}
\examples{
path.expand("~/foo")
}
\keyword{file}
