jQuery(function(){
	$('.sortable').nestedSortable({
		disableNesting: 'no-nest',
		forcePlaceholderSize: true,
		handle: 'div',
		helper:	'clone',
		items: 'li',
		maxLevels: 2,
		opacity: .6,
		placeholder: 'placeholder',
		revert: 250,
		tabSize: 30,
		tolerance: 'pointer',
		toleranceElement: '> div',
		listType: 'ul'
  });
  $('.sortable').nestedSortable('disable');

  $('.sort_link').click(function(){
    $('.sortable').nestedSortable('enable');
    $('.sort_link').addClass('hidden');
		$('.drag_arrow').parent().removeClass('hidden');
    $('.finish_sort_link').removeClass('hidden');
    $('#top-nav, #header, #menu, #footer, h1').fadeTo(500, 0.3);
    return false;
  });
  $('.finish_sort_link').click(function(){
    $.post($('.finish_sort_link').first().attr('href'), $('.sortable').nestedSortable('serialize'), function(data){
      $('#top-nav, #header, #menu, #footer, h1').fadeTo(500, 1);
      $('.sortable tbody.content').nestedSortable('disable');
			$('.drag_arrow').parent().addClass('hidden');
      $('.sort_link').removeClass('hidden');
      $('.finish_sort_link').addClass('hidden');
    });
    return false;
  });
});