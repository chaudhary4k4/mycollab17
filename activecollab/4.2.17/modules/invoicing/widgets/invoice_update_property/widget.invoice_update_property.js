(function($){var update_property=function(wrapper,property_name,property_value,auto_hide){auto_hide=auto_hide===undefined?true:auto_hide;property_value=$.trim(property_value);property_value=property_value===""?null:property_value;var property=wrapper.find(".property_"+property_name);var property_wrapper=property.is(".property_wrapper")?property:property.parents(".property_wrapper:first");property.html(property_value);if((property_value===null||property_value===undefined)&&auto_hide){property_wrapper.hide()}else{if(property_value&&!property_wrapper.is(":visible")){property_wrapper.show()}}};$.fn.invoiceUpdateProperty=function(name,value,auto_hide){var $this=this;if($.isArray(name)){$.each(name,function(index,element){if(element.name){update_property($this,element.name,element.value?element.value:null,element.auto_hide)}})}else{update_property(this,name,value,auto_hide)}return this}})(jQuery);