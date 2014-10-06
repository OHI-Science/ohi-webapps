# Run on cmd: C:\Python27\ArcGISx6410.2\python.exe G:\ohi-webapps\create_subcountry_regions.py

# packages
import arcpy, os, socket, numpy, numpy.lib.recfunctions, pandas, time, re, shutil


# download https://bootstrap.pypa.io/ez_setup.py
# download https://bootstrap.pypa.io/git_pip.py
# C:\Python27\ArcGIS10.2\python C:\Users\visitor\Downloads\ez_setup.py
# C:\Python27\ArcGIS10.2\python C:\Users\visitor\Downloads\get-pip.py
# C:\Python27\ArcGIS10.2\Scripts\pip install pandas
# error: Microsoft Visual C++ 9.0 is required (Unable to find vcvarsall.bat). Get it from http://aka.ms/vcpython27
# pip install pandas
# cd "C:\Users\visitor\Downloads\dist\pandas-0.14.1"
# C:\Python27\ArcGIS10.2\python setup.py install --user
# WORKED: pandas‑0.14.1.win32‑py2.6.exe at http://www.lfd.uci.edu/~gohlke/pythonlibs/#pandas
# import pandas -> ValueError: numpy.dtype has the wrong size, try recompiling
# WORKED: numpy‑MKL‑1.9.0.win32‑py2.7.exe at http://www.lfd.uci.edu/~gohlke/pythonlibs/#pandas


# paths on NCEAS vis lab machine BUMBLEBEE (and # salacia - BB's Vmware WinXP)
# mapped N: to \\neptune\data_edit
wd       = r'C:\Users\visitor\Documents\github\ohi-webapps'       # 'G:/ohi-webapps'
dir_tmp  = r'C:\Users\visitor\bbest\ohi-webapps'                  # r'C:\tmp\ohi-webapps'
gdb      = dir_tmp + '/subcountry.gdb'
dir_rgn  = r'N:\git-annex\Global\NCEAS-Regions_v2014\data' 
fc_gadm  = r'N:\stable\GL-GADM-AdminAreas_v2\data\gadm2.gdb\gadm2' # r'C:\tmp\Global\GL-GADM-AdminAreas_v2\data\gadm2.gdb\gadm2'
#gdb_rgn  = r'C:\tmp\Global\NCEAS-Regions_v2014\geodb.gdb'        # neptune_data:git-annex/Global/NCEAS-Regions_v2014/geodb.gdb
dir_dest = r'N:\git-annex\clip-n-ship'

# buffer units dictionary
buffers = ['offshore3nm','offshore1km','inland1km','inland25km']
buf_units_d = {'nm':'NauticalMiles',
               'km':'Kilometers',
               'mi':'Miles'}

# projections
sr_mol = arcpy.SpatialReference('Mollweide (world)') # projected Mollweide (54009)
sr_gcs = arcpy.SpatialReference('WGS 1984')          # geographic coordinate system WGS84 (4326)

# environment
os.chdir(wd)
if not os.path.exists('tmp'):  os.makedirs('tmp')
#if not os.path.exists('data'): os.makedirs('data')
if not os.path.exists(dir_tmp):  os.makedirs(dir_tmp)
if not arcpy.Exists(gdb):      arcpy.CreateFileGDB_management(os.path.dirname(gdb), os.path.basename(gdb))
arcpy.env.overwriteOutput        = True
arcpy.env.workspace              = gdb

# copy features to tmp gdb
for fc in [fc_gadm, dir_rgn + '/rgn_gcs.shp']:
  arcpy.CopyFeatures_management(fc, os.path.splitext(os.path.basename(fc))[0])

# get list of rgn countries
df_rgn = pandas.DataFrame(arcpy.da.TableToNumPyArray(
    'rgn_gcs',
    ['OBJECTID','rgn_id','rgn_name'],
    "rgn_type = 'eez'"))

# get list of gadm countries with counts of polygons
s_gadm = pandas.Series(
    pandas.DataFrame(
        arcpy.da.TableToNumPyArray(
            'gadm2',
            ['NAME_0'])).groupby('NAME_0', as_index=False).size(),
    name = 'gadm_count')
df_gadm = pandas.DataFrame(s_gadm)
df_gadm['NAME_0'] = df_gadm.index

# left join gadm and rgns
df_rgn = pandas.merge(
    df_rgn, df_gadm,
    how='left', left_on='rgn_name', right_on='NAME_0')

# track regions missing gadm
df_rgn[~df_rgn.rgn_name.isin(df_rgn.NAME_0)].to_csv('tmp/rgn_notmatching_gadm.csv', index=False, encoding='utf-8')
df_rgn = df_rgn[df_rgn.rgn_name.isin(df_rgn.NAME_0)]

