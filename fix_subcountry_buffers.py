import arcpy, pandas, re, os, fnmatch, time

# C:\Python27\ArcGISx6410.2\python.exe G:\ohi-webapps\fix_subcountry_buffers.py
#
# - are : create_maps: readOGR('/Volumes/data_edit/git-annex/clip-n-ship/are/spatial', 'rgn_inland1km_gcs') # Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv) : Multiple # dimensions:
# - aus : create_maps: ggmap tile not found prob
# - nic : missing spatial/rgn_offshore3nm_data.csv
# - zaf : inland1km Error in ogrInfo(dsn = dsn, layer = layer, encoding = encoding, use_iconv = use_iconv) : Multiple # dimensions: 
# TODO: zip shps: kor, are, zaf

#d = {'esp': ['offshore1km', 'inland1km'],
#     'kor': ['offshore1km', 'inland1km'],
#     'zaf': ['offshore1km', 'inland1km']}
#d = {'are': ['offshore1km', 'inland1km']}

gdb     = 'C:/tmp/ohi-webapps/subcountry.gdb'
dir_err = 'G:/ohi-webapps/errors'

# set dictionary of subcountry keys and buffers that errored out before when running create_all
##d = {}
##for f in os.listdir(dir_err):
##    if fnmatch.fnmatch(f, '*_readOGR_fails.txt'):
##        key = f.replace('_readOGR_fails.txt','')
##        d[key] = open('%s/%s' % (dir_err, f), 'r').readlines()[0].split(':')[1].strip().split(',')
##k_todo = ['ury', 'vct', 'ven', 'vnm', 'vut', 'wlf', 'wsm', 'yem']
##d = {k: d[k] for k in k_todo}
##d = {'syr': ['inland1km'],
##     'vnm': ['offshore3nm']}
d = {'ukr': ['offshore3nm']}

d_buf_units = {'nm':'NauticalMiles',
               'km':'Kilometers',
               'mi':'Miles'}

def export_shp_csv(fc_in, fc_out, csv_out, flds=['rgn_id','rgn_name','area_km2']):
    arcpy.CopyFeatures_management(fc_in, fc_out)
    # nic...: buf = 'offshore3nm'; fc_in = '%s/rgn_%s_gcs.shp' % (dir_sp, buf); csv_out = '%s/rgn_%s_data.csv' % (dir_sp, buf); flds=['rgn_id','rgn_name','area_km2']
    dat = pandas.DataFrame(arcpy.da.TableToNumPyArray(fc_in, flds))
    dat.to_csv(csv_out, index=False, encoding='utf-8')

for key in sorted(d.iterkeys()): # key = 'esp'

    dir_sp = 'N:/git-annex/clip-n-ship/%s/spatial' % key
    print '%s: %s [%s]' % (key, ', '.join(d[key]), time.strftime('%H:%M:%S'))

    # delete existing k_* in gdb
    arcpy.env.workspace = gdb
    [arcpy.Delete_management(fc) for fc in arcpy.ListFeatureClasses('k_*')]

    # fetch needed shps
    bufs = d[key]
    if len(set(('inland1km','inland25km')) & set(bufs)) > 0:
        arcpy.Dissolve_management('%s/rgn_offshore_gcs.shp' % dir_sp, 'k_offshore_d')
        arcpy.CopyFeatures_management('%s/rgn_inland_gcs.shp' % dir_sp, 'k_inland')
        
    if len(set(('offshore3nm','offshore1km')) & set(bufs)) > 0:
        arcpy.Dissolve_management('%s/rgn_inland_gcs.shp' % dir_sp, 'k_inland_d')
        arcpy.CopyFeatures_management('%s/rgn_offshore_gcs.shp' % dir_sp, 'k_offshore')

    for buf in d[key]: # buf = 'inland1km' # buf = 'offshore1km'
    
        buf_zone, buf_dist, buf_units = re.search('(\\D+)(\\d+)(\\D+)', buf).groups()
        print '  %s [%s]' % (buf, time.strftime('%H:%M:%S'))

        if buf_zone == 'inland':
            arcpy.Buffer_analysis('k_offshore_d', 'k_%s_b' % buf, '%s %s' % (buf_dist, d_buf_units[buf_units]), dissolve_option='ALL')
            arcpy.Intersect_analysis(['k_%s_b' % buf, 'k_inland'], 'k_%s_bi' % buf)

        if buf_zone == 'offshore':
            arcpy.Buffer_analysis('k_inland_d', 'k_%s_b' % buf, '%s %s' % (buf_dist, d_buf_units[buf_units]), dissolve_option='ALL')
            arcpy.Intersect_analysis(['k_%s_b' % buf, 'k_offshore'], 'k_%s_bi' % buf)

        arcpy.Dissolve_management('k_%s_bi' % buf, 'k_%s_bid' % buf, ['rgn_id','rgn_name'])
        arcpy.RepairGeometry_management('k_%s_bid' % buf) # late add
        arcpy.AddField_management(      'k_%s_bid' % buf, 'area_km2', 'DOUBLE')
        arcpy.CalculateField_management('k_%s_bid' % buf, 'area_km2', '!shape.area@SQUAREKILOMETERS!', 'PYTHON_9.3')

        # delete existing shp, tif
        arcpy.env.workspace = dir_sp
        objects = arcpy.ListFeatureClasses('*%s*' % buf)
        objects.extend(arcpy.ListDatasets('*%s*' % buf))
        for o in objects:
            arcpy.Delete_management(o)

        # export shp, csv
        arcpy.env.workspace = gdb
        export_shp_csv('k_%s_bid' % buf, '%s/rgn_%s_gcs.shp' % (dir_sp, buf), '%s/rgn_%s_data.csv' % (dir_sp, buf))
