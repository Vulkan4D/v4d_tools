#include <v4d.h>
#include "utilities/io/FilePath.h"

#include <sys/stat.h>
#include <filesystem>
#include <vector>
#include <string>
#include <regex>
#include <unordered_map>
#include <fstream>

using namespace std;

filesystem::path inputFilePath, outputFilePath;
vector<filesystem::path> includePaths {};
vector<string> shaderSpvFiles {};
stringstream commandLine {""};
string firstLine {"#version 460 core\n\n"};
std::unordered_map<std::string,int> includedFilesList {};

#define SHADER_REGEX_EXT_TYPES_GLSL "vert|tesc|tese|geom|frag|comp|mesh|task|rgen|rint|rahit|rchit|rmiss|rcall"
#define SHADER_REGEX_EXT_TYPES "conf|glsl|hlsl|" SHADER_REGEX_EXT_TYPES_GLSL

int exec(string cmd) {
	return system(cmd.c_str());
}

bool CompileShader(string src, string dst) {
	// Delete existing file
	remove(dst.c_str());
	// Compile with glslangValidator
	string command(string("glslangValidator -V --target-env vulkan1.2 '") + src + "' -o '" + dst + "'");
	// string output;
	int exitCode = exec(command + " 2>&1"/*, output*/);
	// cout << "::::Compiling Shader........ " << command << endl << output;
	return exitCode == 0;
}

bool GenerateMetaFile() {
	ofstream outputFile(outputFilePath.string(), fstream::out);
	for (auto& file : shaderSpvFiles) {
		outputFile << regex_replace(file, regex("^.*/([^/]+)\\.spv$"), string("$1")) << endl;
	}
	outputFile.close();
	
	std::stringstream includedFiles {""};
	for (auto [incl,_] : includedFilesList)
		includedFiles << "\\\n  '" << incl << "'";
	
	// Generate Watch file (auto-compile upon saving source file)
	string watchFilePath = regex_replace(outputFilePath.string(), regex("^(.*)\\.meta$"), string("$1.watch.sh"));
	ofstream watchCommand(watchFilePath, fstream::out);
	watchCommand << "inotifywait -e modify \\\n  '" << inputFilePath.string() << "'" << includedFiles.str() << "\n\nif [[ -e '" << outputFilePath.string() << "' ]] ; then\n  echo \"\n  \"\n  " << commandLine.str() << "\n  echo \"\n  \"\n  sh -c $0 \nfi" << endl;
	watchCommand.close();
	chmod(watchFilePath.c_str(), 0777);
	return true;
}

struct ShaderStage {
	string type;

	stringstream content{""};

	ShaderStage(const string& type) : type(type) {}

	void Print() { cout << content.str() << endl; }

	bool Compile() {
		// Write temporary shader file
		v4d::io::FilePath tmpfilepath(regex_replace(outputFilePath.string(), regex("^(.*)\\.(spv|meta)$"), string("$1.") + type));
		tmpfilepath.AutoCreateFile();
		ofstream tmp(string(tmpfilepath), fstream::out | fstream::trunc);
		tmp << content.str();
		tmp.close();
		// Compile it and delete tmp file on success
		if (CompileShader(tmpfilepath, string(tmpfilepath)+".spv")) {
			// tmpfilepath.Delete();
			shaderSpvFiles.push_back(string(tmpfilepath)+".spv");
			return true;
		}
		return false;
	}

};

void IncludeFile(filesystem::path parentFile, const string& filepath, stringstream* content);

void ParseLine(const string& inputFile, const string& line, stringstream* content) {
	
	// Ignore separation lines
	if (regex_match(line.c_str(), regex("\\s*##.+"))) 
		return;
	
	// Include other files
	if (regex_match(line.c_str(), regex("\\s*#include.+"))) {
		cmatch match;
		if (regex_match(line.c_str(), match, regex("\\s*#include\\s*\"(.+)\"\\s*$")) || regex_match(line.c_str(), match, regex("\\s*#include\\s*<(.+)>\\s*$"))) {
			IncludeFile(inputFile, match[1].str(), content);
		} else {
			throw runtime_error(string("Failed to parse include directive '") + line + "'");
		}
		return;
	} else if (regex_match(line.c_str(), regex("\\s*#version.+"))) {
		firstLine = line + '\n';
		return;
	}
	
	// Insert the line
	*content << line << '\n';
}

void IncludeFile(filesystem::path parentFile, const string& includeFile, stringstream* content) {
	filesystem::path includeFilePath(includeFile);
	if (!filesystem::exists(includeFilePath)) {
		includeFilePath = parentFile.parent_path().string() + '/' + includeFile;
		if (!filesystem::exists(includeFilePath)) {
			for (auto dir : includePaths) {
				includeFilePath = dir.string() + '/' + includeFile;
				if (filesystem::exists(includeFilePath)) break;
			}
		}
	}
	if (!filesystem::exists(includeFilePath) || filesystem::is_directory(includeFilePath)) {
		throw runtime_error(string("Failed to include file '") + includeFilePath.string() + "' in '" + parentFile.string() + "'");
	}
	ifstream filecontent(includeFilePath);
	string line;
	while (getline(filecontent, line)) ParseLine(includeFilePath.string(), line, content);
	includedFilesList[includeFilePath]++;
}

