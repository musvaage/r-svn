#  File src/library/tools/R/urltools.R
#  Part of the R package, https://www.R-project.org
#
#  Copyright (C) 2015-2024 The R Core Team
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

## See RFC 3986 <https://www.rfc-editor.org/rfc/rfc3986> and
## <https://url.spec.whatwg.org/>.

get_IANA_URI_scheme_db <-
function()
{
    ## See
    ## <https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml>.
    baseurl <- "https://www.iana.org/assignments/uri-schemes/"
    db <- utils::read.csv(url(paste0(baseurl, "uri-schemes-1.csv")),
                          stringsAsFactors = FALSE, encoding = "UTF-8")
    names(db) <- chartr(".", "_", names(db))
    db$URI_Scheme <- sub(" .*", "", db$URI_Scheme)
    db
}

parse_URI_reference <-
function(x)
{
    re <- "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
    if(length(x)) {
        y <- do.call(rbind, regmatches(x, regexec(re, x)))
        y <- y[, c(3, 5, 6, 8, 10), drop = FALSE]
    } else {
        y <- matrix(character(), 0L, 5L)
    }
    y <- as.data.frame(y)
    names(y) <- c("scheme", "authority", "path", "query", "fragment")
    y
}

.get_urls_from_Rd <-
function(x, href = TRUE, ifdef = FALSE)
{
    urls <- character()
    recurse <- function(e) {
        tag <- attr(e, "Rd_tag")
        ## Rd2HTML and Rd2latex remove whitespace and \n from URLs.
        if(identical(tag, "\\url")) {
            urls <<- c(urls, lines2str(.Rd_deparse(e, tag = FALSE)))
        } else if(href && identical(tag, "\\href")) {
            ## One could also record the \href text argument in the
            ## names, but then one would need to process named and
            ## unnamed extracted URLs separately.
            urls <<- c(urls, lines2str(.Rd_deparse(e[[1L]], tag = FALSE)))
        } else if(ifdef && length(tag) && (tag %in% c("\\if", "\\ifelse"))) {
            ## cf. testRdConditional()
            condition <- e[[1L]]
            if(all(RdTags(condition) == "TEXT")) {
                if(any(c("TRUE", "html") %in%
                       trimws(strsplit(paste(condition, collapse = ""), 
                                       ",")[[1L]])))
                    recurse(e[[2L]])
                else if(tag == "\\ifelse")
                    recurse(e[[3L]])
            }
        } else if(is.list(e))
            lapply(e, recurse)
    }
    lapply(x, recurse)
    unique(trimws(urls))
}

.get_urls_from_HTML_file <-
function(f)
{
    doc <- xml2::read_html(f)
    if(!inherits(doc, "xml_node")) return(character())
    nodes <- xml2::xml_find_all(doc, "//a")
    hrefs <- xml2::xml_attr(nodes, "href")
    unique(hrefs[!is.na(hrefs) & !startsWith(hrefs, "#")])
}

.get_urls_from_PDF_file <-
function(f)    
{
    ## Seems there is no straightforward way to extract hyperrefs from a
    ## PDF, hence first convert to HTML.
    ## Note that pdftohtml always outputs in cwd ...
    owd <- getwd()
    dir.create(d <- tempfile())
    on.exit({ unlink(d, recursive = TRUE); setwd(owd) })
    file.copy(normalizePath(f), d)
    setwd(d)
    g <- tempfile(tmpdir = d, fileext = ".xml")
    system2("pdftohtml",
            c("-s -q -i -c -xml", shQuote(basename(f)), shQuote(basename(g))))
    ## Oh dear: seems that pdftohtml can fail without a non-zero exit
    ## status.
    if(file.exists(g))
        .get_urls_from_HTML_file(g)
    else
        character()
}

url_db <-
function(urls, parents)
{
    ## Some people get leading LFs in URLs, so trim before checking.
    db <- list2DF(list(URL = trimws(as.character(urls)),
                       Parent = as.character(parents)))
    class(db) <- c("url_db", "data.frame")
    db
}

