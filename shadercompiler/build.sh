cd `dirname $0`




g++ -std=c++17 -m64 -Wall -I.\
  -o shadercompiler.linux \
  ShaderCompiler.cpp \
&&\




echo "
BUILD SUCCESS
"
