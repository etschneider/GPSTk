#!/bin/bash
#----------------------------------------
#
# purpose = Automate the use of CMake and make to build C++ GPSTk
#
# outline = Optionally clean out install and build paths
#           Export gpstk install path as environment variables used by CMake
#           Run CMake to generate build environment
#           Run make to build GPSTk
#           Run make install to install GPSTk
#           Echo a list of the installed files
#
# usage:    ./script_gpstk_cpp.sh [-h] [-d] [-b] [-i] [-o] [-t] [-v] [-r <path>] [-s <path>]
#
# OPTIONS:
#    -h     help,          Show this message
#    -d     build_doxygen, build doxygen files
#
#    -b     clean_build,   rm -rf gpstk_root/build
#    -i     clean_install, rm -rf gpstk_install
#
#    -o     core_only,     only builds core library code
#    -t     test_switch,   initialize test framework
#    -v     graphviz,      generate dependency graph (.DOT and .PDF files)
#
#    -r     gpstk_root,    default = ~/git/gpstk/dev, path to GPSTk top-level CMakeLists.txt file (and source tree)
#    -s     gpstk_install, default = ~/git/gpstk/install,  path to GPSTk install, e.g. /opt/gpstk, to contain ./bin, ./lib, and ./include
#
#----------------------------------------

#----------------------------------------
# usage() function to use when help is needed:
#----------------------------------------

usage()
{
cat << EOF

usage:     $0 [-h] [-d] [-b] [-i] [-o] [-t] [-v] [-r <path>] [-s <path>]

purpose:   This script is for use with CMake and building GPSTk.

OPTIONS:
   -h     help,          Show this message
   -d     build_doxygen, build doxygen files

   -b     clean_build,   rm -rf gpstk_root/build
   -i     clean_install, rm -rf gpstk_install

   -o     core_only,     only builds core library code
   -t     test_switch,   initialize test framework
   -v     graphviz,      generate dependency graph (.DOT and .PDF files)

   -r     gpstk_root,    default = ~/git/gpstk/dev, path to GPSTk top-level CMakeLists.txt file (and source tree)
   -s     gpstk_install, default = ~/git/gpstk/install,  path to GPSTk install, e.g. ~/opt/gpstk, to contain ./bin, ./lib, and ./include
  
EOF

exit 1
}

#----------------------------------------
# initialize variables as empty
#----------------------------------------

build_doxygen=
clean_build=
clean_install=
core_only=
test_switch=
graphviz=
gpstk_root=
gpstk_install=

#----------------------------------------
# initialize Color Codes
#----------------------------------------

green='\e[1;32m'
red='\e[1;31m'
normal='\e[0m'
white='\e[1;37m'
cyan='\e[1;36m'
purple='\e[1;35m'
brown='\e[1;33m'

#----------------------------------------
# Parse input arguments
#----------------------------------------

while getopts "hdbiotv:r:s:" option; do

  case $option in

    h)
      usage
      ;;

    d)
      build_doxygen=1
      ;;

    b)
      clean_build=1
      ;;

    i)
      clean_install=1
      ;;

    o)
      core_only=1
      ;;

    t)
      test_switch=1
      ;;

    v)
      graphviz=1
      ;;

    r)
      gpstk_root=${OPTARG}
      ;;

    s)
      gpstk_install=${OPTARG}
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;

  esac
done

# Shift OPTIND so that if there are any additional 
# command line options we did not capture,
# then they are accessible via use of $*
shift $(($OPTIND - 1))

#----------------------------------------
# Set input arg defaults, if empty
#----------------------------------------

if [ -z $build_doxygen ]
    then
        build_doxygen=0
        echo "$0: Input arg: build_doxygen = $build_doxygen (default)"
    else
        echo "$0: Input arg: build_doxygen = $build_doxygen (user provided)"
fi

if [ -z $clean_build ]
    then
        clean_build=0
        echo "$0: Input arg: clean_build   = $clean_build (default)"
    else
        echo "$0: Input arg: clean_build   = $clean_build (user provided)"
fi

if [ -z $clean_install ]
    then
        clean_install=0
        echo "$0: Input arg: clean_install = $clean_install (default)"
    else
        echo "$0: Input arg: clean_install = $clean_install (user provided)"
fi

if [ -z $gpstk_root ]
    then
        gpstk_root=~/git/gpstk/dev
        echo "$0: Input arg: gpstk_root    = $gpstk_root (default)"
    else
        echo "$0: Input arg: gpstk_root    = $gpstk_root (user provided)"
fi

if [ -z $gpstk_install ]
    then
        gpstk_install=~/git/gpstk/install
        echo "$0: Input arg: gpstk_install = $gpstk_install (default)"
    else
        echo "$0: Input arg: gpstk_install = $gpstk_install (user provided)"
fi

if [ -z $core_only ]
    then
        core_only=0
        echo "$0: Input arg: core_only     = $core_only (default)"
    else
        echo "$0: Input arg: core_only     = $core_only (user provided)"
fi

if [ -z $test_switch ]
    then
        test_switch=0
        echo "$0: Input arg: test_switch   = $test_switch (default)"
    else
        echo "$0: Input arg: test_switch   = $test_switch (user provided)"
fi

if [ -z $graphviz ]
    then
        graphviz=0
        echo "$0: Input arg: graphviz      = $graphviz (default)"
    else
        echo "$0: Input arg: graphviz      = $graphviz (user provided)"
fi

#----------------------------------------
# Test gpstk paths before doing anything
#----------------------------------------

if [ -d $gpstk_root ]
    then
        echo "$0: Paths: $gpstk_root, directory exist test = PASS"
    else
        echo "$0: Paths: $gpstk_root, directory exist test = FAIL"
        echo "$0: exitting..."
        exit 1
