{use_widget name="objects_list" module="environment"}

<script type="text/javascript">
$('#new_project_task').flyoutForm({
  'success_event' : 'task_created',
  'title' : App.lang('New Task')
});

$('#tasks').each(function() {
  var wrapper = $(this);

  var project_id = '{$active_project->getId() nofilter}';
  var categories_map = {$categories|map nofilter};
  var milestones_map = {$milestones|map nofilter};
  var labels_map = {$labels|map nofilter};
  var users_map = {$users|map nofilter};
  var priority_map = {$priority|map nofilter};
  var reorder_url = '{assemble route=project_tasks_reorder project_slug=$active_project->getSlug()}';

  var print_url = {$print_url|json nofilter};

  var grouping = [{
    'label' : App.lang("Don't group"),
    'property' : '',
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/dont-group.png', 'environment')
  }, {
    'label' : App.lang('By Category'),
    'property' : 'category_id' ,
    'map' : categories_map,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-category.png', 'categories'),
    'default' : true
  }, {
    'label' : App.lang('By Milestone'),
    'property' : 'milestone_id',
    'map' : milestones_map ,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-milestones.png', 'system'),
    'uncategorized_label' : App.lang('No Milestone')
  }, {
    'label' : App.lang('By Label'),
    'property' : 'label_id',
    'map' : labels_map ,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-label.png', 'labels'),
    'uncategorized_label' : App.lang('No Label')
  }, {
    'label' : App.lang('By Assignee'),
    'property' : 'assignee_id',
    'map' : users_map ,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-client.png', 'system'),
    'uncategorized_label' : App.lang('Not Assigned')
  }, {
    'label' : App.lang('By Delegate'),
    'property' : 'delegated_by_id',
    'map' : users_map ,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-client.png', 'system'),
    'uncategorized_label' : App.lang('Not Delegated')
  }, {
    'label' : App.lang('By Priority'),
    'property' : 'priority',
    'map' : priority_map ,
    'icon' : App.Wireframe.Utils.imageUrl('objects-list/group-by-priority.png', 'system'),
    'uncategorized_label' : App.lang('No Priority')
  }];

  {custom_fields_prepare_objects_list grouping_variable=grouping type='Task' sample=$active_task}

  var init_options = {
    'id' : 'project_' + {$active_project->getId()} + '_tasks',
    'items' : {$tasks|json nofilter},
    'required_fields' : ['id', 'name', 'category_id', 'milestone_id', 'task_id', 'is_completed', 'permalink'],
    'requirements' : {
      'project_id' : '{$active_project->getId()}',
    },
    'objects_type' : 'tasks',
    'print_url' : print_url,
    'events' : App.standardObjectsListEvents(),
    'multi_title' : App.lang(':num Tasks Selected'),
    'multi_url' : '{assemble route=project_tasks_mass_edit project_slug=$active_project->getSlug()}',
    'multi_actions' : {$mass_manager|json nofilter},
    'reorder_url' : reorder_url,
    'prepare_item' : function (item) {
      var result = {
        'id'              : item['id'],
        'name'            : item['name'],
        'project_id'      : item['project_id'],
        'task_id'         : item['task_id'],
        'is_completed'    : item['is_completed'],
        'priority'        : item['priority'],
        'permalink'       : item['permalink'],
        'is_favorite'     : item['is_favorite'],
        'total_subtasks'  : item['total_subtasks'],
        'open_subtasks'   : item['open_subtasks'],
        'is_trashed'      : item['state'] == '1' ? 1 : 0,
        'is_archived'     : item['state'] == '2' ? 1 : 0,
        'label'           : item['label'],
        'visibility'      : item['visibility']
      };

      if(typeof(item['assignee']) == 'undefined') {
        result['assignee_id'] = item['assignee_id'];
      } else {
        result['assignee_id'] = item['assignee'] ? item['assignee']['id'] : 0;
      } // if

      if(typeof(item['delegated_by']) == 'undefined') {
        result['delegated_by_id'] = item['delegated_by_id'];
      } else {
        result['delegated_by_id'] = item['delegated_by'] ? item['delegated_by']['id'] : 0;
      } // if

      if(typeof(item['category']) == 'undefined') {
        result['category_id'] = item['category_id'];
      } else {
        result['category_id'] = item['category'] ? item['category']['id'] : 0;
      } // if

      if(typeof(item['milestone']) == 'undefined') {
        result['milestone_id'] = item['milestone_id'];
      } else {
        result['milestone_id'] = item['milestone'] ? item['milestone']['id'] : 0;
      } // if

      if(typeof(item['label']) == 'undefined') {
        result['label_id'] = item['label_id'];
      } else {
        result['label_id'] = item['label'] ? item['label']['id'] : 0;
      } // if

      // Put custom field values as fields, so group by feature can find them
      if(typeof(item['custom_fields']) == 'object' && item['custom_fields']) {
        App.each(item['custom_fields'], function(field_name, details) {
          result[field_name] = details['value'];
        });
      } // if

      return result;
    },
    'render_item' : function (item) {
      var row = '<td class="task_name">' +
        '<span class="task_name_wrapper">' +
        '<span class="task_id">#' + item['task_id'] + '</span>';

      // label
      row += App.Wireframe.Utils.renderLabelTag(item.label);

      // task name
      row += '<span class="real_task_name">' + App.clean(item['name']) + App.Wireframe.Utils.renderVisibilityIndicator(item['visibility']) + '</span></span></td><td class="task_options">';

      // Completed task
      if(item['is_completed']) {
        if(typeof(item['tracked_time']) != 'undefined' && item['tracked_time']) {
          row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-blue-100.png', 'complete') + '">';
        } else {
          row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-mono-100.png', 'complete') + '">';
        } // if

        // Still open
      } else {
        var total_subtasks = typeof(item['total_subtasks']) != 'undefined' && item['total_subtasks'] ? item['total_subtasks'] : 0;
        var open_subtasks = typeof(item['open_subtasks']) != 'undefined' && item['open_subtasks'] ? item['open_subtasks'] : 0;
        var completed_subtasks = total_subtasks - open_subtasks;

        var color_class = 'mono';

        if(typeof(item['estimated_time']) != 'undefined' && typeof(item['tracked_time']) != 'undefined') {
          if(item['estimated_time'] > 0) {
            if(item['tracked_time'] > item['estimated_time']) {
              var color_class = 'red';
            } else if(item['tracked_time'] > 0) {
              var color_class = 'blue';
            } // if
          } else if(item['tracked_time'] > 0) {
            var color_class = 'blue';
          } // if
        } // if

        if (item['is_completed']) {
          row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-100.png', 'complete') + '">';
        } else if (completed_subtasks == 0) {
          row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-0.png', 'complete') + '">';
        } else {
          if(completed_subtasks >= total_subtasks) {
            row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-100.png', 'complete') + '">';
          } else {
            var percentage = Math.ceil((completed_subtasks / total_subtasks) * 100);

            if(percentage <= 10) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-0.png', 'complete') + '">';
            } else if(percentage <= 20) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-10.png', 'complete') + '">';
            } else if(percentage <= 30) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-20.png', 'complete') + '">';
            } else if(percentage <= 40) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-30.png', 'complete') + '">';
            } else if(percentage <= 50) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-40.png', 'complete') + '">';
            } else if(percentage <= 60) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-50.png', 'complete') + '">';
            } else if(percentage <= 70) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-60.png', 'complete') + '">';
            } else if(percentage <= 80) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-70.png', 'complete') + '">';
            } else if(percentage <= 90) {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-80.png', 'complete') + '">';
            } else {
                row += '<img src="' + App.Wireframe.Utils.imageUrl('progress/progress-' + color_class + '-90.png', 'complete') + '">';
            } // if
          } // if
        } // if
      } // if

      row += '</td>';

      return row;
    },

    'search_index' : function (item) {
      return App.clean(item.name) + ' ' + '#' + item.task_id;
    },

    'grouping' : grouping,
    'filtering' : []
  };

  if (!{$in_archive|json nofilter}) {
    init_options.filtering.push({
      'label' : App.lang('Status'),
      'property' : 'is_completed',
      'values' : [{
        'label' : App.lang('All Tasks'),
        'value' : '',
        'icon' : App.Wireframe.Utils.imageUrl('objects-list/active-and-completed.png', 'complete'),
        'breadcrumbs' : App.lang('All Tasks')
      }, {
        'label' : App.lang('Open Tasks'),
        'value' : '0',
        'icon' : App.Wireframe.Utils.imageUrl('objects-list/active.png', 'complete'),
        'default' : true,
        'breadcrumbs' : App.lang('Open Tasks')
      }, {
        'label' : App.lang('Completed Tasks'),
        'value' : '1',
        'icon' : App.Wireframe.Utils.imageUrl('objects-list/completed.png', 'complete'),
        'breadcrumbs' : App.lang('Completed Tasks')
      }]
    });

    init_options.requirements.is_archived = 0;
  } else {
    init_options.requirements.is_archived = 1;
  } // if

  wrapper.objectsList(init_options);

  if (!{$in_archive|json nofilter}) {
    // Task added
    App.Wireframe.Events.bind('task_created.content', function (event, task) {
      if (task['project_id'] == project_id) {
        wrapper.objectsList('add_item', task);
      } else {
        if ($.cookie('ac_redirect_to_target_project')) {
          App.Wireframe.Content.setFromUrl(task['urls']['view']);
        } // if
      } // if
    });
  } // if

  // Task updated
  App.Wireframe.Events.bind('task_updated.content', function (event, task) {
    wrapper.objectsList('update_item', task);// if
  });

    // Task moved
  App.Wireframe.Events.bind('task_moved.content', function (event, task) {
    if ($.cookie('ac_redirect_to_target_project')) {
      App.Wireframe.Content.setFromUrl(task['urls']['view']);
    } else {
      wrapper.objectsList('delete_selected_item');
    } // if
  });

  // Task deleted
  App.Wireframe.Events.bind('task_deleted.content', function (event, task) {
    if (task['project_id'] == project_id) {
      if (wrapper.objectsList('is_loaded', task['id'], false)) {
        wrapper.objectsList('load_empty');
      } // if
      wrapper.objectsList('delete_item', task['id']);
    } // if
  });

  // Manage mappings
  App.objects_list_keep_milestones_map_up_to_date(wrapper, 'milestone_id', project_id);

  // Kepp categories map up to date
  App.objects_list_keep_categories_map_up_to_date(wrapper, 'category_id', {$active_task->category()->getCategoryContextString()|json nofilter}, {$active_task->category()->getCategoryClass()|json nofilter});

  // Pre select item if this is permalink
  {if $active_task->isLoaded()}
    wrapper.objectsList('load_item', {$active_task->getId()|json}, '{$active_task->getViewUrl()}');
  {/if}
});
</script>