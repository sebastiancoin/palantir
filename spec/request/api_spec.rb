require 'rails_helper'

RSpec.describe Palantir::API, :type => :request do
  before(:all) do
    token = 'secret'
    ApiKey.create(token: token)

    @headers = {
      'Authorization' => "Token token=#{token}"
    }

    @image = {
      :url => 'test_image_url',
      :phash => 'test_image_phash',
      :directory_name => 'test_directory_name',
      :name => 'test_image_name.jpg'
    }
  end

  def post_request(image = @image, headers = @headers)
    post "/api/images", { :image => image }, headers
  end

  context "POST /api/images" do
    it "returns 200" do
      post_request
      expect(response).to have_http_status(:created)
    end

    it "returns 401 if authorization fails" do
      fake_auth_header = { 'Authorization' => "Token token=FAKE" }
      post_request(@image, fake_auth_header)
      expect(response).to have_http_status(:unauthorized)
    end

    it "creates an image" do
      expect do
        post_request
      end.to change {Image.count}.from(0).to(1)
    end

    it "creates an image with the given url" do
      post_request
      expect(Image.last.url).to eql(@image[:url])
    end

    it "creates an image with the given phash" do
      post_request
      expect(Image.last.phash).to eql(@image[:phash])
    end

    it "creates an image with the given directory name" do
      post_request
      expect(Image.last.directory_name).to eql(@image[:directory_name])
    end

    it "creates an image with the given name" do
      post_request
      expect(Image.last.name).to eql(@image[:name])
    end

    it "creates an event if the hamming distance is greater than the threshold" do
      first_phash  = '1' * (Image::HAMMING_DISTANCE_THRESHOLD + 1)
      second_phash = '2' * (Image::HAMMING_DISTANCE_THRESHOLD + 1)

      @image[:phash] = first_phash
      post_request

      @image[:phash] = second_phash
      expect do
        post_request
      end.to change {Event.count}.from(0).to(1)
    end
  end
end
