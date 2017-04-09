require "sinatra"
require "pg"
require_relative "./app/models/article"
require 'pry'

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end


get "/" do
  redirect '/articles'
end

get "/articles/new" do
 erb :new
end

get "/articles" do
# @error_message = "Article with same url already submitted"

@articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles ORDER BY title") }

erb :index

end

post "/articles/new"  do

   if params['title'] == "" && !params['url'].include?("https://") && params['description'].size < 20
     @error_message = "Please completely fill out form"
     @error_message1 = "Invalid URL"
     @error_message2 = "Description must be at least 20 characters long"
     erb :new
   elsif params['url'] == "" && params['description'] == ""
     @title = params['title']
     @error_message = "Please completely fill out form"
     erb :new
   elsif !params['url'].include?("https://")
     @error_message = "WARNING: Invalid URL"
     @title = params['title']
     @description = params['description']
     erb :new
   elsif params['description'].size < 20
     @title = params['title']
     @url = params['url']
     @error_message = "Description must be at least 20 characters long"
     erb :new
   else
    articles = db_connection { |conn| conn.exec("SELECT url FROM articles") }

    article_array = articles.to_a.map { |article| article['url'] }
    if article_array.include?(params['url'])
      @articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
      @error_message = "Article with same url already submitted"
      erb :index
    else
      title = params['title']
      url = params['url']
      description = params['description']

      db_connection do |conn|
        conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, url, description])
      end
      redirect '/articles'
    end
   end

end
