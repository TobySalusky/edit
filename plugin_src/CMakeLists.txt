cmake_minimum_required(VERSION 3.15)
project(crust_edit_plugin LANGUAGES C)

add_library(crust_edit_plugin SHARED "../plugin_out/__unity__.c")
