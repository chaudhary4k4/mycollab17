jQuery.fn.objectSubtasks=function(action,p1,p2,p3){switch(action){case"init":var settings=jQuery.extend({subtasks:null,user_id:null,can_add:false,can_edit:false,can_manage:false,add_url:null,reoder_url:null},p1);break;case"add":var subtask=p1;break}return this.each(function(){var wrapper=$(this);var init_subtask_form_row=function(row,on_valid,on_success,on_error,on_cancel){var form=row.find("form");var summary_field=form.find("div.subtask_summary input[type=text]");summary_field.keydown(function(e){if(e.keyCode==27){on_cancel.apply(form[0]);return false}});form.find("a.subtask_cancel").click(function(){on_cancel.apply(form[0]);return false});form.submit(function(){var data={"subtask[body]":jQuery.trim(summary_field.val()),"subtask[assignee_id]":form.find("div.subtask_assignee select").val(),"subtask[priority]":form.find("div.subtask_priority select").val(),"subtask[label_id]":form.find("div.subtask_label select").val(),"subtask[due_on]":jQuery.trim(form.find("div.subtask_due_on input").val()),submitted:"submitted"};if(data["subtask[body]"]==""){summary_field.focus();return false}on_valid.apply(form[0]);$.ajax({url:form.attr("action"),type:"post",data:data,success:function(response){on_success.apply(form[0],[response])},error:function(response){on_error.apply(form[0],[response])}});return false})};var subtasks_table=wrapper.find("table.subtasks_table");subtasks_table.find("tr.add_and_manage a.add_subtask").click(function(){subtasks_table.find("tr.add_and_manage").hide();show_subtask_form_row(subtasks_table.find("tr.new_subtask"));return false});subtasks_table.find("tr.new_subtask").each(function(){var new_subtask_row=$(this);var working_row=false;init_subtask_form_row(new_subtask_row,function(){new_subtask_row.find("div.subtask_summary input[type=text]").val("").focus();working_row=create_working_row();new_subtask_row.before(working_row)},function(response){working_row.remove();add(response);App.Wireframe.Events.trigger("subtask_created",response)},function(response){working_row.remove();App.Wireframe.Flash.error("Failed to add subtask")},function(){hide_subtask_form_row(new_subtask_row);subtasks_table.find("tr.add_and_manage").show();return false})});subtasks_table.find("tr.add_and_manage a.reorder_subtasks").each(function(){var link=$(this);subtasks_table.sortable({axis:"y",cursor:"move",items:"tr.subtask_active",revert:false,connectWith:["table.subtasks_table"],handle:".task_drag_handle",update:function(e,ui){var subtasks_ids=[];subtasks_table.find("tr.subtask_active").each(function(){subtasks_ids.push(parseInt($(this).attr("subtask_id")))});$.ajax({url:link.attr("href"),type:"post",data:{subtasks_ids:subtasks_ids,submitted:"submitted"},error:function(){App.Wireframe.Flash.error("Failed to reorder subtasks. Please try again later")}})},receive:function(event,ui){},remove:function(event,ui){}});link.click(function(){if(subtasks_table.is("table.reorder")){subtasks_table.removeClass("reorder");link.text(App.lang("Reorder"));subtasks_table.enableSelection()}else{subtasks_table.addClass("reorder");link.text(App.lang("Done Reordering"));subtasks_table.disableSelection()}return false})});subtasks_table.find("tr.show_old_completed a").click(function(){subtasks_table.toggleClass("show_old_completed");update_indicator_rows();return false});var add=function(subtask,bulk){var is_completed=subtask.completed_on!==null;var row=$('<tr class="subtask"><td class="task_reorder"><img src="'+App.Config.get("assets_url")+'/images/subtasks/widgets/object_subtasks/subtask-drag-handle.png" class="task_drag_handle" /></td><td class="task_meta"></td><td class="task_content"></td><td class="task_options"></td></tr>').attr({id:"subtask"+subtask.id,subtask_id:subtask.id}).addClass((is_completed?"subtask_completed":"subtask_active"));update(row,subtask);if(is_completed){add_completed(row)}else{add_active(row)}if(!bulk){update_indicator_rows()}};var update=function(row,subtask){if(!subtask){subtask=row.data("subtask")}else{row.data("subtask",subtask)}var is_completed=subtask.completed_on!==null;var subtask_meta_row=row.find("td.task_meta").empty();var add_subtask_label=function(text,color,background,assignee){var label=null,can_edit=settings.can_edit||(typeof(assignee)=="object"&&assignee&&assignee.id&&assignee.id==settings.user_id);if(can_edit){label=$('<a href="#"></a>').attr({href:subtask.urls["update_label"],title:App.lang("Update Label")})}else{label=$("<span></span>")}label.addClass("label").text(App.clean(text)).css({color:color,"background-color":background}).appendTo(subtask_meta_row);if(can_edit){label.flyoutForm({success_message:App.lang("Label successfully changed"),success_event:"subtask_updated",width:"narrow"})}};subtask_meta_row.append(App.Wireframe.Utils.renderPriority(subtask.priority,true));if(typeof(subtask.label)=="object"&&subtask.label){add_subtask_label(subtask.label["name"],subtask.label["fg_color"],subtask.label["bg_color"],subtask.assignee)}var subtask_content_cell=row.find("td.task_content").empty();var completed_icon_url=App.Wireframe.Utils.imageUrl("/icons/12x12/checkbox-checked.png","complete");var open_icon_url=App.Wireframe.Utils.imageUrl("/icons/12x12/checkbox-unchecked.png","complete");if(subtask.permissions&&subtask.permissions["can_change_complete_status"]){$('<a class="completion_status_toggler"></a>').attr("is_on",(is_completed?1:0)).asyncToggler({method:"post",content_when_on:'<img src="'+completed_icon_url+'">',content_when_off:'<img src="'+open_icon_url+'">',title_when_on:App.lang("Click to Reopen"),title_when_off:App.lang("Click to Complete"),url_when_on:subtask.urls["open"],url_when_off:subtask.urls["complete"],indicator_url:App.Wireframe.Utils.indicatorUrl("small"),success:function(response){if(typeof(response)=="object"){if(response.completed_on===null){add_active(row)}else{add_completed(row)}update_indicator_rows()}},indicator_url:App.Wireframe.Utils.indicatorUrl(),success_event:"subtask_updated"}).appendTo(subtask_content_cell)}else{$('<span class="completion_status_toggler" title="'+(is_completed?App.lang("Completed"):App.lang("Open"))+'"><img src="'+(is_completed?completed_icon_url:open_icon_url)+'"></span>').appendTo(subtask_content_cell)}if(typeof(subtask.assignee)=="object"&&subtask.assignee){$('<span class="subtask_assignee">'+App.clean(subtask.assignee["short_display_name"])+"</span>").appendTo(subtask_content_cell)}$('<span class="task_content_text">'+App.clean(subtask.name)+"</a>").linkify().appendTo(subtask_content_cell);if(typeof(subtask.due_on)=="object"&&subtask.due_on&&!is_completed){var due_on_wrapper=$('<span class="subtask_due_on">&middot; <time datetime="'+subtask.due_on["mysql"]+'" title="'+subtask.due_on["formatted_gmt"]+'">'+App.clean(subtask.due_on["formatted_gmt"])+"</time></span>").appendTo(subtask_content_cell);due_on_wrapper.find("time").dueOn()}var subtask_options_cell=row.find("td.task_options");var options_id_prefix=wrapper.attr("id")+"__subtask_"+subtask.id+"_";subtask_options_cell.empty();if(typeof(subtask.options)=="object"){for(var option_name in subtask.options){if(!settings.can_edit&&(option_name=="edit"||option_name=="trash")){continue}var option=$('<a href="'+subtask.options[option_name]["url"]+'">'+(typeof(subtask.options[option_name]["icon"])=="undefined"?"":'<img src="'+subtask.options[option_name]["icon"]+'">')+"</a>").attr("id",options_id_prefix+"_"+option_name).appendTo(subtask_options_cell);if(typeof(subtask.options[option_name]["attributes"])=="object"&&subtask.options[option_name]["attributes"]){option.attr(subtask.options[option_name]["attributes"])}if(typeof(subtask.options[option_name]["classes"])=="object"&&subtask.options[option_name]["classes"]){for(var i in subtask.options[option_name]["classes"]){option.addClass(subtask.options[option_name]["classes"][i])}}if(typeof(subtask.options[option_name]["onclick"])=="string"&&subtask.options[option_name]["onclick"]){var onclick=eval(subtask.options[option_name]["onclick"]);if(typeof(onclick)=="function"){onclick.apply(option[0])}}}}subtask_options_cell.find("#"+options_id_prefix+"_trash").asyncLink({confirmation:App.lang("Are you sure that you want to move selected subtask to Trash?"),success:function(){row.remove();update_indicator_rows();App.Wireframe.Flash.success("Subtask has been successfully moved to Trash")},success_event:"subtask_deleted",error:function(){App.Wireframe.Flash.error("Failed to move selected subtask to Trash. Please try again later")}});subtask_options_cell.find("#"+options_id_prefix+"_edit").click(function(){var link=$(this);var working_row=create_working_row();row.hide().after(working_row);$.ajax({url:App.extendUrl(link.attr("href"),{async:1}),type:"get",success:function(response){var edit_row=$(response);working_row.after(edit_row).remove();show_subtask_form_row(edit_row);init_subtask_form_row(edit_row,function(){edit_row.remove();working_row=create_working_row();row.after(working_row)},function(response){working_row.remove();App.Wireframe.Events.trigger("subtask_updated",response);row.show()},function(response){working_row.remove();row.show();App.Wireframe.Flash.error("Failed to update subtask. Please try again later")},function(){edit_row.remove();row.show()})},error:function(){working_row.remove();row.show();App.Wireframe.Flash.error("Failed to load edit form. Please try again later")}});return false})};var add_active=function(row){var last_active_task=subtasks_table.find("tr.subtask_active:last");if(last_active_task.length>0){last_active_task.after(row)}else{subtasks_table.find("tr.empty_row").after(row)}row.removeClass("subtask_completed").addClass("subtask_active")};var add_completed=function(row){var first_completed_task=subtasks_table.find("tr.subtask_completed:first");if(first_completed_task.length>0){first_completed_task.before(row)}else{subtasks_table.find("tr.show_old_completed").before(row)}row.removeClass("subtask_active").addClass("subtask_completed")};var create_working_row=function(){return $('<tr><td class="task_reorder"></td><td class="task_meta"></td><td class="task_content"><img src="'+App.Wireframe.Utils.indicatorUrl("small")+'" alt="" /> '+App.lang("Working")+'</td><td class="task_options"></td></tr>')};var show_subtask_form_row=function(row){row.show();var form=row.find("form.subtask_form");form.slideDown("fast",function(){form.find("div.subtask_summary").each(function(){$(this).find("input[type=text]").width($(this).width()-18).focus()})})};var hide_subtask_form_row=function(row){row.hide().find("form").hide()};var update_indicator_rows=function(){if(subtasks_table.find("tr.subtask").length>0){subtasks_table.find("tbody tr.empty_row").hide();subtasks_table.find("tr.add_and_manage a.reorder_subtasks").show()}else{subtasks_table.find("tbody tr.empty_row").show();subtasks_table.find("tr.add_and_manage a.reorder_subtasks").hide()}var completed_subtasks=subtasks_table.find("tr.subtask_completed");if(completed_subtasks.length==0){subtasks_table.find("tr.show_old_completed").hide()}else{if(completed_subtasks.length<=3){completed_subtasks.show();subtasks_table.find("tr.show_old_completed").hide()}else{var show_all_completed=subtasks_table.is("table.show_old_completed");if(show_all_completed){subtasks_table.find("tr.show_old_completed td.task_content a").text(App.lang("Show Only Recently Completed"))}else{subtasks_table.find("tr.show_old_completed td.task_content a").text(App.lang("Show All Completed (:count)",{count:completed_subtasks.length}))}var counter=1;completed_subtasks.each(function(){if(show_all_completed||counter<=3){$(this).show()}else{$(this).hide()}counter++});subtasks_table.find("tr.show_old_completed").show()}}};var handle_updates=function(){var scope=settings.event_scope;App.Wireframe.Events.bind(settings.object.event_names.updated+"."+scope+" "+settings.object.event_names.deleted+"."+scope,function(event,object){if(!(object["class"]==settings.object["class"]&&object.id==settings.object.id)){return false}var old_is_completed=settings.object.is_completed;settings.object=object;if(!object.is_completed){return false}if(old_is_completed){return false}subtasks_table.find("tr.subtask.subtask_active").each(function(){var row=$(this);var subtask=row.data("subtask");subtask.is_completed=object.is_completed;subtask.completed_on=object.completed_on;subtask.completed_by_id=object.completed_by_id;subtask.completed_by_name=object.completed_by_name;subtask.completed_by_email=object.completed_by_email;update(row,subtask);add_completed(row)});update_indicator_rows()});var object_inspector=wrapper.parents(".object_wrapper:first").find(".object_inspector:first");App.Wireframe.Events.bind("subtask_updated."+scope+"",function(event,subtask){if(!(subtask.parent_class==settings.object["class"]&&subtask.parent_id==settings.object.id)){return false}var row=subtasks_table.find('tr[subtask_id="'+subtask.id+'"]');if(object_inspector.length){object_inspector.objectInspector("refresh")}update(row,subtask)})};switch(action){case"init":if(settings.subtasks){$.each(settings.subtasks,function(){add(this,true)});update_indicator_rows()}handle_updates();break;case"add":add(subtask);break}})};