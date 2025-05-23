
set(ENALBE_SHARED OFF)

# Crashpad client library
if (ENALBE_SHARED)
    add_library(crashpad_client SHARED)
else()
    add_library(crashpad_client STATIC)
endif()

set_target_properties(crashpad_client PROPERTIES
    CXX_STANDARD 14
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET "hidden"
    C_VISIBILITY_PRESET "hidden"
    VISIBILITY_INLINES_HIDDEN ON
)

# target_include_directories(crashpad_client PUBLIC
#     ${mini_chromium_git_SOURCE_DIR}
#     ${crashpad_git_SOURCE_DIR}
# )

target_link_libraries(crashpad_client PRIVATE
    minichromium
    $<BUILD_INTERFACE:crashpad_common>
    crashpad_compat
    crashpad_util
)

if (ENALBE_SHARED)
    target_compile_options(crashpad_client PUBLIC -fPIC)
endif()

target_sources(crashpad_client PRIVATE
    ${crashpad_git_SOURCE_DIR}/client/annotation.cc
    ${crashpad_git_SOURCE_DIR}/client/annotation_list.cc
    ${crashpad_git_SOURCE_DIR}/client/crash_report_database.cc
    ${crashpad_git_SOURCE_DIR}/client/crashpad_info.cc
    ${crashpad_git_SOURCE_DIR}/client/prune_crash_reports.cc
    ${crashpad_git_SOURCE_DIR}/client/settings.cc
)

if(APPLE)
    target_sources(crashpad_client PRIVATE
        ${crashpad_git_SOURCE_DIR}/client/crash_report_database_mac.mm
        ${crashpad_git_SOURCE_DIR}/client/crashpad_client_mac.cc
        ${crashpad_git_SOURCE_DIR}/client/simulate_crash_mac.cc
    )
endif()

if (UNIX AND NOT APPLE)
    target_sources(crashpad_client PRIVATE
        ${crashpad_git_SOURCE_DIR}/client/crashpad_client_linux.cc
        ${crashpad_git_SOURCE_DIR}/client/client_argv_handling.cc
        ${crashpad_git_SOURCE_DIR}/client/crashpad_info_note.S
        ${crashpad_git_SOURCE_DIR}/client/crash_report_database_generic.cc
    )
endif()

if(WIN32)
    target_sources(crashpad_client PRIVATE
        ${crashpad_git_SOURCE_DIR}/client/crash_report_database_win.cc
        ${crashpad_git_SOURCE_DIR}/client/crashpad_client_win.cc
    )
endif()

install(TARGETS crashpad_client
        EXPORT ${PROJECT_NAME}Targets
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
)

install(DIRECTORY ${crashpad_git_SOURCE_DIR}/client/ DESTINATION include/crashpad FILES_MATCHING PATTERN "*.h" PATTERN "*Base.h" EXCLUDE)
install(DIRECTORY ${mini_chromium_git_SOURCE_DIR}/ DESTINATION include/crashpad/ FILES_MATCHING PATTERN "*.h" PATTERN "*Base.h" EXCLUDE)
install(DIRECTORY ${crashpad_git_SOURCE_DIR}/util/ DESTINATION include/crashpad/util FILES_MATCHING PATTERN "*.h" PATTERN "*Base.h" EXCLUDE)
