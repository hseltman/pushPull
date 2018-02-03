# Push/pull project, Jan 2018, H. Seltman
# 
# This is the setup function for "pushPull".  See pushPull.R for more details.

# One-time setup for Python (or R on a Mac; see below):
#    conda install -c conda-forge pysftp (as an administrator on Windows)
# (or if that fails: pip install pysftp)

# One-time setup usage in R (setup in R also sets up for other languages):
# source("https://raw.githubusercontent.com/hseltman/pushPull/master/setup.R")
# setup()

# setup() asks the user for the name of the common sftp site, the sftp username,
# the sftp password, and the users id, and stores that under ~/pushPullConfig.csv.
# Setup also store pushPull.R and pushPull.py in an appropriate place (see below)
# on the user's computer.

# In a future R session, the user runs "source("~/pushPull.R") to load
# the push() and pull() functions.

# In a future Python session, the user runs "import PushPull" to load push()
# and pull() from pushPull.py.

# Problem: on Windows, "~" expands differently in R and Python!!
# Solution:
#   Normally (Mac and Windows Python), use Sys.getenv("HOME") as
#   the location of the config file and code.
#
#   On Windows, if "Documents" ends the path, drop it for the path for
#   Python

# Problem: We would like a user to type only "from pushPull import push, pull",
#   but Python's sys.path is not very predictable across operating systems.
# Solution: Set PYTHONPATH to include $HOME and place pushPull.py there.
#   To make this permanent, use "setx" on Windows (probably requires admin
#   privileges).  On a Mac, edit .bash_profile to contain
#     if [ -f ~/.bashrc ]; then
#        source ~/.bashrc
#     fi
#   and in ~/.bashrc include:
#     export PYTHONPATH=/my/homePath

# Problem: Spyder on a Mac ignores PYTHONPATH.
# Solution: Also place pushPull.py in $HOME/.ipython if it exists.

# Problem: On a Mac (High Sierra) as of January 2018 "sftp" works from
#   the command prompt, and pysftp allows Python to run sftp, but from
#   the R "RCurl" package, sftp is not available (as shown with 
#    curlVersion()$protocols).  Supposedly the problem is that the
#   "libcurl" program installed on the Mac does not support sftp
#   (http://andrewberls.com/blog/post/adding-sftp-support-to-curl),
#   but checking "curl -V" at the terminal prompt does show sftp to be active.
# Solution:
#   On a Mac have R just run a script that passes the file name to
#   push() or pull() in Python.  This is much simpler than having the
#   user do a recompilation of libcurl2.

# Problem: Running "system(cmd)" in R is not the same as running "cmd"
#   at the operating system prompt.  On a Mac, one might find "which python"
#   to be "/Users/hseltman/anaconda/bin/python" which runs Python 3 from R,
#   but "/usr/bin/python" which runs Python 2 from the command prompt.
#   The code in pushPull.py is written in Python 3, but from inside R we
#   use system() to run the special pull.py and push.py scripts that execute
#   the push() and pull() functions inside pushPull.py.
# Solution: During setup, as the user if we have correctly identified the
#   path to Python 3 (on a Mac only).

# References:
# https://ss64.com/nt/setx.html
# https://anaconda.org/conda-forge/pysftp
# http://www.joshstaiger.org/archives/2005/07/bash_profile_vs.html


