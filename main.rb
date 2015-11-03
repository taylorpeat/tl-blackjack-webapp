require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '98h2jowbvu05jd3'

get '/inline' do
  "Hi, directly from the action!"
end

get '/template' do
  erb :mytemplate
end

get "/template2" do
  erb :"users/user_template"
end