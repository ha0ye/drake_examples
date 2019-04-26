# packages ---------------------------------------------------

library(drake)
library(tidyverse)

# functions ---------------------------------------------------

bytes <- function(x) as.numeric(object.size(x))

elements <- function(x) {
  if (!is.null(dim(x))) {
    prod(dim(x))  
  } else {
    length(x)  
  }
}

vis <- function(full) {
  ggplot(full) +
    geom_line(aes(x = data, y = value, color = method, group = method)) +
    facet_wrap(~method, scales = "free_y", ncol = 1) +
    theme_bw()
}

# plan ---------------------------------------------------

datasets <- c("mtcars", "iris", "Nile", "sunspots") %>%
  rlang::syms()

pipeline <- drake_plan(
  data = target(x, transform = map(x = !!datasets)),
  analysis = target(
    tibble(
      value = fun(data),
      method = deparse(substitute(fun)),
      data = deparse(substitute(data))
    ),
    transform = cross(data, fun = c(bytes, elements))
  ),
  results = target(
    bind_rows(analysis),
    transform = combine(analysis, .by = fun)
  ),
  full = target(
    bind_rows(results),
    transform = combine(results)
  ),
  plot = vis(full),
  report = rmarkdown::render(
    knitr_in("report.Rmd"),
    output_file = file_out("report.html"),
    quiet = TRUE
  )
)

# visuals ---------------------------------------------------

if (FALSE) {
  config <- drake_config(pipeline)
  sankey_drake_graph(config, build_times = "none")  # requires "networkD3" package
  vis_drake_graph(config, build_times = "none")     # requires "visNetwork" package
}

# execution -------------------------------------------------------------

make(pipeline)
