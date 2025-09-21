cmake_minimum_required(VERSION 3.15)
project(edit LANGUAGES C)

# ---- bundling stuff ------
# if (APPLE)
# 	# Set the icon file path
# 	# set(ICON_FILE "${CMAKE_SOURCE_DIR}/EditIcon.icns")
# 	# message("${CMAKE_SOURCE_DIR}/EditIcon.icns yoyoyo")
#
# 	# Create a .app bundle
# 	set_target_properties(edit PROPERTIES MACOSX_BUNDLE TRUE)
#
# 	# Set the icon for the bundle
# 	# set_target_properties(edit PROPERTIES MACOSX_BUNDLE_ICON_FILE "${ICON_FILE}")
# 	set_target_properties(edit PROPERTIES MACOSX_BUNDLE_ICON_FILE "EditIcon.icns")
#
# 	# Set the location of the icon within the app bundle
# 	# set_source_files_properties(${ICON_FILE} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
# 	set_source_files_properties(EditIcon.icns PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
#
# endif()


# Dependencies ---------------------------------------------
set(BUILD_SHARED_LIBS ON CACHE BOOL ON) # build raylib as shared lib (dll/dylib/so)

set(RAYLIB_VERSION 5.5)
find_package(raylib ${RAYLIB_VERSION} QUIET) # QUIET or REQUIRED
if (NOT raylib_FOUND) # If there's none, fetch and build raylib
  include(FetchContent)
  FetchContent_Declare(
    raylib
    DOWNLOAD_EXTRACT_TIMESTAMP OFF
    URL https://github.com/raysan5/raylib/archive/refs/tags/${RAYLIB_VERSION}.tar.gz
  )
  FetchContent_GetProperties(raylib)
  if (NOT raylib_POPULATED) # Have we downloaded raylib yet?
    set(FETCHCONTENT_QUIET NO)
    FetchContent_MakeAvailable(raylib)
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE) # don't build the supplied examples
  endif()
endif()

if (APPLE)
	set(FFMPEG_DIR "${CMAKE_SOURCE_DIR}/lib/ffmpeg-master-latest-linuxarm64-lgpl-shared")
else()
	set(FFMPEG_DIR "${CMAKE_SOURCE_DIR}/lib/ffmpeg-master-latest-win64-lgpl-shared")

	set(FFMPEG_LIBS
		"${FFMPEG_DIR}/lib/avcodec.lib"
		"${FFMPEG_DIR}/lib/avformat.lib"
		"${FFMPEG_DIR}/lib/avutil.lib"
		"${FFMPEG_DIR}/lib/swscale.lib"
		"${FFMPEG_DIR}/lib/swresample.lib"
	)
endif()

# ----------------------------------------------------------

# Our Project

if (APPLE)
	set(ICON_NAME "icon.icns")
	set(ICON_PATH ${PROJECT_SOURCE_DIR}/assets/${ICON_NAME})
	set_source_files_properties(${ICON_NAME} PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
	file(COPY ${ICON_PATH} DESTINATION "edit_app.app/Contents/Resources")

	add_library(edit SHARED "out/__unity__.c")

	add_executable(edit_app MACOSX_BUNDLE ${ICON_PATH} "wrapper_out/__unity__.c")

	set_target_properties(edit_app PROPERTIES
			BUNDLE True
			MACOSX_BUNDLE_GUI_IDENTIFIER my.domain.style.identifier.edit_app
			MACOSX_BUNDLE_BUNDLE_NAME edit_app
			MACOSX_BUNDLE_BUNDLE_VERSION "0.1"
			MACOSX_BUNDLE_SHORT_VERSION_STRING "0.1"
			MACOSX_BUNDLE_ICON_FILE "icon"
			)
else()
	# NOTE: this windows build does not -include-c-file:tinyfiledialogs.c --- because that causes issues with the inclusion of windows.h
	add_executable(edit "out/__unity__.c" "include/tinyfiledialogs.c")
endif()
target_include_directories(edit PUBLIC include)
target_include_directories(edit PUBLIC "${FFMPEG_DIR}/include") # NOTE: should this be public?

target_link_libraries(edit raylib)
target_link_libraries(edit ${CMAKE_SOURCE_DIR}/tcc/libtcc.a)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(edit Threads::Threads)
# target_link_libraries(edit raylib)

if (APPLE)
	find_library(AVCODEC NAMES avcodec)
	find_library(AVFORMAT NAMES avformat)
	find_library(AVUTIL NAMES avutil)
	find_library(SWSCALE NAMES swscale)
	find_library(SWRESAMPLE NAMES swresample)
	target_link_libraries(edit ${AVCODEC} ${AVFORMAT} ${AVUTIL} ${SWSCALE} ${SWRESAMPLE})

else()
	target_link_libraries(edit ${FFMPEG_LIBS})
	file(COPY "${FFMPEG_DIR}/bin/" DESTINATION ${CMAKE_BINARY_DIR})
endif()

add_library(script SHARED "test_out/__unity__.c")
target_link_libraries(script raylib)
target_include_directories(script PUBLIC include) # might not need all that..

target_link_libraries(edit_app raylib)
target_include_directories(edit_app PUBLIC include) # might not need all that..

# add_library(min SHARED "min_out/__unity__.c")
# target_link_libraries(min raylib)
# target_include_directories(min PUBLIC include) # might not need all that..

# Checks if OSX and links appropriate frameworks (Only required on MacOS)
if (APPLE)
    target_link_libraries(edit_app "-framework IOKit")
    target_link_libraries(edit_app "-framework Cocoa")
    target_link_libraries(edit_app "-framework OpenGL")

    target_link_libraries(edit "-framework IOKit")
    target_link_libraries(edit "-framework Cocoa")
    target_link_libraries(edit "-framework OpenGL")

    target_link_libraries(script "-framework IOKit")
    target_link_libraries(script "-framework Cocoa")
    target_link_libraries(script "-framework OpenGL")
endif()
