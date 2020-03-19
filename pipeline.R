library(tidyverse)
library(drake)

# utility functions ------------------------------------------------------------

collect_analyses <- function(list_of_results)
{
    names(list_of_results) <- all.vars(match.call()$list_of_results)
    list_of_results
}

build_analyses_plan <- function(methods, datasets, ...)
{
    drake::drake_plan(
        analysis = target(fun(data),
                          transform = cross(fun = !!rlang::syms(methods$target),
                                            data = !!rlang::syms(datasets$target))
        ),
        results = target(collect_analyses(list(analysis)),
                         transform = combine(analysis, .by = fun)),
        ...
    )
}

# drake plans ------------------------------------------------------------------

datasets <- drake::drake_plan(
    mtcars = mtcars, 
    iris = iris, 
    Nile = Nile, 
#   Orange = Orange, 
    sunspots = sunspots
)

fun_wrapper <- function(f)
{
    method_name <- all.vars(match.call()$f)
    function(x)
    {
        dataset_name <- all.vars(match.call()$x)
        data.frame(value = as.numeric(f(x)),
                   method = method_name, 
                   dataset = dataset_name)
    }
}

methods <- drake::drake_plan(
    nrow = fun_wrapper(NROW),
    ncol = fun_wrapper(NCOL),
    mem = fun_wrapper(object.size)
)

analyses <- build_analyses_plan(methods, datasets)

reports <- drake_plan(
    report = rmarkdown::render(
        knitr_in("report.Rmd")
    )
)

pipeline <- bind_rows(datasets, methods, analyses, reports)

# View the graph of the plan ---------------------------------------------------

if (interactive())
{
    config <- drake_config(pipeline)
    sankey_drake_graph(config, build_times = "none")  # requires "networkD3" package
    vis_drake_graph(config, build_times = "none")     # requires "visNetwork" package
}

# Run the pipeline -------------------------------------------------------------

make(pipeline)
