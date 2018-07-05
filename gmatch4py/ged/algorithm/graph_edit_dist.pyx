# -*- coding: UTF-8 -*-

import sys

import networkx as nx

from .abstract_graph_edit_dist import AbstractGraphEditDistance
from .edge_edit_dist import EdgeEditDistance
from ..graph.edge_graph import EdgeGraph


def compare(g1, g2, print_details=False):
    ged = GraphEditDistance(g1, g2,print_details)
    return ged.distance()


class GraphEditDistance(AbstractGraphEditDistance):

    def __init__(self, g1, g2,debug=False,**kwargs):
        AbstractGraphEditDistance.__init__(self, g1, g2,debug,**kwargs)

    def substitute_cost(self, node1, node2):
        return self.relabel_cost(node1, node2) + self.edge_diff(node1, node2)

    def relabel_cost(self, node1, node2):
        if node1 == node2:
            edges1=set(self.get_edge_multigraph(self.g1,node1))
            edges2=set(self.get_edge_multigraph(self.g2,node2))
            return abs(len(edges2.difference(edges1))) # Take in account if there is a different number of edges
        else:
            return self.node_ins+self.node_del

    def delete_cost(self, int i, int j, nodes1):
        if i == j:
            return self.node_del+self.g1.degree(nodes1[i]) # Deleting a node implicate to delete in and out edges
        return sys.maxsize

    def insert_cost(self, int i, int j, nodes2):
        if i == j:
            deg=self.g2.degree(nodes2[j])
            if isinstance(deg,dict):deg=0
            return self.node_ins+deg
        else:
            return sys.maxsize

    def get_edge_multigraph(self,g,node):
        cdef list edges=[]
        for id_,val in g.edges[node].items():
            if not 0 in val:
                edges.append(str(id_) + val["color"])
            else:
                for _,edge in val.items():
                    edges.append(str(id_)+edge["color"])
        return edges

    def edge_diff(self, node1, node2):
        cdef list edges1,edges2
        if isinstance(self.g1,nx.MultiDiGraph):
            edges1 = self.get_edge_multigraph(self.g1,node1)
            edges2 = self.get_edge_multigraph(self.g2,node2)
        else:
            edges1 = list(self.g1.edges[node1].keys())
            edges2 = list(self.g2.edges[node2].keys())
        if len(edges1) == 0 or len(edges2) == 0:
            return max(len(edges1), len(edges2))

        edit_edit_dist = EdgeEditDistance(
            EdgeGraph(node1,edges1),
            EdgeGraph(node2,edges2),
            edge_del=self.edge_del,edge_ins=self.edge_ins,node_ins=self.node_ins,node_del=self.node_del
        )
        return edit_edit_dist.distance()
