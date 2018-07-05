# coding = utf-8

"""
Shortest-Path graph kernel.
Python implementation based on: "Shortest-path kernels on graphs", by
Borgwardt, K.M.; Kriegel, H.-P., in Data Mining, Fifth IEEE
International Conference on , vol., no., pp.8 pp.-, 27-30 Nov. 2005
doi: 10.1109/ICDM.2005.132
Author : Sandro Vega-Pons, Emanuele Olivetti
Modified by : Jacques Fize
"""

import networkx as nx
import numpy as np


class ShortestPathGraphKernel:
    """
    Shorthest path graph kernel.
    """
    __type__ = "sim"
    @staticmethod
    def compare( g_1, g_2, verbose=False):
        """Compute the kernel value (similarity) between two graphs.
        Parameters
        ----------
        g1 : networkx.Graph
            First graph.
        g2 : networkx.Graph
            Second graph.
        Returns
        -------
        k : The similarity value between g1 and g2.
        """
        # Diagonal superior matrix of the floyd warshall shortest
        # paths:
        fwm1 = np.array(nx.floyd_warshall_numpy(g_1))
        fwm1 = np.where(fwm1 == np.inf, 0, fwm1)
        fwm1 = np.where(fwm1 == np.nan, 0, fwm1)
        fwm1 = np.triu(fwm1, k=1)
        bc1 = np.bincount(fwm1.reshape(-1).astype(int))

        fwm2 = np.array(nx.floyd_warshall_numpy(g_2))
        fwm2 = np.where(fwm2 == np.inf, 0, fwm2)
        fwm2 = np.where(fwm2 == np.nan, 0, fwm2)
        fwm2 = np.triu(fwm2, k=1)
        bc2 = np.bincount(fwm2.reshape(-1).astype(int))

        # Copy into arrays with the same length the non-zero shortests
        # paths:
        v1 = np.zeros(max(len(bc1), len(bc2)) - 1)
        v1[range(0, len(bc1)-1)] = bc1[1:]

        v2 = np.zeros(max(len(bc1), len(bc2)) - 1)
        v2[range(0, len(bc2)-1)] = bc2[1:]

        return np.sum(v1 * v2)


    @staticmethod
    def compare_list(graph_list, verbose=False):
        """Compute the all-pairs kernel values for a list of graphs.
        This function can be used to directly compute the kernel
        matrix for a list of graphs. The direct computation of the
        kernel matrix is faster than the computation of all individual
        pairwise kernel values.
        Parameters
        ----------
        graph_list: list
            A list of graphs (list of networkx graphs)
        Return
        ------
        K: numpy.array, shape = (len(graph_list), len(graph_list))
        The similarity matrix of all graphs in graph_list.
        """
        n = len(graph_list)
        k = np.zeros((n, n))
        for i in range(n):
            for j in range(i, n):
                k[i, j] = ShortestPathGraphKernel.compare(graph_list[i], graph_list[j])
                k[j, i] = k[i, j]

        k_norm = np.zeros(k.shape)
        for i in range(k.shape[0]):
            for j in range(k.shape[1]):
                k_norm[i, j] = k[i, j] / np.sqrt(k[i, i] * k[j, j])

        return k_norm