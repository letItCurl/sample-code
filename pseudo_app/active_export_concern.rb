module ActiveExportConcern
  extend ActiveSupport::Concern
  class_methods do
    def has_one_export(name, query: nil)
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}_export(author: nil)
          if (author.present?)
            #{name}_export_create(author: author)
          end
          #{name}_exportable || build_#{name}_exportable
        end

        def csv_#{name}_export
          #{name}_exportable&.csv_export_file
        end

        def csv_#{name}_export_available?
          #{name}_exportable&.csv_export_file_available?
        end

        def #{name}_export_query
          #{query}
        end

        def #{query}_export_header
          # @NOTE: This method has to be defined in the model.
        end

        def #{name}_export_create(author:)
          #{name}_export.tap do |export|
            export.author = author
            export.tenent_id = author.tenent_id
            export.is_exporting = false
            return export.save
          end
        end

        def #{name}_export_is_exporting?
          (#{name}_export.is_exporting == true)
        end
      CODE

      has_one :"#{name}_exportable", -> { where(name: name) }, class_name: ActiveExport.to_s, as: :exportable, autosave: true, dependent: :destroy
    end
  end
end
