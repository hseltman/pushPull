#' Setup the User to Access the Sftp Site
#' 
#' Each user will have their own subfolder on the sftp site to
#'   which they upload.  This function sets the user's info 
#'   in a persistent data object called 'userSftpInfo'.
#'   It will be called during .onLoad and whenever the user
#'   re-runs it.
#' 
#' @return None
#'
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#' @export

setup <- function() {
  userSftpInfo = .pkgenv[["userSftpInfo"]]
  if (is.null(userSftpInfo)) {
    sftpSite <- NULL
    sftpName <- NULL
    sftpPassword <- NULL
    userName <- NULL
  } else {
    sftpSite <- userSftpInfo[["sftpSite"]]
    sftpName <- userSftpInfo[["sftpName"]]
    sftpPassword <- userSftpInfo[["sftpPassword"]]
    userName <- userSftpInfo[["sftpName"]]
  }
  sftpSite <- ask("sftp site [not including sftp://]", sftpSite)
  sftpName <- ask("sftp login name", sftpName)
  sftpPassword <- ask("sftp password", sftpPassword)
  userName <- ask("Your user name", userName)
  
  ## store the information as variables
  userSftpInfo <- c(sftpSite, sftpName, sftpPassword, userName)
  names(userSftpInfo) <- c("sftpSite", "sftpName", "sftpPassword", "userName")
  
  .pkgenv[["gsl_cflags"]] <<- userSftpInfo
  write(file.path("~", "pushPullInfo.txt"), userSftpInfo)
  # @importFrom devtools use_data
  #suppressMessages(use_data(userSftpInfo, 
  #                 internal = TRUE, 
  #                 overwrite = TRUE))
  invisible(NULL)
}

