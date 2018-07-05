# Gmatch4py a graph matching library for Python

Gmatch4py is a library dedicated to graph matching. Graph structure are stored in NetworkX graph objects.


## Requirements
 
 * Python3
 * Cython
 * networkit (for Bag of Cliques)
 
## Installation

First, compile the library by running this command:

```
$ python3 setup.py build_ext
```

Then, install the compiled module with:

```
$ pip3 install .
```

## Get Started

For now, every algorithms class is composed with a static method called `compare()`. `compare()` takes
two arguments :

 * An array containing the graphs to compare
 * An array containing indexes of graph you want to compare. Set to `None`, if you want to
 measure the similarity/distance between every graphs. 


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
        * Subtree Geo Kernel [new]
        * Edge Geo Kernel [new]
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

  * Debug algorithms with --> (*debug needed*)
  * Improve code structure and performance
  * Simplify `setup.py`
  * Some algorithms are distance and others are similarity measure. Must change the compare
  methods so it can adapt to the user need. For example, maybe the user want to deal with 
  graph similarity rather than distance between graph.
  * Write the documentation