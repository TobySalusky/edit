cmake_minimum_required(VERSION 3.15)
project(rpp_edit_plugin LANGUAGES C)

add_library(rpp_edit_plugin SHARED "../plugin_out/__unity__.c")
