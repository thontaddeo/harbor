require 'fileutils'

module Harbor

  class File

    attr_accessor :path, :name

    def initialize(path, name = nil)
      @path = path
      @name = name || ::File.basename(@path)
    end

    def close
      @io.close
    end

    def closed?
      @io.closed?
    end

    def read(block_size)
      @io ||= ::File.open(@path, "rb")
      @io.read(block_size)
    end

    def rewind
      @io ||= ::File.open(@path, "rb")
      @io.rewind
    end

    def size
      ::File.size(@path)
    end

    def checksum(algorithm = :pkzip)
      Harbor::File::Checksum.new(:pkzip, self)
    end

    ##
    # The file is first copied, and then the provided block is run.
    # If no errors occur, the source file is deleted. If an error
    # occurs, the copied file is removed and the directory cleaned.
    ##
    def self.move_safely(from, to, mode = 0666 - ::File.umask)
      raise ArgumentError.new("no block given") unless block_given?

      FileUtils.mkdir_p(::File.dirname(to))
      FileUtils.cp(from, to)
      FileUtils.chmod(mode, to)
      begin
        yield
        FileUtils.rm(from)
      rescue
        FileUtils.rm(to)
        rmdir_p(::File.dirname(to))
        raise $!
      end
    end

    ##
    # Recursively delete empty directories as mkdir -p recursively
    # creates directories.
    ##
    def self.rmdir_p(directory)
      `rmdir -p #{Shellwords.escape(directory)} &> /dev/null`
    end

    ##
    # Moves a file and gives it the default file permissions minus the
    # declared umask unless another mode is specified.
    ##
    def self.move(from, to, mode = 0666 - ::File.umask)
      FileUtils.mv(from, to)
      FileUtils.chmod(mode, to)
    end
  end
end