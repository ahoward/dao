if(!window.Dao){
  (function(){
    window.Dao = {};

  // pull jQuery off the CDN iff needed 
  //
    !window.jQuery && document.write(unescape('%3Cscript src="js/libs/jquery-1.4.2.js"%3E%3C/script%3E'));
    var jq = jQuery;

  // ctor
  //
    Dao.Api = function(){
      this.route = '' + Dao.Api.route;
      this.result = null;
      this.results = [];
      this.mode = 'get';
      this.method = Dao[this.mode];
    };
    Dao.Api.route = '/api';
    Dao.Api.modes = ["options", "get", "head", "post", "put", "delete", "trace", "connect"];

  // single call interface
  //
    Dao.Api.prototype.call = function(){
      var api = this;
      var options = {};

      if(arguments.length == 1){
        var arg = arguments[0];

        if(typeof(arg)=='string'){
          options.path = arg;
        } else {
          options = arg;
        }
      }

      if(arguments.length > 1){
        options.path = arguments[0];

        if(typeof(arguments[1])=='function'){
          options.success = arguments[1];
          options.params = arguments[2];
        } else {
          options.params = arguments[1];
          options.success = arguments[2];
        }
      }

      if(!options.path){
        options.path = '/ping';
      }

      if(!options.params){
        options.params = {};
      }

      var url = api.route + options.path;
      var data = options.params;

      if(options.success){

        var returned = api;
        var success = function(result){
          var result = new Dao.Result(result);
          options.success(result);
        };

        var ajax = {'url' : url, 'data' : data, 'success' : success, 'async' : true};

        Dao[api.mode](ajax);
        return(returned);

      } else {

        var returned = null;
        var success = function(result){
          returned = new Dao.Result(result);
        };

        var ajax = {'url' : url, 'data' : data, 'success' : success, 'async' : false};

        Dao[api.mode](ajax);
        return(returned);

      };
    };
    Dao.Api.modes = ["options", "get", "head", "post", "put", "delete", "trace", "connect"];
    Dao.Api.result = null;
    Dao.Api.results = [];
    Dao.Api.defaults = {};
    Dao.Api.defaults.type = 'get';
    Dao.Api.defaults.url = '/';

  // meta-program Dao.Api.get(...), Dao.ajax.post(...)
  //
    for(var i = 0; i < Dao.Api.modes.length; i++){
      (function(){
        var mode = Dao.Api.modes[i];

        Dao.Api.prototype[mode] = function(){
          var args = Array.prototype.slice.call(arguments);
          var api = this;
          var default_type = Dao.Api.defaults.type;
          Dao.Api.defaults.type = mode.toUpperCase();
          var result = api.apply(api, args);
          Dao.Api.defaults.type = default_type;
          return(result);
        };
      })();
    }

  // short-cuts for read and write
  // 
    Dao.Api.prototype['read'] = Dao.Api.prototype['get'];
    Dao.Api.prototype['write'] = Dao.Api.prototype['post'];

  // a thin wrapper on results for now.  TODO - make it smarter
  //
    Dao.Result = function(options){
      this.path = options.path;
      this.status = options.status;
      this.errors = options.errors;
      this.data = options.data;

      //parts = ('' + this.status).split(/\s+/);
      //this.status.code = parseInt(parts.shift()); 
      //this.status.message = parts.join(' ');
    };

  // ajax utils
  //
    Dao.ajax = function(options){
      var ajax = {};
      ajax.type = options.type;
      ajax.url = options.url;
      ajax.dataType = 'json';
      ajax.cache = false;
      if(options.async==false || options.sync==true){
        ajax.async = false;
      };
      if(ajax.type == 'POST' || ajax.type == 'PUT'){
        ajax.data = jq.toJSON(options.data || {});
      } else {
        ajax.data = (options.data || {});
      };
      ajax.contentType = (options.contentType || 'application/json; charset=utf-8');
      ajax.success = (options.success || function(){});
      jq.ajax(ajax);
    };

  // meta-program Api.get(...), Api.post(...)
  //
    for(var i = 0; i < Dao.Api.modes.length; i++){
      (function(){
        var mode = Dao.Api.modes[i];

        Dao[mode] = function(options){
          options.type = mode.toUpperCase();
          Dao.ajax(options);
        };
      })();
    }

    Dao.api = new Dao.Api();
    window.api = window.api || Dao.api;
  }());
}
