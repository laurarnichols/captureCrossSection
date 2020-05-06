

########################################################################
#                                                                      #
# Please change the following declarations to meet yours system setup. #
#                                                                      #
########################################################################

QE-5.0.2_Path = ~/postdoc/codes/espresso-5.0.2

f90 = gfortran

mpif90 = mpif90


########################################################################
#                                                                      #
#       Please do NOT make any change in the following lines!          #
#                                                                      #
########################################################################


default :

	@echo ""
	@echo ""
	@echo " If you want to built Quantum Espresso dependent modules, "
	@echo " make sure that PW and PP packages are already built."
	@echo ""
	@echo " Then edit this Makefile to meet yours system setup. "
	@echo " You have to define the path to the Quantum Espresso home directory,"
	@echo " and the fortran compilers you want to be used."
	@echo ""
	@echo ""
	@echo " Please use one of the following commands :"
	@echo ""
	@echo "    make all_QE-5.0.2             to built all the modules of the package using Quantum Espresso 5.0.2."
	@echo "    make QE-5.0.2_dependent       to built all the Quantum Espresso 5.0.2 dependent modules."
	@echo "    make Export_QE-5.0.2          to built the Quantum Espresso 5.0.2 dependent Export module."
	@echo "    make TME                      to built the Transition Matrix Elements (TME) module."
	@echo "    make LSF                      to built the Line Shape Function (LSF) module."
	@echo "    make Sigma                    to built the Cross Section (Sigma) module."
	@echo ""
	@echo ""
	@echo "    make clean_all_QE-5.0.2            to clean all the modules of the package using Quantum Espresso 5.0.2."
	@echo "    make clean_QE-5.0.2_dependent      to clean all the Quantum Espresso 5.0.2 dependent modules."
	@echo "    make cleanExport_QE-5.0.2          to clean the Quantum Espresso 5.0.2 dependent Export module."
	@echo "    make cleanTME                      to clean the Transition Matrix Elements (TME) module."
	@echo "    make cleanLSF                      to clean the Line Shape Function (LSF) module."
	@echo "    make cleanSigma                    to clean the Cross Section (Sigma) module."
	@echo ""
	@echo ""


Export_QE-5.0.2_srcPath = QE-dependent/QE-5.0.2/Export/src
TME_srcPath    = TME/src
LSF_srcPath    = LSF/src
Sigma_srcPath  = Sigma/src

bin = './bin'

all_QE-5.0.2 : initialize QE-5.0.2_dependent TME LSF Sigma

QE-5.0.2_dependent : initialize Export_QE-5.0.2

initialize :

	@echo "" > make.sys ; \
	echo "Home_Path      = " $(PWD) >> make.sys ; \
	echo "QE-5.0.2_Path           = " $(QE-5.0.2_Path) >> make.sys ; \
	echo "Export_QE-5.0.2_srcPath = " $(Export_QE-5.0.2_srcPath) >> make.sys ; \
	echo "TME_srcPath    = " $(TME_srcPath) >> make.sys ; \
	echo "LSF_srcPath = " $(LSF_srcPath) >> make.sys ; \
	echo "Sigma_srcPath = " $(Sigma_srcPath) >> make.sys ; \
	echo "" >> make.sys ; \
	echo "f90    = "$(f90) >> make.sys ; \
	echo "mpif90 = "$(mpif90) >> make.sys ; \
	echo "" >> make.sys
#
	@if test ! -d $(bin) ; then \
		mkdir $(bin) ; \
	fi


Export_QE-5.0.2 : initialize

	@cd $(Export_QE-5.0.2_srcPath) ; \
		make all

TME : initialize

	@cd $(TME_srcPath) ; \
        	make all

LSF : initialize

	@cd $(LSF_srcPath) ; \
        	make all

Sigma : initialize

	@cd $(Sigma_srcPath) ; \
        	make all


clean_all_QE-5.0.2 : clean_QE-5.0.2_dependent cleanTME cleanInitialization cleanLSF cleanSigma

clean_QE-5.0.2_dependent : cleanExport_QE-5.0.2

cleanInitialization :

	@if test -d bin ; then \
		/bin/rm -rf bin ; \
	fi
	@if test -e make.sys ; then \
		/bin/rm -f make.sys ; \
	fi

cleanExport_QE-5.0.2 :

	@cd $(Export_QE-5.0.2_srcPath) ; \
        	make clean

cleanTME :

	@cd $(TME_srcPath) ; \
		make clean

cleanLSF :

	@cd $(LSF_srcPath) ; \
		make clean

cleanSigma :

	@cd $(Sigma_srcPath) ; \
		make clean

