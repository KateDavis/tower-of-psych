I hit the GUI code pretty hard, in preparation for [Version1](Version1.md).  The result is a total overhaul of the Tower of Psych GUIs!

### General ###
The new GUIs show more data than the old ones.  Hopefully they look and feel nicer too, because I redesigned their appearance and took advantage of some undocumented Matlab HTML features.

Thanks to Yair Altman for the [Undocumented Matlab](http://undocumentedmatlab.com/) tips.

Instead of trying to summarize every conceivable variable with a custom "stringify" function, GUIs now capture the output of the built-in `disp()` function.  These summaries are pretty good.

I made a new color scheme called `puebloColors()`, inspired by [Arrow to the Sun](http://en.wikipedia.org/wiki/Arrow_to_the_Sun), a great picture book by [Gerlad McDermott](http://en.wikipedia.org/wiki/Gerald_McDermott).  In the GUIs, strings get colored in based on spelling, creating a visual pop-out effect.

I got rid of some custom widgets like `topsText` and `ScrollingControlGrid`.  Instead, I made better use of the built-in `uitable` and `uitree` (`uitree` is undocumented).

GUIs are based on a `topsFigure` object and one or more `topsPanel` objects each of which presents a different kind of content.  The `topsFigure` and `topsPanel`s can talk to each other by updating a _current item_ which they all share.

### `topsFigure` ###
`topsFigure` is the top-level container for the new GUIs.  One GUI has exactly one `topsFigure`.  The `topsFigure` is in charge of a Matlab figure window, one or more `topsPanel` objects, and four buttons:
  * The **refresh** button tells the `topsFigure` and `topsPanel`s to update their appearances in case anything has changed.
  * The **open as file** button attempts to open the _current item_ as though it were a file name.  If it's not a file name, nothing happens.
  * The **open in gui** button opens a new GUI for the _current item_, to show it in more detail.
  * The **to workspace** button assigns the _current item_ to a variable in the base workspace.  It displays the new variable name and its contents in the Command Window.

Custom buttons can be added to a `topsFigure` once its created.  All the buttons appear in a row at the bottom of the figure.

`topsFigure` also defines the look and feel of most GUI components.  It provides wrapper methods for making things like tables and buttons with consistent property settings, like font and colors.

### `topsPanel` ###
`topsPanel` objects deal with specific kinds of content.  Their job is to represent an item visually.  The item might be a _base item_ that never changes, or a _current item_ which changes as the user clicks around the GUI.  `topsPanel` objects can also set the _current item_ by providing user controls.

There are several flavors of `topsPanel`.  It's easy to drop any combination of these into a `topsFigure` to make a custom GUI.  Since they all know about the _current item_, they all play nicely together.
  * `topsDrillDownPanel` can represent any value.  It shows a tree view for browsing an item and any of its elements, fields, or properties, to arbitrary depth.
  * `topsTablePanel` represents cell array and struct/object array data as a 2D table.  It folds cell arrays to fit into the 2D view.  It shows struct/object field names as column headings
  * `topsGroupedListPanel` lets the user browse a `topsGroupedList` by selecting a group and a mnemonic.  It also lets the user type in a statement to edit the value stored under the selected group and mnemonic.
  * `topsRunnablesPanel` shows a tree view of `topsRunnable` objects.  This gives an overview of an experiment's structure.
  * `topsDataLogPanel` summarizes the data in `topsDataLog`.  It shows a "raster" of data groups vs. data timestamps.  The user can choose which groups and the range of timestamps to view.
  * `topsInfoPanel` shows a description of the _current item_.

### `topsFoundation` ###
As before, all `topsFoundation` classes have a `gui()` method which opens up a GUI for showing object details.

Each `gui()` implementation creates `topsPanel` objects appropriate for summarizing object properties, and adds them to a new `topsFigure`.  Aside from choosing correct panel types, `gui()` methods don't know about GUI details.

Previously, `topsFoundation` objects posted notifications about certain events, like "new item" or "started running".  These allowed GUIs to update some of their content automatically.  This was a nice idea, but using notifications was the wrong approach.

Notifications required foundation classes and GUI classes to "know" a lot about each other, so they made it harder to revise and extend foundation classes.  Notifications sometimes took a long time to execute, which was problematic in Matlab's single-threaded environment.  They were frustrating to debug, because Matlab didn't report a full stack trace for event handler code.  They led to lots of extra lines of code, defining behaviors to handle this and that event.

So I removed all the notification code.  Instead, users can push the GUI **refresh** button when they need to.  This is less nice because it's not automatic, but it's more nice because it will probably work more often.