url_db_from_HTML_files <-
function(dir, recursive = FALSE, files = NULL, verbose = FALSE)
{
    urls <- parents <- character()
    if(is.null(files)) 
        files <- list.files(dir, pattern = "[.]html$",
                            full.names = TRUE,
                            recursive = recursive)
    urls <-
        lapply(files,
               function(f) {
                   if(verbose)
                       message(sprintf("processing %s",
                                       .file_path_relative_to_dir(f, dir)))
                   .get_urls_from_HTML_file(f)
               })
    names(urls) <- files
    urls <- Filter(length, urls)
    if(length(urls)) {
        parents <- rep.int(.file_path_relative_to_dir(names(urls), dir),
                           lengths(urls))
        urls <- unlist(urls, use.names = FALSE)
    }
    url_db(urls, parents)
}

url_db_from_PDF_files <-
function(dir, recursive = FALSE, files = NULL, verbose = FALSE)
{
    urls <- parents <- character()
    if(is.null(files))
        files <- list.files(dir, pattern = "[.]pdf$",
                            full.names = TRUE,
                            recursive = recursive)
    urls <-
        lapply(files,
               function(f) {
                   if(verbose)
                       message(sprintf("processing %s",
                                       .file_path_relative_to_dir(f, dir)))
                   .get_urls_from_PDF_file(f)
               })
    names(urls) <- files
    urls <- Filter(length, urls)
    if(length(urls)) {
        parents <- rep.int(.file_path_relative_to_dir(names(urls), dir),
                           lengths(urls))
        urls <- unlist(urls, use.names = FALSE)
    }
    url_db(urls, parents)
}

url_db_from_package_Rd_db <-
function(db)
{
    urls <- Filter(length, lapply(db, .get_urls_from_Rd))
    url_db(unlist(urls, use.names = FALSE),
           rep.int(file.path("man", names(urls)),
                   lengths(urls)))
}

url_db_from_package_metadata <-
function(meta)
{
    urls <- character()
    fields <- c("URL", "BugReports")
    for(v in meta[fields]) {
        if(is.na(v)) next
        urls <- c(urls, .get_urls_from_DESCRIPTION_URL_field(v))
    }
    if(!is.na(v <- meta["Description"])) {
        urls <- c(urls, .get_urls_from_DESCRIPTION_Description_field(v))
    }
    url_db(urls, rep.int("DESCRIPTION", length(urls)))
}

.get_urls_from_DESCRIPTION_URL_field <-
function(v)
{
    urls <- character()
    if(is.na(v)) return(urls)
    pattern <-
        "<(URL: *)?((https?|ftp)://[^[:space:],]*)[[:space:]]*>"
    m <- gregexpr(pattern, v)
    urls <- c(urls, .gregexec_at_pos(pattern, v, m, 3L))
    regmatches(v, m) <- ""
    pattern <- "(^|[^>\"?])((https?|ftp)://[^[:space:],]*)"
    m <- gregexpr(pattern, v)
    urls <- c(urls, .gregexec_at_pos(pattern, v, m, 3L))
    urls
}

.get_urls_from_DESCRIPTION_Description_field <-
function(v)
{
    urls <- character()
    if(is.na(v)) return(urls)    
    pattern <-
        "<(URL: *)?((https?|ftp)://[^[:space:]]+)[[:space:]]*>"
    m <- gregexpr(pattern, v)
    urls <- c(urls, .gregexec_at_pos(pattern, v, m, 3L))
    regmatches(v, m) <- ""
    pattern <-
        "([^>\"?])((https?|ftp)://[[:alnum:]/.:@+\\_~%#?=&;,-]+[[:alnum:]/])"
    m <- gregexpr(pattern, v)
    urls <- c(urls, .gregexec_at_pos(pattern, v, m, 3L))
    regmatches(v, m) <- ""
    pattern <- "<([A-Za-z][A-Za-z0-9.+-]*:[^>]+)>"
    ##   scheme      = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    m <- gregexpr(pattern, v)
    urls <- c(urls, .gregexec_at_pos(pattern, v, m, 2L))
    urls
}

url_db_from_package_citation <-
function(dir, meta, installed = FALSE)
{
    urls <- character()
    path <- if(installed) "CITATION" else file.path("inst", "CITATION")
    cfile <- file.path(dir, path)
    if(file.exists(cfile)) {
        cinfo <- .read_citation_quietly(cfile, meta)
        if(!inherits(cinfo, "error"))
            urls <- trimws(unique(unlist(cinfo$url, use.names = FALSE)))
    }
    url_db(urls, rep.int(path, length(urls)))
}

