
-include ../../make.sys

OBJS = Sigma_Module_v3.o Sigma_Main.o

all : Sigma.x
	
Sigma.x : $(OBJS)
	$(f90) -o Sigma.x $(OBJS)
	- ( cd $(Home_Path)/bin ; ln -fs $(Home_Path)/$(Sigma_srcPath)/$@ . )

	@echo "" ;\
	echo "" ;\
	echo "Module 'Sigma' compiled successfully ! " ;\
	echo "" ;\
	echo "" ;

%.o : %.f90
	$(f90) -c $<

clean :

	@echo "" ;\
	echo "" ;\
	echo "Cleaning Module 'Sigma' ... " ; \
	/bin/rm -f *.x *.o *.mod .DS_Store ; \
	echo "Cleaning Module 'Sigma' done !" ;\
	echo "" ;\
	echo "" ;

