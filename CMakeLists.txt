# Specify the minimum required version of CMake
cmake_minimum_required(VERSION 3.10)

# Project name and the languages used
project(EigenExa LANGUAGES C Fortran)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(C_DIR "${CMAKE_CURRENT_SOURCE_DIR}/C")

set(FORTRAN_SOURCES
    ${SRC_DIR}/MPI_Allreduce_group.F90
    ${SRC_DIR}/CSTAB.F
    ${SRC_DIR}/eigen_house.F
    ${SRC_DIR}/eigen_house_h.F
    ${SRC_DIR}/eigen_dc.F
    ${SRC_DIR}/eigen_trbak.F
    ${SRC_DIR}/eigen_hrbak.F
    ${SRC_DIR}/eigen_blacs.F
    ${SRC_DIR}/eigen_devel.F
    ${SRC_DIR}/comm.F
    ${SRC_DIR}/comm_h.F
    ${SRC_DIR}/eigen_libs0.F
    ${SRC_DIR}/eigen_libs.F
    ${SRC_DIR}/FS_const.F90
    ${SRC_DIR}/FS_libs.F90
    ${SRC_DIR}/FS_prof.F90
    ${SRC_DIR}/dlacpy.F
    ${SRC_DIR}/lapack_eigen.F
    ${SRC_DIR}/my_pdlaedz.F
    ${SRC_DIR}/my_pdlaed3.F
    ${SRC_DIR}/my_pdlaed2.F
    ${SRC_DIR}/my_pdlaed1.F
    ${SRC_DIR}/my_pdlaed0.F
    ${SRC_DIR}/my_pdlasrt.F
    ${SRC_DIR}/my_pdsxedc.F
    ${SRC_DIR}/mx_pdlaedz.F
    ${SRC_DIR}/mx_pdlaed3.F
    ${SRC_DIR}/mx_pdlaed2.F
    ${SRC_DIR}/mx_pdlaed1.F
    ${SRC_DIR}/mx_pdlaed0.F
    ${SRC_DIR}/mx_pdstedc.F
    ${SRC_DIR}/dc_redist1.F
    ${SRC_DIR}/dc_redist1_r.F
    ${SRC_DIR}/dc_redist2.F
    ${SRC_DIR}/dc_redist2_r.F
    ${SRC_DIR}/dc2.F
    ${SRC_DIR}/dcx.F
    ${SRC_DIR}/bisect.F
    ${SRC_DIR}/bisect2.F
    ${SRC_DIR}/eigen_t1.F
    ${SRC_DIR}/eigen_trd_t2.F
    ${SRC_DIR}/eigen_trd_t4.F
    ${SRC_DIR}/eigen_trd_t5.F
    ${SRC_DIR}/eigen_trd_t5x.F
    ${SRC_DIR}/eigen_trd_t6_3.F
    ${SRC_DIR}/eigen_trd_t7.F
    ${SRC_DIR}/eigen_trd_t8.F
    ${SRC_DIR}/eigen_trd.F
    ${SRC_DIR}/eigen_prd_t2.F
    ${SRC_DIR}/eigen_prd_t4x.F
    ${SRC_DIR}/eigen_prd_t5.F
    ${SRC_DIR}/eigen_prd_t6_3.F
    ${SRC_DIR}/eigen_prd_t7.F
    ${SRC_DIR}/eigen_prd_t8.F
    ${SRC_DIR}/eigen_prd.F
    ${SRC_DIR}/trbakwy4_body.F
    ${SRC_DIR}/trbakwy4.F
    ${SRC_DIR}/eigen_scaling.F
    ${SRC_DIR}/eigen_identity.F
    ${SRC_DIR}/eigen_sx.F
    ${SRC_DIR}/eigen_s.F
    ${SRC_DIR}/FS_dividing.F90
    ${SRC_DIR}/FS_EDC.F90
    ${SRC_DIR}/FS_PDLAED0.F90
    ${SRC_DIR}/FS_PDLAED1.F90
    ${SRC_DIR}/FS_PDLAED2.F90
    ${SRC_DIR}/FS_PDLAED3.F90
    ${SRC_DIR}/FS_PDLAEDZ.F90
    ${SRC_DIR}/FS_MERGE_D.F90
    ${SRC_DIR}/FS_REDUCE_ZD.F90
    ${SRC_DIR}/FS_PDLASRT.F90
    ${SRC_DIR}/FS2eigen_PDLASRT.F90
    ${SRC_DIR}/dc2_FS.F
    ${SRC_DIR}/eigen_FS.F
    ${SRC_DIR}/FS_memory_internal.F
    ${SRC_DIR}/eigen_hrd_t1.F
    ${SRC_DIR}/eigen_hrd_t2.F
    ${SRC_DIR}/eigen_hrd_t4.F
    ${SRC_DIR}/eigen_hrd_t5.F
    ${SRC_DIR}/eigen_hrd_t5x.F
    ${SRC_DIR}/eigen_hrd_t6_3.F
    ${SRC_DIR}/eigen_hrd_t7.F
    ${SRC_DIR}/eigen_hrd_t8.F
    ${SRC_DIR}/eigen_hrd.F
    ${SRC_DIR}/eigen_h.F
    ${SRC_DIR}/hrbakwy4_body.F
    ${SRC_DIR}/hrbakwy4.F
    ${SRC_DIR}/eigen_scaling_h.F
    ${SRC_DIR}/KMATH_EIGEN_GEV.F
    ${C_DIR}/eigen_exa_interfaces.F90
    ${C_DIR}/EigenExa.c
)

