var optgroups = null;

$(document).ready(function(){
  $('#search_dataset').unbind("change").change(function(e) {
    $('#predicate_rows').html('');

    $('#predicate_rows').load($('#predicate_rows').data('refresh-url') + '?identifier=' + $(this).val(), null, function(){
      init_search_form();
    });
  });

  //$('#search_dataset').trigger('change');
  init_search_form();
});

var init_search_form = function() {
  optgroups = $("select.search_operator:first").clone();
  $(".search_row:first").find("a.remove_row").hide();
  $(".search_row").each(function(){
    init_search($(this), false);
  });
};

var init_search = function(row, reset){

  row.find("a.add_row").click(function(){
    // Duplicate row
    cloned = row.clone();
    cloned.find("a.remove_row").show();
    cloned.appendTo(row.parent());
    init_search(cloned, true);
    GATracker._advanced_search_field_add();
    return false;
  });

  row.find("a.remove_row").click(function(){
    row.remove();
    return false;
  });

  row.find("select.search_field").change(function(){
    opt = $(this).find("option:selected");
    GATracker._advanced_search_field_change(opt.val());
    type = opt.attr('class');
    row.find("select.search_operator").empty();
    optgroups.find("optgroup."+type).clone().children().appendTo(row.find("select.search_operator"));
  });

  row.find("select.search_operator").change(function(){
    GATracker._advanced_search_field_type_change($(this).val());
  });


  operator_value = row.find("select.search_operator").val();
  row.find("select.search_field").trigger("change");
  if(reset == true)
  {
    row.find("select.search_field option").removeAttr('selected');
    row.find("select.search_field option:first").attr('selected', 'selected');
    row.find("select.search_operator option").removeAttr('selected');
    row.find("select.search_operator option:first").attr('selected', 'selected');
    row.find("input").val("");
  }
  else
  {
    row.find("select.search_operator").val(operator_value);
  }
}
