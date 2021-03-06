{if $_document_versions_wrap}
<div class="file_versions" id="{$_document_versions_id}">
{/if}

  <div class="content_section_title"><h2>{lang}Text Document History{/lang}</h2></div>
  <div class="content_section_container">
      <table class="file_versions common" cellspacing="0">
      <thead>
      <tr>
        <th>{lang}Version{/lang}</th>
        <th>{lang}Details{/lang}</th>
        <th></th>
      </tr>
      </thead>
      <tbody>
	      <tr class="file_version latest {cycle values='odd,even'}">
	        <td class="version"><a href="{$_document_versions_document->getViewUrl()}">{lang}Latest Version{/lang}</a></td>
	        <td class="details">
	        {if $_document_versions_document->getVersionNum() == 1}
	          {$_document_versions_document->getCreatedOn()|ago nofilter} {lang}by{/lang} {user_link user=$_document_versions_document->getCreatedBy()}
	        {else}
	          {$_document_versions_document->getLastVersionOn()|ago nofilter} {lang}by{/lang} {user_link user=$_document_versions_document->getUpdatedBy()}
	        {/if}
	        </td>
	        <td class="options">
	          <span class="latest_document_version">{lang}Latest{/lang}</span>
	        </td>
	      </tr>
		    {if is_foreachable($_document_versions)}
		      {foreach from=$_document_versions item=_document_version name=document_revisions}
		      <tr class="file_version {cycle values='odd,even'}">
		        <td class="version"><a href="{$_document_version->getViewUrl()}">{lang}Version #{/lang}{$_document_version->getVersionNum()}</a></td>
		        <td class="details">{$_document_version->getCreatedOn()|ago nofilter} {lang}by{/lang} {user_link user=$_document_version->getCreatedBy()}</td>
		        <td class="options">
		          {if $_document_version->canDelete($_document_versions_user)}<a href="{$_document_version->getDeleteUrl()}" title="{lang}Delete Permanently{/lang}" class="remove_version"><img src="{image_url name="icons/12x12/delete.png" module=$smarty.const.ENVIRONMENT_FRAMEWORK}" alt="" /></a>{/if}
		        </td>
		      </tr>
		      {/foreach}
		    {/if}
      </tbody>
    </table>
  </div>

{if $_document_versions_wrap}
</div>

<script type="text/javascript">
  $('#{$_document_versions_id}').each(function() {
    var wrapper = $(this);

    var current_version = {$_document_versions_document->getVersionNum()|json nofilter};
    var versions_table = wrapper.find('table.file_versions');

    /**
     * Initialize row
     *
     * @param jQuery row
     */
    var init_row = function (row) {
      row.find('a.remove_version').asyncLink({
        'confirmation' : App.lang('Are you sure that you want to permanently remove this document version?'),
        'indicator_url' : App.Wireframe.Utils.imageUrl('layout/bits/indicator-loading-small.gif', 'environment'),
        'success' : function() {
          row.remove();
          App.Wireframe.Flash.success('Document version successfully removed');
        }, 
        'error' : function() {
          App.Wireframe.Flash.error('Failed to remove selected document version. Please try again later');
        }
      });
    }; // init_row

    // initialize every row
    versions_table.find('tr').each(function() {
      init_row($(this));
    });

    // asset edited
    App.Wireframe.Events.bind('asset_updated.single', function (event, asset) {
      if (asset['class'] == 'TextDocument' && typeof(asset['previous_version']) == 'object' && asset['previous_version']) {
        var table_body = versions_table.find('tbody:first');
        versions_table.find('tbody tr:eq(0)').remove();

        var previous_row = $('<tr class="file_version latest">' +
  	        '<td class="version"><a target="_blank" href="' + asset['previous_version']['urls']['view'] + '">' + App.lang('Version #:version_num', {
    	        'version_num' : asset['previous_version']['version']
    	      }) + '</a></td>' +
  	        '<td class="details"><span title="' + asset['previous_version'].created_on.formatted + '" class="ago">' + App.Wireframe.Utils.ago(asset['previous_version']['created_on']) + '</span> ' + App.lang('by') + ' <a class="user_link" href="' + asset['previous_version']['created_by']['permalink'] + '">' + App.clean(asset['previous_version']['created_by']['display_name']) + '</a></td>' +
  	        '<td class="options"><a class="remove_version" title="Delete Permanently" href="' + asset['previous_version']['urls']['delete'] + '"><img alt="" src="' + App.Wireframe.Utils.imageUrl('/icons/12x12/delete.png', 'environment') + '"></a></td>' +
  	      '</tr>').prependTo(table_body);
        init_row(previous_row);

        var latest_row = $('<tr class="file_version latest">' +
  	        '<td class="version"><a target="_blank" href="' + asset['urls']['view'] + '">' + App.lang('Latest Version') + '</a></td>' +
  	        '<td class="details"><span title="' + asset['created_on']['formatted'] + '" class="ago">' + App.Wireframe.Utils.ago(asset['created_on']) + '</span> ' + App.lang('by') + ' <a class="user_link" href="' + asset['created_by']['permalink'] + '">' + App.clean(asset['created_by']['display_name']) + '</a></td>' +
  	        '<td class="options"><span class="latest_file_version">' + App.lang('Latest') + '</span></td>' +
  	      '</tr>').prependTo(table_body);
      } // if
    });
  });
</script>
{/if}