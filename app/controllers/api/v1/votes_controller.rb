class Api::V1::VotesController < ApplicationController
  def update
    this_vote = Vote.find_by(imdb_id: vote_params[:imdbid])
    if this_vote.nil?
      Vote.create!(imdb_id: vote_params[:imdbid], count: vote_params[:vote])
    else
      this_vote.count = this_vote.count + vote_params[:vote].to_i
      this_vote.save!
    end
  end

  def index 
    #not implemented on the FrontEnd yet
    # this_vote = Vote.find_by(imdb_id: vote_params[:imdbid])
    # render json: this_vote.count
  end

  private 

  def vote_params
    params.permit(:vote, :imdbid)
  end
end