url_db_from_package_news <-
function(dir, installed = FALSE)
{
    path <- if(installed) "NEWS.Rd" else file.path("inst", "NEWS.Rd")
    nfile <- file.path(dir, path)
    urls <-
        if(file.exists(nfile)) {
            macros <- initialRdMacros()
            .get_urls_from_Rd(prepare_Rd(parse_Rd(nfile, macros = macros),
                                         stages = "install"))
        } else character()
    url_db(urls, rep.int(path, length(urls)))
}

url_db_from_package_HTML_files <-
function(dir, installed = FALSE)
{
    path <- if(installed) "doc" else file.path("inst", "doc")
    files <- Sys.glob(file.path(dir, path, "*.html"))
    if(installed && file.exists(rfile <- file.path(dir, "README.html")))
        files <- c(files, rfile)
    url_db_from_HTML_files(dir, files = files)
}

url_db_from_package_README_md <-
function(dir, installed = FALSE)
{
    urls <- path <- character()
    rfile <- Filter(file.exists,
                    c(if(!installed)
                          file.path(dir, "inst", "README.md"),
                      file.path(dir, "README.md")))[1L]
    if(!is.na(rfile) && nzchar(Sys.which("pandoc"))) {
        path <- .file_path_relative_to_dir(rfile, dir)
        tfile <- tempfile("README", fileext = ".html")
        on.exit(unlink(tfile))
        out <- .pandoc_md_for_CRAN(rfile, tfile)
        if(!out$status) {
            urls <- .get_urls_from_HTML_file(tfile)
        }
    }
    url_db(urls, rep.int(path, length(urls)))
}

url_db_from_package_NEWS_md <-
function(dir, installed = FALSE)
{
    urls <- path <- character()
    nfile <- Filter(file.exists,
                    c(if(!installed)
                          file.path(dir, "inst", "NEWS.md"),
                      file.path(dir, "NEWS.md")))[1L]
    if(!is.na(nfile) && nzchar(Sys.which("pandoc"))) {
        path <- .file_path_relative_to_dir(nfile, dir)
        tfile <- tempfile("NEWS", fileext = ".html")
        on.exit(unlink(tfile))
        out <- .pandoc_md_for_CRAN(nfile, tfile)
        if(!out$status) {
            urls <- .get_urls_from_HTML_file(tfile)
        }
    }
    url_db(urls, rep.int(path, length(urls)))
}

url_db_from_package_sources <-
function(dir, add = FALSE) {
    meta <- .get_package_metadata(dir, FALSE)
    db <- rbind(url_db_from_package_metadata(meta),
                url_db_from_package_Rd_db(Rd_db(dir = dir)),
                url_db_from_package_citation(dir, meta),
                url_db_from_package_news(dir))
    if(requireNamespace("xml2", quietly = TRUE)) {
        db <- rbind(db,
                    url_db_from_package_HTML_files(dir),
                    url_db_from_package_README_md(dir),
                    url_db_from_package_NEWS_md(dir)
                    )
    }
    if(add)
        db$Parent <- file.path(basename(dir), db$Parent)
    db
}

url_db_from_installed_packages <-
function(packages, lib.loc = NULL, verbose = FALSE)
{
    if(!length(packages)) return()
    one <- function(p) {
        if(verbose)
            message(sprintf("processing %s", p))
        dir <- system.file(package = p, lib.loc = lib.loc)
        if(dir == "") return()
        meta <- .read_description(file.path(dir, "DESCRIPTION"))
        rddb <- Rd_db(p, lib.loc = dirname(dir))
        db <- rbind(url_db_from_package_metadata(meta),
                    url_db_from_package_Rd_db(rddb),
                    url_db_from_package_citation(dir, meta,
                                                 installed = TRUE),
                    url_db_from_package_news(dir, installed = TRUE))
        if(requireNamespace("xml2", quietly = TRUE)) {
            db <- rbind(db,
                        url_db_from_package_HTML_files(dir,
                                                       installed = TRUE),
                        url_db_from_package_README_md(dir,
                                                      installed = TRUE),
                        url_db_from_package_NEWS_md(dir,
                                                    installed = TRUE)
                        )
        }
        db$Parent <- file.path(p, db$Parent)
        db
    }
    do.call(rbind,
            c(lapply(packages, one),
              list(make.row.names = FALSE)))
}

