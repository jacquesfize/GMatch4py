#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import random

from io import open
from argparse import ArgumentParser, FileType, ArgumentDefaultsHelpFormatter
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
import logging
from multiprocessing import cpu_count

import networkx as nx
import numpy as np
cimport numpy as np
from six import text_type as unicode
from six import iteritems
from six.moves import range

from gensim.models import Word2Vec
from sklearn.metrics.pairwise import cosine_similarity
from joblib import Parallel, delayed
import psutil

cimport cython
from ..base cimport Base
import graph as graph2
import walks as serialized_walks
from skipgram import Skipgram


p = psutil.Process(os.getpid())
try:
    p.set_cpu_affinity(list(range(cpu_count())))
except AttributeError:
    try:
        p.cpu_affinity(list(range(cpu_count())))
    except AttributeError:
        pass


def process(gr, number_walks = 10, walk_length = 40, window_size = 5, vertex_freq_degree = False, workers = 1, representation_size = 64, max_memory_data_size = 1000000000, seed = 0):
    """
    Return a DeepWalk embedding for a graph
    
    Parameters
    ----------
    gr : nx.Graph
        graph
    number_walks : int, optional
        Number of walk (the default is 10)
    walk_length : int, optional
        Length of the random walk started at each node (the default is 40)
    window_size : int, optional
        Window size of skipgram model. (the default is 5)
    vertex_freq_degree : bool, optional
        Use vertex degree to estimate the frequency of nodes (the default is False)
    workers : int, optional
        Number of parallel processes (the default is 1)
    representation_size : int, optional
        Number of latent dimensions to learn for each node (the default is 64)
    max_memory_data_size : int, optional
        'Size to start dumping walks to disk, instead of keeping them in memory. (the default is 1000000000)
    seed : int, optional
        Seed for random walk generator (the default is 0)
    
    Returns
    -------
    np.array
        DeepWalk embedding
    """
    
    if len(gr.edges())<1:
        return np.zeros((1,representation_size))
    G = graph2.from_networkx(gr.copy(), undirected=gr.is_directed())
    num_walks = len(G.nodes()) * number_walks

    data_size = num_walks * walk_length

    #print("Data size (walks*length): {}".format(data_size))

    if data_size < max_memory_data_size:
        #print("Walking...")
        walks = graph2.build_deepwalk_corpus(G, num_paths=number_walks,
                                            path_length=walk_length, alpha=0, rand=random.Random(seed))
        #print("Training...")
        model = Word2Vec(walks, size=representation_size,
                            window=window_size, min_count=0, sg=1, hs=1, workers=workers)
    else:
        #print("Data size {} is larger than limit (max-memory-data-size: {}).  Dumping walks to disk.".format(
        #    data_size, max_memory_data_size))
        #print("Walking...")

        walks_filebase = "temp.walks"
        walk_files = serialized_walks.write_walks_to_disk(G, walks_filebase, num_paths=number_walks,
                                                            path_length=walk_length, alpha=0, rand=random.Random(seed),
                                                            num_workers=workers)

        #print("Counting vertex frequency...")
        if not vertex_freq_degree:
            vertex_counts = serialized_walks.count_textfiles(
                walk_files, workers)
        else:
            # use degree distribution for frequency in tree
            vertex_counts = G.degree(nodes=G.iterkeys())

        #print("Training...")
        walks_corpus = serialized_walks.WalksCorpus(walk_files)
        model = Skipgram(sentences=walks_corpus, vocabulary_counts=vertex_counts,
                            size=representation_size,
                            window=window_size, min_count=0, trim_rule=None, workers=workers)

    return model.wv.vectors


cdef class DeepWalk(Base):
    """
    Based on :
    @inproceedings{Perozzi:2014:DOL:2623330.2623732,
        author = {Perozzi, Bryan and Al-Rfou, Rami and Skiena, Steven},
        title = {DeepWalk: Online Learning of Social Representations},
        booktitle = {Proceedings of the 20th ACM SIGKDD International Conference on Knowledge Discovery and Data Mining},
        series = {KDD '14},
        year = {2014},
        isbn = {978-1-4503-2956-9},
        location = {New York, New York, USA},
        pages = {701--710},
        numpages = {10},
        url = {http://doi.acm.org/10.1145/2623330.2623732},
        doi = {10.1145/2623330.2623732},
        acmid = {2623732},
        publisher = {ACM},
        address = {New York, NY, USA},
        keywords = {deep learning, latent representations, learning with partial labels, network classification, online learning, social networks},
    }

    Original Code : https://github.com/phanein/deepwalk

    Modified by : Jacques Fize
    """

    def __init__(self):
        Base.__init__(self,0,False)

    def extract_embedding(self, listgs):
        """
        Extract DeepWalk embedding of each graph in `listgs`
        
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
        models =  Parallel(n_jobs = cpu_count())(delayed(process)(nx.Graph(g)) for g in tqdm(listgs,desc="Extracting Embeddings..."))
        return models

    @cython.boundscheck(False)
    cpdef np.ndarray compare(self,list listgs, list selected):
        # Selected is ignored
        models = self.extract_embedding(listgs)
        vector_matrix = np.array([mod.mean(axis=0) for mod in models])   # Average nodes representations
        cs = cosine_similarity(vector_matrix)
        return cs

