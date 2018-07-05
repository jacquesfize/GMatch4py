# coding = utf-8
import numpy as np

from .algorithm.graph_edit_dist import GraphEditDistance
cimport numpy as np

class GreedyEditDistance(GraphEditDistance):
    """
    Implementation of the Greedy Edit Distance presented in :

    Improved quadratic time approximation of graph edit distance by Hausdorff matching and greedy assignement
    Andreas Fischer, Kaspar Riesen, Horst Bunke
    2016
    """
    __type__ = "dist"
    @staticmethod
    def compare(listgs, selected, c_del_node=1, c_del_edge=1, c_ins_node=1, c_ins_edge=1):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        for i in range(n):
            for j in range(i, n):
                f=True
                if not listgs[i] or not listgs[j]:
                    f=False
                elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    comparison_matrix[i, j] = GreedyEditDistance(listgs[i], listgs[j],False, node_del=c_del_node,
                                                            node_ins=c_ins_node, edge_del=c_del_edge,
                                                            edge_ins=c_ins_edge).distance()
                else:
                    comparison_matrix[i, j] =  np.inf
                comparison_matrix[j, i] = comparison_matrix[i, j]


        return comparison_matrix

    def __init__(self,g1,g2,debug=False,**kwargs):
        """Constructor for GreedyEditDistance"""
        super().__init__(g1,g2,debug,**kwargs)


    def edit_costs(self):
        cdef np.ndarray cost_matrix=self.create_cost_matrix()
        cdef np.ndarray cost_matrix_2=cost_matrix.copy()
        cdef list psi=[]
        for i in range(len(cost_matrix)):
            phi_i=np.argmin((cost_matrix[i]))
            cost_matrix=np.delete(cost_matrix,phi_i,1)
            psi.append([i,phi_i+i]) #+i to compensate the previous column deletion
        return [cost_matrix_2[psi[i][0]][psi[i][1]] for i in range(len(psi))]

