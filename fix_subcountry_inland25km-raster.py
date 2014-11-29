import arcpy, os

# C:\Python27\ArcGISx6410.2\python.exe G:\ohi-webapps\fix_subcountry_inland25km-raster.py

mask = 'N:/model/GL-NCEAS-Halpern2008/data/masked_model.tif'
key  = 'usa'

for key in ('rus','spm'):

    fc   = 'N:/git-annex/clip-n-ship/%s/spatial/rgn_inland25km_gcs.shp' % key
    tif  = 'N:/git-annex/clip-n-ship/%s/spatial/rgn_inland25km_mol.tif' % key

    # projections
    sr_mol = arcpy.SpatialReference('Mollweide (world)') # projected Mollweide (54009)
    sr_gcs = arcpy.SpatialReference('WGS 1984')          # geographic coordinate system WGS84 (4326)

    # project to raster, setting snap raster first to sp_[mol|gcs].tif
    arcpy.env.outputCoordinateSystem = mask
    arcpy.env.snapRaster             = mask
    arcpy.env.extent                 = mask
    arcpy.env.workspace              = os.path.dirname(tif)
    arcpy.env.scratchWorkspace       = 'C:/tmp'

    # convert
    cellsize = arcpy.GetRasterProperties_management(mask,'CELLSIZEX') # 934.478877011219
    arcpy.FeatureToRaster_conversion(fc, 'rgn_id', tif, cellsize)     # meters
