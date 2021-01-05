require 'rails_helper'

RSpec.describe 'when a search is executed' do
  it 'can return results for search_term' do
    search_term = 'thomas'

    get "/api/v1/movies?s=#{search_term}"

    parsed = JSON.parse(response.body)

    expect(response).to be_successful
    expect(response).to have_http_status(200)

    parsed.each do |movie|
      expect(movie['Title'].downcase.include?(search_term)).to be_truthy, "entry does not match search term (#{search_term})"

      # happy path - has required keys
      required_keys = %w[Title Year imdbID Type Poster count details]
      movie.all? do |key, value|
        expect(required_keys.include?(key)).to be_truthy, "this entry is missing one or more required keys (#{required_keys})"
        expect(value.is_a?(String) || value.is_a?(Numeric) || value.is_a?(Hash)).to be_truthy, "this value #{value} is not a string"
      end

      # sad path- test will fail if missing a key
      required_keys = %w[Extra_key]
      movie.all? do |key, value|
        expect(required_keys.include?(key)).to be_falsey
      end
      expect(movie['Year']).to_not be_nil
      expect(Date.strptime(movie['Year'], '%y').gregorian?).to eq(true)
      expect(movie['Year'].to_i.between?(1900, 2999)).to be_truthy
    end
  end

  it 'returns no api key provided without the proper credentials' do
    search_term = 'thomas'

    old_omdb_key = ENV['OMDB_KEY']
    ENV['OMDB_KEY'] = ''

    get "/api/v1/movies?s=#{search_term}"

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    expect(response.headers['content-type']).to eq(('application/json; charset=utf-8')) 
    expect(parsed['Error']).to eq('No API key provided.')
    expect(parsed['Response']).to eq('False')

    # teardown
    ENV['OMDB_KEY'] = old_omdb_key
  end

  it 'can test with api key and i value successful response' do
    random_imdbid_value = 'tt3896198'
    get "/api/v1/movies?i=#{random_imdbid_value}"

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(200)

    expect(response.headers['content-type']).to eq('application/json; charset=utf-8')
    expect(parsed['Response']).to eq('True')
    expect(parsed['Title'].nil?).to be_falsey
  end

  # Sad Path - The api doesn't allow long, short searches.  For example, 't' instead of 'thomas'
  it 'can test search capability with too short keyword' do
    search_term = 't'
    get "/api/v1/movies?s=#{search_term}"

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    expect(parsed['Response']).to eq('False')
    expect(parsed['Error']).to eq('Too many results.')
  end

  it 'can test page one title is valid using i parameter' do
    search_term = 'thomas'
    page_num = 1

    get "/api/v1/movies?s=#{search_term}&page=#{page_num}"
    # request('GET', "?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}", {}, 'http://www.omdbapi.com/')

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    searched_movies = parsed
    searched_movies.each do |movie|
      get "/api/v1/movies?i=#{movie['imdbID']}&apikey=#{ENV['OMDB_KEY']}"

      parsed = JSON.parse(response.body)

      expect(response).to have_http_status(200)
      expect(parsed['Response']).to eq('True')
      expect(parsed['Title'].nil?).to eq(false)
    end
  end

  # sad path - check with an intentionally bad imdbID value
  it 'can test page one title is invalid using invalid i parameter' do
    wrong_imdbid_value = 11111111111
    get "/api/v1/movies?i=#{wrong_imdbid_value}&apikey=#{ENV['OMDB_KEY']}"

    parsed = JSON.parse(response.body)

    expect(response).to have_http_status(200)
    expect(parsed['Response']).to eq('False')
    expect(parsed['Title'].nil?).to eq(true)
  end

  it 'can test all poster links on page one valid' do
    search_term = 'thomas'
    page_num = 1
    get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

    parsed = JSON.parse(response.body)

    expect(response).to have_http_status(200)
    searched_movies = parsed

    searched_movies.each do |movie|
      poster_url = movie['Poster']

      poster_request = Faraday.get(poster_url)

      expect(poster_request.status).to eq(200)
      expect(poster_request.headers['content-type']).to eq('image/jpeg')
    end
  end

  # sad path - check with an intentinally bad url 
  it 'can test reports poster link invalid with bad link' do
    bad_poster_url = 'https://m.media-amazon.com/images/M/link_to_nowhere.jpg'

    poster_request = Faraday.get(bad_poster_url)

    expect(poster_request.status).to eq(404)
  end

  it 'can test no duplicate records within first n pages' do
    search_term = 'thomas'
    page_num = 1
    number_of_pages = 5
    @seen_movie_ids = []

    number_of_pages.times do
      get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

      parsed = JSON.parse(response.body)

      searched_movies = parsed
      searched_movies.each do |movie|
        expect(@seen_movie_ids.include?(movie['imdbID'])).to be_falsey, "There is a duplicate movie with imdbID - #{movie['imdbID']} within page - #{page_num}"
        @seen_movie_ids << movie['imdbID']
      end
      page_num += 1
    end
  end

  # sad path - search contains duplication
  it 'can test no duplicate records found within first n pages' do
    search_term = 'thomas'
    page_num = 1
    number_of_pages = 5
    @seen_movie_ids = []

    number_of_pages.times do
      get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

      parsed = JSON.parse(response.body)
      searched_movies = parsed

      # force duplication in @seen_movie_ids
      searched_movies.each { |movie| @seen_movie_ids << movie['imdbID'] }

      searched_movies.each do |movie|
        expect(@seen_movie_ids.include?(movie['imdbID'])).to be_truthy
        @seen_movie_ids << movie['imdbID']
      end
    end
  end
end
