# VERSION : 27.07.97 22:41

PROG      = carre.exe
PROG_TRA  = traduit.exe
PROG_FCRR = fcrr.exe
ifdef SOLPS_CPP
CRRDIR    = ${SOLPSTOP}/modules/Carre
else
CRRDIR    = $(PWD)
endif
B2SRC     = ${SOLPSTOP}/modules/B2.5/src
MOD       = mod
# Test whether necessary environment variables are defined; if not, exit
ifndef HOST_NAME
$(error HOST_NAME not defined)
endif
ifndef COMPILER
$(error COMPILER not defined)
endif

MAKES = Makefile
DEFINES = ${CARRE_DEFINES} ${SOLPS_CPP}
# Include global SOLPS compiler settings
ifndef SOLPS_CPP
  NODENAME = $(shell echo `hostname`)
  ifeq ($(shell [ -e ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER} ] && echo yes || echo no ),yes)
    include ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}
    MAKES += ${SOLPSTOP}/SETUP/setup.csh.${HOST_NAME}.${COMPILER} ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}
  else
    $(warning ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER} not found. Assuming stand-alone compilation.)
  endif
  ifeq ($(shell [ -e ${SOLPSTOP}/SETUP/config.common.${COMPILER} ] && echo yes || echo no ),yes)
    include ${SOLPSTOP}/SETUP/config.common.${COMPILER}
    MAKES += ${SOLPSTOP}/SETUP/config.common.${COMPILER}
  endif
else
  MAKES += ${SOLPSTOP}/Makefile ${SOLPSTOP}/SETUP/setup.csh.${HOST_NAME}.${COMPILER} ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}
  ifeq ($(shell [ -e ${SOLPSTOP}/SETUP/config.common.${COMPILER} ] && echo yes || echo no ),yes)
    MAKES += ${SOLPSTOP}/SETUP/config.common.${COMPILER}
  endif
endif
ifeq ($(shell [ -e ${SOLPSTOP}/SETUP/setup.csh.${HOST_NAME}.${COMPILER}.local ] && echo yes || echo no ),yes)
  MAKES += ${SOLPSTOP}/SETUP/setup.csh.${HOST_NAME}.${COMPILER}.local
endif
ifeq ($(shell [ -e ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}.local ] && echo yes || echo no ),yes)
  include ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}.local
  MAKES += ${SOLPSTOP}/SETUP/config.${HOST_NAME}.${COMPILER}.local
endif

# Extensions for object directories when various options are used
ifdef SOLPS_OPENMP
EXT_OPENMP = .openmp
endif
ifdef USE_IMPGYRO
EXT_IMPGYRO = .ig
else
ifdef SOLPS_MPI
EXT_MPI = .mpi
endif
endif
ifdef SOLPS_DEBUG
EXT_DEBUG = .debug
endif

OBJDIR = ${CRRDIR}/builds/$(HOST_NAME).$(COMPILER)$(EXT_DEBUG)
SRCLOCAL = ${CRRDIR}/src.local

SHELL = /bin/sh
CPP = /usr/lib/cpp

ifeq ($(shell [ -e config/config.${HOST_NAME}.${COMPILER} ] && echo yes || echo no ),yes)
include config/config.${HOST_NAME}.${COMPILER}
MAKES+= config/config.${HOST_NAME}.${COMPILER}
else
$(error config/config.${HOST_NAME}.${COMPILER} not found.)
endif

ifeq ($(shell [ -e config/config.common.${COMPILER} ] && echo yes || echo no ),yes)
include config/config.common.${COMPILER}
MAKES+= config/config.common.${COMPILER}
endif

ifeq ($(shell [ -e config/config.${HOST_NAME}.${COMPILER}.local ] && echo yes || echo no ),yes)
include config/config.${HOST_NAME}.${COMPILER}.local
MAKES+= config/config.${HOST_NAME}.${COMPILER}.local
endif

# Verify that some needed variables are defined
ifndef LD_MSCL
ifndef SOLPS_CPP
$(error LD_MSCL not defined!)
else
$(error LD_MSCL not defined. Run the install_dependencies script first.)
endif
endif