setup = function() {
  rHome = home = Sys.getenv("HOME")
  if (home == "") stop("Environmental variable 'HOME' is undefined")
  os = Sys.info()["sysname"]
  if (os == "Windows") {
    if (grepl("/Documents$", home)) {
      home = substring(home, 1, nchar(home) - 10)
    }
  }
  setupFile = file.path(home, "pushPullConfig.csv")
  rSetupFile = file.path(rHome, "pushPullConfig.csv")
  
  # Get old values if any
  sftpSite = NULL
  sftpName = NULL
  sftpPassword = NULL
  userName = NULL
  python3Path = NULL
  if (file.exists(rSetupFile)) {
    dtf = try(read.csv(rSetupFile, as.is=TRUE), silent=TRUE)
    if (is(dtf, "data.frame")) {
      if (all(c("key", "value") %in% names(dtf))) {
        sftpSite = dtf[dtf$key=="sftpSite", "value"]
        sftpName = dtf[dtf$key=="sftpName", "value"]
        sftpPassword = dtf[dtf$key=="sftpPassword", "value"]
        userName = dtf[dtf$key=="userName", "value"]
        if (os == "Darwin" && "python3Path" %in% dtf$key) {
         python3Path = dtf[dtf$key=="python3Path", "value"]
        }
      } else {
        warning(rSetupFile, " is a csv file, but is missing 'key' and/or 'value'")
      }
    } else {
      warning(rSetupFile, " exists, but is not in csv format")
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
  if (os == "Darwin") {
    if (is.null(python3Path) || trimws(python3Path) == "") {
      python3Path = file.path(home, "anaconda/bin")
    }
    python3Path = ask("Path to Python 3", python3Path)
  }
  
  # Store values in configuration file
  key = c("sftpSite", "sftpName", "sftpPassword", "userName")
  value = c(sftpSite, sftpName, sftpPassword, userName)
  if (os == "Darwin") {
    key = c(key, "python3Path")
    value = c(value, python3Path)
  }
  dtf = data.frame(key = key, value = value)
  w = try(write.csv(dtf, rSetupFile, quote=FALSE, row.names=FALSE), silent=TRUE)
  if (is(w, "try-error")) {
    stop("Cannot write to ", rSetupFile)
  }
  if (setupFile != rSetupFile) {
    w = try(write.csv(dtf, rSetupFile, quote=FALSE, row.names=FALSE), silent=TRUE)
    if (is(w, "try-error")) {
      stop("Cannot write to ", rSetupFile)
    }
  }
  
  # Put main R code in user's home folder(s)
  if (os == "Darwin") {
    codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPullMac.R"
  } else {
    codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPull.R"
  }
  rCode = try(suppressWarnings(readLines(codeLoc, warn=FALSE)), silent=TRUE)
  if (is(rCode, "try-error")) {
    stop("Failed to load pushPull.R code from github")
  }
  rName = file.path(rHome, "pushPull.R")
  msg = try(write(rCode, rName), silent=TRUE)
  if (is(msg, "try-error")) {
    stop("cannot write ", rName)
  }
  
  # Get main Python code
  codeLoc = "https://raw.githubusercontent.com/hseltman/pushPull/master/pushPull.py"
  pCode = try(suppressWarnings(readLines(codeLoc, warn=FALSE)), silent=TRUE)
  if (is(pCode, "try-error")) {
    stop("Failed to load pushPull.py code from github")
  }
  
  # Put the code in the user's home folder and any .ipython subfolder
  # (because Spyder does not read PYTHONPATH, but does add the .ipython
  # folder to its module path (sys.path)).
  pName = file.path(home, "pushPull.py")
  msg = try(write(pCode, pName), silent=TRUE)
  if (is(msg, "try-error")) {
    stop("cannot write ", pName)
  }
  iPDir = file.path(home, ".ipython")
  iPName = file.path(iPDir, "pushPull.py")
  if (isTRUE(file.info(iPDir)$isdir)) {
    msg = try(write(pCode, iPName), silent=TRUE)
    if (is(msg, "try-error")) {
      stop("cannot write ", iPName)
    }
  }
  
  # Set the PYTHONPATH (if not already there) so that the pushPull module
  # is accessable from Python started outside of Anaconda.
  oldPythonPath = Sys.getenv("PYTHONPATH")
  pythonPath = NULL
  if (oldPythonPath == "") {
    pythonPath = home
  } else {
    pps = strsplit(oldPythonPath, ";")[[1]]
    if (!any(grepl(home, pps))) {
      pythonPath = paste0(home, ";", oldPythonPath)
    }
  }
  if (!is.null(pythonPath)) {
    if (os == "Windows") {
      rtn = try(shell(paste("setx PYTHONPATH", pythonPath), intern=TRUE),
                silent=TRUE)
      if (is(rtn, "try-error")) {
        warning("PYTHONPATH was not set: ", as.character(attr(rtn, "CONDITION")))
      }
      # Mac setup
    } else {
      bpFile = file.path(home, ".bash_profile")
      bpt = try(suppressWarnings(readLines(bpFile, warn=FALSE)), silent=TRUE)
      sourceBashProfileText = c("if [ -f ~/.bashrc ]; then",
                                "  source ~/.bashrc",
                                "fi")
      bashProfileText = sourceBashProfileText
      needWrite = TRUE
      if (!is(bpt, "try-error")) {
        if (any(grepl("[.]bashrc", bpt))) {
          needWrite = FALSE
        } else {
          bashProfileText = c(bpt, "\n\n", sourceBashProfileText)
        }
      }
      if (needWrite) {
        rtn = try(write(bashProfileText, bpFile), silent=TRUE)
        if (is(rtn, "try-error")) {
          warning("Cannot write ", bpFile, ": ", as.character(attr(rtn, "CONDITION")))
          print("'import pushPull' in Python may not work")
        }
        rtn = system(paste0("chmod u+x ", bpFile))
        if (is(rtn, "try-error")) {
          warning("Cannot set to executable: ", bpFile, ": ",
                  as.character(attr(rtn, "CONDITION")))
          print("'import pushPull' in Python may not work")
        }
      }
      #
      brcFile = file.path(home, ".bashrc")
      brct = try(suppressWarnings(readLines(brcFile, warn=FALSE)), silent=TRUE)
      sourceBashrcText = paste0("export PYTHONPATH=", home)
      bashrcText = sourceBashrcText
      newExport = paste0("export PYTHONPATH=", home)
      needWrite = TRUE
      # Handle case where old .bashrc text is present
      if (!is(brct, "try-error")) {
        # Declare defeat if more than one line has "export ...PYTHONPATH"
        exports = grep("^\\s*export", brct)
        PP = grep("PYTHONPATH\\s*=", brct, ignore.case=TRUE)
        expPP = intersect(exports, PP)
        if (length(expPP) > 1) {
          stop("PYTHONPATH is exported more than once in ", brcFile,
               "\nFix it and then try setup() again.")
        }
        # Handle a .bashrc file without "export ... PYTHONPATH"
        if (length(expPP) == 0) {
          bashrcText = c(brct, "\n\n", sourceBashrcText)
          # Handle a .bashrc file with "export ... PYTHONPATH"
        } else {
          expLine = gsub("pythonpath", "PYTHONPATH", brct[expPP], ignore.case=TRUE)
          ppLoc = regexpr("PYTHONPATH", expLine)
          oldPaths = regmatches(expLine,
                                regexpr("PYTHONPATH\\s*=\\s*.[^ ]+", expLine))
          oldPaths = gsub("^PYTHONPATH\\s*=\\s*", "", oldPaths)
          oldPaths = strsplit(oldPaths, ":")[[1]]
          homeLoc = match(home, oldPaths)
          if (is.na(homeLoc)) {
            paths = paste(c(home, oldPaths), collapse=":")
            bashrcText = brct
            bashrcText[expPP] = paste0("export PYTHONPATH=", paths)
            newExport = bashrcText[expPP]
          } else {
            needWrite = FALSE
          }
        }
      }
      # Write the new or modified .bashrc file
      if (needWrite) {
        rtn = try(write(bashrcText, brcFile), silent=TRUE)
        if (is(rtn, "try-error")) {
          warning("Cannot write ", brcFile, ": ",
                  as.character(attr(rtn, "CONDITION")))
          print("'import pushPull' in Python may not work")
        }
        rtn = system(paste0("chmod u+x ", brcFile))
        if (is(rtn, "try-error")) {
          warning("Cannot set to executable: ", brcFile, ": ",
                  as.character(attr(rtn, "CONDITION")))
          print("'import pushPull' in Python may not work")
        }
        rtn = try(system(newExport), silent=TRUE)
        if (is(rtn, "try-error")) {
          warning("Cannot export PYTHONPATH: ",
                  as.character(attr(rtn, "CONDITION")))
          print("'import pushPull' in Python may not work")
        }
      }
    }
  }
  
  # On a Mac create push.py and pull.py in the user's home directory
  pushScript = FALSE
  pullScript = FALSE
  if (os == "Darwin") {
    pullPy = c("#!/Users/hseltman/anaconda/bin/python",
               "# This is pull.py from https://github.com/hseltman/pushPull",
               " ", 
               "import pushPull",
               "import sys",
               " ", 
               "file = sys.argv[1]",
               "if len(sys.argv) == 2:",
               "    pushPull.pull(file)",
               "else:",
               "    pushPull.pull(file, sys.argv[2])")
    pushPy = c("#!/Users/hseltman/anaconda/bin/python",
               "# This is push.py from https://github.com/hseltman/pushPull",
               " ", 
               "import pushPull",
               "import sys",
               " ", 
               "file = sys.argv[1]",
               "pushPull.push(file)")
    pullName = file.path(home, "pull.py")
    rtn = try(write(pullPy, pullName), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("could not write ", pullName, ": ", str(attr(rtn, "CONDITION")))
      warning("R pull() may not work")
    } else {
      pullScript= TRUE
      rtn = system(paste0("chmod u+x ", pullName))
      if (rtn != 0) {
        cat("could not chmod to 'u+x' ", pullName)
        warning("R pull() may not work")
      }
    }

    pushName = file.path(home, "push.py")
    rtn = try(write(pushPy, pushName), silent=TRUE)
    if (is(rtn, "try-error")) {
      cat("could not write ", pushName, ": ", str(attr(rtn, "CONDITION")))
      warning("R push() may not work")
    } else {
      pushScript = TRUE
      rtn = system(paste0("chmod u+x ", pushName))
      if (rtn != 0) {
        cat("could not chmod to 'u+x' ", pushName)
        warning("R push() may not work")
      }
    }
  } # end push/pull scripts
  
  # Report success
  cat("Successfully wrote setup.csv and pushPull.R to", rHome, "\n")
  if (home != rHome) {
    cat("Successfully wrote setup.csv to", home, "\n")
  }
  cat("Successfully wrote pushPull.py to", home, "\n")
  if (pushScript) cat("Successfully wrote", pushName, "\n") 
  if (pullScript) cat("Successfully wrote", pullName, "\n") 
  invisible(NULL)
}
