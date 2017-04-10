# -*- encoding : utf-8 -*-
module Dao
  class Status < ::String
  ## http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
  #
    Code2Message = (
      {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",

        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        226 => "IM Used",

        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",

        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Request Entity Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        420 => "Enhance Your Calm",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",

        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        507 => "Insufficient Storage",
        510 => "Not Extended",


      ### ref: https://github.com/joho/7XX-rfc

      #70X => "Inexcusable",
        701 => "Meh",
        702 => "Emacs",

      #71X => "Novelty Implementations",
        710 => "PHP",
        711 => "Convenience Store",
        719 => "I am not a teapot",

      #72X => "Edge Cases",
        720 => "Unpossible",
        721 => "Known Unknowns",
        722 => "Unknown Unknowns",
        723 => "Tricky",
        724 => "This line should be unreachable",
        725 => "It works on my machine",
        726 => "It's a feature, not a bug",

      #73X => "Fucking",
        731 => "Fucking Rubygems",
        732 => "Fucking Unicode",
        733 => "Fucking Deadlocks",
        734 => "Fucking Deferreds",
        735 => "Fucking IE",
        736 => "Fucking Race Conditions",
        737 => "FuckThreadsing",
        738 => "Fucking Bundler",
        739 => "Fucking Windows",

      #74X => "Meme Driven",
        741 => "Compiling",
        742 => "A kitten dies",
        743 => "I thought I knew regular expressions",
        744 => "Y U NO write integration tests?",
        745 => "I don't always test my code, but when I do I do it in production",
        746 => "Missed Ballmer Peak",
        747 => "Motherfucking Snakes on the Motherfucking Plane",
        748 => "Confounded by Ponies",
        749 => "Reserved for Chuck Norris",

      #75X => "Syntax Errors",
        750 => "Didn't bother to compile it",
        753 => "Syntax Error",

      #76X => "Substance-Affected Developer",
        761 => "Hungover",
        762 => "Stoned",
        763 => "Under-Caffeinated",
        764 => "Over-Caffeinated",
        765 => "Railscamp",
        766 => "Sober",
        767 => "Drunk",

      #77X => "Predictable Problems",
        771 => "Cached for too long",
        772 => "Not cached long enough",
        773 => "Not cached at all",
        774 => "Why was this cached?",
        776 => "Error on the Exception",
        777 => "Coincidence",
        778 => "Off By One Error",
        779 => "Off By Too Many To Count Error",

      #78X => "Somebody Else's Problem",
        781 => "Operations",
        782 => "QA",
        783 => "It was a customer request, honestly",
        784 => "Management, obviously",
        785 => "TPS Cover Sheet not attached",

      #79X => "Internet crashed",
        797 => "This is the last page of the Internet. Go back",
        799 => "End of the world"
      }
    ) unless defined?(Code2Message)

    Groups = ({
      100 => 'instruction',
      200 => 'success',
      300 => 'redirection',
      400 => 'client_error',
      500 => 'server_error',
      700 => 'developer_error'
    }) unless defined?(Groups)

  # class methods
  #
    class << Status
      def list
        @list ||= Symbol2Code.sort_by{|sym, code| code}.map{|sym, code| send(sym)}
      end

      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/\s+/, '_').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          gsub(/[^A-Za-z0-9_]/, '_').
          tr("-", "_").
          squeeze('_').
          gsub(/^_+/, '').
          gsub(/_+$/, '').
          downcase
      end

      def default
        Status.for(200)
      end

      def for(*args)
        if args.size >= 2
          code = args.shift
          message = args.join(' ')
          new(code, message)
        else
          arg = args.shift
          case arg
            when Result
              result = arg
              if arg.errors.nil? or arg.errors.empty? or arg.valid?
                new(200)
              else
                new(500)
              end
            when Status
              arg
            when Integer
              code = arg
              message = Code2Message[code]
              new(code, message)
            when Symbol, String
              if arg.to_s =~ %r/^\d+$/
                code = arg.to_i
              else
                sym = Status.underscore(arg).to_sym
                code = Symbol2Code[sym]
              end
              if code
                message = Code2Message[code]
              else
                code = 500
                message = "Unknown Status #{ arg }"
              end
              new(code, message)
            else
              if arg.respond_to?(:code) and arg.respond_to?(:message)
                code, message = arg.code, arg.message
                new(code, message)
              else
                parse(arg)
              end
          end
        end
      end

      def parse(string)
        first, last = string.to_s.strip.split(%r/\s+/, 2)
        if first =~ %r/^\d+$/
          code = Integer(first)
          message = last
        else
          code = 500
          message = "Unknown Status #{ string.inspect }"
        end
        new(code, message)
      end
    end

    Symbol2Code = (
      Code2Message.inject(Hash.new) do |hash, (code, message)|
        sym = Status.underscore(message.gsub(/\s+/, "_")).to_sym
        hash.update(sym => code)
      end
    ) unless defined?(Symbol2Code)

    Symbol2Code.each do |sym, code|
      module_eval <<-__
        def Status.#{ sym }()
          @#{ sym } ||= Status.for(:#{ sym }).freeze
        end
      __
    end

  # instance methods
  #
    attr_accessor :code
    attr_accessor :message
    attr_accessor :group
    attr_accessor :source

    def initialize(*args)
      update(*args)
    end

    def update(*args)
      code, message =
        if args.size == 2
          [args.first, args.last]
        else
          status = Status.for(args.first || 200)
          [status.code, status.message]
        end
      @code, @message = Integer(code), String(message)
      @group = (@code / 100) * 100
      replace("#{ @code } #{ @message }".strip)
    end
    alias_method('set', 'update')

    def ok!
      update(200)
    end

    Groups.each do |code, group|
      module_eval <<-__, __FILE__, __LINE__ -1
        def Status.#{ group }
          @status_group_#{ group } ||= Status.for(#{ code })
        end

        def #{ group }?()
          #{ code } == @group
        end
      __
    end

    def good?
      @group < 400
    end
    alias_method('ok?', 'good?')

    def bad?
      @group >= 400
    end
    alias_method('error?', 'bad?')

    def =~(other)
      begin
        other = Status.for(other)
        self.group == other.group
      rescue
        false
      end
    end

    def ==(other)
      begin
        other = Status.for(other)
        self.code == other.code and self.message == other.message
      rescue
        false
      end
    end

    def clone
      clone = Status.for(code)
    end

    def to_json(*args, &block)
      Map[:code, code, :message, message].to_json(*args, &block)
    end
  end

  def Dao.status(*args, &block)
    if args.empty? and block.nil?
      Status
    else
      Status.for(*args, &block)
    end
  end
end


__END__

### ref: http://en.wikipedia.org/wiki/List_of_HTTP_status_codes

1xx Informational

Request received, continuing process.[2]
This class of status code indicates a provisional response, consisting only of the Status-Line and optional headers, and is terminated by an empty line. Since HTTP/1.0 did not define any 1xx status codes, servers must not send a 1xx response to an HTTP/1.0 client except under experimental conditions.
100 Continue
This means that the server has received the request headers, and that the client should proceed to send the request body (in the case of a request for which a body needs to be sent; for example, a POST request). If the request body is large, sending it to a server when a request has already been rejected based upon inappropriate headers is inefficient. To have a server check if the request could be accepted based on the request's headers alone, a client must send Expect: 100-continue as a header in its initial request[2] and check if a 100 Continue status code is received in response before continuing (or receive 417 Expectation Failed and not continue).[2]
101 Switching Protocols
This means the requester has asked the server to switch protocols and the server is acknowledging that it will do so.[2]
102 Processing (WebDAV) (RFC 2518)
As a WebDAV request may contain many sub-requests involving file operations, it may take a long time to complete the request. This code indicates that the server has received and is processing the request, but no response is available yet.[3] This prevents the client from timing out and assuming the request was lost.
[edit]


2xx Success

This class of status codes indicates the action requested by the client was received, understood, accepted and processed successfully.
200 OK
Standard response for successful HTTP requests. The actual response will depend on the request method used. In a GET request, the response will contain an entity corresponding to the requested resource. In a POST request the response will contain an entity describing or containing the result of the action.[2]
201 Created
The request has been fulfilled and resulted in a new resource being created.[2]
202 Accepted
The request has been accepted for processing, but the processing has not been completed. The request might or might not eventually be acted upon, as it might be disallowed when processing actually takes place.[2]
203 Non-Authoritative Information (since HTTP/1.1)
The server successfully processed the request, but is returning information that may be from another source.[2]
204 No Content
The server successfully processed the request, but is not returning any content.[2]
205 Reset Content
The server successfully processed the request, but is not returning any content. Unlike a 204 response, this response requires that the requester reset the document view.[2]
206 Partial Content
The server is delivering only part of the resource due to a range header sent by the client. The range header is used by tools like wget to enable resuming of interrupted downloads, or split a download into multiple simultaneous streams.[2]
207 Multi-Status (WebDAV) (RFC 4918)
The message body that follows is an XML message and can contain a number of separate response codes, depending on how many sub-requests were made.[4]
[edit]


