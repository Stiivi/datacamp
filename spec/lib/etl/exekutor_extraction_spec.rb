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

describe Etl::Executor::Downloader do

  describe '.download' do
    it 'downloads given url to document' do
      VCR.use_cassette('etl/executor_extraction/executors') do
        document = Etl::Executor::Downloader.download('http://www.ske.sk/zoznam-exekutorov/')
        document.should respond_to(:xpath)
      end
    end
  end
end

describe Etl::Executor::ListingPage do

  describe '#executors' do
    it 'returns executors array of hashes' do
      executors_document = VCR.use_cassette('etl/executor_extraction/executors') do
         Etl::Executor::Downloader.download('http://www.ske.sk/zoznam-exekutorov/')
      end

      executors = Etl::Executor::ListingPage.new(executors_document).executors
      executors.length.should be > 300

      executor = executors.find{ |executor| executor[:name] == 'JUDr. Ingr Jozef' }
      executor.should == {
          name: 'JUDr. Ingr Jozef',
          street: 'Matejkova 13',
          zip: '84105',
          city: 'Bratislava',
          telephone: '02/65411505',
          fax: '02/65411505',
          email: 'jozef.ingr@ske.sk',
      }

      executors.each do |executor|
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
      executor = executors.find { |executor| executor[:name] == 'Mgr. Makita Ján' }
      executor[:telephone].should eq '02 62525594, 95, 96'
      executor[:fax].should eq '-'
    end

    it 'returns empty array if page is not acceptable' do
      executors_document = VCR.use_cassette('etl/executor_extraction/invalid_site') do
        Etl::Executor::Downloader.download('http://www.ske.sk/category/aktuality/')
      end

      executors = Etl::Executor::ListingPage.new(executors_document).executors
      executors.should eq []
    end
  end
end