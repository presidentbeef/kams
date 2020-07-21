#Include this in items to make them automatically be deleted after a specified time.
module Expires
  def initialize *args
    super
  end

  def run
    super
    if info.expiration_time and Time.now.to_i > info.expiration_time
      expire
    end
  end

  def expire_in seconds
    info.expiration_time = (Time.now + seconds).to_i
  end

  private

  def expire
    add_event Event.new(:Mobiles, :action => :expire, :player => self)
  end
end
