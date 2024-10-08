#' @title Principal Component Analysis for PSA Comparison
#' @description A wrapper function of `princomp()` for comparison to PSA. Manipulates
#' result of `princomp()` in a similar format to `psa()`.
#' 
#' @param X a data matrix.
#' @return A list
#' + pts.approx a list of lower dimensional representations with respect to the original basis
#' + scores a matrix of scores.
#' + rss a vector of residual sums of squares.
#' + modes a list of modes of variation. The $r$th element of the list is the difference of 
#' rank $r$ approximations to rank $r-1$ approximations.
#' + loadings a matrix of loading vectors.
#' + center mean of the data
#' @seealso [psa()]
#' 
#' @export
comp_pca <- function(X){
  n = nrow(X)
  d = ncol(X)-1
  var.names = colnames(X)
  
  res = list(pts.approx = list(), scores = NULL, rss = 0, modes = list(),
             loadings = NULL, center = NULL)
  X.pca = stats::princomp(X)
  
  n = nrow(X)
  d = ncol(X)-1
  
  res$pts.approx[['r=1']] = matrix(rep(X.pca$center, n), byrow=T, nrow = n, ncol = d+1)
  for(i in 1:d){
    res$pts.approx[[paste0('r=',i+1)]] = res$pts.approx[[paste0('r=',i)]] +
      as.matrix(X.pca$scores[,i]) %*% t(X.pca$loadings[,i])
  }
  res$scores = X.pca$scores
  res$rss = colSums(res$scores^2)
  
  res$modes[[paste0('r=',d+1)]] = matrix(NA, n, d+1)
  colnames(res$modes[[paste0('r=',d+1)]]) = var.names
  for(i in d:1){
    res$modes[[paste0('r=',i)]] = res$pts.approx[[paste0('r=',i+1)]] - res$pts.approx[[paste0('r=',i)]]
  }
  res$modes = res$modes[(d+1):1]
  
  res$loadings = X.pca$loadings
  class(res$loadings) <- 'matrix'
  res$center = X.pca$center
  
  return(res)
}


#' @title Log-Ratio Principal Component Analysis for PSA Comparison
#' @description A wrapper function of `princomp.acomp()` for comparison to PSA.
#' Zeros are substituted by half of the overall nonzero minimum. Manipulates
#' result of `princomp.acomp()` in a similar format to `psa()`.
#' 
#' @param X a data matrix.
#' @inherit comp_pca return
#' @seealso [comp_pca()], [psa()]
#' 
#' @export
comp_apca <- function(X){
  
  if(min(X) < 0){
    stop('X contains negative values')
  }
  
  if(min(X) <= 0){
    warning('X contains zero values')
    x.min = min(X[X>0])
    X[X<=0] = 0.5*x.min # substitute zeros by 0.5 times the minimum value
    X = to_simplex(X)
  }
  
  n = nrow(X)
  d = ncol(X)-1
  var.names = colnames(X)
  
  res = list(pts.approx = list(), scores = NULL, rss = 0, modes = list(),
             loadings = NULL, center = NULL)
  X.apca = stats::princomp(compositions::acomp(X))

  ## representations in clr coordinate
  res$pts.approx[['r=1']] = matrix(rep(X.apca$center, n), byrow=T, nrow = n, ncol = d+1)
  colnames(res$pts.approx[['r=1']]) = var.names
  for(i in 1:d){
    res$pts.approx[[paste0('r=',i+1)]] = res$pts.approx[[paste0('r=',i)]] +
      as.matrix(X.apca$scores[,i]) %*% t(X.apca$loadings[,i])
  }
  res$scores = X.apca$scores
  res$rss = colSums(res$scores^2)
  
  ## representations in simplex coordinate
  for(i in 1:(d+1)){
    m = clrInv(res$pts.approx[[paste0('r=',i)]])
    class(m) = 'numeric'
    res$pts.approx[[paste0('r=',i)]] = m
  }
  
  res$modes[[paste0('r=',d+1)]] = matrix(NA, n, d+1)
  colnames(res$modes[[paste0('r=',d+1)]]) = var.names
  for(i in d:1){
    res$modes[[paste0('r=',i)]] = res$pts.approx[[paste0('r=',i+1)]] - res$pts.approx[[paste0('r=',i)]]
  }
  res$modes = res$modes[(d+1):1]
  
  res$loadings = X.apca$loadings
  class(res$loadings) <- 'matrix'
  res$center = X.apca$center
  
  return(res)
}

#' @title Power Transform Principal Component Analysis for PSA Comparison
#' @description A wrapper function of `princomp()` applied to power transformed data. 
#' 
#' @param X a data matrix.
#' @param alpha a scalar $\alpha>0$ for power transform.
#' @inherit comp_pca return
#' @seealso [comp_pca()], [psa()]
#' 
#' @export
power_pca <- function(X, alpha = 1/2){
  X = X^alpha
  res = comp_pca(X)
  return(res)
}
