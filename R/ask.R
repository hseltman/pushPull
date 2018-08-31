#' Prompt for User Input
#'
#' Prompt the user to enter some text with or without a default.
#' In the context of this package it is used to prompt for settings
#' needed to access the sftp site.
#' 
#' @param prompt prompt to the user
#' @param default default value (shown to the user)
#' 
#' @return character value of the user's response
#' 
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#'


ask <- function(prompt, default = NULL) {
  if (!is.null(default) && length(default) > 0) {
    prompt <- paste0(prompt, " (or Enter for '", default, "')")
  }
  rtn <- readline(paste0(prompt, "? "))
  if (toupper(rtn) %in% c("Q", "QUIT"))
    stop("user quit setup()")
  if (!is.null(default) && rtn == "") {
    rtn <- default
  }
  return(rtn)
}
