# from here:
#
# https://github.com/lefticus/cppbestpractices/blob/master/02-Use_the_Tools_Available.md
# Courtesy of Jason Turner

function(get_warnings_copts warning_as_error _copts _cxxopts)
        set(MSVC_WARNINGS
                /W4 # Baseline reasonable warnings
                /w14242 # 'identifier': conversion from 'type1' to 'type1', possible loss

                # of data
                /w14254 # 'operator': conversion from 'type1:field_bits' to

                # 'type2:field_bits', possible loss of data
                /w14263 # 'function': member function does not override any base class

                # virtual member function
                /w14265 # 'classname': class has virtual functions, but destructor is not

                # virtual instances of this class may not be destructed correctly
                /w14287 # 'operator': unsigned/negative constant mismatch
                /we4289 # nonstandard extension used: 'variable': loop control variable

                # declared in the for-loop is used outside the for-loop scope
                /w14296 # 'operator': expression is always 'boolean_value'
                /w14311 # 'variable': pointer truncation from 'type1' to 'type2'
                /w14545 # expression before comma evaluates to a function which is missing

                # an argument list
                /w14546 # function call before comma missing argument list
                /w14547 # 'operator': operator before comma has no effect; expected

                # operator with side-effect
                /w14549 # 'operator': operator before comma has no effect; did you intend

                # 'operator'?
                /w14555 # expression has no effect; expected expression with side- effect
                /w14619 # pragma warning: there is no warning number 'number'
                /w14640 # Enable warning on thread un-safe static member initialization
                /w14826 # Conversion from 'type1' to 'type_2' is sign-extended. This may

                # cause unexpected runtime behavior.
                /w14905 # wide string literal cast to 'LPSTR'
                /w14906 # string literal cast to 'LPWSTR'
                /w14928 # illegal copy-initialization; more than one user-defined

                # conversion has been implicitly applied
                /permissive- # standards conformance mode for MSVC compiler.
        )

        set(CLANG_WARNINGS
                -Wall
                -Wextra # reasonable and standard
                # -Wshadow # warn the user if a variable declaration shadows one from a

                # parent context
                # -Wnon-virtual-dtor # warn the user if a class with virtual functions has a
                # non-virtual destructor. This helps catch hard to
                # track down memory errors
                ##-Wno-old-style-cast # warn for c-style casts
                -Wcast-align # warn for potential performance problem casts
                -Wunused # warn on anything being unused
                ##-Woverloaded-virtual # warn if you overload (not override) a virtual

                # function
                # -Wpedantic # warn if non-standard C++ is used
                -Wconversion # warn on type conversions that may lose data
                -Wsign-conversion # warn on sign conversions
                # -Wnull-dereference # warn if a null dereference is detected
                -Wdouble-promotion # warn if float is implicit promoted to double
                -Wformat=2 # warn on security issues around functions that format output
                # (ie printf)
                -Wno-dollar-in-identifier-extension
                -Wno-unused-local-typedef # suppress unused local typedef warning, for STATIC_ASSERT
        )

        set(CLANG_CXX_WARNINGS
                ${CLANG_WARNINGS}
                -Wall
                -Wextra # reasonable and standard
                # -Wshadow # warn the user if a variable declaration shadows one from a

                # parent context
                -Wnon-virtual-dtor # warn the user if a class with virtual functions has a
                # non-virtual destructor. This helps catch hard to
                # track down memory errors
                -Wno-old-style-cast # warn for c-style casts
                -Woverloaded-virtual # warn if you overload (not override) a virtual
        )

        if(warning_as_error)
            list(APPEND CLANG_WARNINGS -Werror)
            list(APPEND CLANG_CXX_WARNINGS -Werror)
            list(APPEND MSVC_WARNINGS /WX)
        endif()

        set(GCC_WARNINGS
                ${CLANG_WARNINGS}
                # -Wmisleading-indentation # warn if indentation implies blocks where blocks

                # do not exist
                # -Wduplicated-cond # warn if if / else chain has duplicated conditions
                # -Wduplicated-branches # warn if if / else branches have duplicated code
                -Wlogical-op # warn about logical operations being used where bitwise were

                # probably wanted
                ##-Wno-useless-cast # warn if you perform a cast to the same type
        )

        set(GCC_CXX_WARNINGS
                ${CLANG_CXX_WARNINGS}
                # -Wmisleading-indentation # warn if indentation implies blocks where blocks

                # do not exist
                # -Wduplicated-cond # warn if if / else chain has duplicated conditions
                # -Wduplicated-branches # warn if if / else branches have duplicated code
                -Wlogical-op # warn about logical operations being used where bitwise were

                # probably wanted
                -Wno-useless-cast # warn if you perform a cast to the same type
        )

        if(MSVC)
                set(PROJECT_WARNINGS ${MSVC_WARNINGS})
                set(PROJECT_CXX_WARNINGS ${MSVC_WARNINGS})
        elseif(CMAKE_CXX_COMPILER_ID MATCHES ".*Clang")
                set(PROJECT_WARNINGS ${CLANG_WARNINGS})
                set(PROJECT_CXX_WARNINGS ${CLANG_CXX_WARNINGS})
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                set(PROJECT_WARNINGS ${GCC_WARNINGS})
                set(PROJECT_CXX_WARNINGS ${GCC_CXX_WARNINGS})
        else()
                message(AUTHOR_WARNING "No compiler warnings set for '${CMAKE_CXX_COMPILER_ID}' compiler.")
        endif()

        # ##################################################################
        # Compiler Options
        message(STATUS "CMAKE_C_COMPILER_ID=${CMAKE_C_COMPILER_ID}, CMAKE_CXX_COMPILER_ID=${CMAKE_CXX_COMPILER_ID}")
        if(MSVC)
                set(PEDANTIC_COMPILE_FLAGS /W3)
                set(WERROR_FLAG /WX)
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "GNU")
                set(PEDANTIC_COMPILE_FLAGS 
                        #-pedantic-errors 
                        -Wall -Wextra 
                        #-pedantic

                        # -Wold-style-cast
                        # -Wundef
                        -Wredundant-decls -Wwrite-strings -Wpointer-arith
                        -Wcast-qual -Wformat=2 -Wmissing-include-dirs
                        -Wcast-align
                        ##-Wctor-dtor-privacy 
                        -Wdisabled-optimization
                        -Winvalid-pch
                        -Wconversion
                        -Wno-format-nonliteral)
                set(PEDANTIC_CXX_COMPILE_FLAGS 
                        ${PEDANTIC_COMPILE_FLAGS}
                        #-pedantic-errors 
                        -Wall -Wextra 
                        # -pedantic

                        # -Wold-style-cast
                        # -Wundef
                        -Wctor-dtor-privacy
                        -Woverloaded-virtual)

                if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 4.6)
                        list(APPEND PEDANTIC_COMPILE_FLAGS
                                -Wno-dangling-else -Wno-unused-local-typedefs)
                        list(APPEND PEDANTIC_CXX_COMPILE_FLAGS
                                -Wno-dangling-else -Wno-unused-local-typedefs)
                endif()

                if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 5.0)
                        list(APPEND PEDANTIC_COMPILE_FLAGS -Wdouble-promotion
                                -Wtrampolines # -Wuseless-cast
                                -Wshadow)
                        list(APPEND PEDANTIC_CXX_COMPILE_FLAGS -Wdouble-promotion
                                -Wtrampolines -Wzero-as-null-pointer-constant # -Wuseless-cast
                                -Wvector-operation-performance -Wsized-deallocation -Wshadow)
                endif()
                
                if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 6.0)
                        list(APPEND PEDANTIC_COMPILE_FLAGS -Wshift-overflow=2
                                -Wnull-dereference -Wduplicated-cond)
                        list(APPEND PEDANTIC_CXX_COMPILE_FLAGS -Wshift-overflow=2
                                -Wnull-dereference -Wduplicated-cond)
                endif()

                set(WERROR_FLAG -Werror)
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
                set(PEDANTIC_COMPILE_FLAGS 
                        -Wall -Wextra 
                        # -pedantic 
                        -Wconversion

                        # -Wundef
                        -Wdeprecated
                        -Wno-dollar-in-identifier-extension
                        # -Wweak-vtables
                        # -Wshadow
                        -Wno-gnu-zero-variadic-macro-arguments)

                # check_cxx_compiler_flag(-Wzero-as-null-pointer-constant HAS_NULLPTR_WARNING)
                if(HAS_NULLPTR_WARNING)
                        list(APPEND PEDANTIC_COMPILE_FLAGS
                                -Wzero-as-null-pointer-constant)
                endif()

                set(WERROR_FLAG -Werror)
        endif()
        
        list(APPEND PROJECT_WARNINGS ${PEDANTIC_COMPILE_FLAGS})
        if (PEDANTIC_CXX_COMPILE_FLAGS)
          list(APPEND PROJECT_CXX_WARNINGS ${PEDANTIC_CXX_COMPILE_FLAGS})
        else()
          list(APPEND PROJECT_CXX_WARNINGS ${PEDANTIC_COMPILE_FLAGS})
        endif()

        # Compiler Options
        # ####################################################################

        list(REMOVE_DUPLICATES PROJECT_WARNINGS)
        list(REMOVE_DUPLICATES PROJECT_CXX_WARNINGS)
        list(REMOVE_ITEM PROJECT_WARNINGS "-Wpedantic")
        list(REMOVE_ITEM PROJECT_CXX_WARNINGS "-Wpedantic")
        set(${_copts} ${PROJECT_WARNINGS} PARENT_SCOPE)
        set(${_cxxopts} ${PROJECT_CXX_WARNINGS} PARENT_SCOPE)
endfunction(get_warnings_copts)
