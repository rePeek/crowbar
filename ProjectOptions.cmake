include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(crowbar_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(crowbar_setup_options)
  option(crowbar_ENABLE_HARDENING "Enable hardening" ON)
  option(crowbar_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    crowbar_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    crowbar_ENABLE_HARDENING
    OFF)

  crowbar_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR crowbar_PACKAGING_MAINTAINER_MODE)
    option(crowbar_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(crowbar_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(crowbar_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(crowbar_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(crowbar_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(crowbar_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(crowbar_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(crowbar_ENABLE_PCH "Enable precompiled headers" OFF)
    option(crowbar_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(crowbar_ENABLE_IPO "Enable IPO/LTO" ON)
    option(crowbar_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(crowbar_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(crowbar_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(crowbar_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(crowbar_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(crowbar_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(crowbar_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(crowbar_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(crowbar_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(crowbar_ENABLE_PCH "Enable precompiled headers" OFF)
    option(crowbar_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      crowbar_ENABLE_IPO
      crowbar_WARNINGS_AS_ERRORS
      crowbar_ENABLE_USER_LINKER
      crowbar_ENABLE_SANITIZER_ADDRESS
      crowbar_ENABLE_SANITIZER_LEAK
      crowbar_ENABLE_SANITIZER_UNDEFINED
      crowbar_ENABLE_SANITIZER_THREAD
      crowbar_ENABLE_SANITIZER_MEMORY
      crowbar_ENABLE_UNITY_BUILD
      crowbar_ENABLE_CLANG_TIDY
      crowbar_ENABLE_CPPCHECK
      crowbar_ENABLE_COVERAGE
      crowbar_ENABLE_PCH
      crowbar_ENABLE_CACHE)
  endif()

  crowbar_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (crowbar_ENABLE_SANITIZER_ADDRESS OR crowbar_ENABLE_SANITIZER_THREAD OR crowbar_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(crowbar_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(crowbar_global_options)
  if(crowbar_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    crowbar_enable_ipo()
  endif()

  crowbar_supports_sanitizers()

  if(crowbar_ENABLE_HARDENING AND crowbar_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR crowbar_ENABLE_SANITIZER_UNDEFINED
       OR crowbar_ENABLE_SANITIZER_ADDRESS
       OR crowbar_ENABLE_SANITIZER_THREAD
       OR crowbar_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${crowbar_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${crowbar_ENABLE_SANITIZER_UNDEFINED}")
    crowbar_enable_hardening(crowbar_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(crowbar_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(crowbar_warnings INTERFACE)
  add_library(crowbar_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  crowbar_set_project_warnings(
    crowbar_warnings
    ${crowbar_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(crowbar_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    crowbar_configure_linker(crowbar_options)
  endif()

  include(cmake/Sanitizers.cmake)
  crowbar_enable_sanitizers(
    crowbar_options
    ${crowbar_ENABLE_SANITIZER_ADDRESS}
    ${crowbar_ENABLE_SANITIZER_LEAK}
    ${crowbar_ENABLE_SANITIZER_UNDEFINED}
    ${crowbar_ENABLE_SANITIZER_THREAD}
    ${crowbar_ENABLE_SANITIZER_MEMORY})

  set_target_properties(crowbar_options PROPERTIES UNITY_BUILD ${crowbar_ENABLE_UNITY_BUILD})

  if(crowbar_ENABLE_PCH)
    target_precompile_headers(
      crowbar_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(crowbar_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    crowbar_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(crowbar_ENABLE_CLANG_TIDY)
    crowbar_enable_clang_tidy(crowbar_options ${crowbar_WARNINGS_AS_ERRORS})
  endif()

  if(crowbar_ENABLE_CPPCHECK)
    crowbar_enable_cppcheck(${crowbar_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(crowbar_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    crowbar_enable_coverage(crowbar_options)
  endif()

  if(crowbar_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(crowbar_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(crowbar_ENABLE_HARDENING AND NOT crowbar_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR crowbar_ENABLE_SANITIZER_UNDEFINED
       OR crowbar_ENABLE_SANITIZER_ADDRESS
       OR crowbar_ENABLE_SANITIZER_THREAD
       OR crowbar_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    crowbar_enable_hardening(crowbar_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
