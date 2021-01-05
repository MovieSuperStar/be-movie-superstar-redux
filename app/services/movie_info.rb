class MovieInfo

  def initialize(incoming)
    @query_params = incoming.to_query
  end

  def get_search_results
    json_response = get_json
    if json_response['Search'].nil?
      get_json
    else
      add_count_other(get_json)
    end
  end

  private

  def get_json
    Rails.cache.fetch(@query_params, :expires => 1.hour) do
      response = Faraday.get("http://www.omdbapi.com?#{@query_params}&apikey=#{ENV['OMDB_KEY']}")
      JSON.parse(response.body)
    end
  end

  def add_count_other(raw_json)
    raw_json['Search'].each do |movie|
      find_vote = Vote.find_by(imdb_id: movie['imdbID'])
      find_vote.nil? ? movie['count'] = 0 : movie['count'] = find_vote.count
      movie_id = movie['imdbID']
      response = Faraday.get("http://www.omdbapi.com?i=#{movie_id}&apikey=#{ENV['OMDB_KEY']}")
      movie['details'] = JSON.parse(response.body)
    end
  end

  def add_details
  end

end