# coding = utf-8

import networkx as nx
import numpy as np

class GeometricRandomWalkKernel():
    __type__ = "sim"
    @staticmethod
    def maxDegree(G):
        degree_sequence = sorted(nx.degree(G).values(), reverse=True)  # degree sequence

        # print "Degree sequence", degree_sequence
        dmax = max(degree_sequence)
        return dmax
    @staticmethod
    def compare(listgs):

        n = len(listgs)
        comparison_matrix=np.zeros((n,n))
        for i in range(n):
            for j in range(i,n):
                if len(listgs[i]) <1 or len(listgs[j]) <1:
                    comparison_matrix[i, j] = 0
                    comparison_matrix[j, i] = 0
                    continue
                direct_product_graph=nx.tensor_product(listgs[i],listgs[j])
                Ax = nx.adjacency_matrix(direct_product_graph).todense()
                try:
                    la = 1/ ((GeometricRandomWalkKernel.maxDegree(direct_product_graph)**2)+1) # lambda value
                except:
                    la= pow(1,-6)
                eps = pow(10,-10)
                I=np.identity(Ax.shape[0])
                I_vec=np.ones(Ax.shape[0])
                x=I_vec.copy()
                x_pre=np.zeros(Ax.shape[0])
                c=0

                while (np.linalg.norm(x-x_pre)) > eps:
                    if c > 100:
                        break
                    x_pre=x

                    x= I_vec + la*np.dot(Ax,x_pre.T)
                    c+=1
                comparison_matrix[i,j]=np.sum(x)
                comparison_matrix[j,i]=comparison_matrix[i,j]
        print(comparison_matrix)
        for i in range(n):
            for j in range(i,n):
                comparison_matrix[i,j] = (comparison_matrix[i,j]/np.sqrt(comparison_matrix[i,i]*comparison_matrix[j,j]))
                comparison_matrix[j,i]=comparison_matrix[i,j]
        return comparison_matrix

class KStepRandomWalkKernel():
    __type__ = "sim"
    @staticmethod
    def maxDegree(G):
        degree_sequence = sorted(nx.degree(G).values(), reverse=True)  # degree sequence
        # print "Degree sequence", degree_sequence
        dmax = max(degree_sequence)
        return dmax
    @staticmethod
    def compare(listgs,lambda_list=[1,1,1]):
        k=len(lambda_list)
        if not len(lambda_list) == k:
            raise AttributeError
        n = len(listgs)
        comparison_matrix=np.zeros((n,n))
        for i in range(n):
            for j in range(i,n):
                if len(listgs[i]) <1 or len(listgs[j]) <1:
                    comparison_matrix[i, j] = 0
                    comparison_matrix[j, i] = 0
                    continue
                direct_product_graph=nx.tensor_product(listgs[i],listgs[j])
                Ax = nx.adjacency_matrix(direct_product_graph).todense()
                eps = pow(10,-10)
                I=np.identity(Ax.shape[0])
                ax_pow = I.copy()
                sum_ = lambda_list[0] * I
                for kk in range(1, k):
                    ax_pow *= Ax
                    sum_ += lambda_list[kk] * ax_pow

                comparison_matrix[i, j] = np.sum(sum_)/(len(listgs[i])**2 * len(listgs[j])**2)
                comparison_matrix[j,i] = comparison_matrix[i,j]

        for i in range(n):
            for j in range(i,n):
                comparison_matrix[i,j] = comparison_matrix[i,j]/np.sqrt(comparison_matrix[i,i]*comparison_matrix[j,j])
                comparison_matrix[j,i]=comparison_matrix[i,j]
        return comparison_matrix