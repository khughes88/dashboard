@client = MongoClient.new('localhost', 27017)
@db     = @client['cildata']
@super  = @db['superset']
@sub  = @db['subset']
@tree  = @db['tree']

@user='kh07285'
@pass='Vibram3'
