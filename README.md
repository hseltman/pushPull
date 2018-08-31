# pushPull
An educational tool for classrooms where coding is being taught.

This tool allows easy sharing of code between students and teachers, on the fly, via a common sftp account.

You must first setup the sftp server and know its URL, sftp login name,
and password.

To install run (in R/RStudio, as an administrator):
  library(devtools)
  install_git("git://github.com/hseltman/pushPull")

First time usage (in R/RStudio, as an administrator):
  library(pushPull)
  sftpSetup() # Then enter URL, login name, sftp login name, and username

The username is any unique string that can be a directory name, e.g.,
the basename of the students unique assigned email name.

General usage (in R/Rstudio)
  library(pushPull)
  # by a teacher to upload "ex1.R"
  push("ex1.R")
  
  # by a student to download copy of "ex1.R"
  pull("ex1.R")
  
  # by a student to upload a revised "ex1.R"
  push("ex1.R") # goes into sftp folder named by students username
  
  # by a teacher to download "ex1.R" from student "obama"
  pull("ex1.R", "obama"")
  
  
Instructions for creating the package on a clone of this git, starting
in the folder above "pushPull" at a command prompt:
  R CMD build pushPull
  R CMD check pushPull_0.1.0.tar.gz
  R -e setwd('pushPull');library(devtools);document()
  R CMD BUILD pushPull
  
Substitute the current version informstion in the "check".
The package is in the tar.gz file.

  
  