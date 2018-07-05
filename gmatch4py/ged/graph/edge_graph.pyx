# -*- coding: UTF-8 -*-


class EdgeGraph():

    def __init__(self, init_node, nodes):
        self.init_node=init_node
        self.nodes_ = nodes
        self.edge=nodes
    def nodes(self):
        return self.nodes_

    def size(self):
        return len(self.nodes)
    def __len__(self):
        return len(self.nodes_)
