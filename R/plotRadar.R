#' Get radar coordinates
#'
#' Helper function to transform input data into coordinates that can be
#' passed to \code{plotRadar}.
#'
#' @importFrom ggplot2 ggproto
#'
#' @param theta x variable
#' @param start location of start on radar plot
#' @param direction direction of variables in radar
#'
#' @export
coordRadar <- function(theta = "x", start = 0, direction = 1) {
  theta <- match.arg(theta, c("x", "y"))
  r <- if (theta == "x") {
    "y"
  } else {"x"}
  ggproto("CordRadar", CoordPolar, theta = theta, r = r, start = start,
          direction = sign(direction), is_linear = function(coord) TRUE)
}

#______________________________________________________________________________

#' Radar plot
#'
#' This function generates a radar plot. Note that PMs on different scales
#' (e.g. proportional abundance vs. absolute abundance) should not be plotted
#' together. If it shouldn't share a y-axis label, it shouldn't be in a radar
#' plot! Also cannot facet so should only be passed one OM and multiple MPs or
#' vice versa. Includes helper function coordRadar.
#'
#' @importFrom dplyr everything filter mutate select
#' @importFrom ggplot2 aes facet_wrap geom_polygon geom_line ggplot guides
#' scale_color_manual scale_y_continuous scale_x_discrete theme xlab ylab
#'
#' @param dat Dataframe generated by \code{buildCUDat}.
#' @param xLab A character representing the x axis label.
#' @param plotVars A character value corresponding to PM in cuDat$vars (can be
#' either catch- or conservation-based).
#' @param groupingVar A character value that can take the values: \code{"mp", "om"}
#' and specifies along which categorical variable dot plots should be grouped.
#' @param cu A logical representing if data are segreated by CUs (Conservation
#' Units).
#' @param mainLab A character representing the main label.
#' @param legendLab A character representing the legend title.
#' @param axisSize A number representing the font size for the axis labels.
#' @return Returns a ggplot object.
#'
#' @examples
#' trimDat <- agPlottingDF %>%
#'   dplyr::filter(var %in% c("ppnCULower", "ppnCUStable", "ppnFisheriesOpen")) %>%
#'   dplyr::mutate(var = factor(var))
#' plotRadar(trimDat, xLab = c("CUs\nLower BM", "CUs\nStable", "Fisheries\n Open"),
#'           plotVars = NULL, groupingVar = NULL, cu = FALSE,
#'           legendLab = "Proportion\nTAC in\nMixed Catch", axisSize = 13)
#'
#' @export
plotRadar <- function(dat, xLab, plotVars = NULL, groupingVar = NULL, cu = FALSE,
                      mainLab = NULL, legendLab = NULL, axisSize = 13) {
  if (cu == TRUE) {
    warning("Facet wrap non-functional with radar plots. If plotting CU-specific
            data, generate list of unique dataframes and plot w/ sapply.")
  }
  d <- if (!is.null(plotVars)) {
    dat %>%
    filter(var %in% plotVars)
  } else {
    dat
  }
  d <- d[order(d$var), ]

  groupVar <- if (is.null(groupingVar)) {
    factor(d[ , 1])
  } else {
    d %>%
      select(groupingVar) %>%
      factor()
  }
  colPal <- viridis::viridis(length(levels(groupVar)), begin = 0, end = 1)
  names(colPal) <- levels(groupVar)

  p <- ggplot(d, aes(x = var, y = avg)) +
    geom_polygon(aes(group = groupVar, color = groupVar), fill = NA, size = 2,
                 show.legend = FALSE) +
    geom_line(aes(group = groupVar, color = groupVar), size = 2) +
    scale_y_continuous(limits = c(0, max(d$avg))) +
    scale_x_discrete(labels = xLab) +
    theme(panel.background = element_rect(fill = "white"),
          panel.grid.major = element_line(colour = "grey70", size = 1),
          panel.grid.minor = element_line(colour = "grey70", size = 1),
          strip.text.x = element_text(size = rel(1)),
          axis.text.x = element_text(colour = "black", size = axisSize),
          axis.ticks.y = element_blank(),
          axis.text.y = element_blank(),
          legend.title = element_text(colour = "grey30", size = rel(1.2)),
          legend.key.size = unit(1, "lines"),
          legend.text = element_text(size = rel(1.1), colour = "grey30"),
          legend.key = element_rect(colour = NA, fill = NA),
          legend.background = element_rect(colour = NA, fill = NA),
          plot.margin = unit(c(5.5, 5.5, 6.5, 5.5), "pt")
    ) +
    xlab("") + ylab("") + ggtitle(mainLab) +
    scale_color_manual(name = legendLab, values = colPal) +
    coordRadar()
  return(p)
}
