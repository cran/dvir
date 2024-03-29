% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dviSim.R
\name{dviSim}
\alias{dviSim}
\title{Simulate genotypes in a DVI dataset}
\usage{
dviSim(
  dvi,
  refs = typedMembers(dvi$am),
  truth = NULL,
  seed = NULL,
  verbose = FALSE
)
}
\arguments{
\item{dvi}{A \code{dviData} object.}

\item{refs}{A character with names of all reference individuals. By default,
the typed members of the input.}

\item{truth}{A named vector of the format \code{c(vic1 = mis1, vic2 = mis2, ...)}.}

\item{seed}{An integer seed for the random number generator.}

\item{verbose}{A logical.}
}
\value{
A \code{dviData} object similar to the input.
}
\description{
Simulates genotypes for the references and missing persons in each AM family,
transfers to the PM singletons according to the indicated matching. Remaining
victims are simulated as unrelated.
}
\examples{
ex = dviSim(example2, truth = c(V1 = "M1", V2 = "M2"))
plotDVI(ex, marker = 1)

}
\seealso{
\code{\link[forrel:profileSim]{forrel::profileSim()}}.
}
