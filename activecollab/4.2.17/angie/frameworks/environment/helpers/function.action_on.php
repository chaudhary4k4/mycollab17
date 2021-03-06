<?php

  /**
   * action_on helper
   *
   * @package activeCollab.modules.system
   * @subpackage helpers
   */
  
  /**
   * Renders action string with time when action was taken
   * 
   * Parameteres:
   * 
   * - action - Action string, default is 'Posted'. It is used for lang retrival
   * - datetime - Datetime object when action was taken
   * - format - Format in with time is displayed. Possible values are ago, 
   *   datetime, date and time. Default is 'ago'
   *
   * @param array $params
   * @param Smarty $smarty
   * @return string
   */
  function smarty_function_action_on($params, &$smarty) {
    $action = clean(array_var($params, 'action', 'Posted'));
    
    $datetime = array_var($params, 'datetime');
    if(!($datetime instanceof DateValue)) {
      return new InvalidParamError('datetime', $datetime, '$datetime is expected to be an instance of DateValue or DateTimeValue class', true);
    } // if
    
    $format = array_var($params, 'format', 'ago');
    if(!in_array($format, array('ago', 'date', 'datetime', 'time'))) {
      return new InvalidParamError('format', $format, 'Format is requred to be one of following four values: ago, date, datetime or time', true);
    } // if
    
    switch($format) {
      case 'date':
        AngieApplication::useHelper('date', GLOBALIZATION_FRAMEWORK, 'modifier');
        $formatted_datetime = smarty_modifier_date($datetime);
        break;
      case 'time':
        AngieApplication::useHelper('time', GLOBALIZATION_FRAMEWORK, 'modifier');
        $formatted_datetime = smarty_modifier_time($datetime);
        break;
      case 'datetime':
        AngieApplication::useHelper('datetime', GLOBALIZATION_FRAMEWORK, 'modifier');
        $formatted_datetime = smarty_modifier_datetime($datetime);
        break;
      default:
        AngieApplication::useHelper('ago', GLOBALIZATION_FRAMEWORK, 'modifier');
        $formatted_datetime = smarty_modifier_ago($datetime);
    } // switch
    
    return lang($action) . ' ' . $formatted_datetime;
  } // smarty_function_action_on

?>