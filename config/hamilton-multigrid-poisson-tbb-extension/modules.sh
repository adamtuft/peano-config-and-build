module purge
module load python
module load oneapi/2024.2
export FLAVOUR_NOCONFLICT=1
module load gcc/14.2
module load intelmpi
module load tbb/2022.0
export I_MPI_CXX=icpx
