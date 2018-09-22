print <<HI;

Hi!
Running this test file shows error:
  [Sat Sep 22 07:28:16 2018] [debug] Using default_handler to render data since 'openapi' was not found in stash. Set 'handler' in stash to avoid this message.

It took a bit of time to figure out what this meant.

If you take a look at the openapi.yaml at the bottom,
you find that there is a typo in the path name:

    x-mojo-name: getEcho,

I managed to leave the comma there, when refactoring an API spec from json to yaml.
Essentially there is no such method/route to handle the GET /echo -endpoint.

I'd prefer to have a solid error message saying that there is no implementation for the
endpoint, instead of complaining about the missing openapi renderer.

Later on there is a 501 error Not Implemented, which is rather spot on.


Would it be possible to have some static safety when loading the OpenAPI-plugin
to check that all the endpoints have an implementation, or atleast a matching route?





HI

use Mojo::Base -strict;
use Mojolicious::Lite;

use Test::Most;
use Test::Mojo;

$ENV{MOJO_OPENAPI_DEBUG} = 1;
$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
$ENV{MOJO_LOG_LEVEL} = 'debug';

# Routes will be moved under "basePath", resulting in "GET /api/v1/echo"
get "/echo" => sub {
  my $c = shift->openapi->valid_input or return;
  $c->app->log->info("GET GOT CALLED!!");
  $c->render(status => 204, openapi => {echo => 1});
}, "getEcho";

post "/echo" => sub {
  my $c = shift->openapi->valid_input or return;
  $c->app->log->info("POST GOT CALLED!!");
  $c->render(status => 204, openapi => {echo => 1});
}, "postEcho";

# Load specification and start web server
plugin OpenAPI => {url => "data://main/api.yaml", log_level => 'debug'};



my $t = Test::Mojo->new;


$t->get_ok('/api/v1/echo')->status_is(204);
$t->post_ok('/api/v1/echo')->status_is(204);


__DATA__
@@ api.yaml
swagger: 2.0
info:
  version: 0.8
  title: PetCORS
schemes:
  - http
basePath: /api/v1
paths:
  /echo:
    get:
      x-mojo-name: getEcho,
      responses:
        204:
          description: Echo response
          schema:
            type: object

    post:
      x-mojo-name: postEcho
      responses:
        204:
          description: Echo response
          schema:
            type: object


