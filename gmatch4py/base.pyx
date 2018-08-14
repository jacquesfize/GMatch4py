# coding = utf-8

import numpy as np
cimport numpy as np
import networkx as nx

cdef np.ndarray minmax_scale(np.ndarray matrix):
    """
    Optimize so it can works with Cython
    :param matrix: 
    :return: 
    """
    cdef double min_,max_
    min_=np.min(matrix)
    max_=np.max(matrix)
    return matrix/(max_-min_)



cpdef intersection(G, H):
    """
    Return a new graph that contains only the edges and nodes that exist in
    both G and H.

    The node sets of H and G must be the same.

    Parameters
    ----------
    G,H : graph
       A NetworkX graph.  G and H must have the same node sets.

    Returns
    -------
    GH : A new graph with the same type as G.

    Notes
    -----
    Attributes from the graph, nodes, and edges are not copied to the new
    graph.  If you want a new graph of the intersection of G and H
    with the attributes (including edge data) from G use remove_nodes_from()
    as follows

    >>> G=nx.path_graph(3)
    >>> H=nx.path_graph(5)
    >>> R=G.copy()
    >>> R.remove_nodes_from(n for n in G if n not in H)

    Modified so it can be used with two graphs with different nodes set
    """
    # create new graph
    R = nx.create_empty_copy(G)

    if not G.is_multigraph() == H.is_multigraph():
        raise nx.NetworkXError('G and H must both be graphs or multigraphs.')
    if G.number_of_edges() <= H.number_of_edges():
        if G.is_multigraph():
            edges = G.edges(keys=True)
        else:
            edges = G.edges()
        for e in edges:
            if H.has_edge(*e):
                R.add_edge(*e)
    else:
        if H.is_multigraph():
            edges = H.edges(keys=True)
        else:
            edges = H.edges()
        for e in edges:
            if G.has_edge(*e):
                R.add_edge(*e)
    nodes_g=set(G.nodes())
    nodes_h=set(H.nodes())
    R.remove_nodes_from(list(nodes_g - nodes_h))
    return R

cpdef union_(G, H):
    R = nx.create_empty_copy(G)
    R.add_edges_from(G.edges(data=True))
    R.add_edges_from(G.edges(data=True))
    return R

cdef class Base:

    def __cinit__(self):
        self.type_alg=0
        self.normalized=False

    def __init__(self,type_alg,normalized):
        if type_alg <0:
            self.type_alg=0
        elif type_alg >1 :
            self.type_alg=1
        else:
            self.type_alg=type_alg
        self.normalized=normalized
    cpdef np.ndarray compare(self,list graph_list, list selected):
        pass

    cpdef np.ndarray distance(self, np.ndarray matrix):
        """
        Return the distance matrix between the graphs
        :return: np.ndarray
        """
        if self.type_alg == 1:
            if not self.normalized:
                matrix=minmax_scale(matrix)
            return matrix
        else:
            if not self.normalized:
                matrix=minmax_scale(matrix)
            return 1-matrix
    cpdef np.ndarray similarity(self, np.ndarray matrix):
        """
        Return a the similarity value between the graphs 
        :return: 
        """
        if self.type_alg == 0:
            return matrix
        else:
            if not self.normalized:
                matrix=minmax_scale(matrix)
            return 1-matrix

    def mcs(self,g1,g2):
        """
        Return the Most Common Subgraph
        :param g1: graph1
        :param g2: graph2
        :return: np.ndarray
        """
        R=g1.copy()
        R.remove_nodes_from(n for n in g1 if n not in g2)
        return R

    cpdef bint isAccepted(self,G,index,selected):
        f=True
        if not G:
            f=False
        elif len(G)== 0:
           f=False
        if selected:
            if not index in selected:
                f=False
        return f
