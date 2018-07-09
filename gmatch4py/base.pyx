# coding = utf-8

import numpy as np
cimport numpy as np

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
