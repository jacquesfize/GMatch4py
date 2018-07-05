# coding = utf-8

import numpy as np
cimport numpy as np

def intersect(a, b):
    return list(set(a) & set(b))
class Jaccard():
    __type__ = "sim"


    @staticmethod
    def compare(listgs,selected):
        cdef int n = len(listgs)
        cdef np.ndarray comparison_matrix = np.zeros((n, n))
        cdef i=0
        cdef j=0
        for i in range(n):
            for j in range(i,n):
                g1 = listgs[i]
                g2 = listgs[j]
                f=True
                if not listgs[i] or not listgs[j]:
                    f=False
                elif len(listgs[i])== 0 or len(listgs[j]) == 0:
                    f=False
                if selected:
                    if not i in selected:
                        f=False
                if f:
                    inter_ver,inter_ed = Jaccard.intersect_graph(g1,g2)
                    un_ver,un_edg=Jaccard.union_nodes(g1,g2),Jaccard.union_edges(g1,g2)
                    if len(un_ver) == 0 or len(un_edg) == 0:
                        comparison_matrix[i, j] = 0.
                    else:
                        comparison_matrix[i,j]=(len(inter_ver)/len(un_ver))*(len(inter_ed)/len(un_edg))
                else:
                    comparison_matrix[i, j] = 0.

                comparison_matrix[j, i] = comparison_matrix[i, j]

        return comparison_matrix


    @staticmethod
    def intersect_edges(g1,g2):
        cdef list ed1 = Jaccard.transform_edges(list(g1.edges(data=True)))
        cdef list ed2 = Jaccard.transform_edges(list(g2.edges(data=True)))
        cdef list inter_ed=[]
        for e1 in ed1:
            for e2 in ed2:
                if e1 == e2:
                    inter_ed.append(e1)
        return inter_ed

    @staticmethod
    def union_nodes(g1, g2):
        cdef set union=set([])
        for n in g1.nodes():union.add(n)
        for n in g2.nodes(): union.add(n)
        return union

    @staticmethod
    def union_edges(g1, g2):
        cdef list ed1 = Jaccard.transform_edges(g1.edges(data=True))
        cdef list ed2 = Jaccard.transform_edges(g2.edges(data=True))
        cdef list union = []
        cdef set register=set([])
        trans_=lambda x : "{0}-{1}:{2}".format(x[0],x[1],x[2]["color"])
        for e1 in ed1:
            if not trans_(e1) in register:
                union.append(e1)
                register.add(trans_(e1))
        for e2 in ed2:
            if not trans_(e2) in register:
                union.append(e2)
                register.add(trans_(e2))
        return union
    @staticmethod
    def intersect_nodes(g1,g2):
        return intersect(list(g1.nodes),list(g2.nodes))

    @staticmethod
    def intersect_graph(g1,g2):
        return Jaccard.intersect_nodes(g1,g2),Jaccard.intersect_edges(g1,g2)

    @staticmethod
    def transform_edges(ed):
        for e in range(len(ed)):
            if "id" in ed[e][-1]:
                del ed[e][-1]["id"]
        return ed

