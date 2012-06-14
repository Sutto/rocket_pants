require 'reversible_data'
ReversibleData.in_memory!

ReversibleData.add(:users) do |t|
  t.integer :age
end

fish = ReversibleData.add(:fish) do |t|
  t.string  :name
  t.string  :latin_name
  t.integer :child_number
  t.string  :token
end

fish.define_model do
  validates :name, :child_number, :presence => true
  # Yes, I know it's technically not right.
  validates :latin_name, :length => {:minimum => 5}, :format => /\A(\w+) (\w+)\Z/
  validates :child_number, :numericality => true
  # validates :token, :uniqueness => true, :allow_nil => true
end
