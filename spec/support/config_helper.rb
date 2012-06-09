module ConfigHelper

  # Temporarily set the value to something new, ensuring we change it back at the end.
  # Note that this isn't in any way thread safe.
  def with_config(name, value)
    original_value = RocketPants.send name
    RocketPants.send "#{name}=", value
    yield if block_given?
  ensure
    RocketPants.send "#{name}=", original_value
  end

  def restoring_env(*keys)
    original = keys.map { |k| ENV[k] }
    yield if block_given?
  ensure
    keys.each_with_index { |k,i | ENV[k] = original[i] }
  end

end