next = require 'nextflow'
request = require 'request'
assert = require 'assert'
equal = assert.equal
mysql = require 'mysql'
_ = require 'underscore'
gate = require 'gate'
l = require('tracer').colorConsole({
	format:'imouto[{{title}}] {{timestamp}} {{message}}'
	dateformat:'yyyy-mm-dd H:MM:ss'
})




conn = mysql.createConnection 'mysql://root:19990906c@127.0.0.1:3306/moefou'


fetch = (page,callback)->
	stats = {}
	next flow =
		error: (err)->
			l.error JSON.stringify err
		start: ->
			request({
				url:'https://yande.re/post.json'
				qs:
					limit:30
					page:page
			},@next)

		check_exist: (err,rep)->
			equal rep.statusCode,200,'Request to imouto is not success.'

			items = JSON.parse rep.body
			stats.item_received = items.length
			sql = 'SELECT `gallery_id` FROM `mp_gallery` WHERE `gallery_md5` = ?'
			g = gate.create()

			for item in items
				item.tags = item.tags.split /\s/g
				conn.query(sql,[item.md5],g.latch({data:1,item:g.val(item)}))

			g.await @next

		insert_data:(err,items)->
			items = _.filter items,(item)->not item.data[0]?
			items = for item in items
				item.item
			if items.length is 0
				@success(null,stats)
				return

			g = gate.create()

			sql = '''
						INSERT INTO `mp_gallery`
						(`gallery_width`, `gallery_height`
						, `gallery_file_url`, `gallery_sample_url`, `gallery_preview_url`
						, `gallery_source`, `gallery_file_size`, `gallery_date`
						, `gallery_rating`, `gallery_md5`, `gallery_site`
						, `gallery_site_id`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
						'''

			for item in items
				conn.query(sql,[
					item.width
					item.height
					item.file_url
					item.sample_url
					item.preview_url
					item.source
					item.file_size
					Math.round(new Date().getTime()/1000)
					item.rating
					item.md5
					'imouto'
					item.id
				],g.latch({result:1,item:g.val(item)}))

			g.await @next

		query_tags:(err,result)->
			items = _.map result,(item)->
				_.extend(item.item,{row:item.result.insertId})

			_tags = {}
			for item in items
				for tag in item.tags
					_tags[tag] = [] unless _tags[tag]?
					_tags[tag].push(item.row)
			tags = for key,val of _tags
				{name:key,rows:val}

			console.dir tags

			g = gate.create()

			for tag in tags
				sql = 'SELECT `tag_id` FROM `mp_tags` WHERE  `tag_eng_name` = ?'
				conn.query sql,[tag.name], g.latch({data:1,tag:g.val(tag)})

			g.await @next





		success:callback






fetch 10,->
	console.dir arguments
	conn.query 'TRUNCATE `mp_gallery`',->
		conn.end()

