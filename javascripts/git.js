jQuery.githubReleases = function(username, reponame, callback) {
   jQuery.getJSON('https://api.github.com/repos/'+username+'/'+reponame+'/releases?callback=?',callback)
}

jQuery.fn.loadLatestPreRelease = function(username, reponame) {
    this.html('<span>Querying GitHub...</span>');
     
    var target = this;
    $.githubReleases(username, reponame, function(data) {
        var releases = data.data; // JSON Parsing
 
        var output = $('<dl/>');
        target.empty().append(output);
        $(releases).each(function() {
           output.append('<dt>' + this.name + '</dt>');
           output.append('<input type="hidden" name="date" value="' + this.tag_name +'">');
           return false;
        });
        if(autoDownload){
           downloadSubmit();
        }
     });
}
