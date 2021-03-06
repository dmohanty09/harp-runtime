require "sinatra/config_file"
require 'securerandom'
require 'harp_runtime'

# The Harp API provides operations to deposit and invoke Harp scripts on the
# Harp runtime.
class HarpApiApp < ApiBase

  register Sinatra::ConfigFile

  config_file File.join(File.dirname(__FILE__), '../config/settings.yaml')

  def set_or_default(params, key, context, default)
    if params[key]
      context[key] = params[key]
    else
      context[key] = default
    end
  end

  def fetch_auth(params)
    auth = params[:auth] || nil
    if auth
      access = settings.send(auth)[:access]
      secret = settings.send(auth)[:secret]
      keys = settings.send(auth)[:keys]
    else
      access = params[:access] || ""
      secret = params[:secret] || ""
      keys = nil
    end
    context = { :access => access, :secret => secret, :keys => keys }
  end

  def prepare_context(params)
    context = fetch_auth(params)
    harp_location = params[:harp_location] || nil
    script = request.body.read

    context[:cloud_type] = :aws # for the moment, assume AWS cloud
    context[:mock] = true if params.key?("mock")
    if harp_location.nil?
      context[:harp_contents] = script
    else
      context[:harp_location] = harp_location
    end
    if script != nil and script.length < 1000
      logger.debug("Got harp script: #{script}")
    end
    set_or_default(params, :break, context, nil)
    context[:step] = params[:step]
    context[:continue] = params[:continue]
    set_or_default(params, :harp_id, context, nil)
    context
  end

  def handle_error(e, action)
    logger.error("Error running script: #{e}")
    logger.error("Error running script: #{e.backtrace[1..-1].join("\n")}")
    erb :harp_api_error,  :layout => :layout_api, :locals => {:action => action, :error => e.message.gsub(/\"|\\|\a|\b|\r|\n|\s|\t/, "")}
  end

  def run_lifecycle(lifecycle, interpreter, context)
    begin
      results = interpreter.play(lifecycle, context)
      erb :harp_api_result,  :layout => :layout_api, :locals => {:lifecycle => lifecycle, :results => results}
    rescue => e
      handle_error(e, lifecycle)
    end
  end

  def get_status(interpreter, context)
    begin
      results = interpreter.get_status(context)
      erb :harp_api_result,  :layout => :layout_api, :locals => {:lifecycle => lifecycle, :results => results}
    rescue => e
      handle_error(e, "get_status")
    end
  end

  def get_output(output_token, interpreter, context)
    begin
      results = interpreter.get_output(output_token, context)
      erb :harp_api_result,  :layout => :layout_api, :locals => {:results => results}
    rescue => e
      handle_error(e, "get_output")
    end
  end

  before "/:verb/:harp_id/:output_token" do
    @context = prepare_context(params)
    @interpreter = Harp::HarpInterpreter.new(@context)
  end

  before "/:lifecycle/:harp_id" do
    @context = prepare_context(params)
    @interpreter = Harp::HarpInterpreter.new(@context)
  end

  before do
    if ! @context
      @context = prepare_context(params)
      @interpreter = Harp::HarpInterpreter.new(@context)
    end
  end

  ##~ sapi = source2swagger.namespace("harp")
  ##~ sapi.swaggerVersion = "1.2"
  ##~ sapi.apiVersion = "0.1.0"
  ##~ sapi.basePath = "http://localhost:9393"
  ##~ sapi.resourcePath = "/api/v1/harp"

  ##~ a = sapi.apis.add
  ##~ a.set :path => "/api/v1/harp/create"
  ##~ a.description = "Harp runtime invocation of create"

  ##~ op = a.operations.add
  ##~ op.set :httpMethod => "POST"
  ##~ op.summary = "Invoke normal create lifecycle"
  ##~ op.nickname = "run_create"
  ##~ op.parameters.add :name => "access", :description => "Cloud credential information, access key or user", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "secret", :description => "Secret key or password", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "auth", :description => "Cloud credential set to use, configured on server", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "harp", :description => "Harp script content", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "body"
  ##~ op.parameters.add :name => "harp_location", :description => "Harp script location (URI)", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.errorResponses.add :message => "Invocation successful", :code => 200
  ##~ op.errorResponses.add :message => "Invocation successfully begun", :code => 202
  ##~ op.errorResponses.add :message => "Bad syntax in script", :code => 400
  ##~ op.errorResponses.add :message => "Unable to authorize with supplied credentials", :code => 401
  ##~ op.errorResponses.add :message => "Fatal error invoking script", :code => 500
  post '/create' do
    run_lifecycle(Harp::Lifecycle::CREATE, @interpreter, @context)
  end

  ##~ a = sapi.apis.add
  ##~ a.set :path => "/api/v1/harp/destroy/{harp_id}"
  ##~ a.description = "Harp runtime invocation of destroy"

  ##~ op = a.operations.add
  ##~ op.set :httpMethod => "POST"
  ##~ op.summary = "Invoke normal destroy lifecycle"
  ##~ op.nickname = "run_destroy"
  ##~ op.parameters.add :name => "harp_id", :description => "Harp script execution ID", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "access", :description => "Cloud credential information, access key or user", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "secret", :description => "Secret key or password", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "auth", :description => "Cloud credential set to use, configured on server", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "harp", :description => "Harp script content", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "body"
  ##~ op.parameters.add :name => "harp_location", :description => "Harp script location (URI)", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.errorResponses.add :message => "Invocation successful", :code => 200
  ##~ op.errorResponses.add :message => "Invocation successfully begun", :code => 202
  ##~ op.errorResponses.add :message => "Bad syntax in script", :code => 400
  ##~ op.errorResponses.add :message => "Unable to authorize with supplied credentials", :code => 401
  ##~ op.errorResponses.add :message => "Fatal error invoking script", :code => 500
  post '/destroy/:harp_id' do
    run_lifecycle(Harp::Lifecycle::DESTROY, @interpreter, @context)
  end

  ##~ a = sapi.apis.add
  ##~ a.set :path => "/api/v1/harp/output/{harp_id}/{output_token}"
  ##~ op = a.operations.add
  ##~ op.set :httpMethod => "GET"
  ##~ op.summary = "Request the output for some step taken during execution of a harp script."
  ##~ op.nickname = "get_output"
  ##~ op.parameters.add :name => "harp_id", :description => "Harp script execution ID", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "output_token", :description => "Token from action which produced some output", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "access", :description => "Cloud credential information, access key or user", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "secret", :description => "Secret key or password", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "auth", :description => "Cloud credential set to use, configured on server", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.errorResponses.add :message => "Request successful", :code => 200
  ##~ op.errorResponses.add :message => "Harp, output not found", :code => 404
  ##~ op.errorResponses.add :message => "Unable to authorize with supplied credentials", :code => 401
  ##~ op.errorResponses.add :message => "Fatal error invoking script", :code => 500
  get '/output/:harp_id/:output_token' do
    get_output(params[:output_token], @interpreter, @context)
  end

  ##~ a = sapi.apis.add
  ##~ a.set :path => "/api/v1/harp/status/{harp_id}"
  ##~ op = a.operations.add
  ##~ op.set :httpMethod => "GET"
  ##~ op.summary = "Get the status of a harp script."
  ##~ op.nickname = "get_status"
  ##~ op.parameters.add :name => "harp_id", :description => "Harp script execution ID", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "access", :description => "Cloud credential information, access key or user", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "secret", :description => "Secret key or password", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "auth", :description => "Cloud credential set to use, configured on server", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.errorResponses.add :message => "Request successful", :code => 200
  ##~ op.errorResponses.add :message => "Harp not found", :code => 404
  ##~ op.errorResponses.add :message => "Unable to authorize with supplied credentials", :code => 401
  ##~ op.errorResponses.add :message => "Fatal error invoking script", :code => 500
  get '/status/:harp_id' do
    get_status(@interpreter, @context)
  end

  ##~ a = sapi.apis.add
  ##~ a.set :path => "/api/v1/harp/{lifecycle}/{harp_id}"
  ##~ op = a.operations.add
  ##~ op.set :httpMethod => "POST"
  ##~ op.summary = "Invoke a particular lifecycle operation on a harp script."
  ##~ op.nickname = "run_lifecycle"
  ##~ op.parameters.add :name => "lifecycle", :description => "Lifecycle action to take (create, etc.)", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "harp_id", :description => "Harp script execution ID", :dataType => "string", :allowMultiple => false, :required => true, :paramType => "path"
  ##~ op.parameters.add :name => "access", :description => "Cloud credential information, access key or user", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "secret", :description => "Secret key or password", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "auth", :description => "Cloud credential set to use, configured on server", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.parameters.add :name => "harp", :description => "Harp script content", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "body"
  ##~ op.parameters.add :name => "harp_location", :description => "Harp script location (URI)", :dataType => "string", :allowMultiple => false, :required => false, :paramType => "query"
  ##~ op.errorResponses.add :message => "Invocation successful", :code => 200
  ##~ op.errorResponses.add :message => "Invocation successfully begun", :code => 202
  ##~ op.errorResponses.add :message => "Bad syntax in script", :code => 400
  ##~ op.errorResponses.add :message => "Unable to authorize with supplied credentials", :code => 401
  ##~ op.errorResponses.add :message => "Fatal error invoking script", :code => 500
  post '/:lifecycle/:harp_id' do
    run_lifecycle(params[:lifecycle], @interpreter, @context)
  end

end
