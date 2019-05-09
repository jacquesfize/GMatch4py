# coding = utf-8
import sys, os, glob, json, re
import networkx as nx
from tqdm import tqdm


"""
The reader submodule contains high-level function to read and store graphs from various files.
"""



methods_read_graph={
        "gexf":nx.read_gexf,
        "gml":nx.read_gml,
        "graphml":nx.read_graphml
    }

def extract_index(fn):
    """
    Extract index from filename
    Parameters
    ----------
    fn : str
        filename

    Returns
    -------
    int
        index
    """
    try:
        return int(re.findall("\d+",fn)[-1])
    except:
        print("No number found !")
        return 0


def import_dir(directory,format="gexf",numbered=True):
    """
    Based on a given directory, import all graphs and store them in a list/array

    Parameters
    ----------
    directory : str
        directory path where graphs are stored
    format : str
        graph file format
    numbered
        if graph filename are numbered
    Returns
    -------
    array
        graphs
    """
    if not os.path.exists(directory):
        raise FileNotFoundError("{0} does not exists".format(directory))
    if not format in methods_read_graph:
        raise NotImplementedError("{0} is not implemented !".format(format))

    # Retrieve filename
    fns = glob.glob(os.path.join(directory, "*.{0}".format(format)))

    graphs=[]
    if numbered:
        n=max([extract_index(fn) for fn in fns])
        graphs= [nx.Graph()]*(n+1)

    association_map, i = {}, 0
    for fn in tqdm(fns,desc="Loading Graphs from {0}".format(directory)):
        if not numbered:
            graphs.append(methods_read_graph[format](fn))
            association_map[fn]=i
            i+=1
        else:
            graphs[extract_index(fn)]=methods_read_graph[format](fn)
    if not numbered:
        return association_map,graphs
    return graphs
