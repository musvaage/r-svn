% File src/library/utils/man/available.packages.Rd
% Part of the R package, https://www.R-project.org
% Copyright 1995-2024 R Core Team
% Distributed under GPL 2 or later

\name{available.packages}
\alias{available.packages}
\alias{R_AVAILABLE_PACKAGES_CACHE_CONTROL_MAX_AGE}

\title{List Available Packages at \abbr{CRAN}-like Repositories}
\description{
  \code{available.packages} returns a matrix of details corresponding to
  packages currently available at one or more repositories. The
  current list of packages is downloaded over the internet (or copied
  from a local mirror).
}
\usage{
available.packages(contriburl = contrib.url(repos, type), method,
                   fields = getOption("available_packages_fields"),
                   type = getOption("pkgType"), filters = NULL,
                   repos = getOption("repos"),
                   ignore_repo_cache = FALSE, max_repo_cache_age,
                   cache_user_dir =
                       str2logical(Sys.getenv("R_PACKAGES_CACHE_USER_DIR",
                                              FALSE)),
                   quiet = TRUE, verbose = FALSE, \dots)
}
\arguments{
  \item{contriburl}{
    URL(s) of the \file{contrib} sections of the repositories.
    Specify this argument only if your repository mirror is incomplete,
    e.g., because you mirrored only the \file{contrib} section.
  }
  \item{method}{
    download method, see \code{\link{download.file}}.
  }
  \item{type}{
    character string, indicate which type of packages: see
    \code{\link{install.packages}}.

    If \code{type = "both"} this will use the source repository.
  }
  \item{fields}{
    a character vector giving the fields to extract from
    the \file{PACKAGES} file(s) in addition to the default ones, or
    \code{NULL} (default).  Unavailable fields result in \code{NA}
    values.
  }
  \item{filters}{
    a character vector or list or \code{NULL} (default). See \sQuote{Details}.
  }
  \item{repos}{
    character vector, the base URL(s) of the repositories to use.
  }
  \item{ignore_repo_cache}{logical.  If true, the repository cache is
    never used (see \sQuote{Details}).
  }
  \item{max_repo_cache_age}{any cached values older than this in seconds
    will be ignored. See \sQuote{Details}.
  }
  \item{cache_user_dir}{\code{\link{logical}} indicating if caching should
    happen in \pkg{tools}' \code{\link[tools]{R_user_dir}("base", "cache")}
    instead of \code{\link{tempdir}()}.}
  \item{quiet}{logical, passed to \code{\link{download.file}()}; change
    only if you know what you are doing.}
  \item{verbose}{logical indicating if a \dQuote{progress report} line
    should be printed about the number of packages found in each repository.}
  % before filtering (TODO: *during* filt.)
  \item{\dots}{
    allow additional arguments to be passed from callers (which might be
    arguments to future versions of this function).  Currently these are
    all passed to \code{\link{download.file}()}.
  }
}
\details{
  The list of packages is either copied from a local mirror (specified by a
  \samp{file://} \abbr{URI}) or downloaded.  If downloaded and
  \code{ignore_repo_cache} is false (the default), the list is cached
  for the \R session in a per-repository file in \code{\link{tempdir}()}
  with a name like
\preformatted{repos_http\%3a\%2f\%2fcran.r-project.org\%2fsrc\%2fcontrib.rds}
  The cached values are renewed when found to be too old, with the age
  limit controlled \emph{via} argument \code{max_repo_cache_age}.
  This defaults to the current value of the environment variable
  \env{R_AVAILABLE_PACKAGES_CACHE_CONTROL_MAX_AGE}, or if unset, to
  \code{3600} (one hour).

  By default, the return value includes only packages whose version and
  OS requirements are met by the running version of \R, and only gives
  information on the latest versions of packages.

  Argument \code{filters} can be used to select which of the packages on the
  repositories are reported.  It is called with its default value
  (\code{NULL}) by functions such as \code{install.packages}: this value
  corresponds to \code{\link{getOption}("available_packages_filters")}
  and to \code{c("R_version", "OS_type", "subarch", "duplicates")} if
  that is unset or set to \code{NULL}.

  The built-in filters are
  \describe{
    \item{\code{"R_version"}}{Exclude packages whose \R version
      requirements are not met.}
    \item{\code{"OS_type"}}{Exclude packages whose OS requirement is
      incompatible with this version of \R: that is exclude
      Windows-only packages on a Unix-alike platform
      and \emph{vice versa}.}
    \item{\code{"subarch"}}{For binary packages, exclude those with
      compiled code that is not available for the current
      sub-architecture, e.g.\sspace{}exclude packages only compiled for
      32-bit Windows on a 64-bit Windows \R.}
    \item{\code{"duplicates"}}{Only report the latest version where more
      than one version is available, and only report the first-named
      repository (in \code{contriburl}) with the latest version if that
      is in more than one repository.}
    \item{\code{"license/FOSS"}}{Include only packages for which
      installation can proceed solely based on packages which can be
      verified as Free or Open Source Software (\abbr{FOSS}, e.g.,
      \url{https://en.wikipedia.org/wiki/FOSS}) employing the available
      license specifications.  Thus both the package and any packages
      that it depends on to load need to be \emph{known to be} \abbr{FOSS}.

      Note that this does depend on the repository supplying license
      information.
    }
    \item{\code{"license/restricts_use"}}{Include only packages for
      which installation can proceed solely based on packages which are
      known not to restrict use.
    }
    \item{\code{"CRAN"}}{Use \abbr{CRAN} versions in preference to versions
      from other repositories (even if these have a higher version
      number).  This needs to be applied \emph{before} the default
      \code{"duplicates"} filter, so cannot be used with
      \code{add = TRUE}.
    }
  }
  If all the filters are from this set, then they can be specified as a
  character vector; otherwise \code{filters} should be a list with
  elements which are character strings, user-defined functions or
  \code{add = TRUE} (see below).

  User-defined filters are functions which take a single argument, a
  matrix of the form returned by \code{available.packages}, and
  return a matrix consisting of a subset of the rows of the argument.

  The special \sQuote{filter} \code{add = TRUE} appends the other
  elements of the filter list to the default filters.
}
\value{
  A character matrix with one row per package, row names the package names and
  column names including \code{"Package"}, \code{"Version"},
  \code{"Priority"}, \code{"Depends"}, \code{"Imports"},
  \code{"LinkingTo"}, \code{"Suggests"}, \code{"Enhances"},
  \code{"File"} and \code{"Repository"}.  Additional columns can be
  specified using the \code{fields} argument.

  Where provided by the repository, fields \code{"OS_type"},
  \code{"License"}, \code{"License_is_FOSS"},
  \code{"License_restricts_use"}, \code{"Archs"}, \code{"MD5sum"} and
  \code{"NeedsCompilation"} are reported for use by the filters and
  package management tools, including \code{\link{install.packages}}.
}
\seealso{
  \code{\link{packageStatus}}, \code{\link{update.packages}},
  \code{\link{install.packages}}, \code{\link{download.packages}},
  \code{\link{contrib.url}}.

  The \sQuote{R Installation and Administration} manual for how to
  set up a repository.
}
\examples{\donttest{
## Count package licenses
db <- available.packages(repos = findCRANmirror("web"), filters = "duplicates")
table(db[,"License"])

## Use custom filter function to only keep recommended packages
## which do not require compilation
available.packages(repos = findCRANmirror("web"),
  filters = list(
    add = TRUE,
    function (db) db[db[,"Priority"] \%in\% "recommended" &
                     db[,"NeedsCompilation"] == "no", ]
  ))
}
\dontrun{
## Restrict install.packages() (etc) to known-to-be-FOSS packages
options(available_packages_filters =
  c("R_version", "OS_type", "subarch", "duplicates", "license/FOSS"))
## or
options(available_packages_filters = list(add = TRUE, "license/FOSS"))

## Give priority to released versions on CRAN, rather than development
## versions on R-Forge etc.
options(available_packages_filters =
     c("R_version", "OS_type", "subarch", "CRAN", "duplicates"))
}}
\keyword{utilities}
