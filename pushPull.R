# Push/pull project, Jan 2018, H. Seltman
# 
# This is a teaching tool to encourage interaction in programming classes.
#
# It is based on the existance of an FTP server where files are shared and exchanged.
# This code can also be implemented as Python functions, SAS macros, etc.

# Educational use examples:
# 1) Students are working in class and a student wants to know why their code
#    failed or you want to show a working (or not working) example from a
#    particular student.  The student pushes the file with push("myFile.R")
#    and you pull it with pull("myFile.R", who="studentId").  Now you can
#    open the file in your current R session.
# 2) Students are attempting to code something, and you want everyone to
#    "catch up" to your version.  Run push("myfile.R").  Each student can
#    then run pull("myFile.R"), and open your version on their computer.

# Requirements:
# "RCurl" package
# An sftp account (ideally restricted to only sftp, with a filespace limit)

# Details:
#   Students use push(files) to upload file(s) from their computer to
#   the sftp site in their folder (as specified by their setup user name).
#   Typically one or more files in the current folder are specified, but
#   relative and absolute locations are allowed.
#
#   Students use pull(files) to download files to their current folder
#   from the root folder of the ftp site.
#
#   Teachers use push(files) to upload file(s) from their computer to the
#   sftp site's root folder (by specifying user name ".").
#
#   Teachers use pull(files, who="studentUserId") to download one or more
#   student files to their current folder.

# One-time setup usage (per computer user):
#   source("https://raw.githubusercontent.com/hseltman/pushPull/master/setup.R")
#
# One time setup (per R session): source("~/pushPull.R")
#
# As needed usage:
# push(files="myFile.R") copies 'files' from the user's computer to folder
#   "userName" in the ftp folder (where 'userName' comes from the config file).
# pull(files="myFile.R", who=NULL) copies 'files' from the main ftp folder
#   to the user's computer (or from folder 'who'),

# References:
# https://stackoverflow.com/questions/15950396/sftp-get-files-with-r
# https://jonkimanalyze.wordpress.com/2014/11/20/r-quick-sftp-file-transfer/

# Return value for all three functions: invisible NULL

# Upload function
push = function(files) {
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")

  # get sftp info from config (or tell user how to run setup)
  fname = path.expand(file.path("~", "pushPullConfig.csv"))
  if (!file.exists(fname) ||
      !is.data.frame((dtf=try(read.csv(fname, as.is=TRUE), silent=TRUE))) ||
      !all(c("key", "value") %in% names(dtf)) ||
      !all(c("sftpSite", "sftpName", "sftpPassword", "userName") %in% dtf$key)) {
    cat("Missing or malformed ~/pushPullConfig.csv\n")
    cat("Run:\n")
    cat("source('https://raw.githubusercontent.com/hseltman/pushPull/master/setup.R'')\n")
    cat("setup()")
    stop("try again after running setup")
  }
  sftpSite = dtf$value[dtf$key=="sftpSite"]
  sftpName = dtf$value[dtf$key=="sftpName"]
  sftpPassword = dtf$value[dtf$key=="sftpPassword"]
  userName = dtf$value[dtf$key=="userName"]

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
  if (!require(RCurl, quietly=TRUE, warn.conflicts=FALSE))
    stop("install 'RCurl' and try again")
  front = paste0("sftp://", sftpName, ":", sftpPassword, "@", sftpSite)
  opts = list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    fRemote = file.path(userName, basename(f))
    rtn = try(ftpUpload(f, file.path(front, fRemote), .opts=opts), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("Upload of", f, "failed.\n")
      cat("Message:", as.character(attr(rtn, "condition")))
    }
  }

  invisible(NULL)
}


# Download function
pull = function(files, who=NULL) {
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  
  # get sftp info from config (or tell user how to run setup)
  fname = path.expand(file.path("~", "pushPullConfig.csv"))
  if (!file.exists(fname) ||
      !is.data.frame((dtf=try(read.csv(fname, as.is=TRUE), silent=TRUE))) ||
      !all(c("key", "value") %in% names(dtf)) ||
      !all(c("sftpSite", "sftpName", "sftpPassword", "userName") %in% dtf$key)) {
    cat("Missing or malformed ~/pushPullConfig.csv\n")
    cat("Run:\n")
    cat("source('https://raw.githubusercontent.com/hseltman/pushPull/master/setup.R'')\n")
    cat("setup()")
    stop("try again after running setup")
  }
  sftpSite = dtf$value[dtf$key=="sftpSite"]
  sftpName = dtf$value[dtf$key=="sftpName"]
  sftpPassword = dtf$value[dtf$key=="sftpPassword"]
  userName = dtf$value[dtf$key=="userName"]
  
  # Fixup files (subdirectories must be through "who")
  files = basename(files)
  if (!is.null(who)) {
    files = paste0(who, "/", files)
  }

  # Download files
  if (!require(RCurl, quietly=TRUE, warn.conflicts=FALSE))
    stop("install 'RCurl' and try again")
  front = paste0("sftp://", sftpName, ":", sftpPassword, "@", sftpSite)
  opts = list(ftp.create.missing.dirs=TRUE)
  for (f in files) {
    url = paste0("sftp://", sftpSite, "/", f)
    userpwd = paste0(sftpName, ":", sftpPassword)
    rtn = try(getURL(url, userpwd=userpwd), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("Download of", f, "failed.\n")
      cat("Message:", as.character(attr(rtn, "condition")))
    } else {
      fLocal = basename(f)
      rtn = try(write(rtn, fLocal), silent=TRUE)
      if (is(rtn, "try-error")) {
        cat("Download of", fLocal, "succeeded, but save to", getwd(), "failed.\n")
        cat("Message:", as.character(attr(rtn, "condition")))
      }
    }
  }
  
  invisible(NULL)
}
