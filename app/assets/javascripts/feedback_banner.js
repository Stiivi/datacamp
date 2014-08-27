$(document).ready(function(){
    if (!enabledFeedbackBanner()) {
        $("#feedback_banner").hide();
        disableFeedbackBanner();
    }
});

$(function(){
    $('.btn_hide').click(function(){
        $("#feedback_banner").hide(200);
        disableFeedbackBanner();
    });
});

function disableFeedbackBanner(){
    $.cookie('disabled_feedback_banner', '1', { expires: 365 });
}

function enabledFeedbackBanner(){
    return $.cookie('disabled_feedback_banner') == undefined;
}