"""tstools.pyx -- Pyrex bindings for the TS tools
"""

# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1
# 
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
# 
# The Original Code is the MPEG TS, PS and ES tools.
# 
# The Initial Developer of the Original Code is Amino Communications Ltd.
# Portions created by the Initial Developer are Copyright (C) 2008
# the Initial Developer. All Rights Reserved.
# 
# Contributor(s):
#   Tibs (tibs@berlios.de)
# 
# ***** END LICENSE BLOCK *****

# If we're going to use definitions like this in more than one pyx file, we'll
# need to define the shared types in a .pxd file and use cimport to import
# them.
cdef extern from "stdio.h":
    ctypedef struct FILE:
        int _fileno
    cdef enum:
        EOF = -1
    cdef FILE *stdout
    # Associate a stream (returned) with an existing file descriptor.
    # The specified mode must be compatible with the existing mode of
    # the file descriptor. Closing the stream will close the descriptor
    # as well.
    cdef FILE *fdopen(int fildes, char *mode)

cdef FILE *convert_python_file(object file):
    """Given a Python file object, return an equivalent stream.
    There are *so many things* dodgy about doing this...
    """
    cdef int fileno
    cdef char *mode
    cdef FILE *stream
    fileno = file.fileno()
    mode = file.mode
    stream = fdopen(fileno, mode) 
    if stream == NULL:
        raise TSToolsException, 'Error converting Python file to C FILE *'
    else:
        return stream

cdef extern from "compat.h":
    # We don't need to define 'offset_t' exactly, just to let Pyrex
    # know it's vaguely int-like
    ctypedef int offset_t

ctypedef char byte

cdef extern from 'es_defns.h':
    # The reader for an ES file
    struct elementary_stream:
        pass

    ctypedef elementary_stream  ES
    ctypedef elementary_stream *ES_p

    # A location within said stream
    struct _ES_offset:
        offset_t    infile      # as used by lseek
        int         inpacket    # in PES file, offset within PES packet

    ctypedef _ES_offset ES_offset

    # An actual ES unit
    struct ES_unit:
        ES_offset   start_posn
        byte       *data
        unsigned    data_len
        unsigned    data_size
        byte        start_code
        byte        PES_had_PTS

    ctypedef ES_unit *ES_unit_p

cdef extern from 'es_fns.h':
    int open_elementary_stream(char *filename, ES_p *es)
    void close_elementary_stream(ES_p *es)

    int build_elementary_stream_file(int input, ES_p *es)
    void free_elementary_stream(ES_p *es)

    int find_and_build_next_ES_unit(ES_p es, ES_unit_p *unit)
    void free_ES_unit(ES_unit_p *unit)
    void report_ES_unit(FILE *stream, ES_unit_p unit)

    # We perhaps need a Python object to represent an ES_offset?
    # Otherwise, it's going to be hard to use them within Python itself
    int seek_ES(ES_p es, ES_offset where)
    int compare_ES_offsets(ES_offset offset1, ES_offset offset2)

    # I'd like to be able to *write* ES files, so...
    # Python file objects can return a file descriptor (i.e., integer)
    # via their fileno() method, so the simplest thing to do may be to
    # add a new C function that uses write() instead of fwrite(). Or I
    # could use fdopen to turn the fileno() into a FILE *...
    int build_ES_unit(ES_unit_p *unit)
    int write_ES_unit(FILE *output, ES_unit_p unit)


# Is this the best thing to do?
class TSToolsException(Exception):
    pass


cdef class ESUnit:
    """A Python class representing an ES unit.
    """

    cdef ES_unit_p unit

    # It appears to be recommended to make __cinit__ expand to take more
    # arguments (if __init__ ever gains them), since both get the same
    # things passed to them. Hmm, normally I'd trust myself, but let's
    # try the recommended route
    def __cinit__(self, *args,**kwargs):
        pass

    def __init__(self):
        pass

    def report(self):
        """Report (briefly) on an ES unit. This write to C stdout, which means
        that Python has no control over the output. A proper Python version of
        this will be provided eventually.
        """
        report_ES_unit(stdout, self.unit)

    #def _set_unit(self, ES_unit_p unit):
    #    if self.unit:
    #        raise TSToolsException,'ESUnit already has an ES unit associated'
    #    else:
    #        self.unit = unit

    def __dealloc__(self):
        free_ES_unit(&self.unit)

    def __repr__(self):
        return 'ES unit: start code %02x'%self.unit.start_code

    cdef __set_es_unit(self, ES_unit_p unit):
        if self.unit == NULL:
            raise ValueError,'ES unit already defined'
        else:
            self.unit = unit

