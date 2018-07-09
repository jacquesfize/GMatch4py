cimport numpy as np

cdef class Base:
    ## Attribute(s)
    cdef int type_alg
    cdef bint normalized

    ## Methods
    cpdef np.ndarray compare(self,list graph_list, list selected)
    cpdef np.ndarray distance(self, np.ndarray matrix)
    cpdef np.ndarray similarity(self, np.ndarray matrix)
    cpdef bint isAccepted(self,G,index,selected)

cpdef intersection(G,H)
cpdef union_(G,H)
