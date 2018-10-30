# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'mainwindow.ui'
#
# Created by: PyQt5 UI code generator 5.10
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets
import os, json,glob
from gmatch4py import *

class Ui_MainWindow(object):

    def setupUi(self, MainWindow):

        self.graph_input_dir=""
        self.selected_input_fn=""
        self.output_dir=""

        self.available_algs=['BP_2','BagOfCliques','BagOfNodes','GraphEditDistance','GreedyEditDistance','HED','Jaccard','MCS','VertexEdgeOverlap','VertexRanking', 'WeisfeleirLehmanKernel']
        
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(1000, 661)
        self.centralWidget = QtWidgets.QWidget(MainWindow)
        self.centralWidget.setObjectName("centralWidget")
        self.textBrowser = QtWidgets.QTextBrowser(self.centralWidget)
        self.textBrowser.setGeometry(QtCore.QRect(405, 31, 591, 551))
        self.textBrowser.setObjectName("textBrowser")
        self.label = QtWidgets.QLabel(self.centralWidget)
        self.label.setGeometry(QtCore.QRect(410, 10, 100, 16))
        self.label.setObjectName("label")
        self.graph_dir_but = QtWidgets.QPushButton(self.centralWidget)
        self.graph_dir_but.setGeometry(QtCore.QRect(280, 90, 113, 32))
        self.graph_dir_but.setObjectName("graph_dir_but")
        self.label_2 = QtWidgets.QLabel(self.centralWidget)
        self.label_2.setGeometry(QtCore.QRect(10, 70, 200, 16))
        self.label_2.setObjectName("label_2")
        self.selected_fn_but = QtWidgets.QPushButton(self.centralWidget)
        self.selected_fn_but.setGeometry(QtCore.QRect(280, 160, 113, 32))
        self.selected_fn_but.setObjectName("selected_fn_but")
        self.label_3 = QtWidgets.QLabel(self.centralWidget)
        self.label_3.setGeometry(QtCore.QRect(10, 140, 300, 16))
        self.label_3.setObjectName("label_3")
        self.generate_button = QtWidgets.QPushButton(self.centralWidget)
        self.generate_button.setGeometry(QtCore.QRect(20, 540, 113, 32))
        self.generate_button.setObjectName("generate_button")
        self.label_4 = QtWidgets.QLabel(self.centralWidget)
        self.label_4.setGeometry(QtCore.QRect(10, 210, 131, 16))
        self.label_4.setObjectName("label_4")
        self.ouptut_dir_but = QtWidgets.QPushButton(self.centralWidget)
        self.ouptut_dir_but.setGeometry(QtCore.QRect(280, 230, 113, 32))
        self.ouptut_dir_but.setObjectName("ouptut_dir_but")
        self.all_alg = QtWidgets.QCheckBox(self.centralWidget)
        self.all_alg.setGeometry(QtCore.QRect(10, 500, 200, 20))
        self.all_alg.setObjectName("all_alg")
        self.save_button = QtWidgets.QPushButton(self.centralWidget)
        self.save_button.setGeometry(QtCore.QRect(150, 540, 200, 32))
        self.save_button.setObjectName("save_button")
        self.label_5 = QtWidgets.QLabel(self.centralWidget)
        self.label_5.setGeometry(QtCore.QRect(10, 30, 121, 31))
        self.label_5.setObjectName("label_5")
        self.experiment_name = QtWidgets.QLineEdit(self.centralWidget)
        self.experiment_name.setGeometry(QtCore.QRect(130, 30, 231, 31))
        self.experiment_name.setObjectName("experiment_name")
        self.graph_dir_label = QtWidgets.QLineEdit(self.centralWidget)
        self.graph_dir_label.setGeometry(QtCore.QRect(10, 90, 261, 31))
        self.graph_dir_label.setObjectName("graph_dir_label")
        self.selected_file_label = QtWidgets.QLineEdit(self.centralWidget)
        self.selected_file_label.setGeometry(QtCore.QRect(10, 160, 261, 31))
        self.selected_file_label.setObjectName("selected_file_label")
        self.output_dir_label = QtWidgets.QLineEdit(self.centralWidget)
        self.output_dir_label.setGeometry(QtCore.QRect(10, 230, 261, 31))
        self.output_dir_label.setText("")
        self.output_dir_label.setObjectName("output_dir_label")
        self.alg_selector = QtWidgets.QListWidget(self.centralWidget)
        self.alg_selector.setGeometry(QtCore.QRect(10, 300, 256, 192))
        self.alg_selector.setObjectName("alg_selector")
        self.alg_selector.setSelectionMode(QtWidgets.QListWidget.MultiSelection)
        self.label_6 = QtWidgets.QLabel(self.centralWidget)
        self.label_6.setGeometry(QtCore.QRect(10, 280, 221, 16))
        self.label_6.setObjectName("label_6")
        MainWindow.setCentralWidget(self.centralWidget)
        self.menuBar = QtWidgets.QMenuBar(MainWindow)
        self.menuBar.setGeometry(QtCore.QRect(0, 0, 1000, 22))
        self.menuBar.setObjectName("menuBar")
        MainWindow.setMenuBar(self.menuBar)
        self.mainToolBar = QtWidgets.QToolBar(MainWindow)
        self.mainToolBar.setObjectName("mainToolBar")
        MainWindow.addToolBar(QtCore.Qt.TopToolBarArea, self.mainToolBar)
        self.statusBar = QtWidgets.QStatusBar(MainWindow)
        self.statusBar.setObjectName("statusBar")
        MainWindow.setStatusBar(self.statusBar)

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

        for item in self.available_algs:
            self.alg_selector.addItem(item)

        self.graph_dir_but.clicked.connect(self.get_graph_input_dir)
        self.ouptut_dir_but.clicked.connect(self.get_res_output_dir)
        self.selected_fn_but.clicked.connect(self.get_selected_file)

        self.generate_button.clicked.connect(self.generate_conf)
        self.save_button.clicked.connect(self.file_save)

    def openDirNameDialog(self,title):    
        fileName = QtWidgets.QFileDialog.getExistingDirectory(None,title)
        if not fileName:
            return ""
        return str(fileName)

    def openFileNameDialog(self,title):    
        options = QtWidgets.QFileDialog.Options()
        options |= QtWidgets.QFileDialog.DontUseNativeDialog
        filename,_ = QtWidgets.QFileDialog.getOpenFileNames(None)
        if filename:
            return filename
        else:
            return ""

    def get_graph_input_dir(self):
        fn = self.openDirNameDialog("Graph Input Dir")
        self.graph_dir_label.setText(fn)
        self.graph_input_dir=fn

    def get_res_output_dir(self):
        fn=self.openDirNameDialog("Results Output Dir")
        self.output_dir_label.setText(fn)
        self.output_dir=fn

    def get_selected_file(self):
        fn=self.openFileNameDialog("SelectGraph File")
        self.selected_file_label.setText(fn[0])
        self.selected_input_fn=fn[0]

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "Générateur de Configuration pour Gmatch4py"))
        self.label.setText(_translate("MainWindow", "Configuration:"))
        self.graph_dir_but.setText(_translate("MainWindow", "Parcourir"))
        self.label_2.setText(_translate("MainWindow", "Dossier contenant les graphes"))
        self.selected_fn_but.setText(_translate("MainWindow", "Parcourir"))
        self.label_3.setText(_translate("MainWindow", "Fichier contenant les graphes sélectionnés"))
        self.generate_button.setText(_translate("MainWindow", "Générer"))
        self.save_button.setText(_translate("MainWindow", "Sauvegarder la configuration"))
        self.label_4.setText(_translate("MainWindow", "Dossier de Sortie"))
        self.ouptut_dir_but.setText(_translate("MainWindow", "Parcourir"))
        self.all_alg.setText(_translate("MainWindow", "Selectionnez tout ?"))
        self.label_5.setText(_translate("MainWindow", "Nom de l'expérimentation"))
        self.label_6.setText(_translate("MainWindow", "Sélectionnez les algorithmes :"))



    def file_save(self):
        name,_ = QtWidgets.QFileDialog.getSaveFileName(None, 'Sauvegarder la configuration')
        print(name)
        if name:
            file = open(name,'w')
            text = self.generate_conf()[1]
            file.write(text)
            file.close()
            msg=QtWidgets.QMessageBox()
            msg.setText("Sauvegarde")
            msg.setInformativeText("Sauvegarde Réussie")
            msg.setWindowTitle("Sauvegarde")
            msg.setStandardButtons(QtWidgets.QMessageBox.Ok)
            msg.exec_()

    def generate_conf(self):
        conf= {
            "experiment_name":self.experiment_name.text(),
            "input_graph_dir":self.graph_input_dir,
            "input_graph_sub_dirs":[dir_ for dir_ in next(os.walk(self.graph_input_dir))[1] if next(os.walk(self.graph_input_dir))[1]],
            "selected_graphs":(True if self.selected_input_fn else False),
            "selected_graph_input_filename":self.selected_input_fn,
            "algorithms_selected": [item.text() for item in self.alg_selector.selectedItems()] if not self.all_alg.isChecked() else self.available_algs,
            "execute_all_algorithms": self.all_alg.isChecked()
        }
        str_conf=json.dumps(conf,indent=2)
        self.textBrowser.setPlainText(str_conf)
        return conf,str_conf

def run_conf_generator():
    import sys
    app = QtWidgets.QApplication(sys.argv)
    MainWindow = QtWidgets.QMainWindow()
    ui = Ui_MainWindow()
    ui.setupUi(MainWindow)
    MainWindow.show()
    sys.exit(app.exec_())

if __name__ == "__main__":
    run_conf_generator()

