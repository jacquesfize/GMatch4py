# coding = utf-8
import sys

from .graph_edit_dist cimport GraphEditDistance
import numpy as np
cimport numpy as np
from cython.parallel cimport prange,parallel

cdef class GreedyEditDistance(GraphEditDistance):
    """
    Implementation of the Greedy Edit Distance presented in :

    Improved quadratic time approximation of graph edit distance by Hausdorff matching and greedy assignement
    Andreas Fischer, Kaspar Riesen, Horst Bunke
    2016
    """

    def __init__(self,node_del,node_ins,edge_del,edge_ins):
        GraphEditDistance.__init__(self,node_del,node_ins,edge_del,edge_ins)


    cdef list edit_costs(self, G, H):
        cdef np.ndarray cost_matrix=self.create_cost_matrix(G,H)
        cdef np.ndarray cost_matrix_2=cost_matrix.copy().astype(np.double)
        cdef list psi=[]
        for i in range(len(cost_matrix)):
            phi_i=np.argmin(cost_matrix_2[i])
            cost_matrix_2[:,phi_i]=sys.maxsize
            psi.append([i,phi_i]) #+i to compensate the previous column deletion
        return [cost_matrix[psi[i][0]][psi[i][1]] for i in range(len(psi))]
