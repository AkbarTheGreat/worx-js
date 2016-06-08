
var username;
var password;
var matrix;
var dataTable;
var lastSelectedMonth;

var checkmark = '<span class="glyphicon glyphicon-ok"></span>';

// A specialized sum that handles our markups instead of trying to handle guess at numbers from a string
jQuery.fn.dataTable.Api.register( 'sum()', function ( )
{
	return this.flatten().reduce( function ( a, b )
	{
		if ( typeof a === 'string' )
		{
			if ( a == ' ' )
			{
				a = 0;
			}
			else if ( a == checkmark )
			{
				a = 1;
			}
			else if ($(a).prop('checked'))
			{
				a = 1;
			}
			else
			{
				a = 0;
			}
		}
		if ( typeof b === 'string' )
		{
			if ( b == ' ' )
			{
				b = 0;
			}
			else if ( b == checkmark )
			{
				b = 1;
			}
			else if ($(b).prop('checked'))
			{
				b = 1;
			}
			else
			{
				b = 0;
			}
		}
		return a + b;
	}, 0 );
} );

function postDrawManipulation()
{
	var api = this.api();

	var numCols = api.columns().count();
	var numRows = api.columns().count();

	// Update total footer to be over all pages
	$(api.column(1).footer()).html('Total');

	api.columns().every(function(idx)
	{
		if ( (idx != 0) && (idx != 1) && (idx != (numCols-1)) )
		{
			var total = this.data().sum();
			$(this.footer()).html(total);
		}
	});

	// Update 1s and 0s to appropriate icons for sign-ups.
	api.cells().every(function(rowIdx, colIdx)
	{
		// Skip the first and last columns (name & total), but do all rows (since the header & footer are title and totals there)
		if ( (colIdx != 0) && (colIdx != (numCols-1)) )
		{
			if ( rowIdx == matrix.active_idx ) // Active user, we need checkboxes for whoever is using this
			{
				var colheader = api.column(colIdx).header();
				var showDate  = $(colheader).text().trim();
				if ( this.data() == '1' )
				{
					this.data('<input value="' + showDate + '" type="checkbox" class="show_check" checked="checked">');
				}
				else
				{
					if ( this.data() == '0' )
					{
						this.data('<input value="' + showDate + '" type="checkbox" class="show_check">');
					}
				}
			}
			else
			{
				if ( this.data() == '1' )
				{
					this.data(checkmark);
				}
				else
				{
					if ( this.data() == '0' )
					{
						this.data(' ');
					}
				}
			}
		}
	});
}

function saveData()
{
	var checkedDays = $(".show_check:checked").map(function()
	{
		return $(this).val();
	}).get().join();
	response = $.ajax("submit_signups",
	                          {
	                             headers:  getHeaders(),
	                             dataType: 'json',
	                             data:     { month: selectedMonth(),
	                                         days:  checkedDays
	                                       }
	                          }
	                      );
	response.success(refreshTable);
	response.fail(function(){console.log('Fail on refresh.  Why?')});
}

function populateTable( newMatrix, textStatus, jqXHR )
{
	matrix = newMatrix;
	var columns = [{'title': 'Active', 'visible': false, 'data': 'active_user'}, {'title': 'Member', 'data': 'member'}];
	matrix.days.forEach(function(val)
	{
		columns.push({'title': val, 'data': 'signups.'+val});
		$("#mfooter").append('<th></th>')
	});


	dataTable = $('#matrix_dt').DataTable(
	{
		'data':         matrix.users,
		'columns' :     columns,
		'rowReorder':   true,
		'drawCallback': postDrawManipulation,
		'order':        [ 0, 'desc' ]
	});

	dataTable.order.fixed(
	{
		pre: [ 0, 'desc' ]
	} );

	var leftButtons = '&nbsp&nbsp<select class="form-control monthSelector" name="month_select" id="month_select">';

	matrix.months.forEach(function(month)
	{
		leftButtons += '<option value="' + month + '"';
		if (month == matrix.current_month)
		{
			leftButtons += ' selected="selected"';
		}
		leftButtons += '>' + month + '</option>';
	});
	leftButtons += '</select>';

	leftButtons += '&nbsp&nbsp<button class="btn btn-primary" type="button" id="refresh_button">Update</button>';

	var rightButtons = '<button class="btn btn-primary" type="button" id="save_button">Save Signups</button>&nbsp&nbsp';

	$("#matrix_dt_length").append(leftButtons);
	$("#matrix_dt_filter").prepend(rightButtons);
	$("#save_button").click(saveData);
	$("#refresh_button").click(refreshTable);
}

function selectedMonth()
{
	if ( $("#month_select :selected").val() != undefined )
	{
		lastSelectedMonth = $("#month_select :selected").val()
	}
	return lastSelectedMonth;
}

function repopulateTable( newMatrix, textStatus, jqXHR )
{
	// We really have to just destroy & remake the table at this point, in order to remake the columns correctly
	destroyTable();
	makeTableTags();
	populateTable( newMatrix, textStatus, jqXHR);
}

function refreshTable()
{
	response = $.ajax("matrix",
	                          {
	                             headers:  getHeaders(),
	                             dataType: 'json',
	                             data:     { month: selectedMonth() }
	                          }
	                      );
	response.success(repopulateTable);
	response.fail(function(){console.log('Fail on refresh.  Why?')});
}

function destroyTable()
{
	dataTable.destroy();
	$("#matrix_dt").remove();
}

function makeTableTags()
{
	var headerString = '<table id="matrix_dt" class="table table-striped table-bordered table-hover table-condensed" cellspacing="0" width="100%">';
	headerString += '<tfoot><tr id="mfooter"><th></th></tr></tfoot></table>';
	$("#page").append(headerString);
}

// Set up the datatable for the new view
function setupTable()
{
	$("#content").hide();
	$("body").removeClass("startingBody");
	$("body").addClass("tableBody");
	$("#page").removeClass("startingPage");
	$("#page").addClass("tablePage");
	makeTableTags();
	response = $.ajax("matrix",
	                          {
	                             headers:  getHeaders(),
	                             dataType: 'json',
	                             data:     { month: selectedMonth() }
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
