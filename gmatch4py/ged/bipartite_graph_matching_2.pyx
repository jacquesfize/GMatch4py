# coding = utf-8
import numpy as np
cimport numpy as np

cdef class BP_2():
    """

    """
    __type__="dist"

    cdef int node_del
    cdef int node_ins
    cdef int edge_del
    cdef int edge_ins

    @staticmethod
    def compare(listgs,selected, c_del_node=1, c_del_edge=1, c_ins_node=1, c_ins_edge=1):
        cdef int n = len(listgs)
        comparator = BP_2(c_del_node, c_ins_node, c_del_edge, c_ins_edge)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        for i in range(n):
            for j in range(i, n):
                f=True
                if not listgs[i] or not listgs[j]:
                    f=False
                elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    comparison_matrix[i, j] = comparator.bp2(listgs[i], listgs[j])
                else:
                    comparison_matrix[i, j] = np.inf
                comparison_matrix[j, i] = comparison_matrix[i, j]

        return comparison_matrix

    def __init__(self, node_del=1, node_ins=1, edge_del=1, edge_ins=1):
        """Constructor for HED"""
        self.node_del = node_del
        self.node_ins = node_ins
        self.edge_del = edge_del
        self.edge_ins = edge_ins

    def bp2(self, g1, g2):
        """
        Compute de Hausdorff Edit Distance
        :param g1: first graph
        :param g2: second graph
        :return:
        """
        return np.min(self.distance(self.psi(g1,g2)),self.distance(self.psi(g2,g1)))

    def distance(self,e):
        return np.sum(e)

    cdef list psi(self,g1,g2):
        cdef list psi_=[]
        cdef list nodes1 = list(g1.nodes)
        cdef list nodes2 = list(g2.nodes)
        for u in nodes1:
            v=None
            for w in nodes2:
                if 2*self.fuv(g1,g2,u,w) < self.fuv(g1,g2,u,None) + self.fuv(g1,g2,None,w)\
                     and self.fuv(g1,g2,u,w) < self.fuv(g1,g2,u,v):
                    v=w
                psi_.append(self.fuv(g1,g2,u,v))
            if u:
                nodes1= list(set(nodes1).difference(set([u])))
            if v:
                nodes2= list(set(nodes2).difference(set([v])))
        for v in nodes2:
            psi_.append(self.fuv(g1,g2,None,v))
        return  psi_


    cdef float fuv(self, g1, g2, n1, n2):
        """
        Compute the Node Distance function
        :param g1: first graph
        :param g2: second graph
        :param n1: node of the first graph
        :param n2: node of the second graph
        :return:
        """
        if n2 == None:  # Del
            return self.node_del + ((self.edge_del / 2) * g1.degree(n1))
        if n1 == None:  # Insert
            return self.node_ins + ((self.edge_ins / 2) * g2.degree(n2))
        else:
            if n1 == n2:
                return 0.
            return (self.node_del + self.node_ins + self.hed_edge(g1, g2, n1, n2)) / 2

    cdef float hed_edge(self, g1, g2, n1, n2):
        """
        Compute HEDistance between edges of n1 and n2, respectively in g1 and g2
        :param g1: first graph
        :param g2: second graph
        :param n1: node of the first graph
        :param n2: node of the second graph
        :return:
        """
        return self.sum_gpq(g1, n1, g2, n2) + self.sum_gpq(g1, n1, g2, n2)

    cdef list get_edge_multigraph(self, g, node):
        """
        Get list of edge around a node in a Multigraph
        :param g: multigraph
        :param node: node in the multigraph
        :return:
        """

        cdef list originals_ = g.edges(node, data=True)
        cdef int n= len(originals_)
        if n == 0:
            return []

        cdef list edges = [""]*n
        for i in range(n):
            edge=originals_[i]
            edges[i]=("{0}-{1}".format(edge[0],edge[1]))
        return edges

    cdef float sum_gpq(self, g1, n1, g2, n2):
        """
        Compute Nearest Neighbour Distance between edges around n1 in G1  and edges around n2 in G2
        :param g1: first graph
        :param n1: node in the first graph
        :param g2: second graph
        :param n2: node in the second graph
        :return:
        """
        cdef list edges1 = self.get_edge_multigraph(g1, n1)
        cdef list edges2 = self.get_edge_multigraph(g2, n2)
        edges2.extend([None])
        cdef np.ndarray min_sum = np.zeros(len(edges1))
        for i in range(len(edges1)):
            min_i = np.zeros(len(edges2))
            for j in range(len(edges2)):
                min_i[j] = self.gpq(edges1[i], edges2[j])
            min_sum[i] = np.min(min_i)
        return np.sum(min_sum)

    cdef float gpq(self, e1, e2):
        """
        Compute the edge distance function
        :param e1: edge1
        :param e2: edge2
        :return:
        """
        if e2 == None:  # Del
            return self.edge_del
        if e1 == None:  # Insert
            return self.edge_ins
        else:
            if e1 == e2:
                return 0.
            return (self.edge_del + self.edge_ins) / 2

