file(GLOB_RECURSE srcModels RELATIVE ${ASSETS_RELATIVE_SRC}/ ${ASSETS_GLOB_SEARCH}/models/**)
foreach(model ${srcModels})
	set(fileInput ${ASSETS_RELATIVE_SRC}/${model})
	set(fileOutput ${RUNTIME_OUTPUT_DIRECTORY}/${model})
	add_custom_command(
		MAIN_DEPENDENCY ${fileInput}
		OUTPUT ${fileOutput} POST_BUILD
		WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
		COMMAND ${CMAKE_COMMAND} -E copy ${fileInput} ${fileOutput}
	)
	list(APPEND copiedModels ${fileOutput})
endforeach()

add_custom_target(models ALL DEPENDS ${copiedModels})
