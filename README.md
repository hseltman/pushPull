# pushPull
An educational tool for classrooms where coding is being taught.

This tool allows easy sharing of code between students and teachers, on the fly, via a common sftp account.

It is assumed that an sftp server has been set up and you know its URL, sftp login name,
and password.

On a Mac, sftp is likely to not be supported in curl, and hence RCurl.
To fix this, run "terminal", create a new directory and change in to it,
then download the "install" script, e.g., with

curl -o install https://raw.githubusercontent.com/hseltman/pushPull/master/macScript/install

Then run the script using:

bash install

To install run (in R/RStudio, as an administrator):

  library(devtools)

  install_github("hseltman/pushPull")

First time usage (in R/RStudio, as an administrator):

  library(pushPull)

  sftpSetup() # Then enter URL, login name, sftp login name, and username

The username is any unique string that can be a directory name, e.g.,
the basename of the students unique assigned University email name.

General usage (in R/Rstudio)

  pull("ex1.R") # Student gets copy of the instructor's "ex1.R"
  
  push("ex2.R") # Student uploads their own copy of "ex2.R"

Instructions for creating the package on a clone of this git, starting
in the folder above "pushPull" at a command prompt:

  R -e 'setwd("pushPull");library(devtools);document()'

  R CMD build pushPull

  R CMD check pushPull_x.x.x.tar.gz

  R CMD BUILD pushPull
  
Substitute the current version information in the "check".

The new package will be in the new tar.gz file.  Copy it to
the pushPull folder.
