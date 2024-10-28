#!/bin/sh

export CIME_MODEL=e3sm
export COMPSET=2000_DATM%QIA_ELM%BGC-FATES_SICE_SOCN_SROF_SGLC_SWAV 
export RES=f45_f45
export MACH=pm-cpu
export PROJECT=e3sm
export COMPILER=intel

export TAG='cnp_test1'
export CASEROOT=/pscratch/sd/j/jneedham/elm_runs/fates-cnp/
export CIMEROOT=/global/homes/j/jneedham/E3SM/cime/scripts
cd ${CIMEROOT}

export CIME_HASH=`git log -n 1 --pretty=%h`
export ELM_HASH=`(cd ../../components/elm/src;git log -n 1 --pretty=%h)`
export FATES_HASH=`(cd ../../components/elm/src/external_models/fates;git log -n 1 --pretty=%h)`
export GIT_HASH=E${ELM_HASH}-F${FATES_HASH}	
export CASE_NAME=${CASEROOT}/${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`


STAGE=AD_SPINUP
#STAGE=POSTAD_SPINUP
#STAGE=TRANSIENT

if [ "$STAGE" = "AD_SPINUP" ]; then
    SETUP_CASE=fates_4x5_nocomp_0006_bgcspinup_v5noseedrain_frombareground
elif [ "$STAGE" = "POSTAD_SPINUP" ]; then
    SETUP_CASE=fates_4x5_nocomp_0006_bgcpostadspinup_v5noseedrain
elif ["$STAGE"= "TRANSIENT"]; then
    SETUP_CASE=fates_4x5_nocomp_0006_bgctransientspinup_v5noseedrain
fi
    
CASE_NAME=${SETUP_CASE}_${TAG}.${GIT_HASH}.`date +"%Y-%m-%d"`

cd ${CIMEROOT}

./create_newcase -case ${CASE_NAME} -res ${RES} -compset ${COMPSET} -mach ${MACH} -project ${PROJECT}

cd $CASE_NAME

if [ "$STAGE" = "AD_SPINUP"  ]; then

    ./xmlchange RUN_STARTDATE=0001-01-01
    ./xmlchange RESUBMIT=1
    ./xmlchange STOP_N=30
    ./xmlchange REST_N=5
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange REST_OPTION=nyears
    ./xmlchange SAVE_TIMING=FALSE
    ./xmlchange JOB_QUEUE=regular
    ./xmlchange JOB_WALLCLOCK_TIME=06:00:00
    ./xmlchange CCSM_CO2_PPMV=287.

    ./xmlchange ELM_ACCELERATED_SPINUP=on
    ./xmlchange ELM_BLDNML_OPTS="-bgc fates -no-megan -no-drydep -nutrient cnp -nutrient_comp_pathway rd -soil_decomp century -bgc_spinup on"
    
    ./xmlchange DATM_MODE=CLMGSWP3v1
    ./xmlchange DATM_CLMNCEP_YR_ALIGN=1965
    ./xmlchange DATM_CLMNCEP_YR_START=1965
    ./xmlchange DATM_CLMNCEP_YR_END=2013
    # Read climate data from DVS (on CFS) in read-only mode - magic speed gains
    ./xmlchange DIN_LOC_ROOT="/dvs_ro/cfs/cdirs/e3sm/inputdata"
    ./xmlchange DIN_LOC_ROOT_CLMFORC="/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7"

    # Use 2 nodes per job (with default 128 MPI tasks per node)
    ./xmlchange NTASKS=512
    # Fewer MPIs to ATM and spread those out evenly
    ./xmlchange ATM_NTASKS=8
    ./xmlchange ATM_PSTRID=32

    ./xmlchange GMAKE=make
    ./xmlchange RUNDIR=${CASE_NAME}/run
    ./xmlchange EXEROOT=${CASE_NAME}/bld
    

    cat > user_nl_elm <<EOF
fates_parteh_mode=2
nu_comp='rd'
use_fates_luh = .false.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
fates_paramfile = '/global/homes/j/jneedham/CNP-scripts/param-files/fates_params_api36_updates.nc'
use_fates_sp = .false.
fates_spitfire_mode = 1
fates_harvest_mode = 'no_harvest'
use_fates_potentialveg = .true.
fluh_timeseries = ''
use_century_decomp = .true.
spinup_state = 1
suplphos = 'ALL'
suplnitro = 'ALL'
EOF

elif [ "$STAGE" = "POSTAD_SPINUP" ]; then

    ./xmlchange RUN_STARTDATE=0001-01-01
    ./xmlchange RESUBMIT=0
    ./xmlchange STOP_N=1
    ./xmlchange REST_N=1
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange REST_OPTION=nyears
    ./xmlchange JOB_QUEUE=regular
    ./xmlchange JOB_WALLCLOCK_TIME=06:00:00
    ./xmlchange CCSM_CO2_PPMV=287.

    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange ELM_BLDNML_OPTS="-bgc fates -no-megan -no-drydep -nutrient cnp -nutrient_comp_pathway rd -soil_decomp century"
    
    ./xmlchange DATM_MODE=CLMGSWP3v1
    ./xmlchange DATM_CLMNCEP_YR_ALIGN=1965
    ./xmlchange DATM_CLMNCEP_YR_START=1965
    ./xmlchange DATM_CLMNCEP_YR_END=2013
    # Read climate data from DVS (on CFS) in read-only mode - magic speed gains
    ./xmlchange DIN_LOC_ROOT="/dvs_ro/cfs/cdirs/e3sm/inputdata"
    ./xmlchange DIN_LOC_ROOT_CLMFORC="/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7"

    # Use 2 nodes per job (with default 128 MPI tasks per node)
    ./xmlchange NTASKS=512
    # Fewer MPIs to ATM and spread those out evenly
    ./xmlchange ATM_NTASKS=8
    ./xmlchange ATM_PSTRID=32

    ./xmlchange GMAKE=make
    ./xmlchange RUNDIR=${CASE_NAME}/run
    ./xmlchange EXEROOT=${CASE_NAME}/bld


    cat > user_nl_elm <<EOF
finidat=''
fates_parteh_mode=2
nu_comp='rd'
use_fates_luh = .false.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
fates_paramfile = '/global/homes/j/jneedham/CNP-scripts/param-files/fates_params_api36_updates.nc'
use_fates_sp = .false.
fates_spitfire_mode = 1
fates_harvest_mode = 'no_harvest'
use_fates_potentialveg = .true.
fluh_timeseries = ''
use_century_decomp = .true.
spinup_state = 0
suplphos = 'ALL'
suplnitro = 'NONE'
EOF

elif [ "$STAGE" = "TRANSIENT" ]; then

    ./xmlchange RUN_STARTDATE=2000-01-01
    ./xmlchange RESUBMIT=0
    ./xmlchange STOP_N=1
    ./xmlchange REST_N=1
    ./xmlchange STOP_OPTION=nyears
    ./xmlchange REST_OPTION=nyears
    ./xmlchange JOB_QUEUE=regular
    ./xmlchange JOB_WALLCLOCK_TIME=06:00:00
    ./xmlchange CCSM_CO2_PPMV=287.

    ./xmlchange ELM_ACCELERATED_SPINUP=off
    ./xmlchange ELM_BLDNML_OPTS="-bgc fates -no-megan -no-drydep -nutrient cnp -nutrient_comp_pathway rd -soil_decomp century"
    
    ./xmlchange DATM_MODE=CLMGSWP3v1
    ./xmlchange DATM_CLMNCEP_YR_ALIGN=1965
    ./xmlchange DATM_CLMNCEP_YR_START=1965
    ./xmlchange DATM_CLMNCEP_YR_END=2013
    # Read climate data from DVS (on CFS) in read-only mode - magic speed gains
    ./xmlchange DIN_LOC_ROOT="/dvs_ro/cfs/cdirs/e3sm/inputdata"
    ./xmlchange DIN_LOC_ROOT_CLMFORC="/dvs_ro/cfs/cdirs/e3sm/inputdata/atm/datm7"

    # Use 2 nodes per job (with default 128 MPI tasks per node)
    ./xmlchange NTASKS=512
    # Fewer MPIs to ATM and spread those out evenly
    ./xmlchange ATM_NTASKS=8
    ./xmlchange ATM_PSTRID=32

    ./xmlchange GMAKE=make
    ./xmlchange RUNDIR=${CASE_NAME}/run
    ./xmlchange EXEROOT=${CASE_NAME}/bld


    cat > user_nl_elm <<EOF
finidat=''
fates_parteh_mode=2
nu_comp='rd'
use_fates_luh = .false.
use_fates_nocomp = .true.
use_fates_fixed_biogeog = .true.
fates_paramfile = '/global/homes/j/jneedham/CNP-scripts/param-files/fates_params_api36_updates.nc'
use_fates_sp = .false.
fates_spitfire_mode = 1
fates_harvest_mode = 'no_harvest'
use_fates_potentialveg = .true.
fluh_timeseries = ''
use_century_decomp = .true.
spinup_state = 0
suplphos = 'ALL'
suplnitro = 'NONE'
EOF
    
fi


./case.setup
./case.build
./case.submit
