# When the package is loaded, attempt to set the site/user
# specific sftp server information in the options().
# The information is read from "pushPullInfo.txt" in the package
# root directory which is plain text with four lines corresponding to
# the sftp site name, sftp user name, sftp password, and student user name.
# (The intent is that in the simple setup, students share the sftp
# user name and password, and their student user name is used as the
# directory name for each student.)
#
# When the package is attached, the user is reminded to run
# sftpSetup() to store the site/user info.

.onLoad <- function(libname, pkgname){
  packageFolder = system.file(package="pushPull")
  fname = file.path(packageFolder, "pushPullInfo.txt")
  userSftpInfo = try(suppressWarnings(readLines(fname)), silent=TRUE)
  if (!methods::is(userSftpInfo, "try-error")) {
    names(userSftpInfo) = c("sftpSite", "sftpName", "sftpPassword", "userName")
    options(pushPullInfo=userSftpInfo)
  }
}

# When the package is attached, the user is reminded to run sftpSetup()
# if it has not been run before.

.onAttach <- function(libname, pkgname){
  if (is.null(getOption("pushPullInfo")))
    packageStartupMessage("Please run sftpSetup() now.")
}
