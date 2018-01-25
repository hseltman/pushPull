# Push/pull project, Jan 2018, H. Seltman
# 
# This is the setup function for "pushPull".  See pushPull.R for details.

# One-time setup usage in R (setup in R also sets up for other languages):
# source("https://raw.githubusercontent.com/hseltman/pushPull/master/setup.R")
# setup()

# Setup asks the user for the name of the common sftp site, the sftp username,
# the sftp password, and the users id, and stores thwaw under ~/pushPullConfig.csv.
# Future use of push() or pull() from pushPull.R will read this configuration info.
# Any push() or pull() functions in other languages should read the same config.

setup = function() {
  setupName = path.expand(file.path("~", "pushPullConfig.csv"))
  
  # Get old values if any
  sftpSite = NULL
  sftpName = NULL
  sftpPassword = NULL
  userName = NULL
  if (file.exists(setupName)) {
    dtf = try(read.csv(setupName, as.is=TRUE), silent=TRUE)
    if (is(dtf, "data.frame")) {
      if (all(c("key", "value") %in% names(dtf))) {
        sftpSite = dtf[dtf$key=="sftpSite", "value"]
        sftpName = dtf[dtf$key=="sftpName", "value"]
        sftpPassword = dtf[dtf$key=="sftpPassword", "value"]
        userName = dtf[dtf$key=="userName", "value"]
      } else {
        warning(setupName, " is a csv file, but is missing 'key' and/or 'value'")
      }
    } else {
      warning(setupName, " exists, but is not in csv format")
    }
  }

  # Helper function to ask for input with a default (allows "QUIT")
  ask = function(prompt, default=NULL) {
    if (!is.null(default) && length(default)>0) {
      prompt = paste0(prompt, " (or Enter for '", default, "')")
    }
    rtn = readline(paste0(prompt, "? "))
    if (toupper(rtn) %in% c("Q", "QUIT"))
      stop("user quit setup()")
    if (!is.null(default) && rtn=="") rtn = default
    return(rtn)
  }

  # Get new values for all parameters
  sftpSite = ask("sftp site [not including sftp://]", sftpSite)
  sftpName = ask("sftp login name", sftpName)
  sftpPassword = ask("sftp password", sftpPassword)
  userName = ask("Your user name", userName)

  # Store values in configuration file
  dtf = data.frame(key = c("sftpSite", "sftpName", "sftpPassword", "userName"),
                   value = c(sftpSite, sftpName, sftpPassword, userName))
  w = try(write.csv(dtf, setupName, quote=FALSE, row.names=FALSE), silent=TRUE)
  if (is(w, "try-error")) {
    stop("Cannot write to ", setupName)
  }
  
  # Put main code in "~"
  codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPull.R"
  code = try(readLines(codeLoc), silent=TRUE)
  if (is(code, "try-error")) {
    stop("Failed to load pushPull.R code from github")
  }
  rname = path.expand(file.path(fileLoc, "pushPull.R"))
  msg = try(write(code, rname), silent=TRUE)
  if (is(msg, "try-error")) {
    stop("cannot write ", rname)
  }
  
  # Report success
  cat("Successfully wrote ", setupName, " and ", rname)
  invisible(NULL)
}
