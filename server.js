// Generated by IcedCoffeeScript 1.6.2d
(function() {
  var cp, sites;



  cp = require('child_process');

  sites = require('require-all')({
    dirname: __dirname + '/sites',
    filter: /(.+)\.js$/
  });

  console.dir(sites);

}).call(this);
