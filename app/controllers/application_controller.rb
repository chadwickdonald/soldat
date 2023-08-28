class ApplicationController < ActionController::Base
	# testing again
	skip_before_action :verify_authenticity_token
end
