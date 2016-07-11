require "sinatra"
require "sinatra/reloader"
require "sinatra/base"
require "pry"
require "tilt/erubis"

configure do
  enable :sessions
  set :sessions_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  def get_html(details)
    result = []
    result << "<tr> <td>" + details[1].values[0..1].join(" ") + "</td>"
    result << "<td>" + details[1].values[5] + "</td>"
    result << "<td>" + details[1].values[2][0..3] + " **** **** ****" + "</td>"
    result << "<td>" + details[1].values[3] + "</td> </tr>"
    result.join
  end
end

def details_missing?(userhash)
  userhash.any? { |_,v| v.nil? || v.length == 0 }
end

def return_missing_info(userhash) 
  missing_details = userhash.select { |k,v| v.nil? || v.length == 0 }.keys
  result = "Missing field(s): #{missing_details.join(" ").upcase}"
  session[:message] = result
end

def return_card_error(userhash)
  if session[:message]
    session[:message] << ".  Error: Cardnumber must be 16 digits!"
  else session[:message] = "Cardnumber must be 16 digits!"
  end
end

def card_number_valid?(userhash)
  userhash[:cardnumber].length == 16
end

def process_session(userhash)
  if card_number_valid?(userhash) && details_missing?(userhash) == false
    redirect '/success'
  else
    return_missing_info(userhash) if details_missing?(userhash)
    return_card_error(userhash) if card_number_valid?(userhash) == false
    redirect '/'
  end
end

def find_user_token(userhash)
  token = userhash[:lastname] + userhash[:cardnumber][0..3]
  token.to_sym
end

get '/' do
  session[:user] ||= Hash.new
  erb :form
end

get '/success' do
  if !session[:user].empty? # guard clause stops nil return from find_user_token on reload
    token = find_user_token(session[:user])
    session[:success] ||= Hash.new # creates hash on first time run
    session[:success][token] = session[:user]
    session[:user] = Hash.new # clears current user info on success
    erb :success
  else
    erb :success
  end
end
 
post '/payments/create' do
  
  details = {}
  details[:firstname] = params[:firstname]
  details[:lastname] = params[:lastname]
  details[:cardnumber] = params[:cardnumber]
  details[:expiry] = params[:expiry]
  details[:ccv] = params[:ccv]
  details[:time] = Time.now.to_s
  session[:user] = details
  process_session(details)

end
