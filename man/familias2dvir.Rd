% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/familias2dvir.R
\name{familias2dvir}
\alias{familias2dvir}
\title{Convert a Familias file to DVI data}
\usage{
familias2dvir(
  famfile,
  victimPrefix = NULL,
  familyPrefix = NULL,
  refPrefix = NULL,
  missingPrefix = NULL,
  missingFormat = NULL,
  othersPrefix = NULL,
  verbose = FALSE,
  missingIdentifier = "^Missing"
)
}
\arguments{
\item{famfile}{Path to Familias file.}

\item{victimPrefix}{Prefix used to label PM individuals.}

\item{familyPrefix}{Prefix used to label the AM families.}

\item{refPrefix}{Prefix used to label the reference individuals, i.e., the
typed members of the AM families.}

\item{missingPrefix}{Prefix used to label the missing persons. At most one of
\code{missingPrefix} and \code{missingFormat} can be given.}

\item{missingFormat}{A string indicating family-wise labelling of missing
persons, using \verb{[FAM]}, \verb{[IDX]}, \verb{[MIS]} as place holders with the
following meanings (see Examples):
\itemize{
\item \verb{[FAM]}: family index
\item \verb{[IDX]}: index of missing person within the family
\item \verb{[MIS]}: index within all missing persons
}}

\item{othersPrefix}{Prefix used to label other untyped individuals. Use ""
for numeric labels ( 1, 2, ...).}

\item{verbose}{A logical, passed on to \code{readFam()}.}

\item{missingIdentifier}{A character of length 1 used to identify missing
persons in the Familias file. The default chooses everyone whose label
begins with "Missing".}
}
\value{
A \code{dviData} object.
}
\description{
This is a wrapper for \code{\link[pedFamilias:readFam]{pedFamilias::readFam()}} that reads Familias files with
DVI information.
}
\details{
The sex of the missing persons need to be checked as this
information may not be correctly recorded in the fam file.
}
\examples{

# Family with three missing
file = system.file("extdata", "dvi-example.fam", package="dvir")

# Read file without relabelling
y = familias2dvir(file)
plotDVI(y)

# With relabelling
z = familias2dvir(file, missingFormat = "M[FAM]-[IDX]",
                   refPrefix = "ref", othersPrefix = "E")
plotDVI(z)

}
\seealso{
\code{\link[=dviData]{dviData()}}, \code{\link[=relabelDVI]{relabelDVI()}}
}
