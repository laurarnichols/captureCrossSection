
-include ../../make.sys

LSF_OBJS = LSF_Module_v34.o LSF_Main.o

all : LSF.x
	
LSF.x : $(LSF_OBJS)
	$(mpif90) -o LSF.x $(LSF_OBJS)
	- ( cd $(Home_Path)/bin ; ln -fs $(Home_Path)/$(LSF_srcPath)/$@ . )

	@echo "" ; \
	echo "" ; \
	echo "Module 'LSF' compiled successfully !" ; \
	echo "" ; \
	echo "" ;

%.o : %.f90
	$(mpif90) -c $<

clean :

	@echo "" ; \
	echo "Cleaning module 'LSF' ... " ; \
	/bin/rm -f *.x *.o *.mod .DS_Store ; \
	echo "Cleaning module 'LSF' done !" ; \
	echo "" ; \

