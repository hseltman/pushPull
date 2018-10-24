#' Pull Files from an Sftp Server
#'
#' Pull one or more files from the main sftp folder into the
#' working directory.
#' 
#' Students use pull(files) to download file(s) to their computer from
#' the sftp site.  One or more files can specified.  Files are loaded to the
#' student's working directory.  If the file already exists the user is
#' asked if s(he) wants to overwrite the old file.  If "n"o is chosen,
#' the user is asked for a new file name.
#' 
#' @param files a character vector containing the files to be loaded
#'
#' @return None
#'
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#' 
#' @references 
#' https://stackoverflow.com/questions/15950396/sftp-get-files-with-r
#' https://jonkimanalyze.wordpress.com/2014/11/20/r-quick-sftp-file-transfer/
#' @export

pull <- function(files) {
  # Check input and restrict to root directory of the sftp server
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  files <- basename(files)
  
  # Get user/site-specific stored sftp info
  userSftpInfo <- getOption("pushPullInfo")
  if (is.null(userSftpInfo)) {
    stop("run 'sftpSetup()'")
  }

  # Download each file
  for (f in files) {
    outF = f
    # Prevent file overwrite unless user agrees
    if (file.exists(f)) {
      ow = ask(paste("Overwrite", f, "(y or n)"), default="n")
      if (toupper(substring(ow, 1, 1)) != "Y") {
        browser()
        outExists = TRUE
        while (outExists) {
          if (outF == "") break
          outF = ask("New name (or Enter to skip)")
          if (outF == "") break
          outExists = file.exists(outF)
        }
      }
    }
    # Perform actual download
    url <- paste0("sftp://", userSftpInfo["sftpSite"], "/", f)
    userpwd <- paste0(userSftpInfo["sftpName"], ":", userSftpInfo["sftpPassword"])
    fileContents <- try(RCurl::getURL(url, userpwd=userpwd), silent=TRUE)
    if (methods::is(fileContents, "try-error")) {
      warning("Download of ", f, " failed.\n",
             "Message: ", as.character(attr(fileContents, "condition")))
    } else {
      # Write downloaded text to the output file
      rtn <- try(write(fileContents, file=outF), silent=TRUE)
      if (is(rtn, "try-error")) {
        warning("Download of ", outF, " succeeded, but save to ", getwd(), " failed.\n",
                "Message:", as.character(attr(rtn, "condition")))
      }
    }
  }
  
  invisible(NULL)
}
