# -*- encoding : utf-8 -*-
require 'spec_helper'
require 'etl/exekutor_extraction'

describe Etl::ExekutorExtraction do
  let!(:tony_executor) { Kernel::DsExecutor.create!(name: 'Tony', record_status: 'published') }

  describe '#perform' do
    it 'saves extracted executors to database and mark old records as suspended' do
      VCR.use_cassette('etl/executor_extraction/executors_letter_i') do
        extration = Etl::ExekutorExtraction.new(
            document_url: 'http://www.ske.sk/zoznam-exekutorov/?f=I'
        )
        extration.perform

        tony_executor.reload.record_status.should eq 'suspended'
        Kernel::DsExecutor.count.should be > 2
        Kernel::DsExecutor.find_by_name!('JUDr. Ingr Jozef').record_status.should eq 'published'
      end
    end

    it 'does not change anything in storage if page does not have any executors' do
      VCR.use_cassette('etl/executor_extraction/invalid_site') do
        extration = Etl::ExekutorExtraction.new(
            document_url: 'http://www.ske.sk/category/aktuality/'
        )
        extration.perform
      end

      tony_executor.reload.record_status.should eq 'published'
      Kernel::DsExecutor.count.should eq 1
    end
  end
end

describe Etl::ExekutorExtraction::ListingPage do

  describe '#executors' do
    it 'returns executors array of hashes' do
      page = VCR.use_cassette('etl/executor_extraction/executors') do
        Etl::PageLoader.load_by_get('http://www.ske.sk/zoznam-exekutorov/', Etl::ExekutorExtraction::ListingPage)
      end

      page.executors.length.should be > 300

      executor = page.executors.find{ |executor| executor[:name] == 'JUDr. Ingr Jozef' }
      executor.should == {
          name: 'JUDr. Ingr Jozef',
          street: 'Matejkova 13',
          zip: '84105',
          city: 'Bratislava',
          telephone: '02/65411505',
          fax: '02/65411505',
          email: 'jozef.ingr@ske.sk',
      }

      page.executors.each do |executor|
        executor[:name].should match_regex /^[\p{Letter}\. ,\(\)]+$/
        executor[:street].should match_regex /^[\p{Letter}\. ,0-9\\\/\-]+$/
        if executor[:zip]
          executor[:zip].should match_regex /^[0-9 ]+$/
        end
        if executor[:city]
          executor[:city].should match_regex /^[\p{Letter} 0-9]+$/
        end
        executor[:telephone].should match_regex /^[0-9 ,\+\-\\\/]+$/
        executor[:fax].should match_regex /^[0-9 ,\+\-\\\/]+$/
        executor[:email].should match_regex /^[a-z0-9\.@]+$/
      end

      # WATCH OUT FOR !
      executor = page.executors.find { |executor| executor[:name] == 'Mgr. Makita Ján' }
      executor[:telephone].should eq '02 62525594, 95, 96'
      executor[:fax].should eq '-'
    end

    it 'returns empty array if page is not acceptable' do
      page = VCR.use_cassette('etl/executor_extraction/invalid_site') do
        Etl::PageLoader.load_by_get('http://www.ske.sk/category/aktuality/', Etl::ExekutorExtraction::ListingPage)
      end

      page.executors.should eq []
    end
  end
end