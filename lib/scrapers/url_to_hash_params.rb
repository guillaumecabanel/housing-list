require "uri"
require "rack"

def deep_convert(element)
  return element.collect { |e| deep_convert(e) } if element.is_a?(Array)
  return element.inject({}) { |sh,(k,v)| sh[k.to_sym] = deep_convert(v); sh } if element.is_a?(Hash)
  element
end

# Useful when we'll need to check if the booking reservation url matches stuff we know about the trip
url = "https://secure.booking.com/book.html?from_source=hotel&hotel_id=1070854&aid=304142&label=gen173nr-1FCAEoggJCAlhYSDNiBW5vcmVmaE2IAQGYATG4AQfIAQzYAQHoAQH4AQKSAgF5qAID&sid=0dcdfab44b9cce7749eaf5e3c6ec1d87&room1=A%2CA&error_url=%2Fhotel%2Fjp%2Fflexstayshirogane.html%3Faid%3D304142%3Blabel%3Dgen173nr-1FCAEoggJCAlhYSDNiBW5vcmVmaE2IAQGYATG4AQfIAQzYAQHoAQH4AQKSAgF5qAID%3Bsid%3D0dcdfab44b9cce7749eaf5e3c6ec1d87%3B&hostname=www.booking.com&stage=1&checkin=2017-12-06&interval=23&children_extrabeds=&nr_rooms_107085403_101645391_0_0_0=1&rt_pos_selected=1"
uri = URI.parse(url)

url_hash = uri.instance_variables.reduce({}) do |uri_data, ivar|
  key = ivar.to_s.tr("@", "").to_sym

  if key == :query
    query_string  = uri.query
    query_hash    = Rack::Utils.parse_query(query_string)
    query_hash_with_symbols = deep_convert(query_hash)
    uri_data[key] = query_hash_with_symbols
  else
    uri_data[key] = uri.instance_variable_get(ivar)
  end
  uri_data
end

p url_hash
