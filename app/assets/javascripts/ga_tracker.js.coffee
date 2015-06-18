@GATracker =

  tracking_container: -> _gaq if _gaq?

  push: (data) ->
    @tracking_container().push(data)

  gather_data: ->
    @_search_keyword()
    @_user_signed_in()
    @_user_registered()

  _search_keyword: ->
    search_keyword = $('*[data-tracking-search-keyword]').data('tracking-search-keyword')
    @tracking_container().push(['_trackEvent', 'vyhladavanie-slovo', search_keyword]) if search_keyword?

  _user_registered: ->
    if $('meta[name="user-registered"]').length > 0
      @push(['_trackPageview', '/goal/registration'])

  _user_signed_in: ->
    if $('meta[name="user-signed-in"]').length > 0
      @push(['_trackPageview', '/goal/login']);
      @push(['_setCustomVar', 1, 'uzivatel-prihlaseny', 'ano', 2 ]);

  _user_registered: ->

  setup_callbacks: ->
    @_advanced_search_toggle()
    @_advanced_search_dataset_change()
    @_catalog_click()
    @_dataset_detail_data_button_click()
    @_dataset_detail_information_button_click()
    @_dataset_detail_comments_button_click()
    @_dataset_api_link()
    @_dataset_detail_sort_click()
    @_new_comment_submitted()
    @_new_comment_report_submitted()
    @_dataset_record_comments_button_click()
    @_dataset_record_metadata_button_click()
    @_remove_from_favorites_click()
    @_download_api_click()
    @_create_api_key_click()

  _advanced_search_toggle: ->
    $('.js_advanced_search_toggle').click => @push(['_trackEvent', 'vyhladavanie-podrobnejsie-sipka', '1'])

  _advanced_search_dataset_change: ->
    $('.js_advanced_search_dataset').change (e) => @push(['_trackEvent', 'vyhladavanie-podrobnejsie-dataset', $(e.srcElement).val()])

  _advanced_search_field_change: (value) ->
    @push(['_trackEvent', 'vyhladavanie-podrobnejsie-dataset-filter', value]) if @tracking_container()?

  _advanced_search_field_type_change: (value) ->
    @push(['_trackEvent', 'vyhladavanie-podrobnejsie-dataset-filter-typ', value]) if @tracking_container()?

  _advanced_search_field_add: ->
    @push(['_trackEvent', 'vyhladavanie-podrobnejsie-dataset-filter-pridanie', '1']) if @tracking_container()?

  _comment_submitted: ->
    @push(['_trackPageview', '/goal/komentar-odoslany']) if @tracking_container()?

  _catalog_click: ->
    $('.js_catalog_dataset_link').mousedown (e) =>
      $element = $(e.currentTarget)
      category = $element.data('tracking-dataset-category-id')
      dataset = $element.data('tracking-dataset-id')
      @push(['_trackEvent', "katalog-udajov-#{category}", dataset])

  _dataset_detail_data_button_click: ->
    $('.js_dataset_detail_data_button').click (e) =>
      @push(['_trackEvent', 'katalog-udajov-menu-3-tlacidla', 'udaje'])

  _dataset_detail_information_button_click: ->
    $('.js_dataset_detail_information_button').click (e) =>
      @push(['_trackEvent', 'katalog-udajov-menu-3-tlacidla', 'informacie'])

  _dataset_detail_comments_button_click: ->
    $('.js_dataset_detail_comments_button').click (e) =>
      @push(['_trackEvent', 'katalog-udajov-menu-3-tlacidla', 'komentare'])

  _dataset_api_link: ->
    $('.js_api_link').mousedown (e) =>
      @push(['_trackPageview', '/goal/stiahnutie-suboru-s-udajmi/'])
      @push(['_trackEvent', "dataset-download", $(e.currentTarget).data('tracking-dataset-id')])

  _dataset_detail_sort_click: ->
    $('.js_sort_link').mousedown (e) =>
      $element = $(e.currentTarget)
      field = $element.data('tracking-field-id')
      direction = $element.data('tracking-direction')
      @push(['_trackEvent', "katalog-udajov-horne-menu", field, direction])

  _new_comment_submitted: ->
    $('form#new_comment').submit (e) =>
      e.preventDefault()
      @push(['_set', 'hitCallback', -> $('form#new_comment')[0].submit()])
      if $('#comment_parent_comment_id').val().length > 0
        @push(['_trackPageview', '/goal/komentar-odpovedat'])
      else
        @push(['_trackPageview', '/goal/komentar-odoslany'])

  _new_comment_report_submitted: ->
    $('form#new_comment_report').submit (e) =>
      e.preventDefault()
      @push(['_set', 'hitCallback', -> $('form#new_comment_report')[0].submit()])
      @push(['_trackPageview', '/goal/komentar-zazalovat'])

  _dataset_record_comments_button_click: ->
    $('.js_dataset_record_comments_button').click =>
      @push(['_trackPageview', '/detail-register/komentare']) if $('.js-my-account').length == 0

  _dataset_record_metadata_button_click: ->
    $('.js_dataset_record_metadata_button').click =>
      @push(['_trackPageview', '/detail-register/metadata']) if $('.js-my-account').length == 0

  _added_to_favorites: ->
    @push(['_trackPageview', '/goal/add-favorites-odoslat'])

  _remove_from_favorites_click: ->
    $('.js_remove_from_favorites').mousedown =>
      @push(['_trackPageview', '/goal/add-favorites-odvolat'])

  _download_api_click: ->
    $('.js_download_relations').mousedown (e) => @push(['_trackEvent', "detail-#{$(e.currentTarget).data('tracking-dataset-id')}-4-tlacidla", 'relacie-xml'])
    $('.js_download_changes').mousedown (e) => @push(['_trackEvent', "detail-#{$(e.currentTarget).data('tracking-dataset-id')}-4-tlacidla", 'zmeny-xml'])
    $('.js_download_csv').mousedown (e) => @push(['_trackEvent', "detail-#{$(e.currentTarget).data('tracking-dataset-id')}-4-tlacidla", 'obsah-csv'])
    $('.js_download_description').mousedown (e) => @push(['_trackEvent', "detail-#{$(e.currentTarget).data('tracking-dataset-id')}-4-tlacidla", 'popis-xml'])

  _more_information_click: (dataset_id) ->
    @push(['_trackEvent', "detail-#{dataset_id}-chcem-vediet-viac", '1'])

  _create_api_key_click: ->
    $('.js-create-api-key').mousedown => @push(['_trackEvent', 'moje-konto-novy-api-kluc', '1'])
