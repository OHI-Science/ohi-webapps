# Run on cmd:
#   salacia:
#     C:\Python27\ArcGISx6410.2\python.exe G:\ohi-webapps\create_subcountry_regions.py 
#   bumblebee in NCEAS Viz Lab:
#     C:\Python27\ArcGIS10.2\python.exe C:\Users\visitor\Documents\github\ohi-webapps\create_subcountry_regions.py
#
# estimating completion:
#   062 of 153: Indonesia (21:54:00) to 081 of 153: Mayotte (17:56:55) ~ 1 / hr, ~ 3 days left


import arcpy, os, socket, numpy, numpy.lib.recfunctions, pandas, time, re, shutil

# paths on NCEAS vis lab machine BUMBLEBEE (and # salacia - BB's Vmware WinXP)
# mapped N: to \\neptune\data_edit
wd       = r'C:\Users\visitor\Documents\github\ohi-webapps'       # 'G:/ohi-webapps'
dir_tmp  = r'C:\Users\visitor\bbest\ohi-webapps'                  # r'C:\tmp\ohi-webapps'
gdb      = dir_tmp + '\\subcountry.gdb'
dir_rgn  = r'N:\git-annex\Global\NCEAS-Regions_v2014\data' 
fc_gadm  = r'N:\stable\GL-GADM-AdminAreas_v2\data\gadm2.gdb\gadm2' # r'C:\tmp\Global\GL-GADM-AdminAreas_v2\data\gadm2.gdb\gadm2'
#gdb_rgn  = r'C:\tmp\Global\NCEAS-Regions_v2014\geodb.gdb'        # neptune_data:git-annex/Global/NCEAS-Regions_v2014/geodb.gdb
dir_dest = r'N:\git-annex\clip-n-ship'
mask_mol = r'N:\model\GL-NCEAS-Halpern2008\data\masked_model.tif'

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
if not os.path.exists(dir_tmp):  os.makedirs(dir_tmp)
if not arcpy.Exists(gdb):
    print 'creating gdb'
    arcpy.CreateFileGDB_management(os.path.dirname(gdb), os.path.basename(gdb))
arcpy.env.overwriteOutput        = True
arcpy.env.workspace              = gdb
arcpy.SetLogHistory(True) # C:\Users\visitor\AppData\Roaming\ESRI\Desktop10.2\ArcToolbox\History

# copy shapefiles to local gdb
arcpy.env.outputCoordinateSystem = sr_gcs
shps_rgn = ['rgn_gcs'] + ['rgn_%s_gcs' % b for b in buffers]
for fc_rgn in [fc_gadm] + ['%s\\%s.shp' % (dir_rgn, x) for x in shps_rgn]:
    fc_gdb = os.path.splitext(os.path.basename(fc_rgn))[0]
    if not arcpy.Exists(fc_gdb):
        print 'copying', fc_gdb
        arcpy.CopyFeatures_management(fc_rgn, fc_gdb)

    # convert gcs to mol
    fc_mol = fc_gdb.replace('_gcs', '_mol')
    if not arcpy.Exists(fc_mol):
        print 'projecting', fc_mol
        arcpy.Project_management(fc_gdb, fc_mol, sr_mol)

# copy rasters locally
m_mol = '%s/%s' % (dir_tmp, os.path.basename(mask_mol))
if not arcpy.Exists(m_mol):
    print 'copying mask_mol'
    arcpy.Copy_management(mask_mol, m_mol)
cellsize = arcpy.GetRasterProperties_management(m_mol,'CELLSIZEX') # 934.478877011219
        
# get admin level 1 (sub country) spatial units        
if not arcpy.Exists('gadm2_admin1'):
    print 'dissolving gadm2 to gadm2_admin1'
    arcpy.Dissolve_management('gadm2', 'gadm2_admin1', ['NAME_0','NAME_1'])
        
# get list of rgn countries
print 'getting lists of countries rgn_gcs vs gadm2 (%s)' % time.strftime('%H:%M:%S')
df_rgn = pandas.DataFrame(arcpy.da.TableToNumPyArray(
    'rgn_gcs',
    ['OBJECTID','rgn_id','rgn_name'],
    "rgn_type = 'eez'"))

# get list of gadm countries with counts of polygons
s_gadm = pandas.Series(
    pandas.DataFrame(
        arcpy.da.TableToNumPyArray(
            'gadm2_admin1',
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

# skip region if already folder in local output directory
##rgns_do = [] # ['Canada']
##rgns_done = [x.replace('_',' ') for x in os.listdir(dir_tmp + '/data') if x not in rgns_do]
##df_rgn = df_rgn[~df_rgn.rgn_name.isin(rgns_done)]
# DEBUG to REDO
#df_rgn = df_rgn[df_rgn.rgn_name.isin(rgns_done)]

# iterate over regions
print 'looping over countries (n=%d)' % len(df_rgn)
for i, rgn in enumerate(sorted(tuple(df_rgn['rgn_name']))): # i=0; rgn = sorted(tuple(df_rgn['rgn_name']))[i]
#for i, rgn in enumerate(sorted(tuple(df_rgn['rgn_name']))[3:4]): # i=0; rgn = sorted(tuple(df_rgn['rgn_name']))[i]

    # DEBUG! bypass ones already done
    if i < 93:
        continue

    # make output dir
    print '\n%03d of %d: %s (%s)' % (i,  len(df_rgn), rgn, time.strftime('%H:%M:%S'))
    dir_tmp_rgn = '%s/data/%s/spatial' % (dir_tmp, rgn.replace(' ', '_'))
    dir_dest_rgn = '%s/%s/spatial' % (dir_dest, rgn.replace(' ', '_'))
    if not os.path.exists(dir_tmp_rgn): os.makedirs(dir_tmp_rgn)
    if not os.path.exists(dir_dest_rgn): os.makedirs(dir_dest_rgn)
    c_offshore_dest = dir_dest_rgn + '/rgn_offshore_mol.shp'
    c_inland_dest = dir_dest_rgn + '/rgn_inland_mol.shp'
        
    # set env
    arcpy.env.workspace = gdb
    arcpy.env.extent = 'rgn_gcs'
    arcpy.env.outputCoordinateSystem = sr_mol
    
    # skip if have all desired outputs: theissen, offshore, inland, buffers
    c_buffers = ['%s/rgn_%s_mol.shp' % (dir_dest_rgn, buf) for buf in buffers]
    if sum([not arcpy.Exists(x) for x in [c_offshore_dest, c_inland_dest] + c_buffers]) > 0:

        # DEBUG!!!
        #if rgn != 'Canada':
        # delete existing country specific feature classes, compact, refresh
        for fc in arcpy.ListFeatureClasses('c_*') + arcpy.ListFeatureClasses('lyr_*'):
            arcpy.Delete_management(fc)

        try:
            print '  compacting gdb (%s)' % time.strftime('%H:%M:%S')
            arcpy.Compact_management(gdb)
        
            if not arcpy.Exists(c_offshore_dest) or not arcpy.Exists(c_inland_dest):
                print '  select (%s)' % time.strftime('%H:%M:%S')
                            
                # select rgn to country only, now in Mollweide projection
                arcpy.Select_analysis('rgn_gcs'    , 'c_eezland' ,                       "rgn_name = '%s'" % rgn)
                n = int(arcpy.GetCount_management('c_eezland').getOutput(0))
                if n == 0: 
                    print  '  EMPTY! skipping...'
                    continue
                arcpy.Select_analysis('rgn_gcs'     , 'c_eez'    , "rgn_type = 'eez'  AND rgn_name = '%s'" % rgn)
                arcpy.Select_analysis('rgn_gcs'     , 'c_land'   , "rgn_type = 'land' AND rgn_name = '%s'" % rgn)
                arcpy.Select_analysis('gadm2_admin1', 'c_gadm'   ,                         "NAME_0 = '%s'" % rgn)
                
                # remove fields which are from global analysis, not to be confused with subcountry fields
                for fld in ['rgn_type','rgn_id','rgn_name','rgn_key','area_km2']:
                    for fc in ['c_eezland','c_eez','c_land']:
                        if fld in [x.name for x in arcpy.ListFields(fc)]:
                            arcpy.DeleteField_management(fc, fld)
            
                # get administrative land
                arcpy.Clip_analysis('c_gadm', 'c_land', 'c_states')
                 
                # create theissen polygons used to split slivers
                arcpy.Densify_edit('c_states', 'DISTANCE', '1 Kilometers')
                arcpy.FeatureVerticesToPoints_management('c_states', 'c_states_pts', 'ALL')
                 
                # delete interior points for faster thiessen rendering
                arcpy.Dissolve_management('c_states', 'c_states_d')
                arcpy.MakeFeatureLayer_management('c_states_pts', 'lyr_c_states_pts')
                arcpy.SelectLayerByLocation_management('lyr_c_states_pts', 'WITHIN_CLEMENTINI', 'c_states_d')
                arcpy.DeleteFeatures_management('lyr_c_states_pts')
                 
                # generate thiessen polygons of gadm for intersecting with land slivers
                arcpy.env.extent = 'c_eezland'
                arcpy.CreateThiessenPolygons_analysis('c_states_pts', 'c_states_t', 'ALL')
                arcpy.Dissolve_management('c_states_t', 'c_states_t_d', 'NAME_1')
                arcpy.RepairGeometry_management('c_states_t_d')

                # add detailed interior back
                arcpy.Erase_analysis('c_states_t_d', 'c_states', 'c_states_t_d_e')
                arcpy.Merge_management(['c_states', 'c_states_t_d_e'], 'c_states_t_d_e_m')
                arcpy.Dissolve_management('c_states_t_d_e_m', 'c_thiessen', 'NAME_1')
                arcpy.RepairGeometry_management('c_thiessen')
            
            if not arcpy.Exists(c_offshore_dest):
                # rgn_offshore: rename NAME_1 to rgn_name
                print '  rgn_offshore, rgn_inland (%s)' % time.strftime('%H:%M:%S') 
                arcpy.Intersect_analysis(['c_eez', 'c_thiessen'], 'c_eez_t', 'NO_FID')
                arcpy.RepairGeometry_management('c_eez_t')
                arcpy.Dissolve_management('c_eez_t', 'c_rgn_offshore_mol', 'NAME_1')
                arcpy.RepairGeometry_management('c_rgn_offshore_mol')
                arcpy.AddField_management('c_rgn_offshore_mol', 'rgn_name', 'TEXT')
                arcpy.CalculateField_management('c_rgn_offshore_mol', 'rgn_name', '!NAME_1!', 'PYTHON_9.3')
                arcpy.DeleteField_management('c_rgn_offshore_mol', 'NAME_1')
                 
                # rgn_offshore: assign rgn_id by ascending y coordinate
                arcpy.AddField_management('c_rgn_offshore_mol', 'centroid_y', 'FLOAT')
                arcpy.CalculateField_management('c_rgn_offshore_mol', 'centroid_y', '!shape.centroid.y!', 'PYTHON_9.3')
                a = arcpy.da.TableToNumPyArray('c_rgn_offshore_mol', ['centroid_y','rgn_name'])
                a.sort(order=['centroid_y'], axis=0)
                a = numpy.lib.recfunctions.append_fields(a, 'rgn_id', range(1, a.size+1), usemask=False)
                arcpy.da.ExtendTable('c_rgn_offshore_mol', 'rgn_name', a[['rgn_name','rgn_id']], 'rgn_name', append_only=False)
                arcpy.DeleteField_management('c_rgn_offshore_mol', 'centroid_y')
                arcpy.CopyFeatures_management('c_rgn_offshore_mol', c_offshore_dest)
            else:
                print '  %s exists, copying into gdb (%s)' % (os.path.basename(c_offshore_dest), time.strftime('%H:%M:%S'))
                arcpy.CopyFeatures_management(c_offshore_dest, 'c_rgn_offshore_mol')
                
            if not arcpy.Exists(c_inland_dest):
                # rgn_inland
                arcpy.Intersect_analysis(['c_land', 'c_thiessen'], 'c_land_t', 'NO_FID')
                arcpy.RepairGeometry_management('c_land_t')
                arcpy.Dissolve_management('c_land_t', 'c_rgn_inland_mol', 'NAME_1')
                arcpy.RepairGeometry_management('c_rgn_inland_mol')
                arcpy.AddField_management('c_rgn_inland_mol', 'rgn_name', 'TEXT')
                arcpy.CalculateField_management('c_rgn_inland_mol', 'rgn_name', '!NAME_1!', 'PYTHON_9.3')
                arcpy.DeleteField_management('c_rgn_inland_mol', 'NAME_1')
                # rgn_inland: assign rgn_id
                arcpy.da.ExtendTable('c_rgn_inland_mol', 'rgn_name', a[['rgn_name','rgn_id']], 'rgn_name', append_only=False)
                arcpy.CopyFeatures_management('c_rgn_inland_mol', c_inland_dest)
            else:
                print '  %s exists, copying into gdb (%s)' % (os.path.basename(c_inland_dest), time.strftime('%H:%M:%S'))
                arcpy.CopyFeatures_management(c_inland_dest, 'c_rgn_inland_mol')

        except Exception as e:
            print e.message
            
            print '  prep FAILED! skipping to next country (%s)' % time.strftime('%H:%M:%S')
            
            # copy failed thiessen inputs
            for fc in set(arcpy.ListFeatureClasses('c_*')) - set(('c_buf_t','c_buf_t_d')):
                fc_f = 'f_%s_%s' % (rgn.replace(' ', '_'), fc[2:])
                if arcpy.Exists(fc) and not arcpy.Exists(fc_f):
                    arcpy.CopyFeatures_management(fc, fc_f)
                
        # loop through buffers
        print '  buffer intersecting (%s)' % time.strftime('%H:%M:%S')
        for buf in buffers: # buf = buffers[0]
                 
            rgn_buf_mol = '%s\\rgn_%s_mol' % (gdb, buf)
            buf_zone, buf_dist, buf_units = re.search('(\\D+)(\\d+)(\\D+)', buf).groups()    
            c_buf_dest = '%s/rgn_%s_mol.shp' % (dir_dest_rgn, buf)            
            
            # get region ids from offshore sh
            if not arcpy.Exists(c_offshore_dest):
                print '    table missing, breaking out of buffering: %s' % os.path.basename(c_offshore_dest)
                break
            tbl_rgns = arcpy.da.TableToNumPyArray(c_offshore_dest, ['rgn_name','rgn_id'])
            
            # delete existing country specific feature classes, compact, refresh
            for fc in ['c_buf_t', 'c_buf_t_d']:
                if arcpy.Exists(fc):
                    arcpy.Delete_management(fc)

            if not arcpy.Exists(c_buf_dest):
                print '    %s %s %s (%s)' % (buf_zone, buf_dist, buf_units, time.strftime('%H:%M:%S'))
                try:
                    if buf_zone == 'inland':
                        arcpy.Intersect_analysis(['c_rgn_inland_mol', rgn_buf_mol], 'c_buf_t', 'NO_FID')
                    elif buf_zone == 'offshore':
                        arcpy.Intersect_analysis(['c_rgn_offshore_mol', rgn_buf_mol], 'c_buf_t', 'NO_FID')
                    else:
                        stop('The buf_zone "%s" is not handled by this function.' % buf_zone)
                    arcpy.RepairGeometry_management('c_buf_t')
                    arcpy.Dissolve_management('c_buf_t', 'c_buf_t_d', 'rgn_name')
                    arcpy.RepairGeometry_management('c_buf_t_d')
                    arcpy.da.ExtendTable('c_buf_t_d', 'rgn_name', tbl_rgns[['rgn_name','rgn_id']], 'rgn_name', append_only=False)
                    arcpy.CopyFeatures_management('c_buf_t_d', c_buf_dest)
                except Exception as e:
                    print e.message
                
                    print '      buf intersect FAILED! copying buffer inputs (%s)' % time.strftime('%H:%M:%S')

                    # copy failed buffer inputs
                    for fc in ('c_buf_t','c_buf_t_d'):
                        fc_f = 'f_%s_%s_%s' % (rgn.replace(' ', '_'), buf, fc[2:])
                        if arcpy.Exists(fc) and not arcpy.Exists(fc_f):
                            arcpy.CopyFeatures_management(fc, fc_f)
                
                    continue
            else:
                #print '      %s exists, skipping (%s)' % (os.path.basename(c_buf_dest), time.strftime('%H:%M:%S'))
                pass
    else:
        print '  all inland/offshore/buffers exist, skip copying to gdb (%s)' % time.strftime('%H:%M:%S')

    try:
        # project to raster, setting snap raster first to sp_[mol|gcs].tif
        print '  rasterizing (%s)' % time.strftime('%H:%M:%S')
        arcpy.env.outputCoordinateSystem = m_mol
        arcpy.env.snapRaster = m_mol
        arcpy.env.extent = m_mol
        arcpy.env.workspace = dir_dest_rgn
        arcpy.env.scratchWorkspace = dir_tmp_rgn
        for fc in sorted(arcpy.ListFeatureClasses('rgn_*_mol.shp')):

            tif_mol = '%s.tif' % os.path.splitext(fc)[0]
            if not arcpy.Exists(tif_mol):
                print '    %s (%s)' % (os.path.basename(fc), time.strftime('%H:%M:%S'))
                tif_mol_tmp = '%s/%s' % (dir_tmp_rgn, os.path.basename(tif_mol))
                arcpy.FeatureToRaster_conversion(fc, 'rgn_id', tif_mol_tmp, cellsize) # meters
                arcpy.Copy_management(tif_mol_tmp, tif_mol)
                arcpy.Delete_management(tif_mol_tmp)
            else:
                #print '    %s found, skipping (%s)' % (os.path.basename(fc), time.strftime('%H:%M:%S'))
                pass

        # project shapefiles to gcs, calculate area and export csv
        arcpy.env.workspace = dir_dest_rgn
        arcpy.env.outputCoordinateSystem = sr_gcs
        print '  projecting (%s)' % time.strftime('%H:%M:%S')
        for fc_mol in sorted(arcpy.ListFeatureClasses('rgn_*_mol.shp')):

            fc_gcs = fc_mol.replace('_mol', '_gcs')
            csv = '%s/%s_data.csv' % (dir_dest_rgn, os.path.splitext(fc_gcs.replace('_gcs.shp', ''))[0])
            if not arcpy.Exists(fc_gcs):
                print '    %s (%s)' % (os.path.basename(csv), time.strftime('%H:%M:%S'))
                
                fc_mol_tmp = '%s/%s' % (gdb, os.path.basename(fc_mol))
                fc_gcs_tmp = '%s/%s' % (gdb, os.path.basename(fc_gcs))
                arcpy.DefineProjection_management(fc_mol, sr_mol)
                arcpy.CopyFeatures(fc_mol, fc_mol_tmp)                
                arcpy.Project_management(fc_mol_tmp, fc_gcs_tmp, sr_gcs)
                arcpy.RepairGeometry_management(fc_gcs_tmp)
                arcpy.AddField_management(fc_gcs_tmp, 'area_km2', 'FLOAT')
                arcpy.CalculateField_management(fc_gcs_tmp, 'area_km2', '!shape.geodesicArea@squarekilometers!', 'PYTHON_9.3')
                
                d = pandas.DataFrame(arcpy.da.TableToNumPyArray(fc_gcs_tmp, ['rgn_id','rgn_name','area_km2']))
                d = d[d.rgn_id != 0]                
                d.to_csv(csv, index=False, encoding='utf-8')        
                
                arcpy.Copy_management(fc_gcs_tmp, fc_gcs)
                arcpy.Delete_management(fc_mol_tmp)
                arcpy.Delete_management(fc_gcs_tmp)
                # DEBUG!
                #shutil.copyfile(csv, '%s/%s' % (dir_dest_rgn, os.path.basename(csv)))
            else:
                #print '    %s found, skipping (%s)' % (os.path.basename(fc_gcs), time.strftime('%H:%M:%S'))
                pass

        arcpy.env.workspace = gdb

        ## Skipping simplify b/c at least for Albania trial decent PAEK tolerance of 0.01 actually producing larger *.shp vs original
        ## simplify offshore to geojson for rendering in toolbox
        # arcpy.env.outputCoordinateSystem = sr_gcs
        # arcpy.RepairGeometry_management('rgn_offshore_gcs.shp')
        # arcpy.cartography.SmoothPolygon('rgn_offshore_gcs.shp', 'rgn_offshore_smooth_gcs.shp', 'PAEK', 0.01, 'FIXED_ENDPOINT', 'FLAG_ERRORS')
        # arcpy.env.outputCoordinateSystem = sr_mol # reset coordinate system
        # arcpy.cartography.SimplifyPolygon('rgn_offshore_gcs.shp', 'rgn_offshore_simplify_gcs.shp', 'BEND_SIMPLIFY', 1000, 0, 'FLAG_ERRORS', 'KEEP_COLLAPSED_POINTS')

        # # copy to destination
        # print '  copy to destination (%s)' % time.strftime('%H:%M:%S')
        # try:
            # shutil.rmtree(dir_dest_rgn) # empty it
            # shutil.copytree(dir_tmp_rgn, dir_dest_rgn) # copy recursively
        # except:
            # print '    copy FAILED!'
            # continue
    except Exception as e:
        print e.message
        print '    project FAILED!'
        continue
