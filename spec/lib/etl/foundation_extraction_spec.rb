# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::FoundationExtraction do

  before :each do
    @extractor = Etl::FoundationExtraction.new(158823)
  end

  describe '#document_url' do
    it 'return a correctly formatted document url' do
      @extractor.document_url.should == URI.encode("http://www.ives.sk/registre/detailrnd.do?action=uplny&formular=&id=158823&locale=sk")
    end
  end

  describe '#download' do
    it 'return downloaded document' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        @extractor.download.should_not be_nil
      end
    end
  end

  describe '#digest' do
    it 'return foundation hash - all attributes' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ives_id].should == 158823
        digest[:name].should include('NADÁCIA EQUUS ARABIUS')
        digest[:identification_number].should == '30864399'
        digest[:registration_number].should == '203/Na-2002/839'
        digest[:address].should == 'Roľnícka 10, 83107 Bratislava, Slovenská republika'
        digest[:date_start].should == Date.new(2006,05,31)
        digest[:date_end].should == Date.new(2008,04,14)
        digest[:date_liquidation].should == Date.new(2007,12,15)
        digest[:date_registration].should == Date.new(2006,05,31)
        digest[:objective].should == 'Podpora zdravia a liečby detí a mládeže  hippoterapiou, podpora jazdeckého a dostihového športu, jazdeckej turistiky a ďalších oblastí športových, liečebných s využitím koní, podpora chovu arabských koní ako ohrozeného druhu, propagácia a rozvoj chovu.'
        digest[:assets_currency].should == 'SKK'
        digest[:assets_value].should == 200000.0
        digest[:url].should == 'http://www.ives.sk/registre/detailrnd.do?action=uplny&formular=&id=158823&locale=sk'
      end
    end

    it 'return foundation hash - without date_end' do
      @extractor = Etl::FoundationExtraction.new(158264)
      VCR.use_cassette('etl/foundation_extraction/foundation_158264') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ives_id].should == 158264
        digest[:date_end].should be_nil
      end
    end

    it 'return foundation hash - without date_liquidation' do
      @extractor = Etl::FoundationExtraction.new(158785)
      VCR.use_cassette('etl/foundation_extraction/foundation_158785') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:date_liquidation].should be_nil
        digest[:ives_id].should == 158785
      end
    end

    it 'return foundation hash - with other currency' do
      @extractor = Etl::FoundationExtraction.new(158785)
      VCR.use_cassette('etl/foundation_extraction/foundation_158785') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:assets_currency].should == 'EUR'
      end
    end

    it 'return foundation hash - with decimal assets' do
      @extractor = Etl::FoundationExtraction.new(158264)
      VCR.use_cassette('etl/foundation_extraction/foundation_158264') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:assets_value].should == 8692.69
      end
    end

    it 'return foundation hash - without assets' do
      @extractor = Etl::FoundationExtraction.new(158309)
      VCR.use_cassette('etl/foundation_extraction/foundation_158309') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:assets_value].should == nil
        digest[:assets_currency].should == nil
      end
    end

    it 'return foundation hash - multiple founders' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_founders_attributes].count.should == 5
        digest[:ds_foundation_founders_attributes].first.should == {
          name: 'Ing. Ján Lalik',
          address: 'Brnianska 15, 81104 Bratislava',
          identification_number: '',
          contribution_value: 40000.0,
          contribution_currency: 'SKK',
          contribution_subject: 'Peňažné prostriedky'
        }
      end
    end

    it 'return foundation hash - founder with identification_number' do
      @extractor = Etl::FoundationExtraction.new(158264)
      VCR.use_cassette('etl/foundation_extraction/foundation_158264') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_founders_attributes].count.should == 1
        digest[:ds_foundation_founders_attributes].first.should == {
          name: 'Čabelkova nadácia',
          address: 'Račianska 71, 83259 Bratislava',
          identification_number: '30804370',
          contribution_value: 8692.69,
          contribution_currency: 'EUR',
          contribution_subject: 'Peňažné prostriedky'
        }
      end
    end

    it 'return foundation hash - founder without contribution' do
      @extractor = Etl::FoundationExtraction.new(158309)
      VCR.use_cassette('etl/foundation_extraction/foundation_158309') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_founders_attributes].count.should == 1
        founder = digest[:ds_foundation_founders_attributes].first
        founder[:contribution_value].should be_nil
        founder[:contribution_currency].should be_nil
        founder[:contribution_subject].should be_blank
      end
    end

    it 'return foundation hash - with trustee' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_trustees_attributes].count.should == 1
        digest[:ds_foundation_trustees_attributes].first.should == {
          name: 'Katarína Liptáková',
          address: 'Kaplínska 10, 83106 Bratislava',
          trustee_from: Date.new(2006,05,31),
          trustee_to: Date.new(2007,12,15)
        }
      end
    end

    it 'return foundation hash - multiple trustees' do
      @extractor = Etl::FoundationExtraction.new(158785)
      VCR.use_cassette('etl/foundation_extraction/foundation_158785') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_trustees_attributes].count.should == 2
        digest[:ds_foundation_trustees_attributes].first.should == {
          name: 'doc. JUDr.  Július Kováč, CSc.',
          address: 'H. Meličkovej 14, 84105 Bratislava',
          trustee_from: Date.new(2005,03,29),
          trustee_to: Date.new(2007,01,11)
        }
        digest[:ds_foundation_trustees_attributes].last.should == {
          name: 'Ing. Oľga Koňuchová',
          address: 'Ondavská 2, 82108 Bratislava',
          trustee_from: Date.new(2007,01,11),
          trustee_to: nil
        }
      end
    end

    it 'return foundation hash - with liquidator' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_liquidators_attributes].count.should == 1
        digest[:ds_foundation_liquidators_attributes].first.should == {
          name: 'Ing. Andrej Lipták',
          address: 'Roľnícka 10, 83107 Bratislava',
          liquidator_from: Date.new(2007,12,15),
          liquidator_to: Date.new(2008,04,14)
        }
      end
    end

    it 'return foundation hash - with liquidator without liquidator_to' do
      @extractor = Etl::FoundationExtraction.new(158264)
      VCR.use_cassette('etl/foundation_extraction/foundation_158264') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        digest[:ds_foundation_liquidators_attributes].count.should == 1
        digest[:ds_foundation_liquidators_attributes].first.should == {
          name: 'Ing. Ľuboš Mráz, CSc.',
          address: 'Sládkovičova 345, 90101 Malacky',
          liquidator_from: Date.new(2003,01,01),
          liquidator_to: nil
        }
      end
    end
  end

  describe '#save', slow_db: true do

    before(:each) do
      initialize_datasets( ['foundations', 'foundation_founders', 'foundation_trustees', 'foundation_liquidators'],
                           [
                               ['foundations','foundation_founders'], ['foundation_founders','foundations'],
                               ['foundations','foundation_trustees'], ['foundation_trustees','foundations'],
                               ['foundations','foundation_liquidators'], ['foundation_liquidators','foundations']
                           ]
      )
    end

    it 'save all attributes' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        @extractor.save digest

        # Foundation
        Dataset::DsFoundation.count.should == 1
        foundation = Dataset::DsFoundation.first
        foundation.ives_id.should == 158823
        foundation.name.should include('NADÁCIA EQUUS ARABIUS')
        foundation.identification_number.should == '30864399'
        foundation.registration_number.should == '203/Na-2002/839'
        foundation.address.should == 'Roľnícka 10, 83107 Bratislava, Slovenská republika'
        foundation.date_start.should == Date.new(2006,05,31)
        foundation.date_end.should == Date.new(2008,04,14)
        foundation.date_liquidation.should == Date.new(2007,12,15)
        foundation.date_registration.should == Date.new(2006,05,31)
        foundation.objective.should == 'Podpora zdravia a liečby detí a mládeže  hippoterapiou, podpora jazdeckého a dostihového športu, jazdeckej turistiky a ďalších oblastí športových, liečebných s využitím koní, podpora chovu arabských koní ako ohrozeného druhu, propagácia a rozvoj chovu.'
        foundation.assets_currency.should == 'SKK'
        foundation.assets_value.should == 200000.0
        foundation.url.should == 'http://www.ives.sk/registre/detailrnd.do?action=uplny&formular=&id=158823&locale=sk'
      end
    end

    it 'save founders' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        @extractor.save digest

        foundation = Dataset::DsFoundation.first

        # Founders
        foundation.ds_foundation_founders.count.should == 5
        founder = foundation.ds_foundation_founders.first
        founder.name.should == 'Ing. Ján Lalik'
        founder.address.should == 'Brnianska 15, 81104 Bratislava'
        founder.contribution_value.should == 40000.0
        founder.contribution_currency.should == 'SKK'
        founder.contribution_subject.should == 'Peňažné prostriedky'
      end
    end

    it 'save trustees' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        @extractor.save digest

        foundation = Dataset::DsFoundation.first

        # Trustees
        foundation.ds_foundation_trustees.count.should == 1
        trustee = foundation.ds_foundation_trustees.first
        trustee.name.should == 'Katarína Liptáková'
        trustee.address.should == 'Kaplínska 10, 83106 Bratislava'
        trustee.trustee_from.should ==  Date.new(2006,05,31)
        trustee.trustee_to.should == Date.new(2007,12,15)
      end
    end

    it 'save liquidators' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        @extractor.save digest

        foundation = Dataset::DsFoundation.first

        # Liquidators
        foundation.ds_foundation_liquidators.count.should == 1
        liquidator = foundation.ds_foundation_liquidators.first
        liquidator.name.should == 'Ing. Andrej Lipták'
        liquidator.address.should == 'Roľnícka 10, 83107 Bratislava'
        liquidator.liquidator_from.should == Date.new(2007,12,15)
        liquidator.liquidator_to.should == Date.new(2008,04,14)
      end
    end

    it 'multiple save' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        doc = @extractor.download
        digest = @extractor.digest(doc)
        @extractor.save digest
        digest = @extractor.digest(doc)
        @extractor.save digest

        # Foundation
        Dataset::DsFoundation.count.should == 1
        foundation = Dataset::DsFoundation.first
        foundation.ds_foundation_liquidators.count.should == 1
        foundation.ds_foundation_trustees.count.should == 1
        foundation.ds_foundation_founders.count.should == 5
      end
    end
  end

  describe '#perform' do
    it 'download and save' do
      VCR.use_cassette('etl/foundation_extraction/foundation_158823') do
        @extractor.perform.should be_true
        Dataset::DsFoundation.count.should == 1
      end
    end
  end

end
