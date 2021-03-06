module pf_nuopc_test_drv

  use ESMF
  use NUOPC
  use NUOPC_Driver, &
    driver_routine_SS             => SetServices, &
    driver_label_SetModelServices => label_SetModelServices, &
    driver_label_SetRunSequence   => label_SetRunSequence
  use NUOPC_Connector,   only: cpl_ss => SetServices
  use pf_nuopc_test_lnd, only: lnd_ss => SetServices
  use parflow_nuopc,     only: pf_ss  => SetServices

  implicit none

  private

  public SetServices

  !-----------------------------------------------------------------------------
  contains
  !-----------------------------------------------------------------------------

  subroutine SetServices(driver, rc)
    type(ESMF_GridComp)  :: driver
    integer, intent(out) :: rc
    ! local variables
    type(ESMF_Config) :: config

    rc = ESMF_SUCCESS

    ! derive generic driver phases
    call NUOPC_CompDerive(driver, driver_routine_SS, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! set entry points for specialized methods
    call NUOPC_CompSpecialize(driver, specLabel=driver_label_SetModelServices, &
      specRoutine=SetModelServices, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_CompSpecialize(driver, specLabel=driver_label_SetRunSequence, &
      specRoutine=SetRunSequence, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! create, open and set the config
    config = ESMF_ConfigCreate(rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigLoadFile(config, filename="nuopc_test.cfg", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_GridCompSet(driver, config=config, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
  end subroutine SetServices

  !-----------------------------------------------------------------------------

  subroutine SetModelServices(driver, rc)
    type(ESMF_GridComp)  :: driver
    integer, intent(out) :: rc
    ! local variables
    type(ESMF_Config)             :: config
    type(NUOPC_FreeFormat)        :: attrFF
    integer, allocatable          :: petList(:)
    integer                       :: dt
    type(ESMF_Time)               :: startTime
    type(ESMF_Time)               :: stopTime
    type(ESMF_TimeInterval)       :: timeStep
    type(ESMF_Clock)              :: internalClock
    type(ESMF_GridComp)           :: child
    type(ESMF_CplComp)            :: connector

    rc = ESMF_SUCCESS

    call ESMF_GridCompGet(driver, config=config, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! read driver attributes
    attrFF = NUOPC_FreeFormatCreate(config, label="driverAttributes::", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_CompAttributeIngest(driver, attrFF, addFlag=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FreeFormatDestroy(attrFF, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! create stub lnd component
    call getPetListFromConfig(config, "pets_lnd:", petList=petList, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    if (allocated(petList)) then
      call NUOPC_DriverAddComp(driver, "LND", lnd_ss, petList=petList, &
        comp=child, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      deallocate(petList)
    else
      call NUOPC_DriverAddComp(driver, "LND", lnd_ss, comp=child, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
    end if
    call NUOPC_CompAttributeSet(child, name="Verbosity", value="1", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    attrFF = NUOPC_FreeFormatCreate(config, label="lndAttributes::", &
      relaxedflag=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_CompAttributeIngest(child, attrFF, addFlag=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FreeFormatDestroy(attrFF, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! create parflow component
    call getPetListFromConfig(config, "pets_hyd:", petList=petList, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    if (allocated(petList)) then
      call NUOPC_DriverAddComp(driver, "HYD", pf_ss, petList=petList, &
        comp=child, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      deallocate(petList)
    else
      call NUOPC_DriverAddComp(driver, "HYD", pf_ss, comp=child, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
    end if
    call NUOPC_CompAttributeSet(child, name="Verbosity", value="131071", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    attrFF = NUOPC_FreeFormatCreate(config, label="hydAttributes::", &
      relaxedflag=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_CompAttributeIngest(child, attrFF, addFlag=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FreeFormatDestroy(attrFF, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! read clock set up from config
    call getTimeFromConfig(config, "start_time:", startTime, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call getTimeFromConfig(config, "stop_time:", stopTime, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigGetAttribute(config, dt, label="time_step:", &
      default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    if (dt == -1) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
        msg="time_step not set in run config", &
        line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    endif
    call ESMF_TimeIntervalSet(timeStep, s=dt, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    internalClock = ESMF_ClockCreate(name="LND-HYD-Clock", &
      timeStep=timeStep, startTime=startTime, stopTime=stopTime, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_GridCompSet(driver, clock=internalClock, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! add field dictionary
    call NUOPC_FieldDictionaryAddEntry( StandardName="parflow_flux", &
      canonicalUnits="m d-1", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FieldDictionaryAddEntry( StandardName="parflow_porosity", &
      canonicalUnits="-", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FieldDictionaryAddEntry( StandardName="parflow_pressure", &
      canonicalUnits="m", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FieldDictionaryAddEntry( StandardName="parflow_saturation", &
      canonicalUnits="-", rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
  end subroutine SetModelServices

  subroutine SetRunSequence(driver, rc)
    type(ESMF_GridComp)  :: driver
    integer, intent(out) :: rc
    ! local variables
    type(ESMF_Config)             :: config
    type(NUOPC_FreeFormat)        :: runSeqFF
    type(ESMF_CplComp), pointer   :: connectorList(:)
    integer                       :: i
    type(NUOPC_FreeFormat)        :: attrFF

    rc = ESMF_SUCCESS

    call ESMF_GridCompGet(driver, config=config, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! read free format run sequence from config
    runSeqFF = NUOPC_FreeFormatCreate(config, label="runSeq::", &
      relaxedflag=.false., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_DriverIngestRunSequence(driver, runSeqFF, &
      autoAddConnectors=.true., rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call NUOPC_FreeFormatDestroy(runSeqFF, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    ! set connector attributes
    nullify(connectorList)
    call NUOPC_DriverGetComp(driver, compList=connectorList, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    do i=1, size(connectorList)
      call NUOPC_CompAttributeSet(connectorList(i), name="Verbosity", &
        value="1", rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      attrFF = NUOPC_FreeFormatCreate(config, label="connectorAttributes::", &
        relaxedflag=.true., rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      call NUOPC_CompAttributeIngest(connectorList(i), attrFF, &
        addFlag=.true., rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      call NUOPC_FreeFormatDestroy(attrFF, rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
    enddo
    deallocate(connectorList)
  end subroutine SetRunSequence

  subroutine getPetListFromConfig(config, label, instance, petList, rc)
    type(ESMF_Config), intent(inout)    :: config
    character(len=*), intent(in)        :: label
    integer, intent(in), optional       :: instance
    integer, allocatable, intent(inout) :: petList(:)
    integer, intent(out)                :: rc
    ! local variables
    integer              :: l_instance
    logical              :: isPresent
    integer              :: attrCnt
    integer, allocatable :: petBoundsList(:)
    integer              :: i, minPet, maxPet

    if (present(instance)) then
      l_instance = instance
    else
      l_instance = 1
    endif

    call ESMF_ConfigFindLabel(config, trim(label), &
      isPresent=isPresent, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    if (isPresent) then
      attrCnt = ESMF_ConfigGetLen(config, label=trim(label), rc=rc)
      if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__)) return
      if (attrCnt .ge. (l_instance*2)) then
        allocate (petBoundsList(attrCnt), stat=rc)
        if (ESMF_LogFoundAllocError(statusToCheck=rc, &
          msg="Could not allocate petBoundsList", &
          line=__LINE__, file=__FILE__)) return
        call ESMF_ConfigGetAttribute(config, petBoundsList, &
          label=trim(label), rc=rc)
        if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
          line=__LINE__, file=__FILE__)) return
        minPet = petBoundsList((2*l_instance)-1)
        maxPet = petBoundsList(2*l_instance)
        deallocate(petBoundsList, stat=rc)
        if (ESMF_LogFoundDeallocError(statusToCheck=rc, &
          msg="Could not deallocate petBoundsList", &
          line=__LINE__, file=__FILE__)) return
        if (minPet <= maxPet) then
          allocate(petList(maxPet-minPet+1), stat=rc)
          do i=1, maxPet-minPet+1
            petList(i) = minPet+i-1
          enddo
        else
          deallocate (petList, stat=rc)
          if (ESMF_LogFoundDeallocError(statusToCheck=rc, &
            msg="Could not deallocate petList", &
            line=__LINE__, file=__FILE__)) return
          call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
            msg=trim(label)//" min must be <= max", &
            line=__LINE__, file=__FILE__, rcToReturn=rc)
          return
        endif
      else
        call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
          msg=trim(label)//" PET bounds missing", &
          line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      endif
    endif

  end subroutine getPetListFromConfig

  subroutine getTimeFromConfig(config, label, tm, rc)
    type(ESMF_Config), intent(inout) :: config
    character(len=*), intent(in)     :: label
    type(ESMF_Time), intent(inout)   :: tm
    integer, intent(out)             :: rc
    ! local variables
    logical :: isPresent
    integer :: yy, mm, dd, h, m

    call ESMF_ConfigFindLabel(config, trim(label), &
      isPresent=isPresent, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    if (.not. isPresent) then
      call ESMF_LogSetError(ESMF_RC_ARG_BAD, &
        msg=trim(label)//" is not present in run config file", &
        line=__LINE__, file=__FILE__, rcToReturn=rc)
      return
    endif
    call ESMF_ConfigGetAttribute(config, yy, default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigGetAttribute(config, mm, default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigGetAttribute(config, dd, default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigGetAttribute(config, h, default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return
    call ESMF_ConfigGetAttribute(config, m, default=-1, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

    call ESMF_TimeSet(tm, yy=yy, mm=mm, dd=dd, h=h, m=m, &
      calkindflag=ESMF_CALKIND_GREGORIAN, rc=rc)
    if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
      line=__LINE__, file=__FILE__)) return

  end subroutine getTimeFromConfig

end module pf_nuopc_test_drv
