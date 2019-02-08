from gmatch4py import *
import networkx as nx

graphs=[nx.random_tree(10) for i in range(10)]
comparator=None
for class_ in [BagOfNodes,WeisfeleirLehmanKernel,GraphEditDistance, BP_2, GreedyEditDistance, HED, Jaccard, MCS, VertexEdgeOverlap]:
    print(class_)
    if class_ in (GraphEditDistance, BP_2, GreedyEditDistance, HED):
        comparator = class_(1, 1, 1, 1)
    elif class_ == WeisfeleirLehmanKernel:
        comparator = class_(h=2)
    else:
        comparator=class_()
    matrix = comparator.compare(graphs, [])
