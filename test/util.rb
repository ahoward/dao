# -*- encoding : utf-8 -*-

class User < Map
  def id() self[:id] end
  def email() self[:email] end

  def User.current
    @current ||= User.new(:id => '42', :email => 'ara.t.howard@gmail.com')
  end
end

module Kernel
private
  def scmp(a, b)
    if b == nil
      puts
      puts a
      puts
      true
    else
      a.to_s.gsub(/\s+/, '') == b.to_s.gsub(/\s+/, '')
    end
  end
  def current_user()
    User.current
  end
end
