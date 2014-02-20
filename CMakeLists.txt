CMAKE_MINIMUM_REQUIRED(VERSION 2.6 FATAL_ERROR)
CMAKE_POLICY(VERSION 2.6)

FIND_PACKAGE(Torch REQUIRED)

SET(src)
FILE(GLOB_RECURSE luasrc *.lua)

ADD_TORCH_PACKAGE(optimbench "${src}" "${luasrc}" "Optimisation benchmark package")
