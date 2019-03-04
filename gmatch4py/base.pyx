# coding = utf-8

import numpy as np
cimport numpy as np
import networkx as nx
cimport cython
import multiprocessing



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

    def __init__(self,type_alg,normalized,node_attr_key="",edge_attr_key=""):
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
        self.cpu_count=multiprocessing.cpu_count()
        self.node_attr_key=node_attr_key
        self.edge_attr_key=edge_attr_key

    cpdef set_attr_graph_used(self, str node_attr_key, str edge_attr_key):
        """
        Set graph attribute used by the algorithm to compare graphs.
        Parameters
        ----------
        node_attr_key : str
            key of the node attribute
        edge_attr_key: str
            key of the edge attribute

        """
        self.node_attr_key=node_attr_key
        self.edge_attr_key=edge_attr_key
    
    cpdef np.ndarray get_selected_array(self,selected,size_corpus):
        """
        Return an array which define which graph will be compared in the algorithms.
        Parameters
        ----------
        selected : list
            indices of graphs you wish to compare
        size_corpus : 
            size of your dataset

        Returns
        -------
        np.ndarray
            selected vector (1 -> selected, 0 -> not selected)
        """
        cdef double[:] selected_test = np.zeros(size_corpus)
        if not selected == None:
            for ix in range(len(selected)):
                selected_test[selected[ix]]=1
            return np.array(selected_test)
        else:
            return np.array(selected_test)+1
        

    cpdef np.ndarray compare_old(self,list listgs, list selected):
        """
        Soon will be depreciated ! To store the old version of an algorithm.
        Parameters
        ----------
        listgs : list
            list of graphs
        selected
            selected graphs

        Returns
        -------
        np.ndarray
            distance/similarity matrix
        """
        pass

    @cython.boundscheck(False) 
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
        np.ndarray
            distance/similarity matrix
            
        """
        pass

    cpdef np.ndarray distance(self, np.ndarray matrix):
        """
        Return a normalized distance matrix
        Parameters
        ----------
        matrix : np.ndarray
            Similarity/distance matrix you wish to transform

        Returns
        -------
        np.ndarray
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
        matrix : np.ndarray
            Similarity/distance matrix you wish to transform

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
