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
  if (userSftpInfo["userName"] != ".") who = NULL
  
  # Fixup files (subdirectories must be through "who")
  files <- basename(files)
  if (!is.null(who)) {
    files <- paste0(who, "/", files)
  }
  

  # Download files
  opts <- list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    outF = f
    if (file.exists(f)) {
      ow = ask(paste("Overwrite", f, "(y or n)"), default="n")
      if (toupper(substring(ow, 1, 1) != "Y")) {
        outExists = TRUE
        while (outExists) {
          if (outF == "") break
          outF = ask("New name (or Enter to skip)")
          if (outF == "") break
          outExists = file.exists(outF)
        }
      }
    }
    url <- paste0("sftp://", userSftpInfo["sftpSite"], "/", f)
    userpwd <- paste0(userSftpInfo["sftpName"], ":", userSftpInfo["sftpPassword"])
    fileContents <- try(RCurl::getURL(url, userpwd=userpwd), silent=TRUE)
    if (methods::is(fileContents, "try-error")) {
      warning("Download of ", f, " failed.\n",
             "Message: ", as.character(attr(fileContents, "condition")))
    } else {
      rtn <- try(write(fileContents, file=outF), silent=TRUE)
      if (is(rtn, "try-error")) {
        warning("Download of ", outF, " succeeded, but save to ", getwd(), " failed.\n",
                "Message:", as.character(attr(rtn, "condition")))
      }
    }
  }
  
  invisible(NULL)
}
