I'm aiming for a major revision, called Version 1.  I expect to finish it by April, 2012.  My big goals for 1.0 are:

  * Good agreement among project areas, including code base, documentation, and project site.
  * Resolution of outstanding project issues, removal of stale issues
  * Good explanation of project components, and how to access components individually, without requiring [the whole enchilada](http://idioms.thefreedictionary.com/whole+enchilada)
  * Installer to easily get Version 1 by name (no need to know about repository tags, trunk etc.)
  * Expectation of long-term stability

This page contains my laundry list of changes to Tower of Psych.



### _January2010_ ###
The first goal is to complete the changes in the [January2012](January2012.md) milestone.

_This was done at the end of January, 2012._

### _GUIs_ ###
The topsGUI code evolved into a mess.  I want to clean it up so that it can become more useful.

  * ScrollingControlGrid -> topsControlGrid
  * Need to refactor GUI code for use cases and clarity, cause it's a mess
  * Fewer GUIs?
  * GUIs need to show relevant data, rather than automatic data
  * Make awesome "pueblo" color scheme
  * Figure out how to re-summarize text, as widget resizes
  * Instead responding to events posted by tops classes, it would be easier and maybe even better just to have a "refresh" button in every GUI.
> (big - 3 days)

_This was done in February, 2012.  See [GUIsVersion1](GUIsVersion1.md)_

### _Code Style_ ###
Class members that are intuitively "internal" to a class should all use the SetAccess = protected or Access = protected modifier.  That way members are viewable but won't get messed with by accident.  Now, there's a mix of access modifiers and hidden status, for no good reason.
> (small)

topsFoundation subclasses should all take a "name" argument in their constructors.  Matlab makes this a pain in the neck because it requires such a constructor to be cut and pasted.  But I think it's worth having a name appear in the same line where an object is created, to make code easy to scan
> (small)

_These are done as of 13 March 2012._

### _Demos_ ###
I want move encounter/ and spots/ demos into a tasks/ folder
> (small)

_This was done in March 2012._

### _Foundation_ ###
I want to rename EventWithData -> topsEvent
> (small)

_This became moot in February, 2012.  See [GUIsVersion1](GUIsVersion1.md)_

### _Utilities_ ###
Several of the utilities/ functions can be cleaned up or organized.

  * Retain spacedColors, but implement "puebloColors" as well
    * done as of January2012._* summarizeValue may truncate internally
    * made moot as of January2012, removed_
  * "bench_" -> "benchmark_", retain all as points of interest
    * done as of 13 March 2012_* "GrapherSandbox" -> "demo\_Grapher", comment, move to demos/graphing/
    * done as of 13 March 2012_
> (small)

_These are all done as of 13 March 2012._

### _Tests_ ###
Some unit tests need renaming.

  * Rename tests to agree with 1.0
  * TestStringifyValue -> TestSummarizeValue
    * _This became moot in February, 2012.  See [GUIsVersion1](GUIsVersion1.md)_
> (small)

_Done as of 13 March 2012_

### _Issues_ ###
The issues database has become stale and irrelevant.

  * Close issues solved in 1.0
  * _No-Solve other issues with a note (did on 8 Jan)_
> (small)

_I worked through and closed all the outstanding issues in March 2012._

### _Docs_ ###
The role and form of the Doxygen docs should be tweaked.

  * Docs have header that links back to project site
  * Doc front page has simple table of contents for classes and functions.
  * Docs just show class and function reference, not other content
  * source code comments all use doxygen style
  * source code comments only define demos and utilities groups
  * doxygen builder script adds newly generated doxygen content
> (small)

_This is done as of 14 March 2012._

### _Wiki_ ###
The wiki should be filled out and brought into agreement with the code and docs.

  * Replace aboutTowerOfPsych with ComponentsAndConcepts page.  For each one, include
    * basic description
    * checkout links
  * Installation instructions

> (big - 1 day)

_This is done as of 16 March 2012._

### _Main Page_ ###
The project main page should be updated.

  * Short intro, Short history, and status
  * link to [ComponentsAndConcepts](ComponentsAndConcepts.md)
  * link to [Installation](Installation.md)
> (small)

_This is done as of 16 March 2012!_