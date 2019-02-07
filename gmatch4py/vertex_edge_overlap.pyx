# coding = utf-8

import numpy as np
cimport numpy as np
from .base cimport Base,intersection
from .graph cimport Graph
from cython.parallel cimport prange,parallel

cdef class VertexEdgeOverlap(Base):

    """
    Vertex/Edge Overlap Algorithm
    presented in Web graph similarity for anomaly detection, Journal of Internet Services and Applications, 2008
    by P. Papadimitriou, A. Dasdan and H.Gracia-Molina

    Code Author : Jacques Fize
    """
    def __init__(self):
            Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef list new_gs=[Graph(g) for g in listgs]
        cdef double[:,:] comparison_matrix = np.zeros((n, n))
        cdef list inter_ver,inter_ed
        cdef int denom,i,j
        cdef bint f
        cdef long[:] n_nodes = np.array([g.size() for g in new_gs])
        cdef long[:] n_edges = np.array([g.density() for g in new_gs])

        #print(type(test[0,0]))
        #cdef str[:,:] hash_edges = test
        cdef bint[:] selected_test

        cdef double[:,:] intersect_len_nodes = np.zeros((n, n))
        cdef double[:,:] intersect_len_edges = np.zeros((n, n))
        for i in range(n):
            for j in range(i,n):
                intersect_len_nodes[i][j]=new_gs[i].size_node_intersect(new_gs[j])
                intersect_len_edges[i][j]=new_gs[i].size_edge_intersect(new_gs[j])#len(set(hash_edges[i]).intersection(hash_edges[j]))
                
        with nogil, parallel(num_threads=4):
            for i in prange(n,schedule='static'):
                for j in range(i,n):
                    if  n_nodes[i] > 0 and n_nodes[j] > 0  :
                        denom=n_nodes[i]+n_nodes[j]+\
                              n_edges[i]+n_edges[j]
                        if denom == 0:
                            continue
                        comparison_matrix[i][j]=(2*(intersect_len_nodes[i][j]
                                                  +intersect_len_edges[i][j]))/denom # Data = True --> For nx.MultiDiGraph

                    comparison_matrix[i][j] = comparison_matrix[i][j]
        return np.array(comparison_matrix)



