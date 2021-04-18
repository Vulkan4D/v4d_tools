set(ASSETS_RELATIVE_SRC ${PROJECT_SOURCE_DIR}/src)

set(ASSETS_DIRS 
	${ASSETS_RELATIVE_SRC}/assets
	${ASSETS_RELATIVE_SRC}/v4d/game/assets
	${ASSETS_RELATIVE_SRC}/v4d/modules/*/assets
)

include(shaders.cmake)
include(resources.cmake)
