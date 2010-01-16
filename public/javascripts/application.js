// Global search

$(document).ready(function(){
  $("form.search").submit(function(event){
    if(inscription_validate_form(this))
    {
      $.loading($("#search_processing").text());
      // return false;
    }
    else
    {
      return false;
    }
  });
  $("a.search_preloader").click(function(){
    $.loading($("#search_processing").text());
  })
});