# track regions with no sub-country gadm provinces, ie gadm_count = 1 
df_rgn[df_rgn.gadm_count == 1].to_csv('tmp/rgn_only1_gadm.csv', index=False, encoding='utf-8')
df_rgn = df_rgn[df_rgn.gadm_count > 1]

# regions to not do for various reasons, eg already done
rgn_skip = ['Israel']
df_rgn = df_rgn[~df_rgn.rgn_name.isin(rgn_skip)]
df_rgn.to_csv('tmp/rgn_ok_gadm.csv', index=False, encoding='utf-8')

# iterate over regions
for rgn in sorted(tuple(df_rgn['rgn_name']))[1:6]: #rgn = sorted(tuple(df_rgn['rgn_name']))[0]

    # make output dir
    print rgn
    dir_tmp_rgn = '%s/data/%s' % (dir_tmp, rgn.replace(' ', '_'))
    dir_dest_rgn = '%s/data/%s' % (dir_dest, rgn.replace(' ', '_'))
    if not os.path.exists(dir_tmp_rgn): os.makedirs(dir_tmp_rgn)
    if not os.path.exists(dir_dest_rgn): os.makedirs(dir_dest_rgn)

    # select rgn
    arcpy.env.outputCoordinateSystem = sr_mol
    arcpy.Select_analysis(gdb_rgn + '/rgn_offshore_gcs', 'eez',     '"rgn_name" = \'%s\'' % rgn)
    arcpy.Select_analysis(gdb_rgn + '/rgn_inland_gcs',   'land',    '"rgn_name" = \'%s\'' % rgn)
    arcpy.Select_analysis(gdb_rgn + '/rgn_gcs',          'eezland', '"rgn_name" = \'%s\'' % rgn)
    arcpy.Select_analysis(fc_gadm,                       'gadm',    '"NAME_0"   = \'%s\'' % rgn)

    # remove fields which are from global analysis, not to be confused with subcountry fields
    for fld in ['rgn_type','rgn_id','rgn_name','rgn_key','area_km2']:
        for fc in ['eez','land','eezland']:
            arcpy.DeleteField_management(fc, fld)

    # get administrative land
    arcpy.Clip_analysis('gadm', 'land', 'gadm_land')
    arcpy.Dissolve_management('gadm_land', 'states', 'NAME_1')
     
    # create theissen polygons used to split slivers
    arcpy.Densify_edit('states', 'DISTANCE', '1 Kilometers')
    arcpy.FeatureVerticesToPoints_management('states', 'states_pts', 'ALL')
     
    # delete interior points for faster thiessen rendering
    arcpy.Dissolve_management('states', 'states_d')
    arcpy.MakeFeatureLayer_management('states_pts', 'lyr_states_pts')
    arcpy.SelectLayerByLocation_management('lyr_states_pts', 'WITHIN_CLEMENTINI', 'states_d')
    arcpy.DeleteFeatures_management('lyr_states_pts')
     
    # generate thiessen polygons of gadm for intersecting with land slivers
    arcpy.env.extent = 'eezland'
    arcpy.CreateThiessenPolygons_analysis('states_pts', 'states_t', 'ALL')
    arcpy.Dissolve_management('states_t', 'states_t_d', 'NAME_1')
    arcpy.RepairGeometry_management('states_t_d')

    # add detailed interior back
    arcpy.Erase_analysis('states_t_d', 'states', 'states_t_d_e')
    arcpy.Merge_management(['states', 'states_t_d_e'], 'states_t_d_e_m')
    arcpy.Dissolve_management('states_t_d_e_m', 'thiessen', 'NAME_1')
     
    # rgn_offshore: rename NAME_1 to rgn_name
    print 'rgn_offshore...'
    arcpy.Intersect_analysis(['eez', 'thiessen'], 'eez_t', 'NO_FID')
    arcpy.Dissolve_management('eez_t', 'rgn_offshore_mol', 'NAME_1')
    arcpy.AddField_management('rgn_offshore_mol', 'rgn_name', 'TEXT')
    arcpy.CalculateField_management('rgn_offshore_mol', 'rgn_name', '!NAME_1!', 'PYTHON_9.3')
    arcpy.DeleteField_management('rgn_offshore_mol', 'NAME_1')
     
    # rgn_offshore: assign rgn_id by ascending y coordinate
    arcpy.AddField_management('rgn_offshore_mol', 'centroid_y', 'FLOAT')
    arcpy.CalculateField_management('rgn_offshore_mol', 'centroid_y', '!shape.centroid.y!', 'PYTHON_9.3')
    a = arcpy.da.TableToNumPyArray('rgn_offshore_mol', ['centroid_y','rgn_name'])
    a.sort(order=['centroid_y'], axis=0)
    a = numpy.lib.recfunctions.append_fields(a, 'rgn_id', range(1, a.size+1), usemask=False)
    arcpy.da.ExtendTable('rgn_offshore_mol', 'rgn_name', a[['rgn_name','rgn_id']], 'rgn_name', append_only=False)
    arcpy.DeleteField_management('rgn_offshore_mol', 'centroid_y')

    # rgn_inland
    print 'rgn_inland'
    arcpy.Intersect_analysis(['land', 'thiessen'], 'land_t', 'NO_FID')
    arcpy.Dissolve_management('land_t', 'rgn_inland_mol', 'NAME_1')
    arcpy.AddField_management('rgn_inland_mol', 'rgn_name', 'TEXT')
    arcpy.CalculateField_management('rgn_inland_mol', 'rgn_name', '!NAME_1!', 'PYTHON_9.3')
    arcpy.DeleteField_management('rgn_inland_mol', 'NAME_1')
    # rgn_inland: assign rgn_id
    arcpy.da.ExtendTable('rgn_inland_mol', 'rgn_name', a[['rgn_name','rgn_id']], 'rgn_name', append_only=False)

    # save
    arcpy.CopyFeatures_management('rgn_inland_mol', dir_tmp_rgn + '/rgn_inland_mol.shp')
    arcpy.CopyFeatures_management('rgn_offshore_mol', dir_tmp_rgn + '/rgn_offshore_mol.shp')

    # loop through buffers
    for buf in buffers:
    #buf = buffers[0]

        print buf
        rgn_buf_mol = '%s/rgn_%s_mol' % (gdb_rgn, buf)
        buf_zone, buf_dist, buf_units = re.search('(\\D+)(\\d+)(\\D+)', buf).groups()    

        if buf_zone == 'inland':
            arcpy.Intersect_analysis(['rgn_inland_mol', rgn_buf_mol], 'buf_t', 'NO_FID')
        elif buf_zone == 'offshore':
            arcpy.Intersect_analysis(['rgn_offshore_mol', rgn_buf_mol], 'buf_t', 'NO_FID')
        else:
            stop('The buf_zone "%s" is not handled by this function.' % buf_zone)
        arcpy.Dissolve_management('buf_t', 'buf_t_d', 'rgn_name')
        arcpy.da.ExtendTable('buf_t_d', 'rgn_name', a[['rgn_name','rgn_id']], 'rgn_name', append_only=False)
        arcpy.CopyFeatures_management('buf_t_d', '%s/rgn_%s_mol.shp' % (dir_tmp_rgn, buf))
        
    # project shapefiles to gcs, calculate area and export csv
    arcpy.env.workspace = dir_tmp_rgn
    arcpy.env.outputCoordinateSystem = sr_gcs
    for fc_mol in sorted(arcpy.ListFeatureClasses('rgn_*_mol.shp')):
        print fc_mol
        fc_gcs = fc_mol.replace('_mol', '_gcs')
        csv = os.path.splitext(fc_gcs.replace('_gcs', ''))[0] + '_data.csv'
        arcpy.Project_management(fc_mol, fc_gcs, sr_gcs)
        arcpy.RepairGeometry_management(fc_gcs)
        arcpy.AddField_management(fc_gcs, 'area_km2', 'FLOAT')
        arcpy.CalculateField_management(fc_gcs, 'area_km2', '!shape.geodesicArea@squarekilometers!', 'PYTHON_9.3')
        d = pandas.DataFrame(arcpy.da.TableToNumPyArray(fc_gcs, ['rgn_id','rgn_name','area_km2']))
        d.to_csv('rgn_%s_data.csv' % (wd, buf), index=False, encoding='utf-8')

    ### Skipping simplify b/c at least for Albania trial decent PAEK tolerance of 0.01 actually producing larger *.shp vs original
    ### simplify offshore to geojson for rendering in toolbox
    ##arcpy.env.outputCoordinateSystem = sr_gcs
    ##arcpy.RepairGeometry_management('rgn_offshore_gcs.shp')
    ##arcpy.cartography.SmoothPolygon('rgn_offshore_gcs.shp', 'rgn_offshore_smooth_gcs.shp', 'PAEK', 0.01, 'FIXED_ENDPOINT', 'FLAG_ERRORS')
    ##arcpy.env.outputCoordinateSystem = sr_mol # reset coordinate system
    ##arcpy.cartography.SimplifyPolygon('rgn_offshore_gcs.shp', 'rgn_offshore_simplify_gcs.shp', 'BEND_SIMPLIFY', 1000, 0, 'FLAG_ERRORS', 'KEEP_COLLAPSED_POINTS')

    # reset workspace and coordinate system
    arcpy.env.outputCoordinateSystem = sr_gcs
    arcpy.env.workspace              = gdb

    # copy to destination        
    shutil.rmtree(dir_dest_rgn) # empty it
    shutil.copytree(dir_tmp_rgn, dir_dest_rgn) # copy recursively
