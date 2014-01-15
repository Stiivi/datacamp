$(document).ready(function(){
  $('a[href$=/collapse]').live('click', function(){
    $(this).attr('href', $(this).attr('href').replace('collapse', 'expand'));
    $(this).text('Expand');
    target = $(this).attr('href').replace('#/', '').replace('/expand', '').replace('/collapse', '');
    $("#"+target).slideUp();
  });
  $('a[href$=/expand]').live('click', function(){
    $(this).attr('href', $(this).attr('href').replace('expand', 'collapse'));
    $(this).text('Collapse');
    target = $(this).attr('href').replace('#/', '').replace('/expand', '').replace('/collapse', '');
    $("#"+target).slideDown();
  });
});

init_ajax_pagination = function(){
  $("div.pagination.ajax a, th a").each(function(){
    if($(this).attr('href') && $(this).attr('href').indexOf('#') == -1)
    {
      $(this).attr('href', '#' + $(this).attr('href'));
    };
  });
};

// $(document).ready(init_ajax_pagination);
// $(document).ajaxComplete(init_ajax_pagination);

$(document).ready(function(){
  $.History.bind(function(state){
    if(state.indexOf('datasets') == -1) return;
    $("#results").addClass("loading");
    $("#results").find("table:first").animate({opacity: 0}, 100);
    $.getScript('/' + state);
  });
});


// // // // // // // // // // // // // // // // // // // // // // // // 
// Suggestions

$(document).ready(function(){
  $("#information table.edit input[type=text]").each(function(){
    if($(this).siblings("div.suggestion").length>0)
    {
      inp = $(this);
      var qs = $(this).siblings("a.quality_status");
      qs.click(function(){
        if(confirm("Remove warning?"))
        {
          qs.remove();
          $.getScript(qs.attr('href'));
          return false;
        }
        return false;
      });
      var sug = $(this).siblings("div.suggestion");
      sug.width(inp.width());
      sug.css('cursor', 'pointer').click(function(){
        inp.val(sug.find('.value').text());
        sug.remove();
      });
      sug.find('img.cancel').click(function(){
        sug.remove();
        if(confirm("Remove warning?"))
        {
          qs.remove();
          $.getScript(qs.attr('href'));
        }
      });
      $(this).bind("focus", function(){
        sug.show();
      });
      $(this).bind("blur", function(){
        setTimeout(function(){
          sug.hide();
        }, 100);
      })
    }
  });
});


// // // // // // // // // // // // // // // // // // // // // // // // 
// Batch edit

$(document).ready(function(){
  show_batch_box();
  $("input.record[type=checkbox]").live("click", function(){
    show_batch_box(true);
  });
  
  $("a.select_all").click(function(){
    var count = $("input.record[type=checkbox]:checked").length;
    if(count>0)
    {
      $("input.record[type=checkbox]").attr('checked', false);
    }
    else
    {
      $("input.record[type=checkbox]").attr('checked', true);
    };
    show_batch_box(true);
    return false;
  });
  
  $("a.batch_cancel").click(function(){
    $("input.record[type=checkbox]").attr('checked', false);
    show_batch_box(true);
    
    return false;
  });
  
  $("a.batch_edit").click(function(){
    var form = $(this).parents("form");
    // form.attr('method', 'get');
    form.attr('action', $(this).attr('href'));
    form.submit();
    return false;
  });
  
  $("form.batch_edit input[type=text]").keyup(function(){
    if($(this).val() != "")
    {
      // Check box indicating the field should be updated.
      $(this).parents("tr:first").find("input[type=checkbox]").attr('checked', 'checked');
    }
    else
    {
      $(this).parents("tr:first").find("input[type=checkbox]").removeAttr('checked');
    }
  });
});

var show_batch_box = function(hiding){
  var count = $("input.record[type=checkbox]:checked").length;
  var edit = $("#batch_edit");

  if(count > 0)
  {
    if(edit.is(":hidden"))
    {
      edit.show();
    };
    edit.find("strong.count").text(count);
  }
  else if(edit.is(":visible"))
  {
    edit.hide();
  }
};