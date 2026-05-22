#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>
#include <functional>
#include <memory>
#include <string>

class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height) : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  bool Create(const std::wstring& title, const Point& origin, const Size& size);
  void Show();
  void Destroy();
  void SetQuitOnClose(bool quit_on_close);
  RECT GetClientArea();

 protected:
  virtual LRESULT MessageHandler(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) noexcept;
  virtual bool OnCreate();
  virtual void OnDestroy();

 private:
  bool RegisterWindowClass();
  bool CreateWindow(const std::wstring& title, const Point& origin, const Size& size);
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

  HWND hwnd_ = nullptr;
  bool quit_on_close_ = false;
};

#endif  // RUNNER_WIN32_WINDOW_H_
