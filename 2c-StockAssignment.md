---
output: html_document
editor_options: 
  chunk_output_type: console
---

```{r}

```

# Stock Assignment

From the PCAngsd covariance matrices, we can run [DAPC](https://pmc.ncbi.nlm.nih.gov/articles/PMC2973851/) for stock assignment.

Load the necessary functions to run DAPC from [run_dapc_functions.R](src/StockAssignment/run_dapc_functions.R):
```{r}
source("src/StockAssignment/run_dapc_functions.R")
```

## Run DAPC for the different SNP datasets

Define the individuals and SNPs datasets to be analyzed:
```{r}
# pcangsd and dapc datasets are kept separate to allow subsampling if needed
pcangsd_dataset <- "wp1_final_bal"
dapc_dataset <- "wp1_final_bal"
# list of sites to go through
sites_name_lst <- c(
  "supplementary_file_7.v2",
  "sf7_noinv.v2",
  "salinity_genes.v2",
  "spring_v_autumn.v2"#,
#  "ns_inversions.chr12"
)
```

Run DAPC with auto-choose K and group assignments algorithm, and save its results:
```{r}
for (sites_name in sites_name_lst){
  print(paste(pcangsd_dataset, dapc_dataset, sites_name))
  # read covariance matrix
  matrix <- get_matrix(pcangsd_dataset, sites_name, dapc_dataset)
  # calculate optimal k
  optimal_k <- get_optimal_k(matrix, dapc_dataset, sites_name)
  # calculate consensus group assignments
  consensus_groups <- get_consensus_groups(matrix, optimal_k)
  # run dapc with cross-validation
  final.dapc <- run_dapc(matrix, consensus_groups)
  # save dapc object
  saveRDS(
    final.dapc,
    file = paste0("data/dapc/final_dapc.",
                  pcangsd_dataset, ".", dapc_dataset, ".", sites_name, ".k", optimal_k, ".rds")
  )
}
```

Create bi-plots if number of Linear Discriminants is > 1 or density plots if there's only one:
```{r}
for (sites_name in sites_name_lst){
  best_k <- read_best_k(dapc_dataset, sites_name)
  dapc_obj <- load_dapc(pcangsd_dataset, dapc_dataset, sites_name, best_k)
  metadata <- get_metadata(dapc_dataset)
  # plot by spawn
  plt <- plot_dapc(dapc_obj, metadata, color_by = "spawn")
  ggsave(
    filename = paste0(
      "plots/dapc/", dapc_dataset, ".", sites_name, ".k", best_k, ".dapc.by_spawn.png"
      ),
    plot = plt, width = 180, height = 90, unit = "mm", dpi = 300
  )
  # plot by region
  plt <- plot_dapc(dapc_obj, metadata)
  ggsave(
    filename = paste0(
      "plots/dapc/", dapc_dataset, ".", sites_name, ".k", best_k, ".dapc.by_region.png"
      ),
    plot = plt, width = 180, height = 90, unit = "mm", dpi = 300
  )
}
```

## Assign Stocks based on DAPC results

Stocks are assigned by ...

Write a table summarizing results:
```{r}
stock_df <- basic_stock_df(dapc_dataset, sites_name_lst)
write.table(stock_df, file = "data/dapc/Stock_Table.csv", quote = F, sep = ",", row.names = F)
```

##

```{r}
library(tidyverse)
library(scales)

colors <- c(
  "Britain and Ireland Autumn" = "#3478C9",
  "North Sea Autumn (NSAS)" = "#18A6A6",
  "Norwegian Spring (NSSH)" = "#45A85A",
  "Faroese / Icelandic" = "#D99A18",
  "Skagerrak herring" = "#E85D4A",
  "Baltic herring" = "#C44E78"
)

# Optional: explicitly control ordering
stock_df <- stock_df  |>
  filter(Region %in% c("Skagerrak & Kattegat", "Britain & Ireland", "Norway")) |>
  mutate(Region = droplevels(Region)) |> 
  mutate(
    Stock = factor(
      Stock,
      levels = c("Skagerrak herring", "Norwegian Spring (NSSH)", "Britain and Ireland Autumn",
                 "Faroese / Icelandic", "North Sea Autumn (NSAS)", "Baltic herring")
    )
  )


# Calculate stock composition within each Region × Period
stock_summary <- stock_df %>%
  count(Region, Period, Stock, name = "n") %>%

  # Explicitly create absent combinations as n = 0
  complete(
    Region,
    Period,
    Stock,
    fill = list(n = 0)
  ) %>%

  group_by(Region, Period) %>%
  mutate(
    total_n = sum(n),
    prop = n / total_n
  ) %>%
  ungroup()

stock_summary

sample_sizes <- stock_df %>%
  count(Region, Period, name = "N")
```


```{r}
ggplot(
  stock_summary,
  aes(
    x = Period,
    y = prop,
    fill = Stock
  )
) +
  geom_col(
    width = 0.75,
    colour = "white",
    linewidth = 0.2
  ) +
  geom_text(
    data = sample_sizes,
    aes(
      x = Period,
      y = 1.03,
      label = paste0("n = ", N)
    ),
    inherit.aes = FALSE,
    size = 3
  ) +
  facet_wrap(~ Region, ncol = 1) +
  scale_y_continuous(
    labels = percent_format(),
    limits = c(0, 1.08),
    breaks = seq(0, 1, 0.25),
    expand = expansion(mult = c(0, 0))
  ) +
  labs(
    x = "Time period",
    y = "Stock composition",
    fill = "Stock"
  ) +
  theme_classic(base_size = 12) +
  theme(
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  ) +
  scale_fill_manual(values = colors)
```

```{r}
ggplot(
  stock_summary,
  aes(
    x = Period,
    y = Stock,
    fill = prop
  )
) +
  geom_tile(
    colour = "white",
    linewidth = 0.5
  ) +
  geom_text(
    aes(label = percent(prop, accuracy = 1)),
    size = 3
  ) +
  facet_wrap(~ Region, ncol = 1) +
  scale_fill_viridis_c(
    labels = percent_format(),
    limits = c(0, 1),
    name = "Proportion"
  ) +
  labs(
    x = "",
    y = ""
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    panel.grid = element_blank(),
    strip.background = element_blank(),
    strip.text = element_text(face = "bold")
  )
```



```{r}
```

