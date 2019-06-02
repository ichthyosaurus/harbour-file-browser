TEMPLATE = subdirs
SUBDIRS = src

# ordered makes sure projects are built in the order specified in SUBDIRS.
# Usually it makes sense to build tests only if main component can be built
CONFIG += ordered

# Inclusion of features that do not comply to Harbour's rules
# can be configured in src/src.pro. See there for details.
