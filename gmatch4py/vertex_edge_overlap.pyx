# coding = utf-8

import numpy as np
cimport numpy as np


cdef list intersect(a, b):
    return list(set(a) & set(b))
class VertexEdgeOverlap():
    __type__ = "sim"

    """
    Vertex/Edge Overlap Algorithm
    presented in Web graph similarity for anomaly detection, Journal of Internet Services and Applications, 2008
    by P. Papadimitriou, A. Dasdan and H.Gracia-Molina

    Code Author : Jacques Fize
    """

    @staticmethod
    def compare(list listgs,selected):
        n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        cdef list inter_ver
        cdef list inter_ed
        cdef int denom
        for i in range(n):
            for j in range(i,n):
                f=True
                if not listgs[i] or not listgs[j]:
                    f=False
                elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    g1 = listgs[i]
                    g2 = listgs[j]
                    inter_ver,inter_ed = VertexEdgeOverlap.intersect_graph(g1,g2)
                    denom=len(g1)+len(g2)+len(g1.edges(data=True))+len(g2.edges(data=True))
                    if denom == 0:
                        continue
                    comparison_matrix[i,j]=2*(len(inter_ver)+len(inter_ed))/denom # Data = True --> For nx.MultiDiGraph
                else:
                    comparison_matrix[i, j] = 0.
                comparison_matrix[j, i] = comparison_matrix[i, j]
        return comparison_matrix


    @staticmethod
    def intersect_edges(g1,g2):
        cdef list ed1 = VertexEdgeOverlap.transform_edges(list(g1.edges(data=True)))
        cdef list ed2 = VertexEdgeOverlap.transform_edges(list(g2.edges(data=True)))
        cdef list inter_ed=[]
        for e1 in ed1:
            for e2 in ed2:
                if e1 == e2:
                    inter_ed.append(e1)
        return inter_ed


    @staticmethod
    def intersect_nodes(g1,g2):
        return intersect(list(g1.nodes),list(g2.nodes))

    @staticmethod
    def intersect_graph(g1,g2):
        return VertexEdgeOverlap.intersect_nodes(g1,g2),VertexEdgeOverlap.intersect_edges(g1,g2)

    @staticmethod
    def transform_edges(ed):
        for e in range(len(ed)):
            if "id" in ed[e][-1]:
                del ed[e][-1]["id"]
        return ed

