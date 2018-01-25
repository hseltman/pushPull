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


def pull(files):
    # Check input
    if isinstance(files, str):
        files = [files]
    if not isinstance(files, (list, tuple)):
        raise TypeError("'files' must be a str or list of str's")
    if not all([isinstance(s, str) for s in files]):
        raise TypeError("all 'files' elements must be str's")

    # Get config
    cDir = os.path.expanduser("~/pushPullConfig.csv")
    return cDir


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
