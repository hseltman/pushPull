#' Push Files to an Sftp Server
#'
#' Push one or more files from to the student's sftp folder from the
#' working directory.
#' 
#' Students use push(files) to upload file(s) from their working folder
#' to the folder matching their user name on the sftp site.
#' 
#' Teachers use push(files) to upload file(s) from their working folder
#' to the sftp site's root folder (by specifying user name ".").
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
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  userSftpInfo = options("userSftpInfo")
  if (is.null(userSftpInfo)) {
    stop("run 'setup()'")
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
  
  # Upload files
  front = paste0("sftp://", userSftpInfo[["sftpName"]], ":",
                 userSftpInfo[["sftpPassword"]], "@", userSftpInfo[["sftpSite"]])
  opts = list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    fRemote = file.path(userSftpInfo[["userName"]], basename(f))
    print(file.path(front, fRemote))
    rtn = try(RCurl::ftpUpload(f, file.path(front, fRemote), .opts=opts), silent=TRUE)
    if (methods::is(rtn, "try-error")) {
      cat("Upload of", f, "failed.\n")
      cat("Message:", as.character(attr(rtn, "condition")))
    }
  }

  invisible(NULL)
}


