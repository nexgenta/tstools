bin_PROGRAMS = esfilter ts2es es2ts esdots esmerge esreport ps2ts psreport \
	psdots stream_type tsinfo tsreport tsplay tsserve ts_packet_insert \
	m2ts2ts pcapreport

lib_LTLIBRARIES = libtstools.la

libtstools_la_SOURCES = \
	accessunit.c avs.c ac3.c adts.c bitdata.c es.c filter.c fmtx.c h222.c \
	h262.c audio.c l2audio.c misc.c nalunit.c ps.c pes.c pidint.c \
	printing.c reverse.c ts.c tswrite.c pcap.c ethernet.c ipv4.c

esfilter_SOURCES = esfilter.c
esfilter_LDADD = libtstools.la

ts2es_SOURCES = ts2es.c
ts2es_LDADD = libtstools.la

es2ts_SOURCES = es2ts.c
es2ts_LDADD = libtstools.la

esdots_SOURCES = esdots.c
esdots_LDADD = libtstools.la

esmerge_SOURCES = esmerge.c
esmerge_LDADD = libtstools.la

esreport_SOURCES = esreport.c
esreport_LDADD = libtstools.la

ps2ts_SOURCES = ps2ts.c
ps2ts_LDADD = libtstools.la

psreport_SOURCES = psreport.c
psreport_LDADD = libtstools.la

psdots_SOURCES = psdots.c
psdots_LDADD = libtstools.la

stream_type_SOURCES = stream_type.c
stream_type_LDADD = libtstools.la

tsinfo_SOURCES = tsinfo.c
tsinfo_LDADD = libtstools.la

tsreport_SOURCES = tsreport.c
tsreport_LDADD = libtstools.la

tsplay_SOURCES = tsplay.c
tsplay_LDADD = libtstools.la

tsserve_SOURCES = tsserve.c
tsserve_LDADD = libtstools.la

ts_packet_insert_SOURCES = ts_packet_insert.c
ts_packet_insert_LDADD = libtstools.la

m2ts2ts_SOURCES = m2ts2ts.c
m2ts2ts_LDADD = libtstools.la

pcapreport_SOURCES = pcapreport.c
pcapreport_LDADD = libtstools.la
