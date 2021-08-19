#!/usr/bin/env python3

from sys import argv

if not len(argv) == 6:
    print("contour.py: Error: contour.py <GPKG Input File> <PNG Output File> <FG colour> <BG colour> <Line Thickness>")
    print("Colors are given in hex RGB or RGBA values")
    exit(1)

from qgis.core import (
    QgsApplication,
    QgsMapRendererParallelJob,
    QgsMapSettings,
    QgsProject,
    QgsVectorLayer,
)

from qgis.PyQt.QtGui import QColor
from qgis.PyQt.QtCore import QSize

QgsApplication.setPrefixPath('/usr', True)

path_to_gpkg = argv[1]
path_to_png = argv[2]

gpkg_layer = path_to_gpkg + "|layername=Contour"
vlayer = QgsVectorLayer(gpkg_layer, "Contour", "ogr")
QgsProject.instance().addMapLayer(vlayer)
vlayer.renderer().symbol().setColor(QColor(argv[3]))
vlayer.renderer().symbol().setWidth(float(argv[5]))

settings = QgsMapSettings()
settings.setLayers([vlayer])
settings.setBackgroundColor(QColor(argv[4]))
settings.setOutputSize(QSize(1000, 1000))
settings.setExtent(vlayer.extent())
settings.setOuputDpi = 100

render = QgsMapRendererParallelJob(settings)
render.start()
render.waitForFinished()
render.renderedImage().save(path_to_png, "png")
