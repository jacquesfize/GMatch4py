# coding = utf-8
import numpy as np
cimport numpy as np

from .base cimport Base

cdef class MCS(Base):
    """
    *A graph distance metric based on the maximal common subgraph, H. Bunke and K. Shearer,
    Pattern Recognition Letters, 1998*
    """
    def __init__(self):
        Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        for i in range(n):
            for j in range(i, n):
                g1,g2=listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected)
                if f:
                    comparison_matrix[i, j] = self.s_mcs(g1,g2)
                else:
                    comparison_matrix[i, j] = 0.
                comparison_matrix[j, i] = comparison_matrix[i, j]
        return comparison_matrix

    def s_mcs(self,G, H):
        """
        Return the MCS measure value between
        Parameters
        ----------
        G : networkx.Graph
            First Graph
        H : networkx.Graph
            Second Graph

        Returns
        -------

        """

        return len(self.mcs(G, H)) / float(max(len(G), len(H)))

