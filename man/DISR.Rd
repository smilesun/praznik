% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/algorithms.R
\name{DISR}
\alias{DISR}
\title{Double input symmetrical relevance filter}
\usage{
DISR(X, Y, k = 3)
}
\arguments{
\item{X}{Attribute table, given as a data frame with either factors (preferred), booleans, integers (treated as categorical) or reals (which undergo automatic categorisation; see below for details).
\code{NA}s are not allowed.}

\item{Y}{Decision attribute; should be given as a factor, but other options are accepted, exactly like for attributes.
\code{NA}s are not allowed.}

\item{k}{Number of attributes to select.
Must not exceed \code{ncol(X)}.}
}
\value{
A list with two elements: \code{selection}, a vector of indices of the selected features in the selection order, and \code{score}, a vector of corresponding feature scores.
Names of both vectors will correspond to the names of features in \code{X}.
Both vectors will either have a length \code{k} or zero, when all features turn out to have zero mutual information with the decision.
}
\description{
The method starts with an attribute of a maximal mutual information with the decision \eqn{Y}.
Then, it greedily adds attribute \eqn{X} with a maximal value of the following criterion:
\deqn{J(X)=\sum_{W\in S} \frac{I(X,W;Y)}{H(X,W,Y)},}
where \eqn{S} is the set of already selected attributes.
}
\note{
DISR is a normalised version of \code{\link{JMI}}; \code{\link{JMIM}} and \code{\link{NJMIM}} are modifications of JMI and DISR in which minimal joint information over already selected attributes is used instead of a sum.

The method requires input to be discrete to use empirical estimators of distribution, and, consequently, information gain or entropy.
To allow smoother user experience, praznik automatically coerces non-factor vectors in \code{X} and \code{Y}, which requires additional time and space and may yield confusing results -- the best practice is to convert data to factors prior to feeding them in this function.
Real attributes are cut into about 10 equally-spaced bins, following the heuristic often used in literature.
Precise number of cuts depends on the number of objects; namely, it is \eqn{n/3}, but never less than 2 and never more than 10.
Integers (which technically are also numeric) are treated as categorical variables (for compatibility with similar software), so in a very different way -- one should be aware that an actually numeric attribute which happens to be an integer could be coerced into a \eqn{n}-level categorical, which would have a perfect mutual information score and would likely become a very disruptive false positive.
}
\examples{
data(MadelonD)
DISR(MadelonD$X,MadelonD$Y,20)
}
\references{
"On the Use of Variable Complementarity for Feature Selection in Cancer Classification" P. Meyer and G. Bontempi, (2006)
}
