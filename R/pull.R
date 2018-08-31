#' Pull Files from an Sftp Server
#'
#' Pull one or more files from the main sftp folder into the
#' working directory.  If \code{"who"} is used, the file is
#' read from that subfolder.
#' 
#' Students use push(files) to upload file(s) from their computer to
#' the sftp site in their folder (as specified by their setup user name).
#' Typically one or more files in the current folder are specified, but
#' relative and absolute locations are allowed.
#' Students use pull(files) to download files to their current folder
#' from the root folder of the ftp site.
#' 
#' Teachers use push(files) to upload file(s) from their computer to the
#' sftp site's root folder (by specifying user name ".").
#' Teachers use pull(files, who="studentUserId") to download one or more
#' student files to their current folder.
#' 
#' @param files a character vector containing the files to be loaded
#' @param who a length-1 character vector specifying the folder on
#'   the sftp server from which the file is read
#'
#' @return None
#'
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#' 
#' @references 
#' https://stackoverflow.com/questions/15950396/sftp-get-files-with-r
#' https://jonkimanalyze.wordpress.com/2014/11/20/r-quick-sftp-file-transfer/
#' @export

pull <- function(files, who = NULL) {
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  userSftpInfo <- getOption("pushPullInfo")
  if (is.null(userSftpInfo)) {
    stop("run 'setup()'")
  }
  
  # Fixup files (subdirectories must be through "who")
  files <- basename(files)
  if (!is.null(who)) {
    files <- paste0(who, "/", files)
  }
  
  # Helper function to add "-user" to file names
  addUser <- function(f, user) {
    if (is.null(user)) user <- "."
    user <- trimws(user)
    if (user %in% c("", ".")) user="instructor"
    f <- strsplit(f, "[.]")[[1]]
    len <- length(f)
    if (len == 1) return(paste0(f, "-", user))
    if (len > 2) {
      f <- c(paste(f[1:(len-1)], collapse="."), f[len])
    }
    return(paste0(f[1], "-", user, ".", f[2]))
  }
  
  # Download files
  front <- paste0("sftp://", userSftpInfo[["sftpName"]], ":",
                  userSftpInfo[["sftpPassword"]], "@", userSftpInfo[["sftpSite"]])
  opts <- list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    url <- paste0("sftp://", userSftpInfo[["sftpSite"]], "/", f)
    userpwd <- paste0(userSftpInfo[["sftpName"]], ":", userSftpInfo[["sftpPassword"]])
    rtn <- try(RCurl::getURL(url, userpwd=userpwd), silent=TRUE)
    if (methods::is(rtn, "try-error")) {
      cat("Download of", f, "failed.\n")
      cat("Message:", as.character(attr(rtn, "condition")))
    } else {
      fLocal <- addUser(basename(f), who)
      rtn <- try(write(rtn, fLocal), silent=TRUE)
      if (is(rtn, "try-error")) {
        cat("Download of", fLocal, "succeeded, but save to", getwd(), "failed.\n")
        cat("Message:", as.character(attr(rtn, "condition")))
      }
    }
  }
  
  invisible(NULL)
}
