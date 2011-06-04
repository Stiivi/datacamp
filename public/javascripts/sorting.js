jQuery(function(){
  $('#sortable tbody.content').sortable();
  $('#sortable tbody.content').sortable('disable');

  $('.sort_link').click(function(){
    $('#sortable tbody.content').sortable('enable');
    $('.sort_link').addClass('hidden');
    $('.finish_sort_link').removeClass('hidden');
    $('#top-nav, #header, #menu, #footer, h1').fadeTo(500, 0.3);
    return false;
  });
  $('.finish_sort_link').click(function(){
    $.post($('.finish_sort_link').first().attr('href'), $('#sortable tbody.content').sortable('serialize'), function(data){
      $('#top-nav, #header, #menu, #footer, h1').fadeTo(500, 1);
      $('#sortable tbody.content').sortable('disable');
      $('.sort_link').removeClass('hidden');
      $('.finish_sort_link').addClass('hidden');
    });
    return false;
  });
});