get_IANA_HTTP_status_code_db <-
function()
{
    ## See
    ## <https://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>
    baseurl <- "https://www.iana.org/assignments/http-status-codes/"
    db <- utils::read.csv(url(paste0(baseurl, "http-status-codes-1.csv")),
                          stringsAsFactors = FALSE)
    ## Drop "Unassigned".
    db[db$Description != "Unassigned", ]
}

## See <https://en.wikipedia.org/wiki/List_of_FTP_server_return_codes>
## and <https://www.rfc-editor.org/rfc/rfc959>,
## Section 4.2.2 "Numeric Order List of Reply Codes",
## and <https://www.rfc-editor.org/rfc/rfc2228>,
## Section 5 "New FTP Replies".
## Only need those >= 400.
table_of_FTP_server_return_codes <-
    c("421" = "Service not available, closing control connection.",
      "425" = "Can't open data connection.",
      "426" = "Connection closed; transfer aborted.",
      "430" = "Invalid username or password",
      "431" = "Need some unavailable resource to process security.",
      "434" = "Requested host unavailable.",
      "450" = "Requested file action not taken.",
      "451" = "Requested action aborted: local error in processing.",
      "452" = "Requested action not taken.  Insufficient storage space in system.",
      "500" = "Syntax error, command unrecognized.",
      "501" = "Syntax error in parameters or arguments.",
      "502" = "Command not implemented.",
      "503" = "Bad sequence of commands.",
      "504" = "Command not implemented for that parameter.",
      "530" = "Not logged in.",
      "532" = "Need account for storing files.",
      "533" = "Command protection level denied for policy reasons.",
      "534" = "Request denied for policy reasons.",
      "535" = "Failed security check (hash, sequence, etc).",
      "536" = "Requested PROT level not supported by mechanism.",
      "537" = "Command protection level not supported by security mechanism.",
      "550" = "Requested action not taken.  File unavailable",
      "551" = "Requested action aborted: page type unknown.",
      "552" = "Requested file action aborted.  Exceeded storage allocation (for current directory or dataset).",
      "553" = "Requested action not taken.  File name not allowed.",
      "631" = "Integrity protected reply.",
      "632" = "Confidentiality and integrity protected reply.",
      "633" = "Confidentiality protected reply."
      )

