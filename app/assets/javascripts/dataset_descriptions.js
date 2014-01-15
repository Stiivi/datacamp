// // // // // // // // // // // // // // // // // // // // // // // // 
// Entities/Show

$(document).ready(function(){
  // // // // // // // // // // // // // // // // // // // // // // //
  // Show more info
  $('.dataset_description.large ul li .info').toggle(function(){
    $(this).find('.more').show();
  }, function(){
    $(this).find('.more').hide();
  });

  // // // // // // // // // // // // // // // // // // // // // // //
  // Sortable lists
  // // // // // // // // // // // // // // // // // // // // // // //
  // Sortables for import settings
  $("#all_field_descriptions ul").sortable({connectWith: '#importable_field_descriptions ul', update: update_import_settings});
  $("#importable_field_descriptions ul").sortable({connectWith: '#all_field_descriptions ul', update: update_import_settings});
});

var update_import_settings = function(){
  var settings = {};
  var counter = 1;
  $("#importable_field_descriptions ul li").each(function(){
    $(this).find("strong").text(counter);
    settings[$(this).attr('id').replace('field_description_', '')] = counter++;
  });
  $("#dataset_description_import_settings").val($.param(settings));
};


// // // // // // // // // // // // // // // // // // // // // // // // 
// Field descriptions visibility

var field_description_visibility_save = null;
$(document).ready(function(){
  $("input.field_description[type=checkbox]").click(function(){
    clearTimeout(field_description_visibility_save);
    field_description_visibility_save = setTimeout(function(){
      // Extract information and save it to server
      var data = $("input.field_description[type=checkbox]").serialize();
      var url = $("a.save_field_descriptions_visibility").attr("href");
      $.post(url, data);
    }, 200);
  });
});

// // // // // // // // // // // // // // // // // // // // // // // // 
// Turning on and off all items at once in DatasetDescriptionsController:visibility

$(document).ready(function(){
  $("a.switch_visibility").click(function(){
    var table = $(this).parents("table:first");
    var target = $(this).attr("href").replace("#", "");
    var inputs = table.find("td."+target).find("input[type=checkbox]");
    var value = inputs[0].checked ? 1 : 0
    if(value==1)
    {
      inputs.attr('checked', false);
    }
    else
    {
      inputs.attr('checked', true);
    }
    
    return false;
  });
});

// // // // // // // // // // // // // // // // // // // // // // // // 
// Import template picker


$(document).ready(function(){
  $("#settings, .settings").toggle();
  $("a.toggle_settings").click(function(){
    $("#settings, .settings").toggle();
    return false;
  });
});


// // // // // // // // // // // // // // // // // // // // // // // // 
// Field ordering

$(document).ready(function(){
  $("a.order").click(function(){
    var obj = $(this).parents("tr");
    
    if($(this).hasClass('up'))
    {
      var prev = obj.prev('.field_description');
      if(prev.length != 0)
      {
        obj.insertBefore(prev);
      }
    }
    else
    {
      var next = obj.next('.field_description');
      if(next.length != 0)
      {
        obj.insertAfter(next);
      }
    }
    
    var order = $.map($(this).parents("tr").parent().find("tr.field_description"), function(row){
      return $(row).attr('id').replace(/[^\d]+/, '');
    }).join(',');
    
    $.post($(this).attr('href'), {order: order});
    
    return false;
  });
});
