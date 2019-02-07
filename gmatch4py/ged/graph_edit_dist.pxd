import numpy as np
cimport numpy as np
from .abstract_graph_edit_dist cimport AbstractGraphEditDistance


cdef class GraphEditDistance(AbstractGraphEditDistance):
    cpdef object relabel_cost(self, node1, node2, G, H)
    cpdef double substitute_cost(self, node1, node2, G, H)
    cdef double delete_cost(self, int i, int j, nodesG, G)
    cdef double insert_cost(self, int i, int j, nodesH, H)