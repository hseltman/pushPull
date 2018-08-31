# Push/pull project, Jan 2018, H. Seltman
# See pushPull.R and setup.R at https://github.com/hseltman/pushPull
#
# This is pushPullMac.R.  It is the workaround for doing push() and pull()
# in R on a Mac.  The workaround is needed because installing sftp for RCurl
# is non-trivial, so this version just runs the corresponding Python versions
# stored in the user's home directory.  
# 
#
# Usage (after setup):
# source("~/pushPull.R")
# push(files="myFile.R") copies 'files' from the user's computer to folder
#   "userName" in the ftp folder (where 'userName' comes from the config file).
# pull(files="myFile.R", who=NULL) copies 'files' from the main ftp folder
#   to the working directory of the user's computer, adding "-instructor"
#   before the extension.  This is the default "student" mode.
#   When the instructor is pulling from a specific ('who') student folder,
#   "-myStudent" is added to the file name before the file is stored in the
#   instructor's working directory.

# Upload function
# Note: 'files' may include a path
push = function(files) {
  # This function is for Mac only
  os = Sys.info()["sysname"]
  if (os != "Darwin") {
    stop("attempting to run the Mac version on ", os)
  }

  # Check input
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  files = trimws(files)
  files = files[files != ""]
  if (length(files) == 0) {
    stop("No files in 'files'")
  }

  
  # get user info from config (or tell user how to run setup)
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
  for (f in files) {
    cmd = paste0("~/push.py '", f, "'")
    rtn = try(system(cmd), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("Failed to push ", f, ": ", str(attr(rtn, "CONDITION")))
    }
  }
  
  invisible(NULL)
}


# Download function
# Note 'files' cannot include a path
pull = function(files, who=NULL) {
  # This function is for Mac only
  os = Sys.info()["sysname"]
  if (os != "Darwin") {
    stop("attempting to run the Mac version on ", os)
  }
  
  # Check input
  if (length(files) == 0 || !is.character(files))
    stop("'files' must be a string vector")
  files = trimws(files)
  files = files[files != ""]
  if (length(files) == 0) {
    stop("No files in 'files'")
  }
  
  # # Fixup files (subdirectories must be through "who")
  # files = basename(files)
  # if (!is.null(who)) {
  #   files = paste0(who, "/", files)
  # }
  # 
  # Download files
  for (f in files) {
    if (is.null(who)) { # Student pull from instructor (main folder)
      cmd = paste0("~/pull.py '", f, "'")
    } else { # Instructor pull from a student folder
      cmd = paste0("~/pull.py '", f, "' '", who, "'")
    }
    rtn = try(system(cmd), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("Failed to pull ", f, ": ", str(attr(rtn, "CONDITION")))
    }
  }
  invisible(NULL)
}