check_url_db <-
function(db, remote = TRUE, verbose = FALSE, parallel = FALSE, pool = NULL)
{
    use_curl <-
        !parallel &&
        config_val_to_logical(Sys.getenv("_R_CHECK_URLS_USE_CURL_",
                                         "TRUE")) &&
        requireNamespace("curl", quietly = TRUE)

    if(parallel && is.null(pool))
        pool <- curl::new_pool()    

    .gather <- function(u = character(),
                        p = list(),
                        s = rep.int("", length(u)),
                        m = rep.int("", length(u)),
                        new = rep.int("", length(u)),
                        cran = rep.int("", length(u)),
                        spaces = rep.int("", length(u)),
                        R = rep.int("", length(u))) {
        y <- list2DF(list(URL = u, From = p, Status = s, Message = m,
                          New = new, CRAN = cran, Spaces = spaces, R = R))
        class(y) <- c("check_url_db", "data.frame")
        y
    }
    
    .fetch_headers <-
        if(parallel)
            function(urls)
                .fetch_headers_via_curl(urls, verbose, pool)
        else
            function(urls)
                .fetch_headers_via_base(urls, verbose)

    .check_ftp <- function(u, h) {
        if(inherits(h, "error")) {
            s <- "-1"
            msg <- sub("[[:space:]]*$", "", conditionMessage(h))
        } else {
            s <- as.character(attr(h, "status"))
            msg <- table_of_FTP_server_return_codes[s]
        }
        c(s, msg, "", "")
    }

    .check_http <- if(remote)
                       function(u, h) c(.check_http_A(u, h),
                                        .check_http_B(u))
                   else
                       function(u, h) c(rep.int("", 3L),
                                        .check_http_B(u))

    .check_http_A <- function(u, h) {
        newLoc <- ""
        if(inherits(h, "error")) {
            s <- "-1"
            msg <- sub("[[:space:]]*$", "", conditionMessage(h))
            if(grepl(paste(c("server certificate verification failed",
                             "failed to get server cert",
                             "libcurl error code (51|60)"),
                           collapse = "|"),
                     msg)) {
                h2 <- tryCatch(curlGetHeaders(u, verify = FALSE),
                               error = identity)
                s2 <- as.character(attr(h2, "status"))
                msg <- paste0(msg, "\n\t(Status without verification: ",
                              table_of_HTTP_status_codes[s2], ")")
            }
        } else {
            s <- as.character(attr(h, "status"))
            msg <- table_of_HTTP_status_codes[s]
        }
        ## Look for redirected URLs
        ## According to
        ## <https://www.rfc-editor.org/rfc/rfc7230#section-3.1.2> the first
        ## line of a response is the status-line, with "a possibly empty
        ## textual phrase describing the status code", so only look for
        ## a 301 status code in the first line.
        if(grepl(" 301 ", h[1L], useBytes = TRUE)) {
            ## Get the new location from the last consecutive 301
            ## obtained.
            h <- split(h, c(0L, cumsum(h == "\r\n")[-length(h)]))
            i <- vapply(h,
                        function(e)
                            grepl(" 301 ", e[1L], useBytes = TRUE),
                        NA)
            h <- h[[which(!i)[1L] - 1L]]
            pos <- grep("^[Ll]ocation: ", h, useBytes = TRUE)
            if(length(pos)) {
                loc <- sub("^[Ll]ocation: ([^\r]*)\r\n", "\\1",
                           h[pos[1L]])
                ## Ouch.  According to RFC 7231, the location is a URI
                ## reference, and may be relative in which case it needs
                ## resolving against the effect request URI.
                ## <https://www.rfc-editor.org/rfc/rfc7231#section-7.1.2>.
                ## Not quite straightforward, hence do not report such
                ## 301s. 
                ## (Alternatively, could try reporting the 301 but no
                ## new location.)
                newParts <- parse_URI_reference(loc)
                if(nzchar(newParts[1L, "scheme"])) {
                    newLoc <- loc
                    ## Handle fragments. If the new URL does have one,
                    ## use it. Otherwise, if the old has one, use that.
                    ## (From section 7.1.2).
                    if (newParts[1L, "fragment"] == "") {
                        uParts <- parse_URI_reference(u)
                        if (nzchar(uFragment <- uParts[1L, "fragment"])) {
                            newLoc <- paste0(newLoc, "#", uFragment)
                        }
                    }
                }
            }
        }
        ##
        if((s != "200") && use_curl) {
            g <- .curl_fetch_memory_status_code(u)
            if(g == "200") {
                s <- g
                msg <- "OK"
            }
        }
        ## A mis-configured site
        if (s == "503" && any(grepl("www.sciencedirect.com", c(u, newLoc))))
            s <- "405"
        c(s, msg, newLoc)
    }

    .check_http_B <- function(u) {
        ul <- tolower(u)
        cran <- ((grepl("^https?://cran.r-project.org/web/packages", ul) &&
                  !grepl("^https?://cran.r-project.org/web/packages/([.[:alnum:]_]+(html|pdf|rds))?$",
                         ul)) ||
                 (grepl("^https?://cran.r-project.org/web/views/[[:alnum:]]+[.]html$",
                        ul)) ||
                 startsWith(ul, "http://cran.r-project.org") ||
                 any(startsWith(ul, mirrors)))
        R <- grepl("^http://(www|bugs|journal).r-project.org", ul)
        spaces <- grepl(" ", u)
        c(if(cran) u else "", if(spaces) u else "", if(R) u else "")
    }

    bad <- .gather()

    if(!NROW(db)) return(bad)

    ## Could also use utils::getCRANmirrors(local.only = TRUE).
    mirrors <- c(utils::read.csv(file.path(R.home("doc"),
                                           "CRAN_mirrors.csv"),
                                 as.is = TRUE, encoding = "UTF-8")$URL,
                 "http://cran.rstudio.com/",
                 "https://cran.rstudio.com/")
    mirrors <- tolower(sub("/$", "", mirrors))

    if(inherits(db, "check_url_db")) {
        ## Allow re-checking check results.
        parents <- db$From
        urls <- db$URL
    } else {
        parents <- split(db$Parent, db$URL)
        urls <- names(parents)
    }

    parts <- parse_URI_reference(urls)

    ## Empty URLs.
    ind <- apply(parts == "", 1L, all)
    if(any(ind)) {
        len <- sum(ind)
        bad <- rbind(bad,
                     .gather(urls[ind],
                             parents[ind],
                             m = rep.int("Empty URL", len)))
    }

    ## Invalid URI schemes.
    schemes <- parts[, 1L]
    ind <- is.na(match(tolower(schemes),
                       c("",
                         IANA_URI_scheme_db$URI_Scheme,
                         "arxiv",
                         ## Also allow 'isbn' and 'issn', which in fact
                         ## are registered URN namespaces but not
                         ## registered URI schemes, see
                         ## <https://www.iana.org/assignments/urn-formal/isbn>
                         ## <https://www.iana.org/assignments/urn-formal/issn>
                         ## <https://doi.org/10.17487/rfc3986>
                         ## <https://doi.org/10.17487/rfc8141>.
                         "isbn", "issn",
                         ## Also allow 'javascript' scheme, see
                         ## <https://tools.ietf.org/html/draft-hoehrmann-javascript-scheme-03>
                         ## (but apparently never registered with IANA).
                         "javascript")))
    if(any(ind)) {
        len <- sum(ind)
        msg <- rep.int("Invalid URI scheme", len)
        doi <- schemes[ind] == "doi"
        if(any(doi))
            msg[doi] <- paste(msg[doi], "(use \\doi for DOIs in Rd markup)")
        bad <- rbind(bad,
                     .gather(urls[ind], parents[ind], m = msg))
    }
    
    ## Could check urn URIs at least for appropriate namespaces using
    ## <https://www.iana.org/assignments/urn-namespaces/urn-namespaces-1.csv>

    ## ftp.
    pos <- which(schemes == "ftp")
    if(length(pos) && remote) {
        urlspos <- urls[pos]
        headers <- .fetch_headers(urlspos)
        results <- do.call(rbind, Map(.check_ftp, urlspos, headers))
        status <- as.numeric(results[, 1L])
        ind <- (status < 0L) | (status >= 400L)
        if(any(ind)) {
            pos <- pos[ind]
            s <- as.character(status[ind])
            s[s == "-1"] <- "Error"
            m <- results[ind, 2L]
            m[is.na(m)] <- ""
            bad <- rbind(bad,
                         .gather(urls[pos], parents[pos], s, m))
        }
    }

    ## http/https.
    pos <- which(schemes == "http" | schemes == "https")
    if(length(pos) && remote) {
        urlspos <- urls[pos]
        ## Check DOI URLs via the DOI handle API, as we nowadays do for
        ## checking DOIs.
        myparts <- parts[pos, , drop = FALSE]
        ind <- (((myparts[, 2L] == "doi.org") | 
                 (myparts[, 2L] == "dx.doi.org")) &
                startsWith(myparts[, 3L], "/10.") &
                !nzchar(myparts[, 4L]) &
                !nzchar(myparts[, 5L]))
        if(any(ind))
            urlspos[ind] <- paste0("https://doi.org/api/handles",
                                   myparts[ind, 3L])
        ## Could also use regexps, e.g.
        ##    pat <- "^https?://(dx[.])?doi.org/10[.]([^?#]+)$"
        ##    ind <- grep(pat, urlspos)
        ##    if(length(ind))
        ##         urlspos[ind] <-
        ##             paste0("https://doi.org/api/handles/10.",
        ##                     sub(pat, "\\2", urlspos[ind]))
        ## but using the parts is considerably faster ...
        headers <- .fetch_headers(urlspos)
        if(parallel &&
           any(ind <- vapply(headers,
                             function(e) {
                                 if(inherits(e, "error")) -1L
                                 else attr(e, "status")
                             },
                             0L) != 200)) {
            ## We also re-check non-200 results in .check_http_A().
            ## Not very useful the way we currently show progress:
            ##   if(verbose)
            ##       message(sprintf("found %d non-OK responses, re-fetching ...",
            ##                       sum(ind)))
            headers[ind] <-
                .fetch_headers_via_curl(urlspos[ind],
                                        verbose, pool, FALSE)
        }
        results <- do.call(rbind, Map(.check_http, urlspos, headers))
        status <- as.numeric(results[, 1L])
        ## 405 is HTTP not allowing HEAD requests
        ## maybe also skip 500, 503, 504 as likely to be temporary issues
        ind <- is.na(match(status, c(200L, 405L, NA))) |
            nzchar(results[, 3L]) |
            nzchar(results[, 4L]) |
            nzchar(results[, 5L]) |
            nzchar(results[, 6L])
        if(any(ind)) {
            pos <- pos[ind]
            s <- as.character(status[ind])
            s[is.na(s)] <- ""
            s[s == "-1"] <- "Error"
            m <- results[ind, 2L]
            m[is.na(m)] <- ""
            bad_https <- .gather(urls[pos], parents[pos], s, m,
                                 results[ind, 3L],
                                 results[ind, 4L],
                                 results[ind, 5L],
                                 results[ind, 6L])
                                 
            ## omit some typically false positives
            ## for efficiency reasons two separate false positives tables for 403 and 404:
            false_pos_db_403 <- c(
                "^https?://twitter.com/", 
                "^https?://www.jstor.org/",
                "^https?://.+\\.wiley.com/", 
                "^https?://www.science.org/",
                "^https?://www.researchgate.net/",
                "^https?://www.tandfonline.com/",
                "^https?://pubs.acs.org/",
                "^https?://journals.aom.org/",
                "^https?://journals.sagepub.com/",
                "^https?://www.pnas.org/")
            false_pos_db_404 <- c(                
                "^https?://finance.yahoo.com/")
            bad_https <- bad_https[!((grepl(paste(false_pos_db_403, collapse="|"), bad_https$URL) & 
                                        bad_https$Status == "403") |
                                     (grepl(paste(false_pos_db_404, collapse="|"), bad_https$URL) & 
                                        bad_https$Status == "404")), , drop=FALSE]
            bad <- rbind(bad, bad_https)
        }
    }
    bad
}

