module ConfigHelper

  # Temporarily set the value to something new, ensuring we change it back at the end.
  # Note that this isn't in any way thread safe.
  def with_config(name, value)
    original_value = RocketPants.send name
    RocketPants.send "#{name}=", value
  ensure
    RocketPants.send "#{name}=", original_value
  end

end