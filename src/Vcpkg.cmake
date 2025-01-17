include_guard()

include(FetchContent)

# Install vcpkg and vcpkg dependencies: - should be called before defining project()
macro(run_vcpkg)
  # named boolean ENABLE_VCPKG_UPDATE arguments
  set(options ENABLE_VCPKG_UPDATE)
  # optional named VCPKG_DIR, VCPKG_URL, and VCPKG_REV arguments
  set(oneValueArgs VCPKG_DIR VCPKG_URL VCPKG_REV)
  cmake_parse_arguments(
    _vcpkg_args
    "${options}"
    "${oneValueArgs}"
    ""
    ${ARGN})

  find_program(GIT_EXECUTABLE "git" REQUIRED)

  if(NOT
     "${_vcpkg_args_VCPKG_DIR}"
     STREQUAL
     "")
    # the installation directory is specified
    get_filename_component(VCPKG_PARENT_DIR "${_vcpkg_args_VCPKG_DIR}" DIRECTORY)
  else()
    # Default vcpkg installation directory
    if(WIN32)
      set(VCPKG_PARENT_DIR $ENV{userprofile})
      set(_vcpkg_args_VCPKG_DIR "${VCPKG_PARENT_DIR}/vcpkg")
    else()
      set(VCPKG_PARENT_DIR $ENV{HOME})
      set(_vcpkg_args_VCPKG_DIR "${VCPKG_PARENT_DIR}/vcpkg")
    endif()
  endif()

  # check if vcpkg is installed
  if(WIN32 AND "${CMAKE_EXECUTABLE_SUFFIX}" STREQUAL "")
    set(CMAKE_EXECUTABLE_SUFFIX ".exe")
  endif()
  if(EXISTS "${_vcpkg_args_VCPKG_DIR}" AND EXISTS "${_vcpkg_args_VCPKG_DIR}/vcpkg${CMAKE_EXECUTABLE_SUFFIX}")
    message(STATUS "vcpkg is already installed at ${_vcpkg_args_VCPKG_DIR}.")
    if(${_vcpkg_args_ENABLE_VCPKG_UPDATE})

      if(NOT
         "${_vcpkg_args_VCPKG_REV}"
         STREQUAL
         "")
        # detect if the head is detached, if so, switch back before calling git pull on a detached head
        set(GIT_STATUS "")
        execute_process(
          COMMAND "${GIT_EXECUTABLE}" "rev-parse" "--abbrev-ref" "--symbolic-full-name" "HEAD"
          OUTPUT_VARIABLE GIT_STATUS
          WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
          OUTPUT_STRIP_TRAILING_WHITESPACE)
        if("${GIT_STATUS}" STREQUAL "HEAD")
          message(STATUS "Switching back before updating")
          execute_process(COMMAND "${GIT_EXECUTABLE}" "switch" "-" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}")
        endif()
      endif()

      message(STATUS "Updating the repository...")
      execute_process(COMMAND "${GIT_EXECUTABLE}" "pull" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}")
    endif()
  else()
    message(STATUS "Installing vcpkg at ${_vcpkg_args_VCPKG_DIR}")
    # clone vcpkg from Github
    if(NOT EXISTS "${_vcpkg_args_VCPKG_DIR}")
      if("${_vcpkg_args_VCPKG_URL}" STREQUAL "")
        set(_vcpkg_args_VCPKG_URL "https://github.com/microsoft/vcpkg.git")
      endif()
      execute_process(COMMAND "${GIT_EXECUTABLE}" "clone" "${_vcpkg_args_VCPKG_URL}"
                      WORKING_DIRECTORY "${VCPKG_PARENT_DIR}" COMMAND_ERROR_IS_FATAL LAST)
    endif()
    # Run vcpkg bootstrap
    if(WIN32)
      execute_process(COMMAND "bootstrap-vcpkg.bat" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                        COMMAND_ERROR_IS_FATAL LAST)
    else()
      execute_process(COMMAND "./bootstrap-vcpkg.sh" "-disableMetrics" WORKING_DIRECTORY "${_vcpkg_args_VCPKG_DIR}"
                                                                                         COMMAND_ERROR_IS_FATAL LAST)
    endif()
  endif()

  if(NOT
     "${_vcpkg_args_VCPKG_REV}"
     STREQUAL
     "")
    execute_process(COMMAND "${GIT_EXECUTABLE}" "checkout" "${_vcpkg_args_VCPKG_REV}"
                    WORKING_DIRECTORY "${VCPKG_PARENT_DIR}/vcpkg" COMMAND_ERROR_IS_FATAL LAST)
  endif()

  configure_mingw_vcpkg()

  # Setting up vcpkg toolchain
  list(APPEND VCPKG_FEATURE_FLAGS "versions")
  set(CMAKE_TOOLCHAIN_FILE
      ${_vcpkg_args_VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake
      CACHE STRING "vcpkg toolchain file")

  configure_mingw_vcpkg_after()
endmacro()
