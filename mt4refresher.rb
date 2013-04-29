require 'ffi'

module Win
  extend FFI::Library

  ffi_lib 'user32'
  ffi_convention :stdcall

  # BOOL CALLBACK EnumWindowProc(HWND hwnd, LPARAM lParam)
  callback :enum_callback, [ :pointer, :long ], :bool

  # BOOL WINAPI EnumDesktopWindows(HDESK hDesktop, WNDENUMPROC lpfn, LPARAM lParam)
  attach_function :enum_desktop_windows, :EnumDesktopWindows,
                  [ :pointer, :enum_callback, :long ], :bool

  # int GetWindowTextA(HWND hWnd, LPTSTR lpString, int nMaxCount)
  attach_function :get_window_text, :GetWindowTextA,
                  [ :pointer, :pointer, :int ], :int

  attach_function :class_name, :GetClassNameA,
                         [:pointer, :pointer, :int], :int                        

  attach_function :post_message, :PostMessageA,
                  [:pointer , :uint, :uint , :uint ], :bool

end

SEARCH_TITLE = "MetaQuotes::MetaTrader::4.00"

terminals = []

title = FFI::MemoryPointer.new :char, 512
class_title = FFI::MemoryPointer.new :char, 100

Win::EnumWindowCallback = Proc.new do |wnd, param|
  
  class_title.clear

  Win.class_name(wnd, class_title, 99)

  if SEARCH_TITLE  == class_title.read_string

      terminal = {}
      title.clear

      terminal[:title] = Win.get_window_text(wnd, title, title.size)
      terminal[:msg] = Win.post_message(wnd,0x0000C056, 0x0000303D, 0x0000C1D9)

      terminals << terminal
  end

  true
end

unless Win.enum_desktop_windows(nil, Win::EnumWindowCallback, 0)
  puts 'Unable to enumerate current desktop\'s top-level windows'
else
  msgCount = terminals.select {|e| e[:msg]}.count
  puts "Refreshed #{msgCount}/#{terminals.count} terminals"
end