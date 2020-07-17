# frozen_string_literal: true

#
# Redmine plugin to preview a Microsoft Office attachment file
#
# Copyright © 2018 Stephan Wenzel <stephan.wenzel@drwpatent.de>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

module RedminePreviewOffice
  module Patches
    module RepositoriesControllerPatch
      def self.included(base)
    #    base.send(:prepend, InstancOverwriteMethods)
        base.class_eval do
          unloadable
          def entry_and_raw(is_raw)

    @entry = @repository.entry(@path, @rev)
    logger.info "path #{@path}"
    logger.info "rev #{@rev}"
    logger.info "entry #{@entry}"
    logger.info "disposition #{disposition(@path)}"

    (show_error_not_found; return) unless @entry

    # If the entry is a dir, show the browser
    (show; return) if @entry.is_dir?
     thumbnails_storage_path = File.join(Rails.root, "tmp", "thumbnails")
     target = File.join(thumbnails_storage_path, @path)
      logger.info "target #{target}"
      logger.info "relative  #{@repository.relative_path(@path)}"

     tmpfile = @repository.cat(@path, @rev)
     #   logger.info "relative  #{@repository.cat(@path, @rev)}"
     tmppath = File.join("/usr/src/redmine/files/", @path)
     directory = File.dirname(tmppath)
                          unless File.exists?(directory)
                                FileUtils.mkdir_p directory
                          end
     
     File.open(tmppath,"wb") do |file|
      file.puts tmpfile
     end


    if is_raw
      # Force the download
      preview = Redmine::Thumbnail.generate_preview_office("/usr/src/redmine/files/#{@path}", target)
      send_file preview,
          filename: filename_for_content_disposition(@path.split('/').last),
          type: 'application/pdf',
          disposition: 'inline'
    else
      # set up pagination from entry to entry
      parent_path = @path.split('/')[0...-1].join('/')
      @entries = @repository.entries(parent_path, @rev).reject(&:is_dir?)
      if index = @entries.index{|e| e.name == @entry.name}
        @paginator = Redmine::Pagination::Paginator.new(@entries.size, 1, index+1)
      end

      if !@entry.size || @entry.size <= Setting.file_max_size_displayed.to_i.kilobyte
        content = @repository.cat(@path, @rev)
        (show_error_not_found; return) unless content

        if content.size <= Setting.file_max_size_displayed.to_i.kilobyte &&
           is_entry_text_data?(content, @path)
          # TODO: UTF-16
          # Prevent empty lines when displaying a file with Windows style eol
          # Is this needed? AttachmentsController simply reads file.
          @content = content.gsub("\r\n", "\n")
        end
      end
      @changeset = @repository.find_changeset_by_name(@rev)
    end
    



          end # def
        end # base
      end # self

    end # module
  end # module
end # module

unless RepositoriesController.included_modules.include?(RedminePreviewOffice::Patches::RepositoriesControllerPatch)
  RepositoriesController.send(:include, RedminePreviewOffice::Patches::RepositoriesControllerPatch)
end
