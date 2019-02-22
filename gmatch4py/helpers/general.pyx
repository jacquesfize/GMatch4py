from ..graph cimport Graph
import networkx as nx

def parsenx2graph(list_gs,node_attr_key="",edge_attr_key=""):
    new_gs=[nx.relabel_nodes(g,{node:str(node) for node in list(g.nodes)},copy=True) for g in list_gs]
    new_gs=[Graph(g,node_attr_key,edge_attr_key) for g in new_gs]
    return new_gs
