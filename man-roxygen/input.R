#' @param X Attribute table, given as a data frame with either factors (preferred), booleans, integers (treated as categorical) or reals (which undergo automatic categorisation; see below for details).
#' \code{NA}s are not allowed.
#' @param Y Decision attribute; should be given as a factor, but other options are accepted, exactly like for attributes.
#' \code{NA}s are not allowed.
#' @note The method requires input to be discrete to use empirical estimators of distribution, and, consequently, information gain or entropy.
#' To allow smoother user experience, praznik automatically coerces non-factor vectors in \code{X} and \code{Y}, which requires additional time and space and may yield confusing results -- the best practice is to convert data to factors prior to feeding them in this function.
#' Real attributes are cut into about 10 equally-spaced bins, following the heuristic often used in literature.
#' Precise number of cuts depends on the number of objects; namely, it is \eqn{n/3}, but never less than 2 and never more than 10.
#' Integers (which technically are also numeric) are treated as categorical variables (for compatibility with similar software), so in a very different way -- one should be aware that an actually numeric attribute which happens to be an integer could be coerced into a \eqn{n}-level categorical, which would have a perfect mutual information score and would likely become a very disruptive false positive.

