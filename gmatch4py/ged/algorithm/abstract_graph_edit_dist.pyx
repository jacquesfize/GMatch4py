# -*- coding: UTF-8 -*-
from __future__ import print_function

import sys

import numpy as np
from scipy.optimize import linear_sum_assignment
cimport numpy as np


class AbstractGraphEditDistance(object):


    def __init__(self, g1, g2,debug=False,**kwargs):
        self.g1 = g1
        self.g2 = g2
        self.debug=debug

        self.node_del = kwargs.get("node_del",1)
        self.node_ins = kwargs.get("node_ins",1)
        self.edge_del = kwargs.get("edge_del",1)
        self.edge_ins = kwargs.get("edge_ins",1)


    def distance(self):
        opt_path = self.edit_costs()
        if self.debug:
            print("Edit path for ",str(self.__class__.__name__),"\n",opt_path)
        return sum(opt_path)

    def print_operations(self,cost_matrix,row_ind,col_ind):
        cdef list nodes1 = list(self.g1.nodes)
        cdef list nodes2 = list(self.g2.nodes)
        dn1 = self.g1.nodes
        dn2 = self.g2.nodes

        cdef int n=len(nodes1)
        cdef int m=len(nodes2)
        cdef int x,y,i
        for i in range(len(row_ind)):
            y,x=row_ind[i],col_ind[i]
            val=cost_matrix[row_ind[i]][col_ind[i]]
            if x<m and y<n:
                print("SUB {0} to {1} cost = {2}".format(dn1[nodes1[y]]["label"],dn2[nodes2[x]]["label"],val))
            elif x <m and y>=n:
                print("ADD {0} cost = {1}".format(dn2[nodes2[y-n]]["label"],val))
            elif x>=m and y<n:
                print("DEL {0} cost = {1}".format(dn1[nodes1[m-x]]["label"],val))

    def edit_costs(self):
        cdef np.ndarray cost_matrix = self.create_cost_matrix()
        if self.debug:
            np.set_printoptions(precision=3)
            print("Cost Matrix for ",str(self.__class__.__name__),"\n",cost_matrix)

        row_ind,col_ind = linear_sum_assignment(cost_matrix)
        if self.debug:
            self.print_operations(cost_matrix,row_ind,col_ind)
        cdef int f=len(row_ind)
        return [cost_matrix[row_ind[i]][col_ind[i]] for i in range(f)]

    def create_cost_matrix(self):
        """
        Creates a |N+M| X |N+M| cost matrix between all nodes in
        graphs g1 and g2
        Each cost represents the cost of substituting,
        deleting or inserting a node
        The cost matrix consists of four regions:

        substitute 	| insert costs
        -------------------------------
        delete 		| delete -> delete

        The delete -> delete region is filled with zeros
        """
        cdef int n = len(self.g1)
        cdef int m = len(self.g2)
        cdef np.ndarray cost_matrix = np.zeros((n+m,n+m))
        #cost_matrix = [[0 for i in range(n + m)] for j in range(n + m)]
        cdef list nodes1 = list(self.g1.nodes)
        cdef list nodes2 = list(self.g2.nodes)
        cdef int i,j
        for i in range(n):
            for j in range(m):
                cost_matrix[i,j] = self.substitute_cost(nodes1[i], nodes2[j])

        for i in range(m):
            for j in range(m):
                cost_matrix[i+n,j] = self.insert_cost(i, j, nodes2)

        for i in range(n):
            for j in range(n):
                cost_matrix[j,i+m] = self.delete_cost(i, j, nodes1)

        self.cost_matrix = cost_matrix
        return cost_matrix

    def insert_cost(self, int i, int j):
        raise NotImplementedError

    def delete_cost(self, int i, int j):
        raise NotImplementedError

    def substitute_cost(self, nodes1, nodes2):
        raise NotImplementedError

    def print_matrix(self):
        print("cost matrix:")
        print(list(self.g1.nodes))
        print(list(self.g2.nodes))
        print(np.array(self.create_cost_matrix()))
        for column in self.create_cost_matrix():
            for row in column:
                if row == sys.maxsize:
                    print ("inf\t")
                else:
                    print ("%.2f\t" % float(row))
            print("")
