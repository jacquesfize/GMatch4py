# -*- coding: UTF-8 -*-

import sys

import networkx as nx
import numpy as np
cimport numpy as np
from .abstract_graph_edit_dist cimport AbstractGraphEditDistance
from ..base cimport intersection,union_


cdef class GraphEditDistance(AbstractGraphEditDistance):

    def __init__(self,node_del,node_ins,edge_del,edge_ins):
        AbstractGraphEditDistance.__init__(self,node_del,node_ins,edge_del,edge_ins)

    cpdef double substitute_cost(self, node1, node2, G, H):
        return self.relabel_cost(node1, node2, G, H)

    def add_edges(self,node1,node2,G):
        R=nx.create_empty_copy(G)
        try:
            R.add_edges_from(G.edges(node1,node2))
        except:
            pass
        return R

    def relabel_cost(self, node1, node2, G, H):
        ## Si deux noeuds égaux
        if node1 == node2 and G.degree(node1) == H.degree(node2):
            return 0.0
        elif node1 == node2 and G.degree(node1) != H.degree(node2):
            R = self.add_edges(node1,node2,G)
            R2 = self.add_edges(node1,node2,H)
            inter_=intersection(R,R2).number_of_edges()
            add_diff=abs(R2.number_of_edges()-inter_)
            del_diff=abs(R.number_of_edges()-inter_)
            return (add_diff*self.edge_ins)+(del_diff*self.edge_del)


        #si deux noeuds connectés
        if (node1,node2) in G.edges() or (node2,node1) in G.edges():
            return self.node_ins+self.node_del
        if not node2 in G:
            nodesH=list(H.nodes())
            index=nodesH.index(node2)
            return self.node_del+self.node_ins+self.insert_cost(index,index,nodesH,H)
        return sys.maxsize

    cdef double delete_cost(self, int i, int j, nodesG, G):
        if i == j:
            return self.node_del+(G.degree(nodesG[i])*self.edge_del) # Deleting a node implicate to delete in and out edges
        return sys.maxsize

    cdef double insert_cost(self, int i, int j, nodesH, H):
        if i == j:
            deg=H.degree(nodesH[j])
            if isinstance(deg,dict):deg=0
            return self.node_ins+(deg*self.edge_ins)
        else:
            return sys.maxsize