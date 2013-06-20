# -*- coding: utf-8 -*-
require 'spec_helper'

if APP_CONFIG["auth_method"] == "ldap"
  describe "LDAP authentication" do
    it "should require login for the dashboard" do
      visit root_path
      current_path.should eq(login_path)
      page.should have_selector('h1', text: "Logga in")
      page.should have_field("password")
    end

    it "should require login for profile page" do
      user = create(:user)
      visit user_path(user.username)
      current_path.should eq(login_path)
      page.should have_selector('h1', text: "Logga in")
    end

    it "should require login for an admin page" do
      visit roles_path
      current_path.should eq(login_path)
      page.should have_selector('h1', text: "Logga in")
    end

    it "should not sign in a user with incorrect credentials" do
      visit login_path
      fill_in 'username', with: 'Fox'
      fill_in 'password', with: 'barx'
      click_button 'Logga in'
      current_path.should eq(login_path)
      page.should have_selector('.warning', text: 'Fel användarnamn eller lösenord')
    end

    it "should not sign in a user without credentials" do
      visit login_path
      fill_in 'username', with: ''
      fill_in 'password', with: ''
      click_button 'Logga in'
      current_path.should eq(login_path)
      page.should have_selector('.warning', text: 'Fel användarnamn eller lösenord')
    end

    it "should sign in a user with correct credentials" do
      create_ldap_userlogin
      current_path.should eq(root_path)
      page.should have_selector('h1', text: "Mina Kominnyheter")
    end

    it "should require admin role" do
      user = create_named_user
      visit login_path
      fill_in 'username', with: user.username
      fill_in 'password', with: AUTH_CREDENTIALS["password"]
      click_button 'Logga in'
      visit feeds_path
      page.should have_selector('.error', text: "Du saknar behörighet")
    end

    it "should honor admin role" do
      user = create_named_user
      user.update_attribute(:admin, true)
      login(user.username, AUTH_CREDENTIALS["password"])
      visit feeds_path
      page.should have_selector('h1', text: "Nyhetsflöden")
    end
  end
end