ifdef SOLPS_DEBUG
DEFINES  += -DDBG
endif

# Source form: src is old fixed form source (used by Carre), src90 is current free form source (used by Carre2)
SRCDIR = src

VHEAD   =
ifeq ($(shell [ -d ${SRCLOCAL} ] && echo yes || echo no ),yes)
VHEAD   =${SRCLOCAL}:
endif
FPATH   = ${VHEAD}${SRCDIR}/carre:${SRCDIR}/include:${SRCDIR}/trans:${SRCDIR}/fcrr:${SRCDIR}/dummy
GPATH   = ${SRCDIR}/cntour:${SRCDIR}/graphe
VPATH   = ${VHEAD}${SRCDIR}/carre:${SRCDIR}/include:${SRCDIR}/trans:${SRCDIR}/fcrr:${SRCDIR}/cntour:${SRCDIR}/dummy:${SRCDIR}/graphe

INCLUDE = -I${SRCDIR}/include

ALLTARGETS = ${OBJDIR}/${PROG} ${OBJDIR}/${PROG_TRA}
# We can only build the dg-to-Carre converter fcrr when we have the SOLPS environment available
USE_DIMENSIONS = 0
ifdef SOLPS_CPP
ALLTARGETS += ${OBJDIR}/${PROG_FCRR}
DEFINES += -DSOLPS_CPP
ifeq ($(shell [ -s ${B2SRC}/modules/b2mod_dimensions.F ] && echo yes || echo no ),yes)
USE_DIMENSIONS = 1
DIMSDIR = ${B2SRC}/modules
ifeq ($(shell [ -s ${B2SRC}/modules.local/b2mod_dimensions.F ] && echo yes || echo no ),yes)
DIMSDIR = ${B2SRC}/modules.local
endif
DEFINES += -DDIMENSIONS_MODULE
else
INCLUDE += -I${SOLPSTOP}/modules/B2.5/src/include.local -I${SOLPSTOP}/modules/B2.5/src/include
endif
endif
MAKETAGS ?= ctags -e -f

MAINLIST = carre.o tradui.o fcrr.o bidon.o fcrblkd.o

$(shell awk 'FNR==1{if(!/^OBJS *=/){e=1;exit}} END{exit e}' \
        ${OBJDIR}/LISTOBJ 2>/dev/null || rm -f ${OBJDIR}/LISTOBJ)
ifeq ($(shell [ -e ${OBJDIR}/LISTOBJ ] && echo yes || echo no ),yes)
  include ${OBJDIR}/LISTOBJ
endif

DEST = $(OBJS:%.o=$(OBJDIR)/%.o)
GDEST = $(GOBJS:%.o=$(OBJDIR)/%.o)
EXCLUDELIST = $(MAINLIST:.o=\\.o)
LIBRARIES = $(LDFLAGS:-l%=${LIBSOLDIR}/lib%.a)

ifdef LD_NCARG
ifeq ($(strip ${GLI_HOME}),)
$(warning Carre graphics may not work because GLI_HOME is not defined.)
endif
all: VERSION ${OBJDIR}/${PROG} ${OBJDIR}/${PROG_TRA} ${OBJDIR}/${PROG_FCRR} ${OBJDIR}/.x
else
ifndef NCARG_ROOT
$(warning Carre graphics are turned off as NCARG_ROOT is not defined.)
endif
all: VERSION ${OBJDIR}/${PROG} ${OBJDIR}/${PROG_TRA} ${OBJDIR}/${PROG_FCRR} ${OBJDIR}/.nox
endif

.PHONY: VERSION clean neat standalone all local depend listobj force

standalone: ${OBJDIR}/${PROG} ${OBJDIR}/${PROG_TRA}

all: ${ALLTARGETS}

