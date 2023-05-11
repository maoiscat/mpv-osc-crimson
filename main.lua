-- mpv-osc-simple
-- by maoiscat
-- github/maoiscat/mpv-osc-crimson

require 'elements'
local assdraw = require 'mp.assdraw'
local utils = require 'mp.utils'

mp.commandv('set', 'osc', 'no')

-- user options
opts = {
	scale = 1,              -- osc render scale
	fixedHeight = false,	-- true to allow osc scale with window
	hideTimeout = 1,		-- seconds untile osc hides, negative means never
	fadeDuration = 0.5,	    -- seconds during fade out, negative means never
	border = 1,				-- border width
	size = 26,				-- button size
	remainingTime = false,	-- true to display remaining time instead of duration in the seekbar
	maxVolume = 130,		-- maximum volume allowed by the volume slider
	}
	
mp.commandv('set', 'keepaspect', 'yes')
mp.commandv('set', 'border', 'no')
mp.commandv('set', 'keepaspect-window', 'no')
setVisibility('always')

-- left, top, right, bottom, unit size
local margins = {
	l = opts.border,
	t = opts.border,
	r = opts.border,
	b = opts.border*3+opts.size*2}

-- styles
styles = {
	tooltip = {
		color = {'FFFFFF', '0', '0', '0'},
		border = 1,
		fontsize = 16,
		wrap = 2,
		},
	border = {
		color = {'0f0f06', '0', '0', '0'},
		},
	invisible = {
		alpha = {255, 255, 255, 255}
		},
	button = {
		color = {'2e2c2a', '0', '0f0f06', '0'},
		border = opts.border,
		},
	button2 = {
		color = {'99', '0', '0f0f06', '0'},
		border = opts.border,
		},
	button3 = {	-- for slider fg
		color = {'99', '0', '0f0f06', '0'},
		},
	icon = {
		color = {'FFFFFF', '0', '0', '0'},
		font = 'material-design-iconic-font',
		fontsize = 20,
		},
	icon2 = {
		color = {'a0a0a0', '0', '0', '0'},
		font = 'material-design-iconic-font',
		fontsize = 20,
		},
	text = {
		color = {'FFFFFF', '0', '0', '0'},
		fontsize = 14,
		},
	text2 = {
		color = {'a0a0a0', '0', '0', '0'},
		fontsize = 14,
		wrap = 2,
		},
	}

-- logo
local ne
ne = addToIdleLayout('logo')
ne:init()

-- message
local msg = addToIdleLayout('message')
msg:init()

-- an enviromental variable updater
ne = newElement('updater')
ne.layer = 1000
ne.visible = false
ne.init = function(self)
		-- opts backup
		player.userScale = opts.scale
		-- event generators
		mp.observe_property('track-list/count', 'native', 
			function(name, val)
				if val==0 then return end
				player.tracks = getTrackList()
				player.playlist = getPlaylist()
				player.chapters = getChapterList()
				player.playlistPos = getPlaylistPos()
				player.duration = mp.get_property_number('duration')
				dispatchEvent('file-loaded')
			end)
		mp.observe_property('pause', 'bool',
			function(name, val)
				player.paused = val
				dispatchEvent('pause')
			end)
		mp.observe_property('fullscreen', 'bool',
			function(name, val)
				player.fullscreen = val
				dispatchEvent('fullscreen')
			end)
		mp.observe_property('current-tracks/video/id', 'number',
			function(name, val)
				if val then player.videoTrack = val
					else player.videoTrack = 0
						end
				dispatchEvent('video-changed')
			end)
		mp.observe_property('current-tracks/audio/id', 'number',
			function(name, val)
				if val then player.audioTrack = val
					else player.audioTrack = 0
						end
				dispatchEvent('audio-changed')
			end)
		mp.observe_property('current-tracks/sub/id', 'number',
			function(name, val)
				if val then player.subTrack = val
					else player.subTrack = 0
						end
				dispatchEvent('sub-changed')
			end)
		mp.observe_property('loop-playlist', 'string',
			function(name, val)
				player.loopPlaylist = val
				dispatchEvent('loop-playlist')
			end)
		mp.observe_property('volume', 'number',
			function(name, val)
				player.volume = val
				dispatchEvent('volume')
			end)
		mp.observe_property('mute', 'bool',
			function(name, val)
				player.muted = val
				dispatchEvent('mute')
			end)
	end
ne.tick = function(self)
		player.percentPos = mp.get_property_number('percent-pos')
		player.timePos = mp.get_property_number('time-pos')
		player.timeRem = mp.get_property_number('time-remaining')
		dispatchEvent('time')
		return ''
	end
ne.setMargin = function(self, mr)
		mp.commandv('set', 'video-margin-ratio-left', mr.l)
		mp.commandv('set', 'video-margin-ratio-top', mr.t)
		mp.commandv('set', 'video-margin-ratio-right', mr.r)
		mp.commandv('set', 'video-margin-ratio-bottom', mr.b)
		mp.set_property_native("user-data/osc/margins", mr)
	end
ne.responder['resize'] = function(self)
		local mr = {l = 0, r = 0, t = 0, b = 0}
		if player.fullscreen then
			setVisibility('normal')
		else
			mr = {
				l = margins.l / player.geo.width,
				r = margins.r / player.geo.width,
				t = margins.t / player.geo.height,
				b = margins.b / player.geo.height,
				}
			setVisibility('always')
		end
		self:setMargin(mr)
		player.geo.refW1 = player.geo.width - opts.size*4 - opts.border*6
		player.geo.refW2 = player.geo.width - opts.size*3 - opts.border*5
		player.geo.refY = player.geo.height - margins.b
		player.geo.refY1 = player.geo.refY + opts.border + opts.size/2
		player.geo.refY2 = player.geo.refY1 + opts.border + opts.size
		setIdleActiveArea('area1', 0, player.geo.refY, player.geo.width, player.geo.height)
		setPlayActiveArea('area2', 0, player.geo.refY, player.geo.width, player.geo.height)
		setPlayActiveArea('area3', 0, player.geo.height*0.67, player.geo.width, player.geo.height, 'show_hide')
		return false
	end
ne.responder['fullscreen'] = ne.responder['resize']
ne:init()
local updater = ne
addToPlayLayout('updater')

-- a shared tooltip
ne = newElement('tip', 'tooltip')
ne.layer = 50
ne.style = clone(styles.tooltip)
ne:init()
addToPlayLayout('tip')
local tooltip = ne

-- outline
ne = newElement('outline')
ne.layer = 1
ne.style = styles.border
ne.render = function(self)
		local ass = assdraw.ass_new()
		ass:draw_start()
		ass:rect_cw(0, 0, player.geo.width, player.geo.height)
		ass:rect_ccw(opts.border, opts.border, player.geo.width-opts.border, player.geo.height-opts.border)
		ass:draw_stop()
		self.pack[4] = ass.text
	end
ne.responder['resize'] = ne.render
ne:init()
addToIdleLayout('outline')
addToPlayLayout('outline')

-- to automatically calculate button position from left border
-- set button x position considering geo.w and geo.an
local stackX = 0
local function stackIn(geo)
	local x1 = stackX + opts.border
	local x2 = x1 + geo.w/2
	local x3 = x1 + geo.w
	local x = {
		[0] = stackX + opts.border + geo.w,
		x1 + geo.w,
		stackX + opts.border + geo.w/2
		}
	stackX = x[0]
	return x[geo.an%3]
end

-- play button
ne = newElement('btnPlay', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = 2*opts.size
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.responder['resize'] = function(self)
--		self.geo.y is set in lblplay
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'pause')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnPlay')
addToPlayLayout('btnPlay')
local btnPlay = ne

