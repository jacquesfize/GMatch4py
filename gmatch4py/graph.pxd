cimport numpy as np

cdef class Graph:
    ##################################
    #            ATTRIBUTES
    ##################################

    # GRAPH PROPERTY ATTRIBUTES
    ###########################
    cdef bint is_directed # If the graph is directed
    cdef bint is_multi # If the graph is a Multi-Graph
    cdef bint is_node_attr
    cdef bint is_edge_attr

    # ATTR VAL ATTRIBUTES
    #####################
    cdef str node_attr_key # Key that contains the main attr value for a node
    cdef str edge_attr_key # Key that contains the main attr value for an edge
    cdef set unique_node_attr_vals # list 
    cdef set unique_edge_attr_vals # list 
    

    ## NODE ATTRIBUTES
    #################

    cdef list nodes_list # list of nodes ids
    cdef list nodes_attr_list # list of attr value for each node (following nodes list order)
    cdef list nodes_hash # hash representation of every node
    cdef set nodes_hash_set # hash representation of every node (set version for intersection and union operation)
    cdef dict nodes_idx # index of each node in `nodes_list`
    cdef list nodes_weight # list that contains each node's weight (following nodes_list order)
    cdef long[:] nodes_degree # degree list
    cdef long[:] nodes_degree_in # in degree list
    cdef long[:] nodes_degree_out # out degree list
    cdef double[:] nodes_degree_weighted #weighted vers. of nodes_degree
    cdef double[:] nodes_degree_in_weighted #weighted vers. of nodes_degree_in
    cdef double[:] nodes_degree_out_weighted #weighted vers. of nodes_degree_out
    cdef dict degree_per_attr # degree information per attr val
    cdef dict degree_per_attr_weighted # degree information per attr val
    cdef list attr_nodes # list of attr(dict) values for each node
    cdef dict edges_of_nodes # list of egdes connected to each node

    # EDGES ATTRIBUTES
    ##################
    
    cdef list edges_list # edge list
    cdef list edges_attr_list # list of attr value for each edge (following nodes list order)
    cdef dict edges_hash_idx # index of hash in edges_list and edges_attr_list
    cdef list edges_hash # hash representation of every edges ## A VOIR !
    cdef set edges_hash_set # set of hash representation of every edges (set version for intersection and union operation)
    cdef dict edges_weight # list that contains each node's weight (following nodes_list order)
    cdef dict edges_hash_map #[id1,[id2,hash]] 
    cdef list attr_edges # list of attr(dict) values for each edge 
    
    # SIZE ATTTRIBUTE
    ###############

    cdef long number_of_nodes  # number of nodes
    cdef long number_of_edges # number of edges

    cdef dict number_of_edges_per_attr # number of nodes per attr value
    cdef dict number_of_nodes_per_attr # number of edges per attr value

    cdef object nx_g

    ##################################
    #            METHODS
    ##################################

    # DIMENSION GETTER
    ##################
    cpdef long size(self)
    cpdef int size_attr(self, attr_val)

    cpdef long density(self)
    cpdef int density_attr(self, str attr_val)

    # HASH FUNCTION
    ###############
    cpdef str hash_node(self,str n1)
    cpdef str hash_edge(self,str n1,str n2)
    cpdef str hash_node_attr(self,str n1, str attr_value)
    cpdef str hash_edge_attr(self,str n1,str n2, str attr_value)
    
    ## EXIST FUNCTION
    ###############
    cpdef bint has_node(self,str n_id)
    cpdef bint has_edge(self,str n_id1,str n_id2)

    ## LEN FUNCTION
    ###############
    cpdef int size_node_intersect(self,Graph G)
    cpdef int size_node_union(self,Graph G)
    
    cpdef int size_edge_intersect(self,Graph G)
    cpdef int size_edge_union(self,Graph G)

    # DEGREE FUNCTION
    #################
    cpdef double degree(self,str n_id, bint weight=*)
    cpdef double in_degree(self,str n_id, bint weight=*)
    cpdef double out_degree(self,str n_id, bint weight=*)

    cpdef double in_degree_attr(self,str n_id,str attr_val, bint weight=*)
    cpdef double out_degree_attr(self,str n_id,str attr_val, bint weight=*)
    cpdef double degree_attr(self,str n_id,str attr_val, bint weight=*)

    ## GETTER
    #########

    cpdef list get_edges_ed(self,str e1, str e2)
    cpdef list get_edges_no(self,str n)
    cpdef set get_edges_hash(self)
    cpdef set get_nodes_hash(self)
    
    cpdef str get_node_key(self)
    cpdef str get_egde_key(self)

    cpdef dict get_edge_attrs(self,edge_hash)
    cpdef dict get_node_attrs(self, node_hash)
    cpdef dict get_node_attr(self, node_hash)
    cpdef dict get_edge_attr(self,edge_hash)