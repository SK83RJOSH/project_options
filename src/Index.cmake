cmake_minimum_required(VERSION 3.15)

include(CMakeParseArguments) # to support cmake 3.4 and older

#
# Params:
# - ENABLE_BUILD_WITH_TIME_TRACE: Enable -ftime-trace to generate time tracing .json files on clang
# - ENABLE_PCH: Enable Precompiled Headers
# - Enable_CACHE: Enable cache if available
# - ENABLE_CONAN: Use Conan for dependency management
# - ENABLE_DOXYGEN: Enable doxygen doc builds of source
# - ENABLE_UNITY: Enable Unity builds of projects
# - WARNINGS_AS_ERRORS: Treat compiler warnings as errors
macro(cmakelib)
  set(options
      ENABLE_BUILD_WITH_TIME_TRACE
      ENABLE_PCH
      Enable_CACHE
      ENABLE_CONAN
      ENABLE_DOXYGEN
      ENABLE_UNITY
      WARNINGS_AS_ERRORS)
  cmake_parse_arguments(cmakelib "${options}" ${ARGN})

  include("${CMAKE_CURRENT_LIST_DIR}/StandardProjectSettings.cmake")
  include("${CMAKE_CURRENT_LIST_DIR}/PreventInSourceBuilds.cmake")

  # Link this 'library' to set the c++ standard / compile-time options requested
  add_library(project_options INTERFACE)

  if(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
    if(cmakelib_ENABLE_BUILD_WITH_TIME_TRACE)
      target_compile_options(project_options INTERFACE -ftime-trace)
    endif()
  endif()

  # Link this 'library' to use the warnings specified in CompilerWarnings.cmake
  add_library(project_warnings INTERFACE)

  if (cmakelib_Enable_CACHE)
    # enable cache system
    include("${CMAKE_CURRENT_LIST_DIR}/Cache.cmake")
    enable_cache()
  endif()

  # Add linker configuration
  include("${CMAKE_CURRENT_LIST_DIR}/Linker.cmake")
  configure_linker(project_options)

  # standard compiler warnings
  include("${CMAKE_CURRENT_LIST_DIR}/CompilerWarnings.cmake")
  set_project_warnings(project_warnings cmakelib_WARNINGS_AS_ERRORS)

  # sanitizer options if supported by compiler
  include("${CMAKE_CURRENT_LIST_DIR}/Sanitizers.cmake")
  enable_sanitizers(project_options)

  if(cmakelib_ENABLE_DOXYGEN)
    # enable doxygen
    include("${CMAKE_CURRENT_LIST_DIR}/Doxygen.cmake")
    enable_doxygen()
  endif()

  # allow for static analysis options
  include("${CMAKE_CURRENT_LIST_DIR}/StaticAnalyzers.cmake")

  # Very basic PCH example
  if(cmakelib_ENABLE_PCH)
    # This sets a global PCH parameter, each project will build its own PCH, which is a good idea if any #define's change
    #
    # consider breaking this out per project as necessary
    target_precompile_headers(
      project_options
      INTERFACE
      <vector>
      <string>
      <map>
      <utility>)
  endif()

  if(cmakelib_ENABLE_CONAN)
    include("${CMAKE_CURRENT_LIST_DIR}/Conan.cmake")
    run_conan()
  endif()

  if(cmakelib_ENABLE_UNITY)
    # Add for any project you want to apply unity builds for
    set_target_properties(main PROPERTIES UNITY_BUILD ON)
  endif()

endmacro()
