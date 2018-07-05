import sys

from .abstract_graph_edit_dist import AbstractGraphEditDistance


class EdgeEditDistance(AbstractGraphEditDistance):
    """
    Calculates the graph edit distance between two edges.
    A node in this context is interpreted as a graph,
    and edges are interpreted as nodes.
    """

    def __init__(self, g1, g2,**kwargs):
        AbstractGraphEditDistance.__init__(self, g1, g2,**kwargs)

    def insert_cost(self, int i, int j, nodes2):
        if i == j:
            return self.edge_ins
        return sys.maxsize

    def delete_cost(self, int i, int j, nodes1):
        if i == j:
            return self.edge_del
        return sys.maxsize

    def substitute_cost(self, edge1, edge2):
        if edge1 == edge2:
            return 0.
        return self.edge_del+self.edge_ins
