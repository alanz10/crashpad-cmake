# Handler executable
add_library(crashpad_handler_obj OBJECT)

set_target_properties(crashpad_handler_obj PROPERTIES
    CXX_STANDARD 14
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET "hidden"
    C_VISIBILITY_PRESET "hidden"
    VISIBILITY_INLINES_HIDDEN ON
)

target_link_libraries(crashpad_handler_obj PRIVATE
    minichromium
    crashpad_common
    crashpad_compat
    crashpad_client
    crashpad_minidump
    crashpad_snapshot
    crashpad_tools
    ZLIB::ZLIB
    AppleFrameworks
)

target_sources(crashpad_handler_obj PRIVATE
    ${crashpad_git_SOURCE_DIR}/handler/crash_report_upload_thread.cc
    ${crashpad_git_SOURCE_DIR}/handler/handler_main.cc
    ${crashpad_git_SOURCE_DIR}/handler/minidump_to_upload_parameters.cc
    ${crashpad_git_SOURCE_DIR}/handler/prune_crash_reports_thread.cc
    ${crashpad_git_SOURCE_DIR}/handler/user_stream_data_source.cc
)

if(APPLE)
    target_sources(crashpad_handler_obj PRIVATE
        ${crashpad_git_SOURCE_DIR}/handler/mac/crash_report_exception_handler.cc
        ${crashpad_git_SOURCE_DIR}/handler/mac/exception_handler_server.cc
        ${crashpad_git_SOURCE_DIR}/handler/mac/file_limit_annotation.cc
    )
	# Hack to fix upstream backtrace fork not updating this var in line with minichromium.
	target_compile_definitions(crashpad_handler_obj PRIVATE OS_MACOSX=1)
endif()

if(UNIX AND NOT APPLE)
    target_sources(crashpad_handler_obj PRIVATE
        ${crashpad_git_SOURCE_DIR}/handler/linux/capture_snapshot.cc
        ${crashpad_git_SOURCE_DIR}/handler/linux/crash_report_exception_handler.cc
        ${crashpad_git_SOURCE_DIR}/handler/linux/exception_handler_server.cc
    )

    if(NOT ANDROID)
        target_sources(crashpad_handler_obj PRIVATE
            ${crashpad_git_SOURCE_DIR}/handler/linux/cros_crash_report_exception_handler.cc
        )
    endif()
endif()

if(WIN32)
    target_sources(crashpad_handler_obj PRIVATE
        ${crashpad_git_SOURCE_DIR}/handler/win/crash_report_exception_handler.cc
    )
endif()

if (NOT CRASHPAD_HANDLER_NAME)
    set(MODULE_NAME crashpad_handler)
else()
    set(MODULE_NAME ${CRASHPAD_HANDLER_NAME})
endif()

add_executable(${MODULE_NAME} ${crashpad_git_SOURCE_DIR}/handler/main.cc)

set_target_properties(${MODULE_NAME} PROPERTIES
    CXX_STANDARD 14
    POSITION_INDEPENDENT_CODE ON
    CXX_VISIBILITY_PRESET "hidden"
    C_VISIBILITY_PRESET "hidden"
    VISIBILITY_INLINES_HIDDEN ON
)

target_link_libraries(${MODULE_NAME} PRIVATE
    minichromium
    crashpad_common
    crashpad_compat
    crashpad_client
    crashpad_minidump
    crashpad_snapshot
    crashpad_tools
    crashpad_handler_obj
    ZLIB::ZLIB
    AppleFrameworks
)

install(TARGETS ${MODULE_NAME}
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
)
