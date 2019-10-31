add_executable(shadercompiler "shadercompiler.cpp")

target_link_libraries(shadercompiler
	v4d
)

set_target_properties(shadercompiler
	PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}"
		RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}"
)

file(GLOB_RECURSE srcShaders RELATIVE ${ASSETS_RELATIVE_SRC}/ ${ASSETS_GLOB_SEARCH}/shaders/**)
foreach(shader ${srcShaders})
	string(REGEX MATCH ".*/[a-zA-Z0-9][^/]*\.(conf|glsl|hlsl|vert|tesc|tese|geom|frag|comp|mesh|task|rgen|rint|rahit|rchit|rmiss|rcall)$" IsShader ${shader})
	if(IsShader)
		string(REGEX REPLACE "\.glsl$" "" shaderFileName ${shader})
		set(shaderInput ${ASSETS_RELATIVE_SRC}/${shader})
		set(shaderOutput ${RUNTIME_OUTPUT_DIRECTORY}/${shaderFileName}.spv)
		add_custom_command(
			MAIN_DEPENDENCY ${shaderInput}
			OUTPUT ${shaderOutput} POST_BUILD
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
			COMMAND ${CMAKE_BINARY_DIR}/shadercompiler${CMAKE_EXECUTABLE_SUFFIX} ${shaderInput} ${shaderOutput} ${PROJECT_SOURCE_DIR}/src
		)
		list(APPEND compiledShaders ${shaderOutput})
	endif()
endforeach()

add_custom_target(shaders ALL DEPENDS ${compiledShaders})
add_dependencies(shaders shadercompiler)