format.check_url_db <-
function(x, ...)
{
    if(!NROW(x)) return(character())

    u <- x$URL
    new <- x$New
    ind <- nzchar(new)
    if(any(ind)) {
        u[ind] <- sprintf("%s (moved to %s)", u[ind], new[ind])
        if(config_val_to_logical(Sys.getenv("_R_CHECK_URLS_SHOW_301_STATUS_",
                                            "FALSE"))) {
            x$Message[ind] <- "Moved Permanently"
            x$Status[ind] <- "301"
        }
    }

    paste0(sprintf("URL: %s", u),
           sprintf("\nFrom: %s",
                   vapply(x$From, paste, "", collapse = "\n      ")),
           ifelse((s <- x$Status) == "",
                  "",
                  sprintf("\nStatus: %s", s)),
           ifelse((m <- x$Message) == "",
                  "",
                  sprintf("\nMessage: %s", gsub("\n", "\n  ", m, fixed=TRUE))),
           ifelse((m <- x$Spaces) == "",
                  "",
                  "\nURL contains spaces"),
           ifelse((m <- x$CRAN) == "",
                  "",
                  "\nCRAN URL not in canonical form"),
           ifelse((m <- x$R) == "",
                  "",
                  "\nR-project URL not in canonical form")
           )
}

