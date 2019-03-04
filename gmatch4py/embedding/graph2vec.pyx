import hashlib
import json
import glob
import pandas as pd
import networkx as nx
from tqdm import tqdm
cimport numpy as np
from joblib import Parallel, delayed
from gensim.models.doc2vec import Doc2Vec, TaggedDocument
import numpy.distutils.system_info as sysinfo
from sklearn.metrics.pairwise import cosine_similarity

from ..base cimport Base
cimport cython


class WeisfeilerLehmanMachine:
    """
    Weisfeiler Lehman feature extractor class.
    """
    def __init__(self, graph, features, iterations):
        """
        Initialization method which executes feature extraction.
        :param graph: The Nx graph object.
        :param features: Feature hash table.
        :param iterations: Number of WL iterations.
        """
        self.iterations = iterations
        self.graph = graph
        self.features = features
        self.nodes = self.graph.nodes()
        self.extracted_features = [str(v) for k,v in features.items()]
        self.do_recursions()

    def do_a_recursion(self):
        """
        The method does a single WL recursion.
        :return new_features: The hash table with extracted WL features.
        """
        new_features = {}
        for node in self.nodes:
            nebs = self.graph.neighbors(node)
            degs = [self.features[neb] for neb in nebs]
            features = "_".join([str(self.features[node])]+list(set(sorted([str(deg) for deg in degs]))))
            hash_object = hashlib.md5(features.encode())
            hashing = hash_object.hexdigest()
            new_features[node] = hashing
        self.extracted_features = self.extracted_features + list(new_features.values())
        return new_features

    def do_recursions(self):
        """
        The method does a series of WL recursions.
        """
        for iteration in range(self.iterations):
            self.features = self.do_a_recursion()
        

def dataset_reader(graph):
    """
    Function to read the graph and features from a json file.
    :param path: The path to the graph json.
    :return graph: The graph object.
    :return features: Features hash table.
    :return name: Name of the graph.
    """

    features = dict(nx.degree(graph))

    features = {k:v for k,v, in features.items()}
    return graph, features

def feature_extractor(graph, ix, rounds):
    """
    Function to extract WL features from a graph.
    :param path: The path to the graph json.
    :param rounds: Number of WL iterations.
    :return doc: Document collection object.
    """
    graph, features = dataset_reader(graph)
    machine = WeisfeilerLehmanMachine(graph,features,rounds)
    doc = TaggedDocument(words = machine.extracted_features , tags = ["g_{0}".format(ix)])
    return doc
        


def generate_model(graphs, iteration = 2, dimensions = 64, min_count = 5, down_sampling =  0.0001, learning_rate = 0.0001, epochs = 10, workers = 4 ):
    """
    Main function to read the graph list, extract features, learn the embedding and save it.
    :param args: Object with the arguments.
    """
    document_collections = [feature_extractor(g, ix,iteration) for ix,g in tqdm(enumerate(graphs),desc="Extracting Features...")]
    graphs=[nx.relabel_nodes(g,{node:str(node) for node in list(g.nodes)},copy=True) for g in graphs]
    model = Doc2Vec(document_collections,
                    vector_size = dimensions,
                    window = 0,
                    min_count = min_count,
                    dm = 0,
                    sample = down_sampling,
                    workers = workers,
                    epochs = epochs,
                    alpha = learning_rate)
    return model

cdef class Graph2Vec(Base):
    """
    Based on :
    graph2vec: Learning distributed representations of graphs. 
    Narayanan, Annamalai and Chandramohan, Mahinthan and Venkatesan, Rajasekar and Chen, Lihui and Liu, Yang 
    MLG 2017, 13th International Workshop on Mining and Learning with Graphs (MLGWorkshop 2017)

    Orignal Code : https://github.com/benedekrozemberczki/graph2vec

    Modified by : Jacques Fize
    """

    def __init__(self):
        Base.__init__(self,0,True)

    @cython.boundscheck(False)
    cpdef np.ndarray compare(self,list listgs, list selected):
        # Selected is ignored
        model  = generate_model(listgs)
        vector_matrix = model.docvecs.vectors_docs
        cs = cosine_similarity(vector_matrix)
        return cs
