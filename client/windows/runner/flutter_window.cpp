#include "flutter_window.h"
#include <optional>
#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow() {}
FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) return false;

  RECT frame = GetClientArea();
  project_ = flutter::DartProject::FromData();

  flutter_view_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);

  if (!flutter_view_controller_) return false;

  RegisterPlugins(flutter_view_controller_->engine());
  SetChildContent(flutter_view_controller_->view()->GetNativeWindow());

  flutter_view_controller_->engine()->SetNextFrameCallback([&]() {
    // Handle first frame
  });

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_view_controller_) {
    flutter_view_controller_ = nullptr;
  }
  Win32Window::OnDestroy();
}

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept {
  if (flutter_view_controller_) {
    std::optional<LRESULT> result = flutter_view_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
    if (result) return *result;
  }
  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
