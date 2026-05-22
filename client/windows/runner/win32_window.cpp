#include "win32_window.h"
#include <dwmapi.h>
#include <flutter_windows.h>

namespace {
constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
}

Win32Window::Win32Window() {}
Win32Window::~Win32Window() { Destroy(); }

bool Win32Window::Create(const std::wstring& title, const Point& origin, const Size& size) {
  Destroy();
  if (!RegisterWindowClass()) return false;
  return CreateWindow(title, origin, size);
}

void Win32Window::Show() { ShowWindow(hwnd_, SW_SHOWNORMAL); }

void Win32Window::Destroy() {
  if (hwnd_) { DestroyWindow(hwnd_); hwnd_ = nullptr; }
}

void Win32Window::SetQuitOnClose(bool quit_on_close) { quit_on_close_ = quit_on_close; }

RECT Win32Window::GetClientArea() {
  RECT frame;
  GetClientRect(hwnd_, &frame);
  return frame;
}

bool Win32Window::RegisterWindowClass() {
  WNDCLASS wc = {};
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = kWindowClassName;
  return RegisterClass(&wc) != 0;
}

bool Win32Window::CreateWindow(const std::wstring& title, const Point& origin, const Size& size) {
  DWORD style = WS_OVERLAPPEDWINDOW;
  DWORD exStyle = WS_EX_APPWINDOW;

  RECT window_rect = {origin.x, origin.y, origin.x + size.width, origin.y + size.height};
  AdjustWindowRectEx(&window_rect, style, FALSE, exStyle);

  hwnd_ = CreateWindowEx(exStyle, kWindowClassName, title.c_str(), style,
      CW_USEDEFAULT, CW_USEDEFAULT, window_rect.right - window_rect.left,
      window_rect.bottom - window_rect.top, nullptr, nullptr,
      GetModuleHandle(nullptr), this);
  if (!hwnd_) return false;

  ShowWindow(hwnd_, SW_SHOWMAXIMIZED);
  return true;
}

LRESULT Win32Window::WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) {
  Win32Window* window = reinterpret_cast<Win32Window*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));
  if (window) {
    if (message == WM_DESTROY) {
      SetWindowLongPtr(hwnd, GWLP_USERDATA, 0);
      window = nullptr;
    }
    return window->MessageHandler(hwnd, message, wparam, lparam);
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}

LRESULT Win32Window::MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) noexcept {
  switch (message) {
    case WM_DESTROY:
      hwnd_ = nullptr;
      if (quit_on_close_) PostQuitMessage(0);
      return 0;
    case WM_DPICHANGED: {
      auto* rect = reinterpret_cast<RECT*>(lparam);
      SetWindowPos(hwnd, nullptr, rect->left, rect->top, rect->right - rect->left, rect->bottom - rect->top, SWP_NOZORDER | SWP_NOACTIVATE);
      return 0;
    }
  }
  return DefWindowProc(hwnd, message, wparam, lparam);
}
