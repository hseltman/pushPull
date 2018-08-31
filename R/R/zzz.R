.pkgenv <- new.env(parent=emptyenv())

.onLoad <- function(libname, pkgname){
  #t = try(suppressWarnings(load(file.path("~", "pushPullInfo.RData"))), silent=TRUE)
  userSftpInfo = try(suppressWarnings(readLines(file.path("~", "pushPullInfo.txt"))), silent=TRUE)
  if (!methods::is(userSftpInfo, "try-error")) {
    names(userSftpInfo) = c("sftpSite", "sftpName", "sftpPassword", "userName")
    .pkgenv[["userSftpInfo"]] = userSftpInfo
  }
}

.onAttach <- function(libname, pkgname){
  if (is.null(.pkgenv[["userSftpInfo"]])) packageStartupMessage("run setup()")
}
