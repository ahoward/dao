class User < Map
  def id() self[:id] end
  def email() self[:email] end

  def User.current
    @current ||= User.new(:id => '42', :email => 'ara.t.howard@gmail.com')
  end
end

module Kernel
private
  def current_user()
    User.current
  end
end
