module LslTools
	using Printf

	function sync_to_continuous!(streams,name_main="EEGstream")
		
	stream_main = get_stream(streams,name_main)
	
	stream_main["type"] == "EEG" || @error("name_main stream is not an EEG stream")
		
	# fix effective samplingrate to EEG sampling rate
	n_samples = size(stream_main["data"],1)
	duration = diff(stream_main["time"][[1,end]])[1]
	srate_eff = n_samples/duration
	factor = srate_eff/stream_main["srate"]
	@info @sprintf("changing effective sampling rate from %.2f to %.2f",stream_main["srate"],srate_eff)
	for k = values(streams)
		k["time"] = k["time"] .* factor
	end
		return streams

	end
	# returns stream with "name", if multiple are found raises error
	function get_stream(streams,name)
		keylist = collect(keys(streams))
		ix = find_stream(streams,name)
		length(ix)==1 || @error("same name found multiple times")
		return streams[keylist[ix[1]]]
	end

	# returns list of index of streams with "name"
	function find_stream(streams,name)
			keylist = collect(keys(streams))

			streamNames = [streams[s]["name"] for s in keylist]
			name_ix =  findall(occursin.(name,streamNames))
		
	end

	
	dejitter!(streams,name_main,name_secondary::String) = dejitter!(streams,name_main,[name_secondary])

	# dejitter stream name_main & list of secondary streams according to the main stream
	function dejitter!(streams,name_main,name_secondary::AbstractVector=[])
		
		stream_main 	 = get_stream(streams,name_main)
		stream_secondary = get_stream.(Ref(streams),name_secondary)
		
		nsamp = length(stream_main["time"])
		coef = [ones(nsamp) 1:nsamp] \ stream_main["time"]

		stream_main["time"] = coef[1] .+ coef[2] .* stream_main["time"]
		for k = stream_secondary
			k["time"] = coef[1] .+ coef[2] .* k["time"]
		end
		return streams
	end
end
