# coding = utf-8
from termcolor import colored
class NotFoundDistance(Exception):
    def __init__(self,dd,distanceFunctionDict):
        # Call the base class constructor with the parameters it needs
        super(Exception, self).__init__(colored("{0} is not an edit distance implemented ! Select a distance from : {1}".format(dd,",".join(distanceFunctionDict.keys())),"red"))

