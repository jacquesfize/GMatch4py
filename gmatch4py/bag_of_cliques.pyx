# coding = utf-8

import copy
from typing import Sequence

import networkx as nx
import numpy as np
cimport numpy as np
from scipy.sparse import csr_matrix,lil_matrix
import sys

from .base cimport Base,intersection


cdef class BagOfCliques(Base):

    def __init__(self):
            Base.__init__(self,0,True)


    cpdef np.ndarray compare(self,list listgs, list selected):
        b=BagOfCliques()
        bog=b.getBagOfCliques(listgs).astype(np.float32)
        print(bog.shape)
        #Compute cosine similarity
        cdef int n=bog.shape[0]
        cdef np.ndarray scores = np.zeros((n,n))
        cdef int i
        for i in range(len(scores)):
            if selected:
                if not i in selected:
                    continue
            bog_i=np.asarray(bog[i].todense())
            for j in range(i,len(scores)):
                bog_j=np.asarray(bog[j].todense())
                scores[i,j]=(np.dot(bog_i,bog_j.T))/(np.sqrt(np.sum(bog_i**2))*np.sqrt(np.sum(bog_j**2))) # Can be computed in one line
                scores[j,i]=scores[i,j]
        return scores

    def getUniqueCliques(self,graphs):
        """
        Return unique cliques from a population of graphs
        :return:
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
            # sys.stdout.write("\r{0}/{1} -- {2}".format(km,len_graphs,len(g)))
            cliques = list(nx.enumerate_all_cliques(nx.Graph(g)))
                #no clique found
                #print(nx.Graph(g).edges())
            #cliques =[]
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
        try:
            return "".join(sorted(cliques))
        except:
            return "".join(sorted(list(map(str,cliques))))

    def transform_clique_vocab(self,clique_vocab):
        cdef dict new_vocab={}
        cdef int len_voc=len(clique_vocab)
        for c in range(len_voc):
            #print(c)
            new_vocab[self.clique2str(clique_vocab[c])]=c
        return new_vocab


    def ifHaveMinor(self,clique, dict mapping):
        """
        If a clique (minor) H belong to a graph G
        :param H:
        :return:
        """
        if self.clique2str(clique) in mapping:
            return 1
        return 0


    def getBagOfCliques(self,graphs ):
        """

        :param clique_vocab:
        :return:
        """
        cdef list clique_vocab=self.getUniqueCliques(graphs)
        cdef dict map_str_cliques=self.transform_clique_vocab(clique_vocab)
        cdef int l_v=len(clique_vocab)
        boc = lil_matrix((len(graphs), l_v))
        cdef np.ndarray vector
        cdef list cliques
        cdef str hash
        #print(1)
        for g in range(len(graphs)):
            #sys.stdout.write("\r{0}/{1}".format(g,len(graphs)))
            gr = graphs[g]
            vector = np.zeros(l_v)
            cliques = list(nx.enumerate_all_cliques(nx.Graph(gr)))
            for clique in cliques:
                hash=self.clique2str(clique)
                if hash in map_str_cliques:
                    vector[map_str_cliques[hash]] = 1
            boc[g] = vector
        return boc
