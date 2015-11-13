require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '98h2jowbvu05jd3'

helpers do
  SUITS = [:S, :C, :D, :H]
  VALUES = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

  def create_deck
    SUITS.product(VALUES).shuffle!
  end

  def deal_cards
    2.times do
      session[:player_cards] << session[:deck].pop
      session[:dealer_cards] << session[:deck].pop
    end
  end

  def calculate_total(cards)
    cards = hide_dealer_card(cards)
    total = 0
    cards.each do |card|
      total += card[1].to_i
      total += 10 if card[1].to_i == 0
      total += 1 if card[1] == 'A'
    end
    total = correct_for_aces(cards, total)
  end

  def hide_dealer_card(cards)
    if cards == session[:dealer_cards] && !session[:show_dealer_card]
      cards = [cards[0]]
    end
    cards
  end

  def correct_for_aces(cards, total)
    cards.each do |card|
      if card[1] == 'A' && total > 21
        total -= 10
      end
    end
    total
  end


  def card_image(card, idx, hand_size)
    suit = determine_suit(card[0])
    value = determine_card_value(card[1])
    card_class = determine_card_class(idx, hand_size)
    
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='#{card_class}'>"
  end

  def determine_suit(suit)
    case suit
    when :S then "spades"
    when :C then "clubs"
    when :D then "diamonds"
    when :H then "hearts"
    end
  end

  def determine_card_value(value)
    if ['J', 'Q', 'K', 'A'].include?(value)
      new_value = case value
      when 'J' then "jack"
      when 'Q' then "queen"
      when 'K' then "king"
      when 'A' then "ace"
      end
    end
    new_value ||= value
  end

  def determine_card_class(idx, hand_size)
    if hand_size == idx + 1 || idx == 0
      "end_card"
    else
      "middle_card"
    end
  end

  def determine_results
    player_total = calculate_total(session[:player_cards])
    dealer_total = calculate_total(session[:dealer_cards])
    player_name = session[:player_name]
    result = "<div class='alert alert-"
    if player_total > 21
      result += "error'>Sorry #{player_name}. You busted."
      session[:balance] -= session[:bet]
    elsif dealer_total > 21
      result += "success'>Congratulations #{player_name}. The dealer busted. You win!"
      session[:balance] += session[:bet]
    elsif player_total == dealer_total
      result += "warning'>It's a tie. Both #{player_name} and the dealer have #{player_total}."
    elsif player_total < dealer_total
      result += "error'>Sorry #{player_name}. You lost to the dealer #{dealer_total} to #{player_total}."
      session[:balance] -= session[:bet]
    elsif player_total > dealer_total
      result += "success'>Congratulations #{player_name}. You beat the dealer #{player_total} to #{dealer_total}!"
      session[:balance] += session[:bet]
    end
    result + "</br>Your new balance is $#{session[:balance]}.</div>"
  end
end


get '/' do
  session.clear
  redirect '/username'
end

get '/username' do
  if session[:player_name]
    redirect '/bet'
  else
    erb :username
  end
end

post '/username' do
  if params[:player_name].empty?
    @error = "Please enter a valid name."
    halt erb :username
  end
  session[:player_name] = params[:player_name]
  session[:balance] = 500
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  if params[:bet].to_i > session[:balance] || params[:bet].to_i <= 0
    @error = "Please enter a valid wager between $1 and $#{session[:balance]}."
    halt erb :bet
  end
  session[:bet] = params[:bet].to_i
  redirect '/game'
end

get '/game' do
  if session['player_name']
    session[:stand] = false
    session[:dealer_turn] = false
    session[:show_dealer_card] = false
    session[:deck] = create_deck
    session[:player_cards] = []
    session[:dealer_cards] = []
    if session[:bet].to_i > session[:balance].to_i
      session[:bet] = session[:balance]
    end
    deal_cards
    if calculate_total(session[:player_cards]) == 21
      session[:stand] = true
      session[:show_dealer_card] = true
      session[:dealer_turn] = true
    end
    erb :game
  else
    redirect '/username'
  end
end

post '/game/player/hit' do
  @slide = true
  erb :game
  @slide = false
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) >= 21
    session[:stand] = true
    session[:dealer_turn] = false
    if calculate_total(session[:player_cards]) == 21
      session[:show_dealer_card] = true
      session[:dealer_turn] = true
    end
  end
  redirect '/game/update'
end

get '/game/update' do
  erb :game, :layout => false
end
  

post '/game/player/stand' do
  session[:stand] = true
  session[:dealer_turn] = true
  session[:show_dealer_card] = true
  redirect '/game/update'
end

# get '/game/dealer' do
#   erb :game, :layout => false
# end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  if calculate_total(session[:dealer_cards]) < 17
    session[:dealer_turn] = true
  else
    session[:dealer_turn] = false
  end
  redirect '/game/update'
end

# get '/game/dealer/hit' do
#   erb :game, :layout => false
# end

get '/quit' do
  @balance = session[:balance]
  @player_name = session[:player_name]
  session.clear
  erb :quit
end
