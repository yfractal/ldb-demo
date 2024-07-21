class User < ApplicationRecord
  has_many :books

  def write_redis
    Rails.cache.write("user-#{self.id}", self.to_json * 1000)
  end

  def read_redis
    Rails.cache.read("user-#{self.id}")
  end
end
