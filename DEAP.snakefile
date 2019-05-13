#!/usr/bin/env python

import os
import sys
import subprocess
import pandas as pd
import yaml
from string import Template
from collections import defaultdict
# vim: syntax=python tabstop=4 expandtab
# coding: utf-8

def updateMeta(config):
    _sanity_checks(config)
    metadata = pd.read_csv(config['metasheet'], index_col=0, sep=',', comment='#', skipinitialspace=True)
    config["comparisons"] = [c[5:] for c in metadata.columns if c.startswith("compare_")]
    config["comps"] = _get_comp_info(metadata)
    config["metacols"] = [c for c in metadata.columns if c.lower()[:4] != 'compare']
    config["file_info"] = { sampleName : config["samples"][sampleName] for sampleName in metadata.index }
    config["ordered_sample_list"] = metadata.index
    print(config)
    return config

def _sanity_checks(config):
    #metasheet pre-parser: converts dos2unix, catches invalid chars
    _invalid_map = {'\r':'\n', '(':'.', ')':'.', ' ':'_', '/':'.', '$':''}
    _meta_f = open(config['metasheet'])
    _meta = _meta_f.read()
    _meta_f.close()

    _tmp = _meta.replace('\r\n','\n')
    #check other invalids
    for k in _invalid_map.keys():
        if k in _tmp:
            _tmp = _tmp.replace(k, _invalid_map[k])

    #did the contents change?--rewrite the metafile
    if _meta != _tmp:
        #print('converting')
        _meta_f = open(config['metasheet'], 'w')
        _meta_f.write(_tmp)
        _meta_f.close()


def _get_comp_info(meta_info):
    comps_info = defaultdict(dict)
    for comp in meta_info.columns:
        if comp[:5] == 'comp_':
            comps_info[comp[5:]]['control'] = meta_info[meta_info[comp] == 1].index
            comps_info[comp[5:]]['treat'] = meta_info[meta_info[comp] == 2].index

    return comps_info


def getRuns(config):
    """parse metasheet for Run groupings"""
    ret = {}

    #KEY: need skipinitialspace to make it fault tolerant to spaces!
    metadata = pd.read_csv(config['metasheet'], index_col=0, sep=',', comment='#', skipinitialspace=True)
    f = metadata.to_csv().split() #make it resemble an actual file with lines
    #SKIP the hdr
    for l in f[1:]:
        tmp = l.strip().split(",")
        #print(tmp)
        ret[tmp[0]] = tmp[1:]

    #print(ret)
    config['runs'] = ret
    return config

def addPy2Paths_Config(config):
    """ADDS the python2 paths to config"""
    conda_root = subprocess.check_output('conda info --root',shell=True).decode('utf-8').strip()
    conda_path = os.path.join(conda_root, 'pkgs')
    config["python2_pythonpath"] = os.path.join(conda_root, 'envs', 'chips_py2', 'lib', 'python2.7', 'site-packages')
    
    if not "python2" in config or not config["python2"]:
        config["python2"] = os.path.join(conda_root, 'envs', 'chips_py2', 'bin', 'python2.7')

def loadRef(config):
    """Adds the static reference paths found in config['ref']
    NOTE: if the elm is already defined, then we DO NOT clobber the value
    """
    f = open(config['ref'])
    ref_info = yaml.safe_load(f)
    f.close()
    #print(ref_info[config['assembly']])
    for (k,v) in ref_info[config['assembly']].items():
        #NO CLOBBERING what is user-defined!
        if k not in config:
            config[k] = v

#---------  CONFIG set up  ---------------
configfile: "config.yaml"   # This makes snakemake load up yaml into config 
config = updateMeta(config)
addPy2Paths_Config(config)

#NOW load ref.yaml - SIDE-EFFECT: loadRef CHANGES config
loadRef(config)
#-----------------------------------------

def all_targets(wildcards):
    print(config)
    ls = []
    #IMPORT all of the module targets
    ls.extend(align_salmon_targets(wildcards))

    return ls   

# include: "./modules/fastqc.snakefile"

if config['aligner'] == 'STAR':
    include: "./modules/align_STAR.snakefile"     # rules specific to STAR
else:
	include: "./modules/align_salmon.snakefile"   # rules specific to salmon



