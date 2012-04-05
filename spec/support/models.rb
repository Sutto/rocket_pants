require 'reversible_data'
ReversibleData.in_memory!

ReversibleData.add(:users) do |t|
  t.integer :age
end