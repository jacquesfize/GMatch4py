# coding = utf-8

from helpers.gazeteer_helpers import get_data,get_data_by_wikidata_id


"""Weisfeiler_Lehman GEO graph kernel.

"""

import numpy as np
import networkx as nx
import copy

class WeisfeleirLehmanKernelEdge(object):
    __type__ = "sim"


    @staticmethod
    def compare(graph_list,h=3):
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

        n = len(graph_list)
        k = [0] * (h + 1)
        n_nodes = 0
        n_max = 0
        ams=[nx.adjacency_matrix(g).todense() for g in graph_list]
        inclusion_dictionnary={}

        # Compute adjacency lists and n_nodes, the total number of
        # nodes in the dataset.
        for i in range(n):
            n_nodes += graph_list[i].number_of_nodes()

            """
            Store Inclusion Informations
            """
            for node in graph_list[i].nodes():
                graph_list[i].nodes[node]["id_GD"]=node
                if not node in inclusion_dictionnary:
                    inc_list = []
                    try:
                        inc_list = get_data(node)["inc_P131"]
                    except:
                        try:
                            inc_list=get_data_by_wikidata_id(get_data(node)["continent"])["id"]
                        except:
                            pass # No inclusion
                    if inc_list:
                        inc_list = inc_list if isinstance(inc_list,list) else [inc_list]

                        inclusion_dictionnary[node]=inc_list[0]
                        for j in range(1,len(inc_list)):
                            if j+1 < len(inc_list):
                                inclusion_dictionnary[inc_list[j]]=inc_list[j+1]




            # Computing the maximum number of nodes in the graphs. It
            # will be used in the computation of vectorial
            # representation.
            if (n_max < graph_list[i].number_of_nodes()):
                n_max = graph_list[i].number_of_nodes()

        phi = np.zeros((n_nodes, n), dtype=np.uint64)
        #print(inclusion_dictionnary)
        # INITIALIZATION: initialize the nodes labels for each graph
        # with their labels or with degrees (for unlabeled graphs)

        labels = [0] * n
        label_lookup = {}
        label_counter = 0

        # label_lookup is an associative array, which will contain the
        # mapping from multiset labels (strings) to short labels
        # (integers)
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

        L=label_counter
        print("L1",L)
        ed=np.zeros((np.int((L*(L+1))),n))
        # MAIN LOOP
        it = 0
        new_labels = copy.deepcopy(labels) # Can't work without it !!!

        for i in range(n):
            labels_aux =  np.tile(new_labels[i].reshape(-1,1),len(new_labels[i]))
            a=np.minimum(labels_aux,labels_aux.T)
            b=np.maximum(labels_aux,np.transpose(labels_aux))
            I=np.triu((ams[i] !=0),1)
            a_i=np.extract(I,a)
            b_i = np.extract(I, b)
            Ind=np.abs(np.multiply((a[I]-1),(2*L+2-a[I])/2+b[I]-a[I]+1).astype(int))
            minind=np.min(Ind)
            aux=np.bincount(Ind)
            ed[Ind,i]=aux[Ind]

        mask=np.sum(ed,1) !=0
        ed= ed[mask]
        k=np.dot(ed.T,ed)

        it = 0
        new_labels = copy.deepcopy(new_labels)  # Can't work without it !!!

        while it < h:
            label_lookup={}
            label_counter=0
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

            L = label_counter
            print("L2",L)
            ed = np.zeros((np.int((L * (L + 1))), n))
            for i in range(n):
                labels_aux = np.tile(new_labels[i].reshape(-1, 1), len(new_labels[i]))
                a = np.minimum(labels_aux, labels_aux.T)
                b = np.maximum(labels_aux, np.transpose(labels_aux))
                I = np.triu((ams[i] != 0), 1)
                a_i = np.extract(I, a)
                b_i = np.extract(I, b)
                Ind = np.abs(np.multiply((a[I] - 1), (2 * L + 2 - a[I]) / 2 + b[I] - a[I] + 1).astype(int))
                minind = np.min(Ind)
                aux = np.bincount(Ind)
                ed[Ind, i] = aux[Ind]

            mask = np.sum(ed, 1) != 0
            ed = ed[mask]
            k += np.dot(ed.T, ed)
            print(k)
            it+=1
        k_norm = np.zeros(k.shape)
        for i in range(k.shape[0]):
            for j in range(k.shape[1]):
                k_norm[i, j] = k[i, j] / np.sqrt(k[i, i] * k[j, j])

        return k_norm