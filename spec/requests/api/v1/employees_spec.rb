# -*- coding: utf-8 -*-
require "spec_helper"

describe "Employees API" do
  let(:api_app) { create(:api_app) }
  let(:user) { create(:user) }

  it "should require authentication" do
    get "/api/v1/employees/123"
    expect(response.status).to eq(401)
    get "/api/v1/employees/#{user.username}"
    expect(response.status).to eq(401)
    get "/api/v1/employees/search"
    expect(response.status).to eq(401)
  end

  it "should have an unauthorized message" do
    get "/api/v1/employees/123"
    json["message"].should match("401 Unauthorized")
  end

  it "should require valid app_token" do
    get "/api/v1/employees/#{user.username}?app_token=x&app_secret=#{api_app.app_secret}"
    response.status.should eq(401)
  end

  it "should require valid app_token" do
    get "/api/v1/employees/#{user.username}?&app_secret=#{api_app.app_secret}"
    expect(response.status).to eq(401)
  end

  it "should require valid app_secret" do
    get "/api/v1/employees/#{user.username}?app_token=#{api_app.app_token}&app_secret=x"
    expect(response.status).to eq(401)
  end

  it "should require valid app_secret" do
    get "/api/v1/employees/#{user.username}?app_token=#{api_app.app_token}"
    expect(response.status).to eq(401)
  end

  it "should require valid ip address" do
    a = ApiApp.create(name: "x", contact: "x", ip_address: "127.0.0.2")
    get "/api/v1/employees/#{user.username}?app_token=#{a.app_token}&app_secret=#{a.app_secret}"
    expect(response.status).to eq(401)
  end

  describe "search response" do
    it "should be a success" do
      get "/api/v1/employees/search?q=#{user.username}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(response).to be_success
    end

    it "should contain one employee" do
      get "/api/v1/employees/search?q=#{user.username}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(1)
    end

    it "should not contain any employee" do
      get "/api/v1/employees/search?q=foo&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(0)
    end

    it "should contain two employees" do
      create(:user, username: "foo-1")
      create(:user, username: "foo-2")
      get "/api/v1/employees/search?q=foo-&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(2)
    end

    it "should not contain any employees" do
      create(:user, username: "foo")
      get "/api/v1/employees/search?q=bar-&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      expect(json.size).to eq(0)
    end

    describe "first matching employee" do
      before(:each) do
        get "/api/v1/employees/search?q=#{user.username}&app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
      end

      it "should have an id" do
        expect(json.first["id"]).to eq(user.id)
      end

      it "should have a first_name" do
        expect(json.first["first_name"]).to eq(user.first_name)
      end

      it "should have an last_name" do
        expect(json.first["last_name"]).to eq(user.last_name)
      end

      it "should have a title" do
        expect(json.first["title"]).to eq(user.title)
      end

      it "should have an email" do
        expect(json.first["email"]).to eq(user.email)
      end

      it "should have a company" do
        expect(json.first["company"]).to eq(user.company)
      end

      it "should have a department " do
        expect(json.first["department"]).to eq(user.department)
      end

      it "should not give away private attributes" do
        %w(
          status_message
          admin
          created_at
          updated_at
          last_login
          status_message_updated_at
          early_adopter
          twitter
          skype
          private_bio
          manager_id
          homepage
          cmg_id
          deactivated
          deactivated_at
        ).each do |attribute|
          expect(json.first[attribute]).to eq(nil)
        end
      end
    end
  end

  describe "response" do
    before(:each) do
      get "/api/v1/employees/#{user.username}?app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
    end

    it "should be a success" do
      expect(response).to be_success
    end

    it "should return employee id" do
      expect(json["id"]).to eq(user.id)
    end

    it "should return employee catalogId" do
      expect(json["catalog_id"]).to eq(user.username)
    end

    it "should return employee firstName" do
      expect(json["first_name"]).to eq(user.first_name)
    end

    it "should return employee catalogId" do
      expect(json["last_name"]).to eq(user.last_name)
    end

    it "should return employee title" do
      expect(json["title"]).to eq(user.title)
    end

    it "should return employee email" do
      expect(json["email"]).to eq(user.email)
    end

    it "should return employee phone" do
      expect(json["phone"]).to eq(user.phone)
    end

    it "should return employee cellPhone" do
      expect(json["cell_phone"]).to eq(user.cell_phone)
    end

    it "should return employee company" do
      expect(json["company"]).to eq(user.company)
    end

    it "should return employee department" do
      expect(json["department"]).to eq(user.department)
    end

    it "should return employee address" do
      expect(json["address"]).to eq(user.address)
    end

    it "should return employee room" do
      expect(json["room"]).to eq(user.room)
    end

    it "should return employee roles array" do
      expect(json["roles"].class).to eq(Array)
    end

    it "should know languages" do
      expect(json["languages"]).to eq(user.languages.map(&:name))
    end

    it "should have skills" do
      expect(json["skills"]).to eq(user.skills.map(&:name))
    end

    it "should not give away private attributes" do
      %w(
        statusMessage
        admin
        last_login
        status_message_updated_at
        early_adopter
        twitter
        skype
        private_bio
        manager_id
        homepage
        cmgId
        deactivated
        deactivated_at
      ).each do |attribute|
        expect(json[attribute]).to eq(nil)
      end
    end
  end

  it "should return response by user id as well" do
    get "/api/v1/employees/#{user.id}?app_token=#{api_app.app_token}&app_secret=#{api_app.app_secret}"
    expect(response).to be_success
    expect(json["id"]).to eq(user.id)
    expect(json["catalog_id"]).to eq(user.username)
    expect(json["first_name"]).to eq(user.first_name)
    expect(json["last_name"]).to eq(user.last_name)
    expect(json["email"]).to eq(user.email)
  end
end
