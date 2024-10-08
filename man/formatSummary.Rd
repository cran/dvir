% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/formatSummary.R
\name{formatSummary}
\alias{formatSummary}
\title{Format final summary table}
\usage{
formatSummary(dfs, orientation = c("AM", "PM"), columns = NULL, dvi = NULL)
}
\arguments{
\item{dfs}{A list of data frames.}

\item{orientation}{Either "AM" or "PM", controlling column order and sorting.}

\item{columns}{A (optional) character vector with column names in the wanted
order.}

\item{dvi}{A \code{dviData} object used for sorting. Note that if given, this must
contain all victims and families.}
}
\value{
A data frame.
}
\description{
Combines and harmonises summary tables from different DVI analyses
}
\details{
The default column order is controlled by \code{orientation}, which the following
effect:
\itemize{
\item \code{AM}:
\itemize{
\item Column order: \code{Family}, \code{Missing}, \code{Sample}, \code{LR}, \code{GLR}, \code{Conclusion}, \code{Comment}
\item Sort by: \code{Family} and \code{Missing}
}
\item \code{PM}:
\itemize{
\item Column order: \code{Sample}, \code{Missing}, \code{Family}, \code{LR}, \code{GLR}, \code{Conclusion}, \code{Comment}
\item Sort by: \code{Sample}
}
}

Columns (in any of the data frames) other than these are simply ignored.
}
\examples{
u = findUndisputed(planecrash)
a = amDrivenDVI(u$dviReduced, threshold2 = 500)

u$summary
a$summary

formatSummary(list(u$summary, a$summary$AM))
formatSummary(list(u$summary, a$summary$PM), orientation = "PM", dvi = planecrash)

}
