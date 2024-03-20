# typed: false
# frozen_string_literal: true

require 'test_helper'

class HelloCodespacesControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get '/'
    assert_response :success
  end
end
