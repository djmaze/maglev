# Maps to Smalltalk class UserException.  See Globals.rb
class Exception
    class_primitive 'allocate', 'rubyBasicNew'
    class_primitive '__signal', 'signal:'
    class_primitive_nobridge '__signal', 'signal'

    class_primitive 'install_debug_block&', 'installDebugBlock:'

    # support for errno to Name translation
    class_primitive_nobridge  '__errno_tables', 'errnoTables'
    class_primitive_nobridge  '__errno_to_name', 'errnoToName:'
    class_primitive_nobridge  '__cpu_os_kind', 'cpuOsKind'

    primitive_nobridge '__handler_active' , '_handlerActive'

    primitive_nobridge '__reraise', '_rubyReraise'
    primitive          '__signal', 'signal:'
    primitive_nobridge '__signal', 'signal'
    primitive          '__description', 'description'
    primitive_nobridge '__message=', 'messageText:'
    primitive_nobridge '__st_initialize', 'initialize'

    def message
      m = @messageText
      if m._equal?(nil)
        m = __description  # generate Smalltalk message
      end
      if m.frozen? 
        # The messages encoded by Smalltalk exceptions are frozen,
        # but ruby allows modifications
        m = m.dup 
      end
      m
    end

    def self.__default_ruby_message
      nil
    end

    def __message_append(str)
      m = @messageText
      if m._equal?(nil)
        m = self.message
        if m._equal?(nil)
          @messageText = str.to_s
          return
        end
      end
      m << str.to_s 
    end

    # Define this in ruby code so we get the full env1 creation hooks
    def self.exception(message=nil)
      self.new(message)
    end

    def self.name
      if self._equal?(Exception)
        'Exception'  # override the smalltalk name UserException
      else
        super
      end
    end

    def self._validate(obj)
      # used in implementation of $! on LHS of assignment
      if (obj._kind_of?(Exception))
        return obj
      else
        raise ArgumentError, 'not an Exception'
      end
    end

    IncludeSmalltalkFrames = false;

    def initialize(message=nil)
      self.__st_initialize  # initialize smalltak instvars
      if message._equal?(nil)
        message = self.class.name
      end
      @messageText = message
    end

    def backtrace(limit = 1000)
      # excludes smalltalk frames from the result
      #  limit defines smalltalk stack depth at which to stop
      @stack || Thread.__backtrace(IncludeSmalltalkFrames, limit)
    end

    def backtrace_st(limit = 1000)
      # include smalltalk frames in the result
      #  limit defines smalltalk stack depth at which to stop
      Thread.__backtrace(true, limit)
    end

    def exception(message = Undefined)
      if message._equal?(self) || message._equal?(Undefined)
        return self
      end
      e = dup
      e.__message=(message)
      e
    end

    def inspect
      str = '#<'
      str << self.class.name
      str << ': '
      str << message
      str << '>'
      str
    end

    def set_backtrace(array)
      @stack = array
    end

    def to_s
      (m = message)._equal?(nil) ? self.class.name : m
    end

    def to_str
      (m = message)._equal?(nil) ? self.class.name : m
    end
end

# open each of the subclasses of Exception that map to
#   a Smalltalk class to initialize the ruby name space
#  order here matches order in  Exception(C)>>commentRubyMapping

class SystemExit
  # Smalltalk reimplements initialize
  primitive_nobridge '__st_initialize', 'initialize'

  def status
    @status
  end

  def initialize(*args)
    status = if args.first._isFixnum
               args.shift
             else
               0
             end
    super(*args)
    @status = status
  end
end

class SystemStackError
  # stack overflow error
end
class NoMemoryError
   # Smalltalk reimplements initialize
   primitive_nobridge '__st_initialize', 'initialize'
end
class ScriptError
   # Smalltalk reimplements initialize
   primitive_nobridge '__st_initialize', 'initialize'
end
class LoadError  # a subclass of ScriptError
end
class NotImplementedError  # a subclass of ScriptError
end
class SyntaxError  # a subclass of ScriptError
end
class StandardError
end
class ArgumentError
end
class IOError
end
class EOFError  # a subclass of IOError
end
class SocketError  # a subclass of IOError
end
class IndexError
end
class LocalJumpError
end
class RuntimeError
end
class RangeError
end
class FloatDomainError # a subclass of RangeError
end
class RegexpError
end
class SecurityError
end
class SystemCallError
  def self.new(*args)
    if args.length < 1
      raise ArgumentError, 'too few args'
    end
    argone = args[0]
    argtwo = nil
    errnum = nil
    if argone._isFixnum
      errnum = argone
      msg = nil
    elsif argone._isString
      msg = argone
      if args.length >= 2 
        argtwo = args[1]
        if argtwo._isFixnum
          errnum = argtwo
        end
      end  
    end
    if errnum._not_equal?(nil)
      exc = Errno.__new_for_errno(errnum)
    end
    if exc._equal?(nil)
      exc = self.allocate
      exc.errno=(errnum)
    end
    if msg._equal?(nil)
      exc.__message=('Unknown error')
    else
      exc.__message=(msg)
    end
    exc
  end
  def errno=(errnum)
    @gsarguments = [ errnum ]
  end
  def errno
    gsa = @gsarguments
    if gsa._equal?(nil)
      nil
    else
      gsa[0]
    end
  end
end
class ThreadError
end
class TypeError
end
class ZeroDivisionError
end

class NameError
   # Smalltalk reimplements initialize
   primitive_nobridge '__st_initialize', 'initialize'

   def self.new(msg=nil, name=nil)
     exc = super(msg)
     if name._not_equal?(nil)
       exc.name=(name)
     end
     exc
   end
   primitive_nobridge 'name=' , 'name:'
   primitive_nobridge 'name', 'name'

   def inspect
     str = super
     n = self.name
     if n._not_equal?(nil)
       str << ', '
       str << n.to_s
     end
     str
   end
end

class NoMethodError  # a subclass of NameError
   # Smalltalk reimplements initialize
   primitive_nobridge '__st_initialize', 'initialize'

   def __init(selector, args_arr, envid)
     gsa = @gsarguments
     if selector._isSymbol
       gsa[1] = selector
     end
     if args_arr._isArray
       gsa[2] = args_arr
     end
     if envid._isFixnum
       gsa[3] = envid
     end
     self
   end

   def selector
     @gsarguments[1]
   end
   def envid
     @gsarguments[3]
   end
   def args
     a = @gsarguments[2]
     if a._equal?(nil)
       a = []
     end
     a
   end

   def inspect
     str = super
     str << "`" ; str << self.selector.to_s ; str << "' called"
     str
   end

end
class SignalException
end
class Interrupt  # a subclass of SignalException
end

# This was in lib/ruby/1.8/timeout.rb, but class_primitive_nobridge is not
# allowed after boot, so the exception definition was moved here.
#
# class RubyTimeoutError  is defined in the maglev*.mcz
#   RubyTimeoutError deprecated , just use  lib/ruby/1.8/timeout.rb
# RUBY.global("TimeoutError", "RubyTimeoutError")
# class TimeoutError
#  class_primitive_nobridge 'timeout', 'timeout:do:'
# end
