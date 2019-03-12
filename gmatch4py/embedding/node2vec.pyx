import random

import numpy as np
cimport numpy as np
from gensim.models import Word2Vec
from sklearn.metrics.pairwise import cosine_similarity

from ..base cimport Base
cimport cython
from joblib import Parallel, delayed
import networkx as nx

class Graph():
    def __init__(self, nx_G, is_directed, p, q):
        self.G = nx_G
        self.is_directed = is_directed
        self.p = p
        self.q = q

    def node2vec_walk(self, walk_length, start_node):
        '''
        Simulate a random walk starting from start node.
        '''
        G = self.G
        alias_nodes = self.alias_nodes
        alias_edges = self.alias_edges

        walk = [start_node]

        while len(walk) < walk_length:
            cur = walk[-1]
            cur_nbrs = sorted(G.neighbors(cur))
            if len(cur_nbrs) > 0:
                if len(walk) == 1:
                    walk.append(
                        cur_nbrs[alias_draw(alias_nodes[cur][0], alias_nodes[cur][1])])
                else:
                    prev = walk[-2]
                    next = cur_nbrs[alias_draw(alias_edges[(prev, cur)][0],
                                               alias_edges[(prev, cur)][1])]
                    walk.append(next)
            else:
                break

        return walk

    def simulate_walks(self, num_walks, walk_length):
        '''
        Repeatedly simulate random walks from each node.
        '''
        # sys.stdout.write("\r")
        G = self.G
        walks = []
        nodes = list(G.nodes)
        for walk_iter in range(num_walks):
            # sys.stdout.write(
            #     '\rWalk iteration: {0}/{1}'.format(walk_iter + 1, num_walks))
            random.shuffle(nodes)
            for node in nodes:
                walks.append(self.node2vec_walk(
                    walk_length=walk_length, start_node=node))

        return walks

    def get_alias_edge(self, src, dst):
        '''
        Get the alias edge setup lists for a given edge.
        '''
        G = self.G
        p = self.p
        q = self.q

        unnormalized_probs = []
        for dst_nbr in sorted(G.neighbors(dst)):
            if dst_nbr == src:
                unnormalized_probs.append(G[dst][dst_nbr]['weight'] / p)
            elif G.has_edge(dst_nbr, src):
                unnormalized_probs.append(G[dst][dst_nbr]['weight'])
            else:
                unnormalized_probs.append(G[dst][dst_nbr]['weight'] / q)
        norm_const = sum(unnormalized_probs)
        normalized_probs = [
            float(u_prob) / norm_const for u_prob in unnormalized_probs]

        return alias_setup(normalized_probs)

    def preprocess_transition_probs(self):
        '''
        Preprocessing of transition probabilities for guiding the random walks.
        '''
        G = self.G
        is_directed = self.is_directed

        alias_nodes = {}
        for node in list(G.nodes):
            unnormalized_probs = [G[node][nbr]['weight']
                                  for nbr in sorted(G.neighbors(node))]
            norm_const = sum(unnormalized_probs)
            normalized_probs = [
                float(u_prob) / norm_const for u_prob in unnormalized_probs]
            alias_nodes[node] = alias_setup(normalized_probs)

        alias_edges = {}
        triads = {}

        if is_directed:
            for edge in list(G.edges()):
                alias_edges[edge] = self.get_alias_edge(edge[0], edge[1])
        else:
            for edge in list(G.edges()):
                alias_edges[edge] = self.get_alias_edge(edge[0], edge[1])
                alias_edges[(edge[1], edge[0])] = self.get_alias_edge(
                    edge[1], edge[0])

        self.alias_nodes = alias_nodes
        self.alias_edges = alias_edges

        return


