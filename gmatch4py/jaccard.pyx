# coding = utf-8

import numpy as np
cimport numpy as np

from .base cimport Base
from .base cimport intersection,union_
from ..helpers.general import parsenx2graph
from cython.parallel cimport prange,parallel

cdef class Jaccard(Base):

    def __init__(self):
        Base.__init__(self,0,True)


    cpdef np.ndarray compare_old(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        cdef int i,j
        for i in range(n):
            for j in range(i,n):
                g1,g2=listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected)
                if f:
                    inter_g=intersection(g1,g2)
                    union_g=union_(g1,g2)
                    if union_g.number_of_nodes() == 0 or union_g.number_of_edges()== 0:
                        comparison_matrix[i, j] = 0.
                    else:
                        comparison_matrix[i,j]=\
                            ((inter_g.number_of_nodes())/(union_g.number_of_nodes()))\
                            *\
                            ((union_g.number_of_edges())/(union_g.number_of_edges()))
                else:
                    comparison_matrix[i, j] = 0.

                comparison_matrix[j, i] = comparison_matrix[i, j]

        return comparison_matrix

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef list new_gs=parsenx2graph(listgs)
        cdef double[:,:] comparison_matrix = np.zeros((n, n))
        cdef long[:] n_nodes = np.array([g.size() for g in new_gs])
        cdef long[:] n_edges = np.array([g.density() for g in new_gs])
        cdef int i,j

        cdef bint[:] selected_test = self.get_selected_array(selected,n)

        cdef double[:,:] intersect_len_nodes = np.zeros((n, n))
        cdef double[:,:] intersect_len_edges = np.zeros((n, n))
        cdef double[:,:] union_len_nodes = np.zeros((n, n))
        cdef double[:,:] union_len_edges = np.zeros((n, n))
        for i in range(n):
            for j in range(i,n):
                intersect_len_nodes[i][j]=new_gs[i].size_node_intersect(new_gs[j])
                intersect_len_edges[i][j]=new_gs[i].size_edge_intersect(new_gs[j])#len(set(hash_edges[i]).intersection(hash_edges[j]))
                union_len_nodes[i][j]=new_gs[i].size_node_union(new_gs[j])
                union_len_edges[i][j]=new_gs[i].size_node_union(new_gs[j])
        with nogil, parallel(num_threads=4):
            for i in prange(n,schedule='static'):
                for j in range(i,n):
                    if  n_nodes[i] > 0 and n_nodes[j] > 0  and selected_test[i]:
                        if union_len_edges[i][j] >0 and union_len_nodes[i][j] >0:
                            comparison_matrix[i][j]= \
                                (intersect_len_edges[i][j]/union_len_edges[i][j])*\
                                (intersect_len_nodes[i][j]/union_len_nodes[i][j])
                        
                        else:
                            comparison_matrix[i][j] = 0.

                    comparison_matrix[j][i] = comparison_matrix[i][j]

        return np.array(comparison_matrix)
