
var username;
var password;
var matrix;
var dataTable;
var lastSelectedMonth;

var checkmark = '<span class="glyphicon glyphicon-ok"></span>';

var headerString = '<table id="matrix_dt" class="matrix_cleanup table table-striped table-bordered table-hover table-condensed" cellspacing="0" width="100%">'
                 + '<thead><tr id="mheader1"><th></th><th></th></tr><tr id="mheader2"><th></th><th></th></tr></thead>'
                 + '<tfoot><tr id="mfooter"><th></th><th></th></tr></tfoot></table><p class="matrix_cleanup">* Yes Yard signups are for support only</p>';
//                 + '<div id="authorize-div" style="display: none" class="matrix_cleanup">'
//                 + '<span>Authorize access to Google Calendar API</span>'
//                 + '<button id="authorize-button" onclick="handleAuthClick(event)">'
//                 + 'Authorize'
//                 + '</button>'
//                 + '</div>'
//                 + '<pre id="output" class="matrix_cleanup"></pre>';

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

	api.columns().every(function(colIdx)
	{
		// Skip the first two and last two columns (name, active & totals), but do all rows (since the header & footer are title and totals there)
		if ( (colIdx != 0) && (colIdx != 1) && (colIdx != (numCols-2)) && (colIdx != (numCols-1)) )
		{
			var total = this.data().sum();
			$(this.footer()).html(total);
		}
	});

	// Update 1s and 0s to appropriate icons for sign-ups.
	api.cells().every(function(rowIdx, colIdx)
	{
		// Skip the first two and last two columns (name, active & totals), but do all rows (since the header & footer are title and totals there)
		if ( (colIdx != 0) && (colIdx != (numCols-2)) && (colIdx != (numCols-1)) )
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
		var type = matrix.show_types[val];

		if ( type != undefined )
		{
			if ( type == 'ComedyWorx' )
			{
				type = 'CWX';
			}

			if ( type == 'Yes Yard (support only)' )
			{
				type = 'Yes Yard*';
			}

			$("#mheader1").append('<th>' + type + '</th>');
			$("#mheader2").append('<th></th>');
			columns.push({'title': val, 'data': 'signups.'+val});
			$("#mfooter").append('<th></th>')
		}
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

	// Cribbed from here to override the built-in searching:  https://stackoverflow.com/questions/33379684/datatables-row-always-visibile-or-dont-hide-row-or-dont-search-row-or-pin-ro
	$('.dataTables_filter input').unbind().bind('keyup', function()
	{
		var searchTerms = this.value.toLowerCase().split(' ');
		$.fn.dataTable.ext.search.push( function( settings, data, dataIndex )
		{
			if (data[0] == 1)
			{
				return true; // Always return true for the active user
			}

			//search normally by comparing content in each row with searchTerm
			for (var s=0;s<searchTerms.length;s++)
			{
				for (var i=0;i<data.length;i++)
				{
					if (~data[i].toLowerCase().indexOf(searchTerms[s])) return true;
				}
			}
			return false;
		});
		dataTable.draw();
		$.fn.dataTable.ext.search.pop();
	});

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
	$(".matrix_cleanup").remove();
}

function makeTableTags()
{
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


function addGoogleCalendarEvents()
{
var event = {
		  'summary': 'Test Item',
		  'location': 'CWX Address',
		  'description': 'Support or Perform at CWX',
		  'start': {
		    'dateTime': '2016-05-28T09:00:00-07:00',
		    'timeZone': 'America/Los_Angeles'
		  },
		  'end': {
		    'dateTime': '2015-05-28T17:00:00-07:00',
		    'timeZone': 'America/Los_Angeles'
		  },
		  'recurrence': [
		    'RRULE:FREQ=DAILY;COUNT=2'
		  ],
		  'attendees': [
		    {'email': 'lpage@example.com'},
		    {'email': 'sbrin@example.com'}
		  ],
		  'reminders': {
		    'useDefault': false,
		    'overrides': [
		      {'method': 'email', 'minutes': 24 * 60},
		      {'method': 'popup', 'minutes': 10}
		    ]
		  }
		};

		var request = gapi.client.calendar.events.insert({
		  'calendarId': 'primary',
		  'resource': event
		});
}




