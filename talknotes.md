# Level up your JSON fu with jq

A [talk at BTPcon 2023 in Hannover](https://qmacro.org/talks/#level-up-your-json-fu-with-jq).

If you peel back the layers of SAP Business Technology Platform, there's a lot of JSON. It's important to feel comfortable with it, to be able to parse, filter, extract, reformulate and otherwise deal with that JSON like a boss. In this session you'll become acquainted with jq, the lightweight and flexible command-line JSON processor that also happens to be a fully formed language.

## Intro

In reality, the cloud is glued together with shell and JSON (ok, and YAML too). This is why it's important to master these aspects, because at the end of the day, your apps and services are very likely to be running in a Unix context consuming and emitting structured data in JSON. Even the outward facing parts, such as the public APIs, will most likely be full of JSON representations.

Today's services manage and emit structured data that is not easily conveyed in plain text. So the traditional Unix tools (such as `sed`, `awk`, `grep` and so on) are not appropriate here. Instead, we need specialist tools to properly manage this structured data.

Popular command line tools emit JSON. One example is the Azure CLI that has [different output formats](https://learn.microsoft.com/en-us/cli/azure/format-output-azure-cli) including JSON, which is in fact the default. Another example is `kubectl`, the CLI for Kubernetes, which also has [multiple output formats](https://kubernetes.io/docs/reference/kubectl/#output-options) including JSON. GitHub's CLI `gh` also has support for JSON output, and even has an option built in to allow you to specify `jq` expressions to filter the JSON output (see for example [the options for `gh issue list`](https://cli.github.com/manual/gh_issue_list)).

For tools that don't have JSON output, there's also [jc](https://github.com/kellyjonbrazil/jc), which is a "CLI tool and python library that converts the output of popular command-line tools, file-types, and common strings to JSON ...".

In addition to the [JSON spec](https://www.json.org/) itself, there are other JSON-centric specifications, including [JSON Lines](https://jsonlines.org/), which uses JSON values to represent records, delimited by newlines. In fact, this concept fits very well with one of the core philosophies of `jq` which we'll learn about, which is JSON value streaming.

And of course the SAP Business Technology Platform (SAP BTP) is full of JSON. Not least in the form of the [JSON output from the btp CLI](https://help.sap.com/docs/btp/sap-business-technology-platform/change-output-format-to-json). Think of the btp CLI as being for humans, and for machines. The default output is human centric and text-based. But with the `--format json` option, the output becomes clearly structured, more predictable and easily parseable.

Not only that, but the resources of the SAP BTP APIs, in the form of the [Core Services for SAP BTP](https://api.sap.com/package/SAPCloudPlatformCoreServices/rest), have representations that are in JSON format.

And of course, who could forget the OData APIs? Both OData v2 and v4 APIs have responses that have prominent JSON representations.

There's a **lot** of JSON about.

And while you're human (probably), you're also the machine, the person who writes the scripts, the clients that interact with the APIs. So you need to embrace JSON and feel comfortable dealing with it.

## On JSON values and streaming

We all know what JSON looks like, right?

```json
{
  "datacenters": [
    {
      "name": "cf-ap21",
      "displayName": "Singapore - Azure",
      "region": "ap21",
      "environment": "cloudfoundry",
      "iaasProvider": "AZURE",
      "supportsTrial": true,
      "domain": "ap21.hana.ondemand.com",
      "isMainDataCenter": true
    },
    {
      "name": "cf-us10",
      "displayName": "US East (VA) - AWS",
      "region": "us10",
      "environment": "cloudfoundry",
      "iaasProvider": "AWS",
      "supportsTrial": true,
      "domain": "us10.hana.ondemand.com",
      "isMainDataCenter": true
    }
  ]
}
```

How about this:

```json
[
  1,
  2,
  3
]
```

What about this:

```json
42
```

Or this:

```json
"Life, The Universe, And Everything"
```

Is this JSON?

```json
hello
```

What about this?

```json
null
```

Or this?

```json
true
```

When processing JSON, it will often be in a form similar to the first example - a complex structure of nested arrays and objects. That's fine, and `jq` will handle that fine. But it's also worth being aware of the fact that `jq` can also process incoming streams of JSON values, regardless of what those values are.

The following (types) are valid JSON values: object, array, string, number, true, false, null.

> `jq` [also has a NaN numeric value that cannot be expressed in JSON](https://hachyderm.io/@wader@fosstodon.org/110173572557329986), but we can safely ignore that for the purposes of this talk.

## Looking at jq

While there are [other tools](#other-tools) that allow you to explore JSON on the command line, the [Swiss Army Chainsaw](http://www.catb.org/jargon/html/S/Swiss-Army-chainsaw.html) of the JSON world is `jq`.

On [the website](https://stedolan.github.io/jq/), `jq` is described as "a lightweight and flexible command-line JSON processor". Which it is. But it's also a Turing-complete language that you can write multi-module programs in, or simple one-liners. And anything in between.

Think of `jq` as being a tool through which you pass one or more JSON values.

> `jq` can also be invoked with the `--null-input` (short form: `-n`) option which effectively gives you the opportunity not to have any input (and to generate the output purely from within your `jq` program); what actually happens is that `null` is tacitly used as the single input value: `jq -n .` returns `null`.

Being a "proper" programming language, there are many features including support for modules, function definitions, conditionals & control structures, regular expressions, I/O, streaming, destructuring, recursion and more.

For our purposes (handling JSON on SAP BTP), we just need to know that we can not only perform read-only operations on the JSON, to sort, filter, and so on, but we can also modify that JSON, by reshaping it, removing, changing or adding values and sub-structures, and more.

Not only that, but while `jq` by default expects to receive JSON values as input and attempts to emit JSON values as output, it can be used to process non-JSON and emit non-JSON too. There are even special format strings to emit common non-JSON values and structures such as HTML, URIs, CSV, TSV, Base64 and more, all with the correct and appropriate escaping.

> `jq` can also parse Base64 encoded values, and also parse stringified JSON too (useful for [structures embedded within string type values in JSON objects](https://github.com/SAP-samples/cloud-btp-cli-api-codejam/tree/main/exercises/05-core-services-api-prep#extracting-the-api-endpoint-value)!)

## Starting with jq

`jq` can be [downloaded](https://stedolan.github.io/jq/download/) as a single binary and is available for many platforms, even Windows. There are `jq` packages for popular repositories such as Debian & Ubuntu on Linux, Homebrew and MacPorts on macOS, and Chocolatey (NuGet) on Windows.

Often, what you want to do with `jq` is simple enough to describe in a short expression, so invoking `jq` on the command line with that expression as part of the invocation is common.

The simplest `jq` expression is also arguably the most common, and it's used to pretty print otherwise ugly or impenetrable JSON output.

The JSON output from most btp CLI commands is quite neat, so here's a made-up scenario for now. Imagine you had a file `data.json` containing some JSON output that had no whitespace, and looked like this in your editor:

```text
{"quotas":[{"service":"APPLICATION_RUNTIME","plan":"MEMORY",
"quota":4,"unlimited":false,"provisioningMethod":"NONE_REQUI
RED","serviceCategory":"PLATFORM"},{"service":"kymaruntime",
"plan":"trial","quota":1,"unlimited":false,"provisioningMeth
od":"NONE_REQUIRED","serviceCategory":"ENVIRONMENT"},{"servi
ce":"alm-ts","plan":"lite","quota":1,"unlimited":false,"prov
isioningMethod":"NONE_REQUIRED","serviceCategory":"APPLICATI
ON"},{"service":"sapappstudiotrial","plan":"trial","quota":1
,"unlimited":false,"provisioningMethod":"NONE_REQUIRED","ser
viceCategory":"APPLICATION"},{"service":"auditlog-viewer","p
lan":"free","quota":1,"unlimited":false,"provisioningMethod"
:"NONE_REQUIRED","serviceCategory":"APPLICATION"},{"service"
:"hana-cloud-tools","plan":"tools","quota":1,"unlimited":fal
se,"provisioningMethod":"NONE_REQUIRED","serviceCategory":"A
```

> The condensed JSON above was actually produced using `jq` too, using the `--compact-output` (short: `-c`) option, combined with a simulation of editor wrapping using the standard Unix `fold` command: `btp --format json list accounts/entitlement | jq -c . | fold -w 60`.

With a quick pipe through `jq` like this `jq '.' data.json` things would look a lot better, with the following being produced (output reduced for brevity):

```json
{
  "quotas": [
    {
      "service": "APPLICATION_RUNTIME",
      "plan": "MEMORY",
      "quota": 4,
      "unlimited": false,
      "provisioningMethod": "NONE_REQUIRED",
      "serviceCategory": "PLATFORM"
    },
    {
      "service": "kymaruntime",
      "plan": "trial",
      "quota": 1,
      "unlimited": false,
      "provisioningMethod": "NONE_REQUIRED",
      "serviceCategory": "ENVIRONMENT"
    }
  ]
}
```

The `.` is the identity filter (yes, [that identity mechanism](https://en.wikipedia.org/wiki/Identity_function), and yes, `jq` is a functional language at its heart), which just produces whatever it's given. And so we must realise that it's not the `.` that is performing the pretty print, it's `jq`'s default approach to output, which is to not only to emit JSON values as output, but to pretty print them too.

Here are some more single-line expression examples:

> All of these can be executed with `btp --format json ... | jq ...` but here they're shown as first loading the JSON into files, so we have the files of JSON here in this repo too to try out.

```shell
# How many different available environments do I have at my disposal?
; btp --format json list accounts/available-environment > environments.json
; jq '.availableEnvironments|length' environments.json
2
```

```shell
# What are the service names on offer?
; btp --format json list services/offering > offerings.json
; jq -r '.[].name' offerings.json
feature-flags
transport
xsuaa
destination
auditlog-management
alert-notification
html5-apps-repo
...
```

> The `-r` is a short form of the `--raw-output` option and tells `jq` not to format strings as JSON strings (surrounded by double quotes), but just to output them as-is.

```shell
# How many roles does each role collection contain?
; btp --format json list security/role-collection > collections.json
; jq 'map({(.name): .roleReferences|length})|add' collections.json
{
  "Business_Application_Studio_Administrator": 1,
  "Business_Application_Studio_Developer": 1,
  "Business_Application_Studio_Extension_Deployer": 1,
  "Cloud Connector Administrator": 1,
  "Connectivity and Destination Administrator": 2,
  "Destination Administrator": 1,
  "Subaccount Administrator": 5,
  "Subaccount Service Administrator": 1,
  "Subaccount Viewer": 5
}
```

```shell
# What are the data centres available to me from Azure?
; btp --format json list accounts/available-region > regions.json
; jq '.datacenters[]|select(.iaasProvider == "AZURE").displayName' regions.json
"Singapore - Azure"
```

## Exploring with jq

With a language that's likely new to you and almost endless possibilities, typing all but the simplest expression in-line might be a little overwhelming. Luckily there are many tools at our disposal to explore JSON with `jq`. Most of them have a similar approach, presenting you with three windows:

- the JSON input
- your `jq` expression
- the resulting JSON output

Many also offer options or switches to adjust the behaviour, reflecting some of the options that are available on the command line (this list is from `jq --help`):

```text
-c               compact instead of pretty-printed output;
-n               use `null` as the single input value;
-e               set the exit status code based on the output;
-s               read (slurp) all inputs into an array; apply filter to it;
-r               output raw strings, not JSON texts;
-R               read raw strings, not JSON texts;
-C               colorize JSON;
-M               monochrome (don't colorize JSON);
-S               sort keys of objects on output;
--tab            use tabs for indentation;
--arg a v        set variable $a to value <v>;
--argjson a v    set variable $a to JSON value <v>;
--slurpfile a f  set variable $a to an array of JSON texts read from <f>;
--rawfile a f    set variable $a to a string consisting of the contents of <f>;
--args           remaining arguments are string arguments, not files;
--jsonargs       remaining arguments are JSON arguments, not files;
--               terminates argument processing;
```

From a Web-based perspective, there's [jqterm](https://jqterm.com/) and [jqplay](https://jqplay.org).

From a command line perspective, there's [ijq](https://sr.ht/~gpanders/ijq/) (the "i" is for "interactive"):

![ijq demo from ijq's home page](https://git.sr.ht/~gpanders/ijq/blob/HEAD/demo/ijq.gif)

## Hands-on

In the rest of this session you'll get a chance to get a feel for how `jq` cleanly and efficiently slices through JSON and gives you the ability to take control.

### Level 1 - getting acquainted

First, let's get closer to how `jq` sees and processes values. We'll start with a simple file [threestrings.dat](threestrings.dat) containing three separate JSON values:

```json
"three"
"separate"
"strings"
```

Each one will be processed, one at a time, by `jq`:

```shell
cat threestrings.dat | jq '.'
# "three"
# "separate"
# "strings"
```

> Of course, this (and subsequent) uses of the pipeline pattern `cat <filename> | jq '.'` is to illustrate the flow of data through `jq`. One could just as easily use `jq '.' <filename>`.

What happens when we use the `length` function?

```shell
cat threestrings.dat | jq 'length'
# 5
# 8
# 7
```

> For the simplest filters, one can emit the single quotes, e.g. `jq .` and `jq length`. But it's helpful to remember to use them always, because you'll soon need them, to enclose `jq` syntax like the pipe `|` which is similar to but not the same as the shell's pipe.

Even though there are three distinct JSON values going in, we can ask `jq` to read them all in at once, into an array, with the `--slurp` option (short: `-s`):

```shell
cat threestrings.dat | jq -s '.'
# [
#   "three",
#   "separate",
#   "strings"
# ]
```

Now look what happens when we use `length` with this array of slurped values:

```shell
cat threestrings.dat | jq -s 'length'
# 3
```

What if we wanted to just emit those words beginning with "s", and make the words all uppercase?

```shell
cat threestrings.dat | jq 'select(startswith("s"))|ascii_upcase'
# "SEPARATE"
# "STRINGS"
```

How about creating a CSV record:

```shell
cat threestrings.dat | jq -r -s '@csv'
# "three","separate","strings"
```

Here's a little bit of reshaping:

```shell
cat threestrings.dat \
| jq -s '{words:., chars:map(length)|add}'
# {
#   "words": [
#     "three",
#     "separate",
#     "strings"
#   ],
#   "chars": 20
# }
```

> Taking [TIMTOWTDI](https://www.urbandictionary.com/define.php?term=TIMTOWDI) into account, one could achieve the character count in a different way, like this: `{words: ., chars: .|add|length}`

## Level 2 - some more realistic input data

Let's start to work with a more realistic data set, but still simple enough to quickly comprehend and use in this introductory session. The data is based loosely on the [BTPcon 2023](https://www.btpcon.org) session information, is contained in [btpcon.json](btpcon.json) and looks like this (content reduced for brevity):

```json
{
  "name": "BTPcon 2023",
  "sessions": [
    {
      "title": "Hands-On: CAP Erweiterungen für SAP S/4HANA auf SAP BTP mit SAP Event Mesh und SAP Private Link service",
      "speaker": "Max Streifeneder",
      "type": "hands-on",
      "duration": 150,
      "starttime": "0930"
    },
    {
      "title": "Prozessgetriebene Softwareentwicklung auf der BTP mit BPMN und CAP",
      "speaker": "Volker Buzek",
      "type": "talk",
      "duration": 45,
      "starttime": "1025"
    },
    {
      "title": "SAP BTP – Cloud Services unter Kontrolle",
      "speaker": "Mike Zaschka",
      "type": "talk",
      "duration": 45,
      "starttime": "1025"
    }
  ]
}
```

First, let's warm up by listing the speakers:

```shell
jq '.sessions[].speaker' btpcon.json
```

This produces a stream of JSON values (strings):

```json
"Max Streifeneder"
"Harutyun Ter-Minasyan"
"Thorsten Düvelmeyer"
"Mohamed Oussman"
"Volker Buzek"
"Mike Zaschka"
"Nicolai Schönteich"
"Eike Bergmann"
"Max Streifeneder"
"Adam Kiwon"
"Alper Dedeoglu"
"Cedric Heisel"
"Gregor Wolf"
"Fabian Lehmann"
"DJ Adams"
```

Which sessions start in the morning and which in the afternoon? We could use the time of day to determine that, but how do we get to that? Let's see:

```shell
jq '.sessions | last | [.title, .starttime[:2]]' btpcon.json
# [
#   "Level up your JSON fu with jq",
#   "15"
# ]
```

Let's encapsulate that in a function, and let's store it separately in a file called `lib.jq`:

```jq
def ampm:
  if .starttime[:2] | tonumber < 12
  then "morning"
  else "afternoon"
  end
;
```

We can then import this "lib" module and use the function to enhance the session data:

```shell
jq 'import "lib" as lib; .sessions | map(.when = lib::ampm)' btpcon.json
```

This should add a new property to each of the session objects (only the first few sessions shown for brevity):

```json
[
  {
    "title": "Hands-On: CAP Erweiterungen für SAP S/4HANA auf SAP BTP mit SAP Event Mesh und SAP Private Link service",
    "speaker": "Max Streifeneder",
    "type": "hands-on",
    "duration": 150,
    "starttime": "0930",
    "when": "morning"
  },
  {
    "title": "Datenverbund von Google BigQuery zu SAP Data Warehouse Cloud / SAP Analytics Cloud",
    "speaker": "Harutyun Ter-Minasyan",
    "type": "hands-on",
    "duration": 150,
    "starttime": "1400",
    "when": "afternoon"
  },
  {
    "title": "RISE with BTP: Erfahrungen aus SAP S/4 HANA-Transformationen mit einem integrierten Einsatz der BTP",
    "speaker": "Thorsten Düvelmeyer",
    "type": "talk",
    "duration": 45,
    "starttime": "0930",
    "when": "morning"
  }
]
```

> We used `map` here to preserve the shape of the value of the `sessions` property, which was an array.

Now we can use that new property to group by (`group_by(.when)`) and not forgetting to then also reverse the groups (`reverse`), as we want "morning" before "afternoon" despite their natural alphabetic sort order.

Finally we convert the two "morning" and "afternoon" sub arrays that resulted from the call to `group_by` into a list of two objects, constructing the objects on the fly while mapping over those sub arrays (`map({ ... })`). These objects have one property each, where the key is either `"morning"` or `"afternoon"`, taken from the value of the `when` property of the first object in the sub array (`first.when`) and the value is the list of `title` properties from the objects in that same sub array (`map(.title)`):

```shell
cat btpcon.json \
| jq '
    import "lib" as lib;
    .sessions
    | map(.when = lib::ampm)
    | group_by(.when)
    | reverse
    | map({
        (first.when): map(.title)
      })
  '
```

This gives us:

```json
[
  {
    "morning": [
      "Hands-On: CAP Erweiterungen für SAP S/4HANA auf SAP BTP mit SAP Event Mesh und SAP Private Link service",
      "RISE with BTP: Erfahrungen aus SAP S/4 HANA-Transformationen mit einem integrierten Einsatz der BTP",
      "BTP Services with a Cloud Native Application",
      "Prozessgetriebene Softwareentwicklung auf der BTP mit BPMN und CAP",
      "SAP BTP – Cloud Services unter Kontrolle",
      "Vom ersten App-Deployment zu CI/CD mit Cloud Foundry",
      "Prozessdigitalisierung mit SAP Build Process Automation"
    ]
  },
  {
    "afternoon": [
      "Datenverbund von Google BigQuery zu SAP Data Warehouse Cloud / SAP Analytics Cloud",
      "Deconstructed: CAP on SAP BTP, Kyma Runtime",
      "SAP Schnittstellenmanagement & Integration Excellence",
      "Entwicklung von Multi-Tenant Software as a Service Applikationen in SAP BTP",
      "Integration-Hub auf der BTP - Eine Symbiose aus CAP und SAP Cloud SDK",
      "WIP: ChatGPT mit SAP Best Practice Content",
      "Wie finden die verschiedenen Suite Qualities ihren Weg zu den SAP-Anwender:innen",
      "Level up your JSON fu with jq"
    ]
  }
]
```

Let's use this new function to find out also who is giving a talk in the afternoon, and arrange the names in "surname, firstname" format:

```shell
cat btpcon.json \
| jq '
  import "lib" as lib;
  .sessions[]
  | select(.type=="talk" and lib::ampm=="afternoon")
  | .speaker
  | split(" ")
  | [last, first]
  | join(", ")
  '
```

This gives us:

```json
"Streifeneder, Max"
"Kiwon, Adam"
"Dedeoglu, Alper"
"Heisel, Cedric"
"Wolf, Gregor"
"Lehmann, Fabian"
"Adams, DJ"
```


## Further reading

- There's a [jq track on Exercism](https://exercism.org/tracks/jq/) with some great exercises.
- The [Q&A on Stack Overflow](https://stackoverflow.com/questions/tagged/jq?tab=Newest) is definitely worth keeping an eye on, especially for answers from users such as peak, 0stone0, pmf, glennj and others.
- The [jq Manual](https://stedolan.github.io/jq/manual/) is a good reference, although it can feel rather terse at first. Worth persisting with though.
- There are quite a few posts tagged `jq` over on [qmacro.org](https://qmacro.org/tags/jq/).
- The blog post [Getting BTP resource GUIDs with the btp CLI - part 2 - JSON and jq](https://blogs.sap.com/2021/12/01/getting-btp-resource-guids-with-the-btp-cli-part-2-json-and-jq/) shows how to use the JSON output of the btp CLI and parse it with `jq`.
- In the BTP Services Metadata repo on GitHub, there's a [Metadata exploration](https://github.com/SAP-samples/btp-service-metadata/tree/main/metadata-exploration) section that has some examples of how you can use `jq` (and also JavaScript) to explore the rich metadata available.
- [An introduction to JQ](https://earthly.dev/blog/jq-select/)

## Other tools

There are other tools available for exploring JSON, and you may wish to look at those in addition to `jq`.

- [gron - making JSON greppable](https://github.com/tomnomnom/gron)
- [fx - function execution](https://github.com/antonmedv/fx)
- [jless — a command-line JSON viewer](https://jless.io/)
