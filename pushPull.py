"""
This is part of https://github.com/hseltman/pushPull
pushPull.py is the Python version of pushPull.R
See pushPull.R and setup.R for a full overview.

Python details:
One time install: From the operating system prompt run
  'conda install -c conda-forge pysftp'.
  If that fails, try 'pip install pysftp'.

Reference: http://pysftp.readthedocs.io/en/release_0.2.9/cookbook.html
           #pysftp-connection-cd
"""

import pysftp
import os.path


def push(files):
    """ Upload files to sftp server.  See pushPull.R for more details. """
    # Check input
    if isinstance(files, str):
        files = [files]
    if not isinstance(files, (list, tuple)):
        raise TypeError("'files' must be a str or list of str's")
    if not all([isinstance(s, str) for s in files]):
        raise TypeError("all 'files' elements must be str's")

    # Check if files are available
    OK = [os.path.isfile(f) for f in files]
    if not all(OK):
        print("Missing files:",
              ", ".join([f for (f, o) in zip(files, OK) if not o]))
        return "Failed"

    # Get configuration info
    cDir = os.path.expanduser("~/pushPullConfig.csv")
    msg = ("Missing or malformed ~/pushPullConfig.csv",
           "Run:",
           "source('https://raw.githubusercontent.com/hseltman/pushPull/" +
           "master/setup.R'')",
           "setup()",
           "Try again after running setup.")

    try:
        with open(cDir) as fh:
            config = fh.read()
    except FileNotFoundError:
        [print(m) for m in msg]
        return "Failed"

    config = [line.split(',') for line in config.splitlines()]
    if not all(len(e) == 2 for e in config):
        [print(m) for m in msg]
        return "Failed"

    config = {k.strip(): v.strip() for (k, v) in config}
    needed = ('sftpSite', 'sftpName', 'sftpPassword', 'userName')
    missing = [config.get(k) is None for k in needed]
    if any(missing):
        print("Missing config keys:",
              ", ".join([n for (m, n) in zip(missing, needed) if m]))

    # Handle the fact that it is possible that a named folder
    # rather that the starting folder is the first writeable folder.
    split = os.path.split(config['sftpSite'])
    if len(split[0]) == 0:
        site = split[1]
        startDir = None
    else:
        site = split[0]
        startDir = split[1]

    # open the ftp site and change to the writeable folder
    try:
        cnopts = pysftp.CnOpts()
        cnopts.hostkeys = None  # Hard to set on Windows
        sftp = pysftp.Connection(host=site,
                                 username=config['sftpName'],
                                 password=config['sftpPassword'],
                                 cnopts=cnopts)
        try:
            if startDir is not None:
                sftp.cwd(startDir)
        except FileNotFoundError:
            print("the starting folder in 'sftpSite' is wrong")
            return "Failure"
    except pysftp.ConnectionException:
        print("Cannot connect to {}".format(site))
        return "Failure"
    except pysftp.AuthenticationException:
        print("Bad username or password in configuration file")
        return "Failure"

    # Change to user's folder, creating it if needed
    if config['userName'] not in ['', '.']:
        if not sftp.isdir(config['userName']):
            try:
                sftp.mkdir(config['userName'])
            except Exception:
                print("Cannot make folder", config['userName'])
                return "Failure"
        try:
            sftp.chdir(config['userName'])
        except IOError:
            print("Cannot chdir server to", config['userName'])
            return("Failure")

    # push the files
    fail_count = 0
    for f in files:
        try:
            sftp.put(f)
        except IOError:
            print("cannot put {} on server".format(f))
            fail_count += 1
        except OSError:
            print("cannot find {} on your computer".format(f))
            fail_count += 1
    sftp.close()

    if fail_count == len(files):
        return "Failed"
    if fail_count == 0:
        return "Success"
    return "Partial success"


def pull(files, who=None):
    """ Download files from sftp server.  See pushPull.R for more details. """
    # Check input
    if isinstance(files, str):
        files = [files]
    if not isinstance(files, (list, tuple)):
        raise TypeError("'files' must be a str or list of str's")
    if not all([isinstance(s, str) for s in files]):
        raise TypeError("all 'files' elements must be str's")

    # Get configuration info
    cDir = os.path.expanduser("~/pushPullConfig.csv")
    msg = ("Missing or malformed ~/pushPullConfig.csv",
           "Run:",
           "source('https://raw.githubusercontent.com/hseltman/pushPull/" +
           "master/setup.R'')",
           "setup()",
           "Try again after running setup.")

    try:
        with open(cDir) as fh:
            config = fh.read()
    except FileNotFoundError:
        [print(m) for m in msg]
        return "Failure"

    config = [line.split(',') for line in config.splitlines()]
    if not all(len(e) == 2 for e in config):
        [print(m) for m in msg]
        return "Failure"

    config = {k.strip(): v.strip() for (k, v) in config}
    needed = ('sftpSite', 'sftpName', 'sftpPassword', 'userName')
    missing = [config.get(k) is None for k in needed]
    if any(missing):
        print("Missing config keys:",
              ", ".join([n for (m, n) in zip(missing, needed) if m]))

    # Handle the fact that it is possible that a named folder
    # rather that the starting folder is the first writeable folder
    # on the sftp server.  E.g., 'sftpSite' might be 'a.b.c.edu/base', where
    # we need to cd to 'base' to use sftp.
    split = os.path.split(config['sftpSite'])
    if len(split[0]) == 0:
        site = split[1]
        startDir = None
    else:
        site = split[0]
        startDir = split[1]

    # open the ftp site and change to the writeable folder
    try:
        cnopts = pysftp.CnOpts()
        cnopts.hostkeys = None  # Hard to set on Windows
        sftp = pysftp.Connection(host=site,
                                 username=config['sftpName'],
                                 password=config['sftpPassword'],
                                 cnopts=cnopts)
        try:
            if startDir is not None:
                sftp.cwd(startDir)
        except FileNotFoundError:
            print("the starting folder in 'sftpSite' is wrong")
            return "Failure"
    except pysftp.ConnectionException:
        print("Cannot connect to {}".format(site))
        return "Failure"
    except pysftp.AuthenticationException:
        print("Bad username or password in configuration file")
        return "Failure"

    # helper function to convert 'path/file.ext' to 'path/file-user.ext'
    def addUser(f, user):
        user = user.strip()
        if user in ('.', ""):
            user = "instructor"
        (root, ext) = os.path.splitext(f)
        return root + "-" + user + ext

    # pull the files
    fail_count = 0
    for f in files:
        if who is None:
            try:
                sftp.get(f, addUser(f, "instructor"))
            except FileNotFoundError:
                print("'{}' was not found on the server".format(f))
                fail_count += 1
        else:
            with sftp.cd():
                try:
                    sftp.cwd(who)
                except FileNotFoundError:
                    print("'folder {}' is not on the server".format(who))
                    fail_count += 1
                try:
                    sftp.get(f, addUser(f, who))
                except FileNotFoundError:
                    print("'{}' was not found on the server".format(f))
                    fail_count += 1
    sftp.close()

    if fail_count == len(files):
        return "Failed"
    if fail_count == 0:
        return "Success"
    return "Partial success"
