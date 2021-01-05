require 'rails_helper'

RSpec.describe 'when executing a vote', type: :request do
  it 'can vote up' do
    vote_direction = 1 # thumbs up 

    incoming_imdb_id = 'tt0454349'

    before_vote = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(before_vote).to be_nil

    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"

    after_vote = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(after_vote.count).to eq(1)

    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"
    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"

    after_vote_twice_more = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(after_vote_twice_more.count).to eq(3)
  end

  it 'can vote down' do
    vote_direction = -1 # thumbs down

    incoming_imdb_id = 'tt0454349'
    Vote.create!(imdb_id: incoming_imdb_id, count: 5)

    before_vote = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(before_vote.count).to eq(5)

    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"

    after_vote = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(after_vote.count).to eq(4)

    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"
    post "/api/v1/votes?vote=#{vote_direction}&imdbid=#{incoming_imdb_id}"

    after_vote_twice_more = Vote.find_by(imdb_id: incoming_imdb_id)
    expect(after_vote_twice_more.count).to eq(2)
  end
end
