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
        options.params = arguments[1];
        options.success = arguments[2];
      }

      if(!options.path){
        options.path = '/ping';
      }

      if(!options.params){
        options.params = {};
      }

      if(!options.success){
        options.success = function(result){
          result = new Dao.Result(result);
          api.result = result;
          api.results.push(result);
        };
      }

      var url = api.route + options.path;

      var data = options.params;

      var success = function(result){
        var result = new Dao.Result(result);
        if(options.success){
          options.success(result);
        } else {
          api.result = result;
          api.results.push(result);
        }
      };

      var ajax = {};
      ajax.url = url;
      ajax.data = data;
      ajax.success = success;

      Dao[api.mode](ajax);
      return(api);
    };

  // meta-program api.read(..), api.post(...), ...
  //
    for(var i = 0; i < Dao.Api.modes.length; i++){
      (function(){
        var mode = Dao.Api.modes[i];

        Dao.Api.prototype[mode] = function(){
          var api = this;
          var previous = api.mode;
          api.mode = mode;
          var returned = api.call.apply(api, arguments);
          api.mode = previous;
          return(returned);
        };
      })();
    }
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
