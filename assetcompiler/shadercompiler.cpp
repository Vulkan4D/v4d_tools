#include <v4d.h>

using namespace std;

filesystem::path inputFilePath, outputFilePath;
vector<filesystem::path> includePaths {};
stringstream shaderStagesToLink{""};

#define SHADER_REGEX_EXT_TYPES_GLSL "vert|tesc|tese|geom|frag|comp|mesh|task|rgen|rint|rahit|rchit|rmiss|rcall"
#define SHADER_REGEX_EXT_TYPES "conf|glsl|hlsl|" SHADER_REGEX_EXT_TYPES_GLSL

int exec(string cmd/*, string& result*/) {
	// array<char, 128> buffer;
	// FILE* pipe(popen(cmd.c_str(), "r"));
	// if (!pipe) throw runtime_error("popen() failed!");
	// while (!feof(pipe)) {
	// 	if (fgets(buffer.data(), 128, pipe) != nullptr)
	// 		result += buffer.data();
	// }
	// return WEXITSTATUS(pclose(pipe));
	return system(cmd.c_str());
}

bool CompileShader(string src, string dst) {
	// Delete existing file
	remove(dst.c_str());
	// Compile with glslangValidator
	string command(string("$VULKAN_SDK/bin/glslangValidator -V '") + src + "' -o '" + dst + "'");
	// string output;
	int exitCode = exec(command + " 2>&1"/*, output*/);
	// cout << "::::Compiling Shader........ " << command << endl << output;
	return exitCode == 0;
}

bool LinkShaderStages() {
	
	// // Compile with glslangValidator
	// string command(string("spirv-link ") + shaderStagesToLink.str() + " -o '" + outputFilePath.string() + "'");
	// // string output;
	// int exitCode = exec(command + " 2>&1"/*, output*/);
	// // cout << "::::Linking Shader stages........ " << command << endl << output;
	// return exitCode == 0;
	
	ofstream out(outputFilePath.string(), fstream::out);
	out << "Linked Shaders not yet supported" << endl;
	out.close();
	return true;
}

struct ShaderStage {
	string type;

	stringstream content{""};

	ShaderStage(const string& type) : type(type) {}

	void Print() { cout << content.str() << endl; }

	bool Compile() {
		// Write temporary shader file
		v4d::io::FilePath tmpfilepath(regex_replace(outputFilePath.string(), regex("^(.*)\\.spv$"), string("$1.") + type));
		tmpfilepath.AutoCreateFile();
		ofstream tmp(string(tmpfilepath), fstream::out | fstream::trunc);
		tmp << content.str();
		tmp.close();
		// Compile it and delete tmp file on success
		if (CompileShader(tmpfilepath, string(tmpfilepath)+".spv")) {
			tmpfilepath.Delete();
			shaderStagesToLink << "'" << string(tmpfilepath) << ".spv" << "' ";
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
}

int main(const int argc, const char** args) {
	
	if (argc < 3) 
		throw runtime_error("You must provide at least two arguments (input and output paths). Additional arguments are include paths.");
		
	inputFilePath = args[1];
	outputFilePath = args[2];
	
	for (int i = 3; i < argc; ++i) {
		includePaths.emplace_back(args[i]);
	}
	
	// Check input file
	if (!filesystem::exists(inputFilePath) || !filesystem::is_regular_file(inputFilePath))
		throw runtime_error(string("Input file does not exist '") + inputFilePath.string() + "'");
	
	if (inputFilePath.extension() == "" || !regex_match(inputFilePath.filename().string().c_str(), regex("^.*\\.((" SHADER_REGEX_EXT_TYPES_GLSL ")\\.glsl|(" SHADER_REGEX_EXT_TYPES "))$")))
		throw runtime_error(string("Invalid input file path extension '") + inputFilePath.string() + "'");
		
	if (outputFilePath.extension() != ".spv")
		throw runtime_error(string("Invalid output file path '") + inputFilePath.string() + "' (missing .spv extension)");
	
	// For a glsl file, parse it then compile it
	if (regex_match(inputFilePath.filename().string().c_str(), regex("^.*\\.((" SHADER_REGEX_EXT_TYPES_GLSL ")\\.glsl|(" SHADER_REGEX_EXT_TYPES_GLSL "))$"))) {
		// Input File is an individual stage to be compiled directly with glslangValidator
		if (!CompileShader(inputFilePath.string(), outputFilePath.string()))
			throw runtime_error("Failed to compile shader");
		
	} else if (inputFilePath.extension() == ".glsl") {
		// Input File is multistage, must be Separated, Compiled, then Linked
		
		// Prepare 2 initial places in memory to store shader stages
		vector<ShaderStage> stages;
		stages.reserve(2);

		// Read from filepath
		ifstream filecontent(inputFilePath, fstream::in);

		// Initialize some vars
		string line;
		map<string, stringstream> common;
		string current_common = "";
		common[current_common] = stringstream("");
		string type = "";
		int index = -1;

		// Go through each line of the input file
		while (getline(filecontent, line)) {
			// If line is a shader definition, create a new shader and assign its type
			cmatch match;
			if (regex_match(line.c_str(), match, regex("\\s*#(shader|stage)\\s+((\\w+\\.)?(" SHADER_REGEX_EXT_TYPES_GLSL "))\\s*"))) {
				type = match[2].str();
				stages.emplace_back(type);
				index++;
				for (const auto& [cm, content] : common) {
					if (cm == "" || regex_match(type.c_str(), match, regex(cm))) {
						stages[index].content << content.str() << '\n';
					}
				}
			} else if (regex_match(line.c_str(), match, regex("\\s*#common\\s+(.+)\\s*"))) {
				current_common = match[1].str();
				common[current_common] = stringstream("");
			} else {
				ParseLine(inputFilePath.string(), line, (type == "")? &common[current_common] : &stages[index].content);
			}
		}
		filecontent.close();

		// Compile shader stage
		for (auto& stage : stages) if (!stage.Compile())
			throw runtime_error("SHADER COMPILATION FAILED");
		
		// Link shader stages into a single final Spir-V file
		if (!LinkShaderStages())
			throw runtime_error("SHADER LINKING FAILED");
	}

}
