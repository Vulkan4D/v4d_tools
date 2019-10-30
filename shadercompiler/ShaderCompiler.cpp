#include <array>
#include <vector>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <unordered_map>
#include <regex>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <sys/stat.h>

// https://github.com/KhronosGroup/glslang/

using namespace std;

string outputPath;

static unordered_map<uint, const char*> SHADER_TYPES = {
	{1, "vert"},
	{2, "tesc"},
	{3, "tese"},
	{4, "geom"},
	{5, "frag"},
	{6, "comp"},
	// {7, "conf"},
};

string exec(string cmd) {
	array<char, 128> buffer;
	string result;
	shared_ptr<FILE> pipe(popen(cmd.c_str(), "r"), pclose);
	if (!pipe) throw runtime_error("popen() failed!");
	while (!feof(pipe.get())) {
		if (fgets(buffer.data(), 128, pipe.get()) != nullptr)
			result += buffer.data();
	}
	return result;
}

bool CompileShader(string src, string dst) {
	// Delete existing file
	remove(dst.c_str());
	// Compile with glslangValidator
	string output = exec(string("$VULKAN_SDK/bin/glslangValidator -V '") + src + "' -o '" + dst + "' 2>&1");
	cout << "::::Compiling Shader........ " << output;
	return output.find("ERROR:") == string::npos;
}

struct Shader {
	string name;
	uint type;

	stringstream content;

	Shader(string name, uint type) : name(name), type(type) {}

	void Print() { cout << content.str() << endl; }

	bool Compile() {
		// Write temporary shader file
		string tmpfilepath = outputPath + "/" + name + "." + SHADER_TYPES[type];
		ofstream tmp(tmpfilepath);
		tmp << content.rdbuf();
		tmp.close();
		// Compile it and delete tmp file on success
		if (CompileShader(tmpfilepath, tmpfilepath+".spv")) {
			remove(tmpfilepath.c_str());
			return true;
		}
		return false;
	}

};

void IncludeFile(string filepath, stringstream& content);

void ParseLine(string line, stringstream& content) {
	// Ignore separation lines
	if (line.find("##########") != string::npos) return;
	// Include other files
	if (line.find("#include") != string::npos) {
		string includeFile = regex_replace(line, regex(R"(\s*#include\s*|['"<>]|\s+$)"), "");
		if (includeFile.size() > 2) IncludeFile(includeFile, content);
		return;
	}
	// Insert the line
	content << line << '\n';
}

void IncludeFile(string filepath, stringstream& content) {
	ifstream filecontent(filepath);
	string line;
	while (getline(filecontent, line)) ParseLine(line, content);
}

int main(const int argc, const char** args) {
	if (argc < 3) 
		throw runtime_error("You must provide a destination directory as the first argument, then one or more glsl files.");

	// Check output directory
	outputPath = args[1];
	if (struct stat statbuf; stat(outputPath.c_str(), &statbuf) != 0 || !S_ISDIR(statbuf.st_mode)) 
		throw runtime_error(string("You must create directory '") + outputPath + "'");

	// Parse cache file
	string cachefile = outputPath+"/shadercache.txt";
	regex cacheLineRegex(R"(^\s*([^:]+):(\d+)\s*$)");
	unordered_map<string, long> filetimes;
	ifstream inCacheFile(cachefile);
	string line;
	while (getline(inCacheFile, line)) {
		if (regex_match(line, cacheLineRegex)) {
			filetimes[regex_replace(line, cacheLineRegex, "$1")] = stol(regex_replace(line, cacheLineRegex, "$2"));
		}
	}
	inCacheFile.close();

	int nbShadersCompiled = 0;
	for (int i = 2; i < argc; i++) {
		// Parse file path and type
		string filepath = args[i];
		regex filepathRegex(R"(^(.*/|)([^/]+)\.([^\.]+)$)");
		if (!regex_match(filepath, filepathRegex)) 
			throw runtime_error(string("Given filepath is invalid '") + filepath + "'");
		string name = regex_replace(filepath, filepathRegex, "$2");
		string filetype = regex_replace(filepath, filepathRegex, "$3");

		// Check input file
		struct stat statbuf;
		if (stat(filepath.c_str(), &statbuf) != 0) 
			throw runtime_error(string("File does not exist '") + filepath + "'");
		// Compare mtime with cache
		if (statbuf.st_mtime == filetimes[filepath])
			continue;
		// Add mtime in cache file
		filetimes[filepath] = statbuf.st_mtime;

		// For a glsl file, parse it then compile it
		if (filetype == "glsl") {
			// Prepare 2 initial places in memory to store some shaders
			vector<Shader> shaders;
			shaders.reserve(2);

			// Read from filepath
			ifstream filecontent(filepath);

			// Initialize some vars
			string line;
			stringstream common;
			uint type = 0;
			int index = -1;

			// Go through each line of the input file
			while (getline(filecontent, line)) {
				// If line is a shader definition, create a new shader and assign its type
				if (line.find("#shader") != string::npos) {
					auto p = find_if(SHADER_TYPES.begin(), SHADER_TYPES.end(), [&line](pair<const uint, const char*>& pair) {
						return line.find(pair.second) != string::npos;
					});
					if (p != SHADER_TYPES.end()) {
						type = p->first;
						shaders.push_back(Shader(name, type));
						index++;
						shaders[index].content << common.str() << '\n';
					}
				} else {
					ParseLine(line, (type == 0)? common : shaders[index].content);
				}
			}
			filecontent.close();

			// Compile shader
			for (auto& shader : shaders) if (!shader.Compile()) {
				throw runtime_error("SHADER COMPILATION FAILED");
			}

		} else {
			// If input file is one of SHADER_TYPES, compile it directly without parsing
			if (find_if(SHADER_TYPES.begin(), SHADER_TYPES.end(), [&filetype](pair<const uint, const char*>& pair) {return filetype == pair.second;}) != SHADER_TYPES.end()) {
				if (!CompileShader(filepath, outputPath+"/"+name+"."+filetype+".spv")) {
					throw runtime_error("SHADER COMPILATION FAILED");
				}
			} else {
				throw runtime_error(string("Given filepath is not a valid shader file '") + filepath + "'");
			}
		}

		// Compilation success
		nbShadersCompiled++;
	}

	// Write cache file
	ofstream outCacheFile(cachefile);
	outCacheFile.clear();
	for (auto f : filetimes) {
		outCacheFile << f.first << ":" << f.second << endl;
	}
	outCacheFile.close();

	// Success !

	if (nbShadersCompiled > 0) 
		cout << nbShadersCompiled << " SHADERS COMPILED SUCCESSFULLY!" << endl;
	return 0;
}
