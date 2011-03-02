require 'zlib'

#Implements the Mud Client Compression Protocol. Sort of.
class MCCP

  def initialize
    @step = "start"
  end

  def step(string)

  end

  def MCCP.decompress(string)
    Zlib::Inflate.inflate(string)
  end

  def MCCP.compress(string)
    Zlib::Deflate.deflate(string)
  end
end
