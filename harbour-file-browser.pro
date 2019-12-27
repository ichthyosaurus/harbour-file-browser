TEMPLATE = subdirs
SUBDIRS = src

# ordered makes sure projects are built in the order specified in SUBDIRS.
# Usually it makes sense to build tests only if main component can be built
CONFIG += ordered

# Note:
# - The current version number can be configured in the yaml-file.
# - Whether or not to include features against Harbour's rules
#   can be configured in the spec-file by passing
#   HARBOUR_COMPLIANCE=on (resp. =off) as option to qmake.
