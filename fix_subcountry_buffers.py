import pandas, re

d = {'kor': ['offshore1km', 'inland1km']}
gdb = r'C:\tmp\ohi-webapps\subcountry.gdb'
d_buf_units = {'nm':'NauticalMiles',
               'km':'Kilometers',
               'mi':'Miles'}

def export_shp_csv(fc_in, fc_out, csv_out, flds=['rgn_id','rgn_name','area_km2']):
    arcpy.CopyFeatures_management(fc_in, fc_out)
    d = pandas.DataFrame(arcpy.da.TableToNumPyArray(fc_in, flds))
    d.to_csv(csv_out, index=False, encoding='utf-8')

for key in d.iterkeys(): # key = 'esp'

    dir_sp = 'N:/git-annex/clip-n-ship/%s/spatial' % key

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

        if buf_zone == 'inland':
            arcpy.Buffer_analysis('k_offshore_d', 'k_%s_b' % buf, '%s %s' % (buf_dist, d_buf_units[buf_units]), dissolve_option='ALL')
            arcpy.Intersect_analysis(['k_%s_b' % buf, 'k_inland'], 'k_%s_bi' % buf)

        if buf_zone == 'offshore':
            arcpy.Buffer_analysis('k_inland_d', 'k_%s_b' % buf, '%s %s' % (buf_dist, d_buf_units[buf_units]), dissolve_option='ALL')
            arcpy.Intersect_analysis(['k_%s_b' % buf, 'k_offshore'], 'k_%s_bi' % buf)

        arcpy.Dissolve_management('k_%s_bi' % buf, 'k_%s_bid' % buf, ['rgn_id','rgn_name'])
        arcpy.AddField_management(      'k_%s_bid' % buf, 'area_km2', 'DOUBLE')
        arcpy.CalculateField_management('k_%s_bid' % buf, 'area_km2', '!shape.area@SQUAREKILOMETERS!', 'PYTHON_9.3')

        # delete existing shp, tif
        arcpy.env.workspace = dir_sp
        d = arcpy.ListFeatureClasses('*%s*' % buf)
        d.extend(arcpy.ListDatasets('*%s*' % buf))
        for o in d:
            arcpy.Delete_management(o)

        # export shp, csv
        arcpy.env.workspace = gdb
        export_shp_csv('k_%s_bid' % buf, '%s/rgn_%s_gcs.shp' % (dir_sp, buf), '%s/rgn_%s_data.csv' % (dir_sp, buf))
