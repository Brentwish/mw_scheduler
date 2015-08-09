require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

module DriveHandler

  APPLICATION_NAME = 'Drive API Quickstart'
  CLIENT_SECRETS_PATH = 'client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials',
                               "drive-quickstart.json")
  SCOPE = 'https://www.googleapis.com/auth/drive.metadata'

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization request via InstalledAppFlow.
# If authorization is required, the user's default browser will be launched
# to approve the request.
#
# @return [Signet::OAuth2::Client] OAuth2 credentials
  def DriveHandler.authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
    storage = Google::APIClient::Storage.new(file_store)
    auth = storage.authorize

    if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
      app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
      flow = Google::APIClient::InstalledAppFlow.new({
        :client_id => app_info.client_id,
        :client_secret => app_info.client_secret,
        :scope => SCOPE})
      auth = flow.authorize(storage)
      puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
    end
    auth
  end

# Initialize the API
  def DriveHandler.init
    @client = Google::APIClient.new(:application_name => APPLICATION_NAME)
    @client.authorization = authorize
    @drive_api = @client.discovered_api('drive', 'v2')
  end

# List the 10 most recently modified files.
  def DriveHandler.list_10_files
    results = client.execute!(
      :api_method => drive_api.files.list,
      :parameters => { :maxResults => 10 })
    puts "Files:"
    puts "No files found" if results.data.items.empty?
    results.data.items.each do |file|
      puts "#{file.title} (#{file.id})"
    end
  end

##
# Print a file's metadata.
#
# @param [Google::APIClient] client
#   Authorized client instance
# @param [String] file_id
#   ID of file to print
# @return nil
  def DriveHandler.print_file(client, file_id)
    drive = client.discovered_api('drive', 'v2')
    result = client.execute(
      :api_method => @drive_api.files.get,
      :parameters => { 'fileId' => file_id })
    if result.status == 200
      file = result.data
      puts "Title: #{file.title}"
      puts "Description: #{file.description}"
      puts "MIME type: #{file.mime_type}"
    else
      puts "An error occurred: #{result.data['error']['message']}"
    end
  end


##
# Download a file's content
#
# @param [Google::APIClient] client
#   Authorized client instance
# @param [Google::APIClient::Schema::Drive::V2::File]
#   Drive File instance
# @return
#   File's content if successful, nil otherwise

  def DriveHandler.download_file(client, file)
    if file.download_url
      result = client.execute(:uri => file.download_url)
      if result.status == 200
        return result.body
      else
        puts "An error occurred: #{result.data['error']['message']}"
        return nil
      end
    else
      # The file doesn't have any content stored on Drive.
      return nil
    end
  end
end
