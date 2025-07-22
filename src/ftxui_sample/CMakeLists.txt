add_executable(intro main.cc)

# 设置需要链接的组件
set(LLVM_REQUIRED_COMPONENTS
    Core
    Support
    Object
    BinaryFormat
    MC
    MCParser
    BitReader
    Option
    Demangle
)

# 将组件映射到库文件名
llvm_map_components_to_libnames(LLVM_LIBRARIES ${LLVM_REQUIRED_COMPONENTS})

# 打印库信息
message(STATUS "LLVM libraries: ${LLVM_LIBRARIES}")

target_link_libraries(
  intro
  PRIVATE crowbar::crowbar_options
          crowbar::crowbar_warnings)

target_link_system_libraries(
  intro
  PRIVATE ${LLVM_LIBRARIES}
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog
          lefticus::tools
          ftxui::screen
          ftxui::dom
          ftxui::component)

message(STATUS "LLVM DEFINITIONS: ${LLVM_DEFINITIONS}")
target_compile_definitions(
  intro
  PRIVATE ${LLVM_DEFINITIONS_LIST})

message(STATUS "LLVM_INCLUDE_DIRS: ${LLVM_INCLUDE_DIRS}")
target_include_directories(
  intro
  PRIVATE ${LLVM_INCLUDE_DIRS}
          "${CMAKE_BINARY_DIR}/configured_files/include")
