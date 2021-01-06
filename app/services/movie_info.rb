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
# "#{@query_params}"
  def get_json
    response = Rails.cache.fetch("#{@query_params}", expires_in: 59.minutes) do
      Faraday.get("http://www.omdbapi.com?#{@query_params}&apikey=#{ENV['OMDB_KEY']}")
    end
    JSON.parse(response.body)
  end

  def add_count_other(raw_json)
    raw_json['Search'].each do |movie|
      find_vote = Vote.find_by(imdb_id: movie['imdbID'])
      find_vote.nil? ? movie['count'] = 0 : movie['count'] = find_vote.count
      @movie_id = movie['imdbID']
      response = Rails.cache.fetch("#{@movie_id}", expires_in: 59.minutes) do
        Faraday.get("http://www.omdbapi.com?i=#{@movie_id}&apikey=#{ENV['OMDB_KEY']}")
      end
      movie['details'] = JSON.parse(response.body)
    end
  end

  def add_details
  end

end