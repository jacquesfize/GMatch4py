# coding = utf-8

import networkx as nx
import numpy as np
import scipy.sparse


class DeltaCon0():
    __type__ = "sim"

    @staticmethod
    def compare(list_gs,selected):
        n=len(list_gs)

        comparison_matrix = np.zeros((n,n))
        for i in range(n):
            for j in range(i,n):
                g1,g2=list_gs[i],list_gs[j]
                f=True
                if not list_gs[i] or not list_gs[j]:
                    f=False
                elif len(list_gs[i])== 0 or len(list_gs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    # S1
                    epsilon = 1/(1+DeltaCon0.maxDegree(g1))
                    D, A = DeltaCon0.degreeAndAdjacencyMatrix(g1)
                    S1 = np.linalg.inv(np.identity(len(g1))+(epsilon**2)*D -epsilon*A)

                    # S2
                    D, A = DeltaCon0.degreeAndAdjacencyMatrix(g2)
                    epsilon = 1 / (1 + DeltaCon0.maxDegree(g2))
                    S2 = np.linalg.inv(np.identity(len(g2))+(epsilon**2)*D -epsilon*A)


                    comparison_matrix[i,j] = 1/(1+DeltaCon0.rootED(S1,S2))
                    comparison_matrix[j,i] = comparison_matrix[i,j]
                else:
                    comparison_matrix[i, j] = 0.
                comparison_matrix[j, i] = comparison_matrix[i, j]


        return comparison_matrix

    @staticmethod
    def rootED(S1,S2):
        return np.sqrt(np.sum((S1-S2)**2)) # Long live numpy !

    @staticmethod
    def degreeAndAdjacencyMatrix(G):
        """
        Return the Degree(D) and Adjacency Matrix(A) from a graph G.
        Inspired of nx.laplacian_matrix(G,nodelist,weight) code proposed by networkx
        :param G:
        :return:
        """
        A = nx.to_scipy_sparse_matrix(G, nodelist=list(G.nodes), weight="weight",
                                      format='csr')
        n, m = A.shape
        diags = A.sum(axis=1)
        D = scipy.sparse.spdiags(diags.flatten(), [0], m, n, format='csr')

        return D, A
    @staticmethod
    def maxDegree(G):
        degree_sequence = sorted(nx.degree(G).values(), reverse=True)  # degree sequence
        # print "Degree sequence", degree_sequence
        dmax = max(degree_sequence)
        return dmax

class DeltaCon():
    __type__ = "sim"

    @staticmethod
    def relabel_nodes(graph_list):
        label_lookup = {}
        label_counter = 0
        n= len(graph_list)
        # label_lookup is an associative array, which will contain the
        # mapping from multiset labels (strings) to short labels
        # (integers)
        for i in range(n):
            nodes = list(graph_list[i].nodes)

            for j in range(len(nodes)):
                if not (nodes[j] in label_lookup):
                    label_lookup[nodes[j]] = label_counter
                    label_counter += 1

            graph_list[i] = nx.relabel_nodes(graph_list[i], label_lookup)
        return graph_list
    @staticmethod
    def compare(list_gs, g=3):
        n=len(list_gs)
        list_gs=DeltaCon.relabel_nodes(list_gs)
        comparison_matrix = np.zeros((n,n))
        for i in range(n):
            for j in range(i,n):
                g1,g2=list_gs[i],list_gs[j]

                V = list(g1.nodes)
                V.extend(list(g2.nodes))
                V=np.unique(V)

                partitions=V.copy()
                np.random.shuffle(partitions)
                if len(partitions)< g:
                    partitions=np.array([partitions])
                else:
                    partitions=np.array_split(partitions,g)
                partitions_e_1 = DeltaCon.partitions2e(partitions, list(g1.nodes))
                partitions_e_2 = DeltaCon.partitions2e(partitions, list(g2.nodes))
                S1,S2=[],[]
                for k in range(len(partitions)):
                    s0k1,s0k2=partitions_e_1[k],partitions_e_2[k]

                    # S1
                    epsilon = 1/(1+DeltaCon0.maxDegree(g1))
                    D, A = DeltaCon0.degreeAndAdjacencyMatrix(g1)
                    s1k = np.linalg.inv(np.identity(len(g1))+(epsilon**2)*D -epsilon*A)
                    s1k=np.linalg.solve(s1k,s0k1).tolist()

                    # S2
                    D, A = DeltaCon0.degreeAndAdjacencyMatrix(g2)
                    epsilon = 1 / (1 + DeltaCon0.maxDegree(g2))
                    s2k= np.linalg.inv(np.identity(len(g2))+(epsilon**2)*D -epsilon*A)
                    s2k = np.linalg.solve(s2k, s0k2).tolist()



                    S1.append(s1k)
                    S2.append(s2k)

                comparison_matrix[i,j] = 1/(1+DeltaCon0.rootED(np.array(S1),np.array(S2)))
                comparison_matrix[j,i] = comparison_matrix[i,j]

        return comparison_matrix


    @staticmethod
    def partitions2e( partitions, V):
        e = [ [] for i in range(len(partitions))]
        for p in range(len(partitions)):
            e[p] = []
            for i in range(len(V)):
                if i in partitions[p]:
                    e[p].append(1.0)
                else:
                    e[p].append(0.0)
        return e