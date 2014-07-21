
#' @title Dynamic Network Model Estimation
#'
#' @description Estimates statistical network models using the exponential
#'              random graph modeling (ERGM) framework with extensions for
#'              dynamic/temporal models (STERGM).
#'
#' @param nw an object of class \code{\link{network}}.
#' @param formation a right-hand sided STERGM formation formula in the form
#'        \code{~ edges + ...}, where \code{...} are additional network statistics.
#' @param dissolution a right-hand sided STERGM dissolution formula of the form
#'        \code{~ offset(edges)}. This dissolution model is the only model currently
#'        supported in \code{EpiModel}.
#' @param target.stats a vector of target statistics for the formation model, with
#'        one number for each network statistic in the model (see \code{\link{stergm}}).
#' @param coef.diss an object of class \code{disscoef} output from the
#'        \code{\link{dissolution_coefs}} function.
#' @param constraints a right-hand sided formula specifying contraints for the
#'        modeled network, in the form \code{~...}, where \code{...} are constraint
#'        terms described in \code{\link{stergm}}. By default, no constraints are set.
#' @param coef.form A vector of coefficients for the offset terms in the formation
#'        formula.
#' @param edapprox if \code{TRUE}, use the indirect edges dissolution approximation
#'        method for the dynamic model fit, otherwise use the more time-intensive
#'        full STERGM estimation (see details).
#' @param set.control.ergm control arguments passed to simulate.ergm (see
#'        details).
#' @param set.control.stergm control arguments passed to simulate.stergm (see
#'        details).
#' @param verbose print progress to the console.
#'
#' @details
#' \code{netest} is a wrapper function for the \code{ergm} and \code{stergm}
#' functions that estimate static and dynamic network models, respectively.
#' Network model estimation is the first step in simulating a stochastic network
#' epidemic model in \code{EpiModel}. The output from \code{netest} is a
#' necessary input for running the epidemic simulations in \code{\link{netsim}}.
#' With a fitted network model, one should always first proceed to model
#' diagnostics, available through the \code{\link{netdx}} function, to check
#' model fit. A detailed description of fitting these models, along with examples,
#' may be found in Section 4 of the
#' \href{http://statnet.org/EpiModel/vignette/Tutorial.pdf}{EpiModel Tutorial}.
#'
#' @section Edges Dissolution Approximation:
#' The edges dissolution approximation method is described in Carnegie et al.
#' This approximation requires that the dissolution coefficients are known, that
#' the formation model is being fit to cross-sectional data conditional on those
#' dissolution coefficients, and that the terms in the dissolution model are a
#' subset of those in the formation model. Under certain additional conditions,
#' the formation coefficients of a STERGM model are approximately equal to the
#' coefficients of that same model fit to the observed cross-sectional data as
#' an ERGM, minus the corresponding coefficients in the dissolution model. The
#' approximation thus estimates this ERGM (which is typically much faster than
#' estimating a STERGM) and subtracts the dissolution coefficients.
#'
#' The conditions under which this approximation best hold are when there are
#' few relational changes from one time step to another; i.e. when either average
#' relational durations are long, or density is low, or both.  Conveniently,
#' these are the same conditions under which STERGM estimation is slowest.  Note
#' that the same approximation is also used to obtain starting values for the
#' STERGM estimate when the latter is being conducted.  The estimation does not
#' allow for calculation of standard errors, p-values, or likelihood for the
#' formation model; thus, this approach is of most use when the main goal of
#' estimation is to drive dynamic network simulations rather than to conduct
#' inference on the formation model. The user is strongly encouraged to examine
#' the behavior of the resulting simulations to confirm that the approximation
#' is adequate for their purposes. For an example, see this
#' \href{http://statnet.org/workshops/SUNBELT/current/tergm/tergm_tutorial.html}{STERGM
#' Tutorial}.
#'
#' @section Control Arguments:
#' The \code{ergm} and \code{stergm} functions allow control settings for the
#' model fitting process. When fitting a STERGM directly (setting \code{edapprox}
#' to \code{FALSE}) control parameters may be passed to the \code{stergm}
#' function with the \code{set.control.stergm} argument in \code{netest}. The
#' controls should be input through the \code{control.stergm()} function, with
#' the available parameters listed in the \code{\link{control.stergm}} help page
#' in the \code{tergm} package.
#'
#' When fitting a STERGM indirectly (setting \code{edapprox} to \code{TRUE})
#' control settings may be passed to the \code{ergm} function using
#' \code{set.control.ergm} in \code{netest}. The controls should be input through
#' the \code{control.ergm()} function, with the available parameters listed in the
#' \code{\link[ergm:control.simulate.ergm]{control.simulate.ergm}} help page in
#' the \code{ergm} package. An example is below.
#'
#' @references
#' Krivitsky PN, Handcock MS. "A separable model for dynamic networks." JRSS(B).
#' 2014; 76.1:29-46.
#'
#' Carnegie NB, Krivitsky PN, Hunter DR, Goodreau SM. An approximation method for
#' improving dynamic network model fitting. Journal of Computational and Graphical
#' Statistics. 2014; In press.
#'
#' @keywords model
#' @seealso Use \code{\link{netdx}} to diagnose the fitted network model, and
#'          \code{\link{netsim}} to simulate epidemic spread over a simulated
#'          dynamic network consistent with the model fit.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize a network of 100 nodes
#' nw <- network.initialize(n = 100, directed = FALSE)
#'
#' # Set formation and dissolution formulas
#' formation <- ~ edges + concurrent
#' dissolution <- ~ offset(edges)
#'
#' # Set target statistics for formation
#' target.stats <- c(50, 25)
#'
#' # Obtain the offset coefficients
#' coef.diss <- dissolution_coefs(dissolution, duration = 10)
#'
#' # Estimate the STERGM using the edges dissolution approximation
#' est <- netest(nw,
#'               formation,
#'               dissolution,
#'               target.stats,
#'               coef.diss,
#'               set.control.ergm = control.ergm(MCMC.burnin = 1e5,
#'                                               MCMC.interval = 1000))
#' est
#'
#' # Estimate the STERGM directly
#' est2 <- netest(nw,
#'                formation,
#'                dissolution,
#'                target.stats,
#'                coef.diss,
#'                edapprox = FALSE)
#' est2
#' }
#'
netest <- function(nw,
                   formation,
                   dissolution,
                   target.stats,
                   coef.diss,
                   constraints,
                   coef.form = NULL,
                   edapprox = TRUE,
                   set.control.ergm,
                   set.control.stergm,
                   verbose = TRUE) {


	formation.nw <- update(formation, nw ~.)
  environment(formation.nw) <- environment()

  if (missing(constraints)) {
    constraints	<- ~.
  }
  environment(constraints) <- environment()

	if (dissolution != ~ offset(edges)) {
	  stop("Currently only ~offset(edges) dissolution models supported")
	}

  if (edapprox == FALSE) {

    if (verbose == TRUE) {
      cat("======================")
      cat("\nFitting STERGM")
      cat("\n======================\n")
    }

    if (missing(set.control.stergm)) {
      set.control.stergm <- control.stergm(EGMME.MCMC.burnin.min = 1e5)
    }

    fit <- stergm(nw,
                  formation = formation,
                  dissolution = dissolution,
                  targets = "formation",
                  target.stats = target.stats,
                  offset.coef.form = coef.form,
                  offset.coef.diss = coef.diss$coef.crude,
                  constraints = constraints,
                  estimate = "EGMME",
                  control = set.control.stergm)

    coef.form <- fit$formation.fit

    out <- list()
    out$fit <- fit
    out$formation <- formation
    out$target.stats <- target.stats
    out$coef.form <- coef.form$coef
    out$dissolution <- dissolution
    out$coef.diss <- coef.diss
    out$constraints <- constraints
    out$edapprox <- edapprox

  } else {

    if (verbose == TRUE) {
      cat("======================")
      cat("\nFitting ERGM")
      cat("\n======================\n")
    }

    if (missing(set.control.ergm)) {
      set.control.ergm <- control.ergm(MCMC.burnin = 1e5,
                                       MCMLE.maxit = 200)
    }

    fit <- ergm(formation.nw,
                target.stats = target.stats,
                constraints = constraints,
                offset.coef = coef.form,
                control = set.control.ergm)

    coef.form <- fit$coef
    if (coef.diss$coef.crude > -Inf) {
      for (i in 1:length(coef.diss$coef.crude)) {
        coef.form[i] <- coef.form[i] - coef.diss$coef.crude[i]
      }
    }

    out <- list()
    out$fit <- fit
    out$formation <- formation
    out$target.stats <- target.stats
    out$coef.form <- coef.form
    out$dissolution <- dissolution
    out$coef.diss <- coef.diss
    out$constraints <- constraints
    out$edapprox <- edapprox

  }

  class(out) <- "netest"
  return(out)
}
