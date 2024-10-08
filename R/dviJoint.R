#' Joint DVI search
#'
#' This is a redesign of [jointDVI()], with narrower scope (no preprocessing
#' steps) and more informative output. The output includes the pairwise GLR
#' matrix based on the joint table.
#'
#' @param dvi A `dviData` object, typically created with [dviData()].
#' @param assignments A data frame containing the assignments to be considered
#'   in the joint analysis. By default, this is automatically generated by
#'   taking all combinations from `dvi$pairings`.
#' @param disableMutations Either TRUE, FALSE (default) or NA. If NA, mutation
#'   modelling is applied only in families where the reference data are
#'   incompatible with the pedigree unless at least one mutation has occurred.
#' @param ignoreSex A logical, only relevant if `dvi$pairings` is NULL, so that
#'   candidate pairings have to be generated.
#' @param maxAssign A positive integer. If the number of assignments going into
#'   the joint calculation exceeds this, the function will abort with an
#'   informative error message. Default: 1e5.
#' @param numCores An integer; the number of cores used in parallelisation.
#'   Default: 1.
#' @param cutoff A number; if non-negative, the output table is restricted to
#'   LRs equal to or exceeding this value.
#' @param verbose A logical.
#' @param progress A logical, indicating if a progress bar should be shown.
#'
#' @return A data frame.
#' @examples
#' dviJoint(example2)
#'
#' @export
dviJoint = function(dvi, assignments = NULL, ignoreSex = FALSE, disableMutations = FALSE, 
                    maxAssign = 1e5, numCores = 1, cutoff = 0, verbose = TRUE, progress = verbose) {
  
  # Ensure proper dviData object
  dvi = consolidateDVI(dvi)
  
  if(verbose)
    print.dviData(dvi)
  
  ### Mutation disabling
  if(any(allowsMutations(dvi$am))) {
    am = dvi$am
    
    if(verbose) 
      cat("\nMutation modelling:\n")
    
    if(isTRUE(disableMutations)) {
      if(verbose) cat(" Disabling mutations in all families\n")
      disableFams = seq_along(am)
    }
    else if(identical(disableMutations, NA)) {
      am.nomut = setMutmod(am, model = NULL)
      badFams = vapply(am.nomut, loglikTotal, FUN.VALUE = 1) == -Inf
      if(verbose) {
        if(any(badFams)) 
          cat("", sum(badFams), "inconsistent families:", trunc(which(badFams)), "\n")
        cat("", sum(!badFams), "consistent families. Disabling mutations in these\n")
      }
      disableFams = which(!badFams)
    }
    else disableFams = NULL
  
    if(length(disableFams)) {
      am[disableFams] = setMutmod(am[disableFams], model = NULL)
    }
    
    # Update DVI object
    dvi$am = am
  }
  
  pm = dvi$pm 
  am = dvi$am
  vics = names(pm)
  pairings = dvi$pairings %||% generatePairings(dvi, ignoreSex = ignoreSex)
  
  if(is.null(assignments)) {
    if(verbose) cat("\nCalculating pairing combinations...")
    # Expand pairings to assignment data frame
    assignments = expand.grid.nodup(pairings, max = maxAssign)
    if(verbose) cat(nrow(assignments), "\n")
  }
  else {
    if(verbose) cat("\nSupplied pairing combinations: ")
    if(!setequal(names(assignments), vics))
      stop2("Names of `assignments` do not match `pm` names")
    assignments = assignments[vics]
    if(verbose) cat(nrow(assignments), "\n")
  }
  
  nAss = nrow(assignments)
  if(nAss == 0)
    stop2("No possible solutions")
  
  # Initial loglikelihoods
  logliks.PM = vapply(pm, loglikTotal, FUN.VALUE = 1)
  logliks.AM = vapply(am, loglikTotal, FUN.VALUE = 1)
  
  loglik0 = sum(logliks.PM) + sum(logliks.AM)
  if(loglik0 == -Inf)
    stop2("Impossible initial data: AM component ", which(logliks.AM == -Inf))
  
  # Parallelise?
  if(is.na(numCores))
    numCores = max(detectCores() - 1, 1)

  cl = NULL
  if(numCores > 1) {
    if(verbose) 
      cat("Using", numCores, "cores\n")
    
    cl = makeCluster(numCores)
    on.exit(stopCluster(cl))
    clusterEvalQ(cl, library(dvir))
    clusterExport(cl, "loglikAssign", envir = environment())
  }
  
  # Convert to list; more handy below
  assignmentList = lapply(1:nAss, function(i) as.character(assignments[i, ]))
  
  # Max 20 chunks to each worker (to reduce overhead but maintain informative PB)
  assignmentList = split(assignmentList, cut(1:nAss, numCores * 20, labels = FALSE))
  
  # Progress bar?
  op = pboptions(type = if(progress) "timer" else "none")
  
  # Main calculation
  loglik = pblapply(cl = cl, assignmentList, function(chunk)
    lapply(chunk, function(a) loglikAssign(pm, am, vics, a, loglik0, logliks.PM, logliks.AM)))
  
  op = pboptions(type = if(progress) "timer" else "none")

  loglik = unlist(loglik, use.names = FALSE)
  
  # Sort in decreasing likelihood, break ties with assignments (alphabetically)
  g = assignments
  g[g == "*"] = NA
  g = cbind(ll = -loglik, g)
  ORD = do.call(order, g)

  assignments = assignments[ORD, , drop = FALSE]
  rownames(assignments) = NULL
  
  # Sorted (joint) logliks and LR
  loglik = loglik[ORD]
  
  # Skip these!?
  #LR = exp(loglik - loglik0) # joint LR
  #posterior = LR/sum(LR) # assuming flat prior
  
  # Collect joint results, including both PM and AM centric assignment tables
  joint = cbind(assignments, loglik = loglik, # LR = LR, posterior = posterior, 
                swapOrientation(assignments))
  joint
}


#' Swap orientation of an assignment table
#'
#' This function switches the roles of victims and missing persons in a table of
#' assignments, from PM-oriented (victims as column names) to AM-oriented (missing
#' persons as column names), and _vice versa_. In both version, each row
#' describes the same assignment vector.
#'
#' @param df A data frame. Each row is an assignment, with `*` representing
#'   non-pairing.
#' @param from A character vector; either victims or missing persons. By
#'   default, the column names of `df`. The only time this argument is needed,
#'   if when `df` has other columns in addition, as in output tables of
#'   `dviJoint()`.
#' @param to The column names of the transformed data frame. If missing, the
#'   unique elements of `df` are used. An error is raised if `to` does not
#'   contain all elements of `df` (except `*`).
#'
#' @return A data frame with `nrow(df)` rows and `length(to)` columns.
#'
#' @examples
#' df = example1 |> generatePairings() |> expand.grid.nodup()
#' df
#' swapOrientation(df)
#' 
#' # Swap is idempotent
#' stopifnot(identical(swapOrientation(swapOrientation(df)), df))
#' 
#' @export
swapOrientation = function(df, from = NULL, to = NULL) {

  if(is.null(from))
    from = names(df)
  
  # Matrix for speed
  amat = as.matrix(df[from])
  
  if(is.null(to))
    to = setdiff(sort.default(unique.default(amat)), "*")
  
  dims = dim(amat)
  
  # Match
  toExt = c(to, "*")
  idx = match(amat, toExt, nomatch = 0L)
  if(any(idx == 0))
     stop2("Table entry not included in `to`: ", setdiff(amat, toExt))
  idx[idx == length(toExt)] = 0L
  dim(idx) = dims
  
  # Melt to long format
  long = cbind(which(idx > 0, arr.ind = TRUE), 
               val = idx[idx > 0])
  
  # Create result matrix
  new = matrix("*", nrow = dims[1], ncol = length(to), dimnames = list(NULL, to))
  
  # Pivot back to wide
  new[long[, c(1,3)]] = from[long[,2]]
  
  res = as.data.frame(new)
  if(ncol(df) > length(from))
    res = cbind(res, df[!names(df) %in% from])
  res
}

