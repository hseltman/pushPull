#' Push Files to an Sftp Server
#'
#' Push one or more files from to the student's working directory (or any
#' other student director) to the student's directory on the sftp server.
#' 
#' @param files a character vector containing the files to be uploaded.
#'
#' @return None
#'
#' @author Howard J. Seltman \email{hseltman@@stat.cmu.edu} and Francis R. Kovacs
#' 
#' @references 
#' https://stackoverflow.com/questions/15950396/sftp-get-files-with-r
#' https://jonkimanalyze.wordpress.com/2014/11/20/r-quick-sftp-file-transfer/
#' @export
#' @importFrom methods is


push <- function(files) {
  # Check input
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  
  # Get stored user/site-specific sftp info
  userSftpInfo = getOption("pushPullInfo")
  if (is.null(userSftpInfo)) {
    stop("run 'sftpSetup()'")
  }

  # Check files
  fid = file.info(files)$isdir
  notFound = is.na(fid)
  if (any(notFound)) {
    stop("missing file(s): '", paste(files[notFound], collapse=", "))
  }
  if (any(fid)) {
    stop("folder not file: ", paste(files[fid], collapse=", "))
  }
  
  # Upload each file
  front = paste0("sftp://", userSftpInfo[["sftpName"]], ":",
                 userSftpInfo[["sftpPassword"]], "@", userSftpInfo[["sftpSite"]])
  opts = list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    fRemote = file.path(userSftpInfo[["userName"]], basename(f))
    rtn = try(RCurl::ftpUpload(f, file.path(front, fRemote), .opts=opts), silent=TRUE)
    if (methods::is(rtn, "try-error")) {
      cat("Upload of", f, "failed.\n")
      cat("Message:", as.character(attr(rtn, "condition")))
    }
  }

  invisible(NULL)
}
