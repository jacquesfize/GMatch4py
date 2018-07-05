# coding = utf-8

import numpy as np

from .algorithm.graph_edit_dist import GraphEditDistance
from cython.parallel import prange

class ApproximateGraphEditDistance():
    __type__ = "dist"

    @staticmethod
    def compare(listgs,selected,c_del_node=1,c_del_edge=1,c_ins_node=1,c_ins_edge=1):
        cdef int n= len(listgs)
        cdef double[:,:] comparison_matrix = np.zeros((n,n))
        cdef int i,j
        for i in prange(n,nogil=True):
            for j in range(i,n):
                with gil:
                    f=True
                    if not listgs[i] or not listgs[j]:
                        f=False
                    elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                        f=False
                    if selected:
                        if not i in selected:
                            f=False

                    if f:
                        comparison_matrix[i][j] = GraphEditDistance(listgs[i],listgs[j],False,node_del=c_del_node,node_ins=c_ins_node,edge_del=c_del_edge,edge_ins=c_ins_edge).distance()
                    else:
                        comparison_matrix[i][j] = np.inf
                    comparison_matrix[j][i] = comparison_matrix[i][j]
        return comparison_matrix