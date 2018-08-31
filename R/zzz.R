# When the package is loaded, attempt to set the site/user
# specific sftp server information in the options().
#
# When the package is attached the user is reminded to run
# setup() to store the site/user info (in "~/pushPullInfo.dat").

.onLoad <- function(libname, pkgname){
  userSftpInfo = try(suppressWarnings(readLines(file.path("~", "pushPullInfo.txt"))), silent=TRUE)
  if (!methods::is(userSftpInfo, "try-error")) {
    names(userSftpInfo) = c("sftpSite", "sftpName", "sftpPassword", "userName")
    options(pushPullInfo=userSftpInfo)
  }
}

.onAttach <- function(libname, pkgname){
  if (is.null(options("pushPullInfo"))) packageStartupMessage("run setup()")
}