3xx Redirection

The client must take additional action to complete the request.[2]
This class of status code indicates that further action needs to be taken by the user agent in order to fulfil the request. The action required may be carried out by the user agent without interaction with the user if and only if the method used in the second request is GET or HEAD. A user agent should not automatically redirect a request more than five times, since such redirections usually indicate an infinite loop.
300 Multiple Choices
Indicates multiple options for the resource that the client may follow. It, for instance, could be used to present different format options for video, list files with different extensions, or word sense disambiguation.[2]
301 Moved Permanently
This and all future requests should be directed to the given URI.[2]
302 Found
This is the most popular redirect code[citation needed], but also an example of industrial practice contradicting the standard.[2] HTTP/1.0 specification (RFC 1945) required the client to perform a temporary redirect (the original describing phrase was "Moved Temporarily"),[5] but popular browsers implemented 302 with the functionality of a 303 See Other. Therefore, HTTP/1.1 added status codes 303 and 307 to distinguish between the two behaviours. However, the majority of Web applications and frameworks still use the 302 status code as if it were the 303[6].
303 See Other (since HTTP/1.1)
The response to the request can be found under another URI using a GET method. When received in response to a PUT, it should be assumed that the server has received the data and the redirect should be issued with a separate GET message.[2]
304 Not Modified
Indicates the resource has not been modified since last requested.[2] Typically, the HTTP client provides a header like the If-Modified-Since header to provide a time against which to compare. Using this saves bandwidth and reprocessing on both the server and client, as only the header data must be sent and received in comparison to the entirety of the page being re-processed by the server, then sent again using more bandwidth of the server and client.
305 Use Proxy (since HTTP/1.1)
Many HTTP clients (such as Mozilla[7] and Internet Explorer) do not correctly handle responses with this status code, primarily for security reasons.[2]
306 Switch Proxy
No longer used.[2]
307 Temporary Redirect (since HTTP/1.1)
In this occasion, the request should be repeated with another URI, but future requests can still use the original URI.[2] In contrast to 303, the request method should not be changed when reissuing the original request. For instance, a POST request must be repeated using another POST request.
[edit]


4xx Client Error