# Is this the simplest way? Since it appears that a class method
# doesn't want to take a non-Python item as an argument...
cdef _next_ESUnit(ES_p stream, filename):
    cdef ES_unit_p unit
    # The C function assumes it has a valid ES stream passed to it
    # = I don't think we're always called with such
    if stream == NULL:
        raise TSToolsException,'No ES stream to read'

    retval = find_and_build_next_ES_unit(stream, &unit)
    if retval == EOF:
        raise StopIteration
    elif retval != 0:
        raise TSToolsException,'Error getting next ES unit from file %s'%filename

    # From http://www.philhassey.com/blog/2007/12/05/pyrex-from-confusion-to-enlightenment/
    # Pyrex doesn't do type inference, so it doesn't detect that 'u' is allowed
    # to hold an ES_unit_p. It's up to us to *tell* it, specifically, what type
    # 'u' is going to be.
    cdef ESUnit u
    u = ESUnit()
    u.unit = unit
    #u._set_unit(unit)
    return u

cdef class ESStream:
    """A Python class representing an ES stream.

    Initially, always a file (so maybe this should be ESFile?)

    We support opening for read, or opening (creating) a new file
    for write. For the moment, we don't support appending.

    So, create a new ESStream as either:

        * ESStream(filename,'r') or
        * ESStream(filename,'w')

    Note that there is always an implicit 'b' attached to the mode (i.e., the
    file is accessed in binary mode).
    """

    cdef object python_file     # File as opened by Python
    cdef FILE *file_stream      # The corresponding C file stream
    cdef ES_p  stream           # For reading an existing ES stream
    cdef readonly object filename
    cdef readonly object mode
    cdef object actual_mode

    # It appears to be recommended to make __cinit__ expand to take more
    # arguments (if __init__ ever gains them), since both get the same
    # things passed to them. Hmm, normally I'd trust myself, but let's
    # try the recommended route
    def __cinit__(self,filename,mode='r',*args,**kwargs):
        if mode == 'r':
            actual_mode = 'rb'
            self.python_file = open(filename,actual_mode)
            fileno = self.python_file.fileno()
            self.file_stream = fdopen(fileno,actual_mode)
            retval = build_elementary_stream_file(fileno,&self.stream)
            if retval != 0:
                raise TSToolsException,'Error starting to read ES file %s'%filename
        elif mode == 'w':
            actual_mode = 'wb'
            self.python_file = open(filename,actual_mode)
            fileno = self.python_file.fileno()
            self.file_stream = fdopen(fileno,actual_mode)
        else:
            raise ValueError,"Only modes 'r' and 'w' supported for ESStream"

    def __init__(self,filename,mode='r'):
        # What should go in __init__ and what in __cinit__ ???
        self.filename = filename
        self.mode = mode
        self.actual_mode = mode + 'b'

    def __dealloc__(self):
        if self.stream != NULL:
            free_elementary_stream(&self.stream)

    def __iter__(self):
        return self

    def is_readable(self):
        """This is a convenience method, whilst reading and writing are exclusive.
        """
        return self.mode == 'r' and self.stream != NULL

    def is_writable(self):
        """This is a convenience method, whilst reading and writing are exclusive.
        """
        return self.mode == 'w' and self.file_stream != NULL

    # For Pyrex classes, we define a __next__ instead of a next method
    # in order to form our iterator
    def __next__(self):
        """Our iterator interface retrieves the ES units from the stream.
        """
        return _next_ESUnit(self.stream,self.filename)

    def close(self):
        if self.python_file:
            self.python_file.close()
            self.python_file = None
            self.mode = None
        # Apparently we can't call the __dealloc__ method itself,
        # but I think this is sensible to do here...
        if self.stream != NULL:
            free_elementary_stream(&self.stream)