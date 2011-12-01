// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$.ajaxSetup({
  beforeSend: function(xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
  }
});

var update_select_fields = function(regis_table_name_select, fields, use_names){
	update_url = regis_table_name_select.parent().attr('data_update_columns');
	$.getJSON(update_url, {id: regis_table_name_select.val()}, function(j){
    var options = '';
    for (var i = 0; i < j.length; i++) {
			if(use_names)
      	options += '<option value="' + j[i][0] + '">' + j[i][1] + '</option>';
			else
				options += '<option value="' + j[i] + '">' + j[i] + '</option>';
    }
		$(fields).html(options);
  });
};

var update_import_status = function(){
  if($("#import_status a.refresh").length == 0)
  {
    return;
  }
  var target = $("#import_status a.refresh").attr('href');
  $.getScript(target, function(){
    setTimeout(update_import_status, 2000);
  });
};

function cleanup_hashes() {
	$('input.remove_element,input.add_element').each(function(index, domElem){
		$(domElem).val($(domElem).val().replace(/\s+#\d+$/, ''));
	});
}

$(function(){
	$("form.search").submit(function(event){
		if(inscription_validate_form(this)) {
			$.loading($("#search_processing").text());
		} else {
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
		update_select_fields($('#data_repair_target_table_name'), "#data_repair_target_ico_column, #data_repair_target_company_name_column, #data_repair_target_company_address_column", false);
	}
	
	$('#data_repair_target_table_name').change(function(){
		update_select_fields($(this), "#data_repair_target_ico_column, #data_repair_target_company_name_column, #data_repair_target_company_address_column", false);
	});

	if($('#data_repair_regis_table_name').length > 0) { 
		update_select_fields($('#data_repair_regis_table_name'), "#data_repair_regis_ico_column, #data_repair_regis_name_column, #data_repair_regis_address_column", false);
	}
	$('#data_repair_regis_table_name').change(function(){
		update_select_fields($(this), "#data_repair_regis_ico_column, #data_repair_regis_name_column, #data_repair_regis_address_column", false);
	});
	
	cleanup_hashes();
	$('.add_element').live('click', function () { 
		var content = $(this).attr("data-element");
	  var new_id = new Date().getTime();
	  var regexp = new RegExp("new_" + $(this).attr("data-association"), "g");
		$(this).before(content.replace(regexp, new_id));
	  cleanup_hashes();
		return false;
	});
	$('.remove_element').live('click', function () { 
		$(this).prev().val("1");
		$(this).closest('fieldset').hide();
		$(this).closest('table').hide();
		return false;
	});
	
	$('.prev_div_toggler').click(function(){
	  $(this).prev().toggle();
	  return false;
	});
});