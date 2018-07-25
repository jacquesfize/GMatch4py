# coding = utf-8

import numpy as np
cimport numpy as np
from .base cimport Base,intersection

cdef class VertexEdgeOverlap(Base):

    """
    Vertex/Edge Overlap Algorithm
    presented in Web graph similarity for anomaly detection, Journal of Internet Services and Applications, 2008
    by P. Papadimitriou, A. Dasdan and H.Gracia-Molina

    Code Author : Jacques Fize
    """
    def __init__(self):
            Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list listgs, list selected):
        n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        cdef list inter_ver,inter_ed
        cdef int denom,i,j
        for i in range(n):
            for j in range(i,n):
                g1,g2 = listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected)
                if f:
                    inter_g= intersection(g1,g2)
                    denom=g1.number_of_nodes()+g2.number_of_nodes()+\
                          g1.number_of_edges()+g2.number_of_edges()
                    if denom == 0:
                        continue
                    comparison_matrix[i,j]=(2*(inter_g.number_of_nodes()
                                              +inter_g.number_of_edges()))/denom # Data = True --> For nx.MultiDiGraph
                comparison_matrix[j, i] = comparison_matrix[i, j]
        return comparison_matrix



