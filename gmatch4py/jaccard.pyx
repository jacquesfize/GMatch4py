# coding = utf-8

import numpy as np
cimport numpy as np

from .base cimport Base
from .helpers.general import parsenx2graph
from cython.parallel cimport prange,parallel
cimport cython

cdef class Jaccard(Base):

    def __init__(self):
        Base.__init__(self,0,True)


    @cython.boundscheck(False)
    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef list new_gs=parsenx2graph(listgs,self.node_attr_key,self.edge_attr_key)
        cdef double[:,:] comparison_matrix = np.zeros((n, n))
        cdef long[:] n_nodes = np.array([g.size() for g in new_gs])
        cdef long[:] n_edges = np.array([g.density() for g in new_gs])
        cdef int i,j

        cdef double[:] selected_test = np.array(self.get_selected_array(selected,n))

        cdef double[:,:] intersect_len_nodes = np.zeros((n, n))
        cdef double[:,:] intersect_len_edges = np.zeros((n, n))
        cdef double[:,:] union_len_nodes = np.zeros((n, n))
        cdef double[:,:] union_len_edges = np.zeros((n, n))
        for i in range(n):
            for j in range(i,n):
                intersect_len_nodes[i][j]=new_gs[i].size_node_intersect(new_gs[j])
                intersect_len_edges[i][j]=new_gs[i].size_edge_intersect(new_gs[j])#len(set(hash_edges[i]).intersection(hash_edges[j]))
                union_len_nodes[i][j]=new_gs[i].size_node_union(new_gs[j])
                union_len_edges[i][j]=new_gs[i].size_edge_union(new_gs[j])
        with nogil, parallel(num_threads=self.cpu_count):
            for i in prange(n,schedule='static'):
                for j in range(i,n):
                    if  n_nodes[i] > 0 and n_nodes[j] > 0  and selected_test[i] == 1:
                        if union_len_edges[i][j] >0 and union_len_nodes[i][j] >0:
                            comparison_matrix[i][j]= \
                                (intersect_len_edges[i][j]/union_len_edges[i][j])*\
                                (intersect_len_nodes[i][j]/union_len_nodes[i][j])
                        
                        else:
                            comparison_matrix[i][j] = 0.

                        comparison_matrix[j][i] = comparison_matrix[i][j]

        return np.array(comparison_matrix)
