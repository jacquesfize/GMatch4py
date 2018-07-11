# coding = utf-8

import copy
from typing import Sequence

import networkx as nx
import numpy as np
cimport numpy as np
import sys

from networkit import graph
from networkit.clique import MaximalCliques

def nx2nk(nxG, weightAttr=None):
    """
    Convert a networkx.Graph to a NetworKit.Graph
        :param weightAttr: the edge attribute which should be treated as the edge weight.
    """

    # map networkx node ids to consecutive numerical node ids
    idmap = dict((id, u) for (id, u) in zip(list(nxG.nodes), range(nxG.number_of_nodes())))
    z = max(idmap.values()) + 1
    # print("z = {0}".format(z))

    if weightAttr is not None:
        nkG = graph.Graph(z, weighted=True, directed=nxG.is_directed())
        for (u_, v_) in nxG.edges():
            u, v = idmap[u_], idmap[v_]
            w = nxG[u_][v_][weightAttr]
            nkG.addEdge(u, v, w)
    else:
        nkG = graph.Graph(z, directed=nxG.is_directed())
        for (u_, v_) in nxG.edges():
            u, v = idmap[u_], idmap[v_]
            # print(u_, v_, u, v)
            assert (u < z)
            assert (v < z)
            nkG.addEdge(u, v)

    assert (nkG.numberOfNodes() == nxG.number_of_nodes())
    assert (nkG.numberOfEdges() == nxG.number_of_edges())
    return nkG.removeSelfLoops(),idmap

def getClique(nx_graph):
    final_cliques=[]
    if len(nx_graph) ==0 or not nx_graph:
        return final_cliques
    netkit_graph,idmap=nx2nk(nx_graph)
    if not netkit_graph:
        return  final_cliques
    idmap={v:k for k,v in idmap.items()}
    cliques=MaximalCliques(netkit_graph).run().getCliques()
    for cl in cliques:
        final_cliques.append(list(map(lambda x:idmap[x],cl)))
    return final_cliques

class BagOfCliques():

    @staticmethod
    def compare(graphs,selected):
        b=BagOfCliques()
        bog=b.getBagOfCliques(graphs).astype(np.float32)
        #Compute cosine similarity
        cdef int n=bog.shape[0]
        cdef double[:,:] scores = np.zeros((n,n))
        cdef int i
        for i in range(len(scores)):
            if selected:
                if not i in selected:
                    continue
            for j in range(i,len(scores)):
                scores[i,j]=(np.dot(bog[i],bog[j]))/(np.sqrt(np.sum(bog[i]**2))*np.sqrt(np.sum(bog[j]**2))) # Can be computed in one line
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
            sys.stdout.write("\r{0}/{1} -- {2}".format(km,len_graphs,len(g)))
            try:
                cliques = list(getClique(nx.Graph(g)))
            except:
                #no clique found
                #print(nx.Graph(g).edges())
                cliques =[]
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
        return "".join(sorted(cliques))

    def transform_clique_vocab(self,clique_vocab):
        cdef dict new_vocab={}
        cdef int len_voc=len(clique_vocab)
        for c in range(len_voc):
            print(c)
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
        cdef np.ndarray boc = np.zeros((len(graphs), l_v))
        cdef np.ndarray vector
        cdef list cliques
        for g in range(len(graphs)):
            sys.stdout.write("\r{0}/{1}".format(g,len(graphs)))
            gr = graphs[g]
            vector = np.zeros(l_v)
            cliques = list(getClique(nx.Graph(gr)))
            for clique in cliques:
                hash=self.clique2str(clique)
                if hash in map_str_cliques:
                    vector[map_str_cliques[hash]] = 1
            boc[g] = vector
        return boc

    def distance(self,matrix):
        return 1-np.array(matrix)
    def similarity(self,matrix):
        return np.array(matrix)