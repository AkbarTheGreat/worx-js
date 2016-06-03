
var username;
var password;

// Set up the datatable for the new view
function setupTable()
{
	console.log("We have work to do");
}

function verifyPassword(event)
{
	username = $("#username").val();
	password = $("#password").val();
	response = $.ajax("password_check",
	                            {
	                              data: {username: username, password: password},
	                              dataType: 'json'
	                            }
	                  );
	response.success(setupTable);
	response.success(setupTable);
	response.fail(   function(){alert("Username/Password does not match, please try again")});
	console.log(response);
	event.preventDefault();
	return false;
}


$(function ()
	{
		$("#user_info").submit(verifyPassword);
	});
