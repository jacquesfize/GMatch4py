# -*- coding: UTF-8 -*-
from __future__ import print_function

import sys

import numpy as np
from scipy.optimize import linear_sum_assignment
cimport numpy as np
from ..base cimport Base

cdef class AbstractGraphEditDistance(Base):


    def __init__(self, node_del,node_ins,edge_del,edge_ins):
        Base.__init__(self,1,False)

        self.node_del = node_del
        self.node_ins = node_ins
        self.edge_del = edge_del
        self.edge_ins = edge_ins


    cpdef double distance_ged(self,G,H):
        """
        Return the distance between G and H
        :return: 
        """
        cdef list opt_path = self.edit_costs(G,H)
        return np.sum(opt_path)


    cdef list edit_costs(self, G, H):
        """
        Return the optimal path edit cost list, to transform G into H
        :return: 
        """
        cdef np.ndarray cost_matrix = self.create_cost_matrix(G,H).astype(float)
        row_ind,col_ind = linear_sum_assignment(cost_matrix)
        cdef int f=len(row_ind)
        return [cost_matrix[row_ind[i]][col_ind[i]] for i in range(f)]

    cpdef np.ndarray create_cost_matrix(self, G, H):
        """
        Creates a |N+M| X |N+M| cost matrix between all nodes in
        graphs G and H
        Each cost represents the cost of substituting,
        deleting or inserting a node
        The cost matrix consists of four regions:

        substitute 	| insert costs
        -------------------------------
        delete 		| delete -> delete

        The delete -> delete region is filled with zeros
        """
        cdef int n = G.number_of_nodes()
        cdef int m = H.number_of_nodes()
        cdef np.ndarray cost_matrix = np.zeros((n+m,n+m))
        cdef list nodes1 = list(G.nodes())
        cdef list nodes2 = list(H.nodes())
        cdef int i,j
        for i in range(n):
            for j in range(m):
                cost_matrix[i,j] = self.substitute_cost(nodes1[i], nodes2[j], G, H)

        for i in range(m):
            for j in range(m):
                cost_matrix[i+n,j] = self.insert_cost(i, j, nodes2, H)

        for i in range(n):
            for j in range(n):
                cost_matrix[j,i+m] = self.delete_cost(i, j, nodes1, G)

        return cost_matrix

    cdef double insert_cost(self, int i, int j, nodesH, H):
        raise NotImplementedError

    cdef double delete_cost(self, int i, int j, nodesG, G):
        raise NotImplementedError

    cpdef double substitute_cost(self, node1, node2, G, H):
        raise NotImplementedError

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n)).astype(float)
        cdef int i,j
        for i in range(n):
            for j in range(i, n):
                g1,g2=listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected)
                if f:
                    comparison_matrix[i, j] = self.distance_ged(g1, g2)
                else:
                    comparison_matrix[i, j] = np.inf
                comparison_matrix[j, i] = comparison_matrix[i, j]
        np.fill_diagonal(comparison_matrix,0)
        return comparison_matrix
