// Global search

$(document).ready(function(){
  $("form.search").submit(function(event){
    if(inscription_validate_form(this))
    {
      $.modal({html: $("#search_processing").html(), type: 'window', shadow: true});
      // return false;
    }
    else
    {
      return false;
    }
  });
});