require_relative '../../server.rb'
require 'pry'
require 'pg'
require 'sinatra'

class Article

  attr_reader :title, :url, :description, :errors

  def initialize(article = {})
    @article = article
    @title = article["title"]
    @url = article["url"]
    @description = article["description"]
    @errors = []
  end



  def self.all
    @articles = []
    articles = db_connection { |conn| conn.exec("SELECT title, url, description FROM articles") }
    articles.to_a.each do |article| #WHAT DOES .to_a do?
      @articles << Article.new(article)
    end
    @articles
  end

  def save
    if valid?
      db_connection do |conn|
        conn.exec_params(
          "INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)",
          [@title, @url, @description]
        )
        return true
      end
	   else
	    return false
    end
  end



  def valid?
    valid = true
    if @title == "" && @url == "" && description == ""
      @errors << "Please completely fill out form"
      valid = false
    elsif @title = "" && !@url.include?("https://") && @description.size < 20
      @errors << "Please completely fill out form"
      @errors << "Invalid URL"
      @errors << "Description must be at least 20 characters long"
      valid = false
    elsif !@url.include?("https://")
      @errors << "Invalid URL"
      valid = false
    elsif @description.size < 20
      @errors << "Description must be at least 20 characters long"
      valid = false
    elsif
      Article.all.each do |article|
        if @url == article.url
          @errors << "Article with same url already submitted"
          valid = false
        end
      end
    end
    valid
  end

end
