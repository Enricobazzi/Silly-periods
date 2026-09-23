library(tidyverse)
library(adegenet)
library(clue)
library(ggrepel)

## ---------- ## ---------- ## ---------- ## ---------- ## ---------- ## -------
## FUNCTIONS:

# get sample names for a dataset from the sample_list file:
get_samples_from_dataset <- function(dataset) {
  file_path <- paste0("data/bamlists/", dataset, ".sample_list.txt")
  samples <- read.table(file_path)[, 1] |> as.character()
  return (samples)
}

# get matrix of the pcangsd dataset + sites, and filter dapc_dataset samples:
get_matrix <- function(pcangsd_dataset, sites_name, dapc_dataset) {
  # read matrix
  file_path <- paste0("data/pcangsd/", pcangsd_dataset, ".", sites_name, ".pcangsd.cov")
  mat <- as.matrix(read.table(file_path))
  # decide which samples to keep
  pcangsd_samples <- get_samples_from_dataset(pcangsd_dataset)
  dapc_samples <- get_samples_from_dataset(dapc_dataset)
  sample_indices <- which(pcangsd_samples %in% dapc_samples)
  # filter samples
  filtered_mat <- mat[sample_indices, sample_indices]
  rownames(filtered_mat) <- pcangsd_samples[sample_indices]
  colnames(filtered_mat) <- pcangsd_samples[sample_indices]
  return (filtered_mat)
}

# get the table with results of 1000 find.clusters runs
calculate_k_table <- function(matrix, n.reps = 1000) {
  Ks <- replicate(n.reps, {
    set.seed(sample(1:1e6, 1))
    length(find.clusters(matrix, n.pca = 5, choose.n.clust = FALSE)$size)
  })
  print(data.frame(table(Ks)) |> 
          arrange(-Freq) |> 
          mutate(Freq = paste0(round(Freq/sum(Freq)*100, 1), "%")))
  return (data.frame(table(Ks)) |> arrange(-Freq))
}

# get optimal k and write table of best 1000 K searches
get_optimal_k <- function(matrix, dapc_dataset, sites_name, n.reps = 1000) {
  k_table <- calculate_k_table(matrix, n.reps)
  write.table(
    k_table,
    file = paste0("data/dapc/", dapc_dataset, ".", sites_name, ".k_table.txt"),
    quote = F, row.names = F
  )
  optimal_k <- as.numeric(as.character(k_table[which.max(k_table$Freq), ]$Ks))
  return (optimal_k)
}

# get consensus group assignments for selected K
get_consensus_groups <- function(matrix, optimal_k,  n.reps = 1000) {
  
  # Create a matrix to hold the assignments (Rows = individuals, Columns = replicates)
  assignment_matrix <- matrix(NA, nrow = nrow(matrix), ncol = n.reps)
  
  for (i in 1:n.reps) {
    # find.clusters uses K-means internally
    temp_clusters <- find.clusters(matrix, n.pca = 5, n.clust = optimal_k, choose.n.clust = FALSE)
    assignment_matrix[, i] <- temp_clusters$grp
  }
  
  # Convert assignments to a matrix of dummy variables
  # Then calculate co-occurrence probabilities
  coassign_array <- array(0, dim = c(nrow(matrix), nrow(matrix), n.reps))
  
  for (i in 1:n.reps) {
    # cl_membership creates a binary classification matrix
    mem_matrix <- as.cl_membership(as.factor(assignment_matrix[, i]))
    M <- unclass(mem_matrix)   # numeric membership matrix: individuals x clusters
    coassign_array[, , i] <- M %*% t(M)
  }
  consensus_matrix <- apply(coassign_array, c(1,2), mean)
  
  # Convert to a distance object (1 - consensus probability)
  dist_matrix <- as.dist(1 - consensus_matrix)
  # Hierarchical clustering with Average Linkage (UPGMA)
  hc_consensus <- hclust(dist_matrix, method = "average")
  # Cut the tree to get exactly K groups
  final.groups <- cutree(hc_consensus, k = optimal_k)
  return (final.groups)
}

# run DAPC:
run_dapc <- function(matrix, consensus_groups){
  xval <- xvalDapc(matrix, consensus_groups, n.pca.max = 100,
                   result = "groupMean",
                   n.rep = 100, xval.plot = FALSE)
  final.dapc <- dapc(matrix, consensus_groups,
                     n.pca = xval$DAPC$n.pca,
                     n.da = xval$DAPC$n.da)
  return (final.dapc)
}

# get metadata table
get_metadata <- function(dapc_dataset) {
  samples <- get_samples_from_dataset(dapc_dataset)
  sample_data_file <- "~/Documents/Silly-periods/data/samples_table.csv"
  sample_data <- read.table(sample_data_file, sep = ",",
                            header = TRUE, na.strings = "UNKNOWN")
  sample_data <- sample_data[sample_data$sample_id %in% samples, ]
  return (sample_data)
}

# read best k from table
read_best_k <- function(dapc_dataset, sites_name) {
  best_k <- read.table(
    paste0("data/dapc/", dapc_dataset, ".", sites_name, ".k_table.txt"),
    header = T)[1,1]
  return (best_k)
}

# load dapc object
load_dapc <- function(pcangsd_dataset, dapc_dataset, sites_name, k) {
  DAPC <- readRDS(paste0("data/dapc/final_dapc.",
                         pcangsd_dataset, ".", dapc_dataset, ".", sites_name, ".k", k, ".rds"))
  return (DAPC)
}

# variance of LD1 & LD2
get_variance_label <- function(dapc_obj, axn) {
  return(paste0("LD", axn, " (", round(dapc_obj$eig[axn] / sum(dapc_obj$eig) * 100, 2), "%)"))
}

# get fancy period names
get_fancy_period <- function(period) {
  period_dict <- c(
    "ah" = "Before 1700s",
    "17sp" = "1747–1805 Sillperiod",
    "18rh" = "Between Sillperiods",
    "18sp" = "1877–1906 Sillperiod",
    "mh" = "Present-day"
  )
  return (unname(period_dict[period]))
}

# get fancy region names
get_fancy_region <- function(region) {
  return(gsub("_", " ", region))
}

# palette of colors
colpal <- c(
  "Bothnia" = "#440154FF",
  "Baltic" = "#1b639e",
  "Belt" = "#71D0F5FF",
  "Skagerrak & Kattegat" = "#b370b2",
  "North Sea" = "#ED3911",
  "Britain & Ireland" = "#91331FFF",
  "Norway" = "#02d97c",
  "Faroe Islands" = "#FED439FF",
  "Iceland" = "#FED999FF",
  "autumn" = "#91331FFF",
  "autumn/winter" = "#440154FF",
  "spring" = "#02d97c",
  "summer" = "#FED439FF",
  "winter" = "#1b639e"
)

# palette of shapes
time_shapes <- c(
  "Before 1700s" = 22,
  "1747–1805 Sillperiod" = 24,
  "Between Sillperiods" = 23,
  "1877–1906 Sillperiod" = 25,
  "Present-day" = 21
)

# plot dapc:
plot_dapc <- function(dapc_obj, metadata, color_by = "region") {
  
  if (ncol( dapc_obj$ind.coord) > 1) {
    
    dapc_df <- data.frame(
      id = metadata$new.id,
      Region = unlist(lapply(metadata$region, get_fancy_region)),
      Spawn = metadata$spawn,
      LD1 = dapc_obj$ind.coord[, 1],
      LD2 = dapc_obj$ind.coord[, 2],
      group = droplevels(dapc_obj$assign),
      old_id = metadata$sample_id,
      Period = unlist(lapply(metadata$period, get_fancy_period))
    )
    
    # dataframe for centroids with names:
    centroids <- dapc_df %>%
      group_by(group) %>%
      summarise(
        mean_LD1 = median(LD1, na.rm = TRUE),
        mean_LD2 = median(LD2, na.rm = TRUE),
        group_name = first(group)
      )
    
    if (color_by == "region") {
      dapc_plot <- ggplot (data = dapc_df,
                           aes(x = LD1, y = LD2, colour = Region, fill = Region, shape = Period))
    } else if (color_by == "spawn") {
      dapc_plot <- ggplot (data = dapc_df,
                           aes(x = LD1, y = LD2, colour = Spawn, fill = Spawn, shape = Period))
    }
    
    dapc_plot <- dapc_plot +
      # lines to group centroid
      geom_segment(
        data = dapc_df %>% left_join(centroids, by = "group"),
        aes(x = LD1, y = LD2, xend = mean_LD1, yend = mean_LD2),
        linewidth = 0.1,
        alpha = 0.8
      ) +
      # ellipse
      # stat_ellipse(aes(group = group), level = 0.5, linetype = 1, linewidth = 0.3) +
      # points
      geom_point(alpha = 0.7, size = 2) +
      # geom_point(
      #   data = dapc_df |> filter(Period == "Present-day"),
      #   aes(x = LD1, y = LD2), inherit.aes = F, shape = 1, size = 2
      # ) +
      geom_label_repel(data = centroids, aes(x = mean_LD1, y = mean_LD2, label = group),
                       fill = "white", size = 2, inherit.aes = F,
                       label.padding = unit(0.1, "lines"), segment.size = 0.05, force = 0.01) +
      # fancy plot:
      xlab(get_variance_label(dapc_obj, 1)) + ylab(get_variance_label(dapc_obj, 2)) +
      scale_fill_manual(values = c(colpal)) +
      scale_color_manual(values = c(colpal)) +
      scale_shape_manual(values = time_shapes) +
      theme_minimal() +
      theme(
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 11),
        axis.title = element_text(size = 11),
        axis.text = element_text(size = 9),
        legend.key.size = unit(0.3, "cm"),
        legend.spacing.y = unit(0, "cm")
      )
  } else if (ncol( dapc_obj$ind.coord) == 1) {
    
    dapc_df <- data.frame(
      id = metadata$new.id,
      Region = unlist(lapply(metadata$region, get_fancy_region)),
      Spawn = metadata$spawn,
      LD1 = dapc_obj$ind.coord[, 1],
      group = droplevels(dapc_obj$assign),
      old_id = metadata$sample_id,
      Period = unlist(lapply(metadata$period, get_fancy_period))
    )
    
    if (color_by == "region") {
      dapc_plot <- ggplot (data = dapc_df,
                           aes(x = LD1, colour = Region, fill = Region))
    } else if (color_by == "spawn") {
      dapc_plot <- ggplot (data = dapc_df,
                           aes(x = LD1, colour = Spawn, fill = Spawn))
    }
    
    dapc_plot <- dapc_plot +
      stat_density (alpha = 0.7) +
      # fancy plot:
      xlab(get_variance_label(dapc_obj, 1)) +
      scale_fill_manual(values = c(colpal)) +
      scale_color_manual(values = c(colpal)) +
      theme_minimal() +
      theme(
        legend.text = element_text(size = 10),
        legend.title = element_text(size = 11),
        axis.title = element_text(size = 11),
        axis.text = element_text(size = 9),
        legend.key.size = unit(0.3, "cm"),
        legend.spacing.y = unit(0, "cm")
      )
  }
  return(dapc_plot)
}

