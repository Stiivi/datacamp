# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Etl::VvoExtractionV2 do

  # documents and attributes
  all_document_types_and_formats = [121890, 121895, 121896, 121898, 121902, 121904, 121914, 121935, 121938, 121945, 121947, 121966, 121973, 121987, 121996, 122091, 122303, 122382, 122391, 122520, 123888, 124203, 125254, 125359, 126599, 135172, 140426, 185477, 185480, 185481, 185503, 185508, 185547, 185583, 185619, 185654, 185702, 185892, 185909, 185927, 186041, 186086, 186194, 187046, 187656, 188318, 188666, 188964, 194287, 198340, 198751, 202431, 226115, 237445, 238166, 238715]
  required_attributes = {
      basic_information: [:procurement_code, :bulletin_code, :year, :procurement_type, :published_on],
      customer_information: {
          notice: [:customer_name, :customer_organisation_code, :customer_address, :customer_place, :customer_zip, :customer_country, :customer_contact_persons, :customer_type, :customer_purchase_for_others, :customer_main_activity, :customer_phone],
          performance: [:customer_name, :customer_organisation_code, :customer_address, :customer_place, :customer_zip, :customer_country, :customer_contact_persons, :customer_phone]
      },
      contract_information: {
          notice: [:project_name, :project_type, :project_category, :place_of_performance, :nuts_code, :project_description, :general_contract, :dictionary_main_subjects, :gpa_agreement],
          performance: []
      },
      procedure_information: {
          notice: [:procedure_type, :procedure_offers_criteria, :procedure_use_auction, :previous_notification1_number, :previous_notification2_number, :previous_notification3_number, :previous_notification1_published_on, :previous_notification2_published_on, :previous_notification3_published_on],
          performance: []
      },
      supplier_information: {
          notice: [:supplier_name, :supplier_organisation_code, :supplier_address, :supplier_place, :supplier_zip, :supplier_country],
          performance: []
      },
      additional_information: {
          notice: [:procurement_euro_found, :evaluation_committee],
          performance: []
      }
  }
  allowed_nil_attributes_in_documents = {
      customer_type: [188318, 185583, 202431, 185583, 125359, 124203, 123888],
      customer_purchase_for_others: [125359, 124203, 123888, 122303],
      project_type: [187656, 122303],
      project_category: [187656, 237445, 238715, 122303],
      place_of_performance: [187656, 122303],
      nuts_code: [187656, 122303],
      gpa_agreement: [121898, 121890, 121902, 121914, 121935, 121947, 126599, 121973, 121966, 122391, 122303, 122382, 238715, 238166, 237445, 226115, 187656, 187046, 185892, 185702, 186041, 185909, 185619, 185508, 185480, 185477],
      general_contract: [122303, 238715, 238166, 237445, 226115, 202431, 198751, 198340, 188666, 188318, 187656, 187046, 186194, 186041, 185927, 185702, 185654, 185547, 185508, 185503, 185477],
      supplier_zip: [135172],
      supplier_place: [135172],
      supplier_organisation_code: [135172]
  }
  allowed_blank_attributes_in_documents = {
      customer_contact_persons: [121902]
  }
  # bool attributes
  not_check_blank_attributes = [:customer_purchase_for_others, :gpa_agreement, :general_contract]

  before :all do
    @extractor_example = Etl::VvoExtractionV2.new(185508)
    @extractor_format2 = Etl::VvoExtractionV2.new(121914)
  end

  describe '#initialize' do
    it 'should successfully init an instance' do
      @extractor_example.document_id.should == 185508
    end
  end

  describe '#download' do
    it 'should download a document' do
      VCR.use_cassette('vvo_185508') do
        @extractor_example.download.should_not be_nil
      end
    end
  end

  describe '#document_url' do
    it 'should return a correctly formatted document url' do
      @extractor_example.document_url.should == "http://www.uvo.gov.sk/sk/evestnik/-/vestnik/185508"
    end
  end

  describe '#document_format' do
    it 'should return format1' do
      VCR.use_cassette('vvo_185508') do
        @extractor_example.document_format.should == :format1
      end
    end

    it 'should return format2' do
      VCR.use_cassette('vvo_121914') do
        @extractor_format2.document_format.should == :format2
      end
    end
  end

  # Document type
  describe '#document_type' do
    it 'should return VSP from format2' do
      VCR.use_cassette('vvo_185508') do
        @extractor_example.document_type.should == 'VSP'
      end
    end

    it 'should return VSP from format2' do
      VCR.use_cassette('vvo_121914') do
        @extractor_format2.document_type.should == 'VSP'
      end
    end
  end

  # Is acceptable
  describe '#is_acceptable?' do
    it 'should accept document with type VSP' do
      VCR.use_cassette('vvo_185508') do
        @extractor_example.is_acceptable?.should be_true
      end
    end

    it 'should not accept document with type M' do
      VCR.use_cassette('vvo_275792') do
        extractor = Etl::VvoExtractionV2.new(275792)
        extractor.is_acceptable?.should be_false
      end
    end

  end

  # Basic information
  describe '#basic_information' do
    it 'should get basic information from a document - VSP - format1' do
      VCR.use_cassette('vvo_185508') do
        extractor = Etl::VvoExtractionV2.new(185508)
        extractor.basic_information.should == {procurement_code: "12686 - VSP", bulletin_code: 204, year: 2012, procurement_type: 'VSP', published_on: Date.new(2012, 10, 24)}
      end
    end
    it 'should get basic information from a document - VSP - format2' do
      VCR.use_cassette('vvo_121914') do
        extractor = Etl::VvoExtractionV2.new(121914)
        extractor.basic_information.should == {:procurement_code => "00009 - VSP", :bulletin_code => 2, :year => 2009, procurement_type: 'VSP', published_on: Date.new(2009, 1, 9)}
      end
    end
    it 'should get basic information from a document - VSS - format1' do
      VCR.use_cassette('vvo_185480') do
        extractor = Etl::VvoExtractionV2.new(185480)
        extractor.basic_information.should == {:procurement_code => "12685 - VSS", :bulletin_code => 204, :year => 2012, procurement_type: 'VSS', published_on: Date.new(2012, 10, 24)}
      end
    end
    it 'should get basic information from a document - VST - format1' do
      VCR.use_cassette('vvo_185477') do
        extractor = Etl::VvoExtractionV2.new(185477)
        extractor.basic_information[:procurement_type].should == 'VST'
      end
    end
    all_document_types_and_formats.each do |document_id|
      it "should get all basic information for document #{document_id}" do
        VCR.use_cassette("vvo_#{document_id}") do
          extractor = Etl::VvoExtractionV2.new(document_id)
          basic_information = extractor.basic_information
          required_attributes[:basic_information].each do |attribute|
            basic_information[attribute].should_not be_nil
            basic_information[attribute].should_not be_blank
          end
        end
      end
    end
  end

  # header_procedure_and_project_information
  describe '#header_procedure_and_project_information' do
    it 'should get header_procedure_and_project information from a document - VDP - format1' do
      VCR.use_cassette('vvo_198751') do
        extractor = Etl::VvoExtractionV2.new(198751)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Súťažný dialóg",
            project_type: "Stavebné práce"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VDT - format1' do
      VCR.use_cassette('vvo_198340') do
        extractor = Etl::VvoExtractionV2.new(198340)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Súťažný dialóg",
            project_type: "Tovary"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VUP - format1' do
      VCR.use_cassette('vvo_186041') do
        extractor = Etl::VvoExtractionV2.new(186041)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Užšia súťaž",
            project_type: "Stavebné práce"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VBS - format1' do
      VCR.use_cassette('vvo_185654') do
        extractor = Etl::VvoExtractionV2.new(185654)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Rokovacie konanie bez zverejnenia",
            project_type: "Služby"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VSS - format1' do
      VCR.use_cassette('vvo_185480') do
        extractor = Etl::VvoExtractionV2.new(185480)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Verejná súťaž",
            project_type: "Služby"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - IZP - format1' do
      VCR.use_cassette('vvo_188964') do
        extractor = Etl::VvoExtractionV2.new(188964)
        extractor.header_procedure_and_project_information.should == {project_type: "Práce"}
      end
    end
    it 'should get header_procedure_and_project information from a document - IZS - format1' do
      VCR.use_cassette('vvo_186086') do
        extractor = Etl::VvoExtractionV2.new(186086)
        extractor.header_procedure_and_project_information.should == {project_type: "Služby"}
      end
    end
    it 'should get header_procedure_and_project information from a document - IZT - format1' do
      VCR.use_cassette('vvo_185481') do
        extractor = Etl::VvoExtractionV2.new(185481)
        extractor.header_procedure_and_project_information.should == {project_type: "Tovary"}
      end
    end
    it 'should get empty header_procedure_and_project information from a document - VZT - format1' do
      VCR.use_cassette('vvo_185619') do
        extractor = Etl::VvoExtractionV2.new(185619)
        extractor.header_procedure_and_project_information.should == {}
      end
    end
    it 'should get header_procedure_and_project information from a document - VST - format2' do
      VCR.use_cassette('vvo_121935') do
        extractor = Etl::VvoExtractionV2.new(121935)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Verejná súťaž",
            project_type: "Tovary"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VBP - format2' do
      VCR.use_cassette('vvo_121966') do
        extractor = Etl::VvoExtractionV2.new(121966)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Rokovacie konanie bez zverejnenia",
            project_type: "Stavebné práce"
        }
      end
    end
    it 'should get header_procedure_and_project information from a document - VZT - format2' do
      VCR.use_cassette('vvo_121947') do
        extractor = Etl::VvoExtractionV2.new(121947)
        extractor.header_procedure_and_project_information.should == {project_type: "Tovary"}
      end
    end
    it 'should get header_procedure_and_project information from a document - VST - format2' do
      VCR.use_cassette('vvo_121935') do
        extractor = Etl::VvoExtractionV2.new(121935)
        extractor.header_procedure_and_project_information.should == {
            procedure_type: "Verejná súťaž",
            project_type: "Tovary"
        }
      end
    end

    all_document_types_and_formats.each do |document_id|
      it "should get header_procedure_and_project information for #{document_id} document" do
        VCR.use_cassette("vvo_#{document_id}") do
          extractor = Etl::VvoExtractionV2.new(document_id)
          extractor.header_procedure_and_project_information.should_not be_nil
        end
      end
    end
  end

  # Customer information
  describe '#customer_information' do
    it 'should get customer information from a document - VZP - format1' do
      VCR.use_cassette('vvo_185702') do
        extractor = Etl::VvoExtractionV2.new(185702)
        extractor.customer_information.should == {
            customer_name: 'Nitriansky samosprávny kraj',
            customer_organisation_code: '37861298',
            customer_address: 'Štefánikova 69',
            customer_place: 'Nitra',
            customer_zip: '94901',
            customer_country: 'Slovensko',
            customer_contact_persons: 'Ing. Daniela Kopperová',
            customer_phone: '+421 376925903',
            customer_email: 'daniela.kopperova@unsk.sk',
            customer_fax: '+421 376925922',
            customer_type: 'Regionálna alebo miestna agentúra/úrad',
            customer_main_activity: 'Životné prostredie',
            customer_purchase_for_others: false
        }
      end
    end
    it 'should get customer information from a document - VZP - format2' do
      VCR.use_cassette('vvo_122391') do
        extractor = Etl::VvoExtractionV2.new(122391)
        extractor.customer_information.should == {
            customer_name: 'Mesto Žiar nad Hronom',
            customer_organisation_code: '00321125',
            customer_address: 'Š. Moyzesa 46',
            customer_zip: '96519',
            customer_place: 'Žiar nad Hronom',
            customer_country: 'Slovenská republika',
            customer_contact_persons: 'Ing. Blažena Kollárová',
            customer_phone: '045 678 71 48',
            customer_fax: '045 678 71 55',
            customer_email: 'blazena.kollarova@ziar.sk',
            customer_type: 'Iný verejný obstarávateľ',
            customer_main_activity: 'Iný predmet činnosti',
            customer_purchase_for_others: false
        }
      end
    end
    it 'should get customer information from a document - VSS - format1' do
      VCR.use_cassette('vvo_266857') do
        extractor = Etl::VvoExtractionV2.new(266857)
        customer_information = extractor.customer_information
        customer_information[:customer_organisation_code].should == '31819494'
        customer_information[:customer_mobile].should == '+421 949096444'
        customer_information[:customer_type].should == 'Štátna agentúra/úrad'
        customer_information[:customer_main_activity].should == 'Všeobecné verejné služby'
      end
    end
    it 'should get customer organisation_code from document' do
      VCR.use_cassette('vvo_274037') do
        extractor = Etl::VvoExtractionV2.new(274037)
        extractor.customer_information[:customer_organisation_code].should == '00165549'
      end
    end

    it 'should get customer information from a document - VSS' do
      VCR.use_cassette('vvo_156855') do
        extractor = Etl::VvoExtractionV2.new(156855)
        customer_information = extractor.customer_information
        customer_information[:customer_type].should == 'Ministerstvo alebo iný štátny orgán vrátane jeho regionálnych alebo miestnych útvarov'
        customer_information[:customer_main_activity].should == 'Všeobecná štátna správa'
        customer_information[:customer_purchase_for_others].should == false
      end
    end

    # Tests in all documents formats for not nil and blank attributes
    all_document_types_and_formats.each do |document_id|
      VCR.use_cassette("vvo_#{document_id}") do
        extractor = Etl::VvoExtractionV2.new(document_id)
        customer_information = extractor.customer_information
        dataset_type = extractor.dataset_type
        required_attributes[:customer_information][dataset_type].each do |attribute|
          # test when not in excluded nil attributes
          if allowed_nil_attributes_in_documents.exclude?(attribute) || allowed_nil_attributes_in_documents[attribute].exclude?(document_id)
            it "should have not nil attribute #{attribute} in customer information for document #{document_id}" do
              customer_information[attribute].should_not be_nil
            end
            # test when check attribute and not in excluded blank attributes
            if not_check_blank_attributes.exclude?(attribute) && (allowed_blank_attributes_in_documents.exclude?(attribute) || allowed_blank_attributes_in_documents[attribute].exclude?(document_id))
              it "should have not blank attribute: #{attribute} in customer information for document #{document_id}" do
                customer_information[attribute].should_not be_blank
              end
            end
          end
        end
      end
    end
  end

  # Contract information
  describe '#contract_information' do
    # Format 1
    it 'should get contract information from a document - VZS - format1' do
      VCR.use_cassette('vvo_185547') do
        extractor = Etl::VvoExtractionV2.new(185547)
        extractor.contract_information.should == {
            project_name: 'Zabezpečenie poskytovania stravovania pre zamestnancov colnej správy formou stravných poukážok',
            project_type: 'Služby',
            project_category: '17',
            place_of_performance: 'Miestami dodania stravných poukážok sú: Colné riaditeľstvo SR, Mierová 23, 815 11 Bratislava, Colný kriminálny úrad, Bajkalská 24, 824 97 Bratislava, Colný úrad, Banská Bystrica, Partizánska cesta 17, 975 90 Banská Bystrica, Colný úrad, Bratislava, Miletičova 42, 824 59 Bratislava, Colný úrad, Michalovce, Plynárenská 4, 071 01 Michalovce, Colný úrad, Košice, Jiskrova 5, 040 02 Košice, Colný úrad, Nitra, Rázusova 2A, 950 50 Nitra, Colný úrad, Prešov, Kpt. Nálepku 4, 080 01 Prešov, Colný úrad, Trenčín, Partizánska 1, 911 50 Trenčín, Colný úrad, Trnava, Továrenská 532/20, 905 01 Senica, Colný úrad, Žilina, Pri cintoríne 36, 010 04 Žilina. Miestami poskytovania stravovania sú zmluvné stravovacie zariadenia uchádzača na Slovensku akceptujúce stravné poukážky uchádzača v lokalitách nasledujúcich miest: Bratislava, Senica, Trenčín, Žilina, Nitra, Komárno, Košice, Banská Bystrica, Lučenec, Prešov, Poprad, Zvolen, Jesenské, Veľký Krtíš, Malacky, Senec, Michalovce, Čierna nad Tisou, Veľké Kapušany, Kráľovský Chlmec, Snina, Uľba, Trebišov, Krčava, Rožňava, Jablonov nad Turňou, Spišská Nová Ves, Levoča, Šahy, Levice, Nové Zámky, Štúrovo, Topoľčany, Bardejov, Humenné, Svidník, Stará Ľubovňa, Kežmarok, Púchov, Prievidza, Bánovce nad Bebravou, Ilava, Nové Mesto nad Váhom, Považská Bystrica, Skalica, Kúty, Trnava, Hlohovec, Leopoldov, Galanta, Piešťany, Veľký Meder, Dunajská Streda, Šamorín, Čadca, Martin, Ružomberok, Liptovský Mikuláš, Dolný Kubín, Trstená, Námestovo.',
            nuts_code: 'SK0',
            project_description: 'Zabezpečenie poskytovania stravovania pre zamestnancov colnej správy v zmluvných stravovacích zariadeniach uchádzača na Slovensku na základe akceptovania stravných poukážok uchádzača.',
            dictionary_main_subjects: '55300000-3',
            gpa_agreement: false
        }
      end
    end
    it 'should get contract information from a document - IPS - format1' do
      VCR.use_cassette('vvo_238166') do
        extractor = Etl::VvoExtractionV2.new(238166)
        extractor.contract_information.should == {
            project_name: 'Oprava videogastroskopu PENTAX',
            project_type: 'Služby',
            project_category: '1',
            place_of_performance: 'Detská fakultná nemocnica Košice, Tr. SNP č. 1, Košice 040 11',
            nuts_code: 'SK042',
            project_description: 'Opravu prístroja bolo potrebné vykonať čo najskôr, aby sa zabezpečilo plynulé poskytovanie zdravotnej starostlivosti pre pacientov z celého východoslovenského regiónu. Počas obhliadky videogastroskopu PENTAX zistil servisný technik viac chýb, ktoré nie je rentabilné odstraňovať po častiach, aj z technického hľadiska by parciálne opravy mohli zapríčiniť devastačné poškodenie ďalších dielov. Predmetom zákazky bola generálna oprava prístroja.',
            dictionary_main_subjects: '50421000-2'
        }
      end
    end
    it 'should get contract information from a document - VZP - format1' do
      VCR.use_cassette('vvo_185702') do
        extractor = Etl::VvoExtractionV2.new(185702)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Stavebné práce'
        contract_information[:project_category].should == 'Uskutočnenie prác'
      end
    end

    it 'should get contract information from a document - VUT - format1' do
      VCR.use_cassette('vvo_185909') do
        extractor = Etl::VvoExtractionV2.new(185909)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Tovary'
        contract_information[:project_category].should == 'Kúpa'
        contract_information[:place_of_performance].should == 'Vojenský útvar 5728 Nováky, resp. iné organizačné útvary a zariadenia rezortu Ministerstva obrany SR.'
        contract_information[:nuts_code].should == 'SK'
      end
    end

    it 'should get contract information from a document - VKS - format1' do
      VCR.use_cassette('vvo_226115') do
        extractor = Etl::VvoExtractionV2.new(226115)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Služby'
        contract_information[:project_category].should == '17'
        contract_information[:place_of_performance].should == 'Fakultná nemocnica s poliklinikou F. D. Roosevelta Banská Bystrica, Nám. L. Svobodu 1, Banská Bystrica'
        contract_information[:nuts_code].should == 'SK032'
      end
    end

    it 'should get contract information from a document - VKS - format1' do
      VCR.use_cassette('vvo_237445') do
        extractor = Etl::VvoExtractionV2.new(237445)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Práce'
      end
    end

    it 'should get contract information from a document - VUS - format1' do
      VCR.use_cassette('vvo_185503') do
        extractor = Etl::VvoExtractionV2.new(185503)
        contract_information = extractor.contract_information
        contract_information[:dictionary_main_subjects].should == '72222300-0'
        contract_information[:dictionary_additional_subjects].should == '72212000-4, 72310000-1, 48000000-8, 30210000-4'
        contract_information[:gpa_agreement].should == true
      end
    end

    it 'should get contract information from a document - VEP - format1' do
      VCR.use_cassette('vvo_202431') do
        extractor = Etl::VvoExtractionV2.new(202431)
        contract_information = extractor.contract_information
        contract_information[:gpa_agreement].should == false
      end
    end

    it 'should get contract information from a document - VZT - format1' do
      VCR.use_cassette('vvo_185619') do
        extractor = Etl::VvoExtractionV2.new(185619)
        contract_information = extractor.contract_information
        contract_information[:general_contract].should == true
      end
    end

    it 'should get empty contract information from a document - IZP - format1' do
      VCR.use_cassette('vvo_188964') do
        extractor = Etl::VvoExtractionV2.new(188964)
        extractor.contract_information.should == {}
      end
    end

    # Format 2

    it 'should get contract information from a document - VZS - format2' do
      VCR.use_cassette('vvo_121973') do
        extractor = Etl::VvoExtractionV2.new(121973)
        extractor.contract_information.should == {
            project_name: 'Vyhotovovanie geodetických prác pre potreby RO SPF',
            project_type: 'Služby',
            project_category: '12',
            place_of_performance: 'Slovenská republika',
            nuts_code: 'SK0',
            project_description: 'Vyhotovovanie rôznych geodetických prác.',
            dictionary_main_subjects: '71354300-7',
            general_contract: false
        }
      end
    end
    it 'should get customer information from a document - VUT - format2' do
      VCR.use_cassette('vvo_122520') do
        extractor = Etl::VvoExtractionV2.new(122520)
        extractor.contract_information.should == {
            project_name: 'Kity, chemikálie a biologický materiál pre biologický výskum, zameraný na bunkovú biológiu a virológiu',
            project_type: 'Tovary',
            project_category: 'Kúpa',
            place_of_performance: 'Virologický ústav SAV, Dúbravská cesta 9, 845 05 Bratislava',
            nuts_code: 'SK01',
            general_contract: true,
            gpa_agreement: false,
            project_description: 'Reagencie vysokej kvality, čistoty vhodné pre tkanivové kultúry, analýzu a izoláciu bunkových komponentov a ostatných biomakromolekúl.',
            dictionary_main_subjects: '24327000-2'
        }
      end
    end

    it 'should get customer information from a document - VNS - format2' do
      VCR.use_cassette('vvo_121902') do
        extractor = Etl::VvoExtractionV2.new(121902)
        extractor.contract_information.should == {
            project_name: 'Obsluha tepelnotechnických zariadení',
            project_type: 'Služby',
            project_category: '27',
            place_of_performance: 'Moldava nad Bodvou, Košice, Veľká Ida',
            nuts_code: 'SK042',
            general_contract: true,
            project_description: 'Obsluha tepelnotechnických zariadení.',
            dictionary_main_subjects: '98390000-3'
        }
      end
    end

    it 'should get project type and category (contract information) from a document - VZT - format2' do
      VCR.use_cassette('vvo_121947') do
        extractor = Etl::VvoExtractionV2.new(121947)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Tovary'
        contract_information[:project_category].should == 'Kúpa'
      end
    end

    it 'should get project type and category (contract information) from a document - VZP - format2' do
      VCR.use_cassette('vvo_122391') do
        extractor = Etl::VvoExtractionV2.new(122391)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Stavebné práce'
        contract_information[:project_category].should == 'Uskutočňovanie stavebných prác'
      end
    end

    it 'should get project type and category (contract information) from a document - VSS - format2' do
      VCR.use_cassette('vvo_121945') do
        extractor = Etl::VvoExtractionV2.new(121945)
        contract_information = extractor.contract_information
        contract_information[:project_type].should == 'Služby'
        contract_information[:project_category].should == '14'
      end
    end

    it 'should get subjects in contract information from a document - VZP - format2' do
      VCR.use_cassette('vvo_122391') do
        extractor = Etl::VvoExtractionV2.new(122391)
        contract_information = extractor.contract_information
        contract_information[:dictionary_main_subjects].should == '45000000-7, IA13-5'
        contract_information[:dictionary_additional_subjects].should == '45262520-2, 45431200-9, 45421100-5, 45432112-2'
      end
    end

    it 'should get subjects in contract information from a document - VBP - format2' do
      VCR.use_cassette('vvo_121966') do
        extractor = Etl::VvoExtractionV2.new(121966)
        contract_information = extractor.contract_information
        contract_information[:dictionary_main_subjects].should == '71320000-7'
        contract_information[:dictionary_additional_subjects].should == '33162000-3'
      end
    end

    it 'should get gpa_agreement in contract information from a document - VSS - format2' do
      VCR.use_cassette('vvo_121945') do
        extractor = Etl::VvoExtractionV2.new(121945)
        contract_information = extractor.contract_information
        contract_information[:gpa_agreement].should == false
      end
    end

    it 'should get general_contract in contract information from a document - VZP - format2' do
      VCR.use_cassette('vvo_122391') do
        extractor = Etl::VvoExtractionV2.new(122391)
        contract_information = extractor.contract_information
        contract_information[:general_contract].should == false
      end
    end

    it 'should get empty contract information) from a document - IDP - format2' do
      VCR.use_cassette('vvo_121996') do
        extractor = Etl::VvoExtractionV2.new(121996)
        extractor.contract_information.should == {}
      end
    end

    # Tests in all documents formats for not nil and blank attributes
    all_document_types_and_formats.each do |document_id|
      VCR.use_cassette("vvo_#{document_id}") do
        extractor = Etl::VvoExtractionV2.new(document_id)
        contract_information = extractor.contract_information
        dataset_type = extractor.dataset_type
        required_attributes[:contract_information][dataset_type].each do |attribute|
          # test when not in excluded nil attributes
          if allowed_nil_attributes_in_documents.exclude?(attribute) || allowed_nil_attributes_in_documents[attribute].exclude?(document_id)
            it "should have not nil attribute: #{attribute} in contract information for document #{document_id}" do
              contract_information[attribute].should_not be_nil
            end
            # test when checked attribute and not in excluded blank attributes
            if not_check_blank_attributes.exclude?(attribute) && (allowed_blank_attributes_in_documents.exclude?(attribute) || allowed_blank_attributes_in_documents[attribute].exclude?(document_id))
              it "should have not blank attribute: #{attribute} in contract information for document #{document_id}" do
                contract_information[attribute].should_not be_blank
              end
            end
          end
        end
      end
    end
  end

  # Procedure information
  describe '#procedure_information' do
    # Format 1
    it 'should get procedure information from a document - VKS - format1' do
      VCR.use_cassette('vvo_226115') do
        extractor = Etl::VvoExtractionV2.new(226115)
        extractor.procedure_information.should == {
            procedure_type: 'Užšia súťaž',
            procedure_offers_criteria: 'Ekonomicky najvýhodnejšia ponuka z hľadiska, 1. I.1. cena za stravu pacientov - racionálna strava (vyjadrená v MJ/EUR s DPH) - 30, 2. I.2. cena za stravu pacientov - diabetická strava (vyjadrená v MJ/EUR s DPH) - 10, 3. I.3. cena za stravu pacientov - výživná strava (vyjadrená v MJ/EUR s DPH) - 10, 4. I.4. cena za stravu pacientov - strava s obmedzením tuku (vyjadrená v MJ/EUR s DPH) - 10, 5. I.5. cena za stravu pacientov - ostatné typy diét (vyjadrená v MJ/EUR s DPH) - 10, 6. I.6. cena za stravu zamestnancov (vyjadrená v MJ/EUR s DPH) - 30',
            procedure_use_auction: true,
            previous_notification1_number: '13422-KOS, VVO 215/2012',
            previous_notification1_published_on: Date.new(2012, 11, 9),
            previous_notification2_number: nil,
            previous_notification2_published_on: nil,
            previous_notification3_number: nil,
            previous_notification3_published_on: nil,
        }
      end
    end
    it 'should get procedure information from a document - VBP - format1' do
      VCR.use_cassette('vvo_185927') do
        extractor = Etl::VvoExtractionV2.new(185927)
        extractor.procedure_information.should == {
            procedure_type: 'Rokovacie konanie bez výzvy na súťaž',
            procedure_offers_criteria: 'Najnižšia cena',
            procedure_use_auction: false,
            previous_notification1_number: nil,
            previous_notification1_published_on: nil,
            previous_notification2_number: nil,
            previous_notification2_published_on: nil,
            previous_notification3_number: nil,
            previous_notification3_published_on: nil,
        }
      end
    end
    it 'should get procedure information from a document - VZP - format1' do
      VCR.use_cassette('vvo_185702') do
        extractor = Etl::VvoExtractionV2.new(185702)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should == '8168-MSP, VVO 135/2012'
        procedure_information[:previous_notification1_published_on].should == Date.new(2012, 7, 14)
      end
    end
    it 'should get procedure information from a document - VBS - format1' do
      VCR.use_cassette('vvo_185654') do
        extractor = Etl::VvoExtractionV2.new(185654)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should_not be_nil
        procedure_information[:previous_notification1_published_on].should_not be_nil
        procedure_information[:previous_notification2_number].should_not be_nil
        procedure_information[:previous_notification2_published_on].should_not be_nil
        procedure_information[:previous_notification3_number].should be_nil
        procedure_information[:previous_notification3_published_on].should be_nil
      end
    end
    it 'should get procedure information from a document - VDT - format1' do
      VCR.use_cassette('vvo_198340') do
        extractor = Etl::VvoExtractionV2.new(198340)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should_not be_nil
        procedure_information[:previous_notification1_published_on].should_not be_nil
        procedure_information[:previous_notification2_number].should_not be_nil
        procedure_information[:previous_notification2_published_on].should_not be_nil
        procedure_information[:previous_notification3_number].should_not be_nil
        procedure_information[:previous_notification3_published_on].should_not be_nil
      end
    end

    # Format 2

    it 'should get procedure information from a document - VBP - format2' do
      VCR.use_cassette('vvo_121966') do
        extractor = Etl::VvoExtractionV2.new(121966)
        extractor.procedure_information.should == {
            procedure_type: 'Rokovacie konanie bez zverejnenia',
            procedure_offers_criteria: 'Najnižšia cena',
            procedure_use_auction: false,
            previous_notification1_number: '03309-VSP, VVO 142/2008',
            previous_notification1_published_on: Date.new(2008, 7, 23),
            previous_notification2_number: nil,
            previous_notification2_published_on: nil,
            previous_notification3_number: nil,
            previous_notification3_published_on: nil,
        }
      end
    end
    it 'should get procedure information from a document - VBS - format2' do
      VCR.use_cassette('vvo_121898') do
        extractor = Etl::VvoExtractionV2.new(121898)
        extractor.procedure_information.should == {
            procedure_type: 'Rokovacie konanie bez zverejnenia',
            procedure_offers_criteria: 'Najnižšia cena',
            procedure_use_auction: false,
            previous_notification1_number: nil,
            previous_notification1_published_on: nil,
            previous_notification2_number: nil,
            previous_notification2_published_on: nil,
            previous_notification3_number: nil,
            previous_notification3_published_on: nil,
        }
      end
    end
    it 'should get procedure information from a document - VZT - format2' do
      VCR.use_cassette('vvo_121947') do
        extractor = Etl::VvoExtractionV2.new(121947)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should == '01257-MST, VVO 50/2008'
        procedure_information[:previous_notification1_published_on].should == Date.new(2008, 3, 11)
      end
    end
    it 'should get procedure information from a document - VUT - format2' do
      VCR.use_cassette('vvo_122520') do
        extractor = Etl::VvoExtractionV2.new(122520)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should == '2008/S 176-234429'
      end
    end
    it 'should get procedure information from a document - VZS - format2' do
      VCR.use_cassette('vvo_121973') do
        extractor = Etl::VvoExtractionV2.new(121973)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should_not be_nil
        procedure_information[:previous_notification1_published_on].should_not be_nil
        procedure_information[:previous_notification2_number].should_not be_nil
        procedure_information[:previous_notification2_published_on].should_not be_nil
        procedure_information[:previous_notification3_number].should be_nil
        procedure_information[:previous_notification3_published_on].should be_nil
      end
    end
    it 'should get procedure information from a document - VBS - format2' do
      VCR.use_cassette('vvo_121898') do
        extractor = Etl::VvoExtractionV2.new(121898)
        procedure_information = extractor.procedure_information
        procedure_information[:previous_notification1_number].should be_nil
        procedure_information[:previous_notification1_published_on].should be_nil
        procedure_information[:previous_notification2_number].should be_nil
        procedure_information[:previous_notification2_published_on].should be_nil
        procedure_information[:previous_notification3_number].should be_nil
        procedure_information[:previous_notification3_published_on].should be_nil
      end
    end
    all_document_types_and_formats.each do |document_id|
      it "should get procedure information for #{document_id} document" do
        VCR.use_cassette("vvo_#{document_id}") do
          extractor = Etl::VvoExtractionV2.new(document_id)
          extractor.procedure_information.should_not be_nil
        end
      end
    end
  end

  # Suppliers information
  describe '#suppliers_information' do
    # Format 1
    it 'should get supliers information from a document - VKS - format1' do
      VCR.use_cassette('vvo_238715') do
        extractor = Etl::VvoExtractionV2.new(238715)
        extractor.suppliers_information.should == {
            suppliers: [{
                            contract_date: Date.new(2014, 4, 3),
                            offers_total_count: 1,
                            offers_excluded_count: 0,
                            supplier_name: 'Siemens s.r.o.',
                            supplier_organisation_code: '31349307',
                            supplier_address: 'Lamačská cesta',
                            supplier_place: 'Bratislava-Karlova Ves',
                            supplier_zip: '84104',
                            supplier_country: 'Slovensko',
                            supplier_phone: '+421 911685855',
                            supplier_email: 'peter.brezina@siemens.com',
                            procurement_currency: 'EUR',
                            final_price_range: false,
                            final_price: 49678.0,
                            final_price_vat_included: false,
                            final_price_vat_rate: nil,
                        }]
        }
      end
    end
    it 'should get supliers information from a document - 191763 - format1' do
      VCR.use_cassette('vvo_191763') do
        extractor = Etl::VvoExtractionV2.new(191763)
        extractor.suppliers_information[:suppliers].count.should == 1
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:contract_name].should == 'ZoD č.12XK24001 zo dňa 10.12.2012 „ŽSR, Elektrifikácia trate Haniska – Veľká Ida – Moldava nad Bodvou mesto“ – projektová dokumentácia'
        supplier[:contract_date].should == Date.new(2012, 12, 10)
        supplier[:offers_total_count].should == 3
        supplier[:offers_online_count].should be_nil
        supplier[:offers_excluded_count].should be_nil
        supplier[:supplier_name].should == 'PRODEX spol. s.r.o.'
        supplier[:supplier_organisation_code].should == '17314569'
        supplier[:supplier_address].should == "Rusovská cesta 16"
        supplier[:supplier_place].should == "Bratislava 5"
        supplier[:supplier_zip].should == "85101"
        supplier[:supplier_country].should == "Slovensko"
        supplier[:supplier_phone].should == "+421 268202650"
        supplier[:supplier_fax].should == "+421 268202645"
        supplier[:supplier_mobile].should be_nil
        supplier[:supplier_email].should be_nil
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should == 865866.0
        supplier[:draft_price_vat_included].should == false
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price].should be_nil
        supplier[:final_price_range].should == true
        supplier[:final_price_min].should == 1996700.0
        supplier[:final_price_max].should == 2079000.0
        supplier[:final_price_vat_included].should == false
        supplier[:final_price_vat_rate].should be_nil
        supplier[:procurement_subcontracted].should == true
      end
    end
    it 'should get supliers information from a document - 185909 - format1' do
      VCR.use_cassette('vvo_185909') do
        extractor = Etl::VvoExtractionV2.new(185909)
        extractor.suppliers_information[:suppliers].count.should == 1
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:contract_name].should == 'Rámcová dohoda č. 2012/579'
        supplier[:contract_date].should == Date.new(2012, 10, 24)
        supplier[:offers_total_count].should == 5
        supplier[:offers_online_count].should == 0
        supplier[:offers_excluded_count].should be_nil
        supplier[:supplier_name].should == 'ZVS holding, a.s.'
        supplier[:supplier_organisation_code].should == '36305600'
        supplier[:supplier_email].should == "duris@zvsholding.sk"
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should == 1250000.0
        supplier[:draft_price_vat_included].should == false
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price_range].should == false
        supplier[:final_price].should == 1250000.0
        supplier[:final_price_min].should be_nil
        supplier[:final_price_max].should be_nil
        supplier[:final_price_vat_included].should == false
        supplier[:final_price_vat_rate].should be_nil
        supplier[:procurement_subcontracted].should == false
      end
    end
    it 'should get supliers information from a document - 185892 - format1' do
      VCR.use_cassette('vvo_185892') do
        extractor = Etl::VvoExtractionV2.new(185892)
        extractor.suppliers_information[:suppliers].count.should == 1
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:contract_name].should == 'čistopisy dokladov'
        supplier[:offers_total_count].should == 1
        supplier[:offers_online_count].should == 0
        supplier[:supplier_organisation_code].should == '81274661'
        supplier[:supplier_address].should == "Oranienstrasse 91"
        supplier[:supplier_place].should == "Berlin"
        supplier[:supplier_zip].should == "10969"
        supplier[:supplier_country].should == "Nemecko"
        supplier[:supplier_email].should == "thomas.morian@bdr.de"
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should be_nil
        supplier[:draft_price_vat_included].should be_nil
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price_range].should == false
        supplier[:final_price].should == 3509600.0
        supplier[:final_price_min].should be_nil
        supplier[:final_price_max].should be_nil
        supplier[:final_price_vat_included].should == false
        supplier[:final_price_vat_rate].should be_nil
        supplier[:procurement_subcontracted].should == false
      end
    end
    it 'should get supliers information from a document - 186041 - format1' do
      VCR.use_cassette('vvo_186041') do
        extractor = Etl::VvoExtractionV2.new(186041)
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should == 205324.0
        supplier[:draft_price_vat_included].should == false
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price_range].should == false
        supplier[:final_price].should == 171000.0
        supplier[:final_price_min].should be_nil
        supplier[:final_price_max].should be_nil
        supplier[:final_price_vat_included].should == true
        supplier[:final_price_vat_rate].should == 20.0
        supplier[:procurement_subcontracted].should == false
      end
    end
    it 'should get supliers information from a document - 238166 - format1' do
      VCR.use_cassette('vvo_238166') do
        extractor = Etl::VvoExtractionV2.new(238166)
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:offers_excluded_count].should == 0
        supplier[:final_price_range].should == false
        supplier[:final_price].should == 25341.6
        supplier[:final_price_vat_included].should == true
        supplier[:final_price_vat_rate].should == 20.0
        supplier[:procurement_subcontracted].should be_nil
      end
    end
    it 'should get supliers information from a document - 185892 - format1' do
      VCR.use_cassette('vvo_188666') do
        extractor = Etl::VvoExtractionV2.new(188666)
        extractor.suppliers_information[:suppliers].count.should == 3
        supplier1 = extractor.suppliers_information[:suppliers][0]
        supplier2 = extractor.suppliers_information[:suppliers][1]
        supplier3 = extractor.suppliers_information[:suppliers][2]
        supplier1[:contract_name].should == 'Zmluva o poskytnutí služieb za účelom optimalizácie nákladov na teplo a teplú úžitkovú vodu'
        supplier1[:supplier_organisation_code].should == '35702257'
        supplier2[:supplier_organisation_code].should == '36344869'
        supplier3[:supplier_organisation_code].should == '17325188'
        supplier1[:final_price].should == 31771.67
        supplier2[:final_price].should == 38200.0
        supplier3[:final_price].should == 34761.0
      end
    end

    # Format 2

    it 'should get supliers information from a document - 121966 - format2' do
      VCR.use_cassette('vvo_121966') do
        extractor = Etl::VvoExtractionV2.new(121966)
        extractor.suppliers_information.should == {
            suppliers: [{
                            contract_name: "OIV-2008_0295 Dodatok č. 3",
                            contract_date: Date.new(2008, 11, 5),
                            offers_total_count: 1,
                            supplier_name: 'SimKor, s. r. o.',
                            supplier_organisation_code: '36014354',
                            supplier_address: 'Ľ. Svobodu 26',
                            supplier_zip: '96901',
                            supplier_place: 'Banská Štiavnica',
                            supplier_country: 'Slovensko',
                            supplier_phone: '00421 45 694 91 11',
                            procurement_currency: 'EUR',
                            draft_price: 4481179.048,
                            draft_price_vat_included: false,
                            draft_price_vat_rate: nil,
                            final_price: 4532843.225,
                            final_price_range: false,
                            final_price_vat_included: false,
                            final_price_vat_rate: nil,
                            procurement_subcontracted: false
                        }]
        }
      end
    end
    it 'should get supliers information from a document - 122520 - format2' do
      VCR.use_cassette('vvo_122520') do
        extractor = Etl::VvoExtractionV2.new(122520)
        extractor.suppliers_information[:suppliers].count.should == 1
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:contract_name].should == 'Kity, chemikálie a biologický materiál pre biologický výskum, zameraný na bunkovú biológiu a virológiu'
        supplier[:contract_date].should == Date.new(2008, 12, 16)
        supplier[:offers_total_count].should == 1
        supplier[:supplier_name].should == 'Lambda Life, a. s.'
        supplier[:supplier_organisation_code].should == '35848189'
        supplier[:supplier_address].should == "Bojnická 20"
        supplier[:supplier_place].should == "Bratislava"
        supplier[:supplier_zip].should == "83104"
        supplier[:supplier_country].should == "Slovensko"
        supplier[:supplier_phone].should == "02 44 88 01 59 - 160"
        supplier[:supplier_fax].should == "02 44 88 01 65"
        supplier[:supplier_mobile].should be_nil
        supplier[:supplier_email].should == "granec.tomas@lambda.sk"
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should == 331939.19
        supplier[:draft_price_vat_included].should == false
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price].should == 331877.61
        supplier[:final_price_range].should == false
        supplier[:final_price_vat_included].should == false
        supplier[:final_price_vat_rate].should be_nil
        supplier[:procurement_subcontracted].should == false
      end
    end
    it 'should get supliers information from a document - 121947 - format2' do
      VCR.use_cassette('vvo_121947') do
        extractor = Etl::VvoExtractionV2.new(121947)
        extractor.suppliers_information[:suppliers].count.should == 1
        supplier = extractor.suppliers_information[:suppliers].first
        supplier[:contract_name].should == 'Audio a videotechnika'
        supplier[:contract_date].should == Date.new(2008, 11, 3)
        supplier[:offers_total_count].should == 2
        supplier[:supplier_name].should == 'AGE, s. r. o.'
        supplier[:supplier_organisation_code].should == '31106251'
        supplier[:supplier_email].should == "vo@age.sk"
        supplier[:procurement_currency].should == "EUR"
        supplier[:draft_price].should == 2210.05
        supplier[:draft_price_vat_included].should == false
        supplier[:draft_price_vat_rate].should be_nil
        supplier[:final_price_range].should == false
        supplier[:final_price].should == 2210.05
        supplier[:final_price_min].should be_nil
        supplier[:final_price_max].should be_nil
        supplier[:final_price_vat_included].should == true
        supplier[:final_price_vat_rate].should == 19.0
        supplier[:procurement_subcontracted].should == false
      end
    end

    it 'should get supliers information from a document - 123012 - format2' do
      VCR.use_cassette('vvo_123012') do
        extractor = Etl::VvoExtractionV2.new(123012)
        extractor.suppliers_information[:suppliers].count.should == 13

        supplier1 = extractor.suppliers_information[:suppliers][0]
        supplier1[:contract_name].should == 'Realizácia ťažbových prác v lokalite Bukovina'
        supplier1[:supplier_name].should == 'Jozef Repka'
        supplier1[:final_price].should == 63077.0

        supplier2 = extractor.suppliers_information[:suppliers][1]
        supplier2[:contract_name].should == "Realizácia ťažbových prác v lokalite Poruba"
        supplier2[:offers_total_count].should == 2
        supplier2[:final_price_min].should == 57000.0
        supplier2[:final_price_max].should == 65970.0
        supplier2[:final_price_range].should == true

        supplier11 = extractor.suppliers_information[:suppliers][10]
        supplier11[:contract_name].should == "Realizácia ťažbových prác v lokalite Kráľová"
        supplier11[:offers_total_count].should == 1
        supplier11[:final_price].should == 20303.0
      end
    end

    it 'should get supliers information from a document - 135172 - format1' do
      VCR.use_cassette('vvo_135172') do
        extractor = Etl::VvoExtractionV2.new(135172)
        extractor.suppliers_information[:suppliers].count.should == 2
        supplier1 = extractor.suppliers_information[:suppliers][0]
        supplier2 = extractor.suppliers_information[:suppliers][1]
        supplier1[:contract_name].should == 'Výroba, dodávka a montáž moderného symfonického koncertného organu s francúzskou charakteristikou'
        supplier1[:supplier_organisation_code].should == ''
        supplier1[:supplier_zip].should == ''
        supplier1[:supplier_place].should == 'A-6 858 Schwarzach'
        supplier1[:final_price].should == 1405440.0

        supplier2[:supplier_organisation_code].should == ''
        supplier2[:supplier_address].should == 'Hofsteigstrasse 120'
        supplier2[:supplier_zip].should == ''
        supplier2[:supplier_place].should == 'A-6 858 Schwarzach'
        supplier2[:final_price].should == 59840.0
      end
    end

    all_document_types_and_formats.each do |document_id|
      VCR.use_cassette("vvo_#{document_id}") do
        extractor = Etl::VvoExtractionV2.new(document_id)
        suppliers_information = extractor.suppliers_information
        dataset_type = extractor.dataset_type

        it "should have not nil attribute suppliers in suppliers information for document #{document_id}" do
          suppliers_information[:suppliers].should_not be_nil
        end

        suppliers_information[:suppliers].each do |supplier_information|
          required_attributes[:supplier_information][dataset_type].each do |attribute|
            # test when not in excluded nil attributes
            if allowed_nil_attributes_in_documents.exclude?(attribute) || allowed_nil_attributes_in_documents[attribute].exclude?(document_id)
              it "should have not nil attribute #{attribute} in customer information for document #{document_id}" do
                supplier_information[attribute].should_not be_nil
              end
              # test when check attribute and not in excluded blank attributes
              if not_check_blank_attributes.exclude?(attribute) && (allowed_blank_attributes_in_documents.exclude?(attribute) || allowed_blank_attributes_in_documents[attribute].exclude?(document_id))
                it "should have not blank attribute: #{attribute} in customer information for document #{document_id}" do
                  supplier_information[attribute].should_not be_blank
                end
              end
            end
          end
        end
      end
    end
  end

  # additional_information
  describe '#additional_information' do
    # Format 1
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_238715') do
        extractor = Etl::VvoExtractionV2.new(238715)
        extractor.additional_information.should == {
            procurement_euro_found: false
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_185909') do
        extractor = Etl::VvoExtractionV2.new(185909)
        extractor.additional_information.should == {
            procurement_euro_found: false,
            evaluation_committee: "Ján RÁCHEL, Sergej MASICA, Vladimír JAKÚBEK"
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_191763') do
        extractor = Etl::VvoExtractionV2.new(191763)
        extractor.additional_information.should == {
            procurement_euro_found: true,
            evaluation_committee: "Ing. Štefan Sedláček, Ing. Marian Janič, Ing. Jozef Kemény, Ing.Vladimír Oravec, Ing.Michal Puškár, Ing. Dagmar Tökölyová, Ing. Jozef Korba, Ing. Marek Harčár, Ing. Ludvik Mikula"
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_185892') do
        extractor = Etl::VvoExtractionV2.new(185892)
        extractor.additional_information.should == {
            procurement_euro_found: false,
            evaluation_committee: "Rudolf Hlavatý, Adriana Jabconová, Peter Dobiaš, Róbert Matejka, Ján Muráň, Peter Koper, Ľubica Michoňová, Juraj Bolech"
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_185927') do
        extractor = Etl::VvoExtractionV2.new(185927)
        extractor.additional_information.should == {
            procurement_euro_found: false,
            evaluation_committee: "Ing.arch.Pavol Ižvolt,PhD; Ing. Jozef Stanko; Ing. Igor Zigo; Ing. Miroslava Ralbovská; Ing. Miroslav Gdovin Tomáš;"
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_198751') do
        extractor = Etl::VvoExtractionV2.new(198751)
        extractor.additional_information[:procurement_euro_found].should == true
      end
    end

    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_188666') do
        extractor = Etl::VvoExtractionV2.new(188666)
        extractor.additional_information[:procurement_euro_found].should == true
      end
    end

    # Format 2

    it 'should get addition information from a document - 121966 - format2' do
      VCR.use_cassette('vvo_121966') do
        extractor = Etl::VvoExtractionV2.new(121966)
        extractor.additional_information.should == {
            procurement_euro_found: false
        }
      end
    end
    it 'should get addition information from a document - ??? - format1' do
      VCR.use_cassette('vvo_185909') do
        extractor = Etl::VvoExtractionV2.new(185909)
        extractor.additional_information.should == {
            procurement_euro_found: false,
            evaluation_committee: "Ján RÁCHEL, Sergej MASICA, Vladimír JAKÚBEK"
        }
      end
    end
    it 'should get addition information from a document - 122520 - format2' do
      VCR.use_cassette('vvo_122520') do
        extractor = Etl::VvoExtractionV2.new(122520)
        extractor.additional_information.should == {
            procurement_euro_found: true
        }
      end
    end

    all_document_types_and_formats.each do |document_id|
      it "should get additional information for #{document_id} document" do
        VCR.use_cassette("vvo_#{document_id}") do
          extractor = Etl::VvoExtractionV2.new(document_id)
          extractor.additional_information.should_not be_nil
        end
      end
    end
  end

  describe '#parse_address' do
    it 'parse address from zip format 949 01' do
      address, zip, place = @extractor_example.parse_address('Štefánikova 69, 949 01 Nitra')
      address.should == 'Štefánikova 69'
      zip.should == '94901'
      place.should == 'Nitra'
    end
    it 'parse address from zip format 94901' do
      address, zip, place = @extractor_example.parse_address('Štefánikova 69, 94901 Nitra')
      address.should == 'Štefánikova 69'
      zip.should == '94901'
      place.should == 'Nitra'
    end
    it 'parse address from multiple commas' do
      address, zip, place = @extractor_example.parse_address('Ulica 1, Štefánikova 69, 949 01 Nitra')
      address.should == 'Ulica 1, Štefánikova 69'
      zip.should == '94901'
      place.should == 'Nitra'
    end
    it 'parse address from empty zip' do
      address, zip, place = @extractor_example.parse_address('Štefánikova 69, Nitra')
      address.should == 'Štefánikova 69'
      zip.should == ''
      place.should == 'Nitra'
    end
    it 'parse address from empty zip and place' do
      address, zip, place = @extractor_example.parse_address('Štefánikova 69')
      address.should == 'Štefánikova 69'
      zip.should == ''
      place.should == ''
    end
  end

  describe '#mostly_numbers?' do
    it 'return true for mostly numbers in string 1' do
      @extractor_example.mostly_numbers?("1211212a").should be_true
    end
    it 'return true for mostly numbers in string 2' do
      @extractor_example.mostly_numbers?("12a").should be_true
    end
    it 'return false for only alpha chars in string' do
      @extractor_example.mostly_numbers?("aaaa").should be_false
    end
  end

end
