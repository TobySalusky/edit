cmake_minimum_required(VERSION 3.15)
project(edit LANGUAGES C)

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
	set(FFMPEG_DIR "${CMAKE_SOURCE_DIR}/lib/ffmpeg-master-latest-win64-gpl-shared")

	set(FFMPEG_LIBS
		"${FFMPEG_DIR}/lib/avcodec.lib"
		"${FFMPEG_DIR}/lib/avformat.lib"
		"${FFMPEG_DIR}/lib/avutil.lib"
		"${FFMPEG_DIR}/lib/swscale.lib"
	)
endif()

# ----------------------------------------------------------

# Our Project

file(GLOB EDIT_C_SOURCES "out/*.c")
file(GLOB SCRIPT_C_SOURCES "test_out/*.c")

add_executable(edit ${EDIT_C_SOURCES})
target_include_directories(edit PUBLIC include)
target_include_directories(edit PUBLIC "${FFMPEG_DIR}/include") # NOTE: should this be public?

target_link_libraries(edit raylib)
if (APPLE)
	find_library(AVCODEC NAMES avcodec)
	find_library(AVFORMAT NAMES avformat)
	find_library(AVUTIL NAMES avutil)
	find_library(SWSCALE NAMES swscale)
	target_link_libraries(edit ${AVCODEC} ${AVFORMAT} ${AVUTIL} ${SWSCALE})

else()
	target_link_libraries(edit ${FFMPEG_LIBS})
endif()

add_library(script SHARED ${SCRIPT_C_SOURCES})
target_link_libraries(script raylib)
target_include_directories(script PUBLIC include) # might not need all that..

# Checks if OSX and links appropriate frameworks (Only required on MacOS)
if (APPLE)
    target_link_libraries(edit "-framework IOKit")
    target_link_libraries(edit "-framework Cocoa")
    target_link_libraries(edit "-framework OpenGL")

    target_link_libraries(script "-framework IOKit")
    target_link_libraries(script "-framework Cocoa")
    target_link_libraries(script "-framework OpenGL")
endif()


