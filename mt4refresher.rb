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

terminals = 0

title = FFI::MemoryPointer.new :char, 512
class_title = FFI::MemoryPointer.new :char, 100

Win::EnumWindowCallback = Proc.new do |wnd, param|
  
  class_title.clear

  Win.class_name(wnd, class_title, 99)

  if SEARCH_TITLE  == class_title.read_string

      title.clear
      
      (49408..49919).each do |lparam|
          Win.post_message(wnd , 0x0000C106 , 0x0000303D, lparam)
      end

      terminals +=1
  end

  true
end

unless Win.enum_desktop_windows(nil, Win::EnumWindowCallback, 0)
  puts 'Unable to enumerate current desktop\'s top-level windows'
else
  puts "Refreshed #{terminals} terminals"
end