Dir[File.dirname(__FILE__) + "/middleware/*.rb"].each do |f|
  require f
end