-- play button label
ne = newElement('lblPlay', 'label')
ne.layer = 11
ne.geo = btnPlay.geo
ne.text = ''
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['pause'] = function(self)
		if player.paused or player.idle then
			self.text = '\xEF\x8E\xAA'
		else
			self.text = '\xEF\x8E\xA7'
		end
		self:render()
		return false
	end
ne.responder['idle'] = ne.responder['pause']
ne:init()
addToIdleLayout('lblPlay')
addToPlayLayout('lblPlay')

-- back button
ne = newElement('btnBack', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.responder['resize'] = function(self)
--		self.geo.y is set in lblBack
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', -10, 'relative', 'keyframes')
						return true
		end
		return false
	end
ne.responder['mbtn_right_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', -30, 'relative', 'keyframes')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnBack')
addToPlayLayout('btnBack')
local btnBack = ne

-- back button label
ne = newElement('lblBack', 'label')
ne.layer = 11
ne.geo = btnBack.geo
ne.text = '\xEF\x8E\xA0'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblBack')
addToPlayLayout('lblBack')

-- forward button
ne = newElement('btnForward', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', 10, 'relative', 'keyframes')
						return true
		end
		return false
	end
ne.responder['mbtn_right_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('seek', 30, 'relative', 'keyframes')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnForward')
addToPlayLayout('btnForward')
local btnForward = ne

-- forward button label
ne = newElement('lblForward', 'label')
ne.layer = 11
ne.geo = btnForward.geo
ne.text = '\xEF\x8E\x9F'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblForward')
addToPlayLayout('lblForward')

-- cycle sub button
ne = newElement('btnSub', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size*2
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.tooltip = tooltip
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		self:setHitBox()
		self.tooltipPos = {20, player.geo.refY - 10, 1}
		return false
	end
ne.responder['file-loaded'] = function(self)
		if #player.tracks.sub > 0 then
			self:enable()
			local list = {}
			for k, v in ipairs(player.tracks.sub) do
				list[k] = string.format('  [%02d] %s', k, v.title or v.lang or 'N/A')
			end
			self.tooltipText = table.concat(list, '\\N')
		else
			self:disable()
		end
		return false
	end
ne.responder['sub-changed'] = function(self)
		if player.tracks then
			self.tooltipText = string.gsub(self.tooltipText, '>>', '  ')
			if player.subTrack > 0 then
				local pattern = string.format('  %%[%02d%%]', player.subTrack)
				local sub = string.format('>>[%02d]', player.subTrack)
				self.tooltipText = string.gsub(self.tooltipText, pattern, sub)
			end
			self.tooltip:update(self.tooltipText, self)
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			cycleTrack('sub')
			return true
		end
		return false
	end
ne.responder['mbtn_right_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			cycleTrack('sub', 'prev')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnSub')
addToPlayLayout('btnSub')
local btnSub = ne

-- cycle sub label icon
ne = newElement('lblSub1', 'label')
ne.layer = 11
ne.text = '\xEF\x8F\x93'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.geo = clone(btnSub.geo)
ne.geo.x = ne.geo.x - ne.geo.w/4
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['file-loaded'] = function(self)
		if #player.tracks.sub > 0 then
			self:enable()
		else
			self:disable()
		end
		return false
	end
ne:init()
addToIdleLayout('lblSub1')
addToPlayLayout('lblSub1')

-- cycle sub label text
ne = newElement('lblSub2', 'label')
ne.layer = 11
ne.text = '0/0'
ne.fontsize1 = 14	-- fontsize for tracks less than 10
ne.fontsize2 = 12	-- more than 10
ne.styleNormal = clone(styles.text)	-- will change it
ne.styleDisabled = clone(styles.text2)
ne.styleNormal.fontsize = ne.fontsize1
ne.enabled = true
ne.geo = clone(btnSub.geo)
ne.geo.x = ne.geo.x + ne.geo.w*0.22
ne.geo.an = 5
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['sub-changed'] = function(self)
		if player.tracks then
			self.text = string.format('%s/%s', player.subTrack, #player.tracks.sub)
			self:render()
		end
		return false
	end
ne.responder['file-loaded'] =function(self)
		local fs
		if #player.tracks.sub >= 10 then
			fs = self.fontsize2
		else
			fs = self.fontsize1
		end
		self.styleNormal.fontsize = fs
		self.styleDisabled.fontsize = fs
		if #player.tracks.sub > 0 then
			self:enable()
		else
			self:disable()
		end
		self.responder['sub-changed'](self)
		return false
	end
ne:init()
addToIdleLayout('lblSub2')
addToPlayLayout('lblSub2')

-- cycle audio button
ne = newElement('btnAudio', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size*2
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.tooltip = tooltip
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		self:setHitBox()
		self.tooltipPos = {20, player.geo.refY - 10, 1}
		return false
	end
ne.responder['file-loaded'] = function(self)
		if #player.tracks.audio > 0 then
			self:enable()
			local list = {}
			for k, v in ipairs(player.tracks.audio) do
				list[k] = string.format('  [%02d] %s', k, v.title or v.lang or 'N/A')
			end
			self.tooltipText = table.concat(list, '\\N')
		else
			self:disable()
		end
		return false
	end
ne.responder['audio-changed'] = function(self)
		if player.tracks then
			self.tooltipText = string.gsub(self.tooltipText, '>>', '  ')
			if player.audioTrack > 0 then
				local pattern = string.format('  %%[%02d%%]', player.audioTrack)
				local sub = string.format('>>[%02d]', player.audioTrack)
				self.tooltipText = string.gsub(self.tooltipText, pattern, sub)
			end
			self.tooltip:update(self.tooltipText, self)
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			cycleTrack('audio')
			return true
		end
		return false
	end
ne.responder['mbtn_right_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			cycleTrack('audio', 'prev')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnAudio')
addToPlayLayout('btnAudio')
local btnAudio = ne

-- cycle audio label icon
ne = newElement('lblAudio1', 'label')
ne.layer = 11
ne.text = '\xEF\x8E\xB7'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.geo = clone(btnAudio.geo)
ne.geo.x = ne.geo.x - ne.geo.w/4
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['file-loaded'] = function(self)
		if #player.tracks.audio > 0 then
			self:enable()
		else
			self:disable()
		end
		return false
	end
ne:init()
addToIdleLayout('lblAudio1')
addToPlayLayout('lblAudio1')

-- cycle audio label text
ne = newElement('lblAudio2', 'label')
ne.layer = 11
ne.text = '0/0'
ne.fontsize1 = 14
ne.fontsize2 = 12
ne.styleNormal = clone(styles.text)
ne.styleDisabled = clone(styles.text2)
ne.styleNormal.fontsize = ne.fontsize1
ne.enabled = true
ne.geo = clone(btnAudio.geo)
ne.geo.x = ne.geo.x + ne.geo.w*0.22
ne.geo.an = 5
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['audio-changed'] = function(self)
		if player.tracks then
			self.text = string.format('%s/%s', player.audioTrack, #player.tracks.audio)
			self:render()
		end
		return false
	end
ne.responder['file-loaded'] =function(self)
		local fs
		if #player.tracks.audio >= 10 then
			fs = self.fontsize2
		else
			fs = self.fontsize1
		end
		self.styleNormal.fontsize = fs
		self.styleDisabled.fontsize = fs
		if #player.tracks.audio > 0 then
			self:enable()
		else
			self:disable()
		end
		self.responder['audio-changed'](self)
		return false
	end
ne:init()
addToIdleLayout('lblAudio2')
addToPlayLayout('lblAudio2')


-- playlist button
ne = newElement('btnList', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.geo.x = stackIn(ne.geo)
ne.tooltip = tooltip
ne.responder['resize'] = function(self)
--		self.geo.y
		self:setPos()
		self:setHitBox()
		self.tooltipPos = {5, player.geo.refY-10, 1}
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('playlist-next', 'weak')
			return true
		end
		return false
	end
	ne.responder['mbtn_right_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('playlist-prev', 'weak')
			return true
		end
		return false
	end
ne.responder['file-loaded'] = function(self)
		local list = {}, line, name
		for k, v in ipairs(player.playlist) do
			-- to discard the path in the filename\
			name = string.match(v.filename, '.+\\([^\\]*%.%w+)$')	-- windows system
			if not name then
				name = string.match(v.filename, ".+/([^/]*%.%w+)$")	-- linux system, not tested through
			end
			if v.current then
				list[k] = string.format('>>[%02d] %s', k, name)
			else
				list[k] = string.format('  [%02d] %s', k, name)
			end
		end
		self.tooltipText = table.concat(list, '\\N')
		self.tooltip:update(self.tooltipText, self)
		return false
	end
ne:init()
addToIdleLayout('btnList')
addToPlayLayout('btnList')
local btnList = ne

-- playlist button label
ne = newElement('lblList', 'label')
ne.layer = 11
ne.geo = btnList.geo
ne.text = '\xEF\x89\x87'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblList')
addToPlayLayout('lblList')

-- file info button
ne = newElement('btnInfo', 'button')
ne.layer = 10
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 4
ne.geo.x = stackX + opts.border
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.text = nil
ne.toggle = false
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('script-binding', 'stats/display-stats-toggle')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnInfo')
addToPlayLayout('btnInfo')
local btnInfo = ne

-- file info button icon
ne = newElement('lblInfo1', 'label')
ne.layer = 11
ne.geo = clone(btnInfo.geo)
ne.geo.an = 5
ne.geo.x = ne.geo.x + opts.size/2
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.text = '\xEF\x87\xB7'
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblInfo1')
addToPlayLayout('lblInfo1')

-- file info button text
ne = newElement('lblInfo2', 'label')
ne.layer = 11
ne.geo = clone(btnInfo.geo)
ne.geo.x = ne.geo.x + opts.size*1.2
ne.styleNormal = styles.text
ne.styleDisabled = styles.icon2
ne.text = ''
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['video-changed'] = function(self)
		if player.tracks then
			local video = player.tracks.video[player.videoTrack]
			local audio = player.tracks.audio[player.audioTrack]
			local infoV, infoA, sep = '', '', ''
			if video then
				infoV = string.format('%s %dx%d %.2ffps', string.upper(video.codec), video['demux-w'], video['demux-h'], video['demux-fps'] or 0)
			end
			if audio then
				infoA = string.format('%s %dch', string.upper(audio.codec), audio['demux-channel-count'] or 0)
			end
			if video and audio then
				sep = ' | '
			end
			self.text = string.format('%s%s%s', infoV, sep, infoA)
			self:render()
			
			local unit = self.style.fontsize/2
			btnInfo.geo.w = (math.ceil(#self.text * unit / opts.size)+1)*opts.size
			btnInfo:render()
			btnInfo:setHitBox()
		end
		return false
	end
ne.responder['audio-changed'] = ne.responder['video-changed']
ne:init()
addToIdleLayout('lblInfo2')
addToPlayLayout('lblInfo2')

-- add a variable space
ne = newElement('space', 'box')
ne.layer = 9
ne.style = styles.button
ne.geo.an = 4
ne.geo.h = opts.size
ne.geo.p = opts.border*4 + opts.size*3
ne.responder['resize'] = function(self)
		self.geo.x = btnInfo.geo.x + btnInfo.geo.w + opts.border
		self.geo.w = player.geo.width - self.geo.x - self.geo.p
		self.geo.y = player.geo.refY2
		self:setPos()
		self:render()
		return false
	end
ne.responder['audio-changed'] = ne.responder['resize']
ne.responder['video-changed'] = ne.responder['resize']
ne:init()
addToIdleLayout('space')
addToPlayLayout('space')

-- window control button bg
ne = newElement('wcbg', 'box')
ne.layer = 19
ne.style = styles.invisible
ne.geo.w = opts.border*4+opts.size*3
ne.geo.h = opts.size
ne.geo.an = 6
ne.setHitBox = function(self)
		local x1, y1, x2, y2 = getBoxPos(self.geo)
		self.hitBox = {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
	end
ne.isInside = isInside
ne.setAlpha = function(self, trans)
	end
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY2
		self.geo.x = player.geo.width
		self:setHitBox()
		return false
	end
ne.responder['mouse_move'] = function(self, pos)
		-- to inhibit normal buttons
		if self:isInside(pos) then
			return true
		end
		return false
	end
addToIdleLayout('wcbg')
addToPlayLayout('wcbg')

-- exit button
ne = newElement('btnExit', 'button')
ne.layer = 20
ne.geo.an = 5
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.responder['resize'] = function(self)
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('quit')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnExit')
addToPlayLayout('btnExit')
local btnExit = ne

-- exit button icon
ne = newElement('lblExit', 'label')
ne.layer = 23
ne.geo = btnExit.geo
ne.text = '\xEF\x84\xB6'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - opts.border - opts.size*0.5
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblExit')
addToPlayLayout('lblExit')

-- max button
ne = newElement('btnMax', 'button')
ne.layer = 20
ne.geo.an = 5
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.responder['resize'] = function(self)
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'fullscreen')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnMax')
addToPlayLayout('btnMax')
local btnMax = ne

-- max button icon
ne = newElement('lblMax', 'label')
ne.layer = 22
ne.geo = btnMax.geo
ne.text = '\xEF\x87\xAA'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = btnExit.geo.x - opts.border - opts.size
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne.responder['fullscreen'] = function(self)
		if player.fullscreen then
			self.text = '\xEF\x87\xAC'
		else
			self.text = '\xEF\x87\xAA'
		end
		self:render()
		return false
	end
ne:init()
addToIdleLayout('lblMax')
addToPlayLayout('lblMax')

-- minimize button
ne = newElement('btnMin', 'button')
ne.layer = 20
ne.geo.an = 5
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.responder['resize'] = function(self)
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'window-minimized')
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('btnMin')
addToPlayLayout('btnMin')
local btnMin = ne

-- Minimize button icon
ne = newElement('lblMin', 'label')
ne.layer = 21
ne.geo = btnMin.geo
ne.text = '\xEF\x87\xAB'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = btnMax.geo.x - opts.border - opts.size
		self.geo.y = player.geo.refY2
		self:setPos()
		return false
	end
ne:init()
addToIdleLayout('lblMin')
addToPlayLayout('lblMin')

-- seekbar
ne = newElement('seekbar', 'slider')
ne.layer = 10
ne.geo.x = opts.border
ne.geo.h = opts.size
ne.style1 = styles.button3
ne.style2 = styles.button
ne.responder['resize'] = function(self)
		self.geo.an = 4
		self.geo.y = player.geo.refY1
		self.geo.w = player.geo.refW1
		if self.geo.w > 0 then
			self.visible = true
			self:setParam()
			self:setPos()
			self:render()
		else
			self.visible = false
		end
		return false
	end
ne.responder['time'] = function(self)
		local val = player.percentPos
		if val then
			self.value = val
			self.xValue = val/100 * self.xLength
			self:render2()
		end
		return false
	end
ne.responder['file-loaded'] = function(self)
		-- update chapter markers
		self.markers = {}
		if player.duration then
			for i, v in ipairs(player.chapters) do
				self.markers[i] = (v.time / player.duration)
			end
			self:render()
		end
		return false
	end
ne.responder['mouse_move'] = function(self, pos)
		local seekTo = self:getValueAt(pos)
		if self.allowDrag then
			mp.commandv('seek', seekTo, 'absolute-percent')
		end
		if self:isInside(pos) then
			local tipText
			if player.duration then
				local seconds = seekTo/100 * player.duration
				if #player.chapters > 0 then
					local ch = #player.chapters
					for i, v in ipairs(player.chapters) do
						if seconds < v.time then
							ch = i - 1
							break
						end
					end
					if ch == 0 then
						tipText = string.format('[0/%d][unknown]\\N%s',
							#player.chapters, mp.format_time(seconds))
					else
						local title = player.chapters[ch].title
						if not title then title = 'unknown' end
						tipText = string.format('[%d/%d][%s]\\N%s',
							ch, #player.chapters, title,
							mp.format_time(seconds))
					end
				else
					tipText = mp.format_time(seconds)
				end
			else
				tipText = '--:--:--'
			end
			tooltip:show(tipText, {pos[1], self.geo.y}, self)
		else
			tooltip:hide(self)
		end
		return false
	end
ne.responder['mbtn_left_down'] = function(self, pos)
		if self:isInside(pos) then
			self.allowDrag = true
			local seekTo = self:getValueAt(pos)
			if seekTo then
				mp.commandv('seek', seekTo, 'absolute-percent')
				return true
			end
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.allowDrag then
			self.allowDrag = false
			self.lastSeek = nil
			return true
		end
	end
ne.responder['mbtn_right_up'] = function(self, pos)
		if self:isInside(pos) then
			local seekTo = self:getValueAt(pos)/100
			local chapter = nil
			if seekTo then
				for k, v in ipairs(self.markers) do
					if v > seekTo then
						break
					else
						chapter = v
					end
				end
			end
			if chapter then
				mp.commandv('seek', chapter*100, 'absolute-percent')
			end
			return true
		end
		return false
	end
ne:init()
addToIdleLayout('seekbar')
addToPlayLayout('seekbar')

-- time
ne = newElement('time', 'label')
ne.layer = 11
ne.geo.an = 4
ne.geo.x = opts.border
ne.geo.h = opts.size
ne.styleNormal = styles.text
ne.styleDisabled = styles.text2
ne.geo.w = ne.styleNormal.fontsize/2*20
ne.text = ''
ne.responder['resize'] = function(self)
		self.geo.y = player.geo.refY1
		self:setPos()
	end
ne.responder['time'] = function(self)
		local str = {' ', '', '', ''}
		if player.timePos then
			str[2] = mp.format_time(player.timePos)
		else
			str[2] = '--:--:--'
		end
		
		str[3] = ' / '
		
		local val
		if opts.remainingTime and player.timeRem then
			val = -player.timeRem
		else
			val = player.duration
		end
		if val then
			str[4] = mp.format_time(val)
		else
			str[4] = '--:--:--'
		end
		self.pack[4] = table.concat(str)
	end
ne:init()
addToIdleLayout('time')
addToPlayLayout('time')

-- title and filename info
ne = newElement('title', 'label')
ne.layer = 11
ne.geo.an = 5
ne.geo.h = opts.size
ne.styleNormal = styles.text
ne.styleDisabled = styles.text2
ne.text = ''
ne.title = ''
ne.chars = 0
ne.responder['resize'] = function(self)
		local w = player.geo.width - opts.size*4 - opts.border*6
		local maxchars = math.floor((w-200)*2 / self.styleNormal.fontsize)
		if maxchars < 20 then
			self.visible = false
			return false
		end
		
		self.visible = true
		self.geo.x = w/2 + 65
		self.geo.y = player.geo.refY1
		self:setPos()
		
		if self.chars == maxchars then return false end
		self.chars = maxchars 
		local text = self.title
		-- 估计1个中文字符约等于1.5个英文字符
		local charcount = (text:len() + select(2, text:gsub('[^\128-\193]', ''))*2) / 3
		if not (maxchars == nil) and (charcount > maxchars) then
			local limit = math.max(0, maxchars - 3)
			if (charcount > limit) then
				while (charcount > limit) do
					text = text:gsub('.[\128-\191]*$', '')
					charcount = (text:len() + select(2, text:gsub('[^\128-\193]', ''))*2) / 3
				end
				text = text .. '...'
			end
		end
		self.text = text
		self:render()
	end
ne.responder['file-loaded'] = function(self)
		self.title = mp.get_property('media-title')
		self.chars = 0
		self.responder['resize'](self)
	end
ne:init()
addToIdleLayout('title')
addToPlayLayout('title')

-- Volume button
ne = newElement('btnVol', 'button')
ne.layer = 20
ne.styleNormal = styles.button
ne.styleActive = styles.button2
ne.styleDisabled = styles.button
ne.enabled = true
ne.geo.an = 5
ne.geo.w = opts.size
ne.geo.h = opts.size
ne.responder['resize'] = function(self)
--		self.geo.y is set in lblVol
		self:setPos()
		self:setHitBox()
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			mp.commandv('cycle', 'mute')
		end
		return false
	end
ne.responder['audio-changed'] = function(self)
		if player.audioTrack == 0 then
			self:disable()
		else
			self:enable()
		end
	end
ne:init()
addToIdleLayout('btnVol')
addToPlayLayout('btnVol')
local btnVol = ne

-- Volume button label
ne = newElement('lblVol', 'label')
ne.layer = 21
ne.geo = btnVol.geo
ne.text = '\xEF\x8E\xBC'
ne.styleNormal = styles.icon
ne.styleDisabled = styles.icon2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - 3.5*opts.size - 4*opts.border
		self.geo.y = player.geo.refY1
		self:setPos()
		return false
	end
ne.responder['mute'] = function(self)
		if player.muted then
			self.text = '\xEF\x8E\xBB'
		else
			self.text = '\xEF\x8E\xBC'
		end
		self:render()
	end
ne.responder['audio-changed'] = btnVol.responder['audio-changed']

ne:init()
addToIdleLayout('lblVol')
addToPlayLayout('lblVol')

-- volume slider
ne = newElement('volume', 'slider')
ne.layer = 20
ne.geo.w = opts.border*2 + opts.size*3
ne.geo.h = opts.size
ne.style1 = styles.button3
ne.style2 = styles.button
ne.ratio = opts.maxVolume/100
ne.responder['resize'] = function(self)
		self.geo.an = 6
		self.geo.x = player.geo.width - opts.border
		self.geo.y = player.geo.refY1
		self:setParam()
		self:setPos()
		self:render()
		return false
	end
ne.responder['volume'] = function(self)
		local val = player.volume
		if val then
			self.value = val / self.ratio
			self.xValue = self.value/100 * self.xLength
			self:render2()
		end
		return false
	end
ne.responder['audio-changed'] = function(self)
		self.enabled = player.audioTrack ~= 0
	end
ne.responder['mouse_move'] = function(self, pos)
		if not self.enabled then return false end
		local vol = self:getValueAt(pos) * self.ratio
		if self.allowDrag then
			mp.commandv('set', 'volume', vol)
		end
		return false
	end
ne.responder['mbtn_left_down'] = function(self, pos)
		if self.enabled and self:isInside(pos) then
			self.allowDrag = true
			local vol = self:getValueAt(pos) * self.ratio
			if vol then
				mp.commandv('set', 'volume', vol)
				return true
			end
		end
		return false
	end
ne.responder['mbtn_left_up'] = function(self, pos)
		if self.allowDrag then
			self.allowDrag = false
			self.lastSeek = nil
			return true
		end
	end
ne:init()
addToIdleLayout('volume')
addToPlayLayout('volume')

-- Volume number label
ne = newElement('lblVolNum', 'label')
ne.layer = 21
ne.geo.an = 5
ne.text = ''
ne.styleNormal = styles.text
ne.styleDisabled = styles.text2
ne.enabled = true
ne.responder['resize'] = function(self)
		self.geo.x = player.geo.width - opts.border*2 - opts.size*1.5
		self.geo.y = player.geo.refY1
		self:setPos()
	end
ne.responder['volume'] = function(self)
		self.text = string.format('VOL%7d%%', math.floor(player.volume + 0.5))
		self:render()
	end
ne.responder['audio-changed'] = btnVol.responder['audio-changed']
ne:init()
addToIdleLayout('lblVolNum')
addToPlayLayout('lblVolNum')
