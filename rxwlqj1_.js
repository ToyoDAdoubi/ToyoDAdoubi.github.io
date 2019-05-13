/*************************** Toggle Content ***************************/

jQuery(document).ready(function(){
	jQuery(".toggle-box").hide(); 
	
	jQuery(".toggle").toggle(function(){
		jQuery(this).addClass("toggle-active");
		jQuery("i.fa fa-chevron-right").addClass("fa-chevron-down");
		jQuery("i.fa fa-chevron-down fa-chevron-down").removeClass("fa-chevron-right");
		}, function () {
		jQuery(this).removeClass("toggle-active");
		jQuery("i.fa fa-chevron-down").addClass("fa-chevron-down");
		jQuery("i.fa fa-chevron-down fa-chevron-down").removeClass("fa-chevron-down");
	});
	
	jQuery(".toggle").click(function(){
		jQuery(this).next(".toggle-box").slideToggle();
	});
});