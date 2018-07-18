# coding = utf-8
import sys, os, glob, json, re
import networkx as nx

methods_read_graph={
        "gexf":nx.read_gexf,
        "gml":nx.read_gml,
        "graphml":nx.read_graphml
    }

def extract_number(fn):
    try:
        return int(re.findall("\d+",fn)[-1])
    except:
        print("No number found !")
        return 0


def import_dir(directory,format="gexf",numbered=True):
    if not os.path.exists(directory):
        raise FileNotFoundError
    if not format in methods_read_graph:
        raise NotImplementedError("{0} is not implemented !".format(format))

    fns = glob.glob(os.path.join(directory, "*.{0}".format(format)))

    graphs=[]
    if numbered:
        n=max([extract_number(fn) for fn in fns])
        graphs= [nx.Graph()]*(n+1)

    association_map, i = {}, 0
    for fn in fns:
        if not numbered:
            graphs.append(methods_read_graph[format](fn))
            association_map[fn]=i
            i+=1
        else:
            graphs[extract_number(fn)]=methods_read_graph[format](fn)
    if not numbered:
        return association_map,graphs
    return graphs
