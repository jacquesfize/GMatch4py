# coding = utf-8

import numpy as np
cimport numpy as np

from .base cimport Base
from .base cimport intersection,union_


cdef class Jaccard(Base):

    def __init__(self):
        Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list listgs, list selected):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        cdef int i,j
        for i in range(n):
            for j in range(i,n):
                g1,g2=listgs[i],listgs[j]
                f=self.isAccepted(g1,i,selected) & self.isAccepted(g2,j,selected)
                if f:
                    inter_g=intersection(g1,g2)
                    union_g=union_(g1,g2)
                    if union_g.number_of_nodes() == 0 or union_g.number_of_edges()== 0:
                        comparison_matrix[i, j] = 0.
                    else:
                        comparison_matrix[i,j]=\
                            ((inter_g.number_of_nodes())/(union_g.number_of_nodes()))\
                            *\
                            ((union_g.number_of_edges())/(union_g.number_of_edges()))
                else:
                    comparison_matrix[i, j] = 0.

                comparison_matrix[j, i] = comparison_matrix[i, j]

        return comparison_matrix



