<?php

  // Built on top of users controller
  AngieApplication::useController('users', SYSTEM_MODULE);

  /**
   * User projects controller
   *
   * @package activeCollab.modules.system
   * @subpackage controllers
   */
  class UserProjectsController extends UsersController {
    
    /**
     * Prepare controller
     */
    function __before() {
      parent::__before();
      
      if($this->active_user->isNew()) {
        $this->response->notFound();
      } // if
      
      $this->wireframe->breadcrumbs->add('user_projects', lang('Projects'), $this->active_user->getProjectsUrl());
      
      if($this->request->isWebBrowser()) {
        if($this->logged_user->isProjectManager()) {
          $this->wireframe->actions->add('add_to_projects', lang('Add to Projects'), $this->active_user->getAddToProjectsUrl());
        } // if
      } // if
    } // __construct
    
    /**
     * Show projects page
     */
    function index() {
      $projects_table = TABLE_PREFIX . 'projects';

      if($this->request->isApiCall()) {
        $conditions = DB::prepare("$projects_table.state >= ? AND $projects_table.completed_on IS NULL", STATE_VISIBLE);

        if ($this->logged_user->is($this->active_user) || $this->logged_user->isProjectManager()) {
          $projects = Projects::findByUser($this->active_user, false, $conditions);
        } else {
          $projects = Projects::findCommonProjects($this->logged_user, $this->active_user, $conditions);
        } // if

        $this->response->respondWithData($projects, array( 'as' => 'projects' ));
      } else {
        $user_projects_url = Router::assemble("people_company_user_projects", array("company_id" => $this->active_company->getId(), 'user_id' => $this->active_user->getId()));

        $conditions = array();
        if ($this->request->get('archive')) {
          $conditions[] = DB::prepare("p.state = ?", STATE_ARCHIVED);
          $order_by = "completed_on DESC";
          $projects_toggle_url = $user_projects_url;
          $projects_toggle_text = lang("Show Active Projects");
        } else {
          $conditions[] = DB::prepare("p.state = ?", STATE_VISIBLE);
          $order_by = "p.completed_on asc, p.name ASC";
          $projects_toggle_url = extend_url($user_projects_url, array('archive' => 1));
          $projects_toggle_text = lang("Show Archived Projects");
        } // if

        $conditions[] = "u.user_id = {$this->active_user->getId()}";

        if (!(($this->logged_user->getId() == $this->active_user->getId()) || $this->logged_user->isProjectManager())) {
          $common_project_ids = Projects::findCommonProjectIds($this->logged_user, $this->active_user);
          if (is_foreachable($common_project_ids)) {
            $conditions[] = DB::prepare("p.id IN (?) AND u.user_id = {$this->active_user->getId()}", $common_project_ids);
          } // if
        } // if

        $conditions_sql = is_foreachable($conditions) ? ("WHERE " . implode(" AND ", $conditions)) : "";

        $projects = DB::execute("SELECT p.id, p.leader_id, p.name, p.slug, p.completed_on, p.label_id, u.role_id FROM " . TABLE_PREFIX . "projects p LEFT JOIN " . TABLE_PREFIX . "project_users u ON p.id = u.project_id {$conditions_sql} ORDER BY {$order_by}");

        $this->response->assign(array(
          "is_archive" => (boolean) $this->request->get('archive'),
          "projects" => $projects,
          "project_url" => Router::assemble('project', array("project_slug" => "--SLUG--")),
          "user_permissions_url" => Router::assemble('project_user_permissions', array('project_slug' => '--SLUG--', 'user_id' => '--UID--')),
          "user_remove_url" => Router::assemble('project_remove_user', array('project_slug' => '--SLUG--', 'user_id' => '--UID--')),
          "project_labels" => Labels::getIdDetailsMap('ProjectLabel'),
          "project_roles" => ProjectRoles::getIdNameMap(),
          "projects_toggle_url" => $projects_toggle_url,
          "projects_toggle_text" => $projects_toggle_text
        ));
      } // if
    } // index
       
    /**
     * Show and process add to projects page
     */
    function add_to_projects() {
      if($this->request->isAsyncCall() || ($this->request->isApiCall() && $this->request->isSubmitted())) {
        if($this->logged_user->isProjectManager()) {
          $this->smarty->assign(array(
            'exclude_project_ids' => Projects::findIdsByUser($this->active_user, false),
            'default_project_role_id' => (integer) DB::executeFirstCell("SELECT id FROM " . TABLE_PREFIX . "project_roles WHERE is_default = 1")
          ));
          
          if($this->request->isSubmitted()) {
            $project_ids = $this->request->post('projects');
            
            if ($project_ids) {
              $projects = Projects::findByIds($project_ids);
              
              $project_permissions = $this->request->post('project_permissions');
              $role = null;
              $role_id = (integer) array_var($project_permissions, 'role_id');
                  
              if($role_id) {
                $role = ProjectRoles::findById($role_id);
              } // if
                 
              if($role instanceof ProjectRole) {
                $permissions = null;
              } else {
                $permissions = array_var($project_permissions, 'permissions');
                if(!is_array($permissions)) {
                  $permissions = null;
                } // if
              } // if
              
              if(is_foreachable($projects)) {
                try {
                  DB::beginWork('Adding projects to user @ ' . __CLASS__);
                  
                  foreach($projects as $project) {
                    $project->users()->add($this->active_user, $role, $permissions);
                  } // foreach
                  
                  DB::commit('Projects added to user @ ' . __CLASS__);

                  clean_menu_projects_and_quick_add_cache($this->active_user);
                  
                  $this->response->respondWithData($this->active_user->projects(), array(
                    'as' => 'user_projects',
                  ));
                } catch(Exception $e) {
                  DB::rollback('Failed to add projects to user @ ' . __CLASS__);
                  $this->response->exception($e);
                } // try
              } // if
            } // if
            $this->response->respondWithData($this->active_user->projects()->get($this->logged_user), array('as' => 'user_projects'));
          } // if
        } else {
          $this->response->forbidden();
        } //if
      } else {
        $this->response->badRequest();
      } //if
    } // add_to_projects
    
    /**
     * Show user projects archive page
     */
    function archive() {
      if($this->request->isMobileDevice()) {
        if($this->logged_user->is($this->active_user) || $this->logged_user->isProjectManager()) {
          $completed_projects = Projects::findCompletedByUser($this->active_user);
        } else {
          $users_completed_projects_ids = objects_array_extract(Projects::findCompletedByUser($this->active_user), "getId");
          $logged_users_completed_projects_ids = objects_array_extract(Projects::findCompletedByUser($this->logged_user), "getId");
          
          $common_completed_project_ids = array_intersect($users_completed_projects_ids, $logged_users_completed_projects_ids);
          $completed_projects = is_array($common_completed_project_ids) ? Projects::findByIds($common_completed_project_ids) : null;
        } // if
        
        $this->smarty->assign('completed_projects', $completed_projects);
      } else {
        $this->response->badRequest();
      } // if
    } // archive
    
  }