print.check_url_db <-
function(x, ...)
{
    if(NROW(x))
        writeLines(paste(format(x), collapse = "\n\n"))
    invisible(x)
}

as.matrix.check_url_db <-
function(x, ...)
{
    n <- lengths(x[["From"]])
    y <- do.call(cbind,
                 c(list(URL = rep.int(x[["URL"]], n),
                        Parent = unlist(x[["From"]])),
                   lapply(x[-c(1L, 2L)], rep.int, n)))
    rownames(y) <- NULL
    y
}

.fetch_headers_via_base <-
function(urls, verbose = FALSE, ids = urls)
    Map(function(u, verbose, i) {
            if(verbose) message(sprintf("processing %s", i))
            tryCatch(curlGetHeaders(u), error = identity)
        },
        urls, verbose, ids)

.fetch_headers_via_curl <-
function(urls, verbose = FALSE, pool = NULL, nobody = TRUE)
{
    out <- .curl_multi_run_worker(urls, nobody, verbose, pool)
    ind <- !vapply(out, inherits, NA, "error")
    if(any(ind))
        out[ind] <- lapply(out[ind],
                           function(x) {
                               y <- strsplit(rawToChar(x$headers),
                                             "(?<=\r\n)",
                                             perl = TRUE)[[1L]]
                               attr(y, "status") <- x$status_code
                               y
                           })
    out
}