file(GLOB C_SOURCES "${C_DIR}/*.c" "${C_DIR}/*.h")

find_package(OpenMP REQUIRED)
find_package(BLAS REQUIRED)
find_package(LAPACK REQUIRED)
find_package(SCALAPACK REQUIRED)


set(HEADER_FILES
    ${C_DIR}/eigen_exa_interfaces.h
    ${C_DIR}/EigenExa.fh
    ${C_DIR}/EigenExa.h
    ${CMAKE_BINARY_DIR}/eigen_devel_mod.mod
	${CMAKE_BINARY_DIR}/eigen_libs_mod.mod
	${CMAKE_BINARY_DIR}/eigen_libs0_mod.mod
	${CMAKE_BINARY_DIR}/fs_libs_mod.mod
	${CMAKE_BINARY_DIR}/eigen_blacs_mod.mod
	${CMAKE_BINARY_DIR}/comm_mod.mod
)

add_library(EigenExa SHARED ${FORTRAN_SOURCES} ${C_SOURCES})
target_link_libraries(EigenExa PUBLIC OpenMP::OpenMP_Fortran BLAS::BLAS LAPACK::LAPACK MPI::MPI_Fortran ${SCALAPACK_LIBRARIES})



#set_target_properties(EigenExa PROPERTIES 
#                      INTERFACE_INCLUDE_DIRECTORIES
#                      IMPORTED_LOCATION)
#
# Specify installation rules for the shared library


install(TARGETS EigenExa
        EXPORT EigenExaTargets  # Export target
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin)
#
## Install header files to the include directory
install(FILES ${HEADER_FILES} DESTINATION include)
#
## Export the target for use in other projects
install(EXPORT EigenExaTargets
        FILE EigenExaTargets.cmake
        DESTINATION lib/cmake/EigenExa)
#
## Install a CMake package configuration file for find_package
include(CMakePackageConfigHelpers)
configure_package_config_file(
    "cmake/Config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/EigenExaConfig.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
    NO_SET_AND_CHECK_MACRO
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/EigenExaConfigVersion.cmake"
  VERSION "${Tutorial_VERSION_MAJOR}.${Tutorial_VERSION_MINOR}"
  COMPATIBILITY AnyNewerVersion
)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/EigenExaConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/EigenExaConfigVersion.cmake"
    DESTINATION lib/cmake/EigenExa)
#include("${CMAKE_CURRENT_LIST_DIR}/EigenExaTargets.cmake")
