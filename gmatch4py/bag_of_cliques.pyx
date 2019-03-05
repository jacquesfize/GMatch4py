# coding = utf-8

import copy
from typing import Sequence

import networkx as nx
import numpy as np
cimport numpy as np
from scipy.sparse import csr_matrix,lil_matrix
import sys

from .base cimport Base


cdef class BagOfCliques(Base):
    """
    The Bag of Cliques is representation of a graph corpus using the well-known *bag of words* model. Here, instead of
    word, we use unique cliques found in the graphs as a vocabulary. A clique is a highly connected graph where all the vertices are connected by an edge.

    The resulting representation is then use to compute similarity value between graphs. For this purpose, we use the cosine
    similarity.
    """

    def __init__(self):
        """
        Constructor of Bag Of Cliques.
        """
        Base.__init__(self,0,True)


    cpdef np.ndarray compare(self,list listgs, list selected):
        b=BagOfCliques()
        bog=b.get_bag_of_cliques(listgs).astype(np.float32)
        cdef int n=bog.shape[0]
        cdef np.ndarray scores = np.zeros((n,n))
        cdef int i
        for i in range(len(scores)):
            if selected:
                if not i in selected:
                    continue
            bog_i=bog[i]
            for j in range(i,len(scores)):
                bog_j=bog[j]
                scores[i,j]=(np.dot(bog_i,bog_j.T))/(np.sqrt(np.sum(bog_i**2))*np.sqrt(np.sum(bog_j**2))) # Can be computed in one line
                scores[j,i]=scores[i,j]
        return scores

    def get_unique_cliques(self, graphs):
        """
        Return a cliques found in a set of graphs
        Parameters
        ----------
        graphs: networkx.Graph array
            list of graphs

        Returns
        -------
        list
            Cliques set
        """
        t = {}
        c_ = 0
        cdef list clique_vocab = []
        cdef list cli_temp
        cdef list cliques
        cdef int len_graphs=len(graphs)
        cdef int km= -1
        for g in graphs:
            km+=1
            if not g:
                continue
            cliques = list(nx.find_cliques(nx.Graph(g)))
            for clique in cliques:
                cli_temp = copy.deepcopy(clique)
                new_clique = False
                for i in range(len(clique)):
                    flag = False
                    v = None  # vertex deleted
                    for vertex in cli_temp:
                        if vertex in t:
                            v = vertex
                            flag = True

                    if not flag in t:
                        v = cli_temp[0]
                        t[v] = {}
                        new_clique = True
                    t = t[v]
                    cli_temp.remove(v)

                if new_clique:
                    c_ += 1
                    clique_vocab.append(clique)
        return clique_vocab


    def clique2str(self,cliques):
        """
        Return a "hash" string of a clique

        Parameters
        ----------
        cliques: array

        Returns
        -------
        str
            hash of a clique
        """
        try:
            return "".join(sorted(cliques))
        except:
            return "".join(sorted(list(map(str,cliques))))

    def transform_clique_vocab(self,clique_vocab):
        """
        Transform cliques found in `get_unique_cliques()` in a proper format to build the "Bag of Cliques"

        Parameters
        ----------
        clique_vocab : array
            contains cliques
        Returns
        -------
        dict
            new clique vocab format
        """
        cdef dict new_vocab={}
        cdef int len_voc=len(clique_vocab)
        for c in range(len_voc):
            #print(c)
            new_vocab[self.clique2str(clique_vocab[c])]=c
        return new_vocab

    def get_bag_of_cliques(self, graphs):
        """
        Return a the Bag of Cliques representation from a graph set.

        Parameters
        ----------
        graphs : networkx.Graph array
            list of graphs

        Returns
        -------
        np.ndarray
            bag of cliques
        """
        cdef list clique_vocab=self.get_unique_cliques(graphs)
        cdef dict map_str_cliques=self.transform_clique_vocab(clique_vocab)
        cdef int l_v=len(clique_vocab)
        boc = np.zeros((len(graphs), l_v))
        cdef np.ndarray vector
        cdef list cliques
        cdef str hash

        for g in range(len(graphs)):
            #sys.stdout.write("\r{0}/{1}".format(g,len(graphs)))
            gr = graphs[g]
            vector = np.zeros(l_v)
            cliques = list(nx.find_cliques(nx.Graph(gr)))
            for clique in cliques:
                hash=self.clique2str(clique)
                if hash in map_str_cliques:
                    vector[map_str_cliques[hash]] = 1
            boc[g] = vector
        return boc