def alias_setup(probs):
    '''
    Compute utility lists for non-uniform sampling from discrete distributions.
    Refer to https://hips.seas.harvard.edu/blog/2013/03/03/the-alias-method-efficient-sampling-with-many-discrete-outcomes/
    for details
    '''
    K = len(probs)
    q = np.zeros(K)
    J = np.zeros(K, dtype=np.int)

    smaller = []
    larger = []
    for kk, prob in enumerate(probs):
        q[kk] = K * prob
        if q[kk] < 1.0:
            smaller.append(kk)
        else:
            larger.append(kk)

    while len(smaller) > 0 and len(larger) > 0:
        small = smaller.pop()
        large = larger.pop()

        J[small] = large
        q[large] = q[large] + q[small] - 1.0
        if q[large] < 1.0:
            smaller.append(large)
        else:
            larger.append(large)

    return J, q


def alias_draw(J, q):
    '''
    Draw sample from a non-uniform discrete distribution using alias sampling.
    '''
    K = len(J)

    kk = int(np.floor(np.random.rand() * K))
    if np.random.rand() < q[kk]:
        return kk
    else:
        return J[kk]


def learn_embeddings(walks, dimensions, window_size, nb_workers, nb_iter):
    '''
    Learn embeddings by optimizing the Skipgram objective using SGD.
    '''
    walks_ = [list(map(str, walk)) for walk in walks]
    model = Word2Vec(walks_, size=dimensions, window=window_size,
                     min_count=0, sg=1, workers=nb_workers, iter=nb_iter)
    return model


def compute_graph_model(nx_graph, **kwargs):
    '''
    Pipeline for representational learning for all nodes in a graph.
        @param nx_graph
        @kwarg p: int
        @kwarg q: int
    '''
    p = kwargs.get("p", 1)
    q = kwargs.get("q", 1)
    dimensions = kwargs.get("dimensions", 128)
    window_size = kwargs.get("window_size", 10)
    nb_workers = kwargs.get("nb_workers", 8)
    nb_iter = kwargs.get("nb_iter", 1)
    num_walks = kwargs.get("num_walks", 10)
    walk_length = kwargs.get("walk_length", 80)
    directed = kwargs.get("directed", False)

    G = Graph(nx_graph, directed, p, q)
    G.preprocess_transition_probs()
    walks = G.simulate_walks(num_walks, walk_length)
    return learn_embeddings(walks, dimensions, window_size, nb_workers, nb_iter).wv.vectors

cdef class Node2Vec(Base):
    """
    Based on :
    Extract Node2vec embedding of each graph in `listgs`
        @inproceedings{Grover:2016:NSF:2939672.2939754,
             author = {Grover, Aditya and Leskovec, Jure},
             title = {Node2Vec: Scalable Feature Learning for Networks},
             booktitle = {Proceedings of the 22Nd ACM SIGKDD International Conference on Knowledge Discovery and Data Mining},
             series = {KDD '16},
             year = {2016},
             isbn = {978-1-4503-4232-2},
             location = {San Francisco, California, USA},
             pages = {855--864},
             numpages = {10},
             url = {http://doi.acm.org/10.1145/2939672.2939754},
             doi = {10.1145/2939672.2939754},
             acmid = {2939754},
             publisher = {ACM},
             address = {New York, NY, USA},
             keywords = {feature learning, graph representations, information networks, node embeddings},
        }

    Original code : https://github.com/aditya-grover/node2vec

    Modified by : Jacques Fize
    """

    def __init__(self):
        Base.__init__(self,0,False)

    def extract_embedding(self, listgs):
        """
        Extract Node2vec embedding of each graph in `listgs`

        Parameters
        ----------
        listgs : list
            list of graphs

        Returns
        -------
        list
            list of embeddings
        """

        from tqdm import tqdm
        models =  Parallel(n_jobs = self.cpu_count)(delayed(compute_graph_model)(g,directed=g.is_directed()) for g in tqdm(listgs,desc="Extracting Embeddings..."))
        return models

    @cython.boundscheck(False)
    cpdef np.ndarray compare(self,list listgs, list selected):
        # Selected is ignored
        [nx.set_edge_attributes(g,1,'weight') for g in listgs]
        models = self.extract_embedding(listgs)
        vector_matrix = np.array([mod.mean(axis=0) for mod in models])   # Average nodes representations
        cs = cosine_similarity(vector_matrix)
        return cs
