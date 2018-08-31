# When the package is loaded, attempt to set the site/user
# specific sftp server information in the options().
#
# When the package is attached the user is reminded to run
# setup() to store the site/user info (in "pushPullInfo.dat" in the
# package folder).

.onLoad <- function(libname, pkgname){
  packageFolder = system.file(package="pushPull")
  fname = file.path(packageFolder, "pushPullInfo.txt")
  userSftpInfo = try(suppressWarnings(readLines(fname)), silent=TRUE)
  if (!methods::is(userSftpInfo, "try-error")) {
    names(userSftpInfo) = c("sftpSite", "sftpName", "sftpPassword", "userName")
    options(pushPullInfo=userSftpInfo)
  }
}

.onAttach <- function(libname, pkgname){
  if (is.null(getOption("pushPullInfo")))
    packageStartupMessage("Please run sftpSetup() now.")
}
