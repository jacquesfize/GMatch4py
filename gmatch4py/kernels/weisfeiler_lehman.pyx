# coding = utf-8

"""Weisfeiler_Lehman graph kernel.

Python implementation based on: "Weisfeiler-Lehman Graph Kernels", by:
Nino Shervashidze, Pascal Schweitzer, Erik J. van Leeuwen, Kurt
Mehlhorn, Karsten M. Borgwardt, JMLR, 2012.
http://jmlr.csail.mit.edu/papers/v12/shervashidze11a.html

Author : Sandro Vega-Pons, Emanuele Olivetti
Source : https://github.com/emanuele/jstsp2015/blob/master/gk_weisfeiler_lehman.py
Modified by : Jacques Fize
"""

import copy

import networkx as nx
import numpy as np
cimport numpy as np
from ..base cimport Base
from ..base import minmax_scale
from scipy.sparse import csc_matrix,lil_matrix

cdef class WeisfeleirLehmanKernel(Base):

    cdef int h

    def __init__(self,h=2):
        Base.__init__(self,0,True)
        self.h=h


    cpdef np.ndarray compare(self,list graph_list, list selected):
        """Compute the all-pairs kernel values for a list of graphs.
        This function can be used to directly compute the kernel
        matrix for a list of graphs. The direct computation of the
        kernel matrix is faster than the computation of all individual
        pairwise kernel values.
        Parameters
        ----------
        graph_list: list
            A list of graphs (list of networkx graphs)
        h : interger
            Number of iterations.
        node_label : boolean
            Whether to use original node labels. True for using node labels
            saved in the attribute 'node_label'. False for using the node
            degree of each node as node attribute.
        Return
        ------
        K: numpy.array, shape = (len(graph_list), len(graph_list))
        The similarity matrix of all graphs in graph_list.
        """

        cdef int n = len(graph_list)
        cdef int n_nodes = 0
        cdef int n_max = 0
        cdef int i,j
        # Compute adjacency lists and n_nodes, the total number of
        # nodes in the dataset.
        for i in range(n):
            n_nodes += graph_list[i].number_of_nodes()

            # Computing the maximum number of nodes in the graphs. It
            # will be used in the computation of vectorial
            # representation.
            if n_max < graph_list[i].number_of_nodes():
                n_max = graph_list[i].number_of_nodes()

        phi = np.zeros((n_nodes, n), dtype=np.uint64)
        phi=lil_matrix(phi)

        # INITIALIZATION: initialize the nodes labels for each graph
        # with their labels or with degrees (for unlabeled graphs)

        cdef list labels = [0] * n
        cdef dict label_lookup = {}
        cdef int label_counter = 0


        # label_lookup is an associative array, which will contain the
        # mapping from multiset labels (strings) to short labels
        # (integers)

        cdef list nodes
        for i in range(n):
            nodes = list(graph_list[i].nodes)
            # It is assumed that the graph has an attribute
            # 'node_label'
            labels[i] = np.zeros(len(nodes), dtype=np.int32)

            for j in range(len(nodes)):
                if not (nodes[j] in label_lookup):
                    label_lookup[nodes[j]] = str(label_counter)
                    labels[i][j] = label_counter
                    label_counter += 1
                else:
                    labels[i][j] = label_lookup[nodes[j]]
                # labels are associated to a natural number
                # starting with 0.

                phi[labels[i][j], i] += 1

            graph_list[i]=nx.relabel_nodes(graph_list[i],label_lookup)

        # cdef np.ndarray[np.float64_t] k
        k = np.dot(phi.transpose(), phi)
        # MAIN LOOP
        cdef int it = 0

        new_labels = copy.deepcopy(labels) # Can't work without it !!!

        while it < self.h:
            # create an empty lookup table
            label_lookup = {}
            label_counter = 0

            phi = np.zeros((n_nodes, n))
            for i in range(n):
                nodes = list(graph_list[i].nodes)
                for v in range(len(nodes)):
                    # form a multiset label of the node v of the i'th graph
                    # and convert it to a string

                    long_label = []
                    long_label.extend(nx.neighbors(graph_list[i],nodes[v]))

                    long_label_string = "".join(long_label)
                    # if the multiset label has not yet occurred, add it to the
                    # lookup table and assign a number to it
                    if not (long_label_string in label_lookup):
                        label_lookup[long_label_string] = str(label_counter)
                        new_labels[i][v] = label_counter
                        label_counter += 1
                    else:
                        new_labels[i][v] = label_lookup[long_label_string]
                # fill the column for i'th graph in phi
                aux = np.bincount(new_labels[i])
                phi[new_labels[i], i] += aux[new_labels[i]]

            k += np.dot(phi.transpose(), phi)
            it = it + 1

        return np.ma.getdata(minmax_scale(k))