ifdef LD_NCARG
${OBJDIR}/${PROG} ${OBJDIR}/.x: ${OBJDIR}/carre.o ${OBJDIR}/libcarre.a ${OBJDIR}/libgcarre.a $(MAKES)
	rm -f ${OBJDIR}/${PROG} 2> /dev/null; \
	rm -f ${OBJDIR}/.nox 2> /dev/null; \
	${FC} $(FFLAGS) ${FFLAGSEXTRA} -o ${OBJDIR}/${PROG} ${OBJDIR}/carre.o ${OBJDIR}/libcarre.a ${OBJDIR}/libgcarre.a $(LDFLAGS) $(LDEXTRA)
	touch ${OBJDIR}/.x
else
${OBJDIR}/${PROG} ${OBJDIR}/.nox: ${OBJDIR}/carre.o ${OBJDIR}/libcarre.a ${OBJDIR}/bidon.o $(MAKES)
	rm -f ${OBJDIR}/${PROG} 2> /dev/null; \
	rm -f ${OBJDIR}/.x 2> /dev/null; \
	${FC} $(FFLAGS) ${FFLAGSEXTRA} -o ${OBJDIR}/${PROG} ${OBJDIR}/carre.o ${OBJDIR}/libcarre.a ${OBJDIR}/bidon.o $(LDFLAGS) $(LDEXTRA)
	touch ${OBJDIR}/.nox
endif

${OBJDIR}/${PROG_TRA}: ${OBJDIR}/tradui.o ${OBJDIR}/libcarre.a $(MAKES)
	rm -f ${OBJDIR}/${PROG_TRA} 2> /dev/null; \
	${FC} $(FFLAGS) ${FFLAGSEXTRA} -o ${OBJDIR}/${PROG_TRA} ${OBJDIR}/tradui.o ${OBJDIR}/libcarre.a $(LDFLAGS) $(LDEXTRA)

${OBJDIR}/${PROG_FCRR}: ${OBJDIR}/fcrr.o ${OBJDIR}/fcrblkd.o ${OBJDIR}/libcarre.a $(MAKES)
	rm -f ${OBJDIR}/${PROG_FCRR} 2> /dev/null; \
	${FC} $(FFLAGS) ${FFLAGSEXTRA} -o ${OBJDIR}/${PROG_FCRR} ${OBJDIR}/fcrr.o ${OBJDIR}/fcrblkd.o ${OBJDIR}/libcarre.a ${LDLIBS} $(LDFLAGS) $(LDEXTRA)

${OBJDIR}/libcarre.a: ${DEST}
	@ar rc $@ ${DEST}
	ranlib $@

${OBJDIR}/libgcarre.a: ${GDEST}
	@ar rc $@ ${GDEST}
	ranlib $@

$(OBJDIR)/%.o : %.F
	@/bin/rm -f ${OBJDIR}/$*.f ${OBJDIR}/$*.o
ifeq ($(strip ${DBLPAD}),)
	${CPP} ${DEFINES} -P ${INCLUDE} $< ${OBJDIR}/$*.f; \
	$(COMPILE) ${FFLAGSEXTRA} $(INCLUDE) ${INCMOD}${OBJDIR} -o ${OBJDIR}/$*.o ${OBJDIR}/$*.f
else
	${CPP} ${DEFINES} -P ${INCLUDE} $< ${OBJDIR}/$*.f; \
	case $< in \
		${SRCDIR}/trans/* ) $(COMPILE) ${FFLAGSEXTRA} $(DBLPAD) $(INCLUDE) ${INCMOD}${OBJDIR} -o ${OBJDIR}/$*.o ${OBJDIR}/$*.f;; \
		       *    ) $(COMPILE) ${FFLAGSEXTRA} $(INCLUDE) ${INCMOD}${OBJDIR} -o ${OBJDIR}/$*.o ${OBJDIR}/$*.f;; \
	esac
endif
	@if [ -f $*.o ]; then /bin/mv $*.o ${OBJDIR}; fi
ifneq (${MOD},o)
	@if [ -f $*.${MOD} ]; then /bin/mv $*.${MOD} ${OBJDIR}; fi
endif

ifneq (${MOD},o)
# The compiler writes the .mod file as a side effect of producing the .o,
# so make .mod depend on .o (no recipe).  This avoids a parallel-make race
# where the duplicate "%.${MOD}: %.F" rule and the "%.o: %.F" rule above
# would both compile the same source concurrently and clobber the .mod
# during gfortran's atomic .mod0 -> .mod rename.
$(OBJDIR)/%.${MOD} : $(OBJDIR)/%.o
	@true
endif

ifeq (${USE_DIMENSIONS},1)
${OBJDIR}/b2mod_dimensions.o: ${DIMSDIR}/b2mod_dimensions.F ${B2SRC}/modules/.new_modules
	@mkdir -p ${SRCDIR}/b25_links/
	ln -sf ${DIMSDIR}/b2mod_dimensions.F ${SRCDIR}/b25_links/b2mod_dimensions.F
	${CPP} ${DEFINES} ${EQUIVS} -P ${INCLUDE} ${SRCDIR}/b25_links/b2mod_dimensions.F ${OBJDIR}/b2mod_dimensions.f
	$(COMPILE) ${FFLAGSEXTRA} $(INCLUDE) -o ${OBJDIR}/b2mod_dimensions.o ${OBJDIR}/b2mod_dimensions.f
	@if [ -f b2mod_dimensions.${MOD} ]; then /bin/mv b2mod_dimensions.${MOD} ${OBJDIR}; fi
ifneq ($(COMPILER),nag_f90)
	@if [ -f ${OBJDIR}/b2mod_dimensions.${MOD} ] ; then touch ${OBJDIR}/b2mod_dimensions.${MOD} ; fi
endif
ifneq (${MOD},o)
# .mod is a side-effect of compiling .o — depend on .o with no recipe to avoid
# a parallel-make race where both rules would compile b2mod_dimensions.F simultaneously.
${OBJDIR}/b2mod_dimensions.${MOD}: ${OBJDIR}/b2mod_dimensions.o
endif
else
${OBJDIR}/b2mod_dimensions.o:
	@touch ${OBJDIR}/b2mod_dimensions.o
ifneq ($(COMPILER),nag_f90)
	@if [ -f ${OBJDIR}/b2mod_dimensions.${MOD} ] ; then touch ${OBJDIR}/b2mod_dimensions.${MOD} ; fi
endif
ifneq (${MOD},o)
${OBJDIR}/b2mod_dimensions.${MOD}: ${OBJDIR}/b2mod_dimensions.o
	@touch ${OBJDIR}/b2mod_dimensions.${MOD}
endif
endif

clean:
	rm -rf ${OBJDIR}/*.o ${OBJDIR}/*.f ${OBJDIR}/*.${MOD} ${OBJDIR}/libcarre.a ${OBJDIR}/libgcarre.a ${OBJDIR}/${PROG} ${OBJDIR}/${PROG_TRA} ${OBJDIR}/${PROG_FCRR} ${SRCDIR}/include/git_version_Carre.h ${OBJDIR}/dependencies* ${OBJDIR}/LISTOBJ

neat:
	rm -rf ${OBJDIR}/*.o ${OBJDIR}/*.f ${OBJDIR}/*.${MOD}

local:
	-rm rzpsi.mtv rzpsi.ps map loadmap gnuplot.data gnuplot.cmd
	-gtfl btor.dat structure.dat rzpsi.dat ncar.cfg gmeta fort.11 carre.out carre.log carre.dat warnings.dat traduit.log selptx.inf traduit.out

TAGS:	tags

tags:
	rm -f TAGS ; ${MAKETAGS} TAGS ${SRCDIR}/*/*.F || touch TAGS


