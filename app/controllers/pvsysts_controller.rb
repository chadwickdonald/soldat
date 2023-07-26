class PvsystsController < ApplicationController
	def index
		@pvsysts = Pvsyst.all
	end

	def new_import
	end

	def import
		begin
			file = params[:file]
			PvsystImportJob.new(file).perform
			flash[:success] = "<strong>Pvsyst imported</strong>"
			redirect_to pvsyts_path
		rescue => exception
			flash[:error] = "There was a problem importing Pvsyst file.<br>
				<strong>#{exception.message}</strong><br>"
			redirect_to root_path
		end
	end
end