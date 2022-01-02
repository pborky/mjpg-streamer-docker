#!/usr/bin/env python3

import grp, sys


def getgid(g):
    try:
        return grp.getgrnam(g).gr_gid
    except KeyError:
        pass


required_groups = ["video"]
gids = filter(None, map(getgid, required_groups + sys.argv))

print("gids=%s" % ",".join(map(str, gids)))
