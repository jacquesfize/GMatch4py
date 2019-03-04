# coding = utf-8

"""
Shortest-Path graph kernel.
Python implementation based on: "Shortest-path kernels on graphs", by
Borgwardt, K.M.; Kriegel, H.-P., in Data Mining, Fifth IEEE
International Conference on , vol., no., pp.8 pp.-, 27-30 Nov. 2005
doi: 10.1109/ICDM.2005.132
Author : Sandro Vega-Pons, Emanuele Olivetti
Modified by : Jacques Fize
"""

import networkx as nx
import numpy as np
cimport numpy as np
from scipy.sparse.csgraph import floyd_warshall
from .adjacency import get_adjacency
from cython.parallel cimport prange,parallel
from ..helpers.general import parsenx2graph
from ..base cimport Base
cimport cython

cdef class ShortestPathGraphKernel(Base):
    """
    Shorthest path graph kernel.
    """
    def __init__(self):
        Base.__init__(self,0,False)
    
    def compare_two(self,g_1, g_2):
        """Compute the kernel value (similarity) between two graphs.
        Parameters
        ----------
        g1 : networkx.Graph
            First graph.
        g2 : networkx.Graph
            Second graph.
        Returns
        -------
        k : The similarity value between g1 and g2.
        """
        # Diagonal superior matrix of the floyd warshall shortest
        # paths:
        if isinstance(g_1,nx.Graph) and isinstance(g_2,nx.Graph):
            g_1,g_2= get_adjacency(g_1,g_2)

        fwm1 = np.array(floyd_warshall(g_1))
        fwm1[np.isinf(fwm1)] = 0
        fwm1[np.isnan(fwm1)] = 0 
        fwm1 = np.triu(fwm1, k=1)
        bc1 = np.bincount(fwm1.reshape(-1).astype(int))

        fwm2 = np.array(floyd_warshall(g_2))
        fwm2[np.isinf(fwm2)] = 0
        fwm2[np.isnan(fwm2)] = 0 
        fwm2 = np.triu(fwm2, k=1)
        bc2 = np.bincount(fwm2.reshape(-1).astype(int))

        # Copy into arrays with the same length the non-zero shortests
        # paths:
        v1 = np.zeros(max(len(bc1), len(bc2)) - 1)
        v1[range(0, len(bc1)-1)] = bc1[1:]

        v2 = np.zeros(max(len(bc1), len(bc2)) - 1)
        v2[range(0, len(bc2)-1)] = bc2[1:]

        return np.sum(v1 * v2)

    @cython.boundscheck(False)
    cpdef np.ndarray compare(self,list graph_list, list selected):
        """Compute the all-pairs kernel values for a list of graphs.
        This function can be used to directly compute the kernel
        matrix for a list of graphs. The direct computation of the
        kernel matrix is faster than the computation of all individual
        pairwise kernel values.
        Parameters
        ----------
        graph_list: list
            A list of graphs (list of networkx graphs)
        Return
        ------
        K: numpy.array, shape = (len(graph_list), len(graph_list))
        The similarity matrix of all graphs in graph_list.
        """
        cdef int n = len(graph_list)
        cdef double[:,:] k = np.zeros((n, n))
        cdef int cpu_count = self.cpu_count
        cdef int i,j
        cdef list adjacency_matrices = [[None for i in range(n)]for j in range(n)]
        
        for i in range(n):
            for j in range(i, n):
                adjacency_matrices[i][j] = get_adjacency(graph_list[i],graph_list[j])
                adjacency_matrices[j][i] = adjacency_matrices[i][j]
        
        with nogil, parallel(num_threads=cpu_count):
            for i in prange(n,schedule='static'):
                for j in range(i, n):
                    with gil:
                        if len(graph_list[i]) > 0 and len(graph_list[j]) >0: 
                            a,b=adjacency_matrices[i][j]
                            k[i][j] = self.compare_two(a,b)
                    k[j][i] = k[i][j]

        k_norm = np.zeros((n,n))
        for i in range(n):
            for j in range(i,n):
                k_norm[i, j] = k[i][j] / np.sqrt(k[i][i] * k[j][j])
                k_norm[j, i] = k_norm[i, j]

        return np.nan_to_num(k_norm)


    
cdef class ShortestPathGraphKernelDotCostMatrix(ShortestPathGraphKernel):
    """
    Instead of just multiply the count of distance values fou,d between nodes of each graph, this version propose to multiply the node distance matrix generated from each graph.
    """
    def __init__(self):
        ShortestPathGraphKernel.__init__(self)
    
    def compare_two(self,g_1, g_2):
        """Compute the kernel value (similarity) between two graphs.
        Parameters
        ----------
        g1 : networkx.Graph
            First graph.
        g2 : networkx.Graph
            Second graph.
        Returns
        -------
        k : The similarity value between g1 and g2.
        """
        # Diagonal superior matrix of the floyd warshall shortest
        # paths:
        if isinstance(g_1,nx.Graph) and isinstance(g_2,nx.Graph):
            g_1,g_2= get_adjacency(g_1,g_2)

        fwm1 = np.array(floyd_warshall(g_1))
        fwm1[np.isinf(fwm1)] = 0
        fwm1[np.isnan(fwm1)] = 0 
        fwm1 = np.triu(fwm1, k=1)

        fwm2 = np.array(floyd_warshall(g_2))
        fwm2[np.isinf(fwm2)] = 0
        fwm2[np.isnan(fwm2)] = 0 
        fwm2 = np.triu(fwm2, k=1)
        
        return np.sum(fwm1 * fwm2)