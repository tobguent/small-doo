CMAKE_MINIMUM_REQUIRED(VERSION 3.8.0)

PROJECT(small_doo CXX)

SET (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)
FIND_PACKAGE(DirectX REQUIRED)

IF(WIN32)
  ADD_DEFINITIONS(-DNOMINMAX)
ENDIF()


SET(VP_SOURCES 
shader_MinGather_LowRes.hlsl
shader_RenderFragments.hlsl
shader_SortFragments_LowRes.hlsl
shader_SortFragments.hlsl
)

SET(VGP_SOURCES 
shader_CreateLists_HQ.hlsl
shader_CreateLists_LowRes.hlsl
)

SET(CS_SOURCES 
shader_FadeToAlphaPerVertex.hlsl
shader_SmoothAlpha.hlsl
)

SET(OBJ_SOURCES 
data/heli.obj
data/rings.obj
data/tornado.obj
)

# executable
set(SOURCES main.cpp camera.hpp cbuffer.hpp d3d.hpp lines.hpp math.hpp renderer.hpp ${VP_SOURCES} ${VGP_SOURCES} ${CS_SOURCES} shader_Common.hlsli ${OBJ_SOURCES})
ADD_EXECUTABLE(small_doo ${SOURCES})
TARGET_LINK_LIBRARIES(small_doo ${DirectX_D3D11_LIBRARY} ${DirectX_DXGI_LIBRARY})

if(WIN32) # Check if we are on Windows
  if(MSVC) # Check if we are using the Visual Studio compiler
    set_target_properties(small_doo PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/$(CONFIGURATION)")
    set_target_properties(small_doo PROPERTIES LINK_FLAGS "/SUBSYSTEM:WINDOWS")
  endif()
endif()


foreach(SOURCE ${VP_SOURCES})
  GET_FILENAME_COMPONENT(FILE_WE ${SOURCE} NAME_WE)
  ADD_CUSTOM_COMMAND(OUTPUT ${FILE_WE}.vso
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.vso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tvs_5_0 /E VS
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.pso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tps_5_0 /E PS
                     MAIN_DEPENDENCY ${SOURCE}
                     COMMENT "Compile vertex and pixel shader: ${SOURCE} \n ${COMMAND}"
                     VERBATIM)
endforeach(SOURCE)

foreach(SOURCE ${VGP_SOURCES})
  GET_FILENAME_COMPONENT(FILE_WE ${SOURCE} NAME_WE)
  ADD_CUSTOM_COMMAND(OUTPUT ${FILE_WE}.vso
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.vso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tvs_5_0 /E VS
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.gso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tgs_5_0 /E GS
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.pso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tps_5_0 /E PS
                     MAIN_DEPENDENCY ${SOURCE}
                     COMMENT "Compile vertex, geometry and pixel shader: ${SOURCE} \n ${COMMAND}"
                     VERBATIM)
endforeach(SOURCE)

foreach(SOURCE ${CS_SOURCES})
  GET_FILENAME_COMPONENT(FILE_WE ${SOURCE} NAME_WE)
  ADD_CUSTOM_COMMAND(OUTPUT ${FILE_WE}.cso
					 COMMAND ${DirectX_FXC_EXECUTABLE} /Fo ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${FILE_WE}.cso ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} /nologo /O2 /Tcs_5_0 /E CS
                     MAIN_DEPENDENCY ${SOURCE}
                     COMMENT "Compile compute shader: ${SOURCE} \n ${COMMAND}"
                     VERBATIM)
endforeach(SOURCE)

foreach(SOURCE ${OBJ_SOURCES})
  GET_FILENAME_COMPONENT(FILE_WE ${SOURCE} NAME_WE)
  ADD_CUSTOM_COMMAND(OUTPUT ${FILE_WE}.obj
					 COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/${SOURCE} ${CMAKE_BINARY_DIR}/$<CONFIGURATION>/${SOURCE}
                     MAIN_DEPENDENCY ${SOURCE}
                     COMMENT "Copy resource to output: ${SOURCE} \n ${COMMAND}"
                     VERBATIM)
endforeach(SOURCE)
