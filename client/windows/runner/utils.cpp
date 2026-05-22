#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <map>
#include <memory>
#include <sstream>

std::vector<std::string> GetCommandLineArguments() {
  int argc;
  wchar_t** argv = ::CommandLineToArgvW(::GetCommandLineW(), &argc);
  if (argv == nullptr) return {};

  std::vector<std::string> result;
  for (int i = 1; i < argc; ++i) {
    int length = ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, nullptr, 0, nullptr, nullptr);
    if (length > 0) {
      std::vector<char> buffer(length);
      ::WideCharToMultiByte(CP_UTF8, 0, argv[i], -1, buffer.data(), length, nullptr, nullptr);
      result.push_back(buffer.data());
    }
  }
  ::LocalFree(argv);
  return result;
}
