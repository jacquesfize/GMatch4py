import numpy as np
cimport numpy as np
from ..base cimport Base

cdef class AbstractGraphEditDistance(Base):
    cdef double node_del
    cdef double node_ins
    cdef double edge_del
    cdef double edge_ins
    cdef np.ndarray cost_matrix
    cdef bint weighted

    cpdef double distance_ged(self,G,H)
    cdef list edit_costs(self,G,H)
    cpdef np.ndarray create_cost_matrix(self,G,H)
    cdef double insert_cost(self, int i, int j, nodesH, H)
    cdef double delete_cost(self, int i, int j, nodesG, G)
    cpdef double substitute_cost(self, node1, node2, G, H)
    