# get group name from group number
get_grp_name <- function(group, sites_name) {
  if (sites_name == "sf7_noinv.v2"){
    if (group == 1){
      grp_name <- "Faroese / Icelandic herring"
    } else if (group == 2){
      grp_name <- "Norwegian Spring (NSSH)"
    } else if (group == 3){
      grp_name <- "North Sea Autumn (NSAS)"
    } else if (group == 4){
      grp_name <- "Baltic herring"
    } else if (group == 5){
      grp_name <- "Skagerrak herring"
    }
  } else if (sites_name == "supplementary_file_7.v2") {
    if (group == 1){
      grp_name <- "Faroese / Icelandic"
    } else if (group == 2){
      grp_name <- "North Sea Autumn (NSAS)"
    } else if (group == 3){
      grp_name <- "Norwegian Spring (NSSH)"
    } else if (group == 4){
      grp_name <- "Britain and Ireland Autumn"
    } else if (group == 5){
      grp_name <- "Baltic herring"
    } else if (group == 6){
      grp_name <- "Skagerrak herring"
    }
  } else if (sites_name == "spring_v_autumn.v2"){
    if (group == 1){
      grp_name <- "Autumn"
    } else if (group == 2){
      grp_name <- "Spring (Norway)"
    } else if (group == 3){
      grp_name <- "Spring (Skagerrak)"
    } else if (group == 4){
      grp_name <- "Spring (Baltic)"
    }
  } else if (sites_name == "salinity_genes.v2"){
    if (group == 1){
      grp_name <- "Salty"
    } else if (group == 2){
      grp_name <- "Brackish"
    }
  }
}

# build basic stock DF
basic_stock_df <- function(dapc_dataset, sites_name_lst){
  
  metadata <- get_metadata(dapc_dataset)
  
  stock_df <- data.frame(
    id = metadata$new.id,
    old_id = metadata$sample_id,
    DP = as.numeric(metadata$wg.depth),
    Year = metadata$year,
    Period = factor(unlist(lapply(metadata$period, get_fancy_period)), levels = c(
      "Before 1700s",
      "1747–1805 Sillperiod",
      "Between Sillperiods",
      "1877–1906 Sillperiod",
      "Present-day"
    )),
    Region = factor(unlist(lapply(metadata$region, get_fancy_region)), levels = c(
      "Skagerrak & Kattegat", "Norway", "Britain & Ireland", "North Sea", "Iceland",
      "Faroe Islands", "Belt", "Baltic", "Bothnia"
    )),
    Spawn = metadata$spawn
  )
  # add stock
  for (sites_name in sites_name_lst){
    dapc_obj <- load_dapc(pcangsd_dataset, dapc_dataset, sites_name,
                          k = read_best_k(dapc_dataset, sites_name))
    group = droplevels(dapc_obj$assign)
    if (sites_name == "supplementary_file_7.v2") {
      col_name <- "Stock"
    } else if (sites_name == "spring_v_autumn.v2") {
      col_name <- "SpawnTime"
    } else if (sites_name == "salinity_genes.v2") {
      col_name <- "SpawnSalinity"
    } else {
      col_name <- sites_name
    }
    stock_df[[col_name]] <- unlist(lapply(group, get_grp_name, sites_name))
  }
  return (stock_df)
}

