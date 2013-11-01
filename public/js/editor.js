/*global $:true, ace:true, console:true, Spinner:true, document:true */
/*jshint forin:false */

(function(){
  "use strict";

var editor = ace.edit("editor"), 
    break_pattern = /.*l:(\d+):.*$/,
    current_line = 0,
    current_token,
    harp_id,
    spinner,
    spinner_opts = {
    lines: 13, // The number of lines to draw
    length: 20, // The length of each line
    width: 10, // The line thickness
    radius: 30, // The radius of the inner circle
    corners: 1, // Corner roundness (0..1)
    rotate: 0, // The rotation offset
    direction: 1, // 1: clockwise, -1: counterclockwise
    color: '#FFFACD', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 60, // Afterglow percentage
    shadow: false, // Whether to render a shadow
    hwaccel: false, // Whether to use hardware acceleration
    className: 'spinner', // The CSS class to assign to the spinner
    zIndex: 2e9, // The z-index (defaults to 2000000000)
    top: 'auto', // Top position relative to parent in px
    left: 'auto' // Left position relative to parent in px
};

editor.setTheme("ace/theme/vibrant_ink");
editor.getSession().setMode("ace/mode/ruby");
editor.on("guttermousedown", function(e){
    var target = e.domEvent.target, row = e.getDocumentPosition().row;
    if (target.className.indexOf("ace_gutter-cell") === -1) {
        e.editor.session.clearBreakpoint(row);
        return;
    }
    if (e.clientX > 25 + target.getBoundingClientRect().left) {
        return;
    }
    if (target.className.indexOf("breakpoint") === -1) {
        e.editor.session.setBreakpoint(row, " breakpoint");
        e.stop();
    } else {
        e.editor.session.clearBreakpoint(row);
        return;
    }
});

String.prototype.toCamelCase = function(){
    return this.replace(/(\-[a-z])/g, function($1){return $1.toUpperCase().replace('-','');});
};

function setExecutionLine(token) {
    var line = parseInt(break_pattern.exec(token)[1], 10);
    if (line !== undefined) {
        current_line = line+1;
        current_token = token;
        editor.session.addGutterDecoration(line, "current_line");
    }
}

function clearExecutionLine() {
    editor.session.removeGutterDecoration(current_line-1, "current_line");
    current_line = 0;
    current_token = undefined;
}

function setHarpId(harp_id) {
    $("#harpId").val(harp_id);
}

function prettyResult(data) {
    var msg = "", verb, line;
    if (data.hasOwnProperty('invoked')) {
        $.each(data.results, function (index, val) { 
            console.debug("Got:", index, val);
            $.each(val, function (action, desc) { 
                console.debug("Got desc:", desc);
                if (/create|update|destroy|break/.test(action)) {
                    verb = action.toCamelCase();
                    if (verb !== "break" && verb !== "error") {
                        verb += (verb.charAt(verb.length-1) === 'e')? "d":"ed";
                    }
                    msg += verb + ": " + desc + ".\n";
                }
                if (action === "output") {
                    clearExecutionLine();
                }
                if (action === "harp_id") {
                    msg += "Harp ID: " + desc + "\n";
                    harp_id = desc;
                    setHarpId(harp_id);
                }
                if (action === "token") {
                    clearExecutionLine();
                    setExecutionLine(desc);
                }
                if (action === "end") {
                    clearExecutionLine();
                }
            });
        });
    }
    if (data.hasOwnProperty('error')) {
        if (data.hasOwnProperty('description')) {
            msg += data.description + "\n";
        }
    }
    return msg;
}

function processResponse(data) {
    var text = prettyResult(data);
    $("#script_output").text(text);
}

function invoke(url, data) {
    var id, spin_target;
    $("#script_output").html("");
    $("#working").show();
    if (!spinner) {
        spin_target = document.getElementById("working");
        spinner = new Spinner(spinner_opts).spin(spin_target);
    }

    $.ajax({
        type: "POST",
        url: url,
        data: data,
        contentType: "application/x-harp; charset=utf-8",
        dataType: "json",
        success: function (data) { 
            processResponse(data);
        },
        failure: function (errMsg) {
            console.error(errMsg);
        }
    }).always(function() {
        spinner.stop();
        $("#working").hide();
    });
}

function invokeLifecycle(lifecycle, data, args) {
    args = args + "&mock=y";
    if (lifecycle !== "create") {
        lifecycle = lifecycle + "/" + harp_id;
    }
    return invoke("/api/v1/harp-debug/"+lifecycle+"?access=1234&secret=5678&auth=default_creds"+args, data);
}

function debugIt(lifecycle, data) {
    var index = 0, breakpoint, args = "";

    $.each(editor.session.getBreakpoints(), function(line, val) {
        if (val && (!breakpoint || line < breakpoint)) {
            if (current_line < line+1) {
                breakpoint = line+1;
            }
        }
    });
    if (breakpoint) {
        args = "&break=" + breakpoint;
    }
    invokeLifecycle(lifecycle, data, args);
}

function stepIt(lifecycle, data) {
    var index = 0, breakpoint, args = "";
    args = args + "&step=" + current_token;
    invokeLifecycle(lifecycle, data, args);
}

$(function() {
    $("a.invoke").click(function(evt) {
        var lifecycle = $("#lifecycle").text().toLowerCase();
        debugIt(lifecycle, editor.getValue());
    });
    $("a#step").click(function(evt) {
        var lifecycle = $("#lifecycle").text().toLowerCase();
        stepIt(lifecycle, editor.getValue());
    });
    $(".change_lifecycle").click(function(evt) {
        var lifecycle = $(evt.target).text();
        $("#lifecycle").text(lifecycle);
    });
    $("#harpId").change(function(evt) {
        harp_id = $(evt.target).text();
    });
});

}());
