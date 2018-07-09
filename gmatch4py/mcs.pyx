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
                f=True
                if not listgs[i] or not listgs[j]:
                    f=False
                elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    comparison_matrix[i, j] = self.s_mcs(listgs[i],listgs[j])
                else:
                    comparison_matrix[i, j] = 0.
                comparison_matrix[j, i] = comparison_matrix[i, j]
        return comparison_matrix

    def s_mcs(self,g1, g2):

        return len(self.mcs(g1, g2)) / float(max(len(g1), len(g2)))

