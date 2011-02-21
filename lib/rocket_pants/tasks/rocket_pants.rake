namespace :rocket_pants do

  desc "Generates a pretty listing of errors registered in the application"
  task :errors => :environment do
    errors = RocketPants::Errors.all
    output = [["Error Name", "HTTP Status", "Class Name"]]
    errors.keys.map(&:to_s).sort.each do |key|
      klass = errors[key.to_sym]
      http_status = klass.respond_to?(:http_status) && klass.http_status
      status_code = Rack::Utils.status_code(http_status)
      status_name = http_status.is_a?(Integer) ?  Rack::Utils::HTTP_STATUS_CODES[http_status] : http_status.to_s.titleize
      output << [key, "#{status_code} #{status_name}", klass.name]
    end
    total_width = 8
    0.upto(2) do |column|
      fields = output.map { |i| i[column] }
      length = fields.map(&:length).max + 2
      total_width += length
      fields.each_with_index do |item, idx|
        output[idx][column] = item.ljust(length)
      end
    end
    puts("+#{"-" * total_width}+")
    puts "| #{output[0] * " | "} |"
    puts("+#{"-" * total_width}+")
    output[1..-1].each do |row|
      puts "| #{row * " | "} |"
    end
    puts("+#{"-" * total_width}+")
  end

end