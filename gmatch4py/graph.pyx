from libcpp.map cimport map
from libcpp.utility cimport pair
from libcpp.string  cimport string
from libcpp.vector  cimport vector
import numpy as np
cimport numpy as np
import networkx as nx

cdef class Graph:

    def __init__(self,G, node_attr_key="",edge_attr_key=""):
        self.nx_g=G

        #GRAPH PROPERTY INIT
        self.is_directed = G.is_directed()
        self.is_multi = G.is_multigraph()
        self.is_node_attr=(True if node_attr_key else False)
        self.is_edge_attr=(True if edge_attr_key else False)
        if self.is_multi and not self.is_edge_attr:
            if not len(nx.get_edge_attributes(G,"id")) == len(G.edges(data=True)):
                i=0
                for id1 in G.adj:
                    for id2 in G.adj[id1]:
                        for id3 in G.adj[id1][id2]:
                            G._adj[id1][id2][id3]["id"]=str(i)
                            i+=1
            self.is_edge_attr = True
            edge_attr_key = "id"  
            
        #    for ed in 

        #len(nx.get_edge_attributes(G1,"id")) == len(G1.edges(data=True))

        if len(G) ==0:
            self.__init_empty__()    

        else:
            a,b=list(zip(*list(G.nodes(data=True))))
            self.nodes_list,self.attr_nodes=list(a),list(b)
            if G.number_of_edges()>0:
                e1,e2,d=zip(*list(G.edges(data=True)))
                self.attr_edges=list(d)
                self.edges_list=list(zip(e1,e2))
            else:
                self.edges_list=[]
                self.attr_edges=[]

            if self.is_node_attr:
                self.node_attr_key = node_attr_key
                self.nodes_attr_list = [attr_dict[node_attr_key] for attr_dict in self.attr_nodes]
                self.unique_node_attr_vals=set(self.nodes_attr_list)
            
            if self.is_edge_attr:
                self.edge_attr_key = edge_attr_key
                self.edges_attr_list = [attr_dict[edge_attr_key] for attr_dict in self.attr_edges]
                self.unique_edge_attr_vals=set(self.edges_attr_list)

            # NODE Information init
            #######################
            
            self.nodes_hash=[self.hash_node_attr(node,self.nodes_attr_list[ix]) if self.is_node_attr else self.hash_node(node) for ix, node in enumerate(self.nodes_list) ]
            self.nodes_hash_set=set(self.nodes_hash)
            self.nodes_idx={node:ix for ix, node in enumerate(self.nodes_list)}
            self.nodes_weight=[attr_dict["weight"] if "weight" in attr_dict else 1 for attr_dict in self.attr_nodes]
            degree_all=[]
            degree_in=[]
            degree_out=[]

            degree_all_weighted=[]
            degree_in_weighted=[]
            degree_out_weighted=[]
            if self.is_edge_attr:
                self.degree_per_attr={attr_v:{n:{"in":0,"out":0} for n in self.nodes_list} for attr_v in self.unique_edge_attr_vals}
                self.degree_per_attr_weighted={attr_v:{n:{"in":0,"out":0} for n in self.nodes_list} for attr_v in self.unique_edge_attr_vals}
            # Retrieving Degree Information
            self.edges_of_nodes={}
            for n in self.nodes_list:
                self.edges_of_nodes[n]=[self.hash_edge_attr(e1,e2,attr_dict[self.edge_attr_key]) if self.is_edge_attr else self.hash_edge(e1,e2) for e1,e2,attr_dict in G.edges(n,data=True)]
                degree_all.append(G.degree(n))
                degree_all_weighted.append(G.degree(n,weight="weight"))
                if self.is_directed:
                    degree_in.append(G.in_degree(n))
                    degree_in_weighted.append(G.in_degree(n,weight="weight"))
                    degree_out.append(G.out_degree(n))
                    degree_out_weighted.append(G.out_degree(n))
                else:
                    degree_in.append(degree_all[-1])
                    degree_in_weighted.append(degree_all_weighted[-1])
                    degree_out.append(degree_all[-1])
                    degree_out_weighted.append(degree_all_weighted[-1])
                if self.is_edge_attr:
                    if self.is_directed:
                        in_edge=list(G.in_edges(n,data=True))
                        out_edge=list(G.out_edges(n,data=True))
                        for n1,n2,attr_dict in in_edge:
                            self.degree_per_attr[attr_dict[self.edge_attr_key]][n]["in"]+=1
                            self.degree_per_attr_weighted[attr_dict[self.edge_attr_key]][n]["in"]+=1*(attr_dict["weight"] if "weight" in attr_dict else 1 )
            
                        for n1,n2,attr_dict in out_edge:
                            self.degree_per_attr[attr_dict[self.edge_attr_key]][n]["out"]+=1
                            self.degree_per_attr_weighted[attr_dict[self.edge_attr_key]][n]["out"]+=1*(attr_dict["weight"] if "weight" in attr_dict else 1 )
        
                    else:
                        edges=G.edges(n,data=True)
                        for n1,n2,attr_dict in edges:
                            self.degree_per_attr[attr_dict[self.edge_attr_key]][n]["in"]+=1
                            self.degree_per_attr[attr_dict[self.edge_attr_key]][n]["out"]+=1
                            self.degree_per_attr_weighted[attr_dict[self.edge_attr_key]][n]["in"]+=1*(attr_dict["weight"] if "weight" in attr_dict else 1 )
                            self.degree_per_attr_weighted[attr_dict[self.edge_attr_key]][n]["out"]+=1*(attr_dict["weight"] if "weight" in attr_dict else 1 )
            
            self.nodes_degree=np.array(degree_all)
            self.nodes_degree_in=np.array(degree_in)
            self.nodes_degree_out=np.array(degree_out)

            self.nodes_degree_weighted=np.array(degree_all_weighted).astype(np.double)
            self.nodes_degree_in_weighted=np.array(degree_in_weighted).astype(np.double)
            self.nodes_degree_out_weighted=np.array(degree_out_weighted).astype(np.double)


            # EDGE INFO INIT
            #################
            
            self.edges_hash=[]
            self.edges_hash_map = {}
            self.edges_hash_idx = {}
            for ix, ed in enumerate(self.edges_list):
                e1,e2=ed
                if not e1 in self.edges_hash_map:self.edges_hash_map[e1]={}
                
                hash_=self.hash_edge_attr(e1,e2,self.edges_attr_list[ix]) if self.is_edge_attr else self.hash_edge(e1,e2)
                if self.is_multi and self.is_edge_attr:
                    if not e2 in self.edges_hash_map[e1]:self.edges_hash_map[e1][e2]={}
                    self.edges_hash_map[e1][e2][self.edges_attr_list[ix]]=hash_
                else:
                    self.edges_hash_map[e1][e2]=hash_
                self.edges_hash_idx[hash_]=ix 
                self.edges_hash.append(hash_) 
            self.edges_hash_set=set(self.edges_hash)

            self.edges_weight={}
            for e1,e2,attr_dict in list(G.edges(data=True)):
                hash_=self.hash_edge_attr(e1,e2,attr_dict[self.edge_attr_key]) if self.is_edge_attr else self.hash_edge(e1,e2)
                self.edges_weight[hash_]=attr_dict["weight"] if "weight" in attr_dict else 1 
            
            self.number_of_edges = len(self.edges_list)
            self.number_of_nodes = len(self.nodes_list)
            
            if self.is_edge_attr and self.number_of_edges >0:
                self.number_of_edges_per_attr={attr:0 for attr in self.unique_edge_attr_vals}
                for _,_,attr_dict in list(G.edges(data=True)):
                    self.number_of_edges_per_attr[attr_dict[self.edge_attr_key]]+=1
            
            if self.is_node_attr and self.number_of_nodes >0:
                self.number_of_nodes_per_attr={attr:0 for attr in self.unique_node_attr_vals}
                for _,attr_dict in list(G.nodes(data=True)):
                    self.number_of_nodes_per_attr[attr_dict[self.node_attr_key]]+=1

    
    # HASH FUNCTION
    cpdef str hash_node(self,str n1):
        return "{0}".format(n1)

    cpdef str hash_edge(self,str n1,str n2):
        if not self.is_directed:
            return "_".join(sorted([n1,n2]))
        return "_".join([n1,n2])

    cpdef str hash_node_attr(self,str n1, str attr_value):
        return "_".join([n1,attr_value])

    cpdef str hash_edge_attr(self,str n1,str n2, str attr_value):
        if self.is_directed:
            return "_".join([n1,n2,attr_value])
        ed=sorted([n1,n2])
        ed.extend([attr_value])
        return "_".join(ed)
    
    ## EXIST FUNCTION
    cpdef bint has_node(self,str n_id):
        if n_id in self.nodes_list:
            return True
        return False

    cpdef bint has_edge(self,str n_id1,str n_id2):
        if self.number_of_edges == 0:
            return False
        if self.is_directed:
            if n_id1 in self.edges_hash_map and n_id2 in self.edges_hash_map[n_id1]:
                return True
        else:
            if n_id1 in self.edges_hash_map and n_id2 in self.edges_hash_map[n_id1]:
                return True
            if n_id2 in self.edges_hash_map and n_id1 in self.edges_hash_map[n_id2]:
                return True
        return False

    ## LEN FUNCTION
    cpdef int size_node_intersect(self,Graph G):
        if self.number_of_nodes == 0:
            return 0
        return len(self.nodes_hash_set.intersection(G.nodes_hash_set))
    cpdef int size_node_union(self,Graph G):
        return len(self.nodes_hash_set.union(G.nodes_hash_set))
    
    cpdef int size_edge_intersect(self,Graph G):
        if self.number_of_edges == 0:
            return 0
        return len(self.edges_hash_set.intersection(G.edges_hash_set))
    cpdef int size_edge_union(self,Graph G):
        return len(self.edges_hash_set.union(G.edges_hash_set))
    
        ## GETTER
    
    def get_nx(self):
        return self.nx_g

    def nodes(self,data=False):
        if data:
            if self.number_of_nodes == 0:
                    return [],[]
            return self.nodes_list,self.attr_nodes
        
        if self.number_of_nodes == 0:
                return []
        return self.nodes_list
        
    
    def edges(self,data=False):
        if data:
            if self.number_of_edges == 0:
                    return [],[]
            return self.edges_list,self.attr_edges
        
        if self.number_of_edges == 0:
            return []
        return self.edges_list
    
    cpdef list get_edges_ed(self,str e1,str e2):
        if self.is_edge_attr:
            hashes=self.edges_hash_map[e1][e2]
            return [(e1,e2,self.edges_attr_list[self.edges_hash_idx[hash_]])for hash_ in hashes]
        
        return [(e1,e2,None)]
            
    cpdef list get_edges_no(self,str n):
        return self.edges_of_nodes[n]

    cpdef dict get_edge_attr(self,edge_hash):
        return self.edges_attr_list[self.edges_hash_idx[edge_hash]]
    
    cpdef dict get_node_attr(self, node_hash):
        return self.edges_attr_list[self.edges_hash_idx[node_hash]]

    cpdef dict get_edge_attrs(self,edge_hash):
        return self.attr_edges[self.edges_hash_idx[edge_hash]]
    
    cpdef dict get_node_attrs(self, node_hash):
        return self.attr_nodes[self.edges_hash_idx[node_hash]]

    cpdef set get_edges_hash(self):
        return self.edges_hash_set

    cpdef set get_nodes_hash(self):
        return self.nodes_hash_set

    cpdef str get_node_key(self):
        return self.node_attr_key
        
    cpdef str get_egde_key(self):
        return self.edge_attr_key
    #####

    cpdef long size(self):
        return self.number_of_nodes
    
    cpdef int size_attr(self, attr_val):
        return self.number_of_nodes_per_attr[attr_val]

    cpdef long density(self):
        return self.number_of_edges
    
    cpdef int density_attr(self, str attr_val):
        return self.number_of_edges_per_attr[attr_val]

    cpdef double degree(self,str n_id, bint weight=False):
        if weight:
            return self.nodes_degree_weighted[self.nodes_idx[n_id]]
        return self.nodes_degree[self.nodes_idx[n_id]]
    
    cpdef double in_degree(self,str n_id, bint weight=False):
        if weight:
            return self.nodes_degree_in_weighted[self.nodes_idx[n_id]]
        return self.nodes_degree_in[self.nodes_idx[n_id]]
    
    cpdef double out_degree(self,str n_id, bint weight=False):
        if weight:
            return self.nodes_degree_out_weighted[self.nodes_idx[n_id]]
        return self.nodes_degree_out[self.nodes_idx[n_id]]

    cpdef double in_degree_attr(self,str n_id,str attr_val, bint weight=False):
        if not self.is_edge_attr and not self.is_directed:
            raise AttributeError("No edge attribute have been defined")
        if weight:
            return self.degree_per_attr_weighted[attr_val][n_id]["in"]
        return self.degree_per_attr[attr_val][n_id]["in"]

    cpdef double out_degree_attr(self,str n_id,str attr_val, bint weight=False):
        if not self.is_edge_attr and not self.is_directed:
            raise AttributeError("No edge attribute have been defined")
        if weight:
            return self.degree_per_attr_weighted[attr_val][n_id]["out"]
        return self.degree_per_attr[attr_val][n_id]["out"]

    cpdef double degree_attr(self,str n_id,str attr_val, bint weight=False):
        if not self.is_edge_attr:
            raise AttributeError("No edge attribute have been defined")
        if not self.is_directed:
            if weight:
                return self.degree_per_attr_weighted[attr_val][n_id]["out"]
            return self.degree_per_attr[attr_val][n_id]["out"]
        if weight:
            return self.degree_per_attr_weighted[attr_val][n_id]["in"] + self.degree_per_attr_weighted[attr_val][n_id]["out"]
        return self.degree_per_attr[attr_val][n_id]["out"] + self.degree_per_attr[attr_val][n_id]["in"]
    
    #GRAPH SETTER
    def add_node(self,str id_,**kwargs):
        if not self.node_attr_key in kwargs:
            print("Node not added because information lacks")
            return self
        if id_ in self.nodes_idx:
            print("Already in G")
            return self
        G=self.nx_g.copy()
        G.add_node(id_,**kwargs)
        return Graph(G,self.node_attr_key,self.edge_attr_key)
    
    
    def add_edge(self,str n1,str n2,**kwargs):
        G=self.nx_g.copy()
        G.add_edge(n1,n2,**kwargs)
        return Graph(G,self.node_attr_key,self.edge_attr_key)
    
    def remove_node(self,str id_):
        if not id_ in self.nodes_idx:
            print("Already removed in G")
            return self
        G=self.nx_g.copy()
        G.remove_node(id_)
        return Graph(G,self.node_attr_key,self.edge_attr_key)
    
    def remove_edge(self,str n1,str n2,**kwargs):
        G=self.nx_g.copy()
        edges=G.edges([n1,n2],data=True)
        if len(edges) == 0:
            return self
        elif len(edges)<2:
            G.remove_edge(n1,n2)
        else:
            if not self.edge_attr_key in kwargs:
                for i in range(len(edges)):
                    G.remove_edge(n1,n2,i)
            else:
                key,val,i=self.edge_attr_key, kwargs[self.edge_attr_key],0
                for e1,ed2,attr_dict in edges:
                    if attr_dict[key] == val:
                        G.remove_edge(n1,n2,i)
                        break
                    i+=1
                    
        return Graph(G,self.node_attr_key,self.edge_attr_key)

    def __init_empty__(self):
        self.nodes_list,self.nodes_attr_list,self.nodes_hash,self.nodes_weight,self.attr_nodes=[],[],[],[],[]
        self.nodes_degree,self.nodes_degree_in,self.nodes_degree_out,self.nodes_degree_weighted,self.nodes_degree_in_weighted,self.nodes_degree_out_weighted=np.array([],dtype=np.long),np.array([],dtype=np.long),np.array([],dtype=np.long),np.array([],dtype=np.double),np.array([],dtype=np.double),np.array([],dtype=np.double)
        self.nodes_idx,self.degree_per_attr,self.degree_per_attr_weighted={},{},{}
        self.nodes_hash_set=set([])
        self.number_of_nodes = 0

        self.number_of_edges = 0
        self.edges_list=[]
        self.edges_attr_list =[]
        self.edges_hash_idx = {}
        self.edges_hash = []
        self.edges_hash_set= set([])
        self.edges_weight={}
        self.edges_hash_map={}
        self.attr_edges=[]

    