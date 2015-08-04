$(function() {
  $('[data-report-error]').click(function() {
    $('#overlay').show();
    $('[data-error-popup]').show();
    return false;
  });

  $('#overlay, [data-close-dialog]').click(function() {
    $('#overlay').hide();
    $('[data-error-popup]').hide();
    return false;
  });
});
