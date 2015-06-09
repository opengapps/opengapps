jQuery.githubRepos = function(username, callback) {
   jQuery.getJSON('https://api.github.com/users/'+username+'/repos?callback=?',callback)
}

jQuery.githubDownloads = function(username, reponame, releaseid, callback) {
   jQuery.getJSON('https://api.github.com/repos/'+username+'/'+reponame+'/releases/'+releaseid+'/assets?callback=?',callback)
}

jQuery.githubLatest = function(username, reponame, callback) {
   jQuery.getJSON('https://api.github.com/repos/'+username+'/'+reponame+'/releases/latest?callback=?',callback)
}

jQuery.fn.loadRepositories = function(username) {
    this.html("<span>Querying GitHub for " + username +"'s repositories...</span>");
     
    var target = this;
    $.githubRepos(username, function(data) {
        var repos = data.data; // JSON Parsing
     
        var list = $('<dl/>');
        target.empty().append(list);
        $(repos).each(function() {
            if (this.name != (username.toLowerCase()+'.github.com')) {
                list.append('<dt><a href="'+ (this.homepage?this.homepage:this.html_url) +'">' + this.name + '</a> <em>'+(this.language?('('+this.language+')'):'')+'</em></dt>');
                list.append('<dd>' + this.description +'</dd>');
            }
        });      
      });
}

jQuery.fn.loadReleases = function(username, reponame) {
    this.html("<span>Querying GitHub for " + reponame +"'s releases...</span>");
     
    var target = this;
    $.githubReleases(username, reponame, function(data) {
        var releases = data.data; // JSON Parsing
 
        var list = $('<dl/>');
        target.empty().append(list);
        $(releases).each(function() {
         
                list.append('<dt><a href="'+ (this.url) +'">' + this.tag_name + '</a></dt>');
                list.append('<dd>' + this.created_at +'</dd>');

        });      
      });
      
}

jQuery.fn.loadDownloads = function(username, reponame, releaseid) {
    this.html("<span>Querying GitHub for " + releaseid +"'s downloads...</span>");
     
    var target = this;
    $.githubDownloads(username, reponame, releaseid, function(data) {
        var downloads = data.data; // JSON Parsing
 
        var list = $('<dl/>');
        target.empty().append(list);
        $(downloads).each(function() {
         
                list.append('<dt><a href="'+ (this.url) +'">' + this.name + '</a></dt>');
                list.append('<dd>' + this.download_count +'</dd>');

        });      
      });
      
}

jQuery.fn.loadLatest = function(username, reponame) {
    this.html("<span>Querying GitHub for " + reponame +"'s latest release...</span>");
     
    var target = this;
    $.githubLatest(username, reponame, function(data) {
        var latest = data.data; // JSON Parsing
 
        var list = $('<dl/>');
        target.empty().append(list);
        $(latest).each(function() {
         
                list.append('<dt><a href="'+ (this.url) +'">' + this.tag_name + '</a></dt>');
                list.append('<dd>' + this.created_at +'</dd>');

        });      
      });
      
}
