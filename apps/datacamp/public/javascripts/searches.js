$(document).ready(function(){
  $("form.new_search_base").submit(function(){
    $(this).addClass("loading").contents().css({opacity:0});
    $(this).find(".loading").show().css({opacity:1});
  });
});