class ActiveExportWorker
  include Sidekiq::Worker

  def perform(export_id)
    @export = ActiveExport.find(export_id)
    @file_name = "#{@export.exportable.model_name.param_key}_#{@export.exportable.id}_#{@export.name}_export_#{Time.current.to_i}.csv"
    @blob_key = "tenent_#{@export.author.tenent_id}/#{@file_name}"
    @client = init_aws_client
    @object = init_aws_object

    I18n.with_locale(@export.author.tenent.settings_locale) do
      @object.upload_stream do |write_stream|
        @checksum = OpenSSL::Digest::MD5.new.tap do |checksum|
          @export.rows.each.with_index do |row, index|
            if (index == 0)
              csv_headers = @export.headers.values.to_csv(col_sep: ';')
              write_stream << csv_headers
              checksum << csv_headers
              @byte_size = csv_headers.bytesize
            end

            csv_row = row.to_csv(col_sep: ';')
            write_stream << csv_row
            checksum << csv_row
            @byte_size = @byte_size + csv_row.bytesize
          end
        end.base64digest
      end

      @blob = ActiveStorage::Blob.create(key: @blob_key, filename: @file_name, content_type: 'text/csv', byte_size: @byte_size, checksum: @checksum, service_name: :aws)
      ActiveStorage::Attachment.create(name: :csv_export_file, record: @export, blob_id: @blob.id)
    end

    ensure
      @export.update_column(:is_exporting, false)
  end

  private
    def init_aws_client
      Aws::S3::Client.new(
        access_key_id: Rails.application.credentials.dig(:aws, :access_key_id),
        secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key),
        region: Rails.application.credentials.dig(:aws, :region)
      )
    end

    def init_aws_object
      Aws::S3::Object.new(Rails.application.credentials.dig(:aws, :bucket), @blob_key, client: @client)
    end
end