int main(const int argc, const char** args) {
	commandLine << "'" << string(args[0]) << "'";
	
	if (argc < 3) 
		throw runtime_error("You must provide at least two arguments (input and output paths). Additional arguments are include paths.");
		
	inputFilePath = args[1];
	outputFilePath = args[2];
	
	commandLine << " '" << string(args[1]) << "' '" << string(args[2]) << "'";
	
	for (int i = 3; i < argc; ++i) {
		includePaths.emplace_back(args[i]);
		commandLine << " '" << string(args[i]) << "'";
	}
	
	// Check input file
	if (!filesystem::exists(inputFilePath) || !filesystem::is_regular_file(inputFilePath))
		throw runtime_error(string("Input file does not exist '") + inputFilePath.string() + "'");
	
	if (inputFilePath.extension() == "" || !regex_match(inputFilePath.filename().string().c_str(), regex("^.*\\.((" SHADER_REGEX_EXT_TYPES_GLSL ")\\.glsl|(" SHADER_REGEX_EXT_TYPES "))$")))
		throw runtime_error(string("Invalid input file path extension '") + inputFilePath.string() + "'");
		
	// For a glsl file, parse it then compile it
	if (regex_match(inputFilePath.filename().string().c_str(), regex("^.*\\.((" SHADER_REGEX_EXT_TYPES_GLSL ")\\.glsl|(" SHADER_REGEX_EXT_TYPES_GLSL "))$"))) {
		
		if (outputFilePath.extension() != ".spv")
			throw runtime_error(string("Invalid output file path '") + inputFilePath.string() + "' (missing .spv extension)");
		
		// Input File is an individual stage to be compiled directly with glslangValidator
		if (!CompileShader(inputFilePath.string(), outputFilePath.string()))
			throw runtime_error("Failed to compile shader");
		
	} else if (inputFilePath.extension() == ".glsl") {
		// Input File is multistage, must be Separated, Compiled, then a meta file is created
		
		if (outputFilePath.extension() != ".meta")
			throw runtime_error(string("Invalid output file path '") + inputFilePath.string() + "' (missing .meta extension)");
		
		// Prepare 2 initial places in memory to store shader stages
		vector<ShaderStage> stages;
		stages.reserve(2);

		// Read from filepath
		ifstream filecontent(inputFilePath, fstream::in);

		// Initialize some vars
		string line;
		vector<tuple<string, stringstream*>> common {};
		stringstream* current_common = get<1>(common.emplace_back("", new stringstream("//////////// Common content for all ///////////\n")));
		string type = "";
		int index = -1;

		// Go through each line of the input file
		while (getline(filecontent, line)) {
			// If line is a shader definition, create a new shader and assign its type
			cmatch match;
			if (regex_match(line.c_str(), match, regex("\\s*#(shader|stage)\\s+((\\w+\\.)*(" SHADER_REGEX_EXT_TYPES_GLSL "))(\\.?(\\d*))\\s*"))) {
				type = match[2].str();
				std::string typeUPPER = match[4].str();
				v4d::String::ToUpperCase(typeUPPER);
				std::string subPass = match[6].str();
				stages.emplace_back(type);
				index++;
				stages[index].content << firstLine << "#define SHADER_" << typeUPPER << "\n";
				if (subPass != "") {
					stages[index].content << "#define SHADER_SUBPASS_" << subPass << "\n";
				}
				stages[index].content << '\n';
				for (const auto& [cm, content] : common) {
					if (cm == "" || regex_match(type.c_str(), match, regex(cm))) {
						stages[index].content << content->str() << '\n';
					}
				}
			} else if (regex_match(line.c_str(), match, regex("\\s*#common\\s+(.+)\\s*"))) {
				auto cm = new stringstream("");
				*cm << "//////////// Common content for '" << match[1].str() << "' ///////////\n";
				current_common = get<1>(common.emplace_back(match[1].str(), cm));
			} else {
				ParseLine(inputFilePath.string(), line, (type == "")? current_common : &stages[index].content);
			}
		}
		filecontent.close();

		// Compile shader stage
		for (auto& stage : stages) if (!stage.Compile())
			throw runtime_error("SHADER COMPILATION FAILED");
		
		// Meta file
		if (!GenerateMetaFile())
			throw runtime_error("META GENERATION FAILED");
			
		for (auto&[str, strstream] : common) {
			delete strstream;
		}
	}

}
