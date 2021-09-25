centroid <- function(x){
  l <- vector(mode = "list", length = ncol(x))
  for (j in 1:ncol(x)){
    if (is.numeric(x[j][[1]])){
      l[[j]] <- mean(x[j][[1]])
    }else if (is.factor(x[j][[1]])){
      l[[j]] <- summary(x[j][[1]])/nrow(x)
    }
  }
  names(l) <- colnames(x)
  l
}

cat_dist <- function(value, mx, freqs){
  distances <- mx[, which(colnames(mx) == value)] # distances between the value and all other possible values
  ws <- matrix(NA, ncol = 2, nrow = length(freqs))
  colnames(ws) <- c("distance", "weight")
  rownames(ws) <- colnames(mx)
  for (cat in colnames(mx)){
    ws[cat,] <- c(distances[cat], ifelse(cat == value, 0, freqs[cat]))
  } # two arranged vectors of distances and weights of the categories (self-similarity means 0 distinctiveness)
  sum(ws[,1]*ws[,2]) / max(ws[,1]) # normalized by the maximum possible distinctiveness
}

group_overlap <- function(vec, cen){
  vec <- vec/sum(vec)
  cen <- unlist(cen)/sum(unlist(cen))
  overlap <- sapply(1:length(vec), function(i) min(vec[i], cen[i]))
  sum(overlap)
}

dist <- function(x, cen, numind, catind, catmxs, grind){
  #x : dataframe with cols-traits and rows-species
  #cen : list with names-traits and values {mean for numeric, vector of freqs for categorical}
  #numind : vector of numeric variables indices or names
  #catind : vector of categorical variables indices or names
  #catmxs : named (=traits) list of distance matrices for categorical variables
  #grind : named (=name of group) list of names of trait variables {e.g., ns: nsbank, nsground,...}
  #
  #numeric variables
  numvals <- matrix(NA, nrow = nrow(x), ncol = length(numind))
  colnames(numvals) <- colnames(x)[numind]
  rownames(numvals) <- rownames(x)
  for (trait in colnames(x)[numind]){
    numvals[,trait] <- sapply(x[,trait], function(taxa_value){
      abs(taxa_value - unlist(cen[trait]))
    })
  }
  #categorical variables
  catvals <- matrix(NA, nrow = nrow(x), ncol = length(catind))
  colnames(catvals) <- colnames(x)[catind]
  rownames(catvals) <- rownames(x)
  for (trait in colnames(x)[catind]){
    mx <- catmxs[trait][[1]]
    sp <- 1
    for (taxa_value in x[,trait]){
      catvals[sp, trait] <- cat_dist(value = taxa_value, 
                                     mx = mx, 
                                     freqs = cen[taxa][[1]])
      sp <- sp+1
    }
  }
  #grouped variables
  grvals <- matrix(NA, nrow = nrow(x), ncol = length(grind))
  rownames(grvals) <- rownames(x)
  colnames(grvals) <- names(grind)
  for (trait in names(grind)){
    traits <- grid[trait][[1]]
    sp <- 1
    for (taxa_value in rownames(x)){
      grvals[taxa_value, trait] <- group_overlap(vec = x[taxa_value, traits], 
                                                 cen = unlist(cen[traits]))
    }
  }
  grdist <- apply(grvals, 1, function(o){
    1 - (o/max(o))
  })
  list(numvals, catvals, grdist)
}