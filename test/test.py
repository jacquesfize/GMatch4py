import pytest
import os
import networkx as nx

def __import():
    # Gmatch4py use networkx graph 
    import networkx as nx 
    import gmatch4py as gm


def test_import():
    os.chdir(os.environ["HOME"] )
    __import()

def test_graph():
    os.chdir(os.environ["HOME"])
    import networkx as nx 
    import gmatch4py as gm

    # Simple Graph
    G1 = nx.Graph()
    G2 = nx.Graph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    
    gm.graph.Graph(G1)

    # Digraph Graph
    G1 = nx.DiGraph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    assert list(G1.edges()) == gm.graph.Graph(G1).edges()

    G1 = nx.DiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","2",color="red")
    G1.add_edge("1","3",color="green")
    assert gm.graph.Graph(G1,edge_attr_key="color").density() == 2
    assert gm.graph.Graph(G1).density() == 2

    # Multi Graph
    G1 = nx.MultiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","3",color="green")
    assert list(G1.edges()) == gm.graph.Graph(G1).edges()
    G1 = nx.MultiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","3",color="green")
    assert len(set([gm.graph.Graph(G1).hash_edge_attr(ed[0],ed[1],ed[2]["color"]) for ed in list(G1.edges(data=True))]).intersection(gm.graph.Graph(G1,edge_attr_key="color").get_edges_hash())) == 2

    G1 = nx.MultiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","2",color="red")
    G1.add_edge("1","3",color="green")
    assert gm.graph.Graph(G1,edge_attr_key="color").density() == len(G1.edges(data=True))
    assert gm.graph.Graph(G1).density() == len(G1.edges(data=True))

    # Multi DiGraph
    G1 = nx.MultiDiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","2",color="red")
    G1.add_edge("1","3",color="green")
    assert gm.graph.Graph(G1,edge_attr_key="color").density() == len(G1.edges(data=True))
    assert gm.graph.Graph(G1).density() == len(G1.edges(data=True))

def test_hash():
    os.chdir(os.environ["HOME"])
    import networkx as nx 
    import gmatch4py as gm

    # Basic HASH
    G1 = nx.Graph()
    G_gm = gm.graph.Graph(G1)
    assert G_gm.hash_edge("1","2") == "1_2"
    assert G_gm.hash_edge("2","1") == "1_2"

    # IF directed
    G1 = nx.DiGraph()
    G1.add_edge("1","2")
    G_gm = gm.graph.Graph(G1)
    assert G_gm.hash_edge("3","2") == "3_2"
    assert G_gm.hash_edge("2","1") == "2_1"

    # IF color and directed
    G1 = nx.DiGraph()
    G1.add_edge("1","2",color="blue")
    G_gm = gm.graph.Graph(G1,edge_attr_key="color")
    assert G_gm.hash_edge_attr("3","2","blue") == "3_2_blue"
    assert G_gm.get_edges_hash() == {"1_2_blue"}

    # if color and not directed
    G1 = nx.Graph()
    G1.add_edge("1","2",color="blue")
    G_gm = gm.graph.Graph(G1,edge_attr_key="color")
    assert G_gm.hash_edge_attr("3","2","blue") == "2_3_blue"

def test_intersect_union():
    os.chdir(os.environ["HOME"])
    import networkx as nx 
    import gmatch4py as gm

    # Basic 
    G1 = nx.Graph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    G2 = G1.copy()
    G2.add_edge("3","4")
    GM1 = gm.graph.Graph(G1)
    GM2 = gm.graph.Graph(G2)

    assert GM1.size_edge_union(GM2) == 3
    assert GM1.size_node_union(GM2) == 4

    assert GM1.size_edge_intersect(GM2) == 2
    assert GM1.size_node_intersect(GM2) == 3

    # BASIC and noised for hash
    G1 = nx.Graph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    G2 = nx.Graph()
    G2.add_edge("1","2")
    G2.add_edge("3","1") # Changing the direction (no impact if working)
    G2.add_edge("3","4")
    GM1 = gm.graph.Graph(G1)
    GM2 = gm.graph.Graph(G2)

    assert GM1.size_edge_union(GM2) == 3
    assert GM1.size_node_union(GM2) == 4
    
    assert GM1.size_edge_intersect(GM2) == 2
    assert GM1.size_node_intersect(GM2) == 3


    # Directed 
    G1 = nx.DiGraph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    G2 = nx.DiGraph()
    G2.add_edge("1","2")
    G2.add_edge("3","1") # Changing the direction (no impact if working)
    G2.add_edge("3","4")
    GM1 = gm.graph.Graph(G1)
    GM2 = gm.graph.Graph(G2)

    assert GM1.size_edge_union(GM2) == 4
    assert GM1.size_node_union(GM2) == 4
    
    assert GM1.size_edge_intersect(GM2) == 1
    assert GM1.size_node_intersect(GM2) == 3


    # IF COLOR
    G1 = nx.DiGraph(); G1.add_node("1",color="blue")
    G2 = nx.DiGraph(); G2.add_node("1",color="red")

    GM1,GM2 = gm.graph.Graph(G1),gm.graph.Graph(G2) 
    assert GM1.size_node_intersect(GM2) == 1
    GM1,GM2 = gm.graph.Graph(G1,node_attr_key="color"),gm.graph.Graph(G2,node_attr_key="color") 
    assert GM1.size_node_intersect(GM2) == 0
    

    G1 = nx.DiGraph(); G1.add_edge("1","2",color="blue")
    G2 = nx.DiGraph(); G2.add_edge("1","2",color="red")

    GM1,GM2 = gm.graph.Graph(G1),gm.graph.Graph(G2) 
    assert GM1.size_edge_intersect(GM2) == 1
    assert GM1.size_edge_union(GM2) == 1
    GM1,GM2 = gm.graph.Graph(G1,edge_attr_key="color"),gm.graph.Graph(G2,edge_attr_key="color") 
    assert GM1.size_edge_intersect(GM2) == 0
    assert GM1.size_edge_union(GM2) == 2

def test_degree():
    os.chdir(os.environ["HOME"])
    import networkx as nx 
    import gmatch4py as gm

    # Not DIRECTED and no attr
    G1 = nx.Graph()
    G1.add_edge("1","2")
    G1.add_edge("1","3")
    GM1 = gm.graph.Graph(G1)
    assert GM1.degree('1') == 2

    G1 = nx.DiGraph()
    G1.add_edge("1","2")
    G1.add_edge("3","1")
    GM1 = gm.graph.Graph(G1)
    assert GM1.degree('1') == 2
    assert GM1.in_degree('1') == 1
    assert GM1.out_degree('1') == 1

    G1 = nx.MultiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","2",color="red")
    G1.add_edge("1","3",color="blue")
    GM1 = gm.graph.Graph(G1,edge_attr_key ="color")
    
    assert GM1.degree_attr('1',"blue") == 2
    assert GM1.degree('1') == 3

    G1 = nx.MultiDiGraph()
    G1.add_edge("1","2",color="blue")
    G1.add_edge("1","2",color="red")
    G1.add_edge("1","3",color="green")
    GM1 = gm.graph.Graph(G1,edge_attr_key ="color")
    assert GM1.in_degree_attr('2','red') == 1
    assert GM1.in_degree('2') == 2







    