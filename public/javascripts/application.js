// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(function(){
	$("form.search").submit(function(event){
    if(inscription_validate_form(this)) {
      $.loading($("#search_processing").text());
    }
    else {
      return false;
    }
  });
  $("a.search_preloader").click(function(){
    $.loading($("#search_processing").text());
  });
  if($("#import_status").length > 0) {
    setTimeout(update_import_status, 1000);
  }

	if($('#data_repair_target_table_name').length > 0) { 
		update_data_repair_columns($('#data_repair_target_table_name'), ["#data_repair_target_ico_column", "#data_repair_target_company_name_column", "#data_repair_target_company_address_column"])
	}
	$('#data_repair_target_table_name').change(function(){
		update_data_repair_columns($(this), ["#data_repair_target_ico_column", "#data_repair_target_company_name_column", "#data_repair_target_company_address_column"])
	});

	if($('#data_repair_regis_table_name').length > 0) { 
		update_data_repair_columns($('#data_repair_regis_table_name'), ["#data_repair_regis_ico_column", "#data_repair_regis_name_column", "#data_repair_regis_address_column"])
	}
	$('#data_repair_regis_table_name').change(function(){
		update_data_repair_columns($(this), ["#data_repair_regis_ico_column", "#data_repair_regis_name_column", "#data_repair_regis_address_column"])
	});
});

$.ajaxSetup({
  beforeSend: function(xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
  }
});

var update_data_repair_columns = function(regis_table_name_select, fields){
	update_url = regis_table_name_select.parent().attr('data_update_columns')
	$.getJSON(update_url, {id: regis_table_name_select.val()}, function(j){
    var options = '';
    for (var i = 0; i < j.length; i++) {
      options += '<option value="' + j[i] + '">' + j[i] + '</option>';
    }
		for (var i = 0; i < fields.length; i++) {
			$(fields.join(',')).html(options);
    }
  });
}

var update_import_status = function(){
  if($("#import_status a.refresh").length == 0)
  {
    return;
  }
  var target = $("#import_status a.refresh").attr('href');
  $.getScript(target, function(){
    setTimeout(update_import_status, 2000);
  })
}