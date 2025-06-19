##############################################################################
# Build global options
# NOTE: Can be overridden externally.
#

PROJECT_DIR = .

# Imported source files and paths
RUSEFI_LIB = .
include $(RUSEFI_LIB)/util/util.mk
include $(RUSEFI_LIB)/pt2001/pt2001.mk
include $(RUSEFI_LIB)/sent/sent.mk

# C sources that can be compiled in ARM or THUMB mode depending on the global
# setting.
CSRC += \
    $(RUSEFI_LIB_C) \

# C++ sources that can be compiled in ARM or THUMB mode depending on the global
# setting.
CPPSRC += \
    $(RUSEFI_LIB_CPP) \
    $(RUSEFI_LIB_CPP_TEST) \
    util/src/timer.cpp \
    mock/lib-time-mocks.cpp \
    gtest-all.cpp \
    gmock-all.cpp \
    gtest_main.cpp \

INCDIR += \
    $(PROJECT_DIR)/ext/googletest/googlemock/ \
    $(PROJECT_DIR)/ext/googletest/googlemock/include \
    $(PROJECT_DIR)/ext/googletest/googletest \
    $(PROJECT_DIR)/ext/googletest/googletest/include \
    $(PROJECT_DIR)/mock \
    $(RUSEFI_LIB_INC) \

# User may want to pass in a forced value for SANITIZE
ifeq ($(SANITIZE),)
    ifneq ($(OS),Windows_NT)
        SANITIZE = yes
    else
        SANITIZE = no
    endif
endif

IS_MAC = no
ifneq ($(OS),Windows_NT)
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Darwin)
        IS_MAC = yes
    endif
endif

# It looks like cygwin build of mingwg-w64 has issues with gcov runtime :(
# mingw-w64 is a project which forked from mingw in 2007 - be careful not to confuse these two.
# In order to have coverage generated please download from https://mingw-w64.org/doku.php/download/mingw-builds
# Install using mingw-w64-install.exe instead of similar thing packaged with cygwin
# Both 32 bit and 64 bit versions of mingw-w64 are generating coverage data.

ifeq ($(OS),Windows_NT)
ifeq ($(USE_MINGW32_I686),)
#this one is 64 bit
  TRGT = x86_64-w64-mingw32-
else
#this one was 32 bit
  TRGT = i686-w64-mingw32-
endif
else
  TRGT =
endif

# On Mac OS gcc from mingw-w64 is a wrapper around clang
# so clang-specific coverage cmd args must be used
IS_CLANG := $(shell $(CC) --version | grep -i clang >/dev/null && echo 1 || echo 0)

ifeq ($(IS_CLANG),1)
CC   = $(TRGT)clang
CXX  = $(TRGT)clang++
CPPC = $(TRGT)clang++
LD   = $(TRGT)clang++
AS   = $(TRGT)clang -x assembler-with-cpp
else
CC   = $(TRGT)gcc
CXX  = $(TRGT)g++
CPPC = $(TRGT)g++
LD   = $(TRGT)g++
AS   = $(TRGT)gcc -x assembler-with-cpp
endif
# Enable loading with g++ only if you need C++ runtime support.
# NOTE: You can use C++ even without C++ support if you are careful. C++
#       runtime support makes code size explode.
CP   = $(TRGT)objcopy
OD   = $(TRGT)objdump
HEX  = $(CP) -O ihex
BIN  = $(CP) -O binary

$(info "Libfirmware compiler is $(CC)")

# Compiler options here.
ifeq ($(USE_OPT),)
  # -O2 is needed for mingw, without it there is a linking issue to isnanf?!?!
  #USE_OPT = $(RFLAGS) -O2 -fgnu89-inline -ggdb -fomit-frame-pointer -falign-functions=16 -std=gnu99 -Werror-implicit-function-declaration -Werror -Wno-error=pointer-sign -Wno-error=unused-function -Wno-error=unused-variable -Wno-error=sign-compare -Wno-error=unused-parameter -Wno-error=missing-field-initializers
  USE_OPT = -c -Wall -Werror=shadow -Wextra -pedantic -O0 -ggdb -g -fno-omit-frame-pointer
  USE_OPT += -Werror=missing-field-initializers
