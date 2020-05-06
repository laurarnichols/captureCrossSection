
module sigma_module
  !
  implicit none
  !
  integer, parameter :: dp    = selected_real_kind(15, 307)
  integer, parameter :: int32 = selected_int_kind(5)
  integer, parameter :: iostd = 16
  !
  real(kind = dp), parameter ::           pi = 3.1415926535897932_dp
  real(kind = dp), parameter ::        twopi = 2.0_dp*pi
  real(kind = dp), parameter ::         abCM = 0.529177219217e-8_dp
  real(kind = dp), parameter :: HartreeToEv  = 27.21138386_dp
  real(kind = dp), parameter :: eVToHartree  = 1.0_dp/27.21138386_dp
  !
  integer(kind = int32) :: ios
  integer :: nEnergies, m, nw
  !
  real(kind = dp) :: maxEnergy, volume, de, eifMin, DHifMin
  !
  real(kind = dp), allocatable :: E(:), Vfis(:), lsfVsE(:), lsfVsEbyPhonon(:)
  real(kind = dp), allocatable :: sigma(:), sigma1(:), sigmaByPhonon(:), lorentz(:), lorentzByPhonon(:)
  !
  character(len = 11), parameter :: output = 'sigmaStatus'
  character(len = 256) :: VfisInput, LSFinput, crossSectionOutput
  !
  logical :: file_exists
  !
  namelist /elphscat/ VfisInput, LSFinput, crossSectionOutput, maxEnergy
  !
  !
contains
  !
  !
  subroutine readInputs()
    !
    implicit none
    !
    ! Check if file output exists. If it does, delete it.
    !
    inquire(file = output, exist = file_exists)
    if ( file_exists ) then
      open (unit = 11, file = output, status = "old")
      close(unit = 11, status = "delete")
    endif
    !
    ! Open new output file.
    !
    open (iostd, file = output, status='new')
    !
    call initialize()
    !
    READ (5, elphscat, iostat = ios)
    !
    call checkAndUpdateInput()
    !
    call readLSF()
    !
    call readVfis()
    !
    return
    !
  end subroutine readInputs
  !
  !
  subroutine initialize()
    !
    implicit none
    !
    VfisInput = ''
    LSFinput = ''
    crossSectionOutput = ''
    maxEnergy = -1.0_dp
    !
    return
    !
  end subroutine initialize
  !
  !
  subroutine checkAndUpdateInput()
    !
    implicit none
    !
    if ( VfisInput == '' ) then
      write(iostd, '(" Vfi elements input (input variable VfisInput) is not defined!")')
    else
      inquire(file =trim(VfisInput), exist = file_exists)
      if ( file_exists ) then
        write(iostd, '(" Vfi elements input : ", a)') trim(VfisInput)
      else
        write(iostd, '(" Vfi elements input : ", a, " does not exist!")') trim(VfisInput)
      endif
    endif
    !
    if ( LSFinput == '' ) then
      write(iostd, '(" LSF input (input variable LSFinput) is not defined!")')
    else
      inquire(file =trim(LSFinput), exist = file_exists)
      if ( file_exists ) then
        write(iostd, '(" LSF input : ", a)') trim(LSFinput)
      else
        write(iostd, '(" LSF input : ", a, " does not exist!")') trim(LSFinput)
      endif
    endif
    !
    if ( crossSectionOutput == '' ) then
      write(iostd, '(" crossSectionOutput is not defined! File name : crossSection, will be used.")')
      crossSectionOutput = 'crossSection'
    else
      write(iostd, '(" Cross section output file name : ", a)') trim(crossSectionOutput)
    endif
    !
    if ( maxEnergy < 0.0_dp ) then
      write(iostd, '(" Maximum energy (input variable maxEnergy) is not defined ! A default value of 10 eV will be used.")')
      maxEnergy = 10.0_dp
    else
      write(iostd, '(" Maximum energy : ", f10.5, " eV.")') maxEnergy
    endif
    !
    nw = 5040 
    de = maxEnergy*eVToHartree/real(nw, dp)
    !
    if ( ( VfisInput == '' ) .or. ( LSFinput == '' ) ) then
      write(iostd, '(" ********************************* ")')
      write(iostd, '(" * Program stops!                * ")')
      write(iostd, '(" * Please check the output file. * ")')
      write(iostd, '(" ********************************* ")')
      stop
    endif
    !
    flush(iostd)
    !
    return
    !
  end subroutine checkAndUpdateInput
  !
  !
  subroutine readLSF()
    !
    implicit none
    !
    character(len = 1) :: dummyC1
    character(len = 8) :: dummyC8
    character(len = 9) :: dummyC9
    !
    real(kind = dp) :: ee
    !
    integer :: iE
    !
    open(1, file=trim(LSFinput), status='old')
    !
    read(1,'(a1, i10, a9, i5, a8)') dummyC1, nEnergies, dummyC9, m, dummyC8
    !
    allocate ( E(-nEnergies:nEnergies), lsfVsE(-nEnergies:nEnergies), lsfVsEbyPhonon(-nEnergies:nEnergies) )
    !
    do iE = -nEnergies, nEnergies
      !
      read(1,'(F16.8,2E18.6e3)') ee, lsfVsE(iE), lsfVsEbyPhonon(iE)
      !
      E(iE) = ee*eVToHartree
      !
    enddo
    !
    close(1)
    !
  end subroutine readLSF
  !
  !
  subroutine readVfis()
    !
    implicit none
    !
    integer :: i, iE0, iE, nEVfi
    real(kind = dp) :: dummyD1, dummyD2, E, VfiOfE, VfiOfE0, deltaE
    character(len =  1) :: dummyC1
    character(len = 32) :: dummyC32
    character(len = 35) :: dummyC35
    !
    open(1, file=trim(VfisInput), status="old")
    !
    nEVfi = 31
    !read(1, '(a1, i10, a9, f15.4, a16)') dummyC1, nEVfi, dummyC9, volume, dummyC16
    !
    read(1, *)
    read(1, '(a32, ES24.15E3, a35)') dummyC32, volume, dummyC35
    read(1, '(a32, ES24.15E3, a35)') dummyC32, eifMin, dummyC35
    read(1, '(a32, ES24.15E3, a35)') dummyC32, DHifMin, dummyC35
    read(1, *) 
    read(1, *)
    !
    allocate ( Vfis(-nEnergies:nEnergies) )
    !
    Vfis(:) = 0.0_dp
    !
    read(1, '(3ES24.15E3)' ) E, VfiOfE0, dummyD1
    !
    deltaE = maxEnergy*eVToHartree/real(nEnergies, dp)
    !
    iE = int(E/deltaE) + 1
    !
    do i = 1, nEVfi - 1
      !
      iE0 = iE
      read(1, '(3ES24.15E3)' ) E, VfiOfE, dummyD2
      iE = int(E/deltaE) + 1
      Vfis(iE0:iE) = VfiOfE0
      VfiOfE0 = VfiOfE
      !
    enddo
    !
    close(1)
    !
    do iE = -nEnergies, nEnergies
      write(44,*) real(iE, dp)*deltaE*HartreeToEv, Vfis(iE)
    enddo
    !
    return
    !
  end subroutine readVfis
  !
  !
  subroutine calculateSigma()
    !
    implicit none
    !
    integer :: iE, iE0
    real(kind = dp) :: vg, sigma0
    !
    logical :: notFound
    !
    allocate( sigma(-nEnergies:nEnergies), sigma1(-nEnergies:nEnergies), sigmaByPhonon(-nEnergies:nEnergies) )
    !
    iE = int(eifMin/de) + 1
    write(6,*) eifMin, eifMin*HartreeToEv, iE
    sigma0 = twoPi*abCM**2*volume*DHifMin*lsfVsE(iE)/sqrt(2.0_dp*E(iE))
    !
    !do iE = -nEnergies, nEnergies - 1
    !  if ( (E(iE) < eifMin).and.(E(iE+1) > eifMin) ) sigma0 = twoPi*abCM**2*volume*DHifMin*lsfVsE(iE)/sqrt(2.0_dp*E(iE))
    !enddo
    !
    write(6,*) eifMin*HartreeToEv, sigma0
    !
    sigma(:) = 0.0_dp
    sigma1(:) = 0.0_dp
    sigmaByPhonon(:) = 0.0_dp
    !
    notFound = .true.
    do iE = -nEnergies, nEnergies
      vg = 1.0_dp
      if ( Vfis(iE) > 0.0_dp ) vg = sqrt(2.0_dp*E(iE))
      sigma(iE)         = twoPi*abCM**2*volume*Vfis(iE)*lsfVsE(iE)/vg
      sigmaByPhonon(iE) = twoPi*abCM**2*volume*Vfis(iE)*lsfVsEbyPhonon(iE)/vg
      if ( Vfis(iE) > 0.0_dp ) then
        sigma1(iE)        = twoPi*abCM**2*volume*DHifMin*lsfVsE(iE)/vg
      else
        sigma1(iE) = 0.0_dp
      endif
      if ( ( Vfis(iE) > 0.0_dp ).and.(notFound)) then 
        iE0 = iE
        notFound = .false.
      endif
    enddo
    !
    write(6,*) 'lalal', iE0, E(iE0)*HartreeToEv, Vfis(iE0), sigma1(iE0)
    !
    return
    !
  end subroutine calculateSigma
  !
  !
  subroutine writeSigma()
    !
    implicit none
    !
    integer :: iE
    !
    open(2, file=trim(crossSectionOutput), status='unknown')
    !
    do iE = -nEnergies, nEnergies
      !
      write(2,*) E(iE)*HartreeToEv, sigma(iE), sigmaByPhonon(iE), sigma1(iE)
      !
    enddo
    !
    close(2)
    !
    return
    !
  end subroutine writeSigma
  !
  !
end module sigma_module
