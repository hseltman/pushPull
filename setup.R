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

# Setup also store pushPull.R and pushPull.py in the users "~" folder.

# Problem: on Windows, "~" expands differently in R and Python!!
# Solution: maintain two copies of the configuration file

setup = function() {
  userHome = path.expand("~")
  if (Sys.info()["sysname"] == "Windows") {
    parts = strsplit(userHome, "[/\\]")[[1]]
    nparts = length(parts)
    if (parts[nparts] == "Documents") {
      # Python and duplicate setup location
      userHome2 = do.call(file.path, as.list(parts[1:(nparts-1)]))
      setupName2 = file.path(userHome2, "pushPullConfig.csv")
    }
  }
  setupName = file.path(userHome, "pushPullConfig.csv")
  
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
  if (exists("setupName2")) {
    w = try(write.csv(dtf, setupName2, quote=FALSE, row.names=FALSE), silent=TRUE)
    if (is(w, "try-error")) {
      stop("Cannot write to ", setupName2)
    }
  }
  
  # Put main R code in userHome
  codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPull.R"
  rCode = try(readLines(codeLoc), silent=TRUE)
  if (is(rCode, "try-error")) {
    stop("Failed to load pushPull.R code from github")
  }
  rName = file.path(userHome, "pushPull.R")
  msg = try(write(rCode, rName), silent=TRUE)
  if (is(msg, "try-error")) {
    stop("cannot write ", rName)
  }
  
  # Put main Python code in userHome(2)
  codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPull.py"
  pCode = try(readLines(codeLoc), silent=TRUE)
  if (is(pCode, "try-error")) {
    stop("Failed to load pushPull.py code from github")
  }
  pythonHome = if (exists("userHome2")) userHome2 else userHome
  pName = file.path(pythonHome, "pushPull.py")
  msg = try(write(pCode, pName), silent=TRUE)
  if (is(msg, "try-error")) {
    stop("cannot write ", pName)
  }
  
  # Report success
  cat("Successfully wrote", basename(setupName), "and", basename(rName),
      "to", userHome, "\n")
  if (exists("userHome2")) {
    cat("Successfully wrote", basename(setupName), "to", userHome2, "\n")
  }
  cat("Successfully wrote", basename(pythonHome), "to", pythonHome, "\n")
  invisible(NULL)
}
