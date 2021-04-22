!-------------------------------------------------------------------------------
! Define Defaults
!-------------------------------------------------------------------------------
#define CONTEXT  line=__LINE__,file=__FILE__
#define PASSTHRU msg=ESMF_LOGERR_PASSTHRU,CONTEXT
#define ESMF_STDERRORCHECK(rc) ESMF_LogFoundError(rcToCheck=rc,msg=ESMF_LOGERR_PASSTHRU,line=__LINE__,file=__FILE__)

!-------------------------------------------------------------------------------
! Define ESMF real kind to match Appplications single/double precision
!-------------------------------------------------------------------------------
#if defined(REAL4)
#define ESMF_KIND_FIELD ESMF_KIND_R4
#define ESMF_KIND_COORD ESMF_KIND_R4
#define ESMF_DEFAULT_VALUE 9.99e20_ESMF_KIND_R8
#define ESMF_TYPEKIND_FIELD ESMF_TYPEKIND_R4
#define ESMF_TYPEKIND_COORD ESMF_TYPEKIND_R4
#elif defined(REAL8)
#define ESMF_KIND_FIELD ESMF_KIND_R8
#define ESMF_KIND_COORD ESMF_KIND_R8
#define ESMF_DEFAULT_VALUE 9.99e20_ESMF_KIND_R8
#define ESMF_TYPEKIND_FIELD ESMF_TYPEKIND_R8
#define ESMF_TYPEKIND_COORD ESMF_TYPEKIND_R8
#else
#define ESMF_KIND_FIELD ESMF_KIND_R4
#define ESMF_KIND_COORD ESMF_KIND_R8
#define ESMF_DEFAULT_VALUE 9.99e20_ESMF_KIND_R8
#define ESMF_TYPEKIND_FIELD ESMF_TYPEKIND_R4
#define ESMF_TYPEKIND_COORD ESMF_TYPEKIND_R8
#endif

