# coding = utf-8

import networkx as nx
import numpy as np
cimport numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from .base cimport Base

cdef class BagOfNodes(Base):
    """
    We could call this algorithm Bag of nodes
    """
    def __init__(self):
        Base.__init__(self,0,True)

    cpdef np.ndarray compare(self,list graph_list, list selected):
        nodes = list()
        for g in graph_list:
            nodes.extend(list(g.nodes()))

        vocabulary = list(set(nodes))
        hash_voc = {}
        i = 0
        for se in vocabulary:
            hash_voc[se] = i
            i += 1
        n, m = len(graph_list), len(hash_voc)
        bow_matrix = np.zeros((n, m))
        i = 0
        for g in range(len(graph_list)):
            graph = graph_list[g]
            nodes = list(graph.nodes())
            for nod in nodes:
                j = hash_voc[nod]
                bow_matrix[i, j] = 1
            i += 1

        sim_matrix = cosine_similarity(bow_matrix)
        np.fill_diagonal(sim_matrix, 1)
        return sim_matrix