fi

if [ ! -d $gpstk_root/build ]
    then
        echo "$0: Paths: Creating $gpstk_root/build directory"
        mkdir $gpstk_root/build
fi

if [ ! -d $gpstk_install ]
    then
        echo "$0: Paths: Creating $gpstk_install directory"
        mkdir $gpstk_install
fi

#----------------------------------------
# Optionally clean out the last gpstk build
#----------------------------------------

if [[ "$clean_build" == 0 ]]
    then
        echo "$0: Options: Previous build to be removed = FALSE"
    else
        echo "$0: Options: Previous build to be removed = TRUE"
        rm -rf $gpstk_root/build
        mkdir $gpstk_root/build
fi

#----------------------------------------
# Optionally clean out the last gpstk install
#----------------------------------------

if [[ "$clean_install" == 0 ]]
    then
        echo "$0: Options: Previous install to be removed = FALSE"
    else
        echo "$0: Options: Previous install to be removed = TRUE"
        rm -rf $gpstk_install
        mkdir $gpstk_install
fi

#----------------------------------------
# Test and then export install paths needed by CMake
#----------------------------------------

if [ -d $gpstk_install ]
    then
        echo "$0: Paths: $gpstk_install, directory exist test = PASS"
    else
        echo "$0: Paths: $gpstk_install, directory exist test = FAIL"
        echo "$0: exitting..."
        exit 1
fi

# This is required by the current CMake set-up
echo "$0: Paths: Exporting install paths..."

export gpstk=$gpstk_install


#----------------------------------------
# CMake
#----------------------------------------

# Construct CMake command string based on script options
# Reminder: to set variables from command line use "$ cmake -D <var>:<type>=<value>"

cmake_command="cmake"

# Update CMake command if optional core_only switch was selected.
if [[ "$core_only" == 0 ]]
    then
        echo "$0: Options: core_only build library = FALSE"
    else
        echo "$0: Options: core_only build library = TRUE"
        cmake_command=$cmake_command" -DCORE_ONLY=ON"
fi

# Update CMake command if optional test switch was selected.
if [[ "$test_switch" == 0 ]]
    then
        echo "$0: Options: test_switch test framework = FALSE"
    else
        echo "$0: Options: test_switch test framework = TRUE"
        cmake_command=$cmake_command" -DTEST_SWITCH=ON"
fi

# Update CMake command if optional Graphiz output was selected.
if [[ "$graphviz" == 0 ]]
    then
        echo "$0: Options: generate graphviz output = FALSE"
    else
        echo "$0: Options: generate graphviz output = TRUE"
        path_graphviz=$gpstk_install/graphviz
        mkdir $path_graphviz
        cmake_command=$cmake_command" --graphviz=$path_graphviz/gpstk_graphviz.dot"
fi

# Specify path of top-level CmakeLists.txt file
cmake_command=$cmake_command" $gpstk_root"

# Evaluate CMake command string from the build directory
echo "$0: Calling CMake as: $cmake_command"
cd $gpstk_root/build
eval $cmake_command

#----------------------------------------
# Doxygen
#----------------------------------------

# Build Doxygen Files
if [[ "$build_doxygen" == 0 ]]
    then
        echo "$0: Options: generate doxygen files = FALSE"
    else
        echo "$0: Options: generate doxygen files = TRUE"
        
        cd $gpstk_root
        doxygen
fi

#----------------------------------------
# GraphViz
#----------------------------------------

# Convert graphviz .DOT file into a .PDF
# Can only be called AFTER the cmake command is executed
if [[ "$graphviz" == 0 ]]
    then
        echo "$0: Options: generate graphviz PDF = FALSE"
    else
        echo "$0: Options: generate graphviz PDF = TRUE"
        dot -Tpdf $path_graphviz/gpstk_graphviz.dot -o $path_graphviz/gpstk_graphviz.pdf
fi

#----------------------------------------
# Make
#----------------------------------------

# Detect system OS flavor
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]
    then
        platform='linux'
    elif [[ "$unamestr" == 'Darwin' ]]
        then
            platform='osx'
    elif [[ "$unamestr" == 'FreeBSD' ]]
        then
            platform='freebsd'
fi

# Determine number of cores so that we can make make faster
num_cores=1
if [[ "$platform" == "osx" ]]
    then
        num_cores=`sysctl -n hw.ncpu`
    elif [[ "$platform" == "linux" ]]
        then
            last_core_index=`cat /proc/cpuinfo | grep "processor" | awk '{print $3}' | tail -1`
            num_cores=`echo "$last_core_index + 1" | bc`
    else
        num_cores=1
fi

# Modify make command to use "-j" flag if you have multiple cores
if [ "$num_cores" -gt "1" ]
   then
      echo "$0: Optimizing: Discovered multiple ($num_cores) cores for use with 'make -j' "
      make_command="make -j $num_cores"
   else
      make_command="make"
fi

# Evaluate make command from GPSTk build directory 
echo "$0: Calling make and make install..."
cd $gpstk_root/build
eval $make_command

# Install!
make install

#----------------------------------------
# Echo the contents of the install paths
#----------------------------------------

cd $gpstk_install
echo ""
echo "$0: Installed file listing..."

echo ""
echo "$0: Installed binaries: $gpstk_install/bin/"
ls $gpstk_install/bin

echo ""
echo "$0: Installed headers: $gpstk_install/include/"
ls $gpstk_install/include

echo ""
echo "$0: Installed libraries: $gpstk_install/lib/"
ls $gpstk_install/lib

echo ""
echo ""
echo "$0: ...done."
echo ""
echo ""

if [[ "$test_switch" == 1 ]]
    then
        cd $gpstk_root/build
        ctest -v
fi

#----------------------------------------
# The End
#----------------------------------------