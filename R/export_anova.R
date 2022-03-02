#' Title
#'
#' @param model
#' @param file
#' @param pnames
#' @param alpha
#' @param boldsig
#' @param digits
#' @param align
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
export_anova <- function(model, file = NULL, pnames = NULL, alpha = 0.05,
                         boldsig = TRUE, digits = c(1, 2, 1, 4),
                         align = c("l", "r", "r", "r"), ...) {

  # export_anova() v0.1
  # Author: Tim Farkas
  # The export_anova function takes a statistical model object and saves pretty
  # table to file.
  # model: a model object on which to run car::Anova
  # file: a path to write the table to, with extension pdf or png.
  #   # If file = NULL, prints latex
  # pnames: a data frame with old parameters names (col 1) and new (col 2)
  # TODO: throw error if mismatch between model parameters and pnames
  # alpha: threshold for boldface p-values
  # boldsig: if TRUE, bold p-values less than alpha
  # digits: number of significant digits to print for each column
  # align: alignment (l = left, r = right, c = center) for each column
  # ... other arguments to Anova, kable, and add_footnote
  #   # label = " ... " will print an (ugly) caption
  #   # type = 3 will change to type 3 ANOVA
  #   # lot of potential options to kable!

  antable <- car::Anova(model, ...) %>%
    tibble::as_tibble(rownames = "Parameter")

  pnamelist <- if(!is.null(pnames)) {
    as.list(pnames[,2]) %>% rlang::set_names(pnames[,1])
  } else { as.list(antable$Parameter) %>%
      rlang::set_names(antable$Parameter) }
  # TODO: allow vector of new names?

  latex_out <- antable %>%
    rlang::set_names(c("Parameter", "$\\chi^2$", "DF", "pvaluetemp")) %>%
    dplyr::mutate(dplyr::across(Parameter, ~ dplyr::recode(.x, !!!pnamelist))) %>%
    dplyr::mutate(dplyr::across(Parameter, ~ stringr::str_replace_all(.x, "_", "\\\\_"))) %>% # wow this is a serious hack
    # TODO: Add more special character exceptions
    dplyr::mutate("pvalue" = ifelse(.[[4]] < 10^-digits[4],
                             paste0("< ", format(10^-digits[4], scientific = FALSE)),
                             format(round(.[[4]], digits[4]), scientific = FALSE))) %>%
    dplyr::mutate(dplyr::across(pvalue, ~ kableExtra::cell_spec(.x, bold = ifelse(pvaluetemp < alpha & boldsig,
                                                        TRUE, FALSE), format = "latex"))) %>%
    dplyr::select(-4) %>%
    dplyr::rename("$P$-value" = pvalue) %>%
    knitr::kable("latex", booktabs = TRUE, linesep = "", escape = FALSE,
          digits = digits, align = align, ...) %>%
    kableExtra::add_footnote(notation = "symbol", ...)

  if(!is.null(file)) kableExtra::save_kable(x = latex_out, file = file)
  else return(latex_out)
}