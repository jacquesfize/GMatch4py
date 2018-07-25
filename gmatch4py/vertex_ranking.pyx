# coding = utf-8

import networkx as nx
import numpy as np
cimport numpy as np
from scipy.stats import spearmanr

from .base cimport Base

cdef class VertexRanking(Base):
    """
    Vertex Ranking
    presented in Web graph similarity for anomaly detection, Journal of Internet Services and Applications, 2008 # Maybe not ??
    by P. Papadimitriou, A. Dasdan and H.Gracia-Molina

    Code Author : Jacques Fize

    """
    def __init__(self):
        Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n,i,j # number of graphs
        n = len(listgs)

        cdef np.ndarray comparison_matrix = np.zeros((n,n)) #similarity matrix
        cdef list X,Y,pager_i,pager_j,page_r,node_intersection #temp data (page rank data for the most part)
        page_r=[nx.pagerank(nx.DiGraph(g)) for g in listgs]
        for i in range(n):
            pager_i=list(page_r[i])
            for j in range(i,n):
                g1,g2=listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected)
                pager_j=list(page_r[j])
                node_intersection=list(set(pager_i) & set(pager_j))
                X,Y=[],[]
                for node in node_intersection:
                    X.append(page_r[i][node])
                    Y.append(page_r[j][node])
                comparison_matrix[i,j] = spearmanr(X,Y)[0]
                comparison_matrix[j,i] = comparison_matrix[i,j]
        return np.nan_to_num(comparison_matrix)
