# coding = utf-8

import numpy as np
cimport numpy as np
import networkx as nx

cpdef np.ndarray minmax_scale(np.ndarray matrix):
    """
    Optimize so it can works with Cython
    :param matrix: 
    :return: 
    """
    cdef double min_,max_
    cdef np.ndarray x
    x=np.ma.masked_invalid(matrix)
    max_=np.max(x)
    return x/(max_)



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
    """
    Return a graph that contains nodes and edges from both graph G and H.
    
    Parameters
    ----------
    G : networkx.Graph
        First graph
    H : networkx.Graph 
        Second graph

    Returns
    -------
    networkx.Graph
        A new graph with the same type as G.
    """
    R = nx.create_empty_copy(G)
    R.add_nodes_from(H.nodes(data=True))
    R.add_edges_from(G.edges(data=True))
    R.add_edges_from(H.edges(data=True))
    return R

cdef class Base:
    """
    This class define the common methods to all Graph Matching algorithm.

    Attributes
    ----------
    type_alg : int
        Indicate the type of measure returned by the algorithm :

         * 0 : similarity
         * 1 : distance
    normalized : bool
        Indicate if the algorithm return normalized results (between 0 and 1)

    """
    def __cinit__(self):
        self.type_alg=0
        self.normalized=False

    def __init__(self,type_alg,normalized):
        """
        Constructor of Base

        Parameters
        ----------
        type_alg : int
            Indicate the type of measure returned by the algorithm :

             * **0** : similarity
             * **1** : distance
        normalized : bool
            Indicate if the algorithm return normalized results (between 0 and 1)
        """
        if type_alg <0:
            self.type_alg=0
        elif type_alg >1 :
            self.type_alg=1
        else:
            self.type_alg=type_alg
        self.normalized=normalized
    cpdef np.ndarray compare(self,list graph_list, list selected):
        """
        Return the similarity/distance matrix using the current algorithm.
        
        >>>Base.compare([nx.Graph(),nx.Graph()],None)
        >>>Base.compare([nx.Graph(),nx.Graph()],[0,1])
        
        Parameters
        ----------
        graph_list : networkx.Graph array
            Contains the graphs to compare
        selected : int array
            Sometimes, you only wants to compute similarity of some graphs to every graphs. If so, indicate their indices in
            `graph_list`, else, put the None value. 
            the None value
        Returns
        -------
        np.array
            distance/similarity matrix
            
        """
        pass

    cpdef np.ndarray distance(self, np.ndarray matrix):
        """
        Return a normalized distance matrix
        Parameters
        ----------
        matrix : np.array
            Similarity/distance matrix you want to transform

        Returns
        -------
        np.array
            distance matrix
        """
        if self.type_alg == 1:
            if not self.normalized:
                matrix=np.ma.getdata(minmax_scale(matrix))
            return matrix
        else:
            if not self.normalized:
                matrix=np.ma.getdata(minmax_scale(matrix))
            return 1-matrix

    cpdef np.ndarray similarity(self, np.ndarray matrix):
        """
        Return a normalized similarity matrix
        Parameters
        ----------
        matrix : np.array
            Similarity/distance matrix you want to transform

        Returns
        -------
        np.array
            similarity matrix
        """
        if self.type_alg == 0:
            return matrix
        else:
            if not self.normalized:
                matrix=np.ma.getdata(minmax_scale(matrix))
            return 1-matrix

    def mcs(self, G, H):
        """
        Return the Most Common Subgraph of
        Parameters
        ----------
        G : networkx.Graph
            First Graph
        H : networkx.Graph
            Second Graph

        Returns
        -------
        networkx.Graph
            Most common Subgrah
        """
        R=G.copy()
        R.remove_nodes_from(n for n in G if n not in H)
        return R

    cpdef bint isAccepted(self,G,index,selected):
        """
        Indicate if the graph will be compared to the other. A graph is "accepted" if :
            * G exists(!= None) and not empty (|vertices(G)| >0)
            * If selected graph to compare were indicated, check if G exists in selected
        
        Parameters
        ----------
        G : networkx.Graph
            Graph
        index : int
            index in the graph list parameter in `Base.compare()`
        selected : int array
            `selected` parameter value in `Base.compare()`

        Returns
        -------
        bool :
            if is accepted
        """
        f=True
        if not G:
            f=False
        elif len(G)== 0:
            f=False
        if selected:
            if not index in selected:
                f=False
        return f
