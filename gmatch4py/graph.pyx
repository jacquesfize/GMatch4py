from libcpp.map cimport map
from libcpp.utility cimport pair
from libcpp.string  cimport string
from libcpp.vector  cimport vector
import numpy as np
cimport numpy as np
import networkx as nx

def fromNXGraph(G):
    G=nx.relabel_nodes(G,mapping={n:str(n)for n in G.nodes()},copy=True)
    nodes,n_attr=zip(*list(G.nodes(data=True)))
    e1,e2,e_attr=zip(*list(G.edges(data=True)))
    eds=list(zip(e1,e2))
    _,deg=zip(*list(G.degree))
    return Graph(list(nodes),eds,list(deg),list(deg),list(n_attr),list(e_attr))

def fromNXDigraph(G):
    G=nx.relabel_nodes(G,mapping={n:str(n)for n in G.nodes()},copy=True)
    nodes,n_attr=zip(*list(G.nodes(data=True)))
    e1,e2,e_attr=zip(*list(G.edges(data=True)))
    eds=list(zip(e1,e2))
    _,deg_in=zip(*list(G.in_degree))
    _,deg_out=zip(*list(G.out_degree))
    return Graph(list(nodes),eds,list(deg_in),list(deg_out),list(n_attr),list(e_attr),is_directed=True)

def fromNXMultiDigraph(G : networkx.MultiDiGraph):
    G=nx.relabel_nodes(G,mapping={n:str(n)for n in G.nodes()},copy=True)
    nodes,n_attr=zip(*list(G.nodes(data=True)))
    e1,e2,e_attr=zip(*list(G.edges(data=True)))
    eds=list(zip(e1,e2))
    _,deg_in=zip(*list(G.in_degree))
    _,deg_out=zip(*list(G.out_degree))
    return Graph(list(nodes),eds,list(deg_in),list(deg_out),list(n_attr),list(e_attr),is_directed=True)

cdef class Graph:

    cdef bint is_directed
    cdef bint is_multi

    cdef list nodes_list #id list 
    cdef list edges_list # edge list 
    cdef dict edge_hash_map #[id1,[id2,hash]] 
    cdef set edges_hash 
    cdef set nodes_set 
    
    cdef long number_of_nodes 
    cdef long number_of_edges 

    cdef list attr_nodes 
    cdef list attr_edges 

    cdef long[:] nodes_degree_in_all 
    cdef long[:] nodes_degree_out_all

    def __init__(self,nodes_list,edges_list,degree_in,degree_out,nodes_attr=[],edge_attr=[],is_directed=False,is_multi=False):
        self.is_directed = is_directed
        self.is_multi = is_multi
        
        self.nodes_list=nodes_list
        self.nodes_set=set(nodes_list)
        self.number_of_nodes=len(nodes_list)
        
        self.attr_nodes=nodes_attr
        self.attr_edges=edge_attr
        
        self.edges_list=edges_list
        self.edges_hash=set([])
        self.edge_hash_map = {}
        
        for x,y in edges_list:
            if not x in self.edge_hash_map:self.edge_hash_map[x]={}
            hash_=self.hash(x,y)
            self.edge_hash_map[x][y]=hash_
            self.edges_hash.add(hash_)
        
        self.number_of_edges = len(self.edges_list)
        self.number_of_nodes = len(self.nodes_list)
        
        self.nodes_degree_in_all=np.array(degree_in)
        self.nodes_degree_out_all=np.array([0]*self.number_of_nodes)
        if self.is_directed:
            self.nodes_degree_out_all=np.array(degree_out)
            

    
    cpdef str hash(self,str n1,str n2):
        return "_".join(sorted([n1,n2]))
    
    ## EXIST FUNCTION
    cdef bint has_node(self,str n_id):
        if n_id in self.nodes_list:
            return True
        return False

    cdef bint has_edge(self,str n_id1,str n_id2):
        if self.is_directed:
            if n_id1 in self.edge_hash_map and n_id2 in self.edge_hash_map[n_id1][n_id2]:
                return True
        else:
            if n_id1 in self.edge_hash_map and n_id2 in self.edge_hash_map[n_id1][n_id2]:
                return True
            if n_id2 in self.edge_hash_map and n_id1 in self.edge_hash_map[n_id2][n_id1]:
                return True
        return False
    
    cpdef int size_node_intersect(self,Graph G):
        return len(self.nodes_set.intersection(G.nodes_set))
    cpdef int size_node_union(self,Graph G):
        return len(self.nodes_set.union(G.nodes_set))
    
    cpdef int size_edge_intersect(self,Graph G):
        return len(self.edges_hash.intersection(G.edges_hash))
    cpdef int size_edge_union(self,Graph G):
        return len(self.edges_hash.union(G.edges_hash))

    def nodes(self,data=False):
        if data:
            return self.nodes_list,self.nodes_attr
        else:
            return self.nodes_list
        
    
    def edges(self,data=False):
        if data:
            return self.edges_list,self.edge_attr
        else:
            return self.edges_list

    cpdef get_edges_hash(self):
        return self.edges_hash

    cpdef size(self):
        return self.number_of_nodes

    cpdef density(self):
        return self.number_of_edges

    cpdef degree_in(self):
        return self.nodes_degree_in_all
    cpdef degree_out(self):
        return self.nodes_degree_out_all
    
    cpdef test(self):
        print(self.has_node("1"))
        print(self.has_edge("1","2"))
        G2=Graph(["1","2","3","4"],[("1","2"),("2","3"),("1","4")],[2,2,1],[2,2,1])
        print(self.size_node_union(G2))
        print(self.size_node_intersect(G2))
        print(self.size_edge_union(G2))
        print(self.size_edge_intersect(G2))

if __name__ == "__main__":
    G=Graph(["1","2","3"],[("1","2"),("2","3")],[1,2,1],[1,2,1])
    G.test()

