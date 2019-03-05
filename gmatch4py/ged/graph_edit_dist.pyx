# -*- coding: UTF-8 -*-

import sys

import networkx as nx
import numpy as np
cimport numpy as np
from .abstract_graph_edit_dist cimport AbstractGraphEditDistance



cdef class GraphEditDistance(AbstractGraphEditDistance):

    def __init__(self,node_del,node_ins,edge_del,edge_ins,weighted=False):
        AbstractGraphEditDistance.__init__(self,node_del,node_ins,edge_del,edge_ins)
        self.weighted=weighted
        
    cpdef double substitute_cost(self, node1, node2, G, H):
        return self.relabel_cost(node1, node2, G, H)

    cpdef object relabel_cost(self, node1, node2, G, H):
        ## Si deux noeuds égaux
        if node1 == node2 and G.degree(node1) == H.degree(node2):
            return 0.0
        elif node1 == node2 and G.degree(node1) != H.degree(node2):
            #R = Graph(self.add_edges(node1,node2,G),G.get_node_key(),G.get_egde_key())
            #R2 = Graph(self.add_edges(node1,node2,H),H.get_node_key(),H.get_egde_key())
            #inter_= R.size_edge_intersect(R2)
            R=set(G.get_edges_no(node1))
            R2=set(H.get_edges_no(node2))
            inter_=R.intersection(R2)
            add_diff=abs(len(R2)-len(inter_))#abs(R2.density()-inter_)
            del_diff=abs(len(R)-len(inter_))#abs(R.density()-inter_)
            return (add_diff*self.edge_ins)+(del_diff*self.edge_del)


        #si deux noeuds connectés
        if  G.has_edge(node1,node2) or G.has_edge(node2,node1):
            return self.node_ins+self.node_del
        if not node2 in G.nodes():
            nodesH=H.nodes()
            index=list(nodesH).index(node2)
            return self.node_del+self.node_ins+self.insert_cost(index,index,nodesH,H)
        return sys.maxsize

    cdef double delete_cost(self, int i, int j, nodesG, G):
        if i == j:
            return self.node_del+(G.degree(nodesG[i],weight=True)*self.edge_del) # Deleting a node implicate to delete in and out edges
        return sys.maxsize

    cdef double insert_cost(self, int i, int j, nodesH, H):
        if i == j:
            deg=H.degree(nodesH[j],weight=True)
            if isinstance(deg,dict):deg=0
            return self.node_ins+(deg*self.edge_ins)
        else:
            return sys.maxsize