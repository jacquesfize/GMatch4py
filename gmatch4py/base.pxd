cimport numpy as np

cdef class Base:
    ## Attribute(s)
    cdef int type_alg
    cdef bint normalized
    cdef int cpu_count
    cdef str node_attr_key
    cdef str edge_attr_key
    ## Methods
    cpdef np.ndarray compare(self,list graph_list, list selected)
    cpdef np.ndarray compare_old(self,list listgs, list selected)
    cpdef np.ndarray distance(self, np.ndarray matrix)
    cpdef np.ndarray similarity(self, np.ndarray matrix)
    cpdef bint isAccepted(self,G,index,selected)
    cpdef np.ndarray get_selected_array(self,selected,size_corpus)

    cpdef set_attr_graph_used(self, str node_attr_key, str edge_attr_key)

