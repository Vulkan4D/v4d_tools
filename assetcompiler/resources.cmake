foreach(dir ${ASSETS_DIRS})
	file(GLOB_RECURSE srcResources RELATIVE ${ASSETS_RELATIVE_SRC}/ ${dir}/resources/**)
	foreach(resource ${srcResources})
		string(REGEX REPLACE "^v4d/" "" resourcePath ${resource})
		set(fileInput ${ASSETS_RELATIVE_SRC}/${resource})
		set(fileOutput ${RUNTIME_OUTPUT_DIRECTORY}/${resourcePath})
		add_custom_command(
			MAIN_DEPENDENCY ${fileInput}
			OUTPUT ${fileOutput} POST_BUILD
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
			COMMAND ${CMAKE_COMMAND} -E copy ${fileInput} ${fileOutput}
		)
		list(APPEND copiedResources ${fileOutput})
	endforeach()
endforeach()

add_custom_target(resources ALL DEPENDS ${copiedResources})
