# coding = utf-8
import networkx as nx
import numpy as np
cimport numpy as np

class MCS():
    """
    *A graph distance metric based on the maximal common subgraph, H. Bunke and K. Shearer,
    Pattern Recognition Letters, 1998*
    """
    @staticmethod
    def compare(listgs,selected):
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
                    comparison_matrix[i, j] = MCS.s_mcs(listgs[i],listgs[j])
                else:
                    comparison_matrix[i, j] = 0.
                comparison_matrix[j, i] = comparison_matrix[i, j]
        return comparison_matrix


    @staticmethod
    def intersect(a, b):
        return list(set(a) & set(b))

    @staticmethod
    def transform_edges(ed):
        for e in range(len(ed)):
            if "id" in ed[e][-1]:
                del ed[e][-1]["id"]
        return ed


    @staticmethod
    def intersect_edges(g1, g2):
        cdef list ed1 = MCS.transform_edges(list(g1.edges(data=True)))
        cdef list ed2 = MCS.transform_edges(list(g2.edges(data=True)))
        inter_ed = []
        for e1 in ed1:
            for e2 in ed2:
                if e1 == e2:
                    inter_ed.append(e1)
        return inter_ed

    @staticmethod
    def intersect_nodes(g1, g2):
        return MCS.intersect(list(g1.nodes), list(g2.nodes))

    @staticmethod
    def maximum_common_subgraph(g1, g2):
        """
        Extract maximum common subgraph
        """
        res = nx.MultiDiGraph()
        res.add_nodes_from(MCS.intersect_nodes(g1, g2))
        res.add_edges_from(MCS.intersect_edges(g1, g2))
        return res

    @staticmethod
    def s_mcs(g1, g2):

        return len(MCS.maximum_common_subgraph(g1, g2)) / float(max(len(g1), len(g2)))

