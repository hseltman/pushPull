"""
pushPull.py is the Python version of pushPull.R
See pushPull.R and setup.R for a full overview.

Python details:
One time install: from operating system prompt run 'pip install pysftp'

Reference: http://pysftp.readthedocs.io/en/release_0.2.9/cookbook.html
           #pysftp-connection-cd
"""

import pysftp
import os.path


def pull(files, who=None):
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
        return None

    config = [line.split(',') for line in config.splitlines()]
    if not all(len(e) == 2 for e in config):
        [print(m) for m in msg]
        return None

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
            return None
    except pysftp.ConnectionException:
        print("Cannot connect to {}".format(site))
        return None
    except pysftp.AuthenticationException:
        print("Bad username or password in configuration file")
        return None

    # pull the files
    for f in files:
        if who is None:
            try:
                sftp.get(f)
            except FileNotFoundError:
                print("'{}' was not found on the server".format(f))
        else:
            with sftp.cd():
                sftp.cwd(who)
                try:
                    sftp.get(f)
                except FileNotFoundError:
                    print("'{}' was not found on the server".format(f))
    return None


if __name__ == "__main__":
    print(pull("aloha.txt", "hseltman"))

if __name__ == "__testing__":
    # Check if files exist
    files = ["x"]
    not_exists = [f for f in files if not os.path.exists(f)]
    if len(not_exists) > 0:
        raise Exception("file does not exist")

    cnopts = pysftp.CnOpts()
    cnopts.hostkeys = None
    srv = pysftp.Connection(host="cetus.stat.cmu.edu",
                            username="mspsftp",
                            password="sftpmsp",
                            cnopts=cnopts)
    srv.cwd("mspsftp")
    srv.get("empty.txt")
    srv.put("ytpme.txt")
    srv.cwd("hseltman")
    srv.put("ytpme.txt")
    srv.cwd("..")
    srv.get("low.txt")
    srv.listdir()
    srv.get("hseltman/hello.txt")

    with srv.cd():
        srv.cwd("hseltman")
        print(srv.listdir())
        srv.put('README.md')
    print(srv.listdir())

    srv.close()
