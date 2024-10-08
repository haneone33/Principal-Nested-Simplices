to_simplex <- function(X){
  if(min(X)<0){
    warning('X contains negative values')
    X = pmax(X, 0)
  }
  X = t(apply(X, 1, function(x){  
    x = x/sum(x)
  }))
  return(X)
}