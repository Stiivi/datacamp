var optgroups = null;

$(document).ready(function(){
  optgroups = $("select.search_operator:first").clone();
  $(".search_row:first").find("a.remove_row").hide();
  $(".search_row").each(function(){
    init_search($(this), false);
  });
});

var init_search = function(row, reset){
  
  row.find("a.add_row").click(function(){
    // Duplicate row
    cloned = row.clone();
    cloned.find("a.remove_row").show();
    cloned.appendTo(row.parent());
    init_search(cloned, true);
    return false;
  });
  
  row.find("a.remove_row").click(function(){
    row.remove();
    return false;
  });
  
  row.find("select.search_field").change(function(){
    opt = $(this).find("option:selected");
    type = opt.attr('class');
    row.find("select.search_operator").empty();
    optgroups.find("optgroup."+type).clone().children().appendTo(row.find("select.search_operator"));
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