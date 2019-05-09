# -*- coding: UTF-8 -*-
from __future__ import print_function

import sys
import warnings

import numpy as np
cimport numpy as np
import networkx as nx
from cython.parallel cimport prange,parallel

try:
    from munkres import munkres
except ImportError:
    warnings.warn("To obtain optimal results install the Cython 'munkres' module at  https://github.com/jfrelinger/cython-munkres-wrapper")
    from scipy.optimize import linear_sum_assignment as munkres

from ..base cimport Base
from ..helpers.general import parsenx2graph



cdef class AbstractGraphEditDistance(Base):


    def __init__(self, node_del,node_ins,edge_del,edge_ins):
        Base.__init__(self,1,False)

        self.node_del = node_del
        self.node_ins = node_ins
        self.edge_del = edge_del
        self.edge_ins = edge_ins


    cpdef double distance_ged(self,G,H):
        """
        Return the distance value between G and H
        
        Parameters
        ----------
        G : gmatch4py.Graph
            graph
        H : gmatch4py.Graph
            graph
        
        Returns
        -------
        int 
            distance
        """
        cdef list opt_path = self.edit_costs(G,H)
        return np.sum(opt_path)

    def edit_path(self,G,H):
        """
        Return  the edit path along with the cost matrix and the selected indices from the Munkres Algorithm
        
        Parameters
        ----------
        G : nx.Graph
            first graph
        H : nx.Graph
            second graph
        
        Returns
        -------
        np.array(1D), np.array(2D), (np.array(2D) if munkres) or (np.array(1,2) if scipy) 
            edit_path, cost_matrix, munkres results
        """
        cost_matrix = self.create_cost_matrix(G,H).astype(float)
        index_path= munkres(cost_matrix)
        return cost_matrix[index_path], cost_matrix, index_path
    

    cdef list edit_costs(self, G, H):
        """
        Return the optimal path edit cost list, to transform G into H
        
        Parameters
        ----------
        G : gmatch4py.Graph
            graph
        H : gmatch4py.Graph
            graph
        
        Returns
        -------
        np.array 
            edit path
        """
        cdef np.ndarray cost_matrix = self.create_cost_matrix(G,H).astype(float)
        return cost_matrix[munkres(cost_matrix)].tolist()

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
        
        Parameters
        ----------
        G : gmatch4py.Graph
            graph
        H : gmatch4py.Graph
            graph
        
        Returns
        -------
        np.array 
            cost matrix
        """
        cdef int n,m
        try:
            n = G.number_of_nodes()
            m = H.number_of_nodes()
        except:
            n = G.size()
            m = H.size()
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
        """
        Return the insert cost of the ith nodes in H
        
        Returns
        -------
        int
            insert cost
        """
        raise NotImplementedError

    cdef double delete_cost(self, int i, int j, nodesG, G):
        """
        Return the delete cost of the ith nodes in H
        
        Returns
        -------
        int
            delete cost
        """
        raise NotImplementedError

    cpdef double substitute_cost(self, node1, node2, G, H):
        """
        Return the substitute cost of between the node1 in G and the node2 in H
        
        Returns
        -------
        int
            substitution cost
        """
        raise NotImplementedError


    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef double[:,:] comparison_matrix = np.zeros((n, n))
        listgs=parsenx2graph(listgs,self.node_attr_key,self.edge_attr_key)
        cdef long[:] n_nodes = np.array([g.size() for g in listgs])
        cdef double[:] selected_test = np.array(self.get_selected_array(selected,n))
        cdef int i,j
        cdef float inf=np.inf

        with nogil, parallel(num_threads=self.cpu_count):
            for i in prange(n,schedule='static'):
                for j in range(n):
                    if n_nodes[i]>0 and n_nodes[j]>0 and selected_test[i] == 1 :
                        with gil:
                            comparison_matrix[i][j] = self.distance_ged(listgs[i],listgs[j])
                    else:
                        comparison_matrix[i][j] = inf
                #comparison_matrix[j, i] = comparison_matrix[i, j]
        return np.array(comparison_matrix)
