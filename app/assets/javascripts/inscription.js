// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// inscription.js
// jQuery-based javascript toolking
// (c) Vojto Rinik


// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Basic Ajax

var class_prefix = "_inscription_"

$(document).ready(function(){
  $('a.ajax').live('click', function(){
    var url = $(this).attr('href');
    $("#ajax_preloader").show();
    $.getScript(url, function(){
      $('#ajax_preloader').hide();
    });
    
    return false;
  });
  
  $('form.ajax').live('submit', function(){
    $("#ajax_preloader").show();
    var url = $(this).attr('action');
    var method = $(this).attr('method');
    
    $.ajax({
      url: url,
      dataType: 'script',
      type: method,
      data: $(this).serialize(),
      success: function(){$("#ajax_preloader").hide()}
    })
    return false;
  });
  
  $('form.ajax input[value="Save and create"]').live('click', function(){
    var hid = $("<input />").attr('type', 'hidden').css('display', 'none').attr('name', 'commit').attr('value', 'Save and create');
    $(this).parents('form:first').append(hid);
  });
});

$('form.ajax a.cancel').live('click', function(){
  var li = $(this).parents('form:first').parent();
  li.prev().show();
  li.remove();
  
  return false;
});


// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Tabs

var init_tabs = function(){
  $("ul.tabs").each(function(){
    // Add init class
    if($(this).hasClass('initialized'))
    {
      return;
    }
    $(this).addClass("initialized");
    
    // Scan through tabs
    var tabs = [];
    var active_tab = false;
    $(this).find('a').each(function(){
      href = $(this).attr('href');
      if($(this).parent().hasClass('active'))
      {
        active_tab = href;
      };
      if(href[0] == '#')
      {
        tabs.push({
          tab: $(href).hide(),
          link: $(this)
        });
      };
    });
    $.each(tabs, function(i, o){
      $(o.link).click(function(){
        tab = $(this).attr('href');
        switch_tab(tab, tabs);
        window.location.hash = '/' + tab.replace('#', '');
        return false;
      });
    });
    if(tabs.length > 0)
    {
      if(!active_tab)
      {
        switch_tab(tabs[0].link.attr('href'), tabs);
      }
      else
      {
        switch_tab(active_tab, tabs);
      }
      if(window.location.hash)
      {
        var current_tab = window.location.hash.replace('/', '');
        $.each(tabs, function(i, o){
          if($(o.link).attr("href") == current_tab)
          {
            switch_tab(current_tab, tabs);
          }
        });
      }; // end if location.hash
    };
  });
};

var switch_tab = function(tab, tabs){
  $.each(tabs, function(i, o){
    if($(o.tab).attr('id') == tab.replace('#', ''))
    {
      $(o.tab).show();
      $(o.link).parent().addClass('active');
    }
    else
    {
      $(o.tab).hide();
      $(o.link).parent().removeClass('active');
    };
  });
};

$(document).ready(init_tabs);
$(document).bind('ajaxComplete', init_tabs);

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Hash forwarding

$(document).ready(function(){
  $("a.forward_hash").click(function(){
    href = $(this).attr('href');
    if(window.location.hash)
    {
      if(href.indexOf('?') == -1)
      {
        href = href + '?hash=' + escape(window.location.hash);
      }
      else
      {
        href = href + '&hash=' + escape(window.location.hash);
      };
    };
    $(this).attr('href', href);
  })
});

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Forms

$(document).ready(function(){
  $("form.submit_on_change").find("select").live("change", function(){
    if(!$(this).hasClass("no_submit"))
    {
      $(this).parents("form:first").submit();
    }
  });
  $("a.submit_form").live("click", function(){
      $(this).parents("form:first").submit();
      return false;
  })
});

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Tooltips

var tooltip = null;
var tooltip_timeout = null;
$(document).ready(function(){
  $("img.tooltip").css({cursor: "pointer"});
  $("img.tooltip, a.tooltip").hover(function(){
    clearTimeout(tooltip_timeout);
    tooltip = $("<div />").addClass("tooltip").css({position: "absolute", opacity: 0});
    tooltip.css({background: "black", color: "#fff", padding: "10px"})
    var text = $(this).attr("alt") ? $(this).attr("alt") : $(this).attr("name");
    tooltip.text(text);
    tooltip.appendTo($("body"));
    
    var offset = $(this).offset();
    offset.left += $(this).width() + 10;
    offset.top += ($(this).height() - tooltip.outerHeight())/2;
    tooltip.css({top: offset.top, left: offset.left});
    
    // Animation
    tooltip.css({opacity: 1});
    
  }, function(){
    $(tooltip).remove();

    
    // tooltip_timeout = setTimeout(function(){
    //       tooltip.remove();Ω
    //     }, 200);
  });
});


// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Editables

$.fn.editable = function(name, url){
  text = this.text().replace(/^\s+|\s+$/g,"");
  width = this.width();
  
  if(this.is(":visible"))
  {
    input = $('<input type="text" />').css({width: width});
    input.attr('name', name)
    input.val(text);
    $(input).insertAfter(this);
    this.hide();
  }
  else
  {
    input = this.siblings("input");
    $(this).text(input.val());
    $.post(url, "_method=put&"+input.serialize(), function() {}, "script");
    input.remove();
    this.show();
  }
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Modal

$.modal = function(options){
  inscription_modal_remove();
  
  options = $.extend({
    position: 'center',
    shadow: false,
    type: 'window'
  }, options);
  
  var position = {}
  
  //////////////////////////////////////////////////////////////////////
  // Count position
  if($(options.position).length > 0)
  {
    var position_element = $(options.position);
    position = position_element.offset();
  }
  else if(options.position=='hidden')
  {
    position.top = -9999
    position.left = -9999
  }
  else
  {
    // We're centering the element
    var view_size = {width: $(window).width(), height: $(window).height()}
    position.top = view_size.height/2
    position.left = view_size.width/2
  }
  
  //////////////////////////////////////////////////////////////////////
  // Summon shadow if needed
  if(options.shadow)
  {
    var overlay = $("<div />").addClass(class_prefix+"Overlay");
    overlay.css({opacity: 0.4});
    overlay.appendTo($("body"));
    overlay.click(inscription_modal_close);
    
    if($.browser.safari)
    {
      overlay.css({webkitTransitionProperty:"opacity", webkitTransitionDuration:"0.3s", opacity: 0});
      setTimeout(function(){
        overlay.css({opacity: 0.4});
      }, 0);
    };
  };
  
  //////////////////////////////////////////////////////////////////////
  // Summon modal
  var modal = $("<div />").css({position: "absolute", top: position.top, left: position.left}).addClass(class_prefix+"Modal").addClass(options.type);
  // Setup default webkit animation stuff

  inner = $("<div />").addClass("inner");
  inner.appendTo(modal);
  
  inner.html(options.html);
  
  inner.find("a.cancel").click(inscription_modal_close);
  
  // modal.css({marginLeft: -1 * modal.width()});


  modal.appendTo($("body"));

  if($.browser.safari)
  {
    modal.css({webkitTransform: "scale(0.6)", webkitTransitionProperty:"-webkit-transform, opacity", webkitTransitionDuration:"0.3s", opacity: 0});
    setTimeout(function(){
      modal.css({webkitTransform: "scale(1)", opacity: 1});
    }, 0);
  };
}

$.close_modal = function(){
  inscription_modal_close();
}

var inscription_modal_close = function(){
  // $("."+class_prefix+"Modal").removeClass("startingPosition");
  if($.browser.safari)
  {
    $("."+class_prefix+"Overlay").css({opacity: 0});
    $("."+class_prefix+"Modal").css({opacity: 0, webkitTransform: "scale(0.8)"});
    setTimeout(function(){
      inscription_modal_remove();
    }, 300);
  }
  else
  {
    inscription_modal_remove();
  }
}

var inscription_modal_remove = function(){
  $("."+class_prefix+"Overlay").remove();
  $("."+class_prefix+"Modal").remove();
}

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Global loading notice

$.loading = function(text){
  $("."+class_prefix+"Loading").remove();
  loading = $("<div />").addClass(class_prefix+"Loading");
  loading.css({opacity: 0, marginTop: -100});
  
  span = $("<div />").addClass("text");
  span.text(text);
  span.appendTo(loading);
  
  loading.appendTo($("body"));
  loading.animate({opacity: 0.8, marginTop: 0});
};

$(document).ready(function(){
  // We need to preload background
  loading = $("<div />").addClass(class_prefix+"Loading");
  loading.css({position:"absolute", top: -1000, left: -1000});
  span = $("<div />").addClass("text");
  span.appendTo(loading);
  loading.appendTo($("body"));
});

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Form validation

var inscription_validate_form = function(form){
  validated = true;
  $(form).find("input.required").each(function(){
    if($(this).val().length==0)
    {
      validated = false;
    }
  });
  return validated;
}

$("form.validate").bind('submit', function(){
  return inscription_validate_form(this);
});

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 
// Form preloading

$(document).ready(function(){
  $("form.preloader").submit(function(){
    var message = $(this).attr("data-preloader-message");
    $.loading(message);
  });
});
