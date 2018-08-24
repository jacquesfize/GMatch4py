# GMatch4py a graph matching library for Python

GMatch4py is a library dedicated to graph matching. Graph structure are stored in NetworkX graph objects.
GMatch4py algorithms were implemented with Cython to enhance performance.

## Requirements
 
 * Python 3.x
 * Cython
 * networkx
 * numpy
 
## Installation

To install `GMatch4py`, run the following commands:

```
$ git clone https://github.com/Jacobe2169/GMatch4py.git
$ cd GMatch4py
$ python3 setup.py install
```

or 

```
$ (sudo) pip3 install .
```

## Get Started
### Graph input format

In `Gmatch4py`, algorithms manipulate `networkx.Graph`, a complete graph model that 
comes with a large spectrum of parser to load your graph from various inputs : `*.graphml,*.gexf,..` (check [here](https://networkx.github.io/documentation/stable/reference/readwrite/index.html) to see all the format accepted)

### Use Gmatch4py
If you want to use algorithms like *graph edit distances*, here is an example:

```{python}
# Gmatch4py use networkx graph 
import networkx as nx 
# import the GED using the munkres algorithm
import gmatch4py as gm
```

In this example, we use generated graphs using `networkx` helpers:
```{python}
g1=nx.complete_bipartite_graph(5,4) 
g2=nx.complete_bipartite_graph(6,4)
```

All graph matching algorithms in `Gmatch4py work this way:
 * Each algorithm is associated with an object, each object having its specific parameters. In this case, the parameters are the edit costs (delete a vertex, add a vertex, ...)
 * Each object is associated with a `compare()` function with two parameters. First parameter is **a list of the graphs** you want to **compare**, i.e. measure the distance/similarity (depends on the algorithm). Then, you can specify a sample of graphs to be compared to all the other graphs. To this end, the second parameter should be **a list containing the indices** of these graphs (based on the first parameter list). If you rather compute the distance/similarity **between all graphs**, just use the `None` value.

```{python}
ged=gm.GraphEditDistance(1,1,1,1) # all edit costs are equal to 1
result=ged.compare([g1,g2],None) 
print(result)
```

The output is a similarity/distance matrix :
```
Out[10]:
array([[0., 7.],
       [7., 0.]])
```
This output result is "raw", if you wish to have normalized results in terms of distance (or similarity) you can use :

```
ged.similarity(result)
# or 
ged.distance(result)
```



## List of algorithms

 * DeltaCon and DeltaCon0 (*debug needed*) [1]
 * Vertex Ranking (*debug needed*) [2]
 * Vertex Edge Overlap [2]
 * Bag of Cliques (a bag of words model using cliques as vocabulary)
 * Graph kernels
    * Random Walk Kernel (*debug needed*) [3]
        * Geometrical 
        * K-Step 
    * Shortest Path Kernel [3]
    * Weisfeiler-Lehman Kernel [4]
        * Subtree Kernel 
        * Edge Kernel
 * Graph Edit Distance [5]
    * Approximated Graph Edit Distance 
    * Hausdorff Graph Edit Distance 
    * Bipartite Graph Edit Distance 
    * Greedy Edit Distance
 * MCS [6]
    

## Publications associated

  * [1] Koutra, D., Vogelstein, J. T., & Faloutsos, C. (2013, May). Deltacon: A principled massive-graph similarity function. In Proceedings of the 2013 SIAM International Conference on Data Mining (pp. 162-170). Society for Industrial and Applied Mathematics.
  * [2] Papadimitriou, P., Dasdan, A., & Garcia-Molina, H. (2010). Web graph similarity for anomaly detection. Journal of Internet Services and Applications, 1(1), 19-30.
  * [3] Vishwanathan, S. V. N., Schraudolph, N. N., Kondor, R., & Borgwardt, K. M. (2010). Graph kernels. Journal of Machine Learning Research, 11(Apr), 1201-1242.
  * [4] Shervashidze, N., Schweitzer, P., Leeuwen, E. J. V., Mehlhorn, K., & Borgwardt, K. M. (2011). Weisfeiler-lehman graph kernels. Journal of Machine Learning Research, 12(Sep), 2539-2561.
  * [5] Fischer, A., Riesen, K., & Bunke, H. (2017). Improved quadratic time approximation of graph edit distance by combining Hausdorff matching and greedy assignment. Pattern Recognition Letters, 87, 55-62.
  * [6] A graph distance metric based on the maximal common subgraph, H. Bunke and K. Shearer, Pattern Recognition Letters, 1998  

## Author(s)

Jacques Fize, *jacques[dot]fize[at]cirad[dot]fr*

Some algorithms coming from other projects were integrated to Gmatch4py. **Be assured that
each code is associated with a reference to the original.**

## TODO List

  * Debug algorithms --> :runner:
  * Improve code structure and performance :runner:
  * Simplify `setup.py` :heavy_check_mark:
  * Some algorithms are distance and others are similarity measure. Must change the compare
  methods so it can adapt to the user need. For example, maybe the user want to deal with 
  graph similarity rather than distance between graph. :heavy_check_mark:
  * Write the documentation :runner: