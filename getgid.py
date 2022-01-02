#!/usr/bin/env python3

import grp, sys, os, yaml
from operator import itemgetter
from itertools import chain

def getgid(g):
    ''' get gid for group name'''
    try:
        return grp.getgrnam(g).gr_gid
    except KeyError:
        pass

def get_file_gid(fn):
    ''' get gid for file ame'''
    try:
        return os.stat(fn).st_gid
    except:
        pass

with open('docker-compose.yml', 'r') as f: 
    compose = yaml.safe_load(f)

# get device list for each service in composefile
services = compose['services'].values()
devices = list(chain(*map(itemgetter('devices'), services)))

# obtain gids for devices and custom ones provided on commanline
gids = chain(map(get_file_gid, devices), filter(None, map(getgid, sys.argv)))

print("gids=%s" % ",".join(map(str, set(gids))))
