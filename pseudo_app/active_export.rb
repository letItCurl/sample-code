class ActiveExport < ApplicationRecord
  paginates_per 30

  belongs_to :author
  belongs_to :exportable, polymorphic: true
  belongs_to :tenent, inverse_of: :exports

  has_one_attached :csv_export_file

  validates :is_exporting, inclusion: [ true, false ]

  def csv_export_file_available?
    (self.csv_export_file.present? && self.csv_export_file.persisted?)
  end

  def query
    self.exportable.public_send("#{self.name}_export_query".to_sym)
  end

  def headers
    self.exportable.public_send("#{self.name}_export_header".to_sym)
  end

  def rows(query_to_map= self.query)
    query_to_map.map do |active_record_instance|
      named_data_row = active_record_instance.public_send("#{self.name}_export_data".to_sym)
      self.headers.keys.map{ |column_name| named_data_row[column_name] }
    end
  end

  def export_later
    unless (self.is_exporting?)
      if (self.update(is_exporting: true))
        self.csv_export_file.purge_later if (self.csv_export_file_available?)
        ActiveExportWorker.perform_async(self.id)
      else
        false
      end
    else
      false
    end
  end
end

# == Schema Information
#
# Table name: active_exports
#
#  id              :uuid             not null, primary key
#  exportable_type :string           not null
#  is_exporting    :boolean          default(FALSE), not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  author_id       :uuid             not null
#  exportable_id   :uuid             not null
#  tenent_id       :uuid             not null
#
# Indexes
#
#  idx_atv_eprs_on_exportable_type_and_exportable_id_and_name  (exportable_type,exportable_id,name) UNIQUE
#  index_active_exports_on_author                              (author_type,author_id)
#  index_active_exports_on_tenent_id                           (tenent_id)
#
# Foreign Keys
#
#  fk_rails_...  (tenent_id => tenents.id) ON DELETE => cascade
#
