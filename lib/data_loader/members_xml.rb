require 'nokogiri'
require 'cgi'

module DataLoader
  class MembersXML
    class << self
      def load_all
        Electorates.load!
        Offices.load!
        load_representatives_and_senators
      end

      # representatives.xml & senators.xml
      def load_representatives_and_senators
        Rails.logger.info "Reloading representatives and senators..."
        Rails.logger.info "Deleted #{Member.delete_all} members"
        %w(representatives senators).each do |file|
          Rails.logger.info "Loading #{file}..."
          xml = Nokogiri.parse(File.read("#{Settings.xml_data_directory}/members/#{file}.xml"))
          xml.search(:member).each do |member|
            # Ignores entries older than the 1997 UK General Election
            next if member[:todate] <= '1997-04-08'

            house = member[:house]
            house = case house
                    when 'representatives'
                      'commons'
                    when 'senate'
                      'lords'
                    end

            gid = member[:id]
            if gid.include?('uk.org.publicwhip/member/')
              raise 'House mismatch' unless house == 'commons'
              id = gid[/uk.org.publicwhip\/member\/(\d*)/, 1]
            elsif gid.include?('uk.org.publicwhip/lord/')
              raise 'House mismatch' unless house == 'lords'
              id = gid[/uk.org.publicwhip\/lord\/(\d*)/, 1]
            else
              raise "Unknown gid type #{gid}"
            end

            person = member_to_person[member[:id]]
            raise "MP #{member[:id]} has no person" unless person
            person = person[/uk.org.publicwhip\/person\/(\d*)/, 1]

            Member.where(gid: gid).destroy_all
            Member.create!(first_name: MembersXML.escape_html(member[:firstname]),
                           last_name: MembersXML.escape_html(member[:lastname]),
                           title: member[:title],
                           constituency: MembersXML.escape_html(member[:division]),
                           party: member[:party],
                           house: house,
                           entered_house: member[:fromdate],
                           left_house: member[:todate],
                           entered_reason: member[:fromwhy],
                           left_reason: member[:towhy],
                           mp_id: id,
                           person: person,
                           gid: gid,
                           source_gid: '')
          end
        end
        Rails.logger.info "Loaded #{Member.count} members"
      end

      # Urgh, add extra HTML escaping that's done in PHP but not Ruby
      def self.escape_html(text)
        text = CGI::escape_html(text)
        text.gsub!('’', '&rsquo;')
        text.gsub('‘', '&lsquo;')
      end

      private

      def member_to_person
        @member_to_person || load_people
      end

      # people.xml
      def load_people
        people_xml = Nokogiri.parse(File.read("#{Settings.xml_data_directory}/members/people.xml"))
        member_to_person = {}
        people_xml.search(:person).each do |person|
          person.search(:office).each do |office|
            member_to_person[office[:id]] = person[:id]
          end
        end

        @member_to_person = member_to_person
      end
    end
  end
end