.curl_multi_run_worker <-
function(urls, nobody = FALSE, verbose = FALSE, pool = NULL,
         opts = NULL, hdrs = NULL)
{
    ## Use 'nobody = TRUE' to fetch only headers.
    
    .progress_bar <- function(length, msg = "") {
        bar <- new.env(parent = baseenv())
        if(is.null(length)) {
            length <- 0L
        }
        done <- fmt <- NULL             # make codetools happy
        bar$length <- length
        bar$done <- -1L
        digits <- trunc(log10(length)) + 1L
        bar$fmt <- paste0("\r", msg, "[ %", digits, "i / %", digits, "i ]")
        bar$update <- function() {
            assign("done", inherits = TRUE, done + 1L)
            if (length <= 0L) {
                return()
            }
            if (done >= length) {
                cat("\r", strrep(" ", nchar(fmt)), "\r", sep = "",
                    file = stderr())
            } else {
                cat(sprintf(fmt, done, length), sep = "",
                    file = stderr())
            }
        }
        environment(bar$update) <- bar
        bar$update()
        bar
    }

    if(is.null(pool))
        pool <- curl::new_pool()

    if(is.null(opts))
        opts <- .curl_handle_default_opts
    opts <- c(opts, list(nobody = nobody))
    timeout <- as.integer(getOption("timeout"))
    if(!is.na(timeout) && (timeout > 0L))
        opts <- c(opts,
                  list(connecttimeout = timeout,
                       timeout = timeout))

    if(is.null(hdrs))
        hdrs <- .curl_handle_default_hdrs

    bar <- .progress_bar(if (verbose) length(urls), msg = "fetching ")    

    out <- vector("list", length(urls))

    for(i in seq_along(out)) {
        u <- urls[[i]]
        h <- curl::new_handle(url = u)
        curl::handle_setopt(h, .list = opts)
        if(length(hdrs))
            curl::handle_setheaders(h, .list = hdrs)
        if((startsWith(u, "https://github.com/") ||
            (u == "https://github.com")) &&
           nzchar(a <- Sys.getenv("GITHUB_PAT", ""))) {
            curl::handle_setheaders(h, "Authorization" = paste("token", a))
        }
        handle_result <- local({
            i <- i
            function(x) {
                out[[i]] <<- x
                bar$update()
            }
        })
        handle_error <- local({
            i <- i
            function(x) {
                out[[i]] <<-
                    structure(list(message = x),
                              class = c("curl_error", "error", "condition"))
                bar$update()
            }
        })
        curl::multi_add(h,
                        done = handle_result,
                        fail = handle_error,
                        pool = pool)
    }

    curl::multi_run(pool = pool)
   
    out
}

.curl_fetch_memory_status_code <-
function(u, verbose = FALSE, opts = NULL, hdrs = NULL)
{
    if(verbose)
        message(sprintf("processing %s", u))

    if(is.null(opts))
        opts <- .curl_handle_default_opts
    timeout <- as.integer(getOption("timeout"))
    if(!is.na(timeout) && (timeout > 0L))
        opts <- c(opts,
                  list(connecttimeout = timeout,
                       timeout = timeout))

    if(is.null(hdrs))
        hdrs <- .curl_handle_default_hdrs
    
    ## Configure curl handle for better luck with JSTOR URLs/DOIs.
    ## Alternatively, special-case requests to
    ##   https?://doi.org/10.2307
    ##   https?://www.jstor.org
    h <- curl::new_handle()
    curl::handle_setopt(h, .list = opts)
    if(length(hdrs))
        curl::handle_setheaders(h, .list = hdrs)
    if((startsWith(u, "https://github.com/") ||
            (u == "https://github.com")) &&
       nzchar(a <- Sys.getenv("GITHUB_PAT", "")))
        curl::handle_setheaders(h, "Authorization" = paste("token", a))
    
    g <- tryCatch(curl::curl_fetch_memory(u, handle = h),
                  error = identity)
    .curl_response_status_code(g)
}

.curl_response_status_code <-
function(x)
{
    if(inherits(x, "error")) -1L else x$status_code
}

.curl_handle_default_opts <-
    list(cookiesession = 1L,
         followlocation = 1L)

.curl_handle_default_hdrs <-
    list("User-Agent" =
             Sys.getenv("_R_CHECK_URLS_CURL_USER_AGENT_", "curl"))

check_package_urls <-
function(dir, verbose = FALSE)
{
    db <- url_db_from_package_sources(dir)
    check_url_db(db, verbose = verbose, parallel = TRUE)
}
