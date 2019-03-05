import networkx as nx
import numpy as np

def get_adjacency(G1,G2):
    """
    Return adjacency matrices of two graph based on nodes present in both of them.
    
    Parameters
    ----------
    G1 : nx.Graph
        first graph
    G2 : nx.Graph
        second graph
    
    Returns
    -------
    tuple of np.array
        adjacency matrices of G1 and G2
    """

    # Extract nodes
    nodes_G1=list(G1.nodes())
    nodes_G2=list(G2.nodes())

    # Get Adjacency Matrix for each graph
    adj_original_G1 = nx.convert_matrix.to_numpy_matrix(G1,nodes_G1)
    adj_original_G2 = nx.convert_matrix.to_numpy_matrix(G2,nodes_G2)

    # Get old index
    index_node_G1={node: ix for ix,node in enumerate(nodes_G1)}
    index_node_G2={node: ix for ix,node in enumerate(nodes_G2)}

    # Building new indices
    nodes_unique = list(set(nodes_G1).union(nodes_G2))
    new_node_index = {node:i for i,node in enumerate(nodes_unique)}

    n=len(nodes_unique)
    
    #Generate new adjacent matrices
    new_adj_G1= np.zeros((n,n))
    new_adj_G2= np.zeros((n,n))

    # Filling old values
    for n1 in nodes_unique:
        for n2 in nodes_unique:
            if n1 in G1.nodes() and n2 in G1.nodes():
                new_adj_G1[new_node_index[n1],new_node_index[n2]]=adj_original_G1[index_node_G1[n1],index_node_G1[n2]]
            if n1 in G2.nodes() and n2 in G2.nodes():
                new_adj_G2[new_node_index[n1],new_node_index[n2]]=adj_original_G2[index_node_G2[n1],index_node_G2[n2]]

    return new_adj_G1,new_adj_G2