endif

# C specific options here (added to USE_OPT).
ifeq ($(USE_COPT),)
  USE_COPT = -std=c11
endif

# C++ specific options here (added to USE_OPT).
ifeq ($(USE_CPPOPT),)
  USE_CPPOPT = -std=c++20 -fno-rtti -fno-use-cxa-atexit -fPIC
endif

ifeq ($(COVERAGE),yes)
  ifeq ($(IS_CLANG),1)
    COVERAGE_FLAGS := -fprofile-instr-generate -fcoverage-mapping
    $(info Detected Clang: using LLVM-style coverage flags)
  else
    COVERAGE_FLAGS := -fprofile-arcs -ftest-coverage
    $(info Detected GCC: using GCC-style coverage flags)
  endif
  USE_OPT += $(COVERAGE_FLAGS)
  USE_CPPOPT += $(COVERAGE_FLAGS)
endif

ifeq ($(IS_CLANG),1)
  USE_CPPOPT += -Wno-unused-private-field
else
  USE_CPPOPT += -Werror=class-memaccess
endif

# Enable address sanitizer for C++ files, but not on Windows since x86_64-w64-mingw32-g++ doesn't support it.
# only c++ because lua does some things asan doesn't like, but don't actually cause overruns.
ifeq ($(SANITIZE),yes)
  ifeq ($(IS_MAC),yes)
      USE_CPPOPT += -fsanitize=address
  else
      USE_CPPOPT += -fsanitize=address -fsanitize=bounds -fno-sanitize-recover=all
  endif
endif

# Enable this if you want the linker to remove unused code and data
ifeq ($(USE_LINK_GC),)
  USE_LINK_GC = yes
endif

# Enable this if you want to see the full log while compiling.
ifeq ($(USE_VERBOSE_COMPILE),)
  USE_VERBOSE_COMPILE = no
endif

# C sources to be compiled in ARM mode regardless of the global setting.
ACSRC =

# C++ sources to be compiled in ARM mode regardless of the global setting.
ACPPSRC =

# List ASM source files here
ASMSRC =

##############################################################################
# Compiler settings
#

# Define C warning options here
CWARN = -Wall -Wextra -Wstrict-prototypes -pedantic -Wmissing-prototypes -Wold-style-definition

# Define C++ warning options here
CPPWARN = -Wall -Wextra -Werror -pedantic -Wno-error=sign-compare

#
# Compiler settings
##############################################################################

##############################################################################
# Start of default section
#

# List all default ASM defines here, like -D_DEBUG=1
DADEFS =

# List all default directories to look for include files here
DINCDIR =

# List the default directory to look for the libraries here
DLIBDIR =

# List all default libraries here
ifeq ($(OS),Windows_NT)
  # Windows
  DLIBS = -static-libgcc -static -static-libstdc++
else
  # Linux
  DLIBS = -pthread
endif

#
# End of default section
##############################################################################

##############################################################################
# Start of user section
#

# List all user C define here, like -D_DEBUG=1
UDEFS =

# Define ASM defines here
UADEFS =

# List all user directories here
UINCDIR =

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS = -lm

ifeq ($(COVERAGE),yes)
  ifeq ($(IS_CLANG),1)
    # Clang coverage: needs no -lgcov, no --coverage
    ULIBS += -fprofile-instr-generate
  else
    # GCC coverage: gcov linking needed
    ULIBS += -lgcov
  endif
endif

ifeq ($(SANITIZE),yes)
  ULIBS += -fsanitize=address -fsanitize=undefined
endif

#
# End of user defines
##############################################################################

# Define project name here
PROJECT = libfirmware_test

include rules.mk
