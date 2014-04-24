class MainController < ApplicationController
	skip_before_filter :verify_authenticity_token, :only => [:webhook]

	def index
		@elements = DsElement.all.order(:fullpath)
		respond_to do |format|
			# Respond with success per Datasift documentation
			format.html {}
		end
	end

	# Plain text output
	def plain
		@elements = DsElement.all.order(:fullpath)
		respond_to do |format|
			# Respond with success per Datasift documentation
			format.html {
				output = []
				@elements.each do |e|
					output << "#{e.fullpath.gsub(/\.$/,'')} - #{e.sample_value}"
				end
				render :text => output.join("<br>")
			}
		end
	end

	# CSV output
	def csv
		@elements = DsElement.all.order(:fullpath)
		respond_to do |format|
			# Respond with success per Datasift documentation
			format.csv {
				output = ["fullpath,sample_value,first_seen,last_seen"]
				@elements.each do |e|
					output << "#{e.fullpath.gsub(/\.$/,'')},#{e.sample_value},#{e.created_at},#{e.updated_at}"
				end
				response.headers['Content-Type'] = 'text/csv'
			    response.headers['Content-Disposition'] = 'attachment; filename=sieve_export.csv'    
				render :text => output.join("\n")
			}
		end
	end

	# JSON output
	def json
		@elements = DsElement.all.order(:fullpath).pluck("fullpath").uniq
		# Respond with success per Datasift documentation
		output = Hash["elements" => []]
		@elements.each do |e|
			allsamples = DsElement.where(:fullpath => e).order(:sample_value).pluck("sample_value")
			thise = Hash["path" => e.fullpath.split(".")[0], "sample_values" => allsamples]
			output["elements"] << thise
		end
		render :json => output.to_json
	end

	def webhook
		lookingfor = ["interaction.source","blog.domain","board.domain","lexusnexis.source.name","newscred.source.name"]
		#if params[:token] == ENV['SIMPLE_TOKEN']
			if params[:interactions]
				params[:interactions].each do |iac|
					output = flatten_with_path(iac)
					#puts output.to_yaml
					output.each do |i, v|
						puts "#{i} : #{v} (#{get_datatype(v)})"
						if lookingfor.include?i
							target = i
							#target = i.gsub(".0",".").gsub("..",".")
							elem = DsElement.find_or_create_by(fullpath: target, samplevalue: v)
							if elem.changed?
								elem.save
							else
								elem.touch
							end
						end
					end
				end
			end
		#end
		respond_to do |format|
			# Respond with success per Datasift documentation
			format.json{
				render :json => Hash["success" => true].to_json
			}
		end
	end
end
