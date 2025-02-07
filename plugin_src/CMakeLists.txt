cmake_minimum_required(VERSION 3.15)
project(rpp_edit_plugin LANGUAGES C)

file(GLOB SOURCES "../plugin_out/*.c")

add_library(rpp_edit_plugin SHARED ${SOURCES})