# Build into a temp file and mv it into place atomically at the very end,
# and mark completion with a trailing "# DEPEND-COMPLETE" line (checked by
# the staleness guard right before "include ${OBJDIR}/dependencies.${COMPILER}"
# further down). If this recipe is interrupted partway (SIGKILL/OOM/walltime/
# Ctrl-C, all realistic under a parallel batch build), the real
# dependencies.${COMPILER} is left untouched (either absent or the previous,
# complete version) instead of a truncated-but-non-empty file. Without the
# atomic mv + completion marker, a partially-written file would be silently
# reused forever, permanently missing the "use module" ordering edges (e.g.
# for carre_dimensions) for whichever sources had not yet been scanned at the
# time of the interruption, letting a parallel make race ahead and read a
# module file before/while it is built.
depend: ${OBJS:.o=.F} ${GOBJS:.o=.F} ${MAINLIST:.o=.F}
	@makedepend ${DEFINES} -f- ${INCLUDE} $^ | \
	sed -e 's|${SRCDIR}/[^ ]*/|${OBJDIR}/|' | \
	sed -e 's,^${OBJDIR}/,\$${OBJDIR}/,' | \
	sed -e 's,: ${SOLPSTOP},: $${SOLPSTOP},' > ${OBJDIR}/dependencies.${COMPILER}.tmp
	@echo '# 1' >> ${OBJDIR}/dependencies.${COMPILER}.tmp
	@egrep -aiH '^ {0,}use ' $^ | grep -v 'IGNORE' | tr , ' ' | awk '{sub("\\.F:",".o:",$$1);sub("\\.F90:",".o:",$$1);sub("\\.f90:",".o:",$$1);sub("^.*/","$${OBJDIR}/",$$1); print $$1,"$${OBJDIR}/"tolower($$3)".${MOD}"}' >> ${OBJDIR}/dependencies.${COMPILER}.tmp
ifneq (${MOD},o)
	@echo '# 2' >> ${OBJDIR}/dependencies.${COMPILER}.tmp
	@egrep -aiH '^ {0,}use ' $^ | grep -v 'IGNORE' | tr , ' ' | awk '{sub("\\.F:",".${MOD}:",$$1);sub("\\.F90:",".${MOD}:",$$1);sub("\\.f90:",".${MOD}:",$$1);sub("^.*/","$${OBJDIR}/",$$1); print $$1,"$${OBJDIR}/"tolower($$3)".${MOD}"}' >> ${OBJDIR}/dependencies.${COMPILER}.tmp
endif
	@echo '# DEPEND-COMPLETE' >> ${OBJDIR}/dependencies.${COMPILER}.tmp
	@mv -f ${OBJDIR}/dependencies.${COMPILER}.tmp ${OBJDIR}/dependencies.${COMPILER}

listobj:
ifneq ($(shell uname),Darwin)
	@rm -f ${OBJDIR}/LISTOBJ; touch ${OBJDIR}/LISTOBJ; \
	l="OBJS ="; \
	for d in `echo "${FPATH}" | tr : \ `; do \
		l="$$l `find $$d -name '*.F' -printf "%f "`"; \
	done; \
	E="-e 's/\.F/\.o/g'" ; for f in $(EXCLUDELIST); do \
		E="$$E -e 's/ $$f//'"; \
	done; \
	echo "$$l" | eval sed "$$E" > ${OBJDIR}/LISTOBJ
	@ll="GOBJS ="; \
	for d in `echo "$(GPATH)" | tr : \ `; do \
		ll="$$ll `find $$d -name '*.F' -printf "%f "`"; \
	done; \
	E="-e 's/\.F/\.o/g'" ; for f in $(EXCLUDELIST); do \
		E="$$E -e 's/ $$f//'"; \
	done; \
	echo "$$ll" | eval sed "$$E" >> ${OBJDIR}/LISTOBJ
else
	@rm -f ${OBJDIR}/LISTOBJ; touch ${OBJDIR}/LISTOBJ; \
	l="OBJS ="; \
	for d in `echo "${FPATH}" | tr : \ `; do \
		l="$$l `find $$d -name '*.F' -exec basename {} \; | tr '\n' ' '`"; \
	done; \
	E="-e 's/\.F/\.o/g'" ; for f in $(EXCLUDELIST); do \
		E="$$E -e 's/ $$f//'"; \
	done; \
	echo "$$l" | eval sed "$$E" > ${OBJDIR}/LISTOBJ
	@ll="GOBJS ="; \
	for d in `echo "$(GPATH)" | tr : \ `; do \
		ll="$$ll `find $$d -name '*.F' -exec basename {} \; | tr '\n' ' '`"; \
	done; \
	E="-e 's/\.F/\.o/g'" ; for f in $(EXCLUDELIST); do \
		E="$$E -e 's/ $$f//'"; \
	done; \
	echo "$$ll" | eval sed "$$E" >> ${OBJDIR}/LISTOBJ
endif

# Rebuild LISTOBJ only when missing (no prerequisites → always up-to-date
# once built).  Use explicit `make listobj` to force a rebuild when sources change.
${OBJDIR}/LISTOBJ:
	$(MAKE) listobj

VERSION: ${SRCDIR}/include/git_version_Carre.h

${SRCDIR}/include/git_version_Carre.h: force
	@echo "      character*32 :: git_version_Carre =" > ${SRCDIR}/include/git_version_new.h
	@echo "     . '`git describe --tags --dirty --always | cut -c 1-32`'" >> ${SRCDIR}/include/git_version_new.h
	@if cmp -s ${SRCDIR}/include/git_version_new.h ${SRCDIR}/include/git_version_Carre.h; then rm ${SRCDIR}/include/git_version_new.h; else mv ${SRCDIR}/include/git_version_new.h ${SRCDIR}/include/git_version_Carre.h; fi

ifeq (${USE_DIMENSIONS},1)
${OBJDIR}/dependencies.${COMPILER}: ${B2SRC}/modules/.new_modules
else
${OBJDIR}/dependencies.${COMPILER}:
endif
	-mkdir -p ${OBJDIR}
	printf '# Dummy dependencies file for Carre (incomplete - placeholder while regenerating)\n' > ${OBJDIR}/dependencies.${COMPILER}
	CARRE_DEPEND_BUILDING=1 ${MAKE} VERSION
	CARRE_DEPEND_BUILDING=1 ${MAKE} tags
	CARRE_DEPEND_BUILDING=1 ${MAKE} listobj
	CARRE_DEPEND_BUILDING=1 ${MAKE} depend

# Treat the file as usable only if the "depend" target ran to completion
# (marked by the trailing "# DEPEND-COMPLETE" line written just before its
# atomic mv into place, see the "depend" target above). Anything else -
# missing file, the placeholder written above, or a file left over from an
# interrupted/killed depend run (SIGKILL/OOM/walltime/Ctrl-C, all realistic
# under a parallel batch build) - is discarded so it gets regenerated from
# scratch instead of being silently reused with missing "use module"
# ordering edges.
#
# This check runs at Makefile PARSE time, so it also runs again inside every
# recursive ${MAKE} sub-invocation spawned by the bootstrap recipe just above
# (VERSION/tags/listobj/depend). Without the CARRE_DEPEND_BUILDING guard,
# each of those sub-invocations would re-parse this Makefile, see the
# not-yet-complete placeholder, delete it, cause "include" to re-trigger the
# bootstrap rule again, and recurse forever. CARRE_DEPEND_BUILDING=1 is set
# in the environment only for those inner sub-makes (see recipe above), so
# they trust whatever is currently on disk and skip the deletion, while a
# fresh top-level "make" invocation (which does not have the variable set)
# still performs the real staleness check.
ifeq ($(CARRE_DEPEND_BUILDING),)
$(shell tail -n1 ${OBJDIR}/dependencies.${COMPILER} 2>/dev/null | grep -q '^# DEPEND-COMPLETE$$' || rm -f ${OBJDIR}/dependencies.${COMPILER})
endif
include ${OBJDIR}/dependencies.${COMPILER}
ifeq ($(shell [ -e ${CRRDIR}/config/dependencies.local ] && echo yes || echo no ),yes)
include ${CRRDIR}/config/dependencies.local
endif

echo:
	@echo INCLUDE=${INCLUDE}
	@echo DEFINES=${DEFINES}
	@echo GOBJS=${GOBJS}
	@echo DEST=${DEST}
