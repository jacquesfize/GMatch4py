# coding = utf-8


# coding = utf-8
import glob
from gmatch4py import *
from gmatch4py.helpers.reader import import_dir
from gmatch4py import GraphEditDistance as GED2
from gmatch4py.base import Base

import argparse, os, sys, re, json, logging
import threading
from queue import Queue
import datetime

from functools import wraps


def objectify(func):
    """Mimic an object given a dictionary.

    Given a dictionary, create an object and make sure that each of its
    keys are accessible via attributes.
    If func is a function act as decorator, otherwise just change the dictionary
    and return it.
    :param func: A function or another kind of object.
    :returns: Either the wrapper for the decorator, or the changed value.

    Example::

    >>> obj = {'old_key': 'old_value'}
    >>> oobj = objectify(obj)
    >>> oobj['new_key'] = 'new_value'
    >>> print oobj['old_key'], oobj['new_key'], oobj.old_key, oobj.new_key

    >>> @objectify
    ... def func():
    ...     return {'old_key': 'old_value'}
    >>> obj = func()
    >>> obj['new_key'] = 'new_value'
    >>> print obj['old_key'], obj['new_key'], obj.old_key, obj.new_key

    """

    def create_object(value):
        """Create the object.

        Given a dictionary, create an object and make sure that each of its
        keys are accessible via attributes.
        Ignore everything if the given value is not a dictionary.
        :param value: A dictionary or another kind of object.
        :returns: Either the created object or the given value.

        """
        if isinstance(value, dict):
            # Build a simple generic object.
            class Object(dict):
                def __setitem__(self, key, val):
                    setattr(self, key, val)
                    return super(Object, self).__setitem__(key, val)

            # Create that simple generic object.
            ret_obj = Object()
            # Assign the attributes given the dictionary keys.
            for key, val in value.items():
                if isinstance(val,dict):
                    ret_obj[key] = objectify(val)
                else:
                    ret_obj[key] = val
                setattr(ret_obj, key, val)
            return ret_obj
        else:
            return value

    # If func is a function, wrap around and act like a decorator.
    if hasattr(func, '__call__'):
        @wraps(func)
        def wrapper(*args, **kwargs):
            """Wrapper function for the decorator.

            :returns: The return value of the decorated function.

            """
            value = func(*args, **kwargs)
            return create_object(value)

        return wrapper

    # Else just try to objectify the value given.
    else:
        return create_object(func)


logging.basicConfig(
filename="{0}.csv".format(datetime.datetime.now().strftime("%Y_%m_%d__%H_%M_%S")),
format="%(message)s,%(asctime)s",
level=logging.DEBUG
)

def compute_matrix(config,graphs,selected,dir):

    for class_ in config.algorithms_selected:
        class_=eval(class_)
        logging.info(msg="C_S,BEG,\"{0}\"".format(class_.__name__))
        print("Computing the Similarity Matrix for {0}".format(class_.__name__))

        if class_ in (GraphEditDistance, BP_2, GreedyEditDistance, HED):
            comparator = class_(1, 1, 1, 1)
        elif class_ == GED2:
            comparator = class_(1, 1, 1, 1,weighted=True)
        elif class_ == WeisfeleirLehmanKernel:
            comparator = class_(h=2)
        else:
            comparator=class_()
        matrix = comparator.compare(graphs, selected)
        matrix = comparator.similarity(matrix)

        logging.info(msg="C_S,DONE,\"{0}\"".format(class_.__name__))
        output_fn="{0}/{1}_{2}_{3}.npy".format(
            config.output_dir.rstrip("/"),
            class_.__name__,os.path.basename(dir),
            config.experiment_name.replace(" ","_").lower()
        )
        print(output_fn)
        logging.info(msg="M_S,BEG,\"{0}\"".format(class_.__name__))
        np.save(output_fn,matrix)
        logging.info(msg="M_S,DONE,\"{0}\"".format(class_.__name__))
        print("Matrix Saved")

def run(config_filename):

    config=objectify(json.load(open(config_filename)))


    if not os.path.exists(config.input_graph_dir):
        print("Input graph directory doesn't exist!")
        sys.exit(1)

    if not os.path.exists(config.output_dir):
        print("Output matrix directory doesn't exist!")
        print("Creating directory")
        os.makedirs(args.output_dir)
        print("Directory created")

    selected=None
    if config.selected_graphs:
        selected=json.load(open(config.selected_graph_input_filename))

    if config.input_graph_sub_dirs:
        dirs=[os.path.join(config.input_graph_dir,sub) for sub in config.input_graph_sub_dirs]
    else:
        dirs=[config.input_graph_dir]
    for dir in dirs:
        logging.info(msg="L_G,BEGIN,\"\"")
        graphs = import_dir(dir)
        logging.info(msg="L_G,DONE,\"\"")
        threading.Thread(target=compute_matrix,args=(config,graphs,selected,dir)).start()


    #json.dump(mapping_files_to_graphs,open("{0}/{1}".format(args.matrix_output_dir.rstrip("/"),"metadata.json")))
    print("Done")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("configuration_file")
    args = parser.parse_args()
    run(args.configuration_file)