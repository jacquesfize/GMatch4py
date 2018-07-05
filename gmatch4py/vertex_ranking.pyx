# coding = utf-8

import networkx as nx
import numpy as np
cimport numpy as np
from scipy.stats import spearmanr


def intersect(a, b):
    return list(set(a) & set(b))

class VertexRanking():
    """
    Vertex Ranking
    presented in Web graph similarity for anomaly detection, Journal of Internet Services and Applications, 2008 # Maybe not ??
    by P. Papadimitriou, A. Dasdan and H.Gracia-Molina

    Code Author : Jacques Fize

    """
    __type__ = "sim"
    @staticmethod
    def  compare(listgs):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n,n))
        cdef list page_r=[nx.pagerank(nx.DiGraph(g)) for g in listgs]
        cdef list node_intersection
        cdef list X
        cdef list Y
        for i in range(n):
            for j in range(i,n):
                node_intersection=intersect(list(page_r[i].keys()),list(page_r[j].keys()))
                X,Y=[],[]
                for node in node_intersection:
                    X.append(page_r[i][node])
                    Y.append(page_r[j][node])
                comparison_matrix[i,j] = spearmanr(X,Y)[0]
                comparison_matrix[j,i] = comparison_matrix[i,j]
        return comparison_matrix
