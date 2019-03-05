import os
os.chdir(os.environ["HOME"])

def test_mesure():
    import gmatch4py as gm
    import networkx as nx
    import time
    from tqdm import tqdm
    import pandas as pd


    max_=100
    size_g=10
    graphs_all=[nx.random_tree(size_g) for i in range(max_)]
    result_compiled=[]
    for size_ in tqdm(range(50,max_,50)):
        graphs=graphs_all[:size_]
        comparator=None
        for class_ in [gm.BagOfNodes,gm.WeisfeleirLehmanKernel, gm.GraphEditDistance,  gm.GreedyEditDistance, gm.HED, gm.BP_2,  gm.Jaccard, gm.MCS, gm.VertexEdgeOverlap]:
            deb=time.time()
            if class_ in (gm.GraphEditDistance, gm.BP_2, gm.GreedyEditDistance, gm.HED):
                comparator = class_(1, 1, 1, 1)
            elif class_ == gm.WeisfeleirLehmanKernel:
                comparator = class_(h=2)
            else:
                comparator=class_()
            matrix = comparator.compare(graphs,None)
            print([class_.__name__,size_,time.time()-deb])
            result_compiled.append([class_.__name__,size_,time.time()-deb])

    df = pd.DataFrame(result_compiled,columns="algorithm size_data time_exec_s".split())
    df.to_csv("new_gmatch4py_res_{0}graphs_{1}size.csv".format(max_,size_g))