#' Setup the User to Access the Sftp Site
#' 
#' Each user will have their own subfolder on the sftp site to
#'   which they upload.  This function sets the site and user info 
#'   in a persistent file called "pushPullInfo.txt" in the packages
#'   root directory.  The information comprises the sftp URL, the sftp
#'   user name, the sftp password, and the user's unique user name.
#'   (The intent is to allow a simple setup where the sftp user name and
#'   password are shared across students.)  When the library is loaded,
#'   the information is loaded from that file and place in an option()
#'   called 'pushPullInfo'.
#' 
#' @return None
#' 
#' @details
#' The file "pushPullInfo.txt" is a plain text file with four lines.  The
#'   lines contain the sftp site URL (without the "sftp://" prefix, and possibly
#'   with a "/directory" suffix), the sftp user name, the sftp password,
#'   and the users unique id (e.g., base portion of University email address).
#' 
#' The return value of getOption("pushPullInfo") is a named character vector
#'   with elements "sftpSite", "sftpName", "sftpPassword", and "userName".
#'
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#' @export

sftpSetup <- function() {
  userSftpInfo = getOption("pushPullInfo")
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
  
  options(pushPullInfo=userSftpInfo)
  packageFolder = system.file(package="pushPull")
  write(userSftpInfo, file=file.path(packageFolder, "pushPullInfo.txt"))
  invisible(NULL)
}

