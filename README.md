
# Test Chamber

*This was a triumph! I'm making a note here: Huge Success*

Test Chamber is Tapjoy's integration testing framework and spec repository. It
provides wrapper objects and spec helpers to make integration a joy and not a
hassle.

# Table of Contents

* [Quickstart](#quickstart)
* [How Test Chamber Works](#works)
* [Advanced Usage](#usage)
    * [Running on Jenkins](#jenkins)
    * [Environment Variables](#env)
    * [Debugging Failed Tests](#failures)
    * [Configuring Tapinabox](#tiab)
    * [SDK Testing](#sdk)
    * [Testing with Spork](#spork)
* [Writing Specs](#writing)
    * [Development Workflow](#workflow)
    * [Repository Structure](#structure)
    * [Adding to Specs](#specs)
    * [Adding to Libs](#libs)
    * [Adding to Models](#models)
    * [Gotchas](#oops)
* [Helpful Resources](#resources)
* [About](#about)

## <a name='quickstart'></a>Quickstart

1. Install `firefox` version 35 from http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/35.0/.
1. Install ffmpeg `brew install ffmpeg`
1. Run `bundle install`
1. There is only one environment variable required to use Test Chamber:
    1. `TARGET_URL` is a TIAB like http://real-not-fake-tapinabox.tapjoy.net
    1. For optional environment variables, see the 'Advanced Usage' section.
1. Run specs with `foreman run bundle exec rspec spec/features/your/spec/here`.
   It's best not to run all the feature specs as they can take over 2 hours. If
   you want to validate that the setup worked, run `spec/features/app_spec.rb`
   as a smoke test.

   To run the whole suite you can push your branch up to the repo and run the
   [test_chamber Jenkins job][].
   When you start it specify the Test Chamber branch you pushed as the `BRANCH`
   parameter and the TIAB you want to use as the `TARGET_URL`.
1. Watch the magic happen

## <a name='works'></a>How Test Chamber Works

Test Chamber consists of a set of automation components which exercise the UI
and APIs, and a set of RSpec helpers that enable writing specs using the
framework.

The UI automation is done using Capybara and Selenium; Capybara is a high level
browser automation DSL, and Selenium does the heavy lifting of automating the
browser - in this case, Firefox.

The API automation uses a rest client wrapper which wraps the ruby RestClient.
This wrapper has helpers to handle authenticated requests, CSRF tokens used for
form submission, and some TJS specific retry logic. For more information about
the rest client, check out `lib/test_chamber/rest.rb`.

In the basic browser automation case, there are several interacting layers:

1. The specs leverages RSpec specific features like shared contexts and shared
examples.
1. These specs call the Test Chamber libraries, like `TestChamber::Partner` and
`TestChamber::Offer`. These objects are Test Chamber's representations of the
corresponding concepts in the Dashboard and TapjoyServer.
1. The methods on these objects call Capybara to automate the browser.
1. Capybara wraps Selenium, and calls the necessary methods to remote control
the browser.

The API Automation cases work similarly, but instead of Capybara, we use the
rest client wrapper and `RestClient`.

## <a name='usage'></a> Advanced Usage

Test Chamber supports many use cases. Some of the more common are covered below.

### <a name='jenkins'></a> Running on Jenkins

Currently Test Chamber is run in the `test_chamber` build in Jenkins.
The build takes the following parameters:

1. `TARGET_URL` is the url of the Tapinabox to run tests against.
1. `SPEC_FILE` is the glob of the tests to run. This is passed to
`parallel_rspec` as a parameter.
1. `BRANCH` is the Test Chamber branch to use when running specs.
1. `PARALLELISM` is the number of Test Chamber processes to run. These are all
run on a single test executor, and each process will use a separate Firefox
instance, so consider resource contention on the executor. The default is 15.
This is passed as a parameter to `parallel_rspec`.
1. `DRIVER` is the Capybara Backend to use. This should always be Selenium
unless you are testing the SDK (see [SDK Testing](#sdk) for more information).
1. `DELETE_PARTNERS_CREATED_DURING_TESTS` is whether Test Chamber should call
`TestChamber::Models::Partner.destroy!` on each Partner after a testrun
completes. This defaults to true. Note that this sets the `TC_PARTNER_NO_DELETE`
environment variable. For more information see [Gotchas](#oops).

The `test_chamber` project is available for anyone to use in running
their Test Chamber specs in parallel, however if you would like a build to run
Test Chamber specs automatically, please see the Tools team and they will help
you configure Jenkins to work for you.

### <a name='env'></a>Environment Variables

Test Chamber allows you to configure the following options via your environment
variables:

1. `TARGET_URL`: the full url of the Tapinabox to run tests against.
1. `TC_DRIVER`: the driver to use for tests. Defaults to `selenium`. For SDK
testing, use `appium`.
1. `TC_PARTNER_DELETE`: delete partners after test runs. This is only necessary when the sheer number of generated partners starts to clog up the hourly statz jobs on the tiab. It is usually not necessary to set this outside of jenkins.
1. `DASHBOARD_ASSET_VERSION`: set a specific version of the dashboard assets.
1. `TC_NO_LOGIN`: don't automatically log in before tests. Will cause most tests
to fail.
1. `TEST_PARTNER_ID`: the ID of a partner to use as the default partner for all
tests.

In addition, some appium configuration is passed via environment variables. See
APPIUM.md for more information on these variables.

### <a name='failures'></a>Debugging Failed Tests

From time to time, tests will fail. Spec failures tend to fall into one of a few
categories:

1. Timeouts
1. Specific errors raised with a helpful (or not) message.
1. ElementNotFound or StaleElementReference exceptions

##### Timeouts

Timeouts in Test Chamber are almost always the result of communicating with the
database, or in rare cases waiting for Capybara to manipulate an element in the
DOM. Because certain operations can take a range of time (for example, adding a
conversion to the database), Test Chamber provides the
`TestChamber::Util.wait_for` method. If you see this in a traceback, the test
has been retrying a block waiting for a `truthy` result.

If the block in question hits the database, then it's likely that the failure is
due to Test Chamber silently failing an action earlier in the test. The best way
to debug these failures is to place `puts` statements in key places to confirm
the creation of objects worked correctly. These failures should be brought to
the attention of the tools team so we can harden Test Chamber against them.

Sometimes, the queues on a Tapinabox can get backed up. In this case, setting
the queue retention to 5 minutes helps clear them out quickly. For more
information about why this happens see [Gotchas](#oops). For information about
how to fix this issue, see [Configuring Tapinabox](#tiab).

If the block is failing on a UI interaction, it's likely that the UI was changed
recently. The lib that contains the failure may need refactored; your friendly
neighborhood tools team member can help you with this process.

##### Specific errors

In many places, we have hardened Test Chamber and provided helpful debugging
information when a failure occurs. These should be self-explanatory. If they are
not helpful, please see a tools team member and we will enhance our messaging.

##### ElementNotFound or StaleElementReference

These errors come directly from the browser. An `ElementNotFound` exception
signifies that the selector used to get an element of the DOM (usually a CSS
selector) is incorrect, or the browser is not on the page expected. In these
cases, placing a `pry` statement right before the call and manually inspecting
the DOM/Browser usually clears up what went wrong. Test Chamber also takes a
screenshot after any failed tests and places a png file in the `screenshots`
folder.

A `StaleElementReference` exception means that the DOM has changed since the
selector found the element you are manupulating. This usually occurs because the
page has been reloaded (by clicking a link or navigating), or because an AJAX
request changed the DOM. Again, the best way to debug these exceptions is a well
placed `pry`.

### <a name='tiab'></a>Configuring Tapinabox

Sometimes you will need to configure Tapinabox for your tests. A few things to
consider:

1. You can set custom branches on Tapinabox at any time by clicking the 'pencil'
icon next to your Tapinabox on Deployboard.
1. Tapinaboxen boot from an AMI built each night from the `production-current`
tag on each service's slug. This means that Tapinaboxen can quickly go out of
date. If that tag is not being updated (for example, with non-production
services), then Tapinabox is using out of date services which will have to be
manually updated. Please see the tools team for the workflow for these services.
1. Tapinabox is not necessarily resiliant when it comes to aborted testruns.
Aborted runs can leave bad messages in the Tapinabox's queues. If you want to
inspect your queues, you can use the `tiab:check_queues` rake task to inspect
queues, and the `tiab:set_queue_retention` task to set their retention to 5
minutes. For information about why this happens, see [Gotchas](#oops).

### <a name='sdk'></a> SDK Testing

Test Chamber can also be used to automate the SDK via simulators/emulators
running locally, simulators/emulators on the Saucelabs service, or real devices
in the AppThwack cloud.

To get started testing the SDK, check out the
[Appium Test Chamber Documentation](docs/appium.md).

This feature is still under heavy development. For more information about how to
test the SDK, please see Jason Carr (jason.carr@tapjoy.net).

### <a name='spork'></a>Testing with Spork

When tweaking code / specs, you may find the startup time for running your specs
to be long.  To allow quick iteration on code / test changes, you can use
spork.  Spork allows the spec environment to be loaded once; each spec run is
then run as a fork of the main process.

To use spork, first run the spork server:

```
foreman run bundle exec spork
```

When you're ready to run specs, just run the spec like so:

```
rspec spec/featurs/statz_spec.rb --drb
```

The output of the specs will be displayed in the terminal running spork.  If
you want to avoid writing `--drb` constantly, you can also create a `.rspec`
file in your home directory with the following contents:

```
--color
--drb
```

Happy sporking!

## <a name='writing'></a> Writing Specs

Here's a quick example of what a spec might look like:

```ruby

it "Creates an offer and converts it" do
  # Create an app and an offer
  app = TestChamber::App.new
  offer = TestChamber::Offer::Generic.new

  # click and convert the offer from the app
  app.click_offer(offer)
  conversion = app.convert_offer(offer)

  # validate bits about the conversion
  ...
end
```

That will actually go through the dashboard UI on a Tapinabox, create a new
generic offer, enable it, click on it, and then wait until its conversion has
been processed by the jobs system. It returns the conversion object for all of
your validation and assertion needs.

One potential point of confusion is that the Test Chamber object is only a
representation of the object that exists in Tapjoy Server; it is not a TJS model
so your tests cannot use the normal interactions provided in TJS.

Check out `spec/features` for where the tests are and how they use the other
objects.

Take a look at `spec/support` to see how we re-use components in the system.

### <a name='workflow'></a> Development Workflow

Test Chamber is under active development using the 'develop' branch. Master is
merged to only during releases. When adding a new feature, branch off of develop
and give your branch a relevant name. Features can be prefixed with `feature/`
while bugfixes can use `fix/`. Throwaway branches use `sandbox/`. There is no
convention about the rest of the branch name - some people use JIRA tickets,
others just use a descriptive name, for example `feature/mobile_offerwall_lib`.

Once your work is done, create a pull request from your branch into develop, and
kick off a Jenkins testrun using your branch. This second step is required
before any work can be merged.

### <a name='structure'></a> Repository Structure

1. `specs` contains the spec files that are run by Test Chamber. The specs in
the `specs/examples` directory are not run by Jenkins and are not guaranteed to
pass. `specs/support` contains the Rspec helpers added for your convenience, as
well as shared examples used by multiple tests.
1. `assets` contains the static assets necessary for offer creation.
1. `config` contains configuration files and initializers for Test Chamber, as
well as the offer parameters that are encoded into urls in our mock SDK
requests.
1. `lib` contains the browser and API automation components.
1. `models` contains the ActiveRecord wrappers that Test Chamber uses to access
the TJS database on Tapinabox. **These wrappers are not the TJS models, although
there are some places where they approximate their behavior.** Test Chamber uses
these models primarily for validation of object creation and accessing some data
that is not available via APIs or the UI (like revenue sharing amounts).

### <a name='specs'></a> Adding to Specs

When adding new specs to Test Chamber, they should go in the `spec` directory.
Inside this directory are folders for each feature being tested. These folders
should not be specific to a service, rather the folders and specs therein should
describe a feature being developed. For example, the `revshare` folder describes
the specs that check that we calculate revenure shares correctly, which touches
many different Tapjoy Services.

### <a name='libs'></a> Adding to Libs

When new libs are created, they should be in `lib/test_chamber/my_lib.rb`. If
multiple related libs are created, consider namespacing them and organizing them
into their own folders (e.g. `lib/test_chamber/eventservice`).

New utilities should go in `lib/test_chamber/utils`.

### <a name='models'></a>Adding to Models

If you need to add a model to Test Chamber, it will need to be vetted by the
Tools team first: in an ideal world, Test Chamber would not access the database
at all. However if you cannot access your data any other way, your model should
subclass `ActiveRecord::Base` and have the minimum number of interactions with
the data store as possible.

### <a name='oops'></a> Gotchas

##### TC_PARTNER_DELETE

The `TC_PARTNER_DELETE` environmental variable can be set to true to delete
partners created during the test run. These partners are deleted to prevent
tapinabox from choking on the hourly_app_stats and hourly_partner_stats jobs,
which can take a very long time due to the number of partners created during
automated tests. This is set to true on jenkins which runs the entire test suite
resulting in many partners being created. In normal development it is usually
not necessary to set this variable.

##### Amazon SQS Backups

If you interrupt a test run with `CTRL + C`, messages are left in the Amazon
queues which will attempt to use broken assets in the system. Because the
default message retention time in SQS is forever, these messages can build up
and cause TJS on your Tapinabox to stop processing clicks and conversions; these
manifest themselves as Timeouts when looking for clicks/conversions.

Setting the queue retention to 5 minutes usually fixes these problems quickly.
See [Debugging Failed Tests](#failures) for more information on setting queue
retention and checking queues.

## <a name='resources'></a> Helpful Resources

For best practices and gotchas check out the [test_chamber wiki][]

Here's a good [cheat sheet][] for using capybara to do browser simulation. When
they say different things the best practices above work better.

# About

Written with love by the Tools team at Tapjoy. Please send all feedback to
tools@tapjoy.com

[test_chamber Jenkins job]: http://jenkins.tapjoy.net/job/test_chamber/
[test_chamber wiki]: https://github.com/Tapjoy/test_chamber/wiki/Best-Practices-when-writing-test_chamber-integration-tests
[cheat sheet]: https://gist.github.com/zhengjia/428105
