$(document).ready(function(){
    if (!enabledBanner('feedback')) {
        $("#feedback_banner").hide();
        disableBanner('feedback');
    }
    if (!enabledBanner('cookie')) {
        $("#cookie_banner").hide();
        disableBanner('cookie');
    }
});

$(function(){
    $('#feedback_banner').find('.btn_hide').click(function(){
        $("#feedback_banner").hide(200);
        disableBanner('feedback');
    });
    $('#cookie_banner').find('.btn_hide').click(function(){
        $("#cookie_banner").hide();
        disableBanner('cookie');
    });
});

function disableBanner(banner_type){
    $.cookie('disabled_' + banner_type + '_banner', '1', { expires: 365 });
}

function enabledBanner(banner_type){
    return $.cookie('disabled_' + banner_type + '_banner') == undefined;
}