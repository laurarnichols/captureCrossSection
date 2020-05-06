program lineShapeFunction
  !
  use mpi
  use lsf
  !
  implicit none
  !
  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, myid, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, numprocs, ierr)
  !
  if ( myid == root ) then
    !
    call cpu_time(ti)
    !
    ! Reading input, initializing and checking all variables of the calculation.
    !
    call readInputs()
    !
    call computeGeneralizedDisplacements()
    !
    call computeVariables()
    !
    call initializeLSF()
    !
  endif
  !
  call MPI_BCAST(nModes   ,  1, MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(maximumNumberOfPhonons,  1, MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(minimumNumberOfPhonons,  1, MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST(nEnergies,  1, MPI_INTEGER,root,MPI_COMM_WORLD,ierr) 
  call MPI_BCAST(deltaE,     1, MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  !
  if ( myid /= root ) then
    allocate( phonF(nModes), x(nModes), Sj(nModes), coth(nModes), wby2kT(nModes) )
    allocate( besOrderNofModeM(0:maximumNumberOfPhonons + 1, nModes) )
  endif
  !
  call MPI_BCAST( phonF, size(phonF), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST( x, size(x), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST( Sj, size(Sj), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST( coth, size(coth), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST( wby2kT, size(wby2kT), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  call MPI_BCAST( besOrderNofModeM, size(besOrderNofModeM), MPI_DOUBLE_PRECISION,root,MPI_COMM_WORLD,ierr)
  !
  allocate( lsfVsEbyBands(-nEnergies:nEnergies) )
  allocate( iEbinsByBands(-nEnergies:nEnergies) )
  !
  allocate( pj(nModes) )
  !
  if ( myid == root ) then
    !
    if ( ( minimumNumberOfPhonons < 2 ) .and. ( maximumNumberOfPhonons > 0 ) ) then
      !
      ! One phonon
      !
      lsfVsEbyBands(:) = 0.0_dp
      iEbinsByBands(:) = 0
      !
      call lsfMbyOneBand(1)
      !
      ! calculate the DOS and update the total lsfVsE
      !
      call calculateDE(1, iEbinsByBands, de)
      !
      write(iostd,*) 'DE', 1,  de
      flush(iostd)
      !
      lsfVsE(:) = lsfVsE(:) + lsfVsEbyBands(:)/de
      !
      open(1, file='lsfVsEwithUpTo1phonons', status='unknown')
      !
      write(1,'("#", i10, " energies", i5, " phonons")') nEnergies, 1
      !
      do iE = -nEnergies, nEnergies
        E = real(iE, dp)*deltaE
        write(1,'(F16.8,2E18.6e3)') E*HartreeToEv, lsfVsE(iE), lsfVsEbyBands(iE)/de
      enddo
      !
      close(1)
      !
    endif
    !
    if ( ( minimumNumberOfPhonons < 3 ) .and. ( maximumNumberOfPhonons > 1 ) ) then
      !
      ! Two phonons
      !
      lsfVsEbyBands(:) = 0.0_dp
      iEbinsByBands(:) = 0
      !
      call cpu_time(t1)
      !
      call lsfMbyOneBand(2)
      call lsfMbyTwoBands(2)
      !
      call cpu_time(t2)
      !
      write(iostd,'(" 2 modes, time needed :," , f10.2, " secs.")') t2-t1
      flush(iostd)
      !
      ! calculate the DOS and update the total lsfVsE
      !
      call calculateDE(2, iEbinsByBands, de)
      !
      write(iostd,*) 'DE', 2,  de
      flush(iostd)
      !
      lsfVsE(:) = lsfVsE(:) + lsfVsEbyBands(:)/de
      !
      open(2, file='lsfVsEwithUpTo2phonons', status='unknown')
      !
      write(2,'("#", i10, " energies", i5, " phonons")') nEnergies, 2
      do iE = -nEnergies, nEnergies
        E = real(iE, dp)*deltaE
        write(2,'(F16.8,2E18.6e3)') E*HartreeToEv, lsfVsE(iE), lsfVsEbyBands(iE)/de
      enddo
      !
      close(2)
      !
    endif
    !
  endif
  !
  allocate( iModeIs(0:numprocs-1) )
  allocate( iModeFs(0:numprocs-1) )
  !
  iModeIs(:) =  0
  iModeFs(:) = -1
  !
  if ( ( minimumNumberOfPhonons < 4 ) .and. ( maximumNumberOfPhonons > 2 ) ) then
    !
    lsfVsEbyBands(:) = 0.0_dp
    iEbinsByBands(:) = 0
    !
    if ( myid == root ) then
      !
      call lsfMbyOneBand(3)
      call lsfMbyTwoBands(3)
      !
      call parallelIsFsBy3()
      !
    endif
    !
    call MPI_BCAST(iModeIs, size(iModeIs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    call MPI_BCAST(iModeFs, size(iModeFs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    !
    call lsfMbyThreeBands(3)
    !
    allocate ( iEbinsByPhonons(-nEnergies:nEnergies), lsfVsEbyPhonons(-nEnergies:nEnergies) )
    !
    iEbinsByPhonons = 0
    lsfVsEbyPhonons = 0.0_dp
    !
    CALL MPI_REDUCE(iEbinsByBands, iEbinsByPhonons, size(iEbinsByBands), MPI_INTEGER, MPI_SUM, root, MPI_COMM_WORLD, ierr)
    CALL MPI_REDUCE(lsfVsEbyBands, lsfVsEbyPhonons, size(lsfVsEbyPhonons), &
                                                               MPI_DOUBLE_PRECISION, MPI_SUM, root, MPI_COMM_WORLD, ierr)
    !
    if ( myid == root ) then
      !
      call calculateDE(3, iEbinsByPhonons, de)
      lsfVsE(:) = lsfVsE(:) + lsfVsEbyPhonons(:)/de
      !
      write(iostd,*) 'DE', 3,  de
      flush(iostd)
      !
      open(1, file='lsfVsEwithUpTo3phonons', status='unknown')
      !
      write(1,'("#", i10, " energies", i5, " phonons")') nEnergies, 3
      !
      do iE = -nEnergies, nEnergies
        !
        E = real(iE, dp)*deltaE
        write(1,'(F16.8,2E18.6e3)') E*HartreeToEv, lsfVsE(iE), lsfVsEbyPhonons(iE)/de
        !
      enddo
      !
      close(1)
      !
    endif
    !
    deallocate ( iEbinsByPhonons, lsfVsEbyPhonons )
    !
  endif
  !
  if ( ( minimumNumberOfPhonons < 5 ) .and. ( maximumNumberOfPhonons > 3 ) ) then
    !
    lsfVsEbyBands(:) = 0.0_dp
    iEbinsByBands(:) = 0
    !
    iModeIs(:) =  0
    iModeFs(:) = -1
    !
    if ( myid == root ) then
      !
      call lsfMbyOneBand(4)
      call lsfMbyTwoBands(4)
      !
      call parallelIsFsBy3()
      !
    endif
    !
    call MPI_BCAST(iModeIs, size(iModeIs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    call MPI_BCAST(iModeFs, size(iModeFs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    !
    call lsfMbyThreeBands(4)
    !
    iModeIs(:) =  0
    iModeFs(:) = -1
    !
    if ( myid == root ) call parallelIsFsBy4()
    !
    call MPI_BCAST(iModeIs, size(iModeIs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    call MPI_BCAST(iModeFs, size(iModeFs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
    !
    call lsfDeterministicFourPhononsByFourBands()
    !
    allocate ( iEbinsByPhonons(-nEnergies:nEnergies), lsfVsEbyPhonons(-nEnergies:nEnergies) )
    !
    iEbinsByPhonons = 0
    lsfVsEbyPhonons = 0.0_dp
    !
    CALL MPI_REDUCE(iEbinsByBands, iEbinsByPhonons, size(iEbinsByBands), MPI_INTEGER, MPI_SUM, root, MPI_COMM_WORLD, ierr)
    CALL MPI_REDUCE(lsfVsEbyBands, lsfVsEbyPhonons, size(lsfVsEbyPhonons), &
                                                               MPI_DOUBLE_PRECISION, MPI_SUM, root, MPI_COMM_WORLD, ierr)
    !
    if ( myid == root ) then
      !
      call calculateDE(4, iEbinsByPhonons, de)
      lsfVsE(:) = lsfVsE(:) + lsfVsEbyPhonons(:)/de
      !
      write(iostd,*) 'DE', 4,  de
      flush(iostd)
      !
      open(1, file='lsfVsEwithUpTo4phonons', status='unknown')
      !
      write(1,'("#", i10, " energies", i5, " phonons")') nEnergies, 4
      !
      do iE = -nEnergies, nEnergies
        !
        E = real(iE, dp)*deltaE
        write(1,'(F16.8,2E18.6e3)') E*HartreeToEv, lsfVsE(iE), lsfVsEbyPhonons(iE)/de
        !
      enddo
      !
      close(1)
      !
    endif
    !
    deallocate ( iEbinsByPhonons, lsfVsEbyPhonons )
    !
  endif
  !
  if ( maximumNumberOfPhonons > 4 ) then
    !
    open(unit=un, file="/dev/urandom", access="stream", form="unformatted", action="read", status="old", iostat=istat)
    !
    if ( myid == root ) then
      if (istat /= 0) then
        write(iostd, *) 'File "/dev/urandom" not found! A pseudo random generator will be used!'
      else
        write(iostd, *) 'File "/dev/urandom" will be used to generate real random numbers!'
      endif
      flush(iostd)
    endif
    !
    if (istat /= 0) close(un)
    !
    allocate ( iEbinsByPhonons(-nEnergies:nEnergies), lsfVsEbyPhonons(-nEnergies:nEnergies) )
    allocate ( lsfbyPhononsPerProc(-nEnergies:nEnergies) )
    !
    if ( minimumNumberOfPhonons < 6 ) minimumNumberOfPhonons = 5
    do m = minimumNumberOfPhonons, maximumNumberOfPhonons
      !
      lsfVsEbyBands(:) = 0.0_dp
      iEbinsByBands(:) = 0
      !
      iModeIs(:) =  0
      iModeFs(:) = -1
      !
      if ( myid == root ) then
        !
        call lsfMbyOneBand(m)
        call lsfMbyTwoBands(m)
        !
        call parallelIsFsBy3()
        !
      endif
      !
      call MPI_BCAST(iModeIs, size(iModeIs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(iModeFs, size(iModeFs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
      !
      call lsfMbyThreeBands(m)
      !
      lsfVsEbyPhonons = 0.0_dp
      !
      CALL MPI_REDUCE(lsfVsEbyBands, lsfVsEbyPhonons, size(lsfVsEbyPhonons), &
                                                                  MPI_DOUBLE_PRECISION, MPI_SUM, root, MPI_COMM_WORLD, ierr)
      !
      if (istat /= 0) CALL init_random_seed() 
      !
      iModeIs(:) =  0
      iModeFs(:) = -1
      !
      if ( myid == root ) then
        !
        iMint = int(nMC/numprocs)
        iMmod = mod(nMC,numprocs)
        !
        iModeIs(0) = 1
        iModeFs(numprocs-1) = nMC
        do i = numprocs - 1, 1, -1
          iModeIs(i) = i*iMint + 1
          if ( iMmod > 0 ) then
            iModeIs(i) = iModeIs(i) + iMmod
            iMmod = iMmod - 1
          endif
          iModeFs(i-1) = iModeIs(i) - 1
        enddo
        !
      endif
      !
      call MPI_BCAST(iModeIs, size(iModeIs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(iModeFs, size(iModeFs), MPI_INTEGER,root,MPI_COMM_WORLD,ierr)
      !
      do l = 4, m
        !
        times = 1.0_dp
        mi = l-1
        do ni = m - 1, m - l + 1, -1
          times = times*dble(ni)/dble(mi)
          mi = mi - 1
        enddo
        !
        allocate( pj0s(int(times + 1.e-3_dp), l) )
        !
        pj0s(:,:) = 0
        !
        call distrubutePhononsInBands(m, l) 
        !
        allocate( pms( 0:2**l-1, 0:l-1 ) )
        !
        pms(:,:) = 0
        !
        call calculatePlusMinusStates(l)
        !
        lsfVsEbyBands(:) = 0.0_dp
        !
        call lsfWithMphonons(m, l, int(times + 1.e-3_dp))
        !
        lsfbyPhononsPerProc(:) = 0.0_dp
        CALL MPI_REDUCE(lsfVsEbyBands, lsfbyPhononsPerProc, size(lsfbyPhononsPerProc), &
                                                            MPI_DOUBLE_PRECISION, MPI_SUM, root, MPI_COMM_WORLD, ierr)
        !
        if ( myid == root ) then
          !
          weight = nModes
          !
          do iMode = 2, l
            weight = weight*(nModes - iMode + 1)/iMode
          enddo
          !
          write(iostd, 101) m, l, times*weight
          write(iostd, 102) m, l, real(nMC, dp)
          write(iostd, 103) m, l, times*real(nMC, dp)
          write(iostd, 104) weight/real(nMC, dp)
          flush(iostd)
          !
          lsfVsEbyPhonons(:) = lsfVsEbyPhonons(:) + lsfbyPhononsPerProc(:)*weight/real(nMC, dp)
          !
        endif
        !
        deallocate( pj0s, pms )
        !
      enddo
      !
      iEbinsByPhonons = 0
      CALL MPI_REDUCE(iEbinsByBands, iEbinsByPhonons, size(iEbinsByBands), MPI_INTEGER, MPI_SUM, root, MPI_COMM_WORLD, ierr)
      !
      if ( myid == root ) then
        ! 
        call calculateDE(m, iEbinsByPhonons, de)
        lsfVsE(:) = lsfVsE(:) + lsfVsEbyPhonons(:)/de
        !
        write(iostd,*) 'DE', m,  de
        flush(iostd)
        !
        if ( m < 10 ) then
          write(fn,'("lsfVsEwithUpTo", i1, "phonons")') m
        elseif ( m < 100 ) then
          write(fn,'("lsfVsEwithUpTo", i2, "phonons")') m
        elseif ( m < 1000 ) then
          write(fn,'("lsfVsEwithUpTo", i3, "phonons")') m
        else
          write(fn,'("lsfVsEwithUpTo", i4, "phonons")') m
        endif
        !
        open(unit=5000, file=trim(fn), status='unknown')
        !
        write(5000,'("#", i10, " energies", i5, " phonons")') nEnergies, m
        !
        do iE = -nEnergies, nEnergies
          E = real(iE, dp)*deltaE
          write(5000,'(F16.8,2E18.6e3)') E*HartreeToEv, lsfVsE(iE), lsfVsEbyPhonons(iE)/de
        enddo
        !
        close(5000)
        !
      endif
      !
    enddo
    !
    deallocate ( iEbinsByPhonons, lsfVsEbyPhonons )
    !
    if (istat == 0) close(un)
    !
  endif
  !
  if ( myid == root ) then
    !
    call writeLSFandCrossSection()
    !
    call cpu_time(tf)
    !
    write(iostd,'(" Time needed: ", f10.2, " secs.")') tf-ti
    !
  endif
  !
 101 format("   Total number of configurations of ", i4, " phonons by ", i4, " bands : ", E20.10E3)
 102 format("   Total number of configurations of ", i4, " phonons by ", i4, " bands sampled : ", E20.10E3)
 103 format("   Total number of configurations of ", i4, " phonons by ", i4, " bands calculated : ", E20.10E3)
 104 format("   Each sampled configuration will be weighted by : ", E20.10E3)
  !
  call MPI_FINALIZE(ierr)
  !
end program lineShapeFunction
