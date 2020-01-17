foreach(dir ${ASSETS_DIRS})
	file(GLOB_RECURSE srcModels RELATIVE ${ASSETS_RELATIVE_SRC}/ ${dir}/models/**)
	foreach(model ${srcModels})
		string(REGEX REPLACE "^v4d/" "" modelPath ${model})
		set(fileInput ${ASSETS_RELATIVE_SRC}/${model})
		set(fileOutput ${RUNTIME_OUTPUT_DIRECTORY}/${modelPath})
		add_custom_command(
			MAIN_DEPENDENCY ${fileInput}
			OUTPUT ${fileOutput} POST_BUILD
			WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
			COMMAND ${CMAKE_COMMAND} -E copy ${fileInput} ${fileOutput}
		)
		list(APPEND copiedModels ${fileOutput})
	endforeach()
endforeach()

add_custom_target(models ALL DEPENDS ${copiedModels})
