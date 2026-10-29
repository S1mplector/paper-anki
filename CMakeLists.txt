cmake_minimum_required(VERSION 3.21)
project(PaperAnki VERSION 0.1.0 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)

qt_add_library(paperankiplugin MODULE src/desktop.cpp)
target_compile_definitions(paperankiplugin PRIVATE PAPER_ANKI_PLUGIN)
target_link_libraries(paperankiplugin PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::Network)
add_executable(root-runner src/root-runner.c)
set_target_properties(root-runner PROPERTIES AUTOMOC OFF)
target_compile_options(root-runner PRIVATE -Wall -Wextra)

qt_add_executable(qmlcheck src/qmlcheck.cpp)
target_link_libraries(qmlcheck PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml)

file(GLOB APP_ICONS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/app/icons/*.svg")
add_custom_command(OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/resources.rcc"
    COMMAND Qt6::rcc --binary "${CMAKE_CURRENT_SOURCE_DIR}/app/app.qrc" -o "${CMAKE_CURRENT_BINARY_DIR}/resources.rcc"
    DEPENDS app/app.qrc app/AppLoad.qml ${APP_ICONS})
add_custom_target(app_resources ALL DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/resources.rcc")
