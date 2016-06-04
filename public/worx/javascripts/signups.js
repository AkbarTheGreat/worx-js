
var username;
var password;

jQuery.fn.dataTable.Api.register( 'sum()', function ( ) {
    return this.flatten().reduce( function ( a, b ) {
        if ( typeof a === 'string' ) {
            a = a.replace(/[^\d.-]/g, '') * 1;
        }
        if ( typeof b === 'string' ) {
            b = b.replace(/[^\d.-]/g, '') * 1;
        }
        return a + b;
    }, 0 );
} );


function populateTable( matrix, textStatus, jqXHR )
{
	var columns = [{'title': 'Member', 'data': 'member'}];
	matrix.days.forEach(function(val)
	{
		columns.push({'title': val, 'data': 'signups.'+val});
		$("#mfooter").append('<th></th>')
	});


	$('#matrix').DataTable(
	{
		'data': matrix.users,
		'columns' : columns,
		'rowReorder': true,

		drawCallback: function()
		{
			var api = this.api();

			// Total over all pages
			$(api.column(0).footer()).html('Total');

			api.columns().every(function(idx)
			{
				if (idx != 0)
				{
				var total = this.data().sum();
				$(this.footer()).html(total);
				}
			});
		}
	});

}

// Set up the datatable for the new view
function setupTable()
{
	$("#content").hide();
//	var headerString = '<table id="matrix" class="display compact" cellspacing="0" width="100%">';
	var headerString = '<table id="matrix" class="table table-striped table-bordered table-hover table-condensed" cellspacing="0" width="100%">';
	headerString += '<tfoot><tr id="mfooter"><th></th></tr></tfoot></table>';
	$("body").removeClass("startingBody");
	$("body").addClass("tableBody");
	$("#page").removeClass("startingPage");
	$("#page").addClass("tablePage");
	$("#page").append(headerString);
	response = $.ajax("matrix",
	                          {
	                             headers:  getHeaders(),
	                             dataType: 'json'
	                          }
	                      );
	response.success(populateTable);
	response.fail(function(){console.log('Fail.  Why?')});
}

function getHeaders()
{
	return {
	         "x-akbar-username": $("#username").val(),
	         "x-akbar-password": $("#password").val()
	       };
}

function verifyPassword(event)
{
	response = $.ajax("password_check",
	                            {
	                              headers:  getHeaders(),
	                              dataType: 'json'
	                            }
	                  );
	response.success(setupTable);
	response.fail(   function(){alert("Username/Password does not match, please try again")});
	event.preventDefault();
	return false;
}


$(function ()
	{
		$("#user_info").submit(verifyPassword);
	});