The 4xx class of status code is intended for cases in which the client seems to have erred. Except when responding to a HEAD request, the server should include an entity containing an explanation of the error situation, and whether it is a temporary or permanent condition. These status codes are applicable to any request method. User agents should display any included entity to the user. These are typically the most common error codes encountered while online.
400 Bad Request
The request cannot be fulfilled due to bad syntax.[2]
401 Unauthorized
Similar to 403 Forbidden, but specifically for use when authentication is possible but has failed or not yet been provided.[2] The response must include a WWW-Authenticate header field containing a challenge applicable to the requested resource. See Basic access authentication and Digest access authentication.
402 Payment Required
Reserved for future use.[2] The original intention was that this code might be used as part of some form of digital cash or micropayment scheme, but that has not happened, and this code is not usually used. As an example of its use, however, Apple's MobileMe service generates a 402 error ("httpStatusCode:402" in the Mac OS X Console log) if the MobileMe account is delinquent.
403 Forbidden
The request was a legal request, but the server is refusing to respond to it.[2] Unlike a 401 Unauthorized response, authenticating will make no difference.[2]
404 Not Found
The requested resource could not be found but may be available again in the future.[2] Subsequent requests by the client are permissible.
405 Method Not Allowed
A request was made of a resource using a request method not supported by that resource;[2] for example, using GET on a form which requires data to be presented via POST, or using PUT on a read-only resource.
406 Not Acceptable
The requested resource is only capable of generating content not acceptable according to the Accept headers sent in the request.[2]
407 Proxy Authentication Required[2]
408 Request Timeout
The server timed out waiting for the request.[2] According to W3 HTTP specifications: "The client did not produce a request within the time that the server was prepared to wait. The client MAY repeat the request without modifications at any later time."
409 Conflict
Indicates that the request could not be processed because of conflict in the request, such as an edit conflict.[2]
410 Gone
Indicates that the resource requested is no longer available and will not be available again.[2]This should be used when a resource has been intentionally removed and the resource should be purged. Upon receiving a 410 status code, the client should not request the resource again in the future. Clients such as search engines should remove the resource from their indices. Most use cases do not require clients and search engines to purge the resource, and a "404 Not Found" may be used instead.
411 Length Required
The request did not specify the length of its content, which is required by the requested resource.[2]
412 Precondition Failed
The server does not meet one of the preconditions that the requester put on the request.[2]
413 Request Entity Too Large
The request is larger than the server is willing or able to process.[2]
414 Request-URI Too Long
The URI provided was too long for the server to process.[2]
415 Unsupported Media Type
The request entity has a media type which the server or resource does not support.[2] For example the client uploads an image as image/svg+xml, but the server requires that images use a different format.
416 Requested Range Not Satisfiable
The client has asked for a portion of the file, but the server cannot supply that portion.[2] For example, if the client asked for a part of the file that lies beyond the end of the file.
417 Expectation Failed
The server cannot meet the requirements of the Expect request-header field.[2]
418 I'm a teapot
This code was defined in 1998 as one of the traditional IETF April Fools' jokes, in RFC 2324, Hyper Text Coffee Pot Control Protocol, and is not expected to be implemented by actual HTTP servers.
422 Unprocessable Entity (WebDAV) (RFC 4918)
The request was well-formed but was unable to be followed due to semantic errors.[4]
423 Locked (WebDAV) (RFC 4918)
The resource that is being accessed is locked[4]
424 Failed Dependency (WebDAV) (RFC 4918)
The request failed due to failure of a previous request (e.g. a PROPPATCH).[4]
425 Unordered Collection (RFC 3648)
Defined in drafts of "WebDAV Advanced Collections Protocol",[8] but not present in "Web Distributed Authoring and Versioning (WebDAV) Ordered Collections Protocol".[9]
444 No Response
An Nginx HTTP server extension. The server returns no information to the client and closes the connection (useful as a deterrent for malware).
426 Upgrade Required (RFC 2817)
The client should switch to a different protocol such as TLS/1.0.[10]
449 Retry With
A Microsoft extension. The request should be retried after performing the appropriate action.[11]
450 Blocked by Windows Parental Controls
A Microsoft extension. This error is given when Windows Parental Controls are turned on and are blocking access to the given webpage.[12]
499 Client Closed Request
An Nginx HTTP server extension. This code is introduced to log the case when the connection is closed by client while HTTP server is processing its request, making server unable to send the HTTP header back.[13]
[edit]


5xx Server Error

The server failed to fulfill an apparently valid request.[2]
Response status codes beginning with the digit "5" indicate cases in which the server is aware that it has encountered an error or is otherwise incapable of performing the request. Except when responding to a HEAD request, the server should include an entity containing an explanation of the error situation, and indicate whether it is a temporary or permanent condition. Likewise, user agents should display any included entity to the user. These response codes are applicable to any request method.
500 Internal Server Error
A generic error message, given when no more specific message is suitable.[2]
501 Not Implemented
The server either does not recognise the request method, or it lacks the ability to fulfill the request.[2]
502 Bad Gateway
The server was acting as a gateway or proxy and received an invalid response from the upstream server.[2]
503 Service Unavailable
The server is currently unavailable (because it is overloaded or down for maintenance).[2] Generally, this is a temporary state.
504 Gateway Timeout
The server was acting as a gateway or proxy and did not receive a timely response from the upstream server.[2]
505 HTTP Version Not Supported
The server does not support the HTTP protocol version used in the request.[2]
506 Variant Also Negotiates (RFC 2295)
Transparent content negotiation for the request results in a circular reference.[14]
507 Insufficient Storage (WebDAV) (RFC 4918)[4]
509 Bandwidth Limit Exceeded (Apache bw/limited extension)
This status code, while used by many servers, is not specified in any RFCs.
510 Not Extended (RFC 2774)
Further extensions to the request are required for the server to fulfill it.[15]
