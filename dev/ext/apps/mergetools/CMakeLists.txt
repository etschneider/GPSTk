# apps/mergetools/CMakeLists.txt


add_executable(mergeRinObs mergeRinObs.cpp)
target_link_libraries(mergeRinObs gpstk)
install (TARGETS mergeRinObs DESTINATION bin)
add_test(mergeRinObsTest mergeRinObs)

add_executable(mergeRinNav mergeRinNav.cpp)
target_link_libraries(mergeRinNav gpstk)
install (TARGETS mergeRinNav DESTINATION bin)
add_test(mergeRinNavTest mergeRinNav)

add_executable(mergeRinMet mergeRinMet.cpp)
target_link_libraries(mergeRinMet gpstk)
install (TARGETS mergeRinMet DESTINATION bin)
add_test(mergeRinMetTest mergeRinMet)

if (CMAKE_SYSTEM_NAME MATCHES "SunOS")
  target_link_libraries(mergeRinObs gen)
  target_link_libraries(mergeRinMet gen)
  target_link_libraries(mergeRinNav gen)
endif()

