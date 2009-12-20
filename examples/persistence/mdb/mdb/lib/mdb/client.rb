require 'rubygems'
require 'httpclient'

require 'mdb/serializer'

module MDB
  # Manages the REST communication to MDB and serialization
  class REST

    # HTTP headers used for post with marshaled data
    POST_ENCODINGS =  {
      'Content-Type' => 'application/mdb',
      'Content-Transfer-Encoding' => "binary" }

    def initialize(url)
      @url = url
      @serializer = MDB::MarshalSerializer.new
      @server = HTTPClient.new
    end

    def delete(path)
      request(:delete, path)
    end

    def get(path)
      request(:get, path)
    end

    def put(path, data)
      # Data should already be wrapped in an array
      request(:put, path, @serializer.serialize(data))
    end

    def post(path, data)
      # Data should already be wrapped in an array
      request(:post, path, @serializer.serialize(data))
    end

    private
    # Issue a request based on op and provided data.
    # Returns an HTTP::Message object.
    def request(op, path, data = nil)
      retry_count = 1
      # Save current data for exceptions in handle_response
      @path = @url + path
      @method = op
      @data = data
      begin
        handle_response case op
                        when :get
                          @server.get_content @path
                        when :put
                          @server.put @path, @data, POST_ENCODINGS
                        when :delete
                          @server.delete @path
                        when :post
                          @server.post @path, @data, POST_ENCODINGS
                        end
      rescue Errno::ECONNRESET
        if retry_count > 0
          retry_count -= 1
          retry
        end
        raise
      end
    end

    def handle_response(response)
      #puts "--- response: #{response.inspect}"
      case response
      when HTTP::Message
        begin
          case response.status
          when 200..299
            deserialize(response)
          else
            raise "Error doing #{@method} #{@path} STATUS: #{response.status} #{response.body.content}"
          end
        rescue HTTPClient::BadResponseError => bre
          raise "Error doing #{@method} #{@path} from database: #{bre.res.content}"
        end
      else
        @serializer.deserialize(response)
      end
    end

    def deserialize(obj)
      obj = obj.content if HTTP::Message === obj
      @serializer.deserialize obj
    end
  end

  class RESTDatabase
    def initialize(url, db_name)
      @rest = REST.new(url)
      @db_name = db_name
    end

    def execute_view(view_name, *params)
      @rest.post("/#{@db_name}/view/#{view_name}", params)
    end

    # GET /:db/:id
    def get(id)
      @rest.get("/#{@db_name}/#{id}")
    end

    # POST /:db   returns docid
    def add(document)
      id = @rest.post("/#{@db_name}", [document])
      document.id = id if document.respond_to?(:id)
      id
    end
    
    # PUT /:db/:id
    def update(id, document)
      @rest.put("/#{@db_name}/#{id}", [document])
    end

    # DELETE /:db/:id
    def delete(document)
      @rest.delete("/#{@db_name}/#{document.id}")
    end
    
    def size
      @rest.get("/#{@db_name}/send/size")
    end

    def list_ids
      @rest.get("/#{@db_name}/send/list_ids")
    end

    def clear
      @rest.get("/#{@db_name}/send/clear")
    end

    def debug_info
      @rest.get("/#{@db_name}/debug_info")
    end
  end

  class RESTServer
    # Initialize a +RESTServer+ that will communicate with the remote
    # MDB::Server object over +url+.
    def initialize(url)
      @url = url
      @rest = REST.new(url)
    end

    def migrate(klass, ruby_source, migrate_instances=false)
      data = {
        :ruby_source => ruby_source,
        :klass => klass,
        :migrate_instances => migrate_instances }
      @rest.post("/migrate", [data])
    end

    def key?(key)
      @rest.get("/#{key}")
    end

    def create(db_name, view_class)
      result = @rest.post("/", [{:db_name => db_name, :view_class => view_class.to_s}])
      if result == db_name
         RESTDatabase.new(@url, db_name)
       else
         raise result
       end
    end

    def delete(db_name)
      @rest.delete("/#{db_name}")
    end

    def [](db_name)
      # TODO: should we ask the server if db_name exists first?
      RESTDatabase.new(@url, db_name)
    end

    def db_names
      @rest.get("/")
    end

    def debug_info
      @rest.get("/debug_info")
    end
  end
end
