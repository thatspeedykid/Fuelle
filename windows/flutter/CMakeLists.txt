# This file controls Flutter-level build steps. It should not be edited.
cmake_minimum_required(VERSION 3.14)

set(EPHEMERAL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/ephemeral")

# Configuration provided via flutter tool.
include(${EPHEMERAL_DIR}/generated_config.cmake)

# TODO: Move the rest of this to an install rule.
# See https://cmake.org/cmake/help/latest/guide/importing-exporting/index.html
set(FLUTTER_LIBRARY "${EPHEMERAL_DIR}/flutter_windows.dll")

# Published to parent scope for install step.
set(FLUTTER_LIBRARY ${FLUTTER_LIBRARY} PARENT_SCOPE)
set(FLUTTER_ICU_DATA_FILE "${EPHEMERAL_DIR}/icudtl.dat" PARENT_SCOPE)
set(PROJECT_BUILD_DIR "${PROJECT_BINARY_DIR}" PARENT_SCOPE)
set(AOT_LIBRARY "${PROJECT_BINARY_DIR}/windows/app.so" PARENT_SCOPE)

list(APPEND FLUTTER_LIBRARY_HEADERS
  "flutter_export.h"
  "flutter_windows.h"
  "flutter_messenger.h"
  "flutter_plugin_registrar.h"
  "flutter_texture_registrar.h"
)
list(TRANSFORM FLUTTER_LIBRARY_HEADERS PREPEND "${EPHEMERAL_DIR}/")
add_library(flutter INTERFACE)
target_include_directories(flutter INTERFACE
  "${EPHEMERAL_DIR}"
)
target_link_libraries(flutter INTERFACE "${FLUTTER_LIBRARY}.lib")
add_dependencies(flutter flutter_assemble)

add_custom_command(
  OUTPUT ${FLUTTER_LIBRARY} ${FLUTTER_LIBRARY_HEADERS}
    "${EPHEMERAL_DIR}/icudtl.dat"
    "${EPHEMERAL_DIR}/flutter_export.h"
  COMMAND ${CMAKE_COMMAND} -E env
    "FLUTTER_ROOT=${FLUTTER_ROOT}"
    "PROJECT_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../.."
    ${FLUTTER_TOOL_ENVIRONMENT}
    "${FLUTTER_ROOT}/bin/flutter"
      --suppress-analytics
      --no-version-check
      build windows
      --config-only
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../.."
  VERBATIM
)

add_custom_target(flutter_assemble DEPENDS
  ${FLUTTER_LIBRARY}
  ${FLUTTER_LIBRARY_HEADERS}
)
