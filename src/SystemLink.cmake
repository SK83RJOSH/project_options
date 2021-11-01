# Include the directories of a library target as system directories (which suppresses their warnings).
function(
  target_include_system_library
  target
  scope
  lib)
  get_target_property(lib_include_dirs ${lib} INTERFACE_INCLUDE_DIRECTORIES)
  if(lib_include_dirs)
    if(MSVC)
      # system includes do not work in MSVC
      # awaiting https://gitlab.kitware.com/cmake/cmake/-/issues/18272#
      # awaiting https://gitlab.kitware.com/cmake/cmake/-/issues/17904
      target_include_directories(${target} ${scope} ${lib_include_dirs})
    else()
      target_include_directories(
        ${target}
        SYSTEM
        ${scope}
        ${lib_include_dirs})
    endif()
  else()
    message(WARNING "${lib} library does not have the INTERFACE_INCLUDE_DIRECTORIES property.")
  endif()
endfunction()

# Link a library target as a system library (which suppresses its warnings).
function(
  target_link_system_library
  target
  scope
  lib)
  # Include the directories in the library
  target_include_system_library(${target} ${scope} ${lib})

  # Link the library
  target_link_libraries(${target} ${scope} ${lib})
endfunction()

# Link multiple library targets as system libraries (which suppresses their warnings).
function(target_link_system_libraries target)
  set(multiValueArgs INTERFACE PUBLIC PRIVATE)
  cmake_parse_arguments(
    ARG
    ""
    ""
    "${multiValueArgs}"
    ${ARGN})

  foreach(scope IN ITEMS INTERFACE PUBLIC PRIVATE)
    foreach(lib IN LISTS ARG_${scope})
      target_link_system_library(${target} ${scope} ${lib})
    endforeach()
  endforeach()
